// Spotlight26 0.2.0 - made by nano
// 0.2.0: no flicker (the pill stays pinned and retracts into the notch when
//        Spotlight closes), liquid two-spring notch stretch + rim shine,
//        iOS 26 resting look (only the app icons, on black glass, no section
//        titles or other rows), "Search or Ask", no magnifier.
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

static BOOL gHideSB = YES, gRest = YES;
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
    gRest    = PrefBool(f, @"rest", YES);
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
static __weak UIView *gHeader;
static NSHashTable *gScrolls;          // Spotlight's result collection views
static CADisplayLink *gLink;
static BOOL gAppeared;                 // the grow already ran for this opening
static NSUInteger gFrame;
static NSString *gCardsDebug = @"-", *gBandDebug = @"-";
static NSHashTable *gMaskedViews, *gCardViews;
static NSString *gOrigPlaceholder;

@interface S26Ticker : NSObject
+ (instancetype)shared;
- (void)tick:(CADisplayLink *)l;
- (void)textChanged:(NSNotification *)n;
@end

static void StartLink(void) {
    if (gLink) return;
    gLink = [CADisplayLink displayLinkWithTarget:[S26Ticker shared] selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    [gLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

static BOOL ReallyVisible(UIView *v) {
    if (!v.window || v.window.hidden) return NO;
    for (UIView *p = v; p; p = p.superview) if (p.hidden || p.alpha < 0.01) return NO;
    return YES;
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

static UIView *RootFor(UIView *header) {
    UIView *root = header;
    for (int d = 0; root.superview && d < 10; d++) {
        root = root.superview;
        if (root.bounds.size.height >= UIScreen.mainScreen.bounds.size.height * 0.9) break;
    }
    return root;
}

static void CollectScrolls(UIView *v, int d, UIView *skip, NSMutableArray *out) {
    if (v == skip || d > 12) return;
    for (UIView *s in v.subviews) {
        if (s == skip) continue;
        if ([s isKindOfClass:[UIScrollView class]]) [out addObject:s];
        CollectScrolls(s, d + 1, skip, out);
    }
}

static void FindResults(UIView *header) {
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    NSMutableArray *all = [NSMutableArray array];
    CollectScrolls(RootFor(header), 0, header, all);
    if (!gScrolls) gScrolls = [NSHashTable weakObjectsHashTable];
    for (UIScrollView *s in all)
        if ([s isKindOfClass:[UICollectionView class]] && s.bounds.size.width >= W * 0.9 && s.bounds.size.height >= 250) [gScrolls addObject:s];
}

static const void *kOrigAlpha = &kOrigAlpha;
// Header contents fade during the notch animation; remember Apple's alpha.
static void FadeContent(UIView *v, CGFloat a) {
    NSNumber *o = objc_getAssociatedObject(v, kOrigAlpha);
    if (!o) { o = @(v.alpha); objc_setAssociatedObject(v, kOrigAlpha, o, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    v.alpha = o.doubleValue * a;
    v.transform = CGAffineTransformMakeScale(0.94 + 0.06 * a, 0.94 + 0.06 * a);
}
static void RestoreContent(UIView *v) {
    NSNumber *o = objc_getAssociatedObject(v, kOrigAlpha);
    if (!o) return;
    v.alpha = o.doubleValue;
    v.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(v, kOrigAlpha, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void SetOurInset(UIScrollView *s, CGFloat ours);
static void ShowStatusBar(void);
static void ResetAll(void) {
    ShowStatusBar();
    UIView *h = gHeader;
    if (h && !CGAffineTransformIsIdentity(h.transform)) h.transform = CGAffineTransformIdentity;
    [[h viewWithTag:PILL_TAG] removeFromSuperview];
    for (UIView *v in h.subviews) RestoreContent(v);
    for (UIView *v in [gMaskedViews allObjects]) Unmask(v);
    [gMaskedViews removeAllObjects];
    for (UIView *v in [gCardViews allObjects]) [[v viewWithTag:CARD_TAG] removeFromSuperview];
    [gCardViews removeAllObjects];
    for (UIScrollView *s in [gScrolls allObjects]) SetOurInset(s, 0);
    UITextField *f = gField;
    if (f && gOrigPlaceholder && [f.placeholder isEqualToString:@"Search or Ask"]) f.placeholder = gOrigPlaceholder;
    gAppeared = NO;
}

static void MaskTracked(UIView *v) { Mask(v); [gMaskedViews addObject:v]; }

#pragma mark - search pill

// Hide Apple's field capsule and header backdrop (only background-type views).
static void HideHeaderBackgrounds(UIView *v, UITextField *f, int d) {
    if (d > 4) return;
    for (UIView *s in v.subviews) {
        if (s.tag == PILL_TAG || s == f) {
            if (s == f) for (UIView *fs in f.subviews) if (IsBackgroundish(fs)) MaskTracked(fs);
            continue;
        }
        if (IsBackgroundish(s) && ![s isDescendantOfView:f] && ![f isDescendantOfView:s]) { MaskTracked(s); continue; }
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

static CGRect NotchFrameIn(UIView *header) {
    UIWindow *w = header.window;
    BOOL notch = w.safeAreaInsets.top > 40;
    CGFloat nw = notch ? 162 : 110, nh = notch ? 33 : 26;
    CGRect r = notch ? CGRectMake((w.bounds.size.width - nw) / 2, -8, nw, nh + 8) : CGRectMake((w.bounds.size.width - nw) / 2, 6, nw, nh);
    return [header convertRect:r fromView:nil];
}

#pragma mark - liquid notch animation

// Two springs: the height drops fast and stiff, the width follows a beat
// later and wobbles, so the notch looks like it stretches into the bar.
typedef struct { CGFloat v, vel, target; } S26S;
static struct {
    BOOL on, retract;
    S26S top, h, w;
    CGFloat h0, h1;
    CFTimeInterval start;
} G;
static BOOL gCollapsed;

static void StepS(S26S *s, CGFloat k, CGFloat c, CGFloat dt) {
    int n = 4; CGFloat h = dt / n;
    for (int i = 0; i < n; i++) { s->vel += (-k * (s->v - s->target) - c * s->vel) * h; s->v += s->vel * h; }
}
static BOOL SettledS(S26S *s) { return fabs(s->v - s->target) < 0.3 && fabs(s->vel) < 3; }

static NSArray *HeaderContents(UIView *header) {
    NSMutableArray *a = [NSMutableArray array];
    for (UIView *v in header.subviews) if (v.tag != PILL_TAG && !objc_getAssociatedObject(v, kMasked)) [a addObject:v];
    return a;
}

static void ApplyGrow(UIView *header, S26Glass *pill) {
    CGFloat cx = header.bounds.size.width / 2;
    CGFloat w = MAX(20, G.w.v), h = MAX(10, G.h.v);
    pill.transform = CGAffineTransformIdentity;
    pill.frame = CGRectMake(cx - w / 2, G.top.v, w, h);
    [pill setNeedsLayout]; [pill layoutIfNeeded];
    CGFloat p = (G.h1 - G.h0) != 0 ? (h - G.h0) / (G.h1 - G.h0) : 1;
    p = MAX(0, MIN(1, p));
    pill.backgroundColor = [UIColor colorWithWhite:0 alpha:1 - 0.18 * p];
    pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14 * p].CGColor;
    pill.sheen.opacity = p;
    CGFloat ca = MAX(0, MIN(1, (p - 0.5) / 0.4));
    for (UIView *v in HeaderContents(header)) FadeContent(v, ca);
}

static void Shimmer(S26Glass *pill) {
    // A bright edge light runs around the rim once.
    CGRect b = pill.bounds;
    CAShapeLayer *ring = [CAShapeLayer layer];
    ring.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.75, 0.75) cornerRadius:MIN(PILL_RADIUS, b.size.height / 2)].CGPath;
    ring.lineWidth = 1.6; ring.fillColor = UIColor.clearColor.CGColor; ring.strokeColor = UIColor.whiteColor.CGColor;
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = b;
    g.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor, (id)[UIColor colorWithRed:0.75 green:0.85 blue:1 alpha:0.9].CGColor,
                 (id)[UIColor colorWithRed:1 green:0.8 blue:0.95 alpha:0.9].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    g.startPoint = CGPointMake(0, 0.5); g.endPoint = CGPointMake(1, 0.5);
    g.locations = @[@-0.4, @-0.25, @-0.1, @0];
    g.mask = ring;
    [pill.layer addSublayer:g];
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"locations"];
    a.fromValue = @[@-0.4, @-0.25, @-0.1, @0];
    a.toValue = @[@1.0, @1.15, @1.3, @1.4];
    a.duration = 0.9; a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    a.removedOnCompletion = NO; a.fillMode = kCAFillModeForwards;
    [g addAnimation:a forKey:@"run"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.95 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [g removeFromSuperlayer]; });
}

static void StartGrow(UIView *header, UITextField *f, BOOL fromNotch) {
    CGRect n = NotchFrameIn(header), fin = PillFrameIn(header, f);
    if (fromNotch) {
        G.top.v = n.origin.y; G.h.v = n.size.height; G.w.v = n.size.width;
        G.top.vel = G.h.vel = G.w.vel = 0;
    }
    G.h0 = n.size.height; G.h1 = fin.size.height;
    G.top.target = fin.origin.y; G.h.target = fin.size.height; G.w.target = fin.size.width;
    G.h.vel += 300;            // a little kick downward
    G.on = YES; G.retract = NO; gCollapsed = NO;
    G.start = CACurrentMediaTime();
}

static void StartRetract(UIView *header) {
    S26Glass *pill = (S26Glass *)[header viewWithTag:PILL_TAG];
    if (!pill) return;
    CGRect n = NotchFrameIn(header), cur = pill.frame;
    if (!G.on) { G.top.v = cur.origin.y; G.h.v = cur.size.height; G.w.v = cur.size.width; G.top.vel = G.h.vel = G.w.vel = 0; }
    G.h0 = n.size.height; G.h1 = PillFrameIn(header, gField).size.height;
    G.top.target = n.origin.y; G.h.target = n.size.height; G.w.target = n.size.width;
    G.on = YES; G.retract = YES;
    G.start = CACurrentMediaTime();
}

static void StepGrow(UIView *header, CGFloat dt) {
    S26Glass *pill = (S26Glass *)[header viewWithTag:PILL_TAG];
    if (!G.on || !pill) return;
    CFTimeInterval age = CACurrentMediaTime() - G.start;
    if (G.retract) {
        StepS(&G.top, 520, 46, dt); StepS(&G.h, 520, 46, dt);
        StepS(&G.w, 380, 38, dt);
    } else {
        StepS(&G.top, 320, 26, dt); StepS(&G.h, 320, 25, dt);
        if (age > 0.05) StepS(&G.w, 190, 13.5, dt);
    }
    ApplyGrow(header, pill);
    if (SettledS(&G.top) && SettledS(&G.h) && SettledS(&G.w)) {
        G.top.v = G.top.target; G.h.v = G.h.target; G.w.v = G.w.target;
        ApplyGrow(header, pill);
        G.on = NO;
        if (G.retract) gCollapsed = YES;
        else {
            for (UIView *v in HeaderContents(header)) RestoreContent(v);
            Shimmer(pill);
        }
    }
}

static void StylePill(UIView *header, UITextField *f) {
    UIWindow *w = header.window;
    // 1. Pin the header so the field sits just under the notch.
    if (gTop) {
        CGPoint origin = [header.superview convertPoint:CGPointMake(0, header.center.y - header.bounds.size.height / 2) toView:nil];
        CGFloat fieldMid = CGRectGetMidY([f convertRect:f.bounds toView:header]);
        CGFloat targetMid = w.safeAreaInsets.top > 40 ? w.safeAreaInsets.top + 20 : w.safeAreaInsets.top + 34;
        CGFloat ty = round(targetMid - (origin.y + fieldMid) + header.transform.ty - header.transform.ty);
        if (fabs(header.transform.ty - ty) > 0.5 || header.transform.a != 1) header.transform = CGAffineTransformMakeTranslation(0, ty);
    } else if (!CGAffineTransformIsIdentity(header.transform)) header.transform = CGAffineTransformIdentity;

    // 2. The black glass shape behind the field (it reaches above the header).
    if (header.clipsToBounds) header.clipsToBounds = NO;
    HideHeaderBackgrounds(header, f, 0);
    if (f.leftView && !objc_getAssociatedObject(f.leftView, kMasked)) MaskTracked(f.leftView);   // no magnifier in iOS 26
    if (!gOrigPlaceholder && f.placeholder.length && ![f.placeholder isEqualToString:@"Search or Ask"]) gOrigPlaceholder = f.placeholder;
    if (![f.placeholder isEqualToString:@"Search or Ask"]) f.placeholder = @"Search or Ask";

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
    }
    if (!gAppeared) {
        gAppeared = YES;
        if (gNotch && gTop) { StartGrow(header, f, YES); ApplyGrow(header, pill); }
        else { SetFrame(pill, pf); for (UIView *v in HeaderContents(header)) RestoreContent(v); }
    } else if (!G.on && !gCollapsed && CGAffineTransformIsIdentity(pill.transform)) {
        SetFrame(pill, pf);
        G.top.target = pf.origin.y; G.h.target = pf.size.height; G.w.target = pf.size.width;
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
    objc_setAssociatedObject(s, kInsetOurs, fabs(ours) > 0.1 ? @(ours) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Where content y=0 sits on screen when scrolled to the top, without our inset.
static CGFloat ContentStartY(UIScrollView *s) {
    CGFloat ours = [objc_getAssociatedObject(s, kInsetOurs) doubleValue];
    return [s.superview convertPoint:s.frame.origin toView:nil].y + s.adjustedContentInset.top - ours;
}

static BOOL IsAppRow(UICollectionViewCell *c) {
    NSString *cn = NSStringFromClass([c class]);
    if ([cn containsString:@"AppIcon"] || [cn containsString:@"IconRow"]) return YES;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:c.contentView ?: c];
    int icons = 0, guard = 0;
    while (stack.count && guard++ < 400) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        NSString *n = NSStringFromClass([v class]);
        CGSize z = v.bounds.size;
        BOOL squareish = z.width >= 44 && z.width <= 90 && fabs(z.width - z.height) < 6;
        if (squareish && ([n containsString:@"Icon"] || [v isKindOfClass:[UIImageView class]])) { icons++; continue; }
        [stack addObjectsFromArray:v.subviews];
    }
    return icons >= 3;
}

static void StyleAppRow(UICollectionViewCell *c) {
    S26Glass *g = (S26Glass *)[c viewWithTag:CARD_TAG];
    if (g.superview != c) g = nil;
    if (!g) {
        g = [S26Glass new];
        g.tag = CARD_TAG;
        g.backgroundColor = [UIColor colorWithWhite:0 alpha:0.78];
        [gCardViews addObject:c];
    }
    if (c.contentView && g.superview != c) [c insertSubview:g belowSubview:c.contentView];
    else if (!g.superview) [c insertSubview:g atIndex:0];
    g.radius = 36;
    SetFrame(g, CGRectInset(c.bounds, 0, -12));
    if (c.backgroundView) MaskTracked(c.backgroundView);
    for (UIView *x in c.subviews) if (x != g && x != c.contentView && IsBackgroundish(x)) MaskTracked(x);
    for (UIView *x in c.contentView.subviews) if (IsBackgroundish(x) && x.bounds.size.width > c.bounds.size.width * 0.6) MaskTracked(x);
}

static void UnstyleCell(UICollectionViewCell *c) {
    [[c viewWithTag:CARD_TAG] removeFromSuperview];
    if (c.backgroundView) Unmask(c.backgroundView);
    for (UIView *x in c.subviews) Unmask(x);
    for (UIView *x in c.contentView.subviews) Unmask(x);
}

// iOS 26 resting look: with nothing typed, show only the app icons on black glass.
static void StyleCollection(UICollectionView *cv, UIView *header, BOOL empty, NSMutableArray *dbg) {
    BOOL rest = empty && gRest && gEnabled;
    UICollectionViewCell *firstApp = nil;
    int apps = 0, hidden = 0, supps = 0;
    NSMutableSet *classes = [NSMutableSet set];
    for (UICollectionViewCell *c in cv.visibleCells) {
        BOOL app = IsAppRow(c);
        if (classes.count < 4) [classes addObject:[NSString stringWithFormat:@"%@%@", NSStringFromClass([c class]), app ? @"*" : @""]];
        if (rest && app) {
            Unmask(c);
            StyleAppRow(c);
            apps++;
            if (!firstApp || c.frame.origin.y < firstApp.frame.origin.y) firstApp = c;
        } else if (rest) {
            UnstyleCell(c);
            MaskTracked(c); hidden++;
        } else {
            Unmask(c);
            UnstyleCell(c);
        }
    }
    for (UIView *v in cv.subviews) {
        if (![v isKindOfClass:[UICollectionReusableView class]] || [v isKindOfClass:[UICollectionViewCell class]]) continue;
        supps++;
        if (rest) MaskTracked(v); else Unmask(v);
    }
    // Push results below the glass; at rest, put the app card right under it.
    CGFloat ours = 0;
    if (gTop && gEnabled) {
        CGRect pw = [header convertRect:PillFrameIn(header, gField) toView:nil];
        CGFloat start = ContentStartY(cv);
        CGFloat anchor = start;
        if (rest && firstApp) anchor = start + firstApp.frame.origin.y - 12;   // card top (glass reaches 12pt above)
        ours = ceil(CGRectGetMaxY(pw) + 14 - anchor);
        ours = MAX(-300, MIN(300, ours));
    }
    SetOurInset(cv, ours);
    if (dbg) [dbg addObject:[NSString stringWithFormat:@"%@ vis=%d cells=%lu apps=%d hid=%d supp=%d ours=%.0f [%@]", NSStringFromClass([cv class]), ReallyVisible(cv),
                             (unsigned long)cv.visibleCells.count, apps, hidden, supps, ours, [[classes allObjects] componentsJoinedByString:@","]]];
}

// The gray strip Spotlight keeps behind the top of the screen.
static void HideTopBand(UIView *v, UIView *header, int d, NSMutableArray *dbg) {
    if (d > 6) return;
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    for (UIView *s in v.subviews) {
        if (s == header || [s isKindOfClass:[UIScrollView class]] || s.tag == DEBUG_TAG) continue;
        if ([header isDescendantOfView:s]) { HideTopBand(s, header, d + 1, dbg); continue; }
        CGRect f = [s convertRect:s.bounds toView:nil];
        if (IsBackgroundish(s) && f.origin.y <= 4 && f.size.height >= 40 && f.size.height <= 330 && f.size.width >= W * 0.9) {
            MaskTracked(s);
            if (dbg.count < 3) [dbg addObject:[NSString stringWithFormat:@"%@ %.0f", NSStringFromClass([s class]), f.size.height]];
            continue;
        }
        HideTopBand(s, header, d + 1, dbg);
    }
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
    UITextField *f = gField; UIView *h = gHeader;
    NSString *text = [NSString stringWithFormat:@" Spotlight26 0.2.0 debug (%@) prefs=%@\n field: %@ %@ text=%lu\n header: %@ ty=%.0f grow=%d retract=%d collapsed=%d\n sb: hidden=%d root=%@\n band: %@\n results: %@",
                      [[NSBundle mainBundle] bundleIdentifier], gPrefsSource, NSStringFromClass([f class]), NSStringFromCGRect([f convertRect:f.bounds toView:nil]),
                      (unsigned long)f.text.length, NSStringFromClass([h class]), h.transform.ty, G.on, G.retract, gCollapsed,
                      gSBHidden, NSStringFromClass([w.rootViewController class]), gBandDebug, gCardsDebug];
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
        return;
    }
    if (!ReallyVisible(f)) {
        if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(4, 4, 4);
        gAppeared = NO;
        UpdateDebug(nil);
        return;
    }
    if (@available(iOS 15.0, *)) if (gLink.preferredFrameRateRange.preferred < 60) gLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    // Spotlight's app is frozen while closed, so a gap between frames means it
    // was just opened again: grow out of the notch again.
    static CFTimeInterval lastStamp;
    CGFloat dt = lastStamp > 0 ? link.timestamp - lastStamp : 1.0 / 60;
    if (dt > 0.35) gAppeared = NO;
    if (dt > 0.05 || dt <= 0) dt = 1.0 / 60;
    lastStamp = link.timestamp;
    gFrame++;
    @try {
        UIView *h = gHeader;
        if (!h || ![f isDescendantOfView:h]) { h = FindHeader(f); gHeader = h; }
        if (!gEnabled) { ResetAll(); UpdateDebug(f.window); return; }
        StylePill(h, f);
        StepGrow(h, dt);
        if (gHideSB && gInSpotlightApp) HideStatusBar(f.window); else ShowStatusBar();
        if (!gScrolls.count || gFrame % 30 == 1) FindResults(h);
        BOOL empty = f.text.length == 0;
        NSMutableArray *dbg = gDebug ? [NSMutableArray array] : nil;
        for (UICollectionView *cv in [gScrolls allObjects]) {
            if (!cv.window) continue;
            if (!ReallyVisible(cv)) { SetOurInset(cv, 0); continue; }
            StyleCollection(cv, h, empty, dbg);
        }
        if (gFrame % 20 == 1) {
            NSMutableArray *bd = [NSMutableArray array];
            HideTopBand(RootFor(h), h, 0, bd);
            if (bd.count) gBandDebug = [bd componentsJoinedByString:@", "];
        }
        if (dbg) gCardsDebug = [dbg componentsJoinedByString:@"\n  "];
        if (gFrame % 6 == 0) UpdateDebug(f.window);
    } @catch (__unused id e) {}
}
- (void)textChanged:(NSNotification *)n {
    if (n.object != gField || !gEnabled || !gBounce) return;
    UIView *pill = [gHeader viewWithTag:PILL_TAG];
    if (!pill || G.on) return;
    // A quick squish and spring back each keystroke.
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{
        pill.transform = CGAffineTransformMakeScale(1.02, 0.95);
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
        if (gField != self) { gAppeared = NO; gHeader = nil; }
        gField = self;
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
        if (f) { gField = f; gAppeared = NO; gHeader = nil; StartLink(); }
    } else if (!gLink) StartLink();
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
    gMaskedViews = [NSHashTable weakObjectsHashTable];
    gCardViews = [NSHashTable weakObjectsHashTable];
    gScrolls = [NSHashTable weakObjectsHashTable];
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    [[NSNotificationCenter defaultCenter] addObserver:[S26Ticker shared] selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue *q = [NSOperationQueue mainQueue];
    // Leaving Spotlight: the bar pulls back up into the notch.
    for (NSString *name in @[UIApplicationWillResignActiveNotification, UISceneWillDeactivateNotification])
        [nc addObserverForName:name object:nil queue:q usingBlock:^(NSNotification *n) {
            @try { if (gEnabled && gNotch && gTop && gHeader) StartRetract(gHeader); } @catch (__unused id e) {}
        }];
    // Fully closed: sit collapsed in the notch so the next opening starts there.
    for (NSString *name in @[UIApplicationDidEnterBackgroundNotification, UISceneDidEnterBackgroundNotification])
        [nc addObserverForName:name object:nil queue:q usingBlock:^(NSNotification *n) {
            @try {
                UIView *h = gHeader; S26Glass *pill = (S26Glass *)[h viewWithTag:PILL_TAG];
                if (pill && gEnabled && gNotch && gTop) {
                    CGRect r = NotchFrameIn(h);
                    G.top.v = G.top.target = r.origin.y; G.h.v = G.h.target = r.size.height; G.w.v = G.w.target = r.size.width;
                    G.top.vel = G.h.vel = G.w.vel = 0; G.on = NO; gCollapsed = YES;
                    ApplyGrow(h, pill);
                }
                gAppeared = NO;
            } @catch (__unused id e) {}
        }];
    for (NSString *name in @[UIApplicationWillEnterForegroundNotification, UISceneWillEnterForegroundNotification, UIApplicationDidBecomeActiveNotification])
        [nc addObserverForName:name object:nil queue:q usingBlock:^(NSNotification *n) {
            if (gCollapsed || !G.on) { if (![n.name isEqualToString:UIApplicationDidBecomeActiveNotification] || gCollapsed) gAppeared = NO; }
            if (gField.window) StartLink();
        }];
    %init;
    if (gInSpringBoard || gInSpotlightApp) dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:gInSpringBoard ? 1.5 : 0.7 repeats:YES block:^(NSTimer *tm) { @try { Scan(); } @catch (__unused id e) {} }];
    });
}
