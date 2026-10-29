// MusicPill 0.8.1 - made by nano
// 0.8.1: collapsed row redone: our own iOS 26 pill (artwork, full-size title
//        with the E badge, artist, play) instead of shrinking Music's bar,
//        circles sized / spaced like iOS 26, the search circle no longer
//        blows up, and a more liquid morph (stretch, overshoot, settle).
// 0.8.0: iOS 26 tab bar collapse. Scrolling down squeezes the tab bar into a
//        glass circle (current tab), Search splits off into its own circle,
//        and the pill drops into the row between them (skip button hides).
//        Scrolling back up / tapping the circle melts it all back out.
// 0.7.4: queue pills, new method. The queue list is slid down 54pt (transform)
//        and the pills fill the space at its top. Music's own scroll math is
//        untouched, so nothing can end up under the pills; the list's bottom
//        54pt is trimmed (mask + touch area) so it never covers the controls.
// 0.7.3: queue pills are trimmed at the list's top edge (slide under the song
//        info instead of over it), Music's auto-scroll is corrected so the
//        pills show when the queue opens, and Repeat One is read from Music's
//        own repeat button icon.
// 0.7.2: queue pills sit between the song info and "Continue Playing" (made
//        with the table's section-header top padding, so Music's own
//        scrolling can't push the song under them) and have a solid background.
// 0.7.1: iOS 26 queue: shuffle / repeat / autoplay as a pill row above
//        "Continue Playing" (54pt band made with the list's top inset), round
//        queue button (it's 28pt, too small for 0.7.0's check).
// 0.7.0: full player queue: "Playing Next" -> "Continue Playing", round queue
//        button, and a debug map of the player screen to build the iOS 26
//        shuffle/repeat/autoplay row next.
// 0.6.5: normal pill another 4% bigger (about 6% over Small); dragging the page
//        down (finger moving down) grows it 10% more, dragging up returns it
//        to normal. Reversed from 0.6.4, and no reset at the top.
// 0.6.3: no flash of the old Play/Shuffle when an album opens. They're hidden
//        the moment they appear and the new row is built right away, instead
//        of waiting for the next 1/4-second check.
// 0.6.2: the row's right circle shows Music's real download control live
//        (arrow, download progress, checkmark) via a portal view; back-button
//        glass sits behind the chevron, 34pt like iOS 26, off the screen edge.
// 0.6.1: no more flicker. Music's resets of the buttons we replace/clear are now
//        blocked when they happen (hooks) instead of corrected 4x a second, and
//        the top glass is attached to the buttons so it moves with them.
// 0.6.0: scrolling song title in the pill; iOS 26 style album/playlist buttons
//        (shuffle circle, white Play, download circle); glass top buttons.
// 0.5.3: shrink/round the bar's INNER content view instead of its container.
//        Music keeps resetting the container's transform after the full player
//        closes, so forcing it there made it flicker. Plus a back-off if
//        anything still fights over the size.
// 0.5.2: pill is always Small (size setting removed) and is forced back to Small
//        after the full player closes, even when Music leaves its own transform on it.
// 0.5.1: pill stays small after closing the full player; see-through background always on.
// 0.5.0: pill size setting (Normal / Compact / Small) and swipe left/right on
//        the pill for next/previous track.
// Apple Music only.
//  1. "Listen Now" tab -> "Home" with a house icon.
//  2. Now-playing bar -> rounded floating glass pill (iOS 26 style).
//     Only corner radius + transform on the bar; never its frame. All work runs
//     after the layout pass, so it can't loop.
//  3. Hides the shared gray blur behind the now-playing bar and tab bar
//     (PaletteContainerView's UIVisualEffectView) so the gap is see-through.
//  4. Debug overlay listing what it found near the tab bar.
//
// Settings: Music is sandboxed and can't read our prefs through cfprefsd, so
// the switches did nothing in 0.3.0. We now read the plist file directly
// (Dopamine keeps tweak prefs under /var/jb) and fall back to cfprefsd.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <MediaPlayer/MediaPlayer.h>

// UIKit's private live-mirror view: draws another view's current contents
// (including its animations) somewhere else.
@interface UIView (MPPortal)
- (instancetype)initWithSourceView:(UIView *)source;
@end

#define DOM CFSTR("com.user.musicpill")
#define DOM_NS @"com.user.musicpill"
#define NOTIFY CFSTR("com.user.musicpill/prefschanged")
#define DEBUG_TAG 0x4D504442
#define GLASS_TAG 0x4D50474C
#define MARQUEE_TAG 0x4D504D51
#define ROW_TAG 0x4D50524F
#define NAVGLASS_TAG 0x4D504E47
#define PORTAL_TAG 0x4D50504F
#define PLAYERDEBUG_TAG 0x4D505044
#define QUEUEROW_TAG 0x4D505152
#define QUEUE_EXTRA 54.0
#define COLLAPSE_TAG 0x4D50434C

static BOOL gRename = YES, gRound = YES, gDebug = NO, gSwipe = YES;
static BOOL gCollapse = YES, gCollapsed = NO;
static NSString *gCollapseDebug = @"-";
static BOOL gMarquee = YES, gAlbum = YES, gNavGlass = YES, gQueueLook = YES;
static NSString *gAlbumDebug = @"-", *gNavDebug = @"-", *gMarqueeDebug = @"-";
// The see-through background is always on (no longer a setting).
static const BOOL gHideBG = YES;
// Fixed at Small (the size picked in Settings in 0.5.0). 0 Normal, 1 Compact, 2 Small.
static const int gSize = 2;
// Pill scale on top of Small: ~6% bigger normally (1.02 x 1.04), and 10% bigger
// than that while the page is dragged down.
static BOOL gExpanded = NO;
#define PILL_GROW_NORMAL (1.02 * 1.04)
#define PILL_GROW_SCROLL (1.02 * 1.04 * 1.10)
static NSString *gPrefsSource = @"defaults";
static __weak UITabBar *gLastTabBar;

static const void *kMini = &kMini;
static const void *kBusy = &kBusy;
static const void *kHome = &kHome;
static const void *kStyled = &kStyled;
static const void *kHiddenBG = &kHiddenBG;
static const void *kApplied = &kApplied;
static const void *kSwipeAdded = &kSwipeAdded;
static const void *kFight = &kFight;
static const void *kHidByUs = &kHidByUs;
static const void *kClearedBG = &kClearedBG;
static const void *kQueueTable = &kQueueTable;
static const void *kQueuePad = &kQueuePad; // original clipsToBounds of the queue list
static NSString *gQueueDebug = @"-";

#pragma mark - prefs

static NSDictionary *ReadPrefsFile(NSString **source) {
    NSString *name = [DOM_NS stringByAppendingString:@".plist"];
    NSArray *dirs = @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"];
    NSDictionary *best = nil; NSDate *bestDate = nil;
    for (NSString *dir in dirs) {
        NSString *p = [dir stringByAppendingString:name];
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p];
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        NSDate *m = [[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil][NSFileModificationDate];
        if (!best || (m && bestDate && [m compare:bestDate] == NSOrderedDescending)) {
            best = d; bestDate = m;
            if (source) *source = p;
        }
    }
    return best;
}

static BOOL PrefBool(NSDictionary *file, NSString *key, BOOL def) {
    id v = file[key];
    if (!v) {
        CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)key, DOM);
        if (cf) v = (__bridge_transfer id)cf;
    }
    return v ? [v boolValue] : def;
}

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSString *src = nil;
    NSDictionary *file = ReadPrefsFile(&src);
    gPrefsSource = src ?: @"cfprefs/defaults";
    gRename = PrefBool(file, @"rename", YES);
    gRound  = PrefBool(file, @"round", YES);
    gDebug  = PrefBool(file, @"debug", NO);
    gSwipe  = PrefBool(file, @"swipe", YES);
    gMarquee  = PrefBool(file, @"marquee", YES);
    gAlbum    = PrefBool(file, @"album", YES);
    gNavGlass = PrefBool(file, @"navglass", YES);
    gQueueLook = PrefBool(file, @"queuelook", YES);
    gCollapse = PrefBool(file, @"collapse", YES);
}

static void Update(UITabBar *tb);

// iOS 26 wording on the queue screen.
static NSString *MapQueueText(NSString *s) {
    if (!gQueueLook || ![s isKindOfClass:[NSString class]]) return s;
    if ([s isEqualToString:@"Playing Next"]) return @"Continue Playing";
    if ([s isEqualToString:@"Autoplaying similar music"]) return @"AutoPlaying similar music";
    return s;
}

static BOOL PlayerIsUp(UIWindow *w, UIView **playerView) {
    UIViewController *p = w.rootViewController.presentedViewController;
    if (!p || p.isBeingDismissed) return NO;
    if (playerView) *playerView = p.view;
    return YES;
}

// The queue button (bottom right of the full player) gets a filled background
// when selected; make that background a circle like iOS 26.
static void RoundIfQueueButton(UIView *v) {
    if (!gQueueLook) return;
    CGFloat w = v.bounds.size.width, h = v.bounds.size.height;
    if (w < 24 || w > 70 || fabs(w - h) > 6) return;
    UIWindow *win = v.window;
    UIView *player = nil;
    if (!win || !PlayerIsUp(win, &player) || ![v isDescendantOfView:player]) return;
    CGRect r = [v convertRect:v.bounds toView:win];
    CGFloat H = win.bounds.size.height;
    if (CGRectGetMinY(r) < H * 0.78 || CGRectGetMidX(r) < win.bounds.size.width * 0.6) return;
    // The queue button is a 28pt button whose selected image is a red rounded
    // square; clipping the button to a circle turns that into a red circle.
    BOOL imageButton = [v isKindOfClass:[UIButton class]] && w <= 40;
    BOOL filled = v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) >= 0.05;
    if (!imageButton && !filled) return;
    CGFloat radius = MIN(w, h) / 2;
    if (v.layer.cornerRadius != radius) { v.layer.cornerRadius = radius; v.layer.cornerCurve = kCACornerCurveContinuous; }
    if (imageButton && !v.clipsToBounds) v.clipsToBounds = YES;
}
static void AlbumControlLaidOut(UIControl *c);
static void PositionQueueRow(UIScrollView *table);

static void ReloadAndApply(void) {
    LoadPrefs();
    UITabBar *tb = gLastTabBar;
    if (tb) { @try { Update(tb); } @catch (__unused id e) {} }
}

static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    // Settings may finish writing the file a moment after the notification.
    dispatch_async(dispatch_get_main_queue(), ^{ ReloadAndApply(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ReloadAndApply(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ReloadAndApply(); });
}

#pragma mark - Listen Now -> Home

static BOOL IsListenNow(NSString *s) {
    return gRename && [s isKindOfClass:[NSString class]] && [s isEqualToString:@"Listen Now"];
}
static UIImage *House(void) { return [UIImage systemImageNamed:@"house.fill"]; }

static void MarkHome(UITabBarItem *it) {
    if (objc_getAssociatedObject(it, kHome)) return;
    objc_setAssociatedObject(it, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    it.image = House();
    it.selectedImage = House();
}

static void FixTabItems(UITabBar *tb) {
    if (!gRename) return;
    for (UITabBarItem *it in tb.items)
        if ([it.title isEqualToString:@"Home"] || [it.title isEqualToString:@"Listen Now"]) {
            if ([it.title isEqualToString:@"Listen Now"]) it.title = @"Home";
            MarkHome(it);
        }
}

%hook UITabBarItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSInteger)tag {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), tag);
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)sel {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), House());
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (void)setTitle:(NSString *)title {
    if (IsListenNow(title)) {
        %orig(@"Home");
        __weak UITabBarItem *weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{ if (weak) MarkHome(weak); });
        return;
    }
    %orig;
}
- (void)setImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
- (void)setSelectedImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
%end

