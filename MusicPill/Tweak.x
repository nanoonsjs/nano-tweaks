// MusicPill 0.3.0 - made by nano
// Apple Music only.
//  1. "Listen Now" tab -> "Home" with a house icon.
//  2. Now-playing bar -> rounded floating pill (iOS 26 style).
//     Done ONLY with corner radius + a transform on the bar itself. We never
//     change its frame, and all work runs after the layout pass finishes, so
//     it can't cause a layout loop.
//  3. Debug overlay: lists the views it found near the tab bar so the
//     detection can be fixed from a screenshot. On by default in this test build.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define DOM CFSTR("com.user.musicpill")
#define NOTIFY CFSTR("com.user.musicpill/prefschanged")
#define DEBUG_TAG 0x4D504442

static BOOL gRename = YES, gRound = YES, gDebug = YES;

static const void *kMini = &kMini;
static const void *kBusy = &kBusy;
static const void *kHome = &kHome;
static const void *kStyled = &kStyled;

static BOOL PrefBool(CFStringRef key, BOOL def) {
    CFPropertyListRef v = CFPreferencesCopyAppValue(key, DOM);
    if (!v) return def;
    return [(__bridge_transfer id)v boolValue];
}
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    gRename = PrefBool(CFSTR("rename"), YES);
    gRound  = PrefBool(CFSTR("round"), YES);
    gDebug  = PrefBool(CFSTR("debug"), YES);
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }

#pragma mark - Listen Now -> Home

static BOOL IsListenNow(NSString *s) {
    return gRename && [s isKindOfClass:[NSString class]] && [s isEqualToString:@"Listen Now"];
}
static UIImage *House(void) { return [UIImage systemImageNamed:@"house.fill"]; }

static void MarkHome(UITabBarItem *it) {
    if (objc_getAssociatedObject(it, kHome)) return;
    objc_setAssociatedObject(it, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    it.image = House();
    it.selectedImage = House();
}

// Music renames the tab through the view controller's title, which never calls
// -[UITabBarItem setTitle:], so 0.2.0 got the "Home" text but not the icon.
// Catch it from the tab bar instead.
static void FixTabItems(UITabBar *tb) {
    if (!gRename) return;
    for (UITabBarItem *it in tb.items)
        if ([it.title isEqualToString:@"Home"] || [it.title isEqualToString:@"Listen Now"]) {
            if ([it.title isEqualToString:@"Listen Now"]) it.title = @"Home";
            MarkHome(it);
        }
}

%hook UITabBarItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSInteger)tag {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), tag);
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)sel {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), House());
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (void)setTitle:(NSString *)title {
    if (IsListenNow(title)) {
        %orig(@"Home");
        __weak UITabBarItem *weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{ if (weak) MarkHome(weak); });
        return;
    }
    %orig;
}
- (void)setImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
- (void)setSelectedImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
%end

%hook UIViewController
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
%end

#pragma mark - now-playing pill

// Frame of v in root's coordinates, ignoring v's own transform
// (so it still matches after we've scaled it).
static CGRect UntransformedRect(UIView *v, UIView *root) {
    if (!v.superview) return CGRectNull;
    CGPoint c = [v.superview convertPoint:v.center toView:root];
    CGSize s = v.bounds.size;
    return CGRectMake(c.x - s.width / 2, c.y - s.height / 2, s.width, s.height);
}

static BOOL Geometry(UIView *v, UIView *root, CGRect tabRect, BOOL loose) {
    if (v.hidden || v.alpha < 0.01 || v.tag == DEBUG_TAG) return NO;
    CGRect r = UntransformedRect(v, root);
    if (CGRectIsNull(r)) return NO;
    CGFloat h = r.size.height;
    if (h < 44 || h > 100) return NO;
    if (r.size.width < root.bounds.size.width * (loose ? 0.6 : 0.9)) return NO;
    // Sits just above the tab bar (allow a gap for floating tab bars).
    CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
    return gap >= -4 && gap <= 40;
}

static UIView *FindByName(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]]) continue;
        if ([NSStringFromClass([sub class]) containsString:@"MiniPlayer"] && Geometry(sub, root, tabRect, YES)) return sub;
        if (depth < 7) { UIView *f = FindByName(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

static UIView *FindByShape(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]] || [sub isKindOfClass:[UITabBar class]]) continue;
        if (Geometry(sub, root, tabRect, NO)) return sub; // outermost match
        if (depth < 4) { UIView *f = FindByShape(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

static CGAffineTransform PillTransform(UIView *m) {
    CGFloat W = m.bounds.size.width;
    CGFloat s = W > 100 ? (W - 24) / W : 1;
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -6), s, s);
}

