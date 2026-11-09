// FastHaptic 2.0 - made by nano
// Faster Haptic Touch everywhere: every long-press menu (apps, Home Screen icons, Control Center,
// links, photos...) opens sooner. Works in every app, because it speeds up iOS's own Haptic Touch
// timer in UIKit itself, not one app's buttons.
//
// How: iOS opens a Haptic Touch menu when a long-press recognizer that belongs to a "click
// interaction" (UIKit's name for Haptic Touch) has been held long enough. When such a recognizer
// starts a touch, its wait time is shortened (once, from Apple's own value). UIKit's click driver
// classes also get their own wait times shortened.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include "../shared/NanoSettings.h"

#define DOM CFSTR("com.nano.fasthaptic")
static BOOL gOn = YES;
static double gFactor = 0.55;   // 0.75 fast, 0.55 faster, 0.35 fastest

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingString:@"com.nano.fasthaptic.plist"]];
        if ([d isKindOfClass:[NSDictionary class]]) { f = d; break; }
    }
    id on = f[@"enabled"], sp = f[@"speed"];
    if (!on) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("enabled"), DOM); if (cf) on = (__bridge_transfer id)cf; }
    if (!sp) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("speed"), DOM); if (cf) sp = (__bridge_transfer id)cf; }
    gOn = on ? [on boolValue] : YES;
    double s = sp ? [sp doubleValue] : 0.55;
    gFactor = (s >= 0.2 && s <= 1) ? s : 0.55;
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }
static double Factor(void) { return gOn ? gFactor : 1.0; }

#pragma mark - which recognizers are Haptic Touch