%hook UIViewController
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
%end

#pragma mark - geometry helpers

// Frame of v in root's coordinates, ignoring v's own transform.
static CGRect UntransformedRect(UIView *v, UIView *root) {
    if (!v.superview) return CGRectNull;
    CGPoint c = [v.superview convertPoint:v.center toView:root];
    CGSize s = v.bounds.size;
    return CGRectMake(c.x - s.width / 2, c.y - s.height / 2, s.width, s.height);
}

static BOOL BarSized(UIView *v, UIView *root) {
    if (v.hidden || v.alpha < 0.01 || v.tag == DEBUG_TAG || v.tag == GLASS_TAG) return NO;
    CGFloat h = v.bounds.size.height;
    return h >= 44 && h <= 100 && v.bounds.size.width >= root.bounds.size.width * 0.6;
}

static BOOL Geometry(UIView *v, UIView *root, CGRect tabRect, CGFloat minGap) {
    if (!BarSized(v, root)) return NO;
    CGRect r = UntransformedRect(v, root);
    if (CGRectIsNull(r)) return NO;
    CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
    return gap >= minGap && gap <= 40;
}

#pragma mark - find the now-playing bar

// iOS 16 Music: PaletteContainerView (h~172, the gray blur behind bar + tab bar)
//   -> UIVisualEffectView -> ... -> PaletteContainerView...ContainerView (h~68)  <- the bar
static UIView *FindByName(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]]) continue;
        NSString *n = NSStringFromClass([sub class]);
        BOOL nameHit = [n containsString:@"MiniPlayer"] ||
                       ([n containsString:@"PaletteContainerView"] && [n hasSuffix:@"ContainerView"] && ![n isEqualToString:@"PaletteContainerView"] && ![n hasSuffix:@"20PaletteContainerView"]);
        if (nameHit && Geometry(sub, root, tabRect, -20)) return sub;
        if (depth < 7) { UIView *f = FindByName(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

static UIView *FindByShape(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]] || [sub isKindOfClass:[UITabBar class]]) continue;
        if (Geometry(sub, root, tabRect, -12)) return sub; // outermost match
        if (depth < 5) { UIView *f = FindByShape(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

// The big gray blur: a PaletteContainerView taller than the bar, and its effect views.
static UIView *FindPalette(UIView *view, int depth) {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:[UIScrollView class]]) continue;
        NSString *n = NSStringFromClass([sub class]);
        if ([n containsString:@"PaletteContainerView"] && sub.bounds.size.height > 100) return sub;
        if (depth < 4) { UIView *f = FindPalette(sub, depth + 1); if (f) return f; }
    }
    return nil;
}

#pragma mark - styling

// The bar container (PaletteContainerView...ContainerView) holds one full-size
// content view (the "UIView h=68" in the debug box). Music animates the
// container; it leaves the content view alone, so that's where we style.
static UIView *InnerContent(UIView *c) {
    for (UIView *s in c.subviews) {
        if (s.tag == GLASS_TAG || s.tag == DEBUG_TAG || s.hidden) continue;
        if (fabs(s.bounds.size.width - c.bounds.size.width) < 2 && fabs(s.bounds.size.height - c.bounds.size.height) < 2) return s;
    }
    return c;
}

static CGRect gCollapsedPill;   // where the pill sits when collapsed (root coords)
static CGAffineTransform PillTransform(UIView *m) {
    CGFloat W = m.bounds.size.width, H = m.bounds.size.height;

    // Total horizontal inset for Normal / Compact / Small.
    CGFloat inset = gSize == 0 ? 24 : (gSize == 1 ? 56 : 96);
    CGFloat s = W > inset + 100 ? (W - inset) / W : 1;
    s = MIN(1.0, s * (gExpanded ? PILL_GROW_SCROLL : PILL_GROW_NORMAL));
    // Scaling shrinks around the center; shift down a bit so a smaller pill
    // keeps the same small gap above the tab bar instead of floating up.
    CGFloat ty = -6 + H * (1 - s) / 2;
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, ty), s, s);
}

// force: the bar is settled (no animation running, full player closed), so put
// our size back no matter what transform Music left on it. Closing the full
// player leaves Music's own (non-identity) transform behind, which is why
// 0.5.1 never shrank it again.
static void ApplyPillTransform(UIView *m, BOOL force) {
    CGAffineTransform t = PillTransform(m);
    NSValue *last = objc_getAssociatedObject(m, kApplied);
    // Back-off: if we've had to force it more than 4 times in 2 seconds,
    // something else is fighting us. Stop forcing for 5 seconds so it can't flicker.
    if (force) {
        CFTimeInterval now = CACurrentMediaTime();
        NSArray *f = objc_getAssociatedObject(m, kFight); // @[windowStart, count, backoffUntil]
        double start = f ? [f[0] doubleValue] : now, until = f ? [f[2] doubleValue] : 0;
        int count = f ? [f[1] intValue] : 0;
        if (now < until) force = NO;
        else if (!CGAffineTransformEqualToTransform(m.transform, t)) {
            if (now - start > 2.0) { start = now; count = 0; }
            count++;
            if (count > 4) { until = now + 5.0; count = 0; start = now; force = NO; }
        }
        objc_setAssociatedObject(m, kFight, @[@(start), @(count), @(until)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    BOOL ours = force || CGAffineTransformIsIdentity(m.transform) ||
                (last && CGAffineTransformEqualToTransform(m.transform, last.CGAffineTransformValue));
    if (ours && !CGAffineTransformEqualToTransform(m.transform, t)) {
        // Already styled once and now coming back from Music's reset: ease
        // back down instead of snapping.
        if (last && m.window) {
            [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{ m.transform = t; } completion:nil];
        } else {
            m.transform = t;
        }
    }
    if (ours) objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - swipe to skip

typedef Boolean (*MRSendCommandFn)(int command, CFDictionaryRef options);

static void SkipTrack(BOOL next) {
    static MRSendCommandFn send;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) send = (MRSendCommandFn)dlsym(h, "MRMediaRemoteSendCommand");
    });
    // MediaRemote commands: 4 = next track, 5 = previous track.
    if (send && send(next ? 4 : 5, NULL)) return;
    MPMusicPlayerController *p = [MPMusicPlayerController systemMusicPlayer];
    if (next) [p skipToNextItem]; else [p skipToPreviousItem];
}

@interface MPSwipeTarget : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end

@implementation MPSwipeTarget
+ (instancetype)shared { static MPSwipeTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPSwipeTarget new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g { return gSwipe && gRound; }
- (void)swiped:(UISwipeGestureRecognizer *)g {
    UIView *m = g.view;
    if (!m || !gSwipe) return;
    BOOL next = g.direction == UISwipeGestureRecognizerDirectionLeft;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SkipTrack(next);
    // Little slide-and-bounce so the swipe feels like it did something.
    CGAffineTransform base = PillTransform(m);
    CGAffineTransform nudge = CGAffineTransformTranslate(base, next ? -26 : 26, 0);
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        m.transform = nudge;
    } completion:^(BOOL done) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ m.transform = base; }
                         completion:^(BOOL d) {
            objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:base], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }];
    }];
    objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:base], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

