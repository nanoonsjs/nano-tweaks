// InstaGlass 0.1.0 - made by nano
// 0.1.0: Instagram's floating tab bar becomes a liquid glass pill (light / dark),
//        the selected-tab bubble becomes clear glass that stretches like liquid
//        when it slides to another tab. Debug: hold three fingers on the screen.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define GLASS_TAG 0x49474C41
#define DEBUG_TAG 0x49474442

static NSString *gDebug = @"-";
static BOOL gShowDebug = NO;
static __weak UIView *gBar, *gBubble;

static BOOL IsDark(UIView *v) { return v.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark; }

// Instagram's floating bar: a wide, short capsule near the bottom holding 4-6 tab
// buttons (icons). The smallest view that fits.
static UIView *FindBar(UIWindow *w) {
    CGFloat W = w.bounds.size.width, H = w.bounds.size.height;
    UIView *best = nil; CGFloat bestArea = CGFLOAT_MAX;
    NSMutableArray *st = [NSMutableArray arrayWithObject:w];
    int g = 0;
    while (st.count && g++ < 6000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.hidden || v.alpha < 0.05 || v.tag == DEBUG_TAG || v.tag == GLASS_TAG) continue;
        if ([v isKindOfClass:[UIScrollView class]] && v.bounds.size.height > H * 0.5) { [st addObjectsFromArray:v.subviews]; continue; }
        CGRect f = [v convertRect:v.bounds toView:nil];
        BOOL shape = f.size.width > W * 0.55 && f.size.width < W * 0.99 && f.size.height >= 44 && f.size.height <= 90 && CGRectGetMidY(f) > H * 0.82;
        if (shape) {
            // count the icon-ish things inside, spread across the width
            int icons = 0;
            NSMutableArray *s2 = [NSMutableArray arrayWithArray:v.subviews];
            int g2 = 0;
            NSMutableSet *cols = [NSMutableSet set];
            while (s2.count && g2++ < 200) {
                UIView *x = s2.lastObject; [s2 removeLastObject];
                if (x.hidden) continue;
                CGSize s = x.bounds.size;
                BOOL iconish = ([x isKindOfClass:[UIImageView class]] || [x isKindOfClass:[UIControl class]]) && s.width >= 18 && s.width <= 80 && s.height >= 18 && s.height <= 80;
                if (iconish) {
                    CGFloat cx = [x convertPoint:CGPointMake(s.width / 2, s.height / 2) toView:v].x;
                    NSNumber *col = @((int)(cx / (f.size.width / 10)));
                    if (![cols containsObject:col]) { [cols addObject:col]; icons++; }
                }
                [s2 addObjectsFromArray:x.subviews];
            }
            CGFloat area = f.size.width * f.size.height;
            if (icons >= 4 && icons <= 7 && area < bestArea) { best = v; bestArea = area; }
        }
        [st addObjectsFromArray:v.subviews];
    }
    return best;
}

// Clear Instagram's own fill / blur behind the bar (views the size of the bar).
static void ClearBackground(UIView *bar) {
    CGSize B = bar.bounds.size;
    NSMutableArray *st = [NSMutableArray arrayWithObject:bar];
    int g = 0;
    while (st.count && g++ < 120) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG) continue;
        CGSize s = v.bounds.size;
        BOOL full = s.width >= B.width * 0.95 && s.height >= B.height * 0.85;
        if (full) {
            if (v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0) v.backgroundColor = UIColor.clearColor;
            if ([v isKindOfClass:[UIVisualEffectView class]] && v != bar) v.alpha = 0;
            if (v.layer.borderWidth > 0) v.layer.borderWidth = 0;
            if (v.layer.shadowOpacity > 0 && v != bar) v.layer.shadowOpacity = 0;
            for (CALayer *l in v.layer.sublayers) {
                if ([l isKindOfClass:[CAShapeLayer class]] && l.bounds.size.width >= B.width * 0.9) { ((CAShapeLayer *)l).fillColor = UIColor.clearColor.CGColor; ((CAShapeLayer *)l).strokeColor = UIColor.clearColor.CGColor; }
                else if (l.backgroundColor && l.bounds.size.width >= B.width * 0.9 && CGColorGetAlpha(l.backgroundColor) > 0 && ![l.name hasPrefix:@"ig."]) l.backgroundColor = UIColor.clearColor.CGColor;
            }
        }
        if (full || v == bar) [st addObjectsFromArray:v.subviews];
    }
}

