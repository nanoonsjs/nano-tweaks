// Photos26 2.3.0 - made by nano
// 2.3.0: light mode (frosted light glass, dark icons), the photo viewer's top
//        bar is glass again (viewer found without the "Edit" label; Edit stays
//        hidden, it's the bottom sliders icon), liquid drop on Years / Months /
//        Days / All Photos when you switch.
// 2.2.1: works after a reboot: buttons recognised without VoiceOver labels, and
//        the Photos-class hooks keep retrying until Photos has loaded them.
// 2.1.1: the Years/Months/Days bar is styled the moment it appears (hooked
//        directly, no flicker on launch) and the dark backdrop behind it is
//        hidden too.
// 2.1.0: Years / Months / Days / All Photos bar: compact liquid glass pill
//        that hides when you scroll up and bounces back when you scroll down.
// 2.0.2: grid top buttons drawn entirely by us inside Apple's button (Apple's
//        pieces only hidden, never moved or resized): no flicker while
//        scrolling, full "Select" text, gap to ... in Library and Albums.
// 2.0.1: X shows on Cancel, Select bigger and spaced from ..., select bar
//        never flashes when opening a photo (needs Apple's selection label).
// 2.0.0: grid top buttons (PXCuratedLibraryOverlayButton) styled from inside
//        each button: glass Select capsule, glass X for Cancel, bigger glass
//        ... circle, larger touch areas; select bar pinned to a fixed spot
//        on screen (no slide-down when Apple moves the toolbar).
// 1.9.0: select bar draws its own share / trash (pressing Apple's), so Apple
//        rebuilding its buttons can't flicker; bar height locked while
//        selecting; grid top glass removed again (debug map of it instead).
// 1.8.0: no flicker when Select opens (Apple's share / trash icons ride
//        inside the splitting circles), grid top buttons on liquid glass:
//        Select capsule (bigger touch area), Cancel -> glass X, bigger ...
// 1.7.0: select bar like iOS 26 (51pt circles, small round pill that hugs
//        its text, icons centered in their circles, extra ... hidden), the
//        split animation replays every time Select opens, middle pill shows
//        "N Selected" (iOS 16 has no show-only-selected view to open).
// 1.6.0: select mode found by "no thumbnail strip on screen" (the viewer
//        always has one), so no video player / edit there; select bar sized
//        like the tab pill; liquid split animation when Select opens.
// 1.5.0: select mode in the grid gets the iOS 26 bar (glass share / trash
//        circles, "Show Selected (N)" capsule) and no video player; jelly only
//        on share, trash and back; favorite burst animation; the timer shows
//        the length to the hundredth (00:05.83).
// 1.4.0: hold the video slider: the player turns into a big iOS 26 timer
//        (elapsed 00:01.30 on the left, length on the right, thick bar);
//        jelly runs on real spring physics every frame (no more janky
//        restarted animations).
// 1.3.0: thumbnails rounded the moment they appear (PUTilingView hook), smooth
//        slow scrubbing (one seek at a time, chasing the finger), bigger video
//        slider, iOS 26 jelly on every glass button (swells, leans toward your
//        finger, wobbles back), top back / ... circles jelly too.
// 1.2.0: videos stay one thumbnail in the strip (PUScrubberView never
//        expands), playhead hidden, rounded thumbnail tiles, trash circle
//        fixed, white top icons, liquid wobble on the top glass when you
//        swipe to another photo, seamless video looping.
// 1.1.0: rounded iOS 26 thumbnails, playhead line hidden, Recently Deleted
//        (no gray bars, glass Delete / Recover, glass top), back-arrow circle,
//        thumbnail strip map in debug to stop the video frame spread next.
// 1.0.3: the top "..." is now whichever right button isn't Edit, so the top
//        glass (back circle, date capsule, ... circle) shows and Edit hides.
// 1.0.2: no gray bar backgrounds top or bottom, thumbnails always shown,
//        slider moves relative to your drag (like Apple's), Edit found
//        directly when the adjust button is tapped.
// 1.0.1: player capsule only for videos, scrubber finds the real player
//        (asset duration, on-screen layer), Apple's frame strip hidden while
//        ours works, top glass fixed, smaller glass buttons.
// iOS 26 style photo/video viewer for iOS 16 Photos:
//  Bottom: [share circle]  [heart | info | adjust]  [trash circle]
//  Videos: a floating glass player above the thumbnails:
//          [play]  [scrubber]  [mute]
//  Top:    glass circle behind back, glass capsule behind the date,
//          glass circle behind "...", Edit moves to the bottom (adjust).
//
// How it stays safe:
//  - Apple's buttons are never moved or re-laid-out. Their views are hidden
//    with an empty layer mask, and our own buttons call Apple's buttons, so
//    every action (share sheet, delete sheet, favorite...) is Apple's own.
//  - Our views live inside the toolbar / nav bar, so they show and hide with
//    Apple's chrome (tap the photo to hide the bars).
//  - Frames are set only when they change, with a busy flag against re-entry.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
// Light mode: clear frosted glass, dark icons. Dark mode: dark glass, white icons.
static UIColor *Dyn(UIColor *light, UIColor *dark) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) { return tc.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light; }];
}
static UIColor *GIcon(void) { static UIColor *c; if (!c) c = Dyn(UIColor.blackColor, UIColor.whiteColor); return c; }

@interface PUTilingView : UIView @end
@interface PXCuratedLibraryOverlayButton : UIView @end
@interface _PXUIScrollView : UIScrollView @end
@interface _PXCuratedLibraryZoomLevelSegmentedControl : UIView @end
#define DOM_NS @"com.user.photos26"
#define DOM CFSTR("com.user.photos26")
#define NOTIFY CFSTR("com.user.photos26/prefschanged")
#define BOTTOM_TAG 0x50473630
#define TOP_TAG    0x50473631
#define DEBUG_TAG  0x50473632

static BOOL gEnabled = YES, gTopBar = YES, gPlayer = YES, gDebug = NO, gLoop = YES;

static const void *kMasked = &kMasked;
static const void *kBusy = &kBusy;
static const void *kStyled = &kStyled;
static const void *kShift = &kShift;

#pragma mark - prefs

// Photos is sandboxed and can't read our prefs through cfprefsd, so read the
// plist file directly (Dopamine keeps tweak prefs under /var/jb), then fall back.
static NSDictionary *ReadPrefsFile(void) {
    NSDictionary *best = nil; NSDate *bestDate = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSString *p = [dir stringByAppendingFormat:@"%@.plist", DOM_NS];
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p];
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        NSDate *m = [[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil][NSFileModificationDate];
        if (!best || (m && bestDate && [m compare:bestDate] == NSOrderedDescending)) { best = d; bestDate = m; }
    }
    return best;
}
static BOOL PrefBool(NSDictionary *f, NSString *key, BOOL def) {
    id v = f[key];
    if (!v) { CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)key, DOM); if (cf) v = (__bridge_transfer id)cf; }
    return v ? [v boolValue] : def;
}
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = ReadPrefsFile();
    gEnabled = PrefBool(f, @"enabled", YES);
    gTopBar  = PrefBool(f, @"topbar", YES);
    gPlayer  = PrefBool(f, @"player", YES);
    gDebug   = PrefBool(f, @"debug", NO);
    gLoop    = PrefBool(f, @"loop", YES);
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{ LoadPrefs(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ LoadPrefs(); });
}

#pragma mark - helpers

static id KV(id obj, NSString *key) {
    if (!obj) return nil;
    @try { return [obj valueForKey:key]; } @catch (__unused id e) { return nil; }
}
// Frames are only set when they change; while a view is mid-jelly (has a
// transform) its size and center are set instead, so the wobble isn't broken.
static void SetFrame(UIView *v, CGRect r) {
    if (CGAffineTransformIsIdentity(v.transform)) { if (!CGRectEqualToRect(v.frame, r)) v.frame = r; return; }
    CGRect b = CGRectMake(0, 0, r.size.width, r.size.height);
    if (!CGRectEqualToRect(v.bounds, b)) v.bounds = b;
    CGPoint c = CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
    if (!CGPointEqualToPoint(v.center, c)) v.center = c;
}
static void Mask(UIView *v) {
    if (!v || objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = [CALayer layer];
    objc_setAssociatedObject(v, kMasked, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void Unmask(UIView *v) {
    if (!v || !objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = nil;
    objc_setAssociatedObject(v, kMasked, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// What a bar item is, from its label and its SF Symbol name.
static NSString *ItemKind(UIBarButtonItem *it) {
    NSMutableString *s = [NSMutableString string];
    if (it.accessibilityLabel) [s appendString:it.accessibilityLabel];
    if (it.title) [s appendString:it.title];
    UIImage *img = it.image;
    UIView *v = KV(it, @"view");
    if (!img && [it.customView isKindOfClass:[UIButton class]]) img = [(UIButton *)it.customView imageForState:UIControlStateNormal];
    if (img) [s appendString:img.description];
    if (v.accessibilityLabel) [s appendString:v.accessibilityLabel];
    // After a reboot VoiceOver labels are empty until accessibility loads, so the
    // system item type and the symbol drawn inside the button count too.
    @try {
        NSNumber *sys = [it valueForKey:@"systemItem"];
        if ([sys isKindOfClass:[NSNumber class]]) switch (sys.integerValue) {
            case UIBarButtonSystemItemAction: [s appendString:@" share"]; break;
            case UIBarButtonSystemItemTrash: [s appendString:@" trash"]; break;
            case UIBarButtonSystemItemPlay: [s appendString:@" play"]; break;
            case UIBarButtonSystemItemPause: [s appendString:@" pause"]; break;
            case UIBarButtonSystemItemEdit: [s appendString:@" edit"]; break;
            default: break;
        }
    } @catch (__unused id e) {}
    if ([v isKindOfClass:[UIView class]]) {
        NSMutableArray *st = [NSMutableArray arrayWithObject:v];
        int g = 0;
        while (st.count && g++ < 40) {
            UIView *x = st.lastObject; [st removeLastObject];
            if ([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image) [s appendString:((UIImageView *)x).image.description];
            if ([x isKindOfClass:[UIButton class]] && [(UIButton *)x currentImage]) [s appendString:[(UIButton *)x currentImage].description];
            if ([x isKindOfClass:[UILabel class]] && ((UILabel *)x).text) [s appendString:((UILabel *)x).text];
            [st addObjectsFromArray:x.subviews];
        }
    }
    NSString *l = s.lowercaseString;
    if ([l containsString:@"square.and.arrow.up"] || [l containsString:@"share"]) return @"share";
    if ([l containsString:@"trash"] || [l containsString:@"delete"]) return @"trash";
    if ([l containsString:@"heart"] || [l containsString:@"favorite"]) return @"heart";
    if ([l containsString:@"info"]) return @"info";
    if ([l containsString:@"speaker"] || [l containsString:@"mute"]) return @"mute";
    if ([l containsString:@"pause"] || [l containsString:@"play"]) return @"play";
    if ([l containsString:@"ellipsis"] || [l containsString:@"more"]) return @"more";
    if ([l isEqualToString:@"edit"] || [l hasPrefix:@"edit"]) return @"edit";
    return @"?";
}
static NSString *ItemSymbolText(UIBarButtonItem *it) {
    UIImage *img = it.image;
    if (!img && [it.customView isKindOfClass:[UIButton class]]) img = [(UIButton *)it.customView imageForState:UIControlStateNormal];
    return [img.description lowercaseString] ?: @"";
}

static NSString *gForwardDebug = @"-";
// Press Apple's own bar button.
static void Forward(UIBarButtonItem *it) {
    if (!it) { gForwardDebug = @"no item"; return; }
    if (it.action && it.target) {
        [[UIApplication sharedApplication] sendAction:it.action to:it.target from:it forEvent:nil];
        gForwardDebug = [NSString stringWithFormat:@"action %@", NSStringFromSelector(it.action)]; return;
    }
    if (it.action) {
        [[UIApplication sharedApplication] sendAction:it.action to:nil from:it forEvent:nil];
        gForwardDebug = [NSString stringWithFormat:@"chain %@", NSStringFromSelector(it.action)]; return;
    }
    UIView *v = it.customView ?: KV(it, @"view");
    NSMutableArray *stack = [NSMutableArray arrayWithObject:v ?: [UIView new]];
    while (stack.count) {
        UIView *x = stack.firstObject; [stack removeObjectAtIndex:0];
        if ([x isKindOfClass:[UIControl class]]) {
            [(UIControl *)x sendActionsForControlEvents:UIControlEventTouchUpInside];
            if (@available(iOS 14.0, *)) [(UIControl *)x sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
            gForwardDebug = [NSString stringWithFormat:@"control %@", NSStringFromClass([x class])]; return;
        }
        [stack addObjectsFromArray:x.subviews];
    }
    if (@available(iOS 14.0, *)) {
        id pa = it.primaryAction;
        SEL s = NSSelectorFromString(@"performWithSender:target:");
        if (pa && [pa respondsToSelector:s]) { ((void (*)(id, SEL, id, id))objc_msgSend)(pa, s, it, nil); gForwardDebug = @"primaryAction"; return; }
    }
    gForwardDebug = @"nothing to press";
}

#pragma mark - glass

@interface PGGlass : UIView
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) CAGradientLayer *rim;
@property (nonatomic, strong) CAShapeLayer *rimMask;
@end
@implementation PGGlass
// Light mode: a soft dark rim and lighter shadow so white glass shows on white.
- (void)registerShade { [self traitCollectionDidChange:nil]; }
- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
    BOOL light = self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark;
    self.layer.shadowOpacity = light ? 0.12 : 0.25;
    if (light) _rim.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.16].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.06].CGColor,
                               (id)[UIColor colorWithWhite:0 alpha:0.05].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.12].CGColor];
    else _rim.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.42].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.08].CGColor,
                         (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.28].CGColor];
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    _blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
    _blur.userInteractionEnabled = NO;
    _blur.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) _blur.layer.cornerCurve = kCACornerCurveContinuous;
    UIView *tint = [UIView new];
    tint.backgroundColor = Dyn([UIColor colorWithWhite:1 alpha:0.30], [UIColor colorWithWhite:0.08 alpha:0.55]);
    tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_blur.contentView addSubview:tint];
    [self addSubview:_blur];
    // Liquid-glass rim: brighter at the top-left and bottom-right edges.
    _rim = [CAGradientLayer layer];
    _rim.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.42].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.08].CGColor,
                    (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.28].CGColor];
    _rim.locations = @[@0, @0.35, @0.65, @1];
    _rim.startPoint = CGPointMake(0, 0); _rim.endPoint = CGPointMake(1, 1);
    _rimMask = [CAShapeLayer layer];
    _rimMask.fillColor = UIColor.clearColor.CGColor;
    _rimMask.strokeColor = UIColor.blackColor.CGColor;
    _rimMask.lineWidth = 1.1;
    _rim.mask = _rimMask;
    [self.layer addSublayer:_rim];
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.25;
    [self registerShade];
    self.layer.shadowRadius = 10;
    self.layer.shadowOffset = CGSizeMake(0, 3);
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat r = self.bounds.size.height / 2;
    _blur.frame = self.bounds;
    _blur.layer.cornerRadius = r;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _rim.frame = self.bounds;
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.55, 0.55) cornerRadius:r];
    _rimMask.path = p.CGPath;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:r].CGPath;
    [CATransaction commit];
}
@end