static void AddSwipes(UIView *m) {
    if (objc_getAssociatedObject(m, kSwipeAdded)) return;
    objc_setAssociatedObject(m, kSwipeAdded, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    for (NSNumber *dir in @[@(UISwipeGestureRecognizerDirectionLeft), @(UISwipeGestureRecognizerDirectionRight)]) {
        UISwipeGestureRecognizer *s = [[UISwipeGestureRecognizer alloc] initWithTarget:[MPSwipeTarget shared] action:@selector(swiped:)];
        s.direction = dir.unsignedIntegerValue;
        s.delegate = [MPSwipeTarget shared];
        s.cancelsTouchesInView = YES; // a swipe shouldn't also count as a tap that opens the player
        [m addGestureRecognizer:s];
    }
}

static void StylePill(UIView *m) {
    CGFloat r = m.bounds.size.height / 2;
    if (m.layer.cornerRadius != r) {
        m.layer.cornerRadius = r;
        m.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (!objc_getAssociatedObject(m, kStyled)) {
        objc_setAssociatedObject(m, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        m.clipsToBounds = YES;
        m.layer.borderWidth = 0.75;
        m.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    }
    // Own glass background, so the pill still has one when the gray blur is hidden.
    UIView *glass = [m viewWithTag:GLASS_TAG];
    if (gHideBG && !glass) {
        UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        g.tag = GLASS_TAG;
        g.userInteractionEnabled = NO;
        g.frame = m.bounds;
        g.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [m insertSubview:g atIndex:0];
    } else if (!gHideBG && glass) {
        [glass removeFromSuperview];
    }
    ApplyPillTransform(m, NO);
    AddSwipes(m);
}

static void UnstylePill(UIView *m) {
    if (!m || !objc_getAssociatedObject(m, kStyled)) return;
    objc_setAssociatedObject(m, kStyled, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSValue *last = objc_getAssociatedObject(m, kApplied);
    if (last && CGAffineTransformEqualToTransform(m.transform, last.CGAffineTransformValue)) m.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(m, kApplied, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    m.layer.cornerRadius = 0;
    m.layer.borderWidth = 0;
    [[m viewWithTag:GLASS_TAG] removeFromSuperview];
}

// The bar's content lives INSIDE the effect view we hide, so hiding the effect
// view would hide the bar too. Instead, clear only the blur layers and keep the
// content view visible.
static void SetBackdropClear(UIView *palette, BOOL clear) {
    if (!palette) return;
    for (UIView *s in palette.subviews) {
        if (![s isKindOfClass:[UIVisualEffectView class]]) continue;
        UIVisualEffectView *ev = (UIVisualEffectView *)s;
        for (UIView *part in ev.subviews) {
            if (part == ev.contentView) continue;
            if (clear) {
                if (part.alpha != 0) { part.alpha = 0; objc_setAssociatedObject(part, kHiddenBG, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            } else if (objc_getAssociatedObject(part, kHiddenBG)) {
                part.alpha = 1;
                objc_setAssociatedObject(part, kHiddenBG, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}

#pragma mark - debug overlay

static void CollectCandidates(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth, NSMutableArray *out) {
    for (UIView *sub in view.subviews) {
        if (out.count >= 10) return;
        if (sub == tb || sub.tag == DEBUG_TAG || sub.tag == GLASS_TAG || sub.tag == MARQUEE_TAG || [sub isKindOfClass:[UIScrollView class]]) continue;
        CGRect r = UntransformedRect(sub, root);
        if (!CGRectIsNull(r)) {
            CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
            if (r.size.width >= root.bounds.size.width * 0.6 && r.size.height >= 30 && r.size.height <= 220 && gap > -160 && gap < 60) {
                NSString *name = NSStringFromClass([sub class]);
                if (name.length > 40) name = [@"…" stringByAppendingString:[name substringFromIndex:name.length - 39]];
                [out addObject:[NSString stringWithFormat:@"%@ h=%.0f gap=%.0f d=%d a=%.1f%@", name, r.size.height, gap, depth, sub.alpha, sub.hidden ? @" hidden" : @""]];
            }
        }
        if (depth < 6) CollectCandidates(sub, root, tabRect, tb, depth + 1, out);
    }
}

static void UpdateDebug(UITabBar *tb, UIView *root, CGRect tabRect, UIView *mini) {
    UIWindow *w = tb.window;
    if (!w) return;
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug || PlayerIsUp(w, NULL)) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = DEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.85];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSMutableArray *c = [NSMutableArray array];
    CollectCandidates(root, root, tabRect, tb, 0, c);
    NSString *found = @"none";
    if (mini) {
        NSString *n = NSStringFromClass([mini class]);
        if (n.length > 40) n = [@"…" stringByAppendingString:[n substringFromIndex:n.length - 39]];
        found = [NSString stringWithFormat:@"%@ h=%.0f", n, mini.bounds.size.height];
    }
    NSString *text = [NSString stringWithFormat:@" MusicPill 0.8.1 debug\n prefs: %@\n rename=%d round=%d size=%d swipe=%d\n tab y=%.0f h=%.0f\n PICKED: %@\n title: %@\n album: %@\n nav: %@\n collapse: %@\n %@",
                      gPrefsSource, gRename, gRound, gSize, gSwipe,
                      CGRectGetMinY(tabRect), tabRect.size.height, found, gMarqueeDebug, gAlbumDebug, gNavDebug, gCollapseDebug,
                      [c componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(12, 110, width, s.height + 8);
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

#pragma mark - driver

static void SetCollapsed(BOOL collapse, BOOL animated);
static void Update(UITabBar *tb) {
    FixTabItems(tb);
    // Full player open: bars back to normal so Music's own animation looks right.
    if (gCollapsed) {
        UIViewController *rv = tb.window.rootViewController;
        if (rv.presentedViewController) SetCollapsed(NO, NO);
        else { UIView *m = objc_getAssociatedObject(tb, kMini); if (m.alpha > 0.01) m.alpha = 0; }
    }
    UIView *root = tb.superview;
    if (!root || !tb.window) return;
    CGRect tabRect = UntransformedRect(tb, root);

    UIView *palette = FindPalette(root, 0);
    SetBackdropClear(palette, gRound && gHideBG);

    UIView *mini = objc_getAssociatedObject(tb, kMini);
    if (gRound) {
        // Stick with the bar we already picked while it's on screen and bar-sized.
        // Re-picking is what caused two nested pills in 0.3.0.
        BOOL keep = mini && mini.window && [mini isDescendantOfView:root] && BarSized(mini, root);
        if (!keep) {
            UIView *byName = FindByName(root, root, tabRect, tb, 0);
            UIView *found = byName ? InnerContent(byName) : FindByShape(root, root, tabRect, tb, 0);
            if (found != mini) UnstylePill(mini);
            mini = found;
            objc_setAssociatedObject(tb, kMini, mini, OBJC_ASSOCIATION_ASSIGN);
        }
        if (mini) StylePill(mini);
    } else if (mini) {
        UnstylePill(mini);
    }
    UpdateDebug(tb, root, tabRect, gRound ? mini : nil);
}

#pragma mark - iOS 26 collapse

@interface MPCollapse : NSObject
+ (instancetype)shared;
- (void)tapTab;
- (void)tapSearch;
@end


static UIView *TabButtonRow(UITabBar *tb, CGFloat *rowY, UIView *root) {
    UIView *first = nil;
    for (UIView *s in tb.subviews) if ([NSStringFromClass([s class]) containsString:@"TabBarButton"] && !s.hidden) { first = s; break; }
    if (first) *rowY = CGRectGetMidY([first.superview convertRect:first.frame toView:root]);
    else *rowY = CGRectGetMinY(UntransformedRect(tb, root)) + 28;
    return first;
}

static UIImage *SelectedTabImage(UITabBar *tb) {
    UITabBarItem *it = tb.selectedItem;
    UIImage *img = it.selectedImage ?: it.image;
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static UIView *GlassCircle(NSString *ident, UIView *host) {
    for (UIView *v in host.subviews) if ([v.accessibilityIdentifier isEqualToString:ident]) return v;
    UIView *c = [UIView new];
    c.accessibilityIdentifier = ident;
    c.clipsToBounds = NO;
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    g.tag = 1; g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    [c addSubview:g];
    UIImageView *iv = [UIImageView new];
    iv.tag = 2; iv.contentMode = UIViewContentModeCenter; iv.userInteractionEnabled = NO;
    [c addSubview:iv];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[MPCollapse shared]
                                                                          action:[ident isEqualToString:@"tab"] ? @selector(tapTab) : @selector(tapSearch)];
    [c addGestureRecognizer:tap];
    [host addSubview:c];
    return c;
}
static void LayoutCircle(UIView *c, CGRect f) {
    c.bounds = CGRectMake(0, 0, f.size.width, f.size.height);
    c.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
    UIView *g = [c viewWithTag:1];
    g.frame = c.bounds;
    g.layer.cornerRadius = MIN(f.size.width, f.size.height) / 2;
    [c viewWithTag:2].frame = c.bounds;
}

@interface MPPassHost : UIView @end
@implementation MPPassHost
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { UIView *h = [super hitTest:p withEvent:e]; return h == self ? nil : h; }
@end

static UIView *CollapseHost(UITabBar *tb) {
    UIView *root = tb.superview;
    UIView *h = [root viewWithTag:COLLAPSE_TAG];
    if (h.superview != root) {
        h = [MPPassHost new];
        h.tag = COLLAPSE_TAG;
        [root addSubview:h];
    }
    [root bringSubviewToFront:h];
    h.frame = root.bounds;
    return h;
}



static void SetCollapsedFwd(BOOL c);
// ---- our compact iOS 26 pill (shown only while collapsed) ----
typedef Boolean (*MRSendFn)(int command, CFDictionaryRef options);
static void SendMR(int cmd) {
    static MRSendFn send; static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) send = (MRSendFn)dlsym(h, "MRMediaRemoteSendCommand");
    });
    if (send) send(cmd, NULL);
}

// Stand-in for a gesture recognizer so Music's tap handler sees "ended".
@interface MPGRProxy : NSProxy
@property (nonatomic, strong) UIGestureRecognizer *gr;
@end
@implementation MPGRProxy
- (UIGestureRecognizerState)state { return UIGestureRecognizerStateEnded; }
- (BOOL)isKindOfClass:(Class)c { return [_gr isKindOfClass:c]; }
- (BOOL)respondsToSelector:(SEL)s { return [_gr respondsToSelector:s]; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)s { return [_gr methodSignatureForSelector:s]; }
- (void)forwardInvocation:(NSInvocation *)i { [i invokeWithTarget:_gr]; }
@end

// Open the full player the way a tap on Music's bar does.
static BOOL OpenPlayer(UIView *mini) {
    for (UIView *v = mini; v; v = v.superview) {
        for (UIGestureRecognizer *g in v.gestureRecognizers) {
            if (![g isKindOfClass:[UITapGestureRecognizer class]] || !g.enabled) continue;
            NSArray *targets = nil;
            @try { targets = [g valueForKey:@"_targets"]; } @catch (__unused id e) {}
            for (id tg in targets) {
                id target = nil; SEL action = NULL;
                @try { target = [tg valueForKey:@"_target"]; } @catch (__unused id e) {}
                Ivar iv = class_getInstanceVariable([tg class], "_action");
                if (iv) action = *(SEL *)((uint8_t *)(__bridge void *)tg + ivar_getOffset(iv));
                if (!target || !action || ![target respondsToSelector:action] || [NSStringFromClass([target class]) hasPrefix:@"MP"]) continue;
                MPGRProxy *p = [MPGRProxy alloc]; p.gr = g;
                ((void (*)(id, SEL, id))objc_msgSend)(target, action, p);
                return YES;
            }
        }
        if ([NSStringFromClass([v class]) isEqualToString:@"PaletteContainerView"] || [NSStringFromClass([v class]) hasSuffix:@".PaletteContainerView"]) break;
    }
    return NO;
}

@interface MPMiniPill : UIView
@property (nonatomic, strong) UIVisualEffectView *glass;
@property (nonatomic, strong) UIImageView *art, *badge;
@property (nonatomic, strong) UILabel *title, *artist;
@property (nonatomic, strong) UIButton *play;
- (void)refresh;
@end
@implementation MPMiniPill
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    _glass.userInteractionEnabled = NO; _glass.clipsToBounds = YES;
    _glass.layer.cornerCurve = kCACornerCurveContinuous;
    _glass.layer.borderWidth = 0.75; _glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    [self addSubview:_glass];
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerRadius = 8; _art.layer.cornerCurve = kCACornerCurveContinuous;
    _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [self addSubview:_art];
    _title = [UILabel new]; _title.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; _title.textColor = UIColor.whiteColor;
    [self addSubview:_title];
    _artist = [UILabel new]; _artist.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular]; _artist.textColor = [UIColor colorWithWhite:1 alpha:0.62];
    [self addSubview:_artist];
    _badge = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"e.square.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium]]];
    _badge.tintColor = [UIColor colorWithWhite:1 alpha:0.62]; _badge.contentMode = UIViewContentModeCenter;
    [self addSubview:_badge];
    _play = [UIButton buttonWithType:UIButtonTypeSystem];
    _play.tintColor = UIColor.whiteColor;
    [_play addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_play];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(open)]];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize S = self.bounds.size;
    _glass.frame = self.bounds; _glass.layer.cornerRadius = S.height / 2;
    CGFloat a = S.height - 14;
    _art.frame = CGRectMake(8, 7, a, a);
    CGFloat x = 8 + a + 11, pw = 44, maxW = S.width - x - pw - 6;
    CGFloat bw = _badge.hidden ? 0 : 18;
    CGFloat tw = MIN(ceil([_title sizeThatFits:CGSizeMake(400, 30)].width), maxW - bw);
    _title.frame = CGRectMake(x, S.height / 2 - 20, tw, 21);
    _badge.frame = CGRectMake(x + tw + 3, S.height / 2 - 19, 15, 19);
    _artist.frame = CGRectMake(x, S.height / 2 + 1, maxW, 18);
    _play.frame = CGRectMake(S.width - pw - 6, (S.height - pw) / 2, pw, pw);
}
- (void)refresh {
    MPMusicPlayerController *p = [MPMusicPlayerController systemMusicPlayer];
    MPMediaItem *it = p.nowPlayingItem;
    NSString *t = it.title ?: @"Not Playing", *ar = it.artist ?: @"";
    if (![_title.text isEqualToString:t]) _title.text = t;
    if (![_artist.text isEqualToString:ar]) _artist.text = ar;
    _badge.hidden = !it.isExplicitItem;
    UIImage *img = [it.artwork imageWithSize:CGSizeMake(120, 120)];
    if (img != _art.image && (img || !it)) _art.image = img;
    BOOL playing = p.playbackState == MPMusicPlaybackStatePlaying;
    NSString *sym = playing ? @"pause.fill" : @"play.fill";
    if (![_play.accessibilityValue isEqualToString:sym]) {
        _play.accessibilityValue = sym;
        [_play setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    }
    [self setNeedsLayout];
}
- (void)togglePlay {
    SendMR(2);
    UIImageView *iv = _play.imageView;
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@1, @0.6, @1.12, @1]; k.keyTimes = @[@0, @0.3, @0.7, @1]; k.duration = 0.35;
    [iv.layer addAnimation:k forKey:@"p"];
    for (NSNumber *d in @[@0.15, @0.5]) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self refresh]; });
}
- (void)open {
    UITabBar *tb = gLastTabBar;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (!OpenPlayer(mini)) SetCollapsedFwd(NO);
}
@end

static const CGFloat kCD = 52;     // circle / pill height, like iOS 26
static const CGFloat kSide = 30;   // circles' distance from the screen edges
static const CGFloat kGap = 14;    // gap between circle and pill
static NSTimer *gPillTimer;

static void SetCollapsed(BOOL collapse, BOOL animated) {
    UITabBar *tb = gLastTabBar;
    UIView *root = tb.superview;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (collapse == gCollapsed) return;
    if (collapse && (!gCollapse || !gRound || !tb.window || tb.hidden || !mini.window || !objc_getAssociatedObject(mini, kStyled))) return;
    UIView *host = CollapseHost(tb);
    UIView *tab = GlassCircle(@"tab", host), *search = GlassCircle(@"search", host);
    MPMiniPill *pill = nil;
    for (UIView *v in host.subviews) if ([v isKindOfClass:[MPMiniPill class]]) pill = (MPMiniPill *)v;
    if (!pill) { pill = [MPMiniPill new]; pill.hidden = YES; [host addSubview:pill]; }
    CGFloat W = root.bounds.size.width, rowY = 0;
    TabButtonRow(tb, &rowY, root);
    CGRect tr = UntransformedRect(tb, root);
    CGRect wide = CGRectMake(CGRectGetMinX(tr) + 14, rowY - 29, tr.size.width - 28, 58);   // the tab bar's pill
    CGRect left = CGRectMake(kSide, rowY - kCD / 2, kCD, kCD), right = CGRectMake(W - kSide - kCD, rowY - kCD / 2, kCD, kCD);
    CGRect rightStart = CGRectMake(CGRectGetMaxX(wide) - kCD - 6, rowY - kCD / 2, kCD, kCD);
    gCollapsedPill = CGRectMake(CGRectGetMaxX(left) + kGap, rowY - kCD / 2, CGRectGetMinX(right) - kGap - CGRectGetMaxX(left) - kGap, kCD);
    CGRect miniRect = [mini convertRect:mini.bounds toView:host];   // where Music's bar is drawn now
    UIImageView *ti = (UIImageView *)[tab viewWithTag:2], *si = (UIImageView *)[search viewWithTag:2];
    ti.image = SelectedTabImage(tb); ti.tintColor = tb.tintColor ?: UIColor.systemPinkColor;
    si.image = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]];
    si.tintColor = UIColor.whiteColor;
    gCollapsed = collapse;
    UIViewAnimationOptions o = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    // Liquid squish: stretch along the motion, then settle with a little wobble.
    void (^wobble)(UIView *, CGFloat, CGFloat, CGFloat) = ^(UIView *v, CGFloat sx, CGFloat sy, CFTimeInterval delay) {
        CAKeyframeAnimation *kx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
        kx.values = @[@1, @(sx), @(1 + (1 - sx) * 0.6), @(1 - (1 - sx) * 0.2), @1];
        CAKeyframeAnimation *ky = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
        ky.values = @[@1, @(sy), @(1 + (1 - sy) * 0.6), @(1 - (1 - sy) * 0.2), @1];
        for (CAKeyframeAnimation *k in @[kx, ky]) {
            k.keyTimes = @[@0, @0.28, @0.55, @0.8, @1]; k.duration = 0.62;
            k.beginTime = CACurrentMediaTime() + delay;
            k.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            k.additive = NO;
        }
        [v.layer addAnimation:kx forKey:@"wx"]; [v.layer addAnimation:ky forKey:@"wy"];
    };
    if (gPillTimer) { [gPillTimer invalidate]; gPillTimer = nil; }
    if (collapse) {
        tab.hidden = search.hidden = pill.hidden = NO;
        tab.transform = search.transform = CGAffineTransformIdentity;
        LayoutCircle(tab, wide); tab.alpha = 0;
        LayoutCircle(search, rightStart); search.alpha = 0;
        ti.alpha = 0;
        [pill refresh];
        pill.frame = miniRect; [pill layoutIfNeeded]; pill.alpha = 0;
        // 1. The bar's glass takes over from Music's tab bar, and Music's mini bar hands over to our pill.
        [UIView animateWithDuration:0.12 delay:0 options:o animations:^{ tab.alpha = 1; tb.alpha = 0; pill.alpha = 1; mini.alpha = 0; } completion:nil];
        // 2. The bar squeezes into the left circle (overshoots a touch, settles).
        [UIView animateWithDuration:0.62 delay:0 usingSpringWithDamping:0.68 initialSpringVelocity:0.6 options:o animations:^{
            LayoutCircle(tab, left);
        } completion:nil];
        wobble(tab, 0.9, 1.12, 0.08);
        [UIView animateWithDuration:0.22 delay:0.2 options:o animations:^{ ti.alpha = 1; } completion:nil];
        // 3. Search buds off the right end and rolls into its own circle.
        [UIView animateWithDuration:0.18 delay:0.04 options:o animations:^{ search.alpha = 1; } completion:nil];
        [UIView animateWithDuration:0.66 delay:0.04 usingSpringWithDamping:0.62 initialSpringVelocity:0.7 options:o animations:^{
            LayoutCircle(search, right);
        } completion:nil];
        wobble(search, 1.18, 0.88, 0.04);
        // 4. The pill drops into the row and narrows.
        [UIView animateWithDuration:0.64 delay:0.02 usingSpringWithDamping:0.72 initialSpringVelocity:0.4 options:o animations:^{
            pill.frame = gCollapsedPill; [pill layoutIfNeeded];
        } completion:nil];
        wobble(pill, 1.05, 0.9, 0.06);
        gPillTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *tm) { [pill refresh]; }];
    } else {
        CGRect miniHome = miniRect;
        [UIView animateWithDuration:0.2 delay:0.16 options:o animations:^{ tb.alpha = 1; } completion:nil];
        [UIView animateWithDuration:0.1 delay:0 options:o animations:^{ ti.alpha = 0; } completion:nil];
        [UIView animateWithDuration:0.56 delay:0 usingSpringWithDamping:0.74 initialSpringVelocity:0.4 options:o animations:^{
            LayoutCircle(tab, wide);
        } completion:nil];
        wobble(tab, 1.06, 0.9, 0.0);
        [UIView animateWithDuration:0.2 delay:0.24 options:o animations:^{ tab.alpha = 0; } completion:^(BOOL d) { if (!gCollapsed) tab.hidden = YES; }];
        [UIView animateWithDuration:0.44 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:o animations:^{
            LayoutCircle(search, rightStart);
        } completion:nil];
        [UIView animateWithDuration:0.18 delay:0.18 options:o animations:^{ search.alpha = 0; } completion:^(BOOL d) { if (!gCollapsed) search.hidden = YES; }];
        // Our pill rises back up to Music's bar and hands over.
        [UIView animateWithDuration:0.56 delay:0 usingSpringWithDamping:0.76 initialSpringVelocity:0.3 options:o animations:^{
            pill.frame = miniHome; [pill layoutIfNeeded];
        } completion:nil];
        [UIView animateWithDuration:0.16 delay:0.32 options:o animations:^{ pill.alpha = 0; mini.alpha = 1; } completion:^(BOOL d) { if (!gCollapsed) pill.hidden = YES; }];
    }
    gCollapseDebug = [NSString stringWithFormat:@"%@ row=%.0f pill=%@ mini=%@", collapse ? @"collapsed" : @"expanded", rowY, NSStringFromCGRect(gCollapsedPill), NSStringFromCGRect(miniRect)];
}
static void SetCollapsedFwd(BOOL c) { SetCollapsed(c, YES); }