// Our glass, under everything in the bar.
static void Glass(UIView *bar) {
    UIVisualEffectView *g = (UIVisualEffectView *)[bar viewWithTag:GLASS_TAG];
    BOOL dark = IsDark(bar);
    if (!g) {
        g = [[UIVisualEffectView alloc] initWithEffect:nil];
        g.tag = GLASS_TAG; g.userInteractionEnabled = NO; g.clipsToBounds = YES;
        g.layer.cornerCurve = kCACornerCurveContinuous;
        UIView *tint = [UIView new]; tint.tag = 1; tint.userInteractionEnabled = NO;
        tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [g.contentView addSubview:tint];
        CAGradientLayer *shine = [CAGradientLayer layer]; shine.name = @"ig.shine";
        shine.startPoint = CGPointMake(0.5, 0); shine.endPoint = CGPointMake(0.5, 1);
        [g.contentView.layer addSublayer:shine];
        [bar insertSubview:g atIndex:0];
        objc_setAssociatedObject(g, "dark", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (bar.subviews.firstObject != g) [bar sendSubviewToBack:g];
    CGRect want = bar.bounds;
    CGFloat r = MIN(want.size.height, want.size.width) / 2;
    if (!CGRectEqualToRect(g.frame, want)) { g.frame = want; g.layer.cornerRadius = r; }
    NSNumber *was = objc_getAssociatedObject(g, "dark");
    if (!was || was.boolValue != dark) {
        objc_setAssociatedObject(g, "dark", @(dark), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        g.effect = [UIBlurEffect effectWithStyle:dark ? UIBlurEffectStyleSystemUltraThinMaterialDark : UIBlurEffectStyleSystemUltraThinMaterialLight];
        [g.contentView viewWithTag:1].backgroundColor = dark ? [UIColor colorWithWhite:0.08 alpha:0.28] : [UIColor colorWithWhite:1 alpha:0.45];
        g.layer.borderWidth = 0.8;
        g.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.18] : [UIColor colorWithWhite:0 alpha:0.08]).CGColor;
        bar.layer.shadowColor = UIColor.blackColor.CGColor;
        bar.layer.shadowOpacity = dark ? 0.35 : 0.14; bar.layer.shadowRadius = 18; bar.layer.shadowOffset = CGSizeMake(0, 6);
        for (CALayer *l in g.contentView.layer.sublayers) if ([l.name isEqualToString:@"ig.shine"])
            ((CAGradientLayer *)l).colors = @[(id)[UIColor colorWithWhite:1 alpha:dark ? 0.10 : 0.35].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    }
    for (CALayer *l in g.contentView.layer.sublayers) if ([l.name isEqualToString:@"ig.shine"] && !CGRectEqualToRect(l.frame, CGRectMake(0, 0, want.size.width, want.size.height * 0.5))) {
        [CATransaction begin]; [CATransaction setDisableActions:YES]; l.frame = CGRectMake(0, 0, want.size.width, want.size.height * 0.5); [CATransaction commit];
    }
    if (bar.clipsToBounds) bar.clipsToBounds = NO;
    if (bar.layer.cornerRadius != r) { bar.layer.cornerRadius = r; bar.layer.cornerCurve = kCACornerCurveContinuous; }
    bar.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:bar.bounds cornerRadius:r].CGPath;
}

// The selected-tab bubble: a filled capsule inside the bar, about one tab wide.
static UIView *FindBubble(UIView *bar) {
    CGSize B = bar.bounds.size;
    UIView *best = nil;
    NSMutableArray *st = [NSMutableArray arrayWithArray:bar.subviews];
    int g = 0;
    while (st.count && g++ < 200) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG || v.hidden) continue;
        CGSize s = v.bounds.size;
        BOOL sized = s.width > B.width * 0.12 && s.width < B.width * 0.4 && s.height > B.height * 0.6 && s.height <= B.height;
        BOOL filled = (v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0.02) || [v isKindOfClass:[UIVisualEffectView class]] || objc_getAssociatedObject(v, "igBubble");
        if (sized && filled && ![v isKindOfClass:[UIControl class]]) { best = v; break; }
        [st addObjectsFromArray:v.subviews];
    }
    return best;
}
static void StyleBubble(UIView *b) {
    BOOL dark = IsDark(b);
    objc_setAssociatedObject(b, "igBubble", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIColor *fill = dark ? [UIColor colorWithWhite:1 alpha:0.16] : [UIColor colorWithWhite:0 alpha:0.07];
    if (![b.backgroundColor isEqual:fill] && ![b isKindOfClass:[UIVisualEffectView class]]) b.backgroundColor = fill;
    if ([b isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *e = (UIVisualEffectView *)b;
        if (e.effect) e.effect = nil;
        e.contentView.backgroundColor = fill;
    }
    CGFloat r = MIN(b.bounds.size.width, b.bounds.size.height) / 2;
    if (b.layer.cornerRadius != r) { b.layer.cornerRadius = r; b.layer.cornerCurve = kCACornerCurveContinuous; }
    b.layer.borderWidth = 0.75;
    b.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.22] : [UIColor colorWithWhite:1 alpha:0.7]).CGColor;
}