#pragma mark - our buttons

@interface PGButton : UIButton
@property (nonatomic, copy) NSString *kind;
@property (nonatomic, weak) UIView *jelly;      // the glass that wobbles (circles)
@property (nonatomic, weak) UIView *capsule;    // the capsule this button sits in
@property (nonatomic, strong) UIView *bubble;   // glass bubble for capsule buttons
@end

// iOS 26 jelly, on real springs: every frame each view's offset and scale
// move toward a target with stiffness k and damping c. Holding sets snappy
// targets that follow the finger; letting go sets a soft, wobbly spring home.
@interface PGJS : NSObject
@property (nonatomic, weak) UIView *view;
@property (nonatomic) CGFloat x, y, sx, sy, vx, vy, vsx, vsy, tx, ty, tsx, tsy, k, c;
@end
@implementation PGJS
- (instancetype)init { if ((self = [super init])) { _sx = _sy = _tsx = _tsy = 1; _k = 300; _c = 20; } return self; }
@end
static const void *kJS = &kJS;
static NSHashTable *gJSActive;
static CADisplayLink *gJSLink;
@interface PGJSTicker : NSObject
+ (instancetype)shared;
@end
@implementation PGJSTicker
+ (instancetype)shared { static PGJSTicker *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [PGJSTicker new]; }); return t; }
- (void)step:(CADisplayLink *)l {
    CGFloat dt = l.targetTimestamp - l.timestamp;
    if (dt <= 0 || dt > 0.05) dt = 1.0 / 120;
    for (PGJS *s in [gJSActive allObjects]) {
        UIView *v = s.view;
        if (!v) { [gJSActive removeObject:s]; continue; }
        int n = 4; CGFloat h = dt / n;
        for (int i = 0; i < n; i++) {
            s.vx += (-s.k * (s.x - s.tx) - s.c * s.vx) * h;     s.x += s.vx * h;
            s.vy += (-s.k * (s.y - s.ty) - s.c * s.vy) * h;     s.y += s.vy * h;
            s.vsx += (-s.k * (s.sx - s.tsx) - s.c * s.vsx) * h; s.sx += s.vsx * h;
            s.vsy += (-s.k * (s.sy - s.tsy) - s.c * s.vsy) * h; s.sy += s.vsy * h;
        }
        BOOL done = fabs(s.x - s.tx) < 0.05 && fabs(s.y - s.ty) < 0.05 && fabs(s.sx - s.tsx) < 0.001 && fabs(s.sy - s.tsy) < 0.001 &&
                    fabs(s.vx) < 0.1 && fabs(s.vy) < 0.1 && fabs(s.vsx) < 0.005 && fabs(s.vsy) < 0.005;
        if (done) { s.x = s.tx; s.y = s.ty; s.sx = s.tsx; s.sy = s.tsy; s.vx = s.vy = s.vsx = s.vsy = 0; [gJSActive removeObject:s]; }
        v.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(s.x, s.y), s.sx, s.sy);
    }
    if (!gJSActive.count) { [gJSLink invalidate]; gJSLink = nil; }
}
@end
static void JellyTo(UIView *v, CGFloat tx, CGFloat ty, CGFloat sx, CGFloat sy, CGFloat k, CGFloat c) {
    if (!v) return;
    PGJS *s = objc_getAssociatedObject(v, kJS);
    if (!s) {
        s = [PGJS new]; s.view = v;
        CGAffineTransform t0 = v.transform;   // start from wherever it is now
        s.x = t0.tx; s.y = t0.ty; s.sx = sqrt(t0.a * t0.a + t0.c * t0.c); s.sy = sqrt(t0.b * t0.b + t0.d * t0.d);
        objc_setAssociatedObject(v, kJS, s, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    s.tx = tx; s.ty = ty; s.tsx = sx; s.tsy = sy; s.k = k; s.c = c;
    if (!gJSActive) gJSActive = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
    [gJSActive addObject:s];
    if (!gJSLink) {
        gJSLink = [CADisplayLink displayLinkWithTarget:[PGJSTicker shared] selector:@selector(step:)];
        if (@available(iOS 15.0, *)) gJSLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
        [gJSLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}
static void JellyPress(UIView *g) { JellyTo(g, 0, 0, 1.16, 1.16, 380, 21); }
// Lean toward the finger (rubber-banded) and stretch along the drag.
static void JellyFollow(UIView *g, CGPoint off) {
    CGFloat ax = tanh(off.x / 55), ay = tanh(off.y / 55);
    CGFloat sx = 1.16 + 0.09 * fabs(ax) - 0.05 * fabs(ay);
    CGFloat sy = 1.16 + 0.09 * fabs(ay) - 0.05 * fabs(ax);
    JellyTo(g, 11 * ax, 9 * ay, sx, sy, 520, 30);
}
static void JellyRelease(UIView *g) { JellyTo(g, 0, 0, 1, 1, 210, 8.5); }

@implementation PGButton
- (UIView *)jellyTarget {
    if (self.jelly) return self.jelly;
    if (!self.bubble) {
        PGGlass *b = [PGGlass new];
        b.accessibilityIdentifier = @"bubble";
        b.alpha = 0;
        self.bubble = b;
    }
    if (self.bubble.superview != self.superview) [self.superview insertSubview:self.bubble belowSubview:self];
    CGFloat d = MIN(self.bounds.size.width, self.bounds.size.height) - 2;
    self.bubble.bounds = CGRectMake(0, 0, d, d);
    self.bubble.center = self.center;
    return self.bubble;
}
- (BOOL)jellyOK { return [self.kind isEqualToString:@"share"] || [self.kind isEqualToString:@"trash"]; }
- (BOOL)beginTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    if (![self jellyOK]) {
        [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ self.alpha = 0.5; } completion:nil];
        return [super beginTrackingWithTouch:t withEvent:e];
    }
    UIView *g = [self jellyTarget];
    if (g == self.bubble) [UIView animateWithDuration:0.15 animations:^{ self.bubble.alpha = 1; }];
    JellyPress(g);
    JellyTo(self, 0, 0, 1.08, 1.08, 380, 22);
    if (self.capsule) JellyTo(self.capsule, 0, 0, 1.03, 1.03, 320, 20);
    return [super beginTrackingWithTouch:t withEvent:e];
}
- (BOOL)continueTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    if (![self jellyOK]) return [super continueTrackingWithTouch:t withEvent:e];
    CGPoint p = [t locationInView:self];
    CGPoint off = CGPointMake(p.x - self.bounds.size.width / 2, p.y - self.bounds.size.height / 2);
    JellyFollow([self jellyTarget], off);
    JellyTo(self, 6 * tanh(off.x / 55), 5 * tanh(off.y / 55), 1.08, 1.08, 520, 30);
    return [super continueTrackingWithTouch:t withEvent:e];
}
- (void)letGo {
    if (![self jellyOK]) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ self.alpha = 1; } completion:nil];
        return;
    }
    UIView *g = [self jellyTarget];
    JellyRelease(g);
    JellyRelease(self);
    if (self.capsule) JellyRelease(self.capsule);
    if (g == self.bubble) [UIView animateWithDuration:0.3 delay:0.22 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self.bubble.alpha = 0; } completion:nil];
}
- (void)endTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e { [super endTrackingWithTouch:t withEvent:e]; [self letGo]; }
- (void)cancelTrackingWithEvent:(UIEvent *)e { [super cancelTrackingWithEvent:e]; [self letGo]; }
@end

// Jelly for Apple's own top buttons (back, ...): our glass circle wobbles.
@interface PGTopJelly : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
static const void *kJellyGlass = &kJellyGlass;
@implementation PGTopJelly
+ (instancetype)shared { static PGTopJelly *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [PGTopJelly new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)press:(UILongPressGestureRecognizer *)g {
    UIView *glass = objc_getAssociatedObject(g.view, kJellyGlass);
    if (!glass) return;
    CGPoint p = [g locationInView:glass];
    CGPoint off = CGPointMake(p.x - glass.bounds.size.width / 2, p.y - glass.bounds.size.height / 2);
    if (g.state == UIGestureRecognizerStateBegan) JellyPress(glass);
    else if (g.state == UIGestureRecognizerStateChanged) JellyFollow(glass, off);
    else if (g.state >= UIGestureRecognizerStateEnded) JellyRelease(glass);
}
@end
static void AddTopJelly(UIView *v, UIView *glass) {
    if (!v || !glass) return;
    objc_setAssociatedObject(v, kJellyGlass, glass, OBJC_ASSOCIATION_ASSIGN);
    for (UIGestureRecognizer *g in v.gestureRecognizers) if (g.delegate == (id)[PGTopJelly shared]) return;
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[PGTopJelly shared] action:@selector(press:)];
    lp.minimumPressDuration = 0;
    lp.cancelsTouchesInView = NO;
    lp.delaysTouchesEnded = NO;
    lp.delegate = [PGTopJelly shared];
    [v addGestureRecognizer:lp];
}

static UIImage *Sym(NSString *name, CGFloat size) {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:size weight:UIImageSymbolWeightMedium];
    return [UIImage systemImageNamed:name withConfiguration:c];
}


// Container that only catches touches on our buttons and the scrubber.
@interface PGPass : UIView @end
@implementation PGPass
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    if (self.hidden || self.alpha < 0.01) return nil;
    for (UIView *s in [self.subviews reverseObjectEnumerator]) {
        if (s.hidden || s.alpha < 0.01 || !s.userInteractionEnabled) continue;
        UIView *h = [s hitTest:[self convertPoint:p toView:s] withEvent:e];
        if (h) return h;
    }
    return nil;
}
@end

#pragma mark - state

static __weak UIToolbar *gToolbar;
static __weak UINavigationBar *gNavBar;
static __weak UIBarButtonItem *gEditItem;
static NSMutableDictionary *gItems;        // kind -> weak box of Apple's item
static __weak AVPlayer *gAVPlayer;
static CADisplayLink *gLink;
static BOOL gScrubbing;
static void LayoutBottom(UIToolbar *tb);
static __weak UIToolbar *gToolbarFwd;
static NSString *Clock(double s, BOOL hundredths) {
    if (!(s >= 0)) s = 0;
    int m = (int)(s / 60), sec = (int)s % 60;
    if (hundredths) return [NSString stringWithFormat:@"%02d:%02d.%02d", m, sec, (int)((s - floor(s)) * 100)];
    int ts = (int)round(s);
    return [NSString stringWithFormat:@"%02d:%02d", ts / 60, ts % 60];
}
static NSString *gBottomDebug = @"-", *gTopDebug = @"-", *gVideoDebug = @"-";

