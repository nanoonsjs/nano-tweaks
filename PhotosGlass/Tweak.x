// PhotosGlass 0.3.0 - made by nano
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

// The visible glyph inside a bar button: its icon image or its text label.
// Bar button views are wider than the icon (tap padding, edge margins), so
// centering on the button view put the pills off-center.
static UIView *Glyph(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.bounds.size.width < 2 || s.bounds.size.height < 2) continue;
        if ([s isKindOfClass:[UIImageView class]] && ((UIImageView *)s).image) return s;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) return s;
        if (depth < 5) { UIView *g = Glyph(s, depth + 1); if (g) return g; }
    }
    return nil;
}

typedef struct { CGRect r; BOOL text; } PGItem;

static CGRect SinglePill(PGItem it, CGFloat cy, CGFloat H) {
    // Icons get a circle; text buttons (Delete, Recover...) get a capsule that fits the word.
    CGFloat w = it.text ? MAX(H, CGRectGetWidth(it.r) + 32) : H;
    return CGRectMake(round(CGRectGetMidX(it.r) - w / 2), round(cy - H / 2), round(w), H);
}

static void LayoutPills(UIToolbar *tb) {
    UIView *existing = objc_getAssociatedObject(tb, kContainer);
    if (!gEnabled) { existing.hidden = YES; return; }

    PGItem items[8];
    int n = 0;
    for (UIBarButtonItem *item in tb.items) {
        UIView *v = KV(item, @"view");
        if (![v isKindOfClass:[UIView class]] || v.hidden || v.alpha < 0.01 || !v.window) continue;
        if (v.bounds.size.width < 2) continue;
        if (n >= 8) { n = 99; break; }
        UIView *g = Glyph(v, 0);
        UIView *target = g ?: v;
        items[n].r = [target convertRect:target.bounds toView:tb];
        items[n].text = [g isKindOfClass:[UILabel class]];
        n++;
    }
    // Only the photo/video viewer toolbar (3-8 buttons). Leave anything else alone.
    if (n < 3 || n > 8) { existing.hidden = YES; return; }
    // Left to right.
    for (int i = 1; i < n; i++) {
        PGItem k = items[i]; int j = i - 1;
        while (j >= 0 && CGRectGetMinX(items[j].r) > CGRectGetMinX(k.r)) { items[j + 1] = items[j]; j--; }
        items[j + 1] = k;
    }

    StyleToolbarOnce(tb);
    UIView *c = ContainerFor(tb);
    c.hidden = NO;
    SetFrameIfChanged(c, tb.bounds);

    CGFloat cy = 0;
    for (int i = 0; i < n; i++) cy += CGRectGetMidY(items[i].r);
    cy /= n;

    const CGFloat H = 50, pad = 22;
    CGRect mid = CGRectNull;
    for (int i = 1; i + 1 < n; i++) mid = CGRectUnion(mid, items[i].r);

    CGRect r0 = SinglePill(items[0], cy, H);
    CGRect r2 = SinglePill(items[n - 1], cy, H);
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