@implementation MPCollapse
+ (instancetype)shared { static MPCollapse *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPCollapse new]; }); return t; }
- (void)tapTab { SetCollapsed(NO, YES); }
- (void)tapSearch {
    UITabBar *tb = gLastTabBar;
    UITabBarController *tc = [tb.delegate isKindOfClass:[UITabBarController class]] ? (UITabBarController *)tb.delegate : nil;
    NSUInteger idx = NSNotFound;
    for (NSUInteger i = 0; i < tb.items.count; i++) {
        UITabBarItem *it = tb.items[i];
        if (it.tag == 0 && [it.title.lowercaseString containsString:@"search"]) idx = i;
    }
    if (idx == NSNotFound && tb.items.count) idx = tb.items.count - 1;
    SetCollapsed(NO, YES);
    if (tc && idx < tc.viewControllers.count) {
        UIViewController *vc = tc.viewControllers[idx];
        if (![tc.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)] || [tc.delegate tabBarController:tc shouldSelectViewController:vc]) {
            tc.selectedIndex = idx;
            if ([tc.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) [tc.delegate tabBarController:tc didSelectViewController:vc];
        }
    }
}
@end

#pragma mark - grow while scrolling

static void SetPillExpanded(BOOL expanded) {
    if (gExpanded == expanded) return;
    gExpanded = expanded;
    UITabBar *tb = gLastTabBar;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (!mini || !mini.window || !objc_getAssociatedObject(mini, kStyled)) return;
    CGAffineTransform t = PillTransform(mini);
    // Record first so the watchdog treats this size as ours and doesn't fight it.
    objc_setAssociatedObject(mini, kApplied, [NSValue valueWithCGAffineTransform:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ mini.transform = t; } completion:nil];
}

static void PageScrolled(UIScrollView *sv, CGFloat dy, CGFloat y) {
    static CGFloat acc = 0;
    if ((dy > 0) != (acc > 0)) acc = 0; // direction changed
    acc += dy;
    if (gCollapse) {
        // iOS 26: scrolling down collapses the bars, scrolling back up (or reaching the top) opens them.
        if (y <= -sv.adjustedContentInset.top + 4) { SetCollapsed(NO, YES); return; }
        if (acc > 28) SetCollapsed(YES, YES);
        else if (acc < -28) SetCollapsed(NO, YES);
        return;
    }
    // dy < 0: finger moving down (page moves back toward the top) -> bigger.
    // dy > 0: finger moving up (page moves down) -> normal.
    if (acc < -12) SetPillExpanded(YES);
    else if (acc > 12) SetPillExpanded(NO);
}

