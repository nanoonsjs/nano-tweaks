// NanoGlass.h - the same liquid glass in every nano tweak.
//
// With LiquidAss installed, our glass becomes LiquidAss's own tab bar glass (its LGLiveBackdropView with the
// "dylv.liquidglass.tabbar" filter). It's rendered by the system itself, so it bends the light at the edges,
// shines, and stays smooth while scrolling. t (0..1) frosts it: 0 = clear like the tab bar, 1 = blurred and a
// little tinted. Without LiquidAss nothing changes: each tweak keeps its own glass.
//
// Use: NGApply(glassView, t) wherever the glass gets its frame / corner radius (it's cheap to call often).
// glassView can be a UIVisualEffectView (its effect and fill step aside) or a plain view / button (its fill steps
// aside). A view with accessibilityIdentifier "ng.skip" is left alone.
#pragma once
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

static Class NGClass(void) {
    static Class c; static BOOL looked;
    if (!looked) {
        looked = YES;
        Class k = NSClassFromString(@"LGLiveBackdropView");
        if (k && [k instancesRespondToSelector:NSSelectorFromString(@"initWithFrame:groupName:filterType:")]) c = k;
    }
    return c;
}
static BOOL NGOn(void) { return NGClass() != nil; }
static BOOL NGIsGlass(UIView *v) { return [v.accessibilityIdentifier isEqualToString:@"nano.glass"]; }

static UIView *NGMake(CGRect f) {
    Class c = NGClass(); if (!c) return nil;
    UIView *v = nil;
    @try { v = ((id (*)(id, SEL, CGRect, id, id))objc_msgSend)([c alloc], NSSelectorFromString(@"initWithFrame:groupName:filterType:"), f, nil, @"dylv.liquidglass.tabbar"); }
    @catch (__unused id e) { v = nil; }
    if (!v) return nil;
    v.userInteractionEnabled = NO;
    v.accessibilityIdentifier = @"nano.glass";   // LGCompat leaves our own copy alone
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.layer.masksToBounds = YES;
    if (@available(iOS 13.0, *)) v.layer.cornerCurve = kCACornerCurveContinuous;
    return v;
}
static void NGFit(UIView *v, CGRect f, CGFloat radius) {
    if (!v) return;
    BOOL rc = fabs(v.layer.cornerRadius - radius) > 0.25;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (!CGRectEqualToRect(v.frame, f)) v.frame = f;
    if (rc) v.layer.cornerRadius = radius;
    [CATransaction commit];
    @try {
        if ([v respondsToSelector:NSSelectorFromString(@"applyFilters")]) ((void (*)(id, SEL))objc_msgSend)(v, NSSelectorFromString(@"applyFilters"));
        if (rc && [v respondsToSelector:NSSelectorFromString(@"updateSpecular")]) ((void (*)(id, SEL))objc_msgSend)(v, NSSelectorFromString(@"updateSpecular"));
    } @catch (__unused id e) {}
}
// frost: a blur (a backdrop layer, no class needed) and a tint, inside the glass, under its rim and shine
static void NGStyle(UIView *lgv, CGFloat t, BOOL light) {
    if (!lgv) return;
    t = MAX(0, MIN(1, t));
    CGRect b = lgv.bounds; CGFloat r = lgv.layer.cornerRadius;
    CALayer *bl = nil, *tn = nil;
    for (CALayer *l in lgv.layer.sublayers) { if ([l.name isEqualToString:@"ng.blur"]) bl = l; else if ([l.name isEqualToString:@"ng.tint"]) tn = l; }
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    CGFloat br = round(18 * t * 2) / 2;
    Class BD = NSClassFromString(@"CABackdropLayer");
    if (br >= 0.5 && BD) {
        if (!bl) {
            bl = [BD layer]; bl.name = @"ng.blur";
            @try {
                [bl setValue:@NO forKey:@"layerUsesCoreImageFilters"];
                [bl setValue:@YES forKey:@"windowServerAware"];
                [bl setValue:[NSUUID UUID].UUIDString forKey:@"groupName"];
                [bl setValue:@0.5 forKey:@"scale"];
            } @catch (__unused id e) {}
            [lgv.layer insertSublayer:bl atIndex:0];
        }
        NSNumber *was = [bl valueForKey:@"ng.br"];
        if (!was || fabs(was.doubleValue - br) > 0.01) {
            @try {
                id f = ((id (*)(id, SEL, NSString *))objc_msgSend)(NSClassFromString(@"CAFilter"), NSSelectorFromString(@"filterWithType:"), @"gaussianBlur");
                [f setValue:@(br) forKey:@"inputRadius"];
                if (f) bl.filters = @[f];
            } @catch (__unused id e) {}
            [bl setValue:@(br) forKey:@"ng.br"];
        }
        bl.frame = b; bl.cornerRadius = r; bl.masksToBounds = YES;
    } else [bl removeFromSuperlayer];
    CGFloat ta = (light ? 0.42 : 0.32) * t;
    if (ta > 0.01) {
        if (!tn) { tn = [CALayer layer]; tn.name = @"ng.tint"; }
        if (tn.superlayer != lgv.layer) { if (bl.superlayer) [lgv.layer insertSublayer:tn above:bl]; else [lgv.layer insertSublayer:tn atIndex:0]; }
        tn.frame = b; tn.cornerRadius = r;
        tn.backgroundColor = (light ? [UIColor colorWithWhite:1 alpha:ta] : [UIColor colorWithWhite:0.06 alpha:ta]).CGColor;
    } else [tn removeFromSuperlayer];
    [CATransaction commit];
}