static void StylePill(UIView *m) {
    CGFloat r = m.bounds.size.height / 2;
    if (m.layer.cornerRadius != r) {
        m.layer.cornerRadius = r;
        m.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (!objc_getAssociatedObject(m, kStyled)) {
        objc_setAssociatedObject(m, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        m.clipsToBounds = YES;
        m.layer.borderWidth = 0.75;
        m.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    }
    CGAffineTransform t = PillTransform(m);
    // Don't fight Music's own animations: only set when it's at rest.
    if (CGAffineTransformIsIdentity(m.transform)) m.transform = t;
}

static void UnstylePill(UIView *m) {
    if (!objc_getAssociatedObject(m, kStyled)) return;
    if (CGAffineTransformEqualToTransform(m.transform, PillTransform(m))) m.transform = CGAffineTransformIdentity;
    m.layer.cornerRadius = 0;
    m.layer.borderWidth = 0;
}

#pragma mark - debug overlay

static void CollectCandidates(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth, NSMutableArray *out) {
    for (UIView *sub in view.subviews) {
        if (out.count >= 10) return;
        if (sub == tb || sub.tag == DEBUG_TAG || [sub isKindOfClass:[UIScrollView class]]) continue;
        CGRect r = UntransformedRect(sub, root);
        if (!CGRectIsNull(r)) {
            CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
            if (r.size.width >= root.bounds.size.width * 0.6 && r.size.height >= 30 && r.size.height <= 220 && gap > -160 && gap < 60) {
                NSString *name = NSStringFromClass([sub class]);
                NSRange dot = [name rangeOfString:@"." options:NSBackwardsSearch];
                if (dot.location != NSNotFound) name = [name substringFromIndex:dot.location + 1];
                [out addObject:[NSString stringWithFormat:@"%@ h=%.0f gap=%.0f d=%d%@", name, r.size.height, gap, depth, sub.hidden ? @" hidden" : @""]];
            }
        }
        if (depth < 6) CollectCandidates(sub, root, tabRect, tb, depth + 1, out);
    }
}

static void UpdateDebug(UITabBar *tb, UIView *root, CGRect tabRect, UIView *mini) {
    UIWindow *w = tb.window;
    if (!w) return;
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = DEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.85];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSMutableArray *c = [NSMutableArray array];
    CollectCandidates(root, root, tabRect, tb, 0, c);
    NSString *found = @"none";
    if (mini) {
        CGRect r = UntransformedRect(mini, root);
        found = [NSString stringWithFormat:@"%@ h=%.0f", NSStringFromClass([mini class]), r.size.height];
    }
    NSString *text = [NSString stringWithFormat:@" MusicPill debug (turn off in Settings > MusicPill)\n tab y=%.0f h=%.0f screen h=%.0f\n PICKED: %@\n %@",
                      CGRectGetMinY(tabRect), tabRect.size.height, root.bounds.size.height, found,
                      [c componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(12, 110, width, s.height + 8);
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

#pragma mark - driver

static void Update(UITabBar *tb) {
    FixTabItems(tb);
    UIView *root = tb.superview;
    if (!root || !tb.window) return;
    CGRect tabRect = UntransformedRect(tb, root);

    UIView *mini = objc_getAssociatedObject(tb, kMini);
    if (gRound) {
        if (!mini || !mini.window || ![mini isDescendantOfView:root] || !Geometry(mini, root, tabRect, YES)) {
            mini = FindByName(root, root, tabRect, tb, 0) ?: FindByShape(root, root, tabRect, tb, 0);
            objc_setAssociatedObject(tb, kMini, mini, OBJC_ASSOCIATION_ASSIGN);
        }
        if (mini) StylePill(mini);
    } else if (mini) {
        UnstylePill(mini);
    }
    UpdateDebug(tb, root, tabRect, gRound ? mini : nil);
}

%hook UITabBar
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UITabBar *weak = self;
    // Run after this layout pass finishes.
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBar *tb = weak;
        if (!tb) return;
        @try { Update(tb); } @catch (__unused id e) {}
        objc_setAssociatedObject(tb, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}
%end

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.Music"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
}