%hook UIScrollView
- (void)setContentInset:(UIEdgeInsets)inset {
    // Queue list is slid down 54pt; add 54pt at the bottom so the last song
    // can still scroll fully into view above the trimmed edge.
    if (objc_getAssociatedObject(self, kQueueTable)) inset.bottom += QUEUE_EXTRA;
    %orig(inset);
}
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)event {
    // Touch area follows what's visible: the pill band on top, nothing in the
    // trimmed 54pt at the bottom (so the play controls stay tappable).
    if (objc_getAssociatedObject(self, kQueueTable)) {
        CGRect b = self.bounds;
        return p.x >= CGRectGetMinX(b) && p.x <= CGRectGetMaxX(b) &&
               p.y >= b.origin.y - QUEUE_EXTRA && p.y < b.origin.y + b.size.height - QUEUE_EXTRA;
    }
    return %orig;
}
- (void)setContentOffset:(CGPoint)offset {
    CGPoint old = self.contentOffset;
    %orig;
    if (objc_getAssociatedObject(self, kQueueTable)) { @try { PositionQueueRow(self); } @catch (__unused id e) {} }
    if (!gRound) return;
    // Only the user scrolling a full page: not side-scrolling rows, not small views.
    if (!(self.isTracking || self.isDecelerating)) return;
    if (self.bounds.size.height < 300) return;
    CGFloat dy = offset.y - old.y, dx = offset.x - old.x;
    if (fabs(dy) < 0.5 || fabs(dx) > fabs(dy)) return;
    UITabBar *tb = gLastTabBar;
    if (!tb || self.window != tb.window) return;
    UIViewController *root = self.window.rootViewController;
    if (root.presentedViewController && !root.presentedViewController.isBeingDismissed) return; // full player
    PageScrolled(self, dy, offset.y);
}
%end

%hook UIControl
// Our hidden originals (Play/Shuffle/Download): if Music tries to bring them
// back, keep them invisible. This is what stops the old buttons flickering in.
- (void)setAlpha:(CGFloat)alpha {
    if (alpha > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
// When Music lays out its (hidden) Play/Shuffle, move our row with it right away.
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kHidByUs)) AlbumControlLaidOut(self);
}
%end

%hook UIView
// Music's gray circles we cleared behind the top buttons stay clear.
- (void)setBackgroundColor:(UIColor *)color {
    if (color && gNavGlass && objc_getAssociatedObject(self, kClearedBG)) { %orig(UIColor.clearColor); return; }
    %orig;
    // Round the queue button's background the moment Music colors it, so the
    // square never shows.
    if (color && gQueueLook && self.window) { @try { RoundIfQueueButton(self); } @catch (__unused id e) {} }
}
%end

%hook UINavigationBar
// White top icons; Music sets its red tint per page, which flashed red.
- (void)setTintColor:(UIColor *)color { %orig(gNavGlass ? UIColor.whiteColor : color); }
%end

%hook UIBarButtonItem
- (void)setTintColor:(UIColor *)color { %orig(gNavGlass ? UIColor.whiteColor : color); }
%end

%hook UITabBar
- (void)setAlpha:(CGFloat)a {
    if (gCollapsed && self == gLastTabBar && a > 0.01) { %orig(0); return; }
    %orig;
}
- (void)setHidden:(BOOL)h {
    %orig;
    if (h && gCollapsed && self == gLastTabBar) {
        dispatch_async(dispatch_get_main_queue(), ^{ SetCollapsed(NO, YES); });
    }
}
- (void)setSelectedItem:(UITabBarItem *)it {
    %orig;
    if (gCollapsed && self == gLastTabBar) dispatch_async(dispatch_get_main_queue(), ^{ SetCollapsed(NO, YES); });
}
- (void)layoutSubviews {
    %orig;
    gLastTabBar = self;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UITabBar *weak = self;
    // Run after this layout pass finishes.
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBar *tb = weak;
        if (!tb) return;
        @try { Update(tb); } @catch (__unused id e) {}
        objc_setAssociatedObject(tb, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}
%end


#pragma mark - scrolling title (marquee)

static const void *kMarqText = &kMarqText;
static const void *kHidLabel = &kHidLabel;

static void FindLabels(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (s.tag == MARQUEE_TAG || s.tag == GLASS_TAG || s.hidden) continue;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) [out addObject:s];
        if (depth < 6) FindLabels(s, depth + 1, out);
    }
}

static UIView *FindMarqueeView(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if ([NSStringFromClass([s class]) containsString:@"Marquee"]) return s;
        if (depth < 6) { UIView *f = FindMarqueeView(s, depth + 1); if (f) return f; }
    }
    return nil;
}