@interface PGBox : NSObject
@property (nonatomic, weak) id obj;
@end
@implementation PGBox
@end

static UIBarButtonItem *AppleItem(NSString *kind) { return ((PGBox *)gItems[kind]).obj; }

@interface PGTarget : NSObject
+ (instancetype)shared;
@end

static void StartLink(void);

#pragma mark - video player (AVPlayer from the visible AVPlayerLayer)

static double Dur(AVPlayer *p) {
    CMTime d = p.currentItem.duration;
    if (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) return CMTimeGetSeconds(d);
    // The asset's length (looked up once per item, it can be slow).
    static const void *kDur = &kDur;
    AVPlayerItem *it = p.currentItem;
    if (!it) return 0;
    NSNumber *c = objc_getAssociatedObject(it, kDur);
    if (c) return c.doubleValue;
    d = it.asset.duration;
    double s = (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) ? CMTimeGetSeconds(d) : 0;
    objc_setAssociatedObject(it, kDur, @(s), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return s;
}

static NSString *gPlayersDebug = @"";
// The player on screen: among all AVPlayerLayers, the visible one over the
// middle of the screen with a real length; playing ones win.
static AVPlayer *CurrentPlayer(UIWindow *w) {
    if (!w) return nil;
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w.layer];
    int guard = 0;
    while (stack.count && guard++ < 8000) {
        CALayer *l = stack.lastObject; [stack removeLastObject];
        if (l.hidden || l.opacity < 0.01) continue;
        if ([l isKindOfClass:[AVPlayerLayer class]] && ((AVPlayerLayer *)l).player) [found addObject:l];
        if (l.sublayers.count) [stack addObjectsFromArray:l.sublayers];
    }
    CGPoint mid = CGPointMake(CGRectGetMidX(w.bounds), CGRectGetMidY(w.bounds));
    AVPlayer *best = nil; int bestScore = -1;
    NSMutableArray *dbg = [NSMutableArray array];
    for (AVPlayerLayer *l in found) {
        AVPlayer *p = l.player;
        CGRect f = [l convertRect:l.bounds toLayer:w.layer];
        int score = 0;
        if (CGRectContainsPoint(f, mid)) score += 4;
        if (CGRectIntersectsRect(f, w.bounds) && f.size.width > 50) score += 2;
        if (Dur(p) > 0) score += 3;
        if (p.rate > 0) score += 1;
        if (dbg.count < 4) [dbg addObject:[NSString stringWithFormat:@"[%.1f/%.1f r%.0f s%d %.0fx%.0f]", CMTimeGetSeconds(p.currentTime), Dur(p), p.rate, score, f.size.width, f.size.height]];
        if (score > bestScore) { bestScore = score; best = p; }
    }
    gPlayersDebug = [NSString stringWithFormat:@"%lu layers %@", (unsigned long)found.count, [dbg componentsJoinedByString:@""]];
    return best;
}

#pragma mark - bottom bar

static PGGlass *GlassIn(UIView *c, NSString *key) {
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGGlass class]] && [v.accessibilityIdentifier isEqualToString:key]) return (PGGlass *)v;
    PGGlass *g = [PGGlass new];
    g.accessibilityIdentifier = key;
    [c insertSubview:g atIndex:0];
    return g;
}

static PGButton *ButtonIn(UIView *c, NSString *kind) {
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGButton class]] && [((PGButton *)v).kind isEqualToString:kind]) return (PGButton *)v;
    PGButton *b = [PGButton buttonWithType:UIButtonTypeSystem];
    b.kind = kind;
    b.tintColor = GIcon();
    [b addTarget:[PGTarget shared] action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [b addTarget:[PGTarget shared] action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [b addTarget:[PGTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:b];
    return b;
}

static void SetSym(PGButton *b, NSString *name, CGFloat size) {
    if ([b.accessibilityValue isEqualToString:name]) return;
    b.accessibilityValue = name;
    UIImage *img = Sym(name, size);
    [UIView transitionWithView:b duration:0.18 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction animations:^{
        [b setImage:img forState:UIControlStateNormal];
    } completion:nil];
}

@interface PGScrubber : UIView
@property (nonatomic, strong) UIView *track, *fill;
@property (nonatomic) CGFloat progress;
@end
@implementation PGScrubber
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _track = [UIView new]; _track.backgroundColor = Dyn([UIColor colorWithWhite:0 alpha:0.18], [UIColor colorWithWhite:1 alpha:0.28]); _track.userInteractionEnabled = NO;
    _fill = [UIView new]; _fill.backgroundColor = Dyn([UIColor colorWithWhite:0 alpha:0.85], [UIColor colorWithWhite:1 alpha:0.92]); _fill.userInteractionEnabled = NO;
    [self addSubview:_track]; [_track addSubview:_fill];
    _track.clipsToBounds = YES;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];

    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = gScrubbing ? 16 : 9;
    _track.frame = CGRectMake(0, (self.bounds.size.height - h) / 2, self.bounds.size.width, h);
    _track.layer.cornerRadius = h / 2;
    _fill.frame = CGRectMake(0, 0, MAX(h, _track.bounds.size.width * _progress), h);
    _fill.layer.cornerRadius = h / 2;
}
- (void)setProgress:(CGFloat)p { _progress = MAX(0, MIN(1, p)); [self setNeedsLayout]; }
// Seek smoothly: only one seek runs at a time; when it lands, jump to wherever
// the finger is now. Slow drags stay smooth and precise.
static double gPendingSeek = -1;
static BOOL gSeeking;
static void ChaseSeek(void) {
    AVPlayer *pl = gAVPlayer;
    if (!pl || gPendingSeek < 0) { gSeeking = NO; return; }
    gSeeking = YES;
    double target = gPendingSeek; gPendingSeek = -1;
    CMTime tol = CMTimeMakeWithSeconds(1.0 / 60, 600);
    [pl seekToTime:CMTimeMakeWithSeconds(target, 600) toleranceBefore:tol toleranceAfter:tol completionHandler:^(BOOL done) {
        dispatch_async(dispatch_get_main_queue(), ^{ gSeeking = NO; if (gPendingSeek >= 0) ChaseSeek(); });
    }];
}
static void SeekTo(double s) { gPendingSeek = s; if (!gSeeking) ChaseSeek(); }

// Like Apple's: the bar moves by how far you drag, not to where your finger is.
- (void)pan:(UIPanGestureRecognizer *)g {
    static CGFloat start;
    static BOOL wasPlaying;
    AVPlayer *pl = gAVPlayer;
    if (g.state == UIGestureRecognizerStateBegan) {
        gScrubbing = YES;
        start = self.progress;
        wasPlaying = pl.rate > 0;
        if (wasPlaying) pl.rate = 0;    // hold the picture still while scrubbing
        // The player grows into the iOS 26 timer.
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.68 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            UIToolbar *tb = gToolbarFwd; if (tb) LayoutBottom(tb);
            [self.superview layoutIfNeeded]; [self setNeedsLayout]; [self layoutIfNeeded];
        } completion:nil];
    }
    CGFloat dx = [g translationInView:self].x;
    self.progress = start + dx / MAX(1, self.bounds.size.width);
    [self layoutIfNeeded];
    double dur = Dur(pl);
    if (pl && dur > 0) SeekTo(dur * self.progress);
    for (UIView *v in self.superview.subviews) if ([v isKindOfClass:[UILabel class]]) {
        UILabel *l = (UILabel *)v;
        if ([l.accessibilityIdentifier isEqualToString:@"elapsed"]) l.text = Clock(dur * self.progress, YES);
        else if ([l.accessibilityIdentifier isEqualToString:@"total"]) l.text = Clock(dur, YES);
    }
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed) {
        gScrubbing = NO;
        if (wasPlaying) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [pl play]; });
        [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            UIToolbar *tb = gToolbarFwd; if (tb) LayoutBottom(tb);
            [self setNeedsLayout]; [self layoutIfNeeded];
        } completion:nil];
    }
}
@end

static UIView *FindFilmstrip(UIView *v, int d) {
    if (d > 18) return nil;
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    for (UIView *s in v.subviews) {
        NSString *n = NSStringFromClass([s class]);
        if (([n containsString:@"Scrubber"] || [n containsString:@"Filmstrip"]) && s.bounds.size.width >= W * 0.8 && s.bounds.size.height >= 20 && s.bounds.size.height <= 120 && !s.hidden && s.alpha > 0.01) return s;
        UIView *r = FindFilmstrip(s, d + 1);
        if (r) return r;
    }
    return nil;
}

static BOOL gTextMode;
static BOOL gWasSelect;   // the select bar is already showing (no split animation)
// Is the photo viewer's thumbnail strip anywhere in this window (shown or not)?
static BOOL HasScrubber(UIWindow *w) {
    static __weak UIView *cached;
    static CFTimeInterval last; static BOOL lastAnswer;
    UIView *c = cached;
    if (c && c.window == w) return YES;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - last < 0.4 && lastAnswer) return YES;
    last = now;
    Class sc = NSClassFromString(@"PUScrubberView");
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w ?: [UIView new]];
    int guard = 0;
    while (stack.count && guard++ < 8000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ((sc && [v isKindOfClass:sc]) || [NSStringFromClass([v class]) containsString:@"Filmstrip"]) { cached = v; lastAnswer = YES; return YES; }
        [stack addObjectsFromArray:v.subviews];
    }
    lastAnswer = NO;
    return NO;
}
static UIView *TextGlyph(UIView *v, int d) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01) continue;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) return s;
        if (d < 5) { UIView *g = TextGlyph(s, d + 1); if (g) return g; }
    }
    return nil;
}