// Liquid stretch: while the bubble moves, it stretches along the way it goes and
// springs back round when it stops.
@interface IGLiquid : NSObject
+ (instancetype)shared;
- (void)tick:(CADisplayLink *)l;
@end
@implementation IGLiquid {
    CGFloat _lastX; CFTimeInterval _lastT; CGFloat _stretch; BOOL _moving;
}
+ (instancetype)shared { static IGLiquid *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [IGLiquid new]; }); return t; }
- (void)tick:(CADisplayLink *)l {
    UIView *b = gBubble;
    if (!b.window) return;
    CALayer *p = b.layer.presentationLayer ?: b.layer;
    CGFloat x = [b.superview.layer convertPoint:p.position toLayer:b.window.layer].x;
    CFTimeInterval t = CACurrentMediaTime();
    CGFloat dt = MAX(t - _lastT, 1.0 / 120);
    CGFloat v = (_lastT > 0) ? (x - _lastX) / dt : 0;
    _lastX = x; _lastT = t;
    CGFloat target = MIN(fabs(v) / 1800.0, 0.32);
    _stretch += (target - _stretch) * 0.35;
    if (_stretch < 0.003) _stretch = 0;
    CALayer *bl = b.layer;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (_stretch > 0) {
        _moving = YES;
        bl.sublayerTransform = CATransform3DIdentity;
        CGFloat sx = 1 + _stretch, sy = 1 - _stretch * 0.35;
        objc_setAssociatedObject(b, "igStretch", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        b.layer.transform = CATransform3DMakeScale(sx, sy, 1);
    } else if (_moving) {
        _moving = NO;
        b.layer.transform = CATransform3DIdentity;
        // settle with a small wobble
        CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
        k.values = @[@0.94, @1.04, @0.99, @1]; k.duration = 0.35;
        [b.layer addAnimation:k forKey:@"ig.settle"];
    }
    [CATransaction commit];
}
@end

static void DebugBox(UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gShowDebug) { [l removeFromSuperview]; return; }
    if (!l) {
        l = [UILabel new]; l.tag = DEBUG_TAG; l.numberOfLines = 0; l.userInteractionEnabled = NO;
        l.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor; l.backgroundColor = [UIColor colorWithRed:0.3 green:0 blue:0.35 alpha:0.85];
        l.layer.cornerRadius = 10; l.clipsToBounds = YES;
        [w addSubview:l];
    }
    l.text = [NSString stringWithFormat:@" InstaGlass 0.1.0 debug\n %@", gDebug];
    CGSize s = [l sizeThatFits:CGSizeMake(w.bounds.size.width - 24, 600)];
    l.frame = CGRectMake(12, w.safeAreaInsets.top + 60, w.bounds.size.width - 24, s.height + 12);
    [w bringSubviewToFront:l];
}

@interface IGDebugToggle : NSObject
+ (instancetype)shared;
@end
@implementation IGDebugToggle
+ (instancetype)shared { static IGDebugToggle *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [IGDebugToggle new]; }); return t; }
- (void)hold:(UILongPressGestureRecognizer *)g { if (g.state == UIGestureRecognizerStateBegan) gShowDebug = !gShowDebug; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
@end

static void Tick(void) {
    UIWindow *w = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *x in ((UIWindowScene *)sc).windows) if (x.isKeyWindow) w = x;
    }
    if (!w) return;
    static const char kInstalled = 0;
    if (!objc_getAssociatedObject(w, &kInstalled)) {
        objc_setAssociatedObject(w, &kInstalled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[IGDebugToggle shared] action:@selector(hold:)];
        lp.numberOfTouchesRequired = 3; lp.minimumPressDuration = 0.8; lp.cancelsTouchesInView = NO;
        lp.delegate = (id<UIGestureRecognizerDelegate>)[IGDebugToggle shared];
        [w addGestureRecognizer:lp];
    }
    UIView *bar = gBar;
    static CFTimeInterval lastFind;
    if (!bar.window || CACurrentMediaTime() - lastFind > 2.0) {
        lastFind = CACurrentMediaTime();
        UIView *found = FindBar(w);
        if (found && found != bar) { [[bar viewWithTag:GLASS_TAG] removeFromSuperview]; bar = found; gBar = found; }
        if (!found && !bar.window) bar = nil;
    }
    if (bar) {
        ClearBackground(bar);
        Glass(bar);
        UIView *b = FindBubble(bar);
        if (b) { StyleBubble(b); gBubble = b; }
        CGRect f = [bar convertRect:bar.bounds toView:nil];
        gDebug = [NSString stringWithFormat:@"bar=%@ %.0fx%.0f @%.0f\n parent=%@\n bubble=%@ %.0fx%.0f\n dark=%d",
                  NSStringFromClass([bar class]), f.size.width, f.size.height, f.origin.y, NSStringFromClass([bar.superview class]),
                  b ? NSStringFromClass([b class]) : @"none", b.bounds.size.width, b.bounds.size.height, IsDark(bar)];
    } else gDebug = @"no bar found";
    DebugBox(w);
}

%ctor {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.burbn.instagram"]) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(__unused NSTimer *t) { @try { Tick(); } @catch (__unused id e) {} }];
        CADisplayLink *dl = [CADisplayLink displayLinkWithTarget:[IGLiquid shared] selector:@selector(tick:)];
        [dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    });
}