static void RemoveMarquee(UILabel *label) {
    UIView *m = [label.superview viewWithTag:MARQUEE_TAG];
    if (m.superview == label.superview) [m removeFromSuperview];
    if (objc_getAssociatedObject(label, kHidLabel)) {
        label.alpha = 1;
        objc_setAssociatedObject(label, kHidLabel, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static UILabel *CopyLabel(UILabel *src) {
    UILabel *l = [UILabel new];
    l.text = src.text;
    l.font = src.font;
    l.textColor = src.textColor;
    [l sizeToFit];
    return l;
}

static void BuildMarquee(UILabel *label, CGFloat textW) {
    UIView *box = [[UIView alloc] initWithFrame:label.frame];
    box.tag = MARQUEE_TAG;
    box.clipsToBounds = YES;
    box.userInteractionEnabled = NO;

    const CGFloat gap = 40;
    UIView *strip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textW * 2 + gap, box.bounds.size.height)];
    UILabel *a = CopyLabel(label), *b = CopyLabel(label);
    CGFloat y = (box.bounds.size.height - a.bounds.size.height) / 2;
    a.frame = CGRectMake(0, y, textW, a.bounds.size.height);
    b.frame = CGRectMake(textW + gap, y, textW, b.bounds.size.height);
    [strip addSubview:a];
    [strip addSubview:b];
    [box addSubview:strip];

    // Soft fade on both edges.
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = box.bounds;
    mask.startPoint = CGPointMake(0, 0.5);
    mask.endPoint = CGPointMake(1, 0.5);
    mask.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
    mask.locations = @[@0, @0.04, @0.92, @1];
    box.layer.mask = mask;

    // Hold, scroll one full loop at a steady speed, repeat. Loops seamlessly
    // because the second copy lands exactly where the first started.
    CGFloat distance = textW + gap;
    CFTimeInterval hold = 2.0, move = distance / 32.0;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    anim.values = @[@0, @0, @(-distance)];
    anim.keyTimes = @[@0, @(hold / (hold + move)), @1];
    anim.duration = hold + move;
    anim.repeatCount = HUGE_VALF;
    anim.removedOnCompletion = NO;
    [strip.layer addAnimation:anim forKey:@"musicpill.marquee"];

    [label.superview insertSubview:box aboveSubview:label];
}

static void MarqueeTick(UIView *mini) {
    if (!mini || !mini.window) return;
    // 1. Apple's own marquee view, if the bar has one: just switch it on.
    UIView *apple = FindMarqueeView(mini, 0);
    if (apple) {
        @try { [apple setValue:@(gMarquee) forKey:@"marqueeEnabled"]; gMarqueeDebug = @"apple marquee"; return; }
        @catch (__unused id e) {}
    }
    // 2. Otherwise our own: the biggest-font label in the bar is the title.
    NSMutableArray *labels = [NSMutableArray array];
    FindLabels(mini, 0, labels);
    UILabel *title = nil;
    for (UILabel *l in labels) if (!title || l.font.pointSize > title.font.pointSize) title = l;
    if (!title) { gMarqueeDebug = @"no label"; return; }

    CGFloat textW = ceil([title.text sizeWithAttributes:@{NSFontAttributeName: title.font}].width);
    BOOL needs = gMarquee && textW > title.bounds.size.width + 1 && title.bounds.size.width > 20;
    UIView *box = [title.superview viewWithTag:MARQUEE_TAG];
    if (box && box.superview != title.superview) box = nil;
    gMarqueeDebug = [NSString stringWithFormat:@"%@ text=%.0f box=%.0f %@", NSStringFromClass([title class]), textW, title.bounds.size.width, needs ? @"scroll" : @"fits"];

    if (!needs) { if (box || objc_getAssociatedObject(title, kHidLabel)) RemoveMarquee(title); return; }

    NSString *sig = [NSString stringWithFormat:@"%@|%.1f|%.1f", title.text, title.bounds.size.width, title.font.pointSize];
    if (!box || ![objc_getAssociatedObject(title, kMarqText) isEqualToString:sig]) {
        [box removeFromSuperview];
        BuildMarquee(title, textW);
        objc_setAssociatedObject(title, kMarqText, sig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        box = [title.superview viewWithTag:MARQUEE_TAG];
    }
    if (!CGRectEqualToRect(box.frame, title.frame)) {
        box.frame = title.frame;
        box.layer.mask.frame = box.bounds;
    }
    if (title.alpha != 0) {
        title.alpha = 0;
        objc_setAssociatedObject(title, kHidLabel, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - iOS 26 album / playlist buttons

static __weak UIControl *gPlayCtl, *gShuffleCtl, *gDownloadCtl;
// The download/checkmark slot in the top bar (leftmost right-hand button).
static __weak UIView *gSlotView;
static BOOL gPortalLive = NO;

static UIControl *FirstControl(UIView *v, int depth) {
    if ([v isKindOfClass:[UIControl class]]) return (UIControl *)v;
    if (depth > 6) return nil;
    for (UIView *s in v.subviews) { UIControl *c = FirstControl(s, depth + 1); if (c) return c; }
    return nil;
}
static __weak UIView *gRowParent;
static CFTimeInterval gLastHeaderSearch;

static UIControl *ControlAbove(UIView *v) {
    int d = 0;
    for (UIView *p = v; p && d < 6; p = p.superview, d++)
        if ([p isKindOfClass:[UIControl class]]) return (UIControl *)p;
    return nil;
}

static BOOL InBottomBars(UIView *v) {
    for (UIView *p = v; p; p = p.superview) {
        if ([p isKindOfClass:[UITabBar class]] || objc_getAssociatedObject(p, kStyled)) return YES;
        NSString *n = NSStringFromClass([p class]);
        if ([n containsString:@"PaletteContainerView"]) return YES;
    }
    return NO;
}

static void FindHeaderControls(UIView *v, int depth, UIControl **play, UIControl **shuffle, UIControl **download) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.tag == ROW_TAG || s.tag == DEBUG_TAG || s.tag == NAVGLASS_TAG) continue;
        if ([s isKindOfClass:[UILabel class]]) {
            NSString *txt = ((UILabel *)s).text;
            if (!*play && [txt isEqualToString:@"Play"]) { UIControl *c = ControlAbove(s); if (c && !InBottomBars(c)) *play = c; }
            else if (!*shuffle && [txt isEqualToString:@"Shuffle"]) { UIControl *c = ControlAbove(s); if (c && !InBottomBars(c)) *shuffle = c; }
        }
        if (!*download && [s isKindOfClass:[UIControl class]] && [s.accessibilityLabel isEqualToString:@"Download"] && !InBottomBars(s))
            *download = (UIControl *)s;
        if (*play && *shuffle && *download) return;
        if (depth < 30) FindHeaderControls(s, depth + 1, play, shuffle, download);
    }
}

static UIView *CommonParent(UIView *a, UIView *b) {
    for (UIView *p = a.superview; p; p = p.superview)
        if ([b isDescendantOfView:p]) return p;
    return nil;
}

static void HideOriginal(UIView *v) {
    if (v.alpha != 0) { v.alpha = 0; objc_setAssociatedObject(v, kHidByUs, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
}
static void ShowOriginal(UIView *v) {
    if (v && objc_getAssociatedObject(v, kHidByUs)) {
        objc_setAssociatedObject(v, kHidByUs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        v.alpha = 1;
    }
}

static void Forward(UIControl *c) {
    if (!c) return;
    UIControlEvents ev = c.allControlEvents;
    if (ev & UIControlEventTouchUpInside) [c sendActionsForControlEvents:UIControlEventTouchUpInside];
    else if (ev & UIControlEventPrimaryActionTriggered) [c sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
}

@interface MPRowTarget : NSObject
+ (instancetype)shared;
@end
@implementation MPRowTarget
+ (instancetype)shared { static MPRowTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPRowTarget new]; }); return t; }
- (void)tap:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b.tag == 1) Forward(gPlayCtl);
    else if (b.tag == 2) Forward(gShuffleCtl);
    else if (b.tag == 3) { UIView *slot = gSlotView; if (slot) Forward(FirstControl(slot, 0)); }
}
@end

static UIButton *RowButton(NSInteger tag, NSString *symbol, NSString *title, BOOL white) {
    UIButtonConfiguration *cfg = white ? [UIButtonConfiguration filledButtonConfiguration] : [UIButtonConfiguration filledButtonConfiguration];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    cfg.baseBackgroundColor = white ? UIColor.whiteColor : [UIColor colorWithWhite:0.20 alpha:1];
    cfg.baseForegroundColor = white ? UIColor.blackColor : UIColor.whiteColor;
    cfg.image = [UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:white ? 17 : 18 weight:UIImageSymbolWeightSemibold]];
    if (title) {
        cfg.title = title;
        cfg.imagePadding = 7;
        cfg.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *in) {
            NSMutableDictionary *d = [in mutableCopy];
            d[NSFontAttributeName] = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
            return d;
        };
    }
    cfg.contentInsets = NSDirectionalEdgeInsetsZero;
    UIButton *b = [UIButton buttonWithConfiguration:cfg primaryAction:nil];
    b.tag = tag;
    [b addTarget:[MPRowTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    if (!white) {
        b.layer.borderWidth = 0.6;
        b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
        b.layer.cornerCurve = kCACornerCurveContinuous;
    }
    return b;
}

static NSHashTable *gPreHidden; // Play/Shuffle hidden early, before the row exists
static CFTimeInterval gPreHideTime;

static void ShowPreHidden(UIControl *keepA, UIControl *keepB) {
    for (UIControl *c in [gPreHidden allObjects]) if (c != keepA && c != keepB) ShowOriginal(c);
    [gPreHidden removeAllObjects];
}

static void TearDownRow(void) {
    UIView *parent = gRowParent;
    [[parent viewWithTag:ROW_TAG] removeFromSuperview];
    ShowOriginal(gPlayCtl); ShowOriginal(gShuffleCtl); ShowOriginal(gDownloadCtl);
    ShowPreHidden(nil, nil);
    gPortalLive = NO;
}

static void AlbumTick(UIWindow *w) {
    if (!w) return;
    if (!gAlbum) { TearDownRow(); gAlbumDebug = @"off"; return; }

    UIControl *play = gPlayCtl, *shuffle = gShuffleCtl;
    BOOL lost = !play || !shuffle || !play.window || !shuffle.window;
    if (lost) {
        CFTimeInterval now = CACurrentMediaTime();
        if (now - gLastHeaderSearch < 0.2) return;
        gLastHeaderSearch = now;
        UIControl *p = nil, *s = nil, *d = nil;
        FindHeaderControls(w, 0, &p, &s, &d);
        if (!p || !s) {
            // One of the pair may not have its label yet. Give it half a second
            // before showing any early-hidden button again (no flash either way).
            if (gPreHidden.count && CACurrentMediaTime() - gPreHideTime < 0.5) { gLastHeaderSearch = 0; return; }
            TearDownRow();
            gPlayCtl = nil; gShuffleCtl = nil; gDownloadCtl = nil;
            gAlbumDebug = [NSString stringWithFormat:@"play=%d shuffle=%d", p != nil, s != nil];
            return;
        }
        gPlayCtl = p; gShuffleCtl = s; gDownloadCtl = d;
        play = p; shuffle = s;
    }
    UIView *parent = CommonParent(play, shuffle);
    // Only take over if the originals can be triggered from our buttons.
    if (!parent || !play.allControlEvents || !shuffle.allControlEvents) {
        TearDownRow();
        gAlbumDebug = [NSString stringWithFormat:@"%@ ev=%lu/%lu parent=%d (can't forward taps)",
                       NSStringFromClass([play class]), (unsigned long)play.allControlEvents, (unsigned long)shuffle.allControlEvents, parent != nil];
        return;
    }
    if (gRowParent && gRowParent != parent) TearDownRow();
    gRowParent = parent;

    UIView *row = [parent viewWithTag:ROW_TAG];
    if (row.superview != parent) row = nil;
    if (!row) {
        row = [UIView new];
        row.tag = ROW_TAG;
        UIView *cover = [UIView new];
        cover.tag = 9;
        cover.backgroundColor = UIColor.systemBackgroundColor;
        cover.userInteractionEnabled = NO;
        [row addSubview:cover];
        [row addSubview:RowButton(2, @"shuffle", nil, NO)];
        [row addSubview:RowButton(1, @"play.fill", @"Play", YES)];
        [row addSubview:RowButton(3, @"arrow.down", nil, NO)];
        [parent addSubview:row];
    }
    [parent bringSubviewToFront:row];

    CGRect pf = [play convertRect:play.bounds toView:parent];
    CGRect sf = [shuffle convertRect:shuffle.bounds toView:parent];
    CGRect u = CGRectUnion(pf, sf);
    CGFloat h = MAX(u.size.height, 40);
    CGRect rf = CGRectMake(u.origin.x, CGRectGetMidY(u) - h / 2, u.size.width, h);
    if (!CGRectEqualToRect(row.frame, rf)) row.frame = rf;
    // Cover exactly where Music's buttons are (not the taller row), so nothing
    // of the old buttons shows even for a frame.
    UIView *cover = [row viewWithTag:9];
    CGRect cf = CGRectOffset(u, -rf.origin.x, -rf.origin.y);
    if (!CGRectEqualToRect(cover.frame, cf)) cover.frame = cf;

    // Right circle: Music's own download control from the top bar, mirrored
    // live, so the arrow, the download progress and the checkmark all show
    // here in the same spot.
    UIView *slot = gSlotView;
    BOOL showDL = slot && slot.window;
    UIButton *bShuffle = [row viewWithTag:2], *bPlay = [row viewWithTag:1], *bDL = [row viewWithTag:3];
    CGFloat W = rf.size.width, gap = 11, playW = MIN(W * 0.45, 220);
    CGFloat x0 = (W - playW) / 2;
    CGRect fs = CGRectMake(x0 - gap - h, 0, h, h), fp = CGRectMake(x0, 0, playW, h), fd = CGRectMake(x0 + playW + gap, 0, h, h);
    if (!CGRectEqualToRect(bShuffle.frame, fs)) bShuffle.frame = fs;
    if (!CGRectEqualToRect(bPlay.frame, fp)) bPlay.frame = fp;
    if (!CGRectEqualToRect(bDL.frame, fd)) bDL.frame = fd;
    bShuffle.layer.cornerRadius = h / 2;
    bDL.layer.cornerRadius = h / 2;
    UIView *portal = nil;
    for (UIView *s in bDL.subviews) if (s.tag == PORTAL_TAG) portal = s;
    if (portal) {
        id src = nil;
        @try { src = [portal valueForKey:@"sourceView"]; } @catch (__unused id e) {}
        if (src != slot || !showDL) { [portal removeFromSuperview]; portal = nil; }
    }
    if (showDL && !portal) {
        Class P = NSClassFromString(@"_UIPortalView");
        if (P && [P instancesRespondToSelector:@selector(initWithSourceView:)]) {
            @try {
                portal = [(UIView *)[P alloc] initWithSourceView:slot];
                [portal setValue:@YES forKey:@"hidesSourceView"];
                @try { [portal setValue:@NO forKey:@"matchesPosition"]; } @catch (__unused id e) {}
                @try { [portal setValue:@NO forKey:@"matchesTransform"]; } @catch (__unused id e) {}
                portal.tag = PORTAL_TAG;
                portal.userInteractionEnabled = NO;
                [bDL addSubview:portal];
            } @catch (__unused id e) { portal = nil; }
        }
    }
    if (portal) {
        CGSize ss = slot.bounds.size;
        CGRect pf2 = CGRectMake(round((h - ss.width) / 2), round((h - ss.height) / 2), ss.width, ss.height);
        if (!CGRectEqualToRect(portal.frame, pf2)) portal.frame = pf2;
    }
    gPortalLive = portal != nil;
    bDL.hidden = !gPortalLive;

    HideOriginal(play);
    HideOriginal(shuffle);
    ShowPreHidden(play, shuffle);
    gAlbumDebug = [NSString stringWithFormat:@"row ok play=%@ slot=%@ portal=%d", NSStringFromClass([play class]), slot ? NSStringFromClass([slot class]) : @"none", gPortalLive];
}

#pragma mark - instant album triggers

static __weak UIWindow *gAlbumWindow;
static BOOL gAlbumPending;

static void ScheduleAlbum(UIWindow *w) {
    if (w) gAlbumWindow = w;
    if (gAlbumPending) return;
    gAlbumPending = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        gAlbumPending = NO;
        UIWindow *win = gAlbumWindow;
        if (win) { @try { AlbumTick(win); } @catch (__unused id e) {} }
    });
}

static void AlbumControlLaidOut(UIControl *c) {
    if (gAlbum && (c == gPlayCtl || c == gShuffleCtl)) ScheduleAlbum(c.window);
}

static BOOL InOurRow(UIView *v) {
    for (UIView *p = v; p; p = p.superview) if (p.tag == ROW_TAG) return YES;
    return NO;
}

// Called the moment a "Play"/"Shuffle" label shows up: hide its button now and
// build the row on this same pass, so the old buttons are never drawn.
static void PreHide(UILabel *label) {
    if (!gAlbum || !label.window || InOurRow(label)) return;
    UIControl *c = ControlAbove(label);
    if (!c || InBottomBars(c)) return;
    if (c != gPlayCtl && c != gShuffleCtl) {
        if (!gPreHidden) gPreHidden = [NSHashTable weakObjectsHashTable];
        HideOriginal(c);
        [gPreHidden addObject:c];
        gPreHideTime = CACurrentMediaTime();
        gLastHeaderSearch = 0; // search immediately, no throttle
    }
    ScheduleAlbum(label.window);
}

static BOOL IsHeaderTitle(NSString *s) {
    return [s isKindOfClass:[NSString class]] && ([s isEqualToString:@"Play"] || [s isEqualToString:@"Shuffle"]);
}

%hook UILabel
- (void)setText:(NSString *)text {
    NSString *mapped = MapQueueText(text);
    %orig(mapped);
    if (gAlbum && IsHeaderTitle(mapped) && self.window) { @try { PreHide(self); } @catch (__unused id e) {} }
}
- (void)setAttributedText:(NSAttributedString *)text {
    if (gQueueLook && text.length) {
        NSString *m = MapQueueText(text.string);
        if (m != text.string) {
            NSMutableAttributedString *x = [text mutableCopy];
            [x replaceCharactersInRange:NSMakeRange(0, x.length) withString:m];
            text = x;
        }
    }
    %orig(text);
}
- (void)didMoveToWindow {
    %orig;
    if (gAlbum && self.window && IsHeaderTitle(self.text)) { @try { PreHide(self); } @catch (__unused id e) {} }
}
%end