static PGPass *EnsureContainer(UIToolbar *tb) {
    PGPass *c = (PGPass *)[tb viewWithTag:BOTTOM_TAG];
    if (c.superview != tb) c = nil;
    if (!c) {
        c = [PGPass new];
        c.tag = BOTTOM_TAG;
        [tb addSubview:c];
    }
    __weak UIToolbar *wt = tb;
    if (!objc_getAssociatedObject(tb, kStyled)) dispatch_async(dispatch_get_main_queue(), ^{
        UIToolbar *t = wt;
        if (!t || objc_getAssociatedObject(t, kStyled)) return;
        objc_setAssociatedObject(t, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIToolbarAppearance *a = [UIToolbarAppearance new];
        [a configureWithTransparentBackground];
        t.standardAppearance = a; t.compactAppearance = a; t.scrollEdgeAppearance = a; t.compactScrollEdgeAppearance = a;
        t.tintColor = GIcon();
    });
    c.hidden = NO;
    if (tb.clipsToBounds) tb.clipsToBounds = NO;
    return c;
}

static void LayoutBottom(UIToolbar *tb) {
    PGPass *c = (PGPass *)[tb viewWithTag:BOTTOM_TAG];
    if (c.superview != tb) c = nil;
    if (!gEnabled) { c.hidden = YES; for (UIBarButtonItem *it in tb.items) Unmask(KV(it, @"view")); return; }

    // Which of Apple's buttons are here?
    NSMutableDictionary *found = [NSMutableDictionary dictionary];
    NSMutableArray *kinds = [NSMutableArray array];
    for (UIBarButtonItem *it in tb.items) {
        UIView *v = KV(it, @"view");
        if (![v isKindOfClass:[UIView class]] || !v.window) continue;
        NSString *k = ItemKind(it);
        [kinds addObject:k];
        if (![k isEqualToString:@"?"]) { PGBox *b = [PGBox new]; b.obj = it; found[k] = b; }
    }
    // Recently Deleted and similar: text buttons (Delete / Recover) in the viewer.
    NSMutableArray *textViews = [NSMutableArray array];
    for (UIBarButtonItem *it in tb.items) {
        UIView *v = KV(it, @"view");
        if (!v.window || v.hidden) continue;
        UIView *g = TextGlyph(v, 0);
        if (g) [textViews addObject:g];
    }
    if (gEnabled && !found[@"share"] && textViews.count && FindFilmstrip(tb.window, 0)) {
        for (UIBarButtonItem *it in tb.items) Unmask(KV(it, @"view"));
        c = EnsureContainer(tb);
        gToolbar = tb; gTextMode = YES;
        for (UIView *v in c.subviews) v.hidden = !([v isKindOfClass:[PGGlass class]] && [v.accessibilityIdentifier hasPrefix:@"txt"]);
        int i = 0;
        for (UIView *g in textViews) {
            PGGlass *gl = GlassIn(c, [NSString stringWithFormat:@"txt%d", i++]);
            gl.hidden = NO;
            CGRect r = [g convertRect:g.bounds toView:c];
            CGFloat w = r.size.width + 40, h = 44;
            SetFrame(gl, CGRectMake(round(CGRectGetMidX(r) - w / 2), round(CGRectGetMidY(r) - h / 2), round(w), h));
        }
        for (UIView *v in c.subviews) if ([v.accessibilityIdentifier hasPrefix:@"txt"] && [[v.accessibilityIdentifier substringFromIndex:3] intValue] >= i) v.hidden = YES;
        // Under Apple's text buttons (they stay Apple's own, just on glass).
        if (tb.subviews.firstObject != c) { [c removeFromSuperview]; [tb insertSubview:c atIndex:0]; }
        UIView *bg = nil;
        for (UIView *s in tb.subviews) if ([NSStringFromClass([s class]) containsString:@"Background"]) bg = s;
        if (bg) [tb insertSubview:c aboveSubview:bg];
        SetFrame(c, tb.bounds);
        gBottomDebug = [NSString stringWithFormat:@"text mode: %lu buttons", (unsigned long)textViews.count];
        StartLink();
        return;
    }
    gTextMode = NO;
    for (UIView *v in c.subviews) if ([v.accessibilityIdentifier hasPrefix:@"txt"]) v.hidden = YES;
    // Selecting in the grid: share, "N Photos Selected", trash. The photo
    // viewer always has the thumbnail strip somewhere in its window; the grid never does.
    BOOL wasSelect = gWasSelect;
    BOOL viewerHere = HasScrubber(tb.window);
    UILabel *countLabel = nil;
    {
        NSMutableArray *stack = [NSMutableArray arrayWithArray:tb.subviews];
        int guard = 0;
        while (stack.count && guard++ < 400) {
            UIView *v = stack.lastObject; [stack removeLastObject];
            if (v.tag == BOTTOM_TAG) continue;
            if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) {
                NSString *s = ((UILabel *)v).text;
                if ([s rangeOfString:@"elect"].location != NSNotFound || [s rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location != NSNotFound) { countLabel = (UILabel *)v; break; }
            }
            [stack addObjectsFromArray:v.subviews];
        }
    }
    BOOL selectLabel = countLabel && [countLabel.text rangeOfString:@"elect"].location != NSNotFound;
    if (gEnabled && !viewerHere && selectLabel && found[@"share"] && found[@"trash"]) {
        c = EnsureContainer(tb);
        gToolbar = tb;
        gItems = found;
        UIBarButtonItem *shareIt = ((PGBox *)found[@"share"]).obj, *trashIt = ((PGBox *)found[@"trash"]).obj;
        // Where Apple's row sits: read once when Select opens, then locked.
        // A fixed spot on screen (just above the home bar), whatever Apple does with the toolbar.
        UIWindow *win = tb.window;
        CGFloat screenY = win ? win.bounds.size.height - win.safeAreaInsets.bottom - 23 : 0;
        CGFloat lockedCY = win ? round([tb convertPoint:CGPointMake(0, screenY) fromView:nil].y) : 25;
        // All of Apple's buttons are hidden (and untouchable); ours press them.
        for (UIBarButtonItem *it in tb.items) {
            UIView *v = KV(it, @"view");
            if (!v) continue;
            Mask(v);
            if (v.userInteractionEnabled) { v.userInteractionEnabled = NO; objc_setAssociatedObject(v, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            if (objc_getAssociatedObject(v, kShift)) { v.transform = CGAffineTransformIdentity; objc_setAssociatedObject(v, kShift, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        }
        for (UIView *v in c.subviews) v.hidden = ![v.accessibilityIdentifier hasPrefix:@"sel"];
        if (tb.subviews.lastObject != c) [tb bringSubviewToFront:c];
        SetFrame(c, tb.bounds);
        CGFloat W = c.bounds.size.width, D = 51, margin = 31, cy = lockedCY;
        CGRect rs = CGRectMake(margin, cy - D / 2, D, D), rt = CGRectMake(W - margin - D, cy - D / 2, D, D);
        CGRect rm = CGRectZero;
        PGGlass *gs = GlassIn(c, @"sel_share"), *gt = GlassIn(c, @"sel_trash"), *gc = GlassIn(c, @"sel_mid");
        gs.hidden = gt.hidden = gc.hidden = NO;
        // Our share / trash buttons on the circles.
        PGButton *bs = nil, *bt = nil;
        for (UIView *v in c.subviews) if ([v isKindOfClass:[PGButton class]]) {
            if ([v.accessibilityIdentifier isEqualToString:@"sel_b_share"]) bs = (PGButton *)v;
            if ([v.accessibilityIdentifier isEqualToString:@"sel_b_trash"]) bt = (PGButton *)v;
        }
        for (NSString *k in @[@"share", @"trash"]) {
            PGButton *b = [k isEqualToString:@"share"] ? bs : bt;
            if (!b) {
                b = [PGButton buttonWithType:UIButtonTypeSystem];
                b.kind = k;
                b.accessibilityIdentifier = [@"sel_b_" stringByAppendingString:k];
                b.tintColor = GIcon();
                [b setImage:Sym([k isEqualToString:@"share"] ? @"square.and.arrow.up" : @"trash", 19) forState:UIControlStateNormal];
                [b addTarget:[PGTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
                [c addSubview:b];
                if ([k isEqualToString:@"share"]) bs = b; else bt = b;
            }
            b.hidden = NO;
            UIBarButtonItem *it = [k isEqualToString:@"share"] ? shareIt : trashIt;
            BOOL on = it.enabled;
            b.userInteractionEnabled = on;
            CGFloat a = on ? 1 : 0.4;
            if (fabs(b.alpha - a) > 0.01 && ![b.layer animationKeys].count) b.alpha = a;
        }
        bs.jelly = gs; bt.jelly = gt;
        [c bringSubviewToFront:bs]; [c bringSubviewToFront:bt];
        // "5 Selected" in the middle.
        NSString *text = @"Select Items";
        if (countLabel) {
            NSScanner *sc = [NSScanner scannerWithString:countLabel.text];
            [sc scanUpToCharactersFromSet:NSCharacterSet.decimalDigitCharacterSet intoString:nil];
            NSInteger n = 0;
            if ([sc scanInteger:&n]) text = [NSString stringWithFormat:@"%ld Selected", (long)n];
            else text = countLabel.text;
        }
        UILabel *sl = nil;
        for (UIView *v in c.subviews) if ([v isKindOfClass:[UILabel class]] && [v.accessibilityIdentifier isEqualToString:@"sel_text"]) sl = (UILabel *)v;
        if (!sl) {
            sl = [UILabel new];
            sl.accessibilityIdentifier = @"sel_text";
            sl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
            sl.textColor = GIcon();
            sl.textAlignment = NSTextAlignmentCenter;
            sl.adjustsFontSizeToFitWidth = YES;
            sl.minimumScaleFactor = 0.7;
            sl.userInteractionEnabled = NO;
            [c addSubview:sl];
        }
        sl.hidden = NO;
        BOOL textChanged = ![sl.text isEqualToString:text];
        if (textChanged) sl.text = text;
        {
            CGFloat tw = [sl.text sizeWithAttributes:@{NSFontAttributeName: sl.font}].width;
            CGFloat mw = MIN(W - 2 * (margin + D + 12), MAX(110, ceil(tw) + 30));
            rm = CGRectMake(round((W - mw) / 2), cy - D / 2, round(mw), D);
        }
        if (!wasSelect) {
            // Liquid split: the circles (with their icons) start inside the pill and bulge out.
            gc.frame = rm; sl.frame = CGRectInset(rm, 12, 0);
            CGRect s0 = CGRectMake(CGRectGetMinX(rm) + 6, rm.origin.y, D, D), t0 = CGRectMake(CGRectGetMaxX(rm) - 6 - D, rm.origin.y, D, D);
            gs.transform = gt.transform = CGAffineTransformIdentity;
            gs.frame = s0; gt.frame = t0; bs.frame = s0; bt.frame = t0;
            gs.transform = gt.transform = CGAffineTransformMakeScale(0.7, 0.7);
            gs.alpha = gt.alpha = 0.4; sl.alpha = 0;
            [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:0.58 initialSpringVelocity:0.9
                                options:UIViewAnimationOptionAllowUserInteraction animations:^{
                gs.transform = gt.transform = CGAffineTransformIdentity;
                gs.frame = rs; gt.frame = rt; bs.frame = rs; bt.frame = rt;
                gs.alpha = gt.alpha = 1;
            } completion:nil];
            [UIView animateWithDuration:0.25 delay:0.12 options:UIViewAnimationOptionAllowUserInteraction animations:^{ sl.alpha = 1; } completion:nil];
            CAKeyframeAnimation *sq = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
            sq.values = @[@1.12, @0.9, @1.04, @0.99, @1]; sq.keyTimes = @[@0, @0.25, @0.55, @0.8, @1]; sq.duration = 0.7;
            CAKeyframeAnimation *sqy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
            sqy.values = @[@0.9, @1.08, @0.97, @1.01, @1]; sqy.keyTimes = sq.keyTimes; sqy.duration = 0.7;
            [gc.layer addAnimation:sq forKey:@"sx"]; [gc.layer addAnimation:sqy forKey:@"sy"];
        } else {
            if (!gs.layer.animationKeys.count && CGAffineTransformIsIdentity(gs.transform)) { SetFrame(gs, rs); SetFrame(bs, rs); }
            if (!gt.layer.animationKeys.count && CGAffineTransformIsIdentity(gt.transform)) { SetFrame(gt, rt); SetFrame(bt, rt); }
            if (textChanged && !CGRectEqualToRect(gc.frame, rm)) {
                // The pill grows or shrinks smoothly as the count changes.
                [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                    gc.frame = rm; [gc layoutIfNeeded]; sl.frame = CGRectInset(rm, 12, 0);
                } completion:nil];
            } else if (!gc.layer.animationKeys.count) { SetFrame(gc, rm); SetFrame(sl, CGRectInset(rm, 12, 0)); }
        }
        gWasSelect = YES;
        gBottomDebug = [NSString stringWithFormat:@"select mode: %@", countLabel.text ?: @"(no label)"];
        return;
    }
    gWasSelect = NO;
    for (UIView *v in c.subviews) if ([v.accessibilityIdentifier hasPrefix:@"sel"]) v.hidden = YES;
    if (countLabel) Unmask(countLabel);
    for (UIBarButtonItem *it in tb.items) {
        UIView *v = KV(it, @"view");
        if (objc_getAssociatedObject(v, kShift)) { v.transform = CGAffineTransformIdentity; objc_setAssociatedObject(v, kShift, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        if (objc_getAssociatedObject(v, kStyled)) { v.userInteractionEnabled = YES; objc_setAssociatedObject(v, kStyled, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    }
    // Only the photo/video viewer toolbar: it has both share and trash.
    if (!found[@"share"] || !found[@"trash"]) { c.hidden = YES; for (UIBarButtonItem *it in tb.items) Unmask(KV(it, @"view")); gBottomDebug = [NSString stringWithFormat:@"not viewer: %@", [kinds componentsJoinedByString:@","]]; return; }
    gItems = found;
    gToolbar = tb;
    gBottomDebug = [kinds componentsJoinedByString:@","];

    if (!c) {
        c = [PGPass new];
        c.tag = BOTTOM_TAG;
        [tb addSubview:c];
        // Toolbar background: clear, so the glass floats over the photo.
        __weak UIToolbar *wt = tb;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIToolbar *t = wt;
            if (!t || objc_getAssociatedObject(t, kStyled)) return;
            objc_setAssociatedObject(t, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIToolbarAppearance *a = [UIToolbarAppearance new];
            [a configureWithTransparentBackground];
            t.standardAppearance = a; t.compactAppearance = a; t.scrollEdgeAppearance = a; t.compactScrollEdgeAppearance = a;
        });
    }
    c.hidden = NO;
    for (UIView *v in c.subviews) if (![v.accessibilityIdentifier hasPrefix:@"txt"] && ![v.accessibilityIdentifier hasPrefix:@"sel"]) { if ([v isKindOfClass:[PGButton class]] || [v isKindOfClass:[PGGlass class]]) v.hidden = NO; }
    if (tb.clipsToBounds) tb.clipsToBounds = NO;
    [tb bringSubviewToFront:c];
    SetFrame(c, tb.bounds);
    for (UIBarButtonItem *it in tb.items) Mask(KV(it, @"view"));

    // Row geometry: centered on Apple's own button row.
    CGFloat W = tb.bounds.size.width, D = 44, cy = 0; int cnt = 0;
    for (UIBarButtonItem *it in tb.items) { UIView *v = KV(it, @"view"); if (v.window) { cy += CGRectGetMidY([v convertRect:v.bounds toView:tb]); cnt++; } }
    cy = cnt ? round(cy / cnt) : 25;
    CGFloat sideX = 18;

    PGGlass *gl = GlassIn(c, @"share"), *gm = GlassIn(c, @"mid"), *gr = GlassIn(c, @"trash");
    SetFrame(gl, CGRectMake(sideX, cy - D / 2, D, D));
    SetFrame(gr, CGRectMake(W - sideX - D, cy - D / 2, D, D));
    CGFloat mw = 150;
    SetFrame(gm, CGRectMake(round((W - mw) / 2), cy - D / 2, mw, D));

    PGButton *bShare = ButtonIn(c, @"share"), *bTrash = ButtonIn(c, @"trash");
    PGButton *bHeart = ButtonIn(c, @"heart"), *bInfo = ButtonIn(c, @"info"), *bEdit = ButtonIn(c, @"edit");
    SetSym(bShare, @"square.and.arrow.up", 17);
    SetSym(bTrash, @"trash", 17);
    BOOL fav = [ItemSymbolText(AppleItem(@"heart")) containsString:@"heart.fill"];
    SetSym(bHeart, fav ? @"heart.fill" : @"heart", 17);
    bHeart.tintColor = GIcon();
    SetSym(bInfo, @"info.circle", 18);
    SetSym(bEdit, @"slider.horizontal.3", 17);
    bInfo.hidden = !AppleItem(@"info");
    bHeart.hidden = !AppleItem(@"heart");
    SetFrame(bShare, gl.frame); SetFrame(bTrash, gr.frame);
    bShare.jelly = gl; bTrash.jelly = gr;
    bHeart.capsule = bInfo.capsule = bEdit.capsule = gm;
    CGFloat third = mw / 3;
    SetFrame(bHeart, CGRectMake(gm.frame.origin.x, gm.frame.origin.y, third, D));
    SetFrame(bInfo, CGRectMake(gm.frame.origin.x + third, gm.frame.origin.y, third, D));
    SetFrame(bEdit, CGRectMake(gm.frame.origin.x + third * 2, gm.frame.origin.y, third, D));

    // Video player capsule (only for videos: Apple shows play/pause then).
    // Videos only: Apple's play button is really showing (photos can keep a hidden one).
    UIBarButtonItem *playItem = AppleItem(@"play");
    UIView *pv = KV(playItem, @"view");
    BOOL video = gPlayer && playItem && playItem.enabled && pv.window && !pv.hidden && pv.alpha > 0.01 && pv.bounds.size.width > 2;
    for (UIView *p = pv.superview; p && p != tb && video; p = p.superview) if (p.hidden || p.alpha < 0.01) video = NO;
    gBottomDebug = [gBottomDebug stringByAppendingFormat:@" video=%d", video];
    static __weak UIView *gFilm;
    UIView *film = FindFilmstrip(tb.window, 0);
    if (film) gFilm = film;
    // Apple's own frame strip goes away while our scrubber has a real player.
    AVPlayer *pl = gAVPlayer;
    BOOL ours = video && pl && Dur(pl) > 0;
    (void)ours;
    if (gFilm) Unmask(gFilm);   // thumbnails always stay
    PGGlass *gv = GlassIn(c, @"video");
    PGButton *bPlay = ButtonIn(c, @"play"), *bMute = ButtonIn(c, @"mute");
    PGScrubber *scrub = nil;
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGScrubber class]]) scrub = (PGScrubber *)v;
    if (!scrub) { scrub = [PGScrubber new]; [c addSubview:scrub]; }
    gv.hidden = bPlay.hidden = bMute.hidden = scrub.hidden = !video;
    if (video) {
        CGFloat filmTop = film ? [film convertRect:film.bounds toView:tb].origin.y : -58;
        CGFloat VD = 54;
        CGFloat vy = MIN(filmTop, -40) - 12 - VD;
        CGFloat vx = 22, vw = W - vx * 2;
        gToolbarFwd = tb;
        UILabel *le = nil, *lt = nil;
        for (UIView *v in c.subviews) if ([v isKindOfClass:[UILabel class]]) {
            if ([v.accessibilityIdentifier isEqualToString:@"elapsed"]) le = (UILabel *)v;
            if ([v.accessibilityIdentifier isEqualToString:@"total"]) lt = (UILabel *)v;
        }
        if (!le) { le = [UILabel new]; le.accessibilityIdentifier = @"elapsed"; [c addSubview:le]; }
        if (!lt) { lt = [UILabel new]; lt.accessibilityIdentifier = @"total"; lt.textAlignment = NSTextAlignmentRight; [c addSubview:lt]; }
        for (UILabel *l in @[le, lt]) {
            l.font = [UIFont monospacedDigitSystemFontOfSize:19 weight:UIFontWeightSemibold];
            l.textColor = GIcon();
            l.userInteractionEnabled = NO;
        }
        if (gScrubbing) {
            // iOS 26 timer: taller capsule, times on top, a thick bar across the bottom.
            CGFloat TH = 80, ty = vy + VD - TH;
            SetFrame(gv, CGRectMake(vx, ty, vw, TH));
            SetFrame(le, CGRectMake(vx + 24, ty + 12, vw / 2 - 24, 26));
            SetFrame(lt, CGRectMake(vx + vw / 2, ty + 12, vw / 2 - 24, 26));
            le.alpha = lt.alpha = 1;
            bPlay.alpha = bMute.alpha = 0;
            bPlay.transform = bMute.transform = CGAffineTransformMakeScale(0.5, 0.5);
            SetFrame(scrub, CGRectMake(vx + 22, ty + 40, vw - 44, 34));
            le.hidden = lt.hidden = NO;
            gv.hidden = NO;
            StartLink();
            return;
        }
        le.alpha = lt.alpha = 0;
        if (bPlay.alpha < 1) { bPlay.alpha = bMute.alpha = 1; bPlay.transform = bMute.transform = CGAffineTransformIdentity; }
        SetFrame(le, CGRectMake(vx + 24, vy + 6, vw / 2 - 24, 26));
        SetFrame(lt, CGRectMake(vx + vw / 2, vy + 6, vw / 2 - 24, 26));
        SetFrame(gv, CGRectMake(vx, vy, vw, VD));
        bPlay.capsule = bMute.capsule = gv;
        BOOL playing = [ItemSymbolText(AppleItem(@"play")) containsString:@"pause"];
        SetSym(bPlay, playing ? @"pause.fill" : @"play.fill", 21);
        NSString *m = ItemSymbolText(AppleItem(@"mute"));
        SetSym(bMute, ([m containsString:@"slash"] || [m containsString:@"mute"]) ? @"speaker.slash.fill" : @"speaker.wave.2.fill", 18);
        bMute.hidden = !AppleItem(@"mute");
        SetFrame(bPlay, CGRectMake(vx + 5, vy + 2, 50, VD - 4));
        SetFrame(bMute, CGRectMake(vx + vw - 55, vy + 2, 50, VD - 4));
        CGFloat sx = vx + 60, ex = vx + vw - (AppleItem(@"mute") ? 62 : 22);
        SetFrame(scrub, CGRectMake(sx, vy, ex - sx, VD));
        StartLink();
    }
}

#pragma mark - bar backgrounds

static NSString *gBgDebug = @"-";
static BOOL IsBg(UIView *v) {
    if ([v isKindOfClass:[UIVisualEffectView class]]) return YES;
    NSString *n = NSStringFromClass([v class]);
    if ([n containsString:@"Background"] || [n containsString:@"Backdrop"] || [n containsString:@"Blur"] || [n containsString:@"Material"]) return YES;
    // A plain colored strip with nothing inside.
    if ([v class] == [UIView class] && !v.subviews.count && v.backgroundColor) {
        CGFloat a = 0; [v.backgroundColor getWhite:NULL alpha:&a];
        return a > 0.3;
    }
    return NO;
}
// The gray top and bottom bars (and the strip behind the thumbnails).
static void HideBarBackgrounds(UIWindow *w, CGFloat topBand, CGFloat bottomBand) {
    if (!w) return;
    CGFloat H = w.bounds.size.height, W = w.bounds.size.width;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w];
    NSMutableArray *dbg = [NSMutableArray array];
    int guard = 0;
    while (stack.count && guard++ < 6000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.tag == BOTTOM_TAG || v.tag == TOP_TAG || v.tag == DEBUG_TAG || [v isKindOfClass:[PGGlass class]]) continue;
        if (v != w && IsBg(v) && !v.hidden) {
            CGRect f = [v convertRect:v.bounds toView:nil];
            BOOL wide = f.size.width >= W * 0.9 && f.size.height < 300;
            BOOL inTop = f.origin.y <= 2 && CGRectGetMaxY(f) <= topBand + 12;
            BOOL inBottom = CGRectGetMaxY(f) >= H - 2 && f.origin.y >= bottomBand - 12;
            BOOL inStrip = f.origin.y >= bottomBand - 12 && f.size.height < 140;   // behind the thumbnails
            if (wide && (inTop || inBottom || inStrip)) {
                Mask(v);
                if (dbg.count < 4) [dbg addObject:[NSString stringWithFormat:@"%@ %.0f@%.0f", NSStringFromClass([v class]), f.size.height, f.origin.y]];
                continue;
            }
        }
        [stack addObjectsFromArray:v.subviews];
    }
    gBgDebug = dbg.count ? [dbg componentsJoinedByString:@", "] : @"none";
}

#pragma mark - thumbnail strip

static NSString *gFilmDebug = @"-";
// iOS 26 thumbnails: rounded corners; the white playhead line goes away.
static void StyleFilmstrip(UIWindow *w) {
    UIView *film = FindFilmstrip(w, 0);
    if (!film) { gFilmDebug = @"no strip"; return; }
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:film];
    int guard = 0;
    CGFloat H = film.bounds.size.height;
    while (stack.count && guard++ < 1500) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        NSString *n = NSStringFromClass([v class]);
        counts[n] = @([counts[n] intValue] + 1);
        CGSize z = v.bounds.size;
        if ([n containsString:@"Playhead"]) { Mask(v); continue; }
        if (([v isKindOfClass:[UIImageView class]] || [n containsString:@"FilmstripWrapper"]) && z.height >= H * 0.5 && z.width >= 8) {
            if (v.layer.cornerRadius != 6) { v.layer.cornerRadius = 6; if (@available(iOS 13.0, *)) v.layer.cornerCurve = kCACornerCurveContinuous; }
            if (!v.layer.masksToBounds) v.layer.masksToBounds = YES;
        }
        if ([v isKindOfClass:[UICollectionViewCell class]]) {
            UIView *cv = ((UICollectionViewCell *)v).contentView;
            if (v.layer.cornerRadius != 7) { v.layer.cornerRadius = 7; if (@available(iOS 13.0, *)) v.layer.cornerCurve = kCACornerCurveContinuous; }
            if (!v.layer.masksToBounds) v.layer.masksToBounds = YES;
            (void)cv;
        }
        // The thin white playhead line (tall and only a few points wide).
        if (z.width <= 5 && z.height >= H * 0.6 && v != film && ![v isKindOfClass:[UIScrollView class]]) Mask(v);
        [stack addObjectsFromArray:v.subviews];
    }
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *k in counts) if (parts.count < 10) [parts addObject:[NSString stringWithFormat:@"%@x%@", k, counts[k]]];
    NSMutableArray *ms = [NSMutableArray array];
    for (Class c = [film class]; c && c != [UIView class] && ms.count < 8; c = class_getSuperclass(c)) {
        unsigned int cnt = 0; Method *m = class_copyMethodList(c, &cnt);
        for (unsigned int i = 0; i < cnt && ms.count < 8; i++) {
            NSString *s = NSStringFromSelector(method_getName(m[i]));
            if ([s rangeOfString:@"xpand" options:0].location != NSNotFound || [s rangeOfString:@"video" options:NSCaseInsensitiveSearch].location != NSNotFound) [ms addObject:s];
        }
        free(m);
    }
    gFilmDebug = [NSString stringWithFormat:@"%@ | %@ | %@", NSStringFromClass([film class]), [parts componentsJoinedByString:@" "], [ms componentsJoinedByString:@" "]];
}

#pragma mark - top bar

static UIView *FindBackButton(UINavigationBar *nb) {
    // The back button: a "BackButton" view, or else the left-most bar button control.
    NSMutableArray *stack = [NSMutableArray arrayWithArray:nb.subviews];
    UIView *best = nil; int guard = 0;
    while (stack.count && guard++ < 400) {
        UIView *v = stack.firstObject; [stack removeObjectAtIndex:0];
        if (v.tag == TOP_TAG || v.hidden || v.alpha < 0.01) continue;
        NSString *n = NSStringFromClass([v class]);
        if ([n containsString:@"BackButton"] && v.bounds.size.width > 4) return v;
        CGRect f = [v convertRect:v.bounds toView:nb];
        if (([n containsString:@"ButtonBarButton"] || [v isKindOfClass:[UIControl class]]) && CGRectGetMidX(f) < 90 && f.size.width > 10 && f.size.width < 140) {
            if (!best || f.size.width > best.bounds.size.width) best = v;
            continue;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    return best;
}

static UIView *GlyphIn(UIView *v, int d) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.bounds.size.width < 2) continue;
        if ([s isKindOfClass:[UIImageView class]] && ((UIImageView *)s).image) return s;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) return s;
        if (d < 5) { UIView *g = GlyphIn(s, d + 1); if (g) return g; }
    }
    return nil;
}

