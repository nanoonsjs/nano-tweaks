// NanoGlass.h - the same liquid glass in every nano tweak.
//
// With LiquidAss installed, our glass becomes LiquidAss's own tab bar glass (its LGLiveBackdropView with the
// "dylv.liquidglass.tabbar" filter). It's rendered by the system itself, so it bends the light at the edges,
// shines, and stays smooth while scrolling. t (0..1) frosts it: 0 = clear like the tab bar, 1 = blurred and a
// little tinted. Without LiquidAss nothing changes: each tweak keeps its own glass.
//
// How clear or frosted it is comes from the NanoGlass settings tweak (com.nano.glass: "frost" 0..1, "enabled"),
// shared by every tweak; changes apply live (Darwin notification com.nano.glass/changed).
//
// Use: NGApply(glassView) wherever the glass gets its frame / corner radius (it's cheap to call often).
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
static CGFloat gNGFrost = 0.5;
static BOOL gNGOff, gNGLoaded;
static NSHashTable *gNGViews;   // every glass of ours (weak), refreshed when the setting changes
static void NGLoad(void) {
    NSDictionary *f = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingString:@"com.nano.glass.plist"]];
        if ([d isKindOfClass:[NSDictionary class]]) { f = d; break; }
    }
    id fr = f[@"frost"], en = f[@"enabled"];
    if (!fr) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("frost"), CFSTR("com.nano.glass")); if (cf) fr = (__bridge_transfer id)cf; }
    if (!en) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.nano.glass")); if (cf) en = (__bridge_transfer id)cf; }
    gNGFrost = [fr respondsToSelector:@selector(doubleValue)] ? MAX(0, MIN(1, [fr doubleValue])) : 0.5;
    gNGOff = en ? ![en boolValue] : NO;
    gNGLoaded = YES;
}
static void NGRefreshAll(void);
static void NGChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{ CFPreferencesAppSynchronize(CFSTR("com.nano.glass")); NGLoad(); NGRefreshAll(); });
}
static void NGEnsure(void) {
    if (gNGLoaded) return;
    NGLoad();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, NGChanged, CFSTR("com.nano.glass/changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
static CGFloat NGFrost(void) { NGEnsure(); return gNGFrost; }
static BOOL NGOn(void) { NGEnsure(); return NGClass() != nil && !gNGOff; }
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
        NSNumber *was = [bl valueForKey:@"ngBr"];
        if (!was || fabs(was.doubleValue - br) > 0.01) {
            @try {
                id f = ((id (*)(id, SEL, NSString *))objc_msgSend)(NSClassFromString(@"CAFilter"), NSSelectorFromString(@"filterWithType:"), @"gaussianBlur");
                [f setValue:@(br) forKey:@"inputRadius"];
                if (f) bl.filters = @[f];
            } @catch (__unused id e) {}
            [bl setValue:@(br) forKey:@"ngBr"];
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

static const void *kNGFx = &kNGFx, *kNGBg = &kNGBg;
static UIView *NGBox(UIView *g) { return [g isKindOfClass:[UIVisualEffectView class]] ? ((UIVisualEffectView *)g).contentView : g; }
// our liquid glass off again: the view's own look comes back
static void NGRemove(UIView *g) {
    UIView *box = NGBox(g);
    UIView *lgv = nil;
    for (UIView *v in box.subviews) if (NGIsGlass(v)) lgv = v;
    if (!lgv) return;
    [lgv removeFromSuperview];
    UIVisualEffect *fx = objc_getAssociatedObject(g, kNGFx);
    if (fx && [g isKindOfClass:[UIVisualEffectView class]] && !((UIVisualEffectView *)g).effect) ((UIVisualEffectView *)g).effect = fx;
    UIColor *bg = objc_getAssociatedObject(g, kNGBg);
    if (bg) box.backgroundColor = bg;
    for (UIView *s in box.subviews) if ([objc_getAssociatedObject(s, kNGBg) boolValue]) { s.hidden = NO; objc_setAssociatedObject(s, kNGBg, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    for (CALayer *l in box.layer.sublayers) if ([[l valueForKey:@"ngHid"] boolValue]) { l.hidden = NO; [l setValue:nil forKey:@"ngHid"]; }
    for (CALayer *l in g.layer.sublayers) if ([l.name hasSuffix:@".rim"]) l.opacity = 1;
}
// LiquidAss already puts its own glass on this one (bar buttons, Settings buttons): ours stays out of the way,
// two glasses on top of each other blurred the icon
static BOOL NGTheirs(UIView *g) {
#ifdef NANO_LGCOMPAT
    if (!LGPresent() || !g.window) return NO;
    NSNumber *c = objc_getAssociatedObject(g, &gNGLoaded); NSNumber *t = objc_getAssociatedObject(g, &gNGOff);
    CFTimeInterval now = CACurrentMediaTime();
    if (c && now - c.doubleValue < 1.0) return t.boolValue;
    BOOL theirs = LGTheirsOn(g).count > 0;
    objc_setAssociatedObject(g, &gNGLoaded, @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(g, &gNGOff, @(theirs), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return theirs;
#else
    return NO;
#endif
}
// turn a glass view of ours into the liquid glass (call it again whenever its frame or radius changes)
static void NGApply(UIView *g) {
    if (!g || [g.accessibilityIdentifier isEqualToString:@"ng.skip"] || !NGClass()) return;
    if (!gNGViews) gNGViews = [NSHashTable weakObjectsHashTable];
    [gNGViews addObject:g];
    if (!NGOn() || NGTheirs(g)) { NGRemove(g); return; }
    UIView *box = NGBox(g);
    if ([g isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *e = (UIVisualEffectView *)g;
        if (e.effect) { objc_setAssociatedObject(e, kNGFx, e.effect, OBJC_ASSOCIATION_RETAIN_NONATOMIC); e.effect = nil; }
        // our own flat tints / sheens inside it step aside (real content like labels stays)
        for (UIView *s in box.subviews) if (!NGIsGlass(s) && [s class] == [UIView class] && !s.subviews.count && s.backgroundColor && !s.hidden) { s.hidden = YES; objc_setAssociatedObject(s, kNGBg, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        for (CALayer *l in box.layer.sublayers) if (([l.name hasSuffix:@"sheen"] || [l.name hasSuffix:@"shine"]) && !l.hidden) { l.hidden = YES; [l setValue:@YES forKey:@"ngHid"]; }
    }
    if (box.backgroundColor && ![box.backgroundColor isEqual:UIColor.clearColor]) { objc_setAssociatedObject(g, kNGBg, box.backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC); box.backgroundColor = UIColor.clearColor; }
    UIView *lgv = nil;
    for (UIView *v in box.subviews) if (NGIsGlass(v)) { lgv = v; break; }
    if (!lgv) { lgv = NGMake(box.bounds); if (!lgv) return; [box insertSubview:lgv atIndex:0]; }
    else if (box.subviews.firstObject != lgv) [box sendSubviewToBack:lgv];
    lgv.layer.zPosition = -100;   // always under the icon / title, whatever gets added later
    // LiquidAss draws the rim and the shine: ours step aside
    if (g.layer.borderWidth != 0) g.layer.borderWidth = 0;
    for (CALayer *l in g.layer.sublayers) if ([l.name hasSuffix:@".rim"] && l.opacity != 0) l.opacity = 0;
    if (!g.clipsToBounds && ![g isKindOfClass:[UIButton class]]) g.clipsToBounds = YES;
    CGFloat r = g.layer.cornerRadius > 0 ? g.layer.cornerRadius : MIN(g.bounds.size.width, g.bounds.size.height) / 2;
    NGFit(lgv, box.bounds, r);
    NGStyle(lgv, gNGFrost, g.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark);
}
static void NGRefreshAll(void) {
    for (UIView *g in [gNGViews allObjects]) {
        objc_setAssociatedObject(g, &gNGLoaded, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NGApply(g);
        [g.superview setNeedsLayout];
    }
}