#pragma mark - glass top buttons

static __weak UIView *gRightHost;

static void CollectBarButtons(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.tag == NAVGLASS_TAG) continue;
        NSString *n = NSStringFromClass([s class]);
        if ([n containsString:@"ButtonBarButton"] || [n containsString:@"BackButton"]) {
            if (s.bounds.size.width > 2) [out addObject:s];
            continue;
        }
        if (depth < 6) CollectBarButtons(s, depth + 1, out);
    }
}

static UIView *GlyphIn(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.bounds.size.width < 2 || s.tag == NAVGLASS_TAG) continue;
        if ([s isKindOfClass:[UIImageView class]] && ((UIImageView *)s).image) return s;
        if (depth < 5) { UIView *g = GlyphIn(s, depth + 1); if (g) return g; }
    }
    return nil;
}

// Music's own gray circles behind its top buttons: clear them once. The
// setBackgroundColor hook below keeps them clear, so they can't flash back.
static void ClearCircles(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UIImageView class]] || [s isKindOfClass:[UILabel class]] || s.tag == NAVGLASS_TAG) continue;
        if (!objc_getAssociatedObject(s, kClearedBG) && s.backgroundColor && CGColorGetAlpha(s.backgroundColor.CGColor) > 0.01 &&
            fabs(s.bounds.size.width - s.bounds.size.height) < 3 && s.bounds.size.width >= 20) {
            objc_setAssociatedObject(s, kClearedBG, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            s.backgroundColor = UIColor.clearColor;
        }
        if (depth < 4) ClearCircles(s, depth + 1);
    }
}

static UIView *GlassIn(UIView *host) {
    for (UIView *s in host.subviews) if (s.tag == NAVGLASS_TAG) return s;
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    g.tag = NAVGLASS_TAG;
    g.userInteractionEnabled = NO;
    g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75;
    g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    [host insertSubview:g atIndex:0];
    return g;
}

static void RemoveGlass(UIView *v, int depth) {
    for (UIView *s in [v.subviews copy]) {
        if (s.tag == NAVGLASS_TAG) { [s removeFromSuperview]; continue; }
        if (depth < 8) RemoveGlass(s, depth + 1);
    }
}

static void SetFrameIfNew(UIView *v, CGRect f, CGFloat radius) {
    if (!CGRectEqualToRect(v.frame, f)) v.frame = f;
    if (v.layer.cornerRadius != radius) v.layer.cornerRadius = radius;
}

// Glass goes right behind the icon, in the icon's own container, so it moves
// and fades with the button during transitions and never covers the icon.
static UIView *GlassBelow(UIView *glyph) {
    UIView *host = glyph.superview;
    UIView *g = nil;
    for (UIView *s in host.subviews) if (s.tag == NAVGLASS_TAG) { g = s; break; }
    if (!g) {
        UIVisualEffectView *e = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        e.tag = NAVGLASS_TAG;
        e.userInteractionEnabled = NO;
        e.clipsToBounds = YES;
        e.layer.cornerCurve = kCACornerCurveContinuous;
        e.layer.borderWidth = 0.75;
        e.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
        g = e;
        [host insertSubview:g belowSubview:glyph];
    } else if ([host.subviews indexOfObject:g] > [host.subviews indexOfObject:glyph]) {
        [host insertSubview:g belowSubview:glyph];
    }
    return g;
}

static void NavTick(UINavigationBar *nb) {
    if (!nb || !nb.window) return;
    if (!gNavGlass) { RemoveGlass(nb, 0); gNavDebug = @"off"; return; }
    if (![nb.tintColor isEqual:UIColor.whiteColor]) nb.tintColor = UIColor.whiteColor;

    NSMutableArray *buttons = [NSMutableArray array];
    CollectBarButtons(nb, 0, buttons);
    CGFloat mid = nb.bounds.size.width / 2;
    const CGFloat H = 34;          // iOS 26 top buttons are ~34pt
    const CGFloat edge = 12;       // keep circles off the screen edge
    NSMutableArray *right = [NSMutableArray array];
    for (UIView *b in buttons) {
        ClearCircles(b, 0);
        UIView *g = GlyphIn(b, 0);
        CGRect inNav = [(g ?: b) convertRect:(g ?: b).bounds toView:nb];
        if (CGRectGetMidX(inNav) < mid) {
            if (!g) continue;
            // Nudge the back button right so its circle doesn't hit the edge.
            CGFloat untransformedMid = CGRectGetMidX(inNav) - b.transform.tx;
            CGFloat tx = MAX(0, round(edge + H / 2 - untransformedMid));
            if (b.transform.tx != tx) b.transform = CGAffineTransformMakeTranslation(tx, 0);
            CGRect r = g.frame;
            SetFrameIfNew(GlassBelow(g), CGRectMake(round(CGRectGetMidX(r) - H / 2), round(CGRectGetMidY(r) - H / 2), H, H), H / 2);
        } else {
            [right addObject:b];
        }
    }
    [right sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = CGRectGetMinX([a convertRect:a.bounds toView:nb]), y = CGRectGetMinX([b convertRect:b.bounds toView:nb]);
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    // Leftmost of 2+ right-hand buttons is the add/download/checkmark slot.
    gSlotView = right.count >= 2 ? right.firstObject : nil;
    if (gPortalLive && right.count >= 2) [right removeObjectAtIndex:0]; // shown in the album row instead

    UIView *host = nil, *single = nil;
    if (right.count == 1) { single = GlyphIn(right.firstObject, 0); host = single.superview; }
    else if (right.count > 1) {
        host = [right.firstObject superview];
        for (UIView *b in right) while (host && ![b isDescendantOfView:host]) host = host.superview;
    }
    UIView *old = gRightHost;
    if (old && old != host) for (UIView *s in [old.subviews copy]) if (s.tag == NAVGLASS_TAG) [s removeFromSuperview];
    gRightHost = host;
    if (single) {
        CGRect r = single.frame;
        CGFloat w = MAX(H, r.size.width + 16);
        SetFrameIfNew(GlassBelow(single), CGRectMake(round(CGRectGetMidX(r) - w / 2), round(CGRectGetMidY(r) - H / 2), round(w), H), H / 2);
    } else if (host) {
        CGRect u = CGRectNull;
        for (UIView *b in right) {
            UIView *g = GlyphIn(b, 0) ?: b;
            u = CGRectUnion(u, [g convertRect:g.bounds toView:host]);
        }
        CGFloat w = MAX(H, u.size.width + 28);
        SetFrameIfNew(GlassIn(host), CGRectMake(round(CGRectGetMidX(u) - w / 2), round(CGRectGetMidY(u) - H / 2), round(w), H), H / 2);
    }
    gNavDebug = [NSString stringWithFormat:@"%lu buttons, %lu right, slot=%d", (unsigned long)buttons.count, (unsigned long)right.count, gSlotView != nil];
}

static UINavigationBar *TopNavBar(UIWindow *w) {
    UIViewController *vc = w.rootViewController;
    while (vc.presentedViewController && !vc.presentedViewController.isBeingDismissed) vc = vc.presentedViewController;
    if ([vc isKindOfClass:[UITabBarController class]]) vc = ((UITabBarController *)vc).selectedViewController;
    if ([vc isKindOfClass:[UINavigationController class]]) return ((UINavigationController *)vc).navigationBar;
    return vc.navigationController.navigationBar;
}

// Opening and closing the full player resets the bar without laying out the
// tab bar again, so nothing re-shrank it. Check a few times a second (cheap:
// it only compares a transform) and re-apply once the bar is settled.
#pragma mark - iOS 26 queue pill row

static __weak UIControl *gQShuffle, *gQRepeat, *gQAuto;
static __weak UIScrollView *gQueueTable;

static UIView *FindQueueHeader(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden) continue;
        if ([NSStringFromClass([s class]) containsString:@"NowPlayingQueueHeaderView"]) return s;
        if (depth < 22) { UIView *f = FindQueueHeader(s, depth + 1); if (f) return f; }
    }
    return nil;
}

static void CollectControls(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UIControl class]]) { [out addObject:s]; continue; }
        if (depth < 8) CollectControls(s, depth + 1, out);
    }
}

// A header button is "on" if it's selected or has a filled background (Music
// draws active toggles with a red rounded square behind the icon).
static BOOL ToggleOn(UIControl *c) {
    if (!c) return NO;
    if (c.isSelected) return YES;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:c];
    int n = 0;
    while (stack.count && n++ < 40) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v != c && v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0.3 &&
            v.bounds.size.width >= c.bounds.size.width * 0.7) return YES;
        [stack addObjectsFromArray:v.subviews];
    }
    return NO;
}

static void StyleQueuePill(UIButton *b, NSString *symbol, BOOL on) {
    UIButtonConfiguration *cfg = b.configuration ?: [UIButtonConfiguration filledButtonConfiguration];
    UIColor *bg = on ? [UIColor colorWithWhite:0.56 alpha:1] : [UIColor colorWithWhite:0.17 alpha:1];
    UIColor *fg = on ? UIColor.blackColor : UIColor.whiteColor;
    if ([cfg.baseBackgroundColor isEqual:bg] && [cfg.baseForegroundColor isEqual:fg] &&
        [objc_getAssociatedObject(b, kQueueTable) isEqual:symbol]) return;
    cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    cfg.baseBackgroundColor = bg;
    cfg.baseForegroundColor = fg;
    cfg.image = [UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]];
    cfg.contentInsets = NSDirectionalEdgeInsetsZero;
    b.configuration = cfg;
    objc_setAssociatedObject(b, kQueueTable, symbol, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Repeat One: Music's repeat button switches to the "repeat.1" symbol.
static BOOL ImageIsRepeatOne(UIImage *img) {
    return img && [img.description containsString:@"repeat.1"];
}
static BOOL RepeatOneOn(UIControl *c) {
    if (!c) return NO;
    if ([c isKindOfClass:[UIButton class]] && ImageIsRepeatOne(((UIButton *)c).currentImage)) return YES;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:c];
    int n = 0;
    while (stack.count && n++ < 40) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:[UIImageView class]] && ImageIsRepeatOne(((UIImageView *)v).image)) return YES;
        [stack addObjectsFromArray:v.subviews];
    }
    NSString *val = c.accessibilityValue.lowercaseString;
    if ([val containsString:@"one"] || [val containsString:@"song"] || [val containsString:@"1"]) return YES;
    return [MPMusicPlayerController systemMusicPlayer].repeatMode == MPMusicRepeatModeOne;
}

static void RefreshQueueRow(void) {
    UIScrollView *table = gQueueTable;
    UIView *row = nil;
    for (UIView *s in table.subviews) if (s.tag == QUEUEROW_TAG) row = s;
    if (!row) return;
    BOOL repeatOne = RepeatOneOn(gQRepeat);
    StyleQueuePill([row viewWithTag:11], @"shuffle", ToggleOn(gQShuffle));
    StyleQueuePill([row viewWithTag:12], repeatOne ? @"repeat.1" : @"repeat", repeatOne || ToggleOn(gQRepeat));
    StyleQueuePill([row viewWithTag:13], @"infinity", ToggleOn(gQAuto));
    [row viewWithTag:13].hidden = gQAuto == nil;
}