static void LayoutTop(UINavigationBar *nb) {
    UIView *c = [nb viewWithTag:TOP_TAG];
    if (c.superview != nb) c = nil;
    UINavigationItem *top = nb.topItem;
    UIBarButtonItem *edit = nil, *more = nil;
    for (UIBarButtonItem *it in top.rightBarButtonItems) {
        NSNumber *sys = nil;
        @try { sys = [it valueForKey:@"systemItem"]; } @catch (__unused id e) {}
        BOOL isEdit = [it.title isEqualToString:@"Edit"] || [it.title isEqualToString:@"Done"] || ([sys isKindOfClass:[NSNumber class]] && sys.integerValue == UIBarButtonSystemItemEdit);
        NSString *k = isEdit ? @"edit" : ItemKind(it);
        if ([k isEqualToString:@"edit"]) edit = it;
        else if ([k isEqualToString:@"more"]) more = it;
    }
    // Any text-only right button that isn't "..." is Edit.
    if (!edit) for (UIBarButtonItem *it in top.rightBarButtonItems) if (it != more && !it.image && it.title.length) { edit = it; break; }
    // "..." is whichever right button isn't Edit (its label/icon varies).
    if (!more) for (UIBarButtonItem *it in top.rightBarButtonItems) if (it != edit) { more = it; break; }
    UIView *back = FindBackButton(nb);
    BOOL viewer = (edit || gTextMode || HasScrubber(nb.window)) && gToolbar && gToolbar.window == nb.window && ![gToolbar viewWithTag:BOTTOM_TAG].hidden;
    UIView *editView = KV(edit, @"view");
    if (!gEnabled || !gTopBar || !viewer) {
        if (gTopBar && gEnabled) gTopDebug = [NSString stringWithFormat:@"skip: edit=%d more=%d toolbar=%d rights=%lu", edit != nil, more != nil, gToolbar != nil, (unsigned long)top.rightBarButtonItems.count];
        c.hidden = YES;
        if (editView) { Unmask(editView); editView.userInteractionEnabled = YES; }
        if (back && objc_getAssociatedObject(back, kShift)) { back.transform = CGAffineTransformIdentity; objc_setAssociatedObject(back, kShift, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        return;
    }
    gEditItem = edit;
    gNavBar = nb;
    if (!c) {
        c = [UIView new];
        c.tag = TOP_TAG;
        c.userInteractionEnabled = NO;
        [nb insertSubview:c atIndex:0];
        __weak UINavigationBar *wn = nb;
        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationBar *n = wn;
            if (!n || objc_getAssociatedObject(n, kStyled)) return;
            objc_setAssociatedObject(n, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UINavigationBarAppearance *a = [UINavigationBarAppearance new];
            [a configureWithTransparentBackground];
            n.standardAppearance = a; n.compactAppearance = a; n.scrollEdgeAppearance = a;
            if (@available(iOS 15.0, *)) n.compactScrollEdgeAppearance = a;
            n.tintColor = GIcon();
        });
    }
    c.hidden = NO;
    if (nb.clipsToBounds) nb.clipsToBounds = NO;
    // Glass goes just above the bar's background, under Apple's buttons.
    UIView *bg = nil;
    for (UIView *s in nb.subviews) if ([NSStringFromClass([s class]) containsString:@"Background"]) bg = s;
    if (bg && [nb.subviews indexOfObject:c] != [nb.subviews indexOfObject:bg] + 1) [nb insertSubview:c aboveSubview:bg];
    SetFrame(c, nb.bounds);

    // Edit lives in the bottom capsule now.
    if (editView) { Mask(editView); if (editView.userInteractionEnabled) editView.userInteractionEnabled = NO; }

    CGFloat D = 42;
    // Back: move it in from the edge so it sits in its circle.
    PGGlass *gb = GlassIn(c, @"back");
    gb.hidden = !back;
    if (back) {
        UIView *g = GlyphIn(back, 0) ?: back;
        CGRect gr = [g convertRect:g.bounds toView:nb];
        CGFloat curX = CGRectGetMidX(gr) - back.transform.tx;
        CGFloat dx = round((15 + D / 2) - curX);
        if (fabs(back.transform.tx - dx) > 0.5) back.transform = CGAffineTransformMakeTranslation(dx, 0);
        objc_setAssociatedObject(back, kShift, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SetFrame(gb, CGRectMake(15, round(CGRectGetMidY(gr) - D / 2), D, D));
        AddTopJelly(back, gb);
    }
    // "..." circle.
    UIView *moreView = KV(more, @"view");
    PGGlass *gm = GlassIn(c, @"more");
    gm.hidden = !moreView.window;
    if (moreView.window) {
        UIView *g = GlyphIn(moreView, 0) ?: moreView;
        CGRect r = [g convertRect:g.bounds toView:nb];
        SetFrame(gm, CGRectMake(round(CGRectGetMidX(r) - D / 2), round(CGRectGetMidY(r) - D / 2), D, D));

    }
    // Date capsule behind the title.
    UIView *title = top.titleView;
    if (!title) {
        NSMutableArray *stack = [NSMutableArray arrayWithArray:nb.subviews];
        int guard = 0;
        while (stack.count && guard++ < 300) {
            UIView *v = stack.firstObject; [stack removeObjectAtIndex:0];
            if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length && fabs(CGRectGetMidX([v convertRect:v.bounds toView:nb]) - nb.bounds.size.width / 2) < 30) { title = v; break; }
            [stack addObjectsFromArray:v.subviews];
        }
    }
    // Set once each (a light/dark colour never compares equal, re-setting it looped layout).
    static char kTinted;
    for (UIView *v in @[back ?: [UIView new], moreView ?: [UIView new], nb]) if (!objc_getAssociatedObject(v, &kTinted)) { objc_setAssociatedObject(v, &kTinted, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); v.tintColor = GIcon(); }
    PGGlass *gt = GlassIn(c, @"title");
    gt.hidden = !title.window;
    if (title.window) {
        // Fit the widest line of text.
        CGFloat tw = 0; CGRect tr = [title convertRect:title.bounds toView:nb];
        NSMutableArray *labels = [NSMutableArray array];
        if ([title isKindOfClass:[UILabel class]]) [labels addObject:title];
        NSMutableArray *stack = [NSMutableArray arrayWithArray:title.subviews];
        while (stack.count) { UIView *v = stack.lastObject; [stack removeLastObject]; if ([v isKindOfClass:[UILabel class]]) [labels addObject:v]; [stack addObjectsFromArray:v.subviews]; }
        for (UILabel *l in labels) tw = MAX(tw, [l sizeThatFits:CGSizeMake(400, 40)].width);
        CGFloat w = MAX(tw + 64, 150), h = MAX(D, MIN(56, tr.size.height + 12));
        CGRect nf = CGRectMake(round(CGRectGetMidX(tr) - w / 2), round(CGRectGetMidY(tr) - h / 2), round(w), round(h));
        NSMutableString *txt = [NSMutableString string];
        for (UILabel *l in labels) if (l.text) [txt appendString:l.text];
        static NSString *lastTitle;
        if (lastTitle && ![txt isEqualToString:lastTitle] && !CGRectIsEmpty(gt.frame)) {
            // New photo: the capsule morphs to the new width and wobbles like liquid.
            [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.9
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                gt.frame = nf; [gt layoutIfNeeded];
            } completion:nil];
            CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
            sx.values = @[@1, @1.09, @0.95, @1.025, @1]; sx.keyTimes = @[@0, @0.18, @0.45, @0.72, @1]; sx.duration = 0.62;
            CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
            sy.values = @[@1, @0.88, @1.06, @0.98, @1]; sy.keyTimes = sx.keyTimes; sy.duration = 0.62;
            for (CAKeyframeAnimation *a in @[sx, sy]) a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [gt.layer addAnimation:sx forKey:@"wx"]; [gt.layer addAnimation:sy forKey:@"wy"];
            for (UIView *circle in @[GlassIn(c, @"back"), GlassIn(c, @"more")]) {
                CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
                s.values = @[@1, @0.9, @1.05, @0.99, @1]; s.keyTimes = sx.keyTimes; s.duration = 0.55; s.beginTime = CACurrentMediaTime() + 0.04;
                [circle.layer addAnimation:s forKey:@"w"];
            }
        } else SetFrame(gt, nf);
        lastTitle = [txt copy];
    }
    gTopDebug = [NSString stringWithFormat:@"back=%@ title=%@ more=%d edit=%d", NSStringFromClass([back class]), NSStringFromClass([title class]), moreView != nil, editView != nil];
}