static const void *kNGFx = &kNGFx;
// turn a glass view of ours into the liquid glass (call it again whenever its frame or radius changes)
static void NGApply(UIView *g, CGFloat t) {
    if (!g || !NGOn() || [g.accessibilityIdentifier isEqualToString:@"ng.skip"]) return;
    UIView *box = g;
    if ([g isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *e = (UIVisualEffectView *)g;
        if (e.effect) { objc_setAssociatedObject(e, kNGFx, e.effect, OBJC_ASSOCIATION_RETAIN_NONATOMIC); e.effect = nil; }
        box = e.contentView;
        if (box.backgroundColor && ![box.backgroundColor isEqual:UIColor.clearColor]) box.backgroundColor = UIColor.clearColor;
        // our own flat tints / sheens inside it step aside (real content like labels stays)
        for (UIView *s in box.subviews) if (!NGIsGlass(s) && [s class] == [UIView class] && !s.subviews.count && s.backgroundColor && !s.hidden) s.hidden = YES;
        for (CALayer *l in box.layer.sublayers) if (([l.name hasSuffix:@"sheen"] || [l.name hasSuffix:@"shine"]) && !l.hidden) l.hidden = YES;
    } else if (g.backgroundColor && ![g.backgroundColor isEqual:UIColor.clearColor]) g.backgroundColor = UIColor.clearColor;
    UIView *lgv = nil;
    for (UIView *v in box.subviews) if (NGIsGlass(v)) { lgv = v; break; }
    if (!lgv) { lgv = NGMake(box.bounds); if (!lgv) return; [box insertSubview:lgv atIndex:0]; }
    else if (box.subviews.firstObject != lgv) [box sendSubviewToBack:lgv];
    // LiquidAss draws the rim and the shine: ours step aside
    if (g.layer.borderWidth != 0) g.layer.borderWidth = 0;
    for (CALayer *l in g.layer.sublayers) if ([l.name hasSuffix:@".rim"] && l.opacity != 0) l.opacity = 0;
    if (!g.clipsToBounds && ![g isKindOfClass:[UIButton class]]) g.clipsToBounds = YES;
    CGFloat r = g.layer.cornerRadius > 0 ? g.layer.cornerRadius : MIN(g.bounds.size.width, g.bounds.size.height) / 2;
    NGFit(lgv, box.bounds, r);
    NGStyle(lgv, t, g.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark);
}