@interface MPQueueTarget : NSObject
+ (instancetype)shared;
@end
@implementation MPQueueTarget
+ (instancetype)shared { static MPQueueTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPQueueTarget new]; }); return t; }
- (void)tap:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIControl *c = b.tag == 11 ? gQShuffle : (b.tag == 12 ? gQRepeat : gQAuto);
    Forward(c);
    // Music updates its button a moment later; mirror it quickly.
    dispatch_async(dispatch_get_main_queue(), ^{ RefreshQueueRow(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RefreshQueueRow(); });
}
@end

static __weak UIView *gQueueHeader;

static void LayoutPillButtons(UIView *row) {
    CGFloat pad = 20, gap = 10, h = 40, n = 3, W = row.bounds.size.width;
    CGFloat w = (W - pad * 2 - gap * (n - 1)) / n;
    for (int i = 0; i < 3; i++) {
        UIView *b = [row viewWithTag:11 + i];
        CGRect bf = CGRectMake(pad + i * (w + gap), (QUEUE_EXTRA - h) / 2, w, h);
        if (!CGRectEqualToRect(b.frame, bf)) b.frame = bf;
    }
}

static CGAffineTransform QueueShift(void) { return CGAffineTransformMakeTranslation(0, QUEUE_EXTRA); }

// The pill row lives inside the list, in the 54pt just above what's scrolled
// into view. With the list slid down 54pt, that band lands exactly where the
// top of the list used to be, and it moves/fades with the list.
static void PositionQueueRow(UIScrollView *list) {
    UIView *row = nil;
    for (UIView *s in list.subviews) if (s.tag == QUEUEROW_TAG) row = s;
    if (!row) return;
    CGRect b = list.bounds;
    CGRect f = CGRectMake(0, b.origin.y - QUEUE_EXTRA, b.size.width, QUEUE_EXTRA);
    if (!CGRectEqualToRect(row.frame, f)) row.frame = f;
    if (list.subviews.lastObject != row) [list bringSubviewToFront:row];
    LayoutPillButtons(row);

    // Slide the list down (only if Music isn't using the transform itself).
    CGAffineTransform shift = QueueShift();
    if (CGAffineTransformIsIdentity(list.transform)) list.transform = shift;
    if (list.clipsToBounds) list.clipsToBounds = NO;

    // Show: the pill band + the list minus its bottom 54pt.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    CALayer *mask = list.layer.mask;
    if (!mask) { mask = [CALayer layer]; mask.backgroundColor = UIColor.blackColor.CGColor; list.layer.mask = mask; }
    CGRect mf = CGRectMake(0, b.origin.y - QUEUE_EXTRA, b.size.width, b.size.height);
    if (!CGRectEqualToRect(mask.frame, mf)) mask.frame = mf;
    [CATransaction commit];
}

static void UnflagQueueTable(UIScrollView *list) {
    if (!list || !objc_getAssociatedObject(list, kQueueTable)) return;
    for (UIView *s in [list.subviews copy]) if (s.tag == QUEUEROW_TAG) [s removeFromSuperview];
    objc_setAssociatedObject(list, kQueueTable, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIEdgeInsets i = list.contentInset; i.bottom -= QUEUE_EXTRA; list.contentInset = i;
    if (CGAffineTransformEqualToTransform(list.transform, QueueShift())) list.transform = CGAffineTransformIdentity;
    list.layer.mask = nil;
    NSNumber *clip = objc_getAssociatedObject(list, kQueuePad);
    if (clip) list.clipsToBounds = clip.boolValue;
    ShowOriginal(gQShuffle); ShowOriginal(gQRepeat); ShowOriginal(gQAuto);
}

static void QueueTick(UIView *player) {
    UIView *header = gQueueLook ? FindQueueHeader(player, 0) : nil;
    UIScrollView *table = nil;
    for (UIView *p = header.superview; p; p = p.superview) if ([p isKindOfClass:[UIScrollView class]]) { table = (UIScrollView *)p; break; }
    UIScrollView *old = gQueueTable;
    if (old && old != table) UnflagQueueTable(old);
    if (!header || !table) { gQueueTable = nil; gQueueDebug = header ? @"no table" : @"no header"; return; }

    NSMutableArray *ctls = [NSMutableArray array];
    CollectControls(header, 0, ctls);
    [ctls sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = [a convertRect:a.bounds toView:nil].origin.x, y = [b convertRect:b.bounds toView:nil].origin.x;
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    UIControl *sh = nil, *rp = nil, *ap = nil;
    for (UIControl *c in ctls) {
        NSString *n = NSStringFromClass([c class]).lowercaseString;
        if ([n containsString:@"shuffle"]) sh = c;
        else if ([n containsString:@"repeat"]) rp = c;
        else if ([n containsString:@"autoplay"] || [n containsString:@"infinit"]) ap = c;
    }
    // Fall back to left-to-right order: shuffle, repeat, autoplay.
    if (!sh && ctls.count >= 1) sh = ctls[0];
    if (!rp && ctls.count >= 2) rp = ctls[1];
    if (!ap && ctls.count >= 3) ap = ctls[2];
    if (!sh || !rp || !sh.allControlEvents || !rp.allControlEvents) {
        UnflagQueueTable(table);
        gQueueTable = nil;
        gQueueDebug = [NSString stringWithFormat:@"header ok, %lu controls, can't forward", (unsigned long)ctls.count];
        return;
    }
    gQShuffle = sh; gQRepeat = rp; gQAuto = ap;
    gQueueTable = table;
    gQueueHeader = header;

    if (!objc_getAssociatedObject(table, kQueueTable)) {
        objc_setAssociatedObject(table, kQueuePad, @(table.clipsToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(table, kQueueTable, @"shift", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        table.contentInset = table.contentInset;   // through the hook: +54 at the bottom
        UIView *row = [UIView new];
        row.tag = QUEUEROW_TAG;
        // Solid background so the list never shows through behind the pills.
        UIColor *bg = table.backgroundColor;
        row.backgroundColor = (bg && CGColorGetAlpha(bg.CGColor) > 0.9) ? bg : UIColor.blackColor;
        for (int i = 0; i < 3; i++) {
            UIButton *b = [UIButton buttonWithConfiguration:[UIButtonConfiguration filledButtonConfiguration] primaryAction:nil];
            b.tag = 11 + i;
            [b addTarget:[MPQueueTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            [row addSubview:b];
        }
        [table addSubview:row];
    }
    HideOriginal(sh); HideOriginal(rp); if (ap) HideOriginal(ap);
    PositionQueueRow(table);
    RefreshQueueRow();
    gQueueDebug = [NSString stringWithFormat:@"row ok (%@, %@) %@ / %@ / %@", objc_getAssociatedObject(table, kQueueTable), NSStringFromClass([table class]),
                   NSStringFromClass([sh class]), NSStringFromClass([rp class]), ap ? NSStringFromClass([ap class]) : @"-"];
}

#pragma mark - full player

static void SweepQueueButtons(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden || [s isKindOfClass:[UIScrollView class]]) continue;
        RoundIfQueueButton(s);
        if (depth < 14) SweepQueueButtons(s, depth + 1);
    }
}

static NSString *ShortName(UIView *v) {
    NSString *n = NSStringFromClass([v class]);
    NSRange dot = [n rangeOfString:@"." options:NSBackwardsSearch];
    if (dot.location != NSNotFound) n = [n substringFromIndex:dot.location + 1];
    if (n.length > 30) n = [@"…" stringByAppendingString:[n substringFromIndex:n.length - 29]];
    return n;
}

static void MapPlayer(UIView *v, UIWindow *w, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (out.count >= 34) return;
        if (s.hidden || s.alpha < 0.01 || s.tag == PLAYERDEBUG_TAG) continue;
        BOOL isCtl = [s isKindOfClass:[UIControl class]];
        BOOL isHeader = [s isKindOfClass:[UILabel class]] &&
            ([((UILabel *)s).text isEqualToString:@"Continue Playing"] || [((UILabel *)s).text isEqualToString:@"Playing Next"]);
        if (isCtl || isHeader) {
            CGRect r = [s convertRect:s.bounds toView:w];
            NSString *ax = s.accessibilityLabel ?: (isHeader ? ((UILabel *)s).text : @"");
            NSString *chain = [NSString stringWithFormat:@"%@<%@", ShortName(s.superview), ShortName(s.superview.superview)];
            [out addObject:[NSString stringWithFormat:@"%@ '%@' %.0f,%.0f %.0fx%.0f in %@",
                            ShortName(s), ax, r.origin.x, r.origin.y, r.size.width, r.size.height, chain]];
        }
        if (isCtl) continue;
        if (depth < 18) MapPlayer(s, w, depth + 1, out);
    }
}

static void PlayerDebug(UIView *player, UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:PLAYERDEBUG_TAG];
    if (!gDebug || !player) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = PLAYERDEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:8.5 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.88];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSMutableArray *lines = [NSMutableArray array];
    MapPlayer(player, w, 0, lines);
    NSString *text = [NSString stringWithFormat:@" MusicPill player map (open the queue, screenshot this)\n queue: %@\n %@", gQueueDebug, [lines componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 16;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(8, 50, width, MIN(s.height + 6, w.bounds.size.height - 100));
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

static void StartWatchdog(void) {
    static int tick = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
        tick++;
        UITabBar *tb = gLastTabBar;
        UIWindow *w = tb.window;
        UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
        UIViewController *root = w.rootViewController;
        BOOL playerUp = root.presentedViewController && !root.presentedViewController.isBeingDismissed;

        // Keep the pill small.
        if (gRound && mini && mini.window && !mini.hidden && mini.alpha >= 0.01 &&
            !mini.layer.animationKeys.count && !playerUp && objc_getAssociatedObject(mini, kStyled)) {
            @try {
                CGFloat r = mini.bounds.size.height / 2;
                if (mini.layer.cornerRadius != r) mini.layer.cornerRadius = r;
                ApplyPillTransform(mini, YES);
            } @catch (__unused id e) {}
        }
        // Scrolling title.
        if (mini && !playerUp) { @try { MarqueeTick(mini); } @catch (__unused id e) {} }
        // Album/playlist buttons and glass top buttons.
        if (w && !playerUp) {
            @try { AlbumTick(w); } @catch (__unused id e) {}
            @try { NavTick(TopNavBar(w)); } @catch (__unused id e) {}
        }
        // Full player: round queue button (backup for the hook) + debug map.
        UIView *player = nil;
        if (w && PlayerIsUp(w, &player)) {
            @try { SweepQueueButtons(player, 0); } @catch (__unused id e) {}
            @try { QueueTick(player); } @catch (__unused id e) {}
            if (tick % 4 == 0) { @try { PlayerDebug(player, w); } @catch (__unused id e) {} }
        } else if (w) {
            [[w viewWithTag:PLAYERDEBUG_TAG] removeFromSuperview];
        }
        // Keep the debug box current.
        if (gDebug && tb && tick % 4 == 0) { @try { Update(tb); } @catch (__unused id e) {} }
    }];
}

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.Music"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
    dispatch_async(dispatch_get_main_queue(), ^{ StartWatchdog(); });
}