#pragma mark - Years / Months / Days / All Photos bar

static __weak UIView *gSegBar;
static BOOL gSegShown = YES;
static NSString *gSegDebug = @"-";
#define SEG_SCALE 0.84

static UILabel *FindLabel(UIView *root, NSString *text, int maxDepth) {
    NSMutableArray *stack = [NSMutableArray arrayWithObject:root];
    int guard = 0;
    while (stack.count && guard++ < 6000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:[UICollectionViewCell class]]) continue;
        if ([v isKindOfClass:[UILabel class]] && [((UILabel *)v).text isEqualToString:text]) return (UILabel *)v;
        [stack addObjectsFromArray:v.subviews];
    }
    return nil;
}

static CGAffineTransform SegTransform(BOOL shown) {
    // Shrink around the bottom middle so it sits low and compact.
    CGAffineTransform t = CGAffineTransformMakeScale(SEG_SCALE, SEG_SCALE);
    if (!shown) t = CGAffineTransformConcat(CGAffineTransformMakeScale(0.7, 0.7), CGAffineTransformMakeTranslation(0, 110));
    return t;
}

static void SetSegShown(BOOL shown, BOOL animated) {
    UIView *bar = gSegBar;
    if (!bar) return;
    if (shown == gSegShown && animated) return;
    gSegShown = shown;
    void (^a)(void) = ^{ bar.transform = SegTransform(shown); bar.alpha = shown ? 1 : 0; };
    if (!animated) { a(); return; }
    if (shown)   // liquid bounce back in
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.9
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:a completion:nil];
    else
        [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn animations:a completion:nil];
}

static void StyleSegBar(UIView *bar);
static void StyleSegments(UIWindow *w) {
    if (!w || !gEnabled || HasScrubber(w)) return;
    UIView *bar = gSegBar;
    static CFTimeInterval lastSearch;
    if ((!bar || bar.window != w) && CACurrentMediaTime() - lastSearch > 1.0) {
        lastSearch = CACurrentMediaTime();
        UILabel *years = FindLabel(w, @"Years", 0);
        bar = nil;
        for (UIView *p = years.superview; p && p != w; p = p.superview) {
            if (FindLabel(p, @"All Photos", 0)) { bar = p; break; }
        }
        gSegBar = bar;
        if (bar) { gSegShown = YES; bar.transform = SegTransform(YES); }
        gSegDebug = bar ? [NSString stringWithFormat:@"%@ %.0fx%.0f", NSStringFromClass([bar class]), bar.bounds.size.width, bar.bounds.size.height] : @"not found";
    }
    if (!bar) return;
    StyleSegBar(bar);
}

// The dark capsule Apple draws behind the bar lives next to it, not inside it.
static void HideSegBackdrop(UIView *bar) {
    CGRect bf = [bar convertRect:bar.bounds toView:nil];
    UIView *child = bar;
    int up = 0;
    for (UIView *p = bar.superview; p && up < 3; child = p, p = p.superview, up++) {
        for (UIView *s in p.subviews) {
            if (s == child || [bar isDescendantOfView:s]) continue;
            CGRect f = [s convertRect:s.bounds toView:nil];
            BOOL near = fabs(CGRectGetMidY(f) - CGRectGetMidY(bf)) < 30 && f.size.height < bf.size.height * 2.5 && f.size.width >= bf.size.width * 0.8;
            if (!near) continue;
            NSString *n = NSStringFromClass([s class]);
            BOOL bg = [s isKindOfClass:[UIVisualEffectView class]] || [n containsString:@"Background"] || [n containsString:@"Blur"] || [n containsString:@"Material"] || [n containsString:@"Backdrop"] ||
                      (s.backgroundColor && CGColorGetAlpha(s.backgroundColor.CGColor) > 0.05 && s.layer.cornerRadius > 8);
            if (bg) Mask(s);
        }
        // An ancestor drawing the capsule itself.
        CGRect pf = [p convertRect:p.bounds toView:nil];
        if (pf.size.height < bf.size.height * 2.5 && p.layer.cornerRadius > 8 && p.backgroundColor && CGColorGetAlpha(p.backgroundColor.CGColor) > 0.05) p.backgroundColor = UIColor.clearColor;
    }
}

