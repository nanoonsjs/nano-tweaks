// Spotlight26 0.1.3 - made by nano
// 0.1.3: grows out of the notch every time Spotlight opens, big iOS 26 top
//        pill, status bar hidden, black glass on the suggestion cards,
//        results pushed below the pill with contentInset.
// 0.1.2: loads into any process using Spotlight's UI frameworks, scans for the
//        search field itself, and the debug box shows even with no field.
// 0.1.1: iOS 16 runs Spotlight as its own app (com.apple.Spotlight), so the
//        tweak now loads there too. Debug shows which process it's in.
// iOS 26 style Spotlight for iOS 16 (rootless, SpringBoard).
//  - The search bar moves to the top and grows out of the notch into a black
//    glass pill (Apple's search header is only moved with a transform; its
//    layout is never touched).
//  - Results get pushed below the pill (additionalSafeAreaInsets) and sit on
//    black glass cards (our view added inside Apple's card backgrounds).
//  - The pill does a small jelly bounce while typing.
// Spotlight's classes are found at runtime from its text field, so nothing
// here depends on exact private class names.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define DOM_NS @"com.user.spotlight26"
#define DOM CFSTR("com.user.spotlight26")
#define NOTIFY CFSTR("com.user.spotlight26/prefschanged")
#define PILL_TAG   0x53323630
#define DEBUG_TAG  0x53323631
#define CARD_TAG   0x53323632
#define PILL_RADIUS 40

static BOOL gHideSB = YES;
static BOOL gEnabled = YES, gTop = YES, gNotch = YES, gCards = YES, gBounce = YES, gDebug = NO;

static const void *kMasked = &kMasked;
static const void *kInsetOurs = &kInsetOurs;

#pragma mark - prefs

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
static NSString *gPrefsSource = @"?";
static BOOL gPrefsUnreadable;
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = ReadPrefsFile();
    gPrefsSource = f ? @"file" : @"none";
    gPrefsUnreadable = (f == nil);
    gEnabled = PrefBool(f, @"enabled", YES);
    gTop     = PrefBool(f, @"top", YES);
    gNotch   = PrefBool(f, @"notch", YES);
    gCards   = PrefBool(f, @"cards", YES);
    gBounce  = PrefBool(f, @"bounce", YES);
    gDebug   = PrefBool(f, @"debug", NO);
    gHideSB  = PrefBool(f, @"statusbar", YES);
    // Can't read the settings here at all? Show the debug box so we can tell.
    if (gPrefsUnreadable && !CFPreferencesCopyAppValue(CFSTR("debug"), DOM)) gDebug = YES;
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ LoadPrefs(); });
}

#pragma mark - helpers

static void SetFrame(UIView *v, CGRect f) { if (!CGRectEqualToRect(v.frame, f)) v.frame = f; }

