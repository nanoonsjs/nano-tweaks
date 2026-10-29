// PhotosGlass 0.1.0 - made by nano
// Photos-only. Turns the bottom toolbar into iOS 26 style glass pills:
// [share]  [middle buttons]  [delete]
//
// Safety rules learned from CC26:
//  - Never change the toolbar's own frame or its buttons' frames.
//  - Our pills live inside our own container view, so moving them can't
//    make the toolbar lay out again.
//  - Frames are only set when they actually change, and a busy flag stops
//    any re-entry.
//  - Appearance changes happen once, on the next main-queue turn, never
//    inside layoutSubviews.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define DOM CFSTR("com.user.photosglass")
#define NOTIFY CFSTR("com.user.photosglass/prefschanged")

static BOOL gEnabled = YES;

static const void *kContainer = &kContainer;
static const void *kStyled = &kStyled;
static const void *kBusy = &kBusy;

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    CFPropertyListRef v = CFPreferencesCopyAppValue(CFSTR("enabled"), DOM);
    gEnabled = v ? [(__bridge_transfer id)v boolValue] : YES;
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }

static id KV(id obj, NSString *key) {
    if (!obj) return nil;
    @try { return [obj valueForKey:key]; } @catch (__unused id e) { return nil; }
}

static void SetFrameIfChanged(UIView *v, CGRect r) {
    if (!CGRectEqualToRect(v.frame, r)) v.frame = r;
}

static UIView *MakeGlass(void) {
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    v.userInteractionEnabled = NO;
    v.clipsToBounds = YES;
    v.layer.cornerCurve = kCACornerCurveContinuous;
    v.layer.borderWidth = 0.75;
    v.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    UIView *sheen = [[UIView alloc] initWithFrame:v.contentView.bounds];
    sheen.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    sheen.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sheen.userInteractionEnabled = NO;
    [v.contentView addSubview:sheen];
    return v;
}

static void StyleToolbarOnce(UIToolbar *tb) {
    if (objc_getAssociatedObject(tb, kStyled)) return;
    objc_setAssociatedObject(tb, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UIToolbar *weak = tb;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIToolbar *t = weak;
        if (!t || !gEnabled) return;
        UIToolbarAppearance *a = [UIToolbarAppearance new];
        [a configureWithTransparentBackground];
        t.standardAppearance = a;
        t.compactAppearance = a;
        t.scrollEdgeAppearance = a;
        t.compactScrollEdgeAppearance = a;
        t.tintColor = UIColor.whiteColor;
    });
}

static UIView *ContainerFor(UIToolbar *tb) {
    UIView *c = objc_getAssociatedObject(tb, kContainer);
    if (!c) {
        c = [UIView new];
        c.userInteractionEnabled = NO;
        c.backgroundColor = UIColor.clearColor;
        for (int i = 0; i < 3; i++) [c addSubview:MakeGlass()];
        objc_setAssociatedObject(tb, kContainer, c, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (c.superview != tb) {
        UIView *bg = nil;
        for (UIView *s in tb.subviews)
            if ([NSStringFromClass([s class]) containsString:@"Background"]) { bg = s; break; }
        if (bg) [tb insertSubview:c aboveSubview:bg];
        else [tb insertSubview:c atIndex:0];
    }
    return c;
}

static void LayoutPills(UIToolbar *tb) {
    UIView *existing = objc_getAssociatedObject(tb, kContainer);
    if (!gEnabled) { existing.hidden = YES; return; }

    NSMutableArray<NSValue *> *frames = [NSMutableArray array];
    for (UIBarButtonItem *item in tb.items) {
        UIView *v = KV(item, @"view");
        if (![v isKindOfClass:[UIView class]] || v.hidden || v.alpha < 0.01 || !v.window) continue;
        if (v.bounds.size.width < 2) continue;
        [frames addObject:[NSValue valueWithCGRect:[v convertRect:v.bounds toView:tb]]];
    }
    // Only the photo/video viewer toolbar (3-8 buttons). Leave anything else alone.
    if (frames.count < 3 || frames.count > 8) { existing.hidden = YES; return; }
    [frames sortUsingComparator:^NSComparisonResult(NSValue *a, NSValue *b) {
        CGFloat x = CGRectGetMinX(a.CGRectValue), y = CGRectGetMinX(b.CGRectValue);
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];

    StyleToolbarOnce(tb);
    UIView *c = ContainerFor(tb);
    c.hidden = NO;
    SetFrameIfChanged(c, tb.bounds);

    CGFloat cy = 0;
    for (NSValue *f in frames) cy += CGRectGetMidY(f.CGRectValue);
    cy /= frames.count;

    const CGFloat H = 50, pad = 12;
    CGRect first = frames.firstObject.CGRectValue, last = frames.lastObject.CGRectValue;
    CGRect mid = CGRectNull;
    for (NSUInteger i = 1; i + 1 < frames.count; i++) mid = CGRectUnion(mid, frames[i].CGRectValue);

    CGRect r0 = CGRectMake(round(CGRectGetMidX(first) - H / 2), round(cy - H / 2), H, H);
    CGRect r2 = CGRectMake(round(CGRectGetMidX(last) - H / 2), round(cy - H / 2), H, H);
    CGFloat mw = MAX(CGRectGetWidth(mid) + pad * 2, H);
    CGRect r1 = CGRectMake(round(CGRectGetMidX(mid) - mw / 2), round(cy - H / 2), round(mw), H);

    CGRect rects[3] = { r0, r1, r2 };
    for (int i = 0; i < 3 && i < (int)c.subviews.count; i++) {
        UIView *g = c.subviews[i];
        SetFrameIfChanged(g, rects[i]);
        if (g.layer.cornerRadius != H / 2) g.layer.cornerRadius = H / 2;
    }
}

%hook UIToolbar
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try { LayoutPills(self); } @catch (__unused id e) {}
    objc_setAssociatedObject(self, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.mobileslideshow"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
}
