// MusicPill 0.1.1 - made by nano
// Apple Music only. Minimal build: ONLY renames "Listen Now" to "Home"
// (tab title, tab icon, page title). No layout code at all.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define DOM CFSTR("com.user.musicpill")
#define NOTIFY CFSTR("com.user.musicpill/prefschanged")

static BOOL gRename = YES;
static const void *kHome = &kHome;

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    CFPropertyListRef v = CFPreferencesCopyAppValue(CFSTR("rename"), DOM);
    gRename = v ? [(__bridge_transfer id)v boolValue] : YES;
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }

static BOOL IsListenNow(NSString *s) {
    return gRename && [s isKindOfClass:[NSString class]] && [s isEqualToString:@"Listen Now"];
}
static UIImage *House(void) { return [UIImage systemImageNamed:@"house.fill"]; }

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
        objc_setAssociatedObject(self, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig(@"Home");
        __weak UITabBarItem *weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{ weak.image = House(); weak.selectedImage = House(); });
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

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.Music"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
}