static UIViewController *OwnerVC(UIView *v) {
    UIResponder *r = v; int d = 0;
    while (r && d++ < 60 && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
    return [r isKindOfClass:[UIViewController class]] ? (UIViewController *)r : nil;
}

static BOOL gInSpotlightApp;
static BOOL IsSpotlightField(UIView *f) {
    if (gInSpotlightApp) return YES;
    int d = 0;
    for (UIView *p = f; p && d < 30; p = p.superview, d++) {
        NSString *n = NSStringFromClass([p class]);
        if ([n hasPrefix:@"SPUI"] || [n containsString:@"Spotlight"]) return YES;
    }
    UIViewController *vc = OwnerVC(f);
    for (UIViewController *p = vc; p; p = p.parentViewController) {
        NSString *n = NSStringFromClass([p class]);
        if ([n hasPrefix:@"SPUI"] || [n containsString:@"Spotlight"]) return YES;
    }
    return NO;
}

static BOOL IsBackgroundish(UIView *v) {
    if ([v isKindOfClass:[UIVisualEffectView class]]) return YES;
    NSString *n = NSStringFromClass([v class]);
    return [n containsString:@"Background"] || [n containsString:@"Backdrop"] || [n containsString:@"Material"] || [n containsString:@"Blur"] || [n containsString:@"Platter"];
}

static void Mask(UIView *v) {
    if (objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = [CALayer layer];   // draws nothing; Apple never touches masks here
    objc_setAssociatedObject(v, kMasked, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void Unmask(UIView *v) {
    if (!objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = nil;
    objc_setAssociatedObject(v, kMasked, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - black glass

@interface S26Glass : UIView
@property (nonatomic, strong) CAGradientLayer *sheen;
@property (nonatomic) CGFloat radius;
@end
@implementation S26Glass
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.62];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.13].CGColor;
    if (@available(iOS 13.0, *)) self.layer.cornerCurve = kCACornerCurveContinuous;
    _sheen = [CAGradientLayer layer];
    _sheen.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.13].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                      (id)[UIColor colorWithWhite:1 alpha:0].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor];
    _sheen.locations = @[@0, @0.35, @0.8, @1];
    [self.layer addSublayer:_sheen];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat r = _radius > 0 ? MIN(_radius, self.bounds.size.height / 2) : self.bounds.size.height / 2;
    self.layer.cornerRadius = r;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _sheen.frame = self.bounds; _sheen.cornerRadius = r;
    [CATransaction commit];
}
@end

#pragma mark - state

static __weak UITextField *gField;
static __weak UIView *gHeader, *gScroll;
static __weak id gInsetVC;   // the results scroll view we added inset to
static CADisplayLink *gLink;
static BOOL gAppeared;          // notch animation already played for this opening
static NSUInteger gFrame;
static NSString *gCardsDebug = @"-";
static NSHashTable *gMaskedViews, *gCardViews;

@interface S26Ticker : NSObject
+ (instancetype)shared;
- (void)tick:(CADisplayLink *)l;
- (void)textChanged:(NSNotification *)n;
@end

static void StartLink(void) {
    if (gLink) return;
    gLink = [CADisplayLink displayLinkWithTarget:[S26Ticker shared] selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    [gLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

// The search header: the highest ancestor of the field that is screen-wide but short.
static UIView *FindHeader(UITextField *f) {
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    UIView *best = nil; int d = 0;
    for (UIView *p = f.superview; p && d < 8; p = p.superview, d++) {
        if (p.bounds.size.height > 160) break;
        if ([NSStringFromClass([p class]) containsString:@"Header"]) return p;
        if (p.bounds.size.width >= W * 0.9) best = p;
    }
    return best ?: f.superview;
}

static void CollectScrolls(UIView *v, int d, UIView *skip, NSMutableArray *out) {
    if (v == skip || d > 12) return;
    for (UIView *s in v.subviews) {
        if (s == skip) continue;
        if ([s isKindOfClass:[UIScrollView class]]) [out addObject:s];
        CollectScrolls(s, d + 1, skip, out);
    }
}

static UIView *FindResults(UIView *header) {
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    UIView *root = header;
    for (int d = 0; root.superview && d < 10; d++) {
        root = root.superview;
        if (root.bounds.size.height >= UIScreen.mainScreen.bounds.size.height * 0.9) break;
    }
    NSMutableArray *all = [NSMutableArray array];
    CollectScrolls(root, 0, header, all);
    UIScrollView *best = nil;
    for (UIScrollView *s in all) {
        if (s.bounds.size.width < W * 0.9 || s.bounds.size.height < 250 || !s.window || s.hidden) continue;
        if (!best || s.bounds.size.height * s.bounds.size.width > best.bounds.size.height * best.bounds.size.width) best = s;
    }
    return best;
}

static void SetOurInset(UIScrollView *s, CGFloat ours);
static void ShowStatusBar(void);
static void ResetAll(void) {
    ShowStatusBar();
    UIView *h = gHeader;
    if (h && !CGAffineTransformIsIdentity(h.transform)) h.transform = CGAffineTransformIdentity;
    [[h viewWithTag:PILL_TAG] removeFromSuperview];
    for (UIView *v in [gMaskedViews allObjects]) Unmask(v);
    [gMaskedViews removeAllObjects];
    for (UIView *v in [gCardViews allObjects]) [[v viewWithTag:CARD_TAG] removeFromSuperview];
    [gCardViews removeAllObjects];
    UIScrollView *s = gInsetVC;
    if ([s isKindOfClass:[UIScrollView class]]) SetOurInset(s, 0);
}

#pragma mark - search pill

// Hide Apple's field capsule and header backdrop (only background-type views).
static void HideHeaderBackgrounds(UIView *v, UITextField *f, int d) {
    if (d > 4) return;
    for (UIView *s in v.subviews) {
        if (s.tag == PILL_TAG || s == f) {
            if (s == f) for (UIView *fs in f.subviews) if (IsBackgroundish(fs)) { Mask(fs); [gMaskedViews addObject:fs]; }
            continue;
        }
        if (IsBackgroundish(s) && ![s isDescendantOfView:f] && ![f isDescendantOfView:s]) { Mask(s); [gMaskedViews addObject:s]; continue; }
        HideHeaderBackgrounds(s, f, d + 1);
    }
}

static CGRect PillFrameIn(UIView *header, UITextField *f) {
    // iOS 26: one big black glass shape from just under the top edge to below
    // the field, nearly the full width.
    CGRect fr = [f convertRect:f.bounds toView:header];
    CGFloat inset = 9;
    CGFloat top = [header convertPoint:CGPointMake(0, 7) fromView:nil].y;
    CGFloat bottom = CGRectGetMidY(fr) + 31;
    if (!gTop || bottom - top > 140 || bottom - top < 56) { top = CGRectGetMidY(fr) - 28; bottom = CGRectGetMidY(fr) + 28; }
    return CGRectMake(inset, top, header.bounds.size.width - inset * 2, bottom - top);
}

static void PlayNotchGrow(S26Glass *pill, UIView *header, UITextField *f) {
    UIWindow *w = header.window;
    CGRect final = pill.frame;
    BOOL notch = w.safeAreaInsets.top > 40;
    CGFloat nw = notch ? 164 : 120, nh = notch ? 32 : 30;
    CGRect start = [header convertRect:CGRectMake((w.bounds.size.width - nw) / 2, notch ? -2 : 10, nw, nh) fromView:nil];
    pill.radius = 16;
    pill.frame = start;
    pill.backgroundColor = UIColor.blackColor;   // blends into the notch
    pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0].CGColor;
    [pill layoutIfNeeded];
    // field contents fade in once the pill has dropped
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @0; fade.toValue = @1;
    fade.beginTime = CACurrentMediaTime() + 0.16; fade.duration = 0.28;
    fade.fillMode = kCAFillModeBackwards;
    [f.layer addAnimation:fade forKey:@"s26fade"];
    [UIView animateWithDuration:0.62 delay:0.02 usingSpringWithDamping:0.74 initialSpringVelocity:0.4
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
        pill.radius = PILL_RADIUS;
        pill.frame = final;
        [pill layoutIfNeeded];
        pill.backgroundColor = [UIColor colorWithWhite:0 alpha:0.82];
    } completion:nil];
    [UIView animateWithDuration:0.4 delay:0.25 options:0 animations:^{
        pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    } completion:nil];
}

static void StylePill(UIView *header, UITextField *f) {
    UIWindow *w = header.window;
    // 1. Move the header so the field sits just under the notch.
    if (gTop) {
        CGPoint origin = [header.superview convertPoint:CGPointMake(0, header.center.y - header.bounds.size.height / 2) toView:nil];
        CGFloat fieldMid = CGRectGetMidY([f convertRect:f.bounds toView:header]);
        CGFloat targetMid = w.safeAreaInsets.top > 40 ? w.safeAreaInsets.top + 20 : w.safeAreaInsets.top + 34;
        CGFloat ty = round(targetMid - (origin.y + fieldMid));
        if (fabs(header.transform.ty - ty) > 0.5 || header.transform.a != 1) header.transform = CGAffineTransformMakeTranslation(0, ty);
    } else if (!CGAffineTransformIsIdentity(header.transform)) header.transform = CGAffineTransformIdentity;

    // 2. Our black glass pill behind the field (it reaches above the header).
    if (header.clipsToBounds) header.clipsToBounds = NO;
    HideHeaderBackgrounds(header, f, 0);
    S26Glass *pill = (S26Glass *)[header viewWithTag:PILL_TAG];
    if (pill.superview != header) pill = nil;
    CGRect pf = PillFrameIn(header, f);
    if (!pill) {
        pill = [[S26Glass alloc] initWithFrame:pf];
        pill.tag = PILL_TAG;
        pill.radius = PILL_RADIUS;
        pill.backgroundColor = [UIColor colorWithWhite:0 alpha:0.82];
        pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
        [header insertSubview:pill atIndex:0];
        if (!gAppeared && gNotch && gTop) PlayNotchGrow(pill, header, f);
        gAppeared = YES;
    } else if (![pill.layer animationForKey:@"position"] && ![pill.layer animationForKey:@"bounds"] && !pill.layer.animationKeys.count) {
        SetFrame(pill, pf);
    }
    if (header.subviews.firstObject != pill) [header sendSubviewToBack:pill];
}

#pragma mark - results

static void SetOurInset(UIScrollView *s, CGFloat ours) {
    CGFloat prev = [objc_getAssociatedObject(s, kInsetOurs) doubleValue];
    if (fabs(prev - ours) < 0.5) return;
    UIEdgeInsets in = s.contentInset;
    in.top += ours - prev;
    BOOL atTop = s.contentOffset.y <= -s.adjustedContentInset.top + 1;
    s.contentInset = in;
    if (atTop) s.contentOffset = CGPointMake(s.contentOffset.x, -s.adjustedContentInset.top);
    objc_setAssociatedObject(s, kInsetOurs, ours > 0 ? @(ours) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void PushResults(UIView *header, UIView *scroll) {
    if (![scroll isKindOfClass:[UIScrollView class]]) return;
    UIScrollView *s = (UIScrollView *)scroll;
    if (gInsetVC != (id)s) {
        UIScrollView *old = (UIScrollView *)gInsetVC;
        if ([old isKindOfClass:[UIScrollView class]]) SetOurInset(old, 0);
        gInsetVC = (id)s;
    }
    CGFloat ours = 0;
    if (gTop) {
        CGRect pw = [header convertRect:PillFrameIn(header, gField) toView:nil];   // where the pill ends up
        CGFloat contentTop = [s convertPoint:CGPointMake(0, -s.adjustedContentInset.top + [objc_getAssociatedObject(s, kInsetOurs) doubleValue]) toView:nil].y;
        // contentTop: where results start without us (window coords, at scroll top)
        CGFloat startY = [s.superview convertPoint:s.frame.origin toView:nil].y + (s.adjustedContentInset.top - [objc_getAssociatedObject(s, kInsetOurs) doubleValue]);
        (void)contentTop;
        ours = MAX(0, ceil(CGRectGetMaxY(pw) + 10 - startY));
    }
    SetOurInset(s, ours);
}

// A card: a wide, short-ish view with rounded corners (or a background-type view).
static BOOL IsCard(UIView *s, CGFloat minW) {
    if (s.tag == CARD_TAG || s.hidden || s.alpha < 0.01) return NO;
    CGSize z = s.bounds.size;
    if (z.width < minW || z.height < 36 || z.height > 600) return NO;
    return s.layer.cornerRadius >= 8 || IsBackgroundish(s);
}
static void FindCards(UIView *v, int d, CGFloat minW, NSMutableArray *out) {
    if (d > 9) return;
    for (UIView *s in v.subviews) {
        if (s.tag == CARD_TAG) continue;
        if (IsCard(s, minW)) { [out addObject:s]; continue; }
        FindCards(s, d + 1, minW, out);
    }
}

static void StyleCards(UIView *scroll) {
    NSMutableArray *cards = [NSMutableArray array];
    FindCards(scroll, 0, scroll.bounds.size.width * 0.6, cards);
    NSMutableArray *info = [NSMutableArray array];
    for (UIView *c in cards) {
        if (info.count < 4) {
            CGFloat a = 0; [c.backgroundColor getWhite:NULL alpha:&a];
            NSMutableArray *subs = [NSMutableArray array];
            for (UIView *x in c.subviews) if (subs.count < 3) [subs addObject:NSStringFromClass([x class])];
            [info addObject:[NSString stringWithFormat:@"%@ r=%.0f bg=%.2f [%@]", NSStringFromClass([c class]), c.layer.cornerRadius, a, [subs componentsJoinedByString:@","]]];
        }
        S26Glass *g = (S26Glass *)[c viewWithTag:CARD_TAG];
        if (g.superview != c) g = nil;
        if (!g) {
            g = [S26Glass new];
            g.tag = CARD_TAG;
            g.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
            [gCardViews addObject:c];
        }
        // Sit just above Apple's own background pieces, below the icons and text.
        if (g.superview != c) {
            NSInteger at = 0;
            for (NSUInteger i = 0; i < c.subviews.count; i++) if (IsBackgroundish(c.subviews[i])) at = i + 1;
            [c insertSubview:g atIndex:at];
        }
        CGFloat r = c.layer.cornerRadius;
        if (r < 1) r = c.superview.layer.cornerRadius;
        g.radius = r > 1 ? r : 22;
        SetFrame(g, c.bounds);
    }
    if (gDebug) gCardsDebug = [NSString stringWithFormat:@"%lu\n   %@", (unsigned long)cards.count, [info componentsJoinedByString:@"\n   "]];
}

#pragma mark - status bar

static const void *kSBOrig = &kSBOrig;
static __weak UIViewController *gSBVC;
static BOOL gSBHidden;
static void HookStatusBarFor(UIViewController *vc) {
    if (!vc) return;
    Class c = [vc class];
    if (objc_getAssociatedObject(c, kSBOrig)) return;
    SEL sel = @selector(prefersStatusBarHidden);
    IMP orig = class_getMethodImplementation(c, sel);
    IMP mine = imp_implementationWithBlock(^BOOL(id me) {
        if (gSBHidden) return YES;
        return ((BOOL (*)(id, SEL))orig)(me, sel);
    });
    Method m = class_getInstanceMethod(c, sel);
    class_replaceMethod(c, sel, mine, method_getTypeEncoding(m));
    SEL child = @selector(childViewControllerForStatusBarHidden);
    IMP origChild = class_getMethodImplementation(c, child);
    IMP mineChild = imp_implementationWithBlock(^UIViewController *(id me) {
        if (gSBHidden) return nil;
        return ((UIViewController *(*)(id, SEL))origChild)(me, child);
    });
    class_replaceMethod(c, child, mineChild, method_getTypeEncoding(class_getInstanceMethod(c, child)));
    objc_setAssociatedObject(c, kSBOrig, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void HideStatusBar(UIWindow *w) {
    UIViewController *vc = w.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    if (!vc) return;
    HookStatusBarFor(w.rootViewController);
    HookStatusBarFor(vc);
    gSBVC = vc;
    if (!gSBHidden) {
        gSBHidden = YES;
        [UIView animateWithDuration:0.2 animations:^{ [vc setNeedsStatusBarAppearanceUpdate]; [w.rootViewController setNeedsStatusBarAppearanceUpdate]; }];
    }
}
static void ShowStatusBar(void) {
    if (!gSBHidden) return;
    gSBHidden = NO;
    UIViewController *vc = gSBVC;
    [vc setNeedsStatusBarAppearanceUpdate];
    [vc.view.window.rootViewController setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - debug

static void UpdateDebug(UIWindow *w) {
    static __weak UILabel *last;
    UILabel *l = w ? (UILabel *)[w viewWithTag:DEBUG_TAG] : last;
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
    last = l;
    UITextField *f = gField; UIView *h = gHeader; UIScrollView *s = (UIScrollView *)gScroll;
    NSMutableArray *chain = [NSMutableArray array];
    int d = 0;
    for (UIView *p = f.superview; p && d < 6; p = p.superview, d++) [chain addObject:[NSString stringWithFormat:@"%@(%.0f)", NSStringFromClass([p class]), p.bounds.size.height]];
    NSMutableArray *vcs = [NSMutableArray array];
    for (UIViewController *p = OwnerVC(f); p; p = p.parentViewController) [vcs addObject:NSStringFromClass([p class])];
    NSString *sbInfo = [NSString stringWithFormat:@"sb: hidden=%d vc=%@ root=%@", gSBHidden, NSStringFromClass([gSBVC class]), NSStringFromClass([w.rootViewController class])];
    NSString *text = [NSString stringWithFormat:@" %@\n Spotlight26 0.1.3 debug (%@) prefs=%@\n field: %@ %@\n chain: %@\n vcs: %@\n header: %@ ty=%.0f\n results: %@ inset=%.0f ours=%@\n cards: %@",
                      sbInfo, [[NSBundle mainBundle] bundleIdentifier], gPrefsSource, NSStringFromClass([f class]), NSStringFromCGRect([f convertRect:f.bounds toView:nil]),
                      [chain componentsJoinedByString:@" > "], [vcs componentsJoinedByString:@" > "],
                      NSStringFromClass([h class]), h.transform.ty,
                      s ? NSStringFromClass([s class]) : @"none", s.adjustedContentInset.top, objc_getAssociatedObject(s, kInsetOurs), gCardsDebug];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize sz = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    SetFrame(l, CGRectMake(12, w.bounds.size.height * 0.36, width, sz.height + 6));
    [w bringSubviewToFront:l];
}

#pragma mark - tick

@implementation S26Ticker
+ (instancetype)shared { static S26Ticker *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [S26Ticker new]; }); return t; }
- (void)tick:(CADisplayLink *)link {
    UITextField *f = gField;
    if (!f || !f.window) {
        @try { ResetAll(); } @catch (__unused id e) {}
        [gLink invalidate]; gLink = nil;
        gAppeared = NO;
        return;
    }
    // Spotlight can stay in its window while closed: idle slowly until it shows again.
    BOOL visible = !f.window.hidden;
    for (UIView *p = f; p && visible; p = p.superview) if (p.hidden || p.alpha < 0.01) visible = NO;
    if (visible && !CGRectIntersectsRect([f convertRect:f.bounds toView:nil], f.window.bounds)) visible = NO;
    if (!visible) {
        if (gAppeared) { @try { ResetAll(); } @catch (__unused id e) {} gAppeared = NO; }
        if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(4, 4, 4);
        UpdateDebug(nil);
        return;
    }
    if (@available(iOS 15.0, *)) if (gLink.preferredFrameRateRange.preferred != 60) gLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    // Spotlight's app is frozen while closed, so a gap between frames means it
    // was just opened again: grow out of the notch again.
    static CFTimeInterval lastStamp;
    if (lastStamp > 0 && link.timestamp - lastStamp > 0.35) {
        @try { ResetAll(); } @catch (__unused id e) {}
        gAppeared = NO;
    }
    lastStamp = link.timestamp;
    gFrame++;
    @try {
        UIView *h = gHeader;
        if (!h || ![f isDescendantOfView:h]) { h = FindHeader(f); gHeader = h; }
        if (!gEnabled) { ResetAll(); UpdateDebug(f.window); return; }
        StylePill(h, f);
        if (gHideSB && gInSpotlightApp) HideStatusBar(f.window); else ShowStatusBar();
        UIView *s = gScroll;
        if (!s || !s.window || gFrame % 30 == 0) { s = FindResults(h); gScroll = s; }
        if (s) {
            PushResults(h, s);
            if (gCards && gFrame % 6 == 0) StyleCards(s);
        }
        if (gFrame % 6 == 0) UpdateDebug(f.window);
    } @catch (__unused id e) {}
}
- (void)textChanged:(NSNotification *)n {
    if (n.object != gField || !gEnabled || !gBounce) return;
    UIView *pill = [gHeader viewWithTag:PILL_TAG];
    if (!pill || pill.layer.animationKeys.count) return;
    // A quick squish and spring back each keystroke.
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{
        pill.transform = CGAffineTransformMakeScale(1.025, 0.95);
    } completion:^(BOOL d) {
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.42 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            pill.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}
@end

#pragma mark - hooks

%hook UITextField
- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;
    @try {
        if (!IsSpotlightField(self)) return;
        if (gField != self) { gAppeared = NO; gHeader = nil; gScroll = nil; }
        gField = self;
        if (!gMaskedViews) gMaskedViews = [NSHashTable weakObjectsHashTable];
        if (!gCardViews) gCardViews = [NSHashTable weakObjectsHashTable];
        StartLink();
    } @catch (__unused id e) {}
}
%end

#pragma mark - field scanner

static UITextField *ScanForField(UIView *v, int d) {
    if (d > 30) return nil;
    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UITextField class]] && s.window && !s.hidden && IsSpotlightField(s)) return (UITextField *)s;
        UITextField *f = ScanForField(s, d + 1);
        if (f) return f;
    }
    return nil;
}

static NSArray *AllWindows(void) {
    NSMutableArray *ws = [NSMutableArray array];
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes)
        if ([sc isKindOfClass:[UIWindowScene class]]) [ws addObjectsFromArray:((UIWindowScene *)sc).windows];
    for (UIWindow *w in UIApplication.sharedApplication.windows) if (![ws containsObject:w]) [ws addObject:w];
    return ws;
}

static BOOL gInSpringBoard;
static void Scan(void) {
    UITextField *f = gField;
    if (!f || !f.window) {
        for (UIWindow *w in AllWindows()) {
            if (w.hidden) continue;
            if (gInSpringBoard) {
                NSString *n = [NSStringFromClass([w class]) stringByAppendingString:NSStringFromClass([w.rootViewController class]) ?: @""];
                if (!([n containsString:@"Spotlight"] || [n containsString:@"SPUI"] || [n containsString:@"Search"])) continue;
            }
            f = ScanForField(w, 0);
            if (f) break;
        }
        if (f) { gField = f; gAppeared = NO; gHeader = nil; gScroll = nil; StartLink(); }
    }
    // With no field yet, still show the debug box on the key window.
    if (!gField && gDebug && gInSpotlightApp) {
        UIWindow *key = nil;
        for (UIWindow *w in AllWindows()) if (w.isKeyWindow) key = w;
        if (!key) key = AllWindows().firstObject;
        UpdateDebug(key);
    }
}

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    gInSpringBoard = [bid isEqualToString:@"com.apple.springboard"];
    // Only Spotlight's own app treats every field as the search field; other
    // processes that use Spotlight's frameworks go by the class check.
    gInSpotlightApp = [bid rangeOfString:@"spotlight" options:NSCaseInsensitiveSearch].location != NSNotFound;
    if (!gMaskedViews) gMaskedViews = [NSHashTable weakObjectsHashTable];
    if (!gCardViews) gCardViews = [NSHashTable weakObjectsHashTable];
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    [[NSNotificationCenter defaultCenter] addObserver:[S26Ticker shared] selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
    // Spotlight's app stays alive between pulls: replay the notch grow each time it comes back.
    for (NSString *name in @[UIApplicationWillEnterForegroundNotification, UISceneWillEnterForegroundNotification, UIApplicationDidEnterBackgroundNotification])
        [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            @try { ResetAll(); } @catch (__unused id e) {}
            gAppeared = NO;
            if (gField.window) StartLink();
        }];
    %init;
    if (gInSpringBoard || gInSpotlightApp) dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:gInSpringBoard ? 1.5 : 0.7 repeats:YES block:^(NSTimer *tm) { @try { Scan(); } @catch (__unused id e) {} }];
    });
}
