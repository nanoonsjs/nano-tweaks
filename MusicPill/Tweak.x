// MusicPill 0.5.2 - made by nano
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
#import <MediaPlayer/MediaPlayer.h>

#define DOM CFSTR("com.user.musicpill")
#define DOM_NS @"com.user.musicpill"
#define NOTIFY CFSTR("com.user.musicpill/prefschanged")
#define DEBUG_TAG 0x4D504442
#define GLASS_TAG 0x4D50474C

static BOOL gRename = YES, gRound = YES, gDebug = NO, gSwipe = YES;
// The see-through background is always on (no longer a setting).
static const BOOL gHideBG = YES;
// Fixed at Small (the size picked in Settings in 0.5.0). 0 Normal, 1 Compact, 2 Small.
static const int gSize = 2;
static NSString *gPrefsSource = @"defaults";
static __weak UITabBar *gLastTabBar;

static const void *kMini = &kMini;
static const void *kBusy = &kBusy;
static const void *kHome = &kHome;
static const void *kStyled = &kStyled;
static const void *kHiddenBG = &kHiddenBG;
static const void *kApplied = &kApplied;
static const void *kSwipeAdded = &kSwipeAdded;

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
}

static void Update(UITabBar *tb);

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

static CGAffineTransform PillTransform(UIView *m) {
    CGFloat W = m.bounds.size.width, H = m.bounds.size.height;
    // Total horizontal inset for Normal / Compact / Small.
    CGFloat inset = gSize == 0 ? 24 : (gSize == 1 ? 56 : 96);
    CGFloat s = W > inset + 100 ? (W - inset) / W : 1;
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
        if (sub == tb || sub.tag == DEBUG_TAG || sub.tag == GLASS_TAG || [sub isKindOfClass:[UIScrollView class]]) continue;
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
    if (!gDebug) { [l removeFromSuperview]; return; }
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
    NSString *text = [NSString stringWithFormat:@" MusicPill 0.5.2 debug\n prefs: %@\n rename=%d round=%d size=%d swipe=%d\n tab y=%.0f h=%.0f\n PICKED: %@\n %@",
                      gPrefsSource, gRename, gRound, gSize, gSwipe,
                      CGRectGetMinY(tabRect), tabRect.size.height, found,
                      [c componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(12, 110, width, s.height + 8);
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

#pragma mark - driver

static void Update(UITabBar *tb) {
    FixTabItems(tb);
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
            UIView *found = FindByName(root, root, tabRect, tb, 0) ?: FindByShape(root, root, tabRect, tb, 0);
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

%hook UITabBar
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

// Opening and closing the full player resets the bar without laying out the
// tab bar again, so nothing re-shrank it. Check a few times a second (cheap:
// it only compares a transform) and re-apply once the bar is settled.
static void StartWatchdog(void) {
    [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        if (!gRound) return;
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
        UITabBar *tb = gLastTabBar;
        if (!tb) return;
        UIView *mini = objc_getAssociatedObject(tb, kMini);
        if (!mini || !mini.window || mini.hidden || mini.alpha < 0.01) return;
        if (mini.layer.animationKeys.count) return; // let Music's animation finish first
        // Don't touch it while the full player is up.
        UIViewController *root = mini.window.rootViewController;
        if (root.presentedViewController && !root.presentedViewController.isBeingDismissed) return;
        if (!objc_getAssociatedObject(mini, kStyled)) return;
        @try {
            CGFloat r = mini.bounds.size.height / 2;
            if (mini.layer.cornerRadius != r) mini.layer.cornerRadius = r;
            ApplyPillTransform(mini, YES);
        } @catch (__unused id e) {}
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