@interface PGSegDrop : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
static CGPoint gSegLastTap;
static BOOL gSegHasLast;
@implementation PGSegDrop
+ (instancetype)shared { static PGSegDrop *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [PGSegDrop new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)tap:(UITapGestureRecognizer *)g {
    UIView *bar = g.view;
    if (!gEnabled || !bar.window) return;
    // The label under the finger: the drop lands on it.
    CGPoint p = [g locationInView:bar];
    UILabel *best = nil; CGFloat bd = 1e9;
    NSMutableArray *st = [NSMutableArray arrayWithObject:bar];
    while (st.count) {
        UIView *v = st.lastObject; [st removeLastObject];
        if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) {
            CGPoint c = [v convertPoint:CGPointMake(v.bounds.size.width / 2, v.bounds.size.height / 2) toView:bar];
            if (fabs(c.x - p.x) < bd) { bd = fabs(c.x - p.x); best = (UILabel *)v; }
        }
        [st addObjectsFromArray:v.subviews];
    }
    if (!best) return;
    CGPoint to = [best convertPoint:CGPointMake(best.bounds.size.width / 2, best.bounds.size.height / 2) toView:bar];
    CGFloat H = bar.bounds.size.height - 8, W = MAX(best.bounds.size.width + 26, H * 1.6);
    CGPoint from = gSegHasLast ? gSegLastTap : to;
    gSegLastTap = to; gSegHasLast = YES;
    PGGlass *drop = [[PGGlass alloc] initWithFrame:CGRectMake(from.x - W / 2, to.y - H / 2, W, H)];
    drop.layer.cornerRadius = H / 2; drop.userInteractionEnabled = NO;
    [drop layoutSubviews];
    [bar addSubview:drop];
    CGFloat dist = fabs(to.x - from.x);
    // Stretch along the way, round off on arrival, then melt into the pill.
    [UIView animateKeyframesWithDuration:0.36 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.45 animations:^{
            drop.frame = CGRectMake((from.x + to.x) / 2 - (W + dist * 0.5) / 2, to.y - H * 0.42, W + dist * 0.5, H * 0.84); [drop layoutIfNeeded];
        }];
        [UIView addKeyframeWithRelativeStartTime:0.45 relativeDuration:0.55 animations:^{
            drop.frame = CGRectMake(to.x - W / 2, to.y - H / 2, W, H); [drop layoutIfNeeded];
        }];
    } completion:^(BOOL d) {
        [UIView animateWithDuration:0.18 animations:^{ drop.alpha = 0; } completion:^(BOOL f) { [drop removeFromSuperview]; }];
    }];
    // The whole bar gives a little jelly squish.
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    sx.values = @[@1, @1.04, @0.985, @1.01, @1]; sx.keyTimes = @[@0, @0.25, @0.55, @0.8, @1]; sx.duration = 0.5; sx.additive = NO;
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    sy.values = @[@1, @0.92, @1.04, @0.99, @1]; sy.keyTimes = sx.keyTimes; sy.duration = 0.5;
    // Applied to the glass, not the bar (the bar's own transform keeps it small).
    for (UIView *s in bar.subviews) if ([s isKindOfClass:[PGGlass class]] && s != drop) { [s.layer addAnimation:sx forKey:@"jx"]; [s.layer addAnimation:sy forKey:@"jy"]; }
}
@end
static void StyleSegBar(UIView *bar) {
    if (!gEnabled) return;
    static char kDropTap;
    if (!objc_getAssociatedObject(bar, &kDropTap)) {
        objc_setAssociatedObject(bar, &kDropTap, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:[PGSegDrop shared] action:@selector(tap:)];
        tg.cancelsTouchesInView = NO; tg.delaysTouchesBegan = NO; tg.delaysTouchesEnded = NO;
        tg.delegate = [PGSegDrop shared];
        [bar addGestureRecognizer:tg];
    }
    if (gSegBar != bar) { gSegBar = bar; gSegShown = YES; }
    HideSegBackdrop(bar);
    // Liquid glass instead of Apple's dark capsule (the selected-segment pill stays).
    CGSize S = bar.bounds.size;
    PGGlass *g = nil;
    for (UIView *s in bar.subviews) if ([s isKindOfClass:[PGGlass class]]) g = (PGGlass *)s;
    for (UIView *s in bar.subviews) {
        if (s == g) continue;
        BOOL full = s.bounds.size.width >= S.width * 0.9 && s.bounds.size.height >= S.height * 0.8;
        NSString *n = NSStringFromClass([s class]);
        BOOL bg = [s isKindOfClass:[UIVisualEffectView class]] || [n containsString:@"Background"] || [n containsString:@"Blur"] || [n containsString:@"Material"];
        if (full && bg) Mask(s);
    }
    if (bar.backgroundColor && CGColorGetAlpha(bar.backgroundColor.CGColor) > 0.05) bar.backgroundColor = UIColor.clearColor;
    if (!g) { g = [PGGlass new]; [bar insertSubview:g atIndex:0]; }
    SetFrame(g, bar.bounds);
    // Keep our size / hidden state if Apple resets it.
    if (!bar.layer.animationKeys.count && !CGAffineTransformEqualToTransform(bar.transform, SegTransform(gSegShown))) {
        bar.transform = SegTransform(gSegShown);
        bar.alpha = gSegShown ? 1 : 0;
    }
}

#pragma mark - grid top buttons (Select / Cancel / ...)

static const void *kOvlKind = &kOvlKind;
#define OVL_SHIFT 16
// Restyle one of Photos' grid buttons (Select / Cancel / ...) from the inside.
// Apple's own pieces stay where they are, only hidden (empty mask); the glass,
// text, X and dots are ours. Nothing of Apple's is moved, scaled or replaced.
static void StyleOverlayButton(UIView *b) {
    PGGlass *g = nil; UIImageView *x = nil, *d = nil; UILabel *t = nil;
    NSMutableArray *apple = [NSMutableArray array];
    for (UIView *s in b.subviews) {
        if ([s isKindOfClass:[PGGlass class]]) g = (PGGlass *)s;
        else if ([s.accessibilityIdentifier isEqualToString:@"ovl_x"]) x = (UIImageView *)s;
        else if ([s.accessibilityIdentifier isEqualToString:@"ovl_d"]) d = (UIImageView *)s;
        else if ([s.accessibilityIdentifier isEqualToString:@"ovl_t"]) t = (UILabel *)s;
        else [apple addObject:s];
    }
    // What is this button? Read it from Apple's (hidden) pieces.
    UILabel *label = nil; BOOL dots = NO;
    NSMutableArray *stack = [apple mutableCopy];
    while (stack.count) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) label = (UILabel *)v;
        else if ([v isKindOfClass:[UIImageView class]] && [((UIImageView *)v).image.description containsString:@"ellipsis"]) dots = YES;
        [stack addObjectsFromArray:v.subviews];
    }
    BOOL on = gEnabled && gTopBar && (label || dots);
    if (!on) {
        for (UIView *s in apple) Unmask(s);
        g.hidden = x.hidden = d.hidden = t.hidden = YES;
        return;
    }
    for (UIView *s in apple) Mask(s);
    if (b.backgroundColor && CGColorGetAlpha(b.backgroundColor.CGColor) > 0) b.backgroundColor = UIColor.clearColor;
    if (b.clipsToBounds) b.clipsToBounds = NO;
    if (!g) { g = [PGGlass new]; [b insertSubview:g atIndex:0]; }
    if (!t) {
        t = [UILabel new]; t.accessibilityIdentifier = @"ovl_t";
        t.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        t.textColor = GIcon(); t.textAlignment = NSTextAlignmentCenter; t.userInteractionEnabled = NO;
        [b addSubview:t];
    }
    if (!x) {
        x = [[UIImageView alloc] initWithImage:Sym(@"xmark", 18)]; x.accessibilityIdentifier = @"ovl_x";
        x.tintColor = GIcon(); x.contentMode = UIViewContentModeCenter; x.userInteractionEnabled = NO;
        [b addSubview:x];
    }
    if (!d) {
        d = [[UIImageView alloc] initWithImage:Sym(@"ellipsis", 21)]; d.accessibilityIdentifier = @"ovl_d";
        d.tintColor = GIcon(); d.contentMode = UIViewContentModeCenter; d.userInteractionEnabled = NO;
        [b addSubview:d];
    }
    g.hidden = x.hidden = d.hidden = t.hidden = NO;
    NSString *kind = dots ? @"more" : ([label.text isEqualToString:@"Cancel"] ? @"cancel" : @"text");
    BOOL cancel = [kind isEqualToString:@"cancel"], text = [kind isEqualToString:@"text"];
    if (text && ![t.text isEqualToString:label.text]) t.text = label.text;
    CGSize S = b.bounds.size;
    CGFloat H = 44, cx = S.width / 2 - (dots ? 0 : OVL_SHIFT), cy = S.height / 2;   // Select / X sit a bit left, away from ...
    CGRect nf;
    if (text) {
        CGFloat w = MAX(ceil([t.text sizeWithAttributes:@{NSFontAttributeName: t.font}].width) + 36, 88);
        nf = CGRectMake(round(cx - w / 2), round(cy - H / 2), w, H);
    } else nf = CGRectMake(round(cx - H / 2), round(cy - H / 2), H, H);
    NSString *old = objc_getAssociatedObject(b, kOvlKind);
    objc_setAssociatedObject(b, kOvlKind, kind, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    void (^apply)(void) = ^{
        g.frame = nf; [g layoutIfNeeded];
        t.frame = nf; x.frame = nf; d.frame = nf;
        t.alpha = text ? 1 : 0; x.alpha = cancel ? 1 : 0; d.alpha = dots ? 1 : 0;
    };
    if (old && ![old isEqualToString:kind] && !dots) {
        // Select <-> X: the capsule melts into a circle (and back).
        x.transform = CGAffineTransformMakeScale(cancel ? 0.4 : 1, cancel ? 0.4 : 1);
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.58 initialSpringVelocity:0.8
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            apply();
            x.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else if (!g.layer.animationKeys.count) {
        if (!CGRectEqualToRect(g.frame, nf) || t.alpha != (text ? 1 : 0)) apply();
    }
}

static NSString *gGridDebug = @"-";
static void UpdateDebug(UIWindow *w);
// Debug only for now: what the grid's top-right buttons are made of.
static void StyleGridTop(UIWindow *w) {
    if (!w || !gDebug || HasScrubber(w)) return;
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w];
    int guard = 0;
    while (stack.count && guard++ < 5000 && found.count < 4) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.hidden || [v isKindOfClass:[UICollectionViewCell class]]) continue;
        CGRect f = [v convertRect:v.bounds toView:nil];
        if (f.origin.y > w.bounds.size.height * 0.5) continue;
        BOOL hit = NO; NSString *what = @"";
        if (f.origin.y < 160 && [v isKindOfClass:[UILabel class]]) {
            NSString *s = ((UILabel *)v).text;
            if ([s isEqualToString:@"Select"] || [s isEqualToString:@"Cancel"]) { hit = YES; what = s; }
        } else if (f.origin.y < 160 && [v isKindOfClass:[UIImageView class]] && [((UIImageView *)v).image.description containsString:@"ellipsis"]) { hit = YES; what = @"..."; }
        if (hit) {
            NSMutableArray *chain = [NSMutableArray array];
            int d = 0;
            for (UIView *p = v.superview; p && d < 4; p = p.superview, d++) [chain addObject:[NSString stringWithFormat:@"%@%@", NSStringFromClass([p class]), p.alpha < 0.99 ? [NSString stringWithFormat:@"(a%.1f)", p.alpha] : @""]];
            [found addObject:[NSString stringWithFormat:@"%@ %.0f,%.0f: %@", what, f.origin.x, f.origin.y, [chain componentsJoinedByString:@" < "]]];
        }
        [stack addObjectsFromArray:v.subviews];
    }
    gGridDebug = found.count ? [found componentsJoinedByString:@"\n  "] : @"none";
    UpdateDebug(w);
}

#pragma mark - debug

static void UpdateDebug(UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug || !w) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = DEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.88];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSString *text = [NSString stringWithFormat:@" Photos26 2.1.1 debug\n bottom: %@\n top: %@\n video: %@\n bg: %@\n strip: %@\n grid top: %@\n segments: %@\n last tap: %@", gBottomDebug, gTopDebug, gVideoDebug, gBgDebug, gFilmDebug, gGridDebug, gSegDebug, gForwardDebug];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize sz = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    SetFrame(l, CGRectMake(12, w.bounds.size.height * 0.3, width, sz.height + 6));
    [w bringSubviewToFront:l];
}

#pragma mark - looping

static CFTimeInterval gLastPlayingAt;
static BOOL gLoopBusy;
static void ResumePlay(AVPlayer *p) {
    // Keep Apple's play button in step: press it if Apple thinks it's paused.
    UIBarButtonItem *play = AppleItem(@"play");
    if (play && ![ItemSymbolText(play) containsString:@"pause"]) Forward(play);
    else [p play];
}
static void LoopNow(AVPlayer *p) {
    if (!p || gLoopBusy) return;
    gLoopBusy = YES;
    [p seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL done) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (p.rate == 0) ResumePlay(p);
            gLoopBusy = NO;
        });
    }];
}
static void LoopTick(AVPlayer *p) {
    if (!p) return;
    static const void *kLoopSet = &kLoopSet;
    if (!objc_getAssociatedObject(p, kLoopSet)) {
        objc_setAssociatedObject(p, kLoopSet, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        p.actionAtItemEnd = AVPlayerActionAtItemEndNone;   // don't stop at the end
        __weak AVPlayer *wp = p;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            AVPlayer *pl = wp;
            if (pl && gLoop && gEnabled && n.object == pl.currentItem) LoopNow(pl);
        }];
    }
    CFTimeInterval now = CACurrentMediaTime();
    if (p.rate > 0) gLastPlayingAt = now;
    // Backup: it stopped right at the end just after playing.
    double d = Dur(p), cur = CMTimeGetSeconds(p.currentTime);
    if (p.rate == 0 && d > 0 && cur >= d - 0.2 && now - gLastPlayingAt < 0.8) LoopNow(p);
}

