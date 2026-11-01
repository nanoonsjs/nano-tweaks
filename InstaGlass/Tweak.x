// InstaGlass 0.3.1 - made by nano
// 0.3.1: finds Instagram's tab bar (IGTabBar) again
// 0.3.0: no more glass on the like / comment row of posts (the tab bar is never
//        inside a list); the bubble follows the tab you're on, also when you swipe
//        between pages; hold the bubble, drag it to a tab and let go to open it
// 0.2.0: also the normal full-width tab bar (profile etc.): it becomes a floating
//        glass pill with a glass bubble under the tab you tap
// 0.1.0: Instagram's floating tab bar becomes a liquid glass pill (light / dark),
//        the selected-tab bubble becomes clear glass that stretches like liquid
//        when it slides to another tab. Debug: hold three fingers on the screen.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
        // Not inside a post / list row (the like row under posts looks like a bar).
        if ([v isKindOfClass:[UICollectionViewCell class]] || [v isKindOfClass:[UITableViewCell class]]) continue;
        // Instagram's own tab bar, by name.
        if ([NSStringFromClass([v class]) isEqualToString:@"IGTabBar"]) {
            CGRect tf = [v convertRect:v.bounds toView:nil];
            if (tf.size.width > W * 0.5 && CGRectGetMaxY(tf) > H - 160) return v;
        }
        CGRect f = [v convertRect:v.bounds toView:nil];
        BOOL shape = f.size.width > W * 0.55 && f.size.width <= W + 1 && f.size.height >= 44 && f.size.height <= 130 && CGRectGetMidY(f) > H * 0.8 && CGRectGetMaxY(f) <= H + 2 && CGRectGetMaxY(f) > H - 140;
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

// The tab icons (one per column), in the bar's coordinates, left to right.
static NSArray *IconFrames(UIView *bar) {
    CGSize B = bar.bounds.size;
    NSMutableDictionary *cols = [NSMutableDictionary dictionary];
    NSMutableArray *st = [NSMutableArray arrayWithArray:bar.subviews];
    int g = 0;
    while (st.count && g++ < 300) {
        UIView *x = st.lastObject; [st removeLastObject];
        if (x.hidden || x.tag == GLASS_TAG || x.tag == GLASS_TAG + 1) continue;
        CGSize s = x.bounds.size;
        if ([x isKindOfClass:[UIImageView class]] && s.width >= 18 && s.width <= 60 && s.height >= 18 && s.height <= 60) {
            CGRect f = [x convertRect:x.bounds toView:bar];
            NSNumber *col = @((int)(CGRectGetMidX(f) / (B.width / 10)));
            NSValue *old = cols[col];
            if (!old || f.size.width * f.size.height > old.CGRectValue.size.width * old.CGRectValue.size.height) cols[col] = [NSValue valueWithCGRect:f];
            continue;
        }
        [st addObjectsFromArray:x.subviews];
    }
    NSArray *keys = [cols.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *out = [NSMutableArray array];
    for (NSNumber *k in keys) [out addObject:cols[k]];
    return out;
}
static BOOL IsFullBar(UIView *bar) { return bar.bounds.size.width >= bar.window.bounds.size.width - 2; }
// Clear Instagram's own fill / blur behind the bar (views the size of the bar).
static void ClearBackground(UIView *bar) {
    CGSize B = bar.bounds.size;
    NSMutableArray *st = [NSMutableArray arrayWithObject:bar];
    int g = 0;
    while (st.count && g++ < 120) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG) continue;
        CGSize s = v.bounds.size;
        BOOL full = s.width >= B.width * 0.95 && s.height >= B.height * 0.5;
        if (s.width >= B.width * 0.95 && s.height <= 1.5 && !v.hidden) v.hidden = YES;   // the hairline on top
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
    if (IsFullBar(bar)) {
        NSArray *ic = IconFrames(bar);
        CGFloat midY = 0; for (NSValue *v in ic) midY += CGRectGetMidY(v.CGRectValue);
        midY = ic.count ? midY / ic.count : 30;
        CGFloat h = 62;
        want = CGRectMake(14, round(midY - h / 2), bar.bounds.size.width - 28, h);
    }
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
    if (!IsFullBar(bar) && bar.layer.cornerRadius != r) { bar.layer.cornerRadius = r; bar.layer.cornerCurve = kCACornerCurveContinuous; }
    bar.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:want cornerRadius:r].CGPath;
}

