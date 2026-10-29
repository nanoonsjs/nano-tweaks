// Spotlight26 0.1.0 - made by nano
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
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = ReadPrefsFile();
    gEnabled = PrefBool(f, @"enabled", YES);
    gTop     = PrefBool(f, @"top", YES);
    gNotch   = PrefBool(f, @"notch", YES);
    gCards   = PrefBool(f, @"cards", YES);
    gBounce  = PrefBool(f, @"bounce", YES);
    gDebug   = PrefBool(f, @"debug", NO);
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

static BOOL IsSpotlightField(UIView *f) {
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
static __weak UIViewController *gInsetVC;
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

static void ResetAll(void) {
    UIView *h = gHeader;
    if (h && !CGAffineTransformIsIdentity(h.transform)) h.transform = CGAffineTransformIdentity;
    [[h viewWithTag:PILL_TAG] removeFromSuperview];
    for (UIView *v in [gMaskedViews allObjects]) Unmask(v);
    [gMaskedViews removeAllObjects];
    for (UIView *v in [gCardViews allObjects]) [[v viewWithTag:CARD_TAG] removeFromSuperview];
    [gCardViews removeAllObjects];
    UIViewController *vc = gInsetVC;
    if (vc && objc_getAssociatedObject(vc, kInsetOurs)) {
        vc.additionalSafeAreaInsets = UIEdgeInsetsZero;
        objc_setAssociatedObject(vc, kInsetOurs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
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
    CGRect fr = [f convertRect:f.bounds toView:header];
    CGFloat h = 56, inset = 12;
    return CGRectMake(inset, CGRectGetMidY(fr) - h / 2, header.bounds.size.width - inset * 2, h);
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
        pill.radius = 0;
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

    // 2. Our black glass pill behind the field.
    HideHeaderBackgrounds(header, f, 0);
    S26Glass *pill = (S26Glass *)[header viewWithTag:PILL_TAG];
    if (pill.superview != header) pill = nil;
    CGRect pf = PillFrameIn(header, f);
    if (!pill) {
        pill = [[S26Glass alloc] initWithFrame:pf];
        pill.tag = PILL_TAG;
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

static void PushResults(UIView *header, UIView *scroll) {
    UIViewController *vc = OwnerVC(scroll);
    if (!vc) return;
    if (gInsetVC && gInsetVC != vc) {
        UIViewController *old = gInsetVC;
        if (objc_getAssociatedObject(old, kInsetOurs)) { old.additionalSafeAreaInsets = UIEdgeInsetsZero; objc_setAssociatedObject(old, kInsetOurs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    }
    gInsetVC = vc;
    CGFloat top = 0;
    if (gTop) {
        UIView *pill = [header viewWithTag:PILL_TAG];
        CGRect pw = [header convertRect:PillFrameIn(header, gField) toView:nil];  // where the pill ends up
        (void)pill;
        top = MAX(0, ceil(CGRectGetMaxY(pw) + 6 - header.window.safeAreaInsets.top));
    }
    if (fabs(vc.additionalSafeAreaInsets.top - top) > 0.5) {
        vc.additionalSafeAreaInsets = UIEdgeInsetsMake(top, 0, 0, 0);
        objc_setAssociatedObject(vc, kInsetOurs, top > 0 ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void FindCards(UIView *v, int d, CGFloat minW, NSMutableArray *out) {
    if (d > 9) return;
    for (UIView *s in v.subviews) {
        if (s.tag == CARD_TAG) continue;
        if (IsBackgroundish(s) && s.bounds.size.width >= minW && s.bounds.size.height >= 36 && s.alpha > 0.01 && !s.hidden) { [out addObject:s]; continue; }
        FindCards(s, d + 1, minW, out);
    }
}

static void StyleCards(UIView *scroll) {
    NSMutableArray *cards = [NSMutableArray array];
    FindCards(scroll, 0, scroll.bounds.size.width * 0.6, cards);
    NSMutableSet *classes = [NSMutableSet set];
    for (UIView *c in cards) {
        [classes addObject:NSStringFromClass([c class])];
        S26Glass *g = (S26Glass *)[c viewWithTag:CARD_TAG];
        if (g.superview != c) g = nil;
        if (!g) {
            g = [S26Glass new];
            g.tag = CARD_TAG;
            [c addSubview:g];
            [gCardViews addObject:c];
        }
        CGFloat r = c.layer.cornerRadius;
        if (r < 1) r = c.superview.layer.cornerRadius;
        g.radius = r > 1 ? r : 20;
        SetFrame(g, c.bounds);
        [g setNeedsLayout];
    }
    if (gDebug) gCardsDebug = [NSString stringWithFormat:@"%lu %@", (unsigned long)cards.count, [[classes allObjects] componentsJoinedByString:@","]];
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
    NSString *text = [NSString stringWithFormat:@" Spotlight26 0.1.0 debug\n field: %@ %@\n chain: %@\n vcs: %@\n header: %@ ty=%.0f\n results: %@ inset=%.0f vc=%@\n cards: %@",
                      NSStringFromClass([f class]), NSStringFromCGRect([f convertRect:f.bounds toView:nil]),
                      [chain componentsJoinedByString:@" > "], [vcs componentsJoinedByString:@" > "],
                      NSStringFromClass([h class]), h.transform.ty,
                      s ? NSStringFromClass([s class]) : @"none", s.adjustedContentInset.top, NSStringFromClass([gInsetVC class]), gCardsDebug];
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
    gFrame++;
    @try {
        UIView *h = gHeader;
        if (!h || ![f isDescendantOfView:h]) { h = FindHeader(f); gHeader = h; }
        if (!gEnabled) { ResetAll(); UpdateDebug(f.window); return; }
        StylePill(h, f);
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

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.springboard"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    [[NSNotificationCenter defaultCenter] addObserver:[S26Ticker shared] selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
    %init;
}