#pragma mark - taps and the per-frame update

@implementation PGTarget
+ (instancetype)shared { static PGTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [PGTarget new]; }); return t; }
- (void)down:(PGButton *)b { }
- (void)up:(PGButton *)b { }
- (void)tap:(PGButton *)b {
    NSString *k = b.kind;
    if ([k isEqualToString:@"edit"]) {
        UIBarButtonItem *ed = gEditItem;
        if (!ed) {
            // Find Apple's Edit in the top bar of this window.
            NSMutableArray *stack = [NSMutableArray arrayWithObject:b.window ?: [UIView new]];
            int guard = 0;
            while (stack.count && guard++ < 4000 && !ed) {
                UIView *v = stack.lastObject; [stack removeLastObject];
                if ([v isKindOfClass:[UINavigationBar class]])
                    for (UINavigationItem *ni in ((UINavigationBar *)v).items)
                        for (UIBarButtonItem *it in ni.rightBarButtonItems) if ([ItemKind(it) isEqualToString:@"edit"]) ed = it;
                [stack addObjectsFromArray:v.subviews];
            }
            gEditItem = ed;
        }
        Forward(ed);
    }
    BOOL wasFav = [ItemSymbolText(AppleItem(@"heart")) containsString:@"heart.fill"];
    if (![k isEqualToString:@"edit"]) Forward(AppleItem(k));
    if ([k isEqualToString:@"heart"]) {
        UIImageView *iv = b.imageView;
        CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        if (!wasFav) {
            // Favorited: the heart fills, pops, and little hearts burst out.
            b.accessibilityValue = @"heart.fill";
            [b setImage:Sym(@"heart.fill", 17) forState:UIControlStateNormal];
            pop.values = @[@1, @0.55, @1.45, @0.88, @1.08, @1];
            pop.keyTimes = @[@0, @0.12, @0.38, @0.6, @0.8, @1];
            pop.duration = 0.6;
            UIView *host = b.superview;
            CGPoint c = b.center;
            for (int i = 0; i < 8; i++) {
                UIImageView *h = [[UIImageView alloc] initWithImage:Sym(@"heart.fill", 7 + (i % 3) * 2)];
                h.tintColor = i % 2 ? UIColor.whiteColor : [UIColor colorWithRed:1 green:0.42 blue:0.55 alpha:1];
                h.center = c;
                h.alpha = 0;
                h.userInteractionEnabled = NO;
                [host addSubview:h];
                CGFloat a = (M_PI * 2 / 8) * i - M_PI_2 + ((i % 2) ? 0.2 : -0.1);
                CGFloat r = 30 + (i % 3) * 7;
                [UIView animateWithDuration:0.12 delay:0.08 options:0 animations:^{ h.alpha = 1; } completion:nil];
                [UIView animateWithDuration:0.6 delay:0.08 usingSpringWithDamping:0.7 initialSpringVelocity:0.9 options:0 animations:^{
                    h.center = CGPointMake(c.x + cos(a) * r, c.y + sin(a) * r);
                    h.transform = CGAffineTransformMakeRotation((i % 2 ? 0.4 : -0.4));
                } completion:nil];
                [UIView animateWithDuration:0.3 delay:0.42 options:0 animations:^{
                    h.alpha = 0; h.transform = CGAffineTransformScale(h.transform, 0.4, 0.4);
                } completion:^(BOOL d) { [h removeFromSuperview]; }];
            }
        } else {
            b.accessibilityValue = @"heart";
            [b setImage:Sym(@"heart", 17) forState:UIControlStateNormal];
            pop.values = @[@1, @0.7, @1.12, @1];
            pop.keyTimes = @[@0, @0.3, @0.65, @1];
            pop.duration = 0.4;
        }
        pop.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [iv.layer addAnimation:pop forKey:@"pop"];
    }
    // Apple's buttons change (heart fills, play becomes pause): refresh soon.
    for (NSNumber *d in @[@0.05, @0.25, @0.6])
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIToolbar *t = gToolbar; if (t) { @try { LayoutBottom(t); } @catch (__unused id e) {} }
        });
}
- (void)tick:(CADisplayLink *)link {
    UIToolbar *tb = gToolbar;
    UIView *c = [tb viewWithTag:BOTTOM_TAG];
    if (!tb.window || tb.hidden) gWasSelect = NO;
    if (!tb.window || !c || c.hidden) { [gLink invalidate]; gLink = nil; return; }
    static NSUInteger frame; frame++;
    @try {
        if (frame % 12 == 0) LayoutBottom(tb);
        if (frame % 20 == 9) StyleFilmstrip(tb.window);
        if (frame % 30 == 2) {
            UINavigationBar *n = gNavBar;
            CGFloat topBand = n.window ? CGRectGetMaxY([n convertRect:n.bounds toView:nil]) : 100;
            UIView *film = FindFilmstrip(tb.window, 0);
            CGFloat bottomBand = film ? [film convertRect:film.bounds toView:nil].origin.y : [tb convertRect:tb.bounds toView:nil].origin.y;
            HideBarBackgrounds(tb.window, topBand, bottomBand);
        }
        PGScrubber *scrub = nil;
        for (UIView *v in c.subviews) if ([v isKindOfClass:[PGScrubber class]]) scrub = (PGScrubber *)v;
        if (scrub && !scrub.hidden) {
            if (frame % 15 == 1 || !gAVPlayer) gAVPlayer = CurrentPlayer(tb.window);
            if (gLoop) LoopTick(gAVPlayer);
            AVPlayer *p = gAVPlayer;
            CMTime dur = p.currentItem.duration, now = p.currentTime;
            (void)dur;
            if (p && Dur(p) > 0 && !gScrubbing) scrub.progress = CMTimeGetSeconds(now) / Dur(p);
            gVideoDebug = [NSString stringWithFormat:@"using %.1f/%.1f r%.1f | %@", CMTimeGetSeconds(now), Dur(p), p.rate, gPlayersDebug];
        }
        if (frame % 10 == 0) UpdateDebug(tb.window);
        UINavigationBar *nb = gNavBar;
        if ((!nb || nb.window != tb.window) && frame % 30 == 3) {
            NSMutableArray *stack = [NSMutableArray arrayWithObject:tb.window];
            int guard = 0; nb = nil;
            while (stack.count && guard++ < 3000 && !nb) {
                UIView *v = stack.lastObject; [stack removeLastObject];
                if ([v isKindOfClass:[UINavigationBar class]] && !v.hidden && v.alpha > 0.01 && ((UINavigationBar *)v).topItem.rightBarButtonItems.count) nb = (UINavigationBar *)v;
                else [stack addObjectsFromArray:v.subviews];
            }
            if (nb) gNavBar = nb;
        }
        if (nb && frame % 12 == 6) LayoutTop(nb);
    } @catch (__unused id e) {}
}
@end

static void StartLink(void) {
    if (gLink) return;
    gLink = [CADisplayLink displayLinkWithTarget:[PGTarget shared] selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    [gLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - hooks

%hook UIToolbar
- (void)setHidden:(BOOL)h {
    %orig;
    if (h) gWasSelect = NO;
}
- (void)didMoveToWindow {
    %orig;
    if (!self.window) gWasSelect = NO;
}
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try { LayoutBottom(self); if ([self viewWithTag:BOTTOM_TAG] && ![self viewWithTag:BOTTOM_TAG].hidden) StartLink(); } @catch (__unused id e) {}
    objc_setAssociatedObject(self, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
// Our player capsule floats above the toolbar, outside its bounds.
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *c = [self viewWithTag:BOTTOM_TAG];
    if (c && !c.hidden && self.alpha > 0.01 && !self.hidden) {
        UIView *h = [c hitTest:[self convertPoint:p toView:c] withEvent:e];
        if (h) return h;
    }
    return %orig;
}
%end

%group SegCtl
%hook _PXCuratedLibraryZoomLevelSegmentedControl
// Styled the moment it lays out, so it never shows full size first.
- (void)layoutSubviews {
    %orig;
    @try { StyleSegBar(self); } @catch (__unused id e) {}
}
- (void)didMoveToWindow {
    %orig;
    if (self.window) { @try { StyleSegBar(self); } @catch (__unused id e) {} }
}
%end
%end

%group SegScroll
%hook _PXUIScrollView
// Scroll up: the Years/Months/Days bar hides. Scroll down: it bounces back.
- (void)setContentOffset:(CGPoint)o {
    CGFloat before = self.contentOffset.y;
    %orig;
    UIView *bar = gSegBar;
    if (!gEnabled || !bar || bar.window != self.window || self.bounds.size.height < 400) return;
    if (!(self.isDragging || self.isDecelerating)) return;
    static CGFloat run;
    CGFloat dy = o.y - before;
    if ((dy > 0) != (run > 0)) run = 0;
    run += dy;
    CGFloat maxY = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
    if (o.y >= maxY - 30) { SetSegShown(YES, YES); return; }
    if (run > 24) SetSegShown(YES, YES);
    else if (run < -24) SetSegShown(NO, YES);
}
%end
%end

%group Overlay
%hook PXCuratedLibraryOverlayButton
- (void)layoutSubviews {
    %orig;
    @try { StyleOverlayButton(self); } @catch (__unused id e) {}
}
// Easier to hit: a little extra touch area around each button.
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)e {
    if (gEnabled && gTopBar) {
        CGRect r = CGRectInset(self.bounds, -10, -8);
        r.origin.x -= OVL_SHIFT; r.size.width += OVL_SHIFT;   // the glass reaches further left
        if (CGRectContainsPoint(r, p)) return YES;
    }
    return %orig;
}
%end
%end

%group Scrubber
%hook PUTilingView
// Round thumbnails the moment they're laid out (only the small strip, not the big photo).
- (void)layoutSubviews {
    %orig;
    CGFloat H = self.bounds.size.height;
    if (!gEnabled || H < 12 || H > 130) return;
    for (UIView *a in self.subviews) {
        NSArray *list = [@[a] arrayByAddingObjectsFromArray:a.subviews];
        for (UIView *v in list) {
            if (!([v isKindOfClass:[UIImageView class]] || [NSStringFromClass([v class]) containsString:@"FilmstripWrapper"])) continue;
            if (v.bounds.size.height < H * 0.5) continue;
            if (v.layer.cornerRadius != 6) { v.layer.cornerRadius = 6; if (@available(iOS 13.0, *)) v.layer.cornerCurve = kCACornerCurveContinuous; }
            if (!v.layer.masksToBounds) v.layer.masksToBounds = YES;
        }
    }
}
%end
%hook PUScrubberView
// iOS 26 look: a video stays one thumbnail in the strip instead of spreading
// into frames (our glass slider does the scrubbing).
- (long long)_expandedItemType {
    if (gEnabled && gPlayer) return 0;
    return %orig;
}
%end
%end

%hook UINavigationBar
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try { LayoutTop(self); } @catch (__unused id e) {}
    objc_setAssociatedObject(self, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

static void InitOverlay(void) {
    static BOOL done; if (done) return; done = YES;
    %init(Overlay);
    if (objc_getClass("_PXUIScrollView")) %init(SegScroll);
    if (objc_getClass("_PXCuratedLibraryZoomLevelSegmentedControl")) %init(SegCtl);
}
static void InitScrubber(void) { static BOOL done; if (done) return; done = YES; %init(Scrubber); }

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.mobileslideshow"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
    // The grid's top buttons live outside the bars: check them a few times a second.
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *tm) {
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
            UIWindow *key = nil;
            for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
                if ([s isKindOfClass:[UIWindowScene class]]) for (UIWindow *w in ((UIWindowScene *)s).windows) if (w.isKeyWindow) key = w;
            @try { StyleGridTop(key); StyleSegments(key); } @catch (__unused id e) {}
        }];
    });
    // Photos' own classes load late on a cold start (right after a reboot it's
    // slower than 1.5s), so keep checking until both are there.
    if (objc_getClass("PXCuratedLibraryOverlayButton")) InitOverlay();
    if (objc_getClass("PUScrubberView")) InitScrubber();
    dispatch_async(dispatch_get_main_queue(), ^{
        __block int tries = 0;
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer *tm) {
            static BOOL ovl, scr;
            if (!ovl && objc_getClass("PXCuratedLibraryOverlayButton")) { InitOverlay(); ovl = YES; }
            if (!scr && objc_getClass("PUScrubberView")) { InitScrubber(); scr = YES; }
            if ((ovl && scr) || ++tries > 400) [tm invalidate];
        }];
    });
}