static const void *kIsClick = &kIsClick, *kOrigDur = &kOrigDur;
static BOOL IsClickRecognizer(UIGestureRecognizer *g) {
    NSNumber *c = objc_getAssociatedObject(g, kIsClick);
    if (c) return c.boolValue;
    NSMutableString *s = [NSMutableString stringWithString:NSStringFromClass(g.class)];
    if (g.delegate) [s appendString:NSStringFromClass([(NSObject *)g.delegate class])];
    if (g.name) [s appendString:g.name];
    @try { id t = [g valueForKey:@"_targets"]; if (t) [s appendString:[t description]]; } @catch (__unused id e) {}
    NSString *l = s.lowercaseString;
    BOOL yes = [l containsString:@"clickinteraction"] || [l containsString:@"contextmenu"] || [l containsString:@"previewinteraction"] ||
               [l containsString:@"clickpresentation"] || ([l containsString:@"click"] && [l containsString:@"driver"]);
    objc_setAssociatedObject(g, kIsClick, @(yes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return yes;
}

#pragma mark - long press: shorter wait for Haptic Touch ones

static void (*origLPBegan)(UILongPressGestureRecognizer *, SEL, NSSet *, UIEvent *);
static void LPBegan(UILongPressGestureRecognizer *self, SEL _cmd, NSSet *touches, UIEvent *e) {
    @try {
        if (IsClickRecognizer(self)) {
            NSNumber *o = objc_getAssociatedObject(self, kOrigDur);
            if (!o) { o = @(self.minimumPressDuration); objc_setAssociatedObject(self, kOrigDur, o, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            double want = o.doubleValue * Factor();
            if (fabs(self.minimumPressDuration - want) > 0.001) self.minimumPressDuration = want;
        }
    } @catch (__unused id ex) {}
    origLPBegan(self, _cmd, touches, e);
}
// Apple sets the wait again (e.g. after the menu closes): remember its value, keep ours
static void (*origLPSetDur)(UILongPressGestureRecognizer *, SEL, NSTimeInterval);
static void LPSetDur(UILongPressGestureRecognizer *self, SEL _cmd, NSTimeInterval d) {
    if (objc_getAssociatedObject(self, kOrigDur) && IsClickRecognizer(self)) {
        // our own change comes through here too: only take values that aren't ours
        NSNumber *o = objc_getAssociatedObject(self, kOrigDur);
        if (fabs(d - o.doubleValue * Factor()) > 0.001) { objc_setAssociatedObject(self, kOrigDur, @(d), OBJC_ASSOCIATION_RETAIN_NONATOMIC); d = d * Factor(); }
    }
    origLPSetDur(self, _cmd, d);
}

#pragma mark - UIKit's click classes: their own timers

static NSMutableSet *gHooked;
// every "...duration" / "...delay" number a click class hands out is shortened
static void ScaleTimers(Class c, BOOL meta) {
    if (!c) return;
    unsigned int n = 0; Method *ms = class_copyMethodList(meta ? object_getClass((id)c) : c, &n);
    for (unsigned int i = 0; i < n; i++) {
        SEL s = method_getName(ms[i]);
        NSString *name = NSStringFromSelector(s);
        NSString *l = name.lowercaseString;
        const char *te = method_getTypeEncoding(ms[i]);
        if (!te || te[0] != 'd' || method_getNumberOfArguments(ms[i]) != 2) continue;
        if (!([l containsString:@"duration"] || [l containsString:@"delay"] || [l containsString:@"timeout"] || ([l containsString:@"threshold"] && [l containsString:@"time"]))) continue;
        if ([l containsString:@"animation"] || [l containsString:@"dismiss"]) continue;   // only the wait, not how the menu animates
        NSString *key = [NSString stringWithFormat:@"%@%@%@", meta ? @"+" : @"-", NSStringFromClass(c), name];
        if ([gHooked containsObject:key]) continue;
        [gHooked addObject:key];
        IMP orig = method_getImplementation(ms[i]);
        IMP rep = imp_implementationWithBlock(^double(id me) { return ((double (*)(id, SEL))orig)(me, s) * Factor(); });
        method_setImplementation(ms[i], rep);
    }
    free(ms);
}
static void HookClickClasses(void) {
    if (!gHooked) gHooked = [NSMutableSet set];
    for (NSString *n in @[@"_UILongPressClickInteractionDriver", @"_UIClickInteractionDefaultDriver", @"_UIClickInteraction", @"_UIClickPresentationInteraction",
                          @"_UITouchDurationObservingGestureRecognizer", @"_UIClickInteractionDriverBase", @"_UIRelationshipGestureRecognizer"]) {
        Class c = NSClassFromString(n);
        if (!c) continue;
        ScaleTimers(c, NO);
        ScaleTimers(c, YES);
    }
}
// _UITouchDurationObservingGestureRecognizer (used by Haptic Touch on some iOS versions)
static void ShortenDurationObserver(UIGestureRecognizer *g) {
    SEL get = NSSelectorFromString(@"minimumDurationRequired"), set = NSSelectorFromString(@"setMinimumDurationRequired:");
    if (![g respondsToSelector:get] || ![g respondsToSelector:set]) return;
    NSNumber *o = objc_getAssociatedObject(g, kOrigDur);
    double cur = ((double (*)(id, SEL))objc_msgSend)(g, get);
    if (!o) { o = @(cur); objc_setAssociatedObject(g, kOrigDur, o, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    double want = o.doubleValue * Factor();
    if (fabs(cur - want) > 0.001) ((void (*)(id, SEL, double))objc_msgSend)(g, set, want);
}
static void (*origDOBegan)(UIGestureRecognizer *, SEL, NSSet *, UIEvent *);
static void DOBegan(UIGestureRecognizer *self, SEL _cmd, NSSet *t, UIEvent *e) {
    @try { ShortenDurationObserver(self); } @catch (__unused id ex) {}
    origDOBegan(self, _cmd, t, e);
}

#pragma mark - Settings: a "hold me" button to feel the speed

@interface FHTry : NSObject <UIContextMenuInteractionDelegate>
+ (instancetype)shared;
@end
@implementation FHTry
+ (instancetype)shared { static FHTry *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [FHTry new]; }); return s; }
- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)i configurationForMenuAtLocation:(CGPoint)p {
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu *(NSArray *s) {
        UIAction *a = [UIAction actionWithTitle:@"That was FastHaptic" image:[UIImage systemImageNamed:@"bolt.fill"] identifier:nil handler:^(__unused UIAction *x) {}];
        UIAction *b = [UIAction actionWithTitle:@"Works in every app" image:[UIImage systemImageNamed:@"apps.iphone"] identifier:nil handler:^(__unused UIAction *x) {}];
        return [UIMenu menuWithTitle:@"" children:@[a, b]];
    }];
}
@end
@interface NSObject (FHPS)
- (id)propertyForKey:(NSString *)k;
- (NSString *)identifier;
@end
static void FHTryLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    UIView *b = [cv viewWithTag:0x4648];
    if (!b) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        b = [UIView new]; b.tag = 0x4648;
        b.backgroundColor = [UIColor colorWithRed:0.42 green:0.32 blue:0.92 alpha:1];
        b.layer.cornerRadius = 22; b.layer.cornerCurve = kCACornerCurveContinuous;
        UILabel *l = [UILabel new]; l.tag = 1; l.text = @"Hold Me"; l.textColor = UIColor.whiteColor;
        l.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]; l.textAlignment = NSTextAlignmentCenter;
        [b addSubview:l];
        [b addInteraction:[[UIContextMenuInteraction alloc] initWithDelegate:[FHTry shared]]];
        [cv addSubview:b];
    }
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height;
    b.frame = CGRectMake(W / 2 - 90, H / 2 - 22, 180, 44);
    [b viewWithTag:1].frame = b.bounds;
}
static NSArray *(*origFHSpecs)(id, SEL);
static NSArray *FHSpecs(id self, SEL _cmd) {
    NSArray *a = origFHSpecs(self, _cmd);
    @try {
        for (id s in a) if ([s respondsToSelector:@selector(identifier)] && [[s identifier] isEqualToString:@"FH_TRY"]) {
            Class sup = NSClassFromString(@"PSTableCell");
            Class c = objc_getClass("FHTryCell");
            if (!c && sup) { c = objc_allocateClassPair(sup, "FHTryCell", 0); class_addMethod(c, @selector(layoutSubviews), (IMP)FHTryLayout, "v@:"); objc_registerClassPair(c); }
            if (c && [s propertyForKey:@"cellClass"] != c) ((void (*)(id, SEL, id, id))objc_msgSend)(s, @selector(setProperty:forKey:), c, @"cellClass");
        }
    } @catch (__unused id e) {}
    return a;
}

%ctor {
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.fasthaptic/prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    MSHookMessageEx([UILongPressGestureRecognizer class], @selector(touchesBegan:withEvent:), (IMP)LPBegan, (IMP *)&origLPBegan);
    MSHookMessageEx([UILongPressGestureRecognizer class], @selector(setMinimumPressDuration:), (IMP)LPSetDur, (IMP *)&origLPSetDur);
    Class DO = NSClassFromString(@"_UITouchDurationObservingGestureRecognizer");
    if (DO && class_getInstanceMethod(DO, @selector(touchesBegan:withEvent:))) MSHookMessageEx(DO, @selector(touchesBegan:withEvent:), (IMP)DOBegan, (IMP *)&origDOBegan);
    @try { HookClickClasses(); } @catch (__unused id e) {}
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"]) {
        StartNanoSettings();
        Class PS = NSClassFromString(@"PSListController");
        if (PS) MSHookMessageEx(PS, @selector(specifiers), (IMP)FHSpecs, (IMP *)&origFHSpecs);
        else dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            Class P2 = NSClassFromString(@"PSListController");
            if (P2) MSHookMessageEx(P2, @selector(specifiers), (IMP)FHSpecs, (IMP *)&origFHSpecs);
        });
    }
}