// The selected-tab bubble: a filled capsule inside the bar, about one tab wide.
static UIView *FindBubble(UIView *bar) {
    CGSize B = bar.bounds.size;
    UIView *best = nil;
    NSMutableArray *st = [NSMutableArray arrayWithArray:bar.subviews];
    int g = 0;
    while (st.count && g++ < 200) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG || v.tag == GLASS_TAG + 1 || v.hidden) continue;
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


// Which tab is on.
// Floating bar: where Instagram's own bubble is. Full bar: the outline icon that
// is filled in right now (each icon's ink is measured; the filled look has more).
static NSMapTable *gInk;
static CGFloat InkOf(UIImage *img) {
    if (!img.CGImage) return 0;
    if (!gInk) gInk = [NSMapTable weakToStrongObjectsMapTable];
    NSNumber *c = [gInk objectForKey:img];
    if (c) return c.doubleValue;
    const int N = 24; uint8_t px[N * N]; memset(px, 0, sizeof(px));
    CGContextRef ctx = CGBitmapContextCreate(px, N, N, 8, N, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    if (!ctx) return 0;
    CGContextDrawImage(ctx, CGRectMake(0, 0, N, N), img.CGImage);
    CGContextRelease(ctx);
    double sum = 0; for (int i = 0; i < N * N; i++) sum += px[i];
    CGFloat ink = sum / (N * N * 255.0);
    [gInk setObject:@(ink) forKey:img];
    return ink;
}
static NSArray *IconViews(UIView *bar) {
    CGSize B = bar.bounds.size;
    NSMutableDictionary *cols = [NSMutableDictionary dictionary];
    NSMutableArray *st = [NSMutableArray arrayWithArray:bar.subviews];
    int g = 0;
    while (st.count && g++ < 300) {
        UIView *x = st.lastObject; [st removeLastObject];
        if (x.hidden || x.tag == GLASS_TAG || x.tag == GLASS_TAG + 1) continue;
        CGSize sz = x.bounds.size;
        if ([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image && sz.width >= 18 && sz.width <= 60 && sz.height >= 18 && sz.height <= 60) {
            CGRect f = [x convertRect:x.bounds toView:bar];
            NSNumber *col = @((int)(CGRectGetMidX(f) / (B.width / 10)));
            UIView *old = cols[col];
            if (!old || sz.width * sz.height > old.bounds.size.width * old.bounds.size.height) cols[col] = x;
            continue;
        }
        [st addObjectsFromArray:x.subviews];
    }
    NSArray *keys = [cols.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *out = [NSMutableArray array];
    for (NSNumber *k in keys) [out addObject:cols[k]];
    return out;
}
static NSInteger gSelected = 0;
static NSString *gSelWhy = @"-";
static NSInteger SelectedTab(UIView *bar, UIView *igBubble) {
    NSArray *iv = IconViews(bar);
    if (!iv.count) return gSelected;
    if (igBubble.window) {
        CGFloat bx = CGRectGetMidX([igBubble convertRect:igBubble.bounds toView:bar]), best = CGFLOAT_MAX; NSInteger bi = 0;
        for (NSUInteger i = 0; i < iv.count; i++) { CGFloat d = fabs(CGRectGetMidX([iv[i] convertRect:[iv[i] bounds] toView:bar]) - bx); if (d < best) { best = d; bi = i; } }
        gSelWhy = @"ig bubble";
        return bi;
    }
    if ([bar isKindOfClass:[UITabBar class]]) {
        UITabBar *tb = (UITabBar *)bar; NSUInteger i = tb.selectedItem ? [tb.items indexOfObject:tb.selectedItem] : NSNotFound;
        if (i != NSNotFound) { gSelWhy = @"tabbar"; return i; }
    }
    // per icon: the most and least ink it has had; filled = near its most
    static NSMutableDictionary *range;
    if (!range) range = [NSMutableDictionary dictionary];
    NSInteger pick = -1; CGFloat pickGain = 0;
    NSMutableString *dbg = [NSMutableString string];
    for (NSUInteger i = 0; i < iv.count; i++) {
        UIImageView *v = iv[i];
        BOOL photo = v.image.renderingMode != UIImageRenderingModeAlwaysTemplate && v.layer.cornerRadius >= v.bounds.size.width * 0.3;
        if (photo) { [dbg appendString:@"p "]; continue; }
        CGFloat ink = InkOf(v.image);
        NSArray *r = range[@(i)];
        CGFloat lo = r ? MIN([r[0] doubleValue], ink) : ink, hi = r ? MAX([r[1] doubleValue], ink) : ink;
        range[@(i)] = @[@(lo), @(hi)];
        [dbg appendFormat:@"%.2f ", ink];
        if (hi - lo > 0.04 && ink > lo + (hi - lo) * 0.6 && ink - lo > pickGain) { pick = i; pickGain = ink - lo; }
    }
    gSelWhy = [NSString stringWithFormat:@"ink %@", dbg];
    if (pick >= 0) return pick;
    // no outline icon is filled in: the profile picture (last) is the one on
    BOOL anyKnown = NO; for (NSNumber *k in range) { NSArray *r = range[k]; if ([r[1] doubleValue] - [r[0] doubleValue] > 0.04) anyKnown = YES; }
    return anyKnown ? (NSInteger)iv.count - 1 : gSelected;
}
static BOOL gDragging = NO;
static void PlaceOwnBubble(UIView *bar, BOOL animated) {
    UIView *g = [bar viewWithTag:GLASS_TAG];
    NSArray *ic = IconFrames(bar);
    if (!g || !ic.count || gDragging) return;
    UIView *b = [bar viewWithTag:GLASS_TAG + 1];
    if (!b) {
        b = [UIView new]; b.tag = GLASS_TAG + 1; b.userInteractionEnabled = NO;
        [bar insertSubview:b aboveSubview:g];
    }
    if (b.superview.subviews.count > 1 && [bar.subviews indexOfObject:b] != [bar.subviews indexOfObject:g] + 1) [bar insertSubview:b aboveSubview:g];
    NSInteger i = MAX(0, MIN(gSelected, (NSInteger)ic.count - 1));
    CGRect gf = g.frame, f = [ic[i] CGRectValue];
    CGFloat w = MIN(gf.size.width / ic.count + 6, 92), h = gf.size.height - 10;
    CGRect want = CGRectMake(round(MIN(MAX(CGRectGetMidX(f) - w / 2, CGRectGetMinX(gf) + 5), CGRectGetMaxX(gf) - 5 - w)), CGRectGetMinY(gf) + 5, w, h);
    gBubble = b;
    StyleBubble(b);
    if (CGRectEqualToRect(b.frame, want)) return;
    if (!animated || CGRectIsEmpty(b.frame)) { b.frame = want; return; }
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ b.frame = want; } completion:nil];
}
// Open tab i the way a tap would.
static void OpenTab(UIView *bar, NSInteger i) {
    NSArray *iv = IconViews(bar);
    if (i < 0 || i >= (NSInteger)iv.count) return;
    if ([bar isKindOfClass:[UITabBar class]]) {
        UITabBar *tb = (UITabBar *)bar;
        if (i < (NSInteger)tb.items.count) {
            UITabBarController *tc = [tb.delegate isKindOfClass:[UITabBarController class]] ? (UITabBarController *)tb.delegate : nil;
            if (tc && i < (NSInteger)tc.viewControllers.count) { tc.selectedIndex = i; return; }
        }
    }
    for (UIView *p = iv[i]; p && p != bar.superview; p = p.superview) {
        if ([p isKindOfClass:[UIControl class]]) { [(UIControl *)p sendActionsForControlEvents:UIControlEventTouchUpInside]; return; }
        for (UIGestureRecognizer *gr in p.gestureRecognizers) if ([gr isKindOfClass:[UITapGestureRecognizer class]] && gr != (id)objc_getAssociatedObject(bar, "igTap")) {
            // a tap recognizer's targets: call them
            NSArray *targets = nil; @try { targets = [gr valueForKey:@"_targets"]; } @catch (__unused id e) {}
            for (id t in targets) {
                id target = nil; SEL action = NULL;
                @try { target = [t valueForKey:@"_target"]; } @catch (__unused id e) {}
                Ivar ai = class_getInstanceVariable([t class], "_action");
                if (ai) action = *(SEL *)((__bridge void *)t + ivar_getOffset(ai));
                if (target && action && [target respondsToSelector:action]) { ((void (*)(id, SEL, id))objc_msgSend)(target, action, gr); return; }
            }
        }
        if (p.isAccessibilityElement) { [p accessibilityActivate]; return; }
    }
}
@interface IGTap : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation IGTap
+ (instancetype)shared { static IGTap *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [IGTap new]; }); return t; }
- (void)tap:(UITapGestureRecognizer *)tg {
    UIView *bar = tg.view;
    NSArray *ic = IconFrames(bar);
    if (!ic.count) return;
    CGFloat x = [tg locationInView:bar].x, best = CGFLOAT_MAX; NSInteger bi = 0;
    for (NSUInteger i = 0; i < ic.count; i++) { CGFloat d = fabs(CGRectGetMidX([ic[i] CGRectValue]) - x); if (d < best) { best = d; bi = i; } }
    gSelected = bi;
    objc_setAssociatedObject(bar, "igPinUntil", @(CACurrentMediaTime() + 0.8), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    PlaceOwnBubble(bar, YES);
}
// Hold the bubble, slide it, let go on a tab: it opens.
- (void)hold:(UILongPressGestureRecognizer *)lp {
    UIView *bar = lp.view;
    UIView *b = [bar viewWithTag:GLASS_TAG + 1], *g = [bar viewWithTag:GLASS_TAG];
    NSArray *iv = IconViews(bar);
    if (!b || !g || !iv.count) return;
    CGFloat x = [lp locationInView:bar].x;
    CGRect gf = g.frame;
    if (lp.state == UIGestureRecognizerStateBegan) {
        if (!CGRectContainsPoint(CGRectInset(b.frame, -14, -10), [lp locationInView:bar])) { lp.enabled = NO; lp.enabled = YES; return; }
        gDragging = YES;
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformMakeScale(1.12, 1.12); } completion:nil];
        objc_setAssociatedObject(bar, "igHover", @(-1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!gDragging) return;
    if (lp.state == UIGestureRecognizerStateChanged || lp.state == UIGestureRecognizerStateBegan) {
        CGFloat w = b.bounds.size.width;
        CGFloat cx = MIN(MAX(x, CGRectGetMinX(gf) + 5 + w / 2), CGRectGetMaxX(gf) - 5 - w / 2);
        b.center = CGPointMake(cx, b.center.y);
        // a tick each time it passes over a new tab
        NSInteger near = 0; CGFloat best = CGFLOAT_MAX;
        for (NSUInteger i = 0; i < iv.count; i++) { CGFloat d = fabs(CGRectGetMidX([iv[i] convertRect:[iv[i] bounds] toView:bar]) - cx); if (d < best) { best = d; near = i; } }
        if ([objc_getAssociatedObject(bar, "igHover") integerValue] != near) {
            objc_setAssociatedObject(bar, "igHover", @(near), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [[UISelectionFeedbackGenerator new] selectionChanged];
        }
        return;
    }
    gDragging = NO;
    NSInteger near = [objc_getAssociatedObject(bar, "igHover") integerValue];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
    if (lp.state == UIGestureRecognizerStateEnded && near >= 0) {
        gSelected = near;
        objc_setAssociatedObject(bar, "igPinUntil", @(CACurrentMediaTime() + 0.8), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        PlaceOwnBubble(bar, YES);
        OpenTab(bar, near);
    } else PlaceOwnBubble(bar, YES);
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
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
    l.text = [NSString stringWithFormat:@" InstaGlass 0.3.1 debug\n %@", gDebug];
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
        static const char kTapped = 0;
        if (!objc_getAssociatedObject(bar, &kTapped)) {
            objc_setAssociatedObject(bar, &kTapped, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:[IGTap shared] action:@selector(tap:)];
            tg.cancelsTouchesInView = NO; tg.delaysTouchesEnded = NO; tg.delegate = [IGTap shared];
            [bar addGestureRecognizer:tg];
            objc_setAssociatedObject(bar, "igTap", tg, OBJC_ASSOCIATION_ASSIGN);
            UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[IGTap shared] action:@selector(hold:)];
            lp.minimumPressDuration = 0.25; lp.cancelsTouchesInView = YES; lp.delegate = [IGTap shared];
            [bar addGestureRecognizer:lp];
        }
        // Instagram's own bubble (floating bar) only tells us where it is; ours is shown.
        UIView *ig = IsFullBar(bar) ? nil : FindBubble(bar);
        if (ig && ig.tag != GLASS_TAG + 1 && ig.alpha > 0) ig.alpha = 0.001;
        if (!gDragging && CACurrentMediaTime() > [objc_getAssociatedObject(bar, "igPinUntil") doubleValue]) gSelected = SelectedTab(bar, ig);
        PlaceOwnBubble(bar, YES);
        UIView *b = [bar viewWithTag:GLASS_TAG + 1];
        CGRect f = [bar convertRect:bar.bounds toView:nil];
        gDebug = [NSString stringWithFormat:@"bar=%@ %.0fx%.0f @%.0f full=%d icons=%lu sel=%ld (%@)\n parent=%@\n bubble=%@ %.0fx%.0f\n dark=%d",
                  NSStringFromClass([bar class]), f.size.width, f.size.height, f.origin.y, IsFullBar(bar), (unsigned long)IconFrames(bar).count, (long)gSelected, gSelWhy, NSStringFromClass([bar.superview class]),
                  b ? NSStringFromClass([b class]) : @"none", b.bounds.size.width, b.bounds.size.height, IsDark(bar)];
    } else {
        NSMutableArray *c = [NSMutableArray array];
        NSMutableArray *st = [NSMutableArray arrayWithObject:w];
        int g = 0;
        while (st.count && g++ < 6000 && c.count < 8) {
            UIView *v = st.lastObject; [st removeLastObject];
            if (v.hidden || v.tag == DEBUG_TAG) continue;
            CGRect f = [v convertRect:v.bounds toView:nil];
            if (f.size.width > w.bounds.size.width * 0.5 && f.size.height < 160 && f.size.height > 30 && CGRectGetMinY(f) > w.bounds.size.height * 0.75)
                [c addObject:[NSString stringWithFormat:@"%@ %.0fx%.0f@%.0f", NSStringFromClass([v class]), f.size.width, f.size.height, f.origin.y]];
            [st addObjectsFromArray:v.subviews];
        }
        gDebug = [NSString stringWithFormat:@"no bar found\n %@", [c componentsJoinedByString:@"\n "]];
    }
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
