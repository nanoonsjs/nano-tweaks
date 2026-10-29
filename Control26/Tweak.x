// Control26 0.2.2 - made by nano
// 0.2.2: iOS 26 tiles (square, brighter glass rim, up/down chevron after the
//        status), menu probing for Wi-Fi/Bluetooth lists.
// 0.2.1: Wi-Fi/Bluetooth arrows expand Apple's nested module, rounder bars,
//        sliders settle back slowly (~0.5s) with no bounce.
// 0.2.0: live signal bars, no outer glass behind the cards, Wi-Fi/Bluetooth
//        arrows open their lists, white icons when off, Airplane take-off.
// 0.1.9: expanded connectivity (hold Wi-Fi) rebuilt as iOS 26 glass cards:
//        Airplane/Hotspot pills, Wi-Fi/AirDrop/Cellular/Bluetooth tiles.
// 0.1.8: previous/play/next animate on the spring engine (press sink, release
//        pop, arrow fling + ghost, play/pause morph). Expanded connectivity:
//        Cellular Data icon -> iOS 26 signal bars, and a debug map of it.
// 0.1.7: star uses Music's Love command (21) and can un-love (IsNegative);
//        loved state read from the command's active flag. Instant song changes
//        via MediaRemote notifications, artwork slides in the skip direction,
//        swoosh/morph animations on previous/play/next, no haptic on skips,
//        smaller AirPlay icons.
// 0.1.6: spring physics (per screen refresh) for the jelly buttons and slider
//        stretch, favorite star only for Apple Music + burst animation, smaller
//        AirPlay capsule tucked under the volume slider, debug shows Music's
//        supported commands so the favorite command can be confirmed.
// 0.1.5: every view hidden in the music module is tracked and restored when it
//        switches between small and expanded (fixes missing back button and the
//        doubled AirPlay icons). Expanded player gets an "AirPlay" capsule under
//        the volume slider and a favorite star left of the play controls.
// 0.1.4: own previous/play/next (Apple's group scales itself, so it couldn't
//        be moved), slider icons turn white when the fill is below them,
//        spring-back carries finger speed, "jelly" round buttons.
// 0.1.3: small AirPlay icon searched in the module's container too; transport
//        row moved as a group (down + tighter); brightness updates with no
//        animation for exact 1:1 tracking; the whole slider shell stretches.
// 0.1.2: real AirPlay picker in the round button (AVRoutePickerView) and the
//        small original fully hidden; Apple's gray slider icons fully hidden;
//        transport row found reliably and placed like iOS 26; brightness
//        slider tracks your finger directly (1:1, every touch update).
// 0.1.1: song info + artwork from MediaRemote ("Not Playing" when idle), round
//        AirPlay finds Apple's button by position too, transport buttons pulled
//        together near the bottom, smoother stretch / spring / icon changes.
// iOS 26 style Control Center for iOS 16 (SpringBoard).
//  1. Music module: artwork top-left, round AirPlay top-right, title/artist
//     left-aligned. Built as an overlay; Apple's play buttons stay as-is.
//  2. Slider icons: orange sun (brightness), blue speaker (volume).
//  3. Slider bounce: stretch past the ends and spring back; icon pops at 0/100%.
//
// SpringBoard safety rules (an earlier CC tweak froze the phone):
//  - NO layoutSubviews hooks and NO frame changes on Apple's views.
//  - Only our own overlay views get frames; Apple's views only get alpha
//    (kept hidden by setAlpha hooks) and a transform during the bounce.
//  - Everything runs from a timer that exists only while Control Center is
//    on screen, wrapped in @try.
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>

@interface MRUNowPlayingView : UIView @end
@interface CCUIBaseSliderView : UIView @end
@interface MRUContinuousSliderView : UIView @end
@interface CCUICAPackageView : UIView @end
@interface CCUIRoundButton : UIView @end
@interface CCUIButtonModuleView : UIView @end
@interface CCUILabeledRoundButton : UIView @end

#define DOM_NS @"com.user.control26"
#define DOM CFSTR("com.user.control26")
#define NOTIFY CFSTR("com.user.control26/prefschanged")
#define OVERLAY_TAG 0x43323630
#define GLYPH_TAG   0x43323631
#define DEBUG_TAG   0x43323632
#define EXP_TAG     0x43323633
#define CELL_TAG    0x43323634
#define CONN_TAG    0x43323635
#define CARD_A      0.24
#define CARD_PRESSED 0.34

static BOOL gEnabled = YES, gMusic = YES, gColors = YES, gBounce = YES, gDebug = NO, gJelly = YES, gConn = YES;

static const void *kHidByUs = &kHidByUs;
static const void *kBounce = &kBounce;
static const void *kLastValue = &kLastValue;

#define SUN_COLOR    [UIColor colorWithRed:0.86 green:0.60 blue:0.16 alpha:1]
#define VOLUME_COLOR [UIColor colorWithRed:0.20 green:0.50 blue:0.72 alpha:1]

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
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = ReadPrefsFile();
    gEnabled = PrefBool(f, @"enabled", YES);
    gMusic   = PrefBool(f, @"music", YES);
    gColors  = PrefBool(f, @"colors", YES);
    gBounce  = PrefBool(f, @"bounce", YES);
    gDebug   = PrefBool(f, @"debug", NO);
    gJelly   = PrefBool(f, @"jelly", YES);
    gConn    = PrefBool(f, @"conn", YES);
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ LoadPrefs(); });
}

#pragma mark - helpers

static id KV(id obj, NSString *key) {
    if (!obj) return nil;
    @try { return [obj valueForKey:key]; } @catch (__unused id e) { return nil; }
}

static BOOL InControlCenter(UIView *v) {
    int d = 0;
    for (UIView *p = v; p && d < 40; p = p.superview, d++) {
        NSString *n = NSStringFromClass([p class]);
        if ([n hasPrefix:@"CCUI"] || [n containsString:@"ControlCenter"]) return YES;
    }
    return NO;
}

static UIViewController *OwnerVC(UIView *v) {
    UIResponder *r = v; int d = 0;
    while (r && d++ < 60 && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
    return [r isKindOfClass:[UIViewController class]] ? (UIViewController *)r : nil;
}

static void HideOriginal(UIView *v) {
    if (!v) return;
    objc_setAssociatedObject(v, kHidByUs, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (v.alpha != 0) v.alpha = 0;
}
static void ShowOriginal(UIView *v);
static NSHashTable *gHiddenMusic;  // everything the music module code hid
static void HideMusic(UIView *v) {
    if (!v) return;
    if (!gHiddenMusic) gHiddenMusic = [NSHashTable weakObjectsHashTable];
    [gHiddenMusic addObject:v];
    HideOriginal(v);
}
static void RestoreMusic(void) {
    for (UIView *v in [gHiddenMusic allObjects]) ShowOriginal(v);
    [gHiddenMusic removeAllObjects];
}

static void ShowOriginal(UIView *v) {
    if (!v || !objc_getAssociatedObject(v, kHidByUs)) return;
    objc_setAssociatedObject(v, kHidByUs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    v.alpha = 1;
}

__attribute__((unused)) static void Forward(UIControl *c) {
    if (!c) return;
    UIControlEvents ev = c.allControlEvents;
    if (ev & UIControlEventTouchUpInside) [c sendActionsForControlEvents:UIControlEventTouchUpInside];
    else if (ev & UIControlEventPrimaryActionTriggered) [c sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
}

// A view that only catches touches on its own subviews (our buttons).
@interface C26PassView : UIView @end
@implementation C26PassView
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { UIView *h = [super hitTest:p withEvent:e]; return h == self ? nil : h; }
@end

#pragma mark - tracked views (only while Control Center is on screen)

static NSHashTable *gMediaViews, *gSliders, *gConnButtons;
static NSTimer *gTimer;
static NSString *gMusicDebug = @"-", *gSliderDebug = @"-", *gConnDebug = @"-";
static void Tick(void);

static void StartTimer(void) {
    if (gTimer) return;
    gTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *t) { @try { Tick(); } @catch (__unused id e) {} }];
    dispatch_async(dispatch_get_main_queue(), ^{ @try { Tick(); } @catch (__unused id e) {} });
}

#pragma mark - music module

// Now-playing info straight from MediaRemote (title, artist, artwork).
// 0.1.0 copied Apple's labels, but the first ones are the route name ("iPhone").
typedef void (*MRGetInfoFn)(dispatch_queue_t, void (^)(CFDictionaryRef));
static NSString *gNPTitle, *gNPArtist;
static UIImage *gArtwork;
static NSData *gArtworkData;
static CFTimeInterval gLastFetch;

typedef Boolean (*MRSendFn)(int, CFDictionaryRef);
typedef void (*MRIsPlayingFn)(dispatch_queue_t, void (^)(Boolean));
static BOOL gIsPlaying;
static NSString *gNPApp;           // bundle id of the app that is playing
static NSString *gCmdDebug = @"-";
static NSNumber *gNPLiked;   // loved? (from Music's Love command state)
static int gSkipDir;         // +1 next, -1 previous: which way the artwork slides
static NSString *gLikedLocally;
static void *MediaRemote(void) {
    static void *h; static dispatch_once_t o;
    dispatch_once(&o, ^{ h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY); });
    return h;
}
// 2 = play/pause, 4 = next track, 5 = previous track
static void SendMR(int cmd) {
    MRSendFn send = MediaRemote() ? (MRSendFn)dlsym(MediaRemote(), "MRMediaRemoteSendCommand") : NULL;
    if (send) send(cmd, NULL);
}
static NSString *MRConst(const char *sym, NSString *fallback) {
    CFStringRef *p = MediaRemote() ? (CFStringRef *)dlsym(MediaRemote(), sym) : NULL;
    return (p && *p) ? (__bridge NSString *)*p : fallback;
}
// Love / un-love the current Apple Music song (command 21 = "like track").
static void SendLove(BOOL love) {
    MRSendFn send = MediaRemote() ? (MRSendFn)dlsym(MediaRemote(), "MRMediaRemoteSendCommand") : NULL;
    if (!send) return;
    NSDictionary *opts = love ? nil : @{ MRConst("kMRMediaRemoteOptionIsNegative", @"kMRMediaRemoteOptionIsNegative"): @YES };
    send(21, (__bridge CFDictionaryRef)opts);
}
typedef void (*MRAppIDFn)(dispatch_queue_t, void (^)(CFStringRef));
typedef CFTypeRef (*MROriginFn)(void);
typedef void (*MRCmdsFn)(CFTypeRef, dispatch_queue_t, void (^)(CFArrayRef));
typedef int (*MRCmdIDFn)(CFTypeRef);
typedef Boolean (*MRCmdEnabledFn)(CFTypeRef);
typedef CFTypeRef (*MRCmdValueFn)(CFTypeRef, CFStringRef);

static void FetchAppAndCommands(void) {
    if (!MediaRemote()) return;
    MRAppIDFn appID = (MRAppIDFn)dlsym(MediaRemote(), "MRMediaRemoteGetNowPlayingApplicationDisplayID");
    if (appID) appID(dispatch_get_main_queue(), ^(CFStringRef bid) { gNPApp = bid ? [(__bridge NSString *)bid copy] : nil; });
    MROriginFn origin = (MROriginFn)dlsym(MediaRemote(), "MRMediaRemoteGetLocalOrigin");
    MRCmdsFn cmds = (MRCmdsFn)dlsym(MediaRemote(), "MRMediaRemoteGetSupportedCommandsForOrigin");
    MRCmdIDFn cmdID = (MRCmdIDFn)dlsym(MediaRemote(), "MRMediaRemoteCommandInfoGetCommand");
    MRCmdEnabledFn cmdOn = (MRCmdEnabledFn)dlsym(MediaRemote(), "MRMediaRemoteCommandInfoGetEnabled");
    MRCmdValueFn cmdValue = (MRCmdValueFn)dlsym(MediaRemote(), "MRMediaRemoteCommandInfoCopyValueForKey");
    NSString *activeKey = MRConst("kMRMediaRemoteCommandInfoIsActiveKey", @"kMRMediaRemoteCommandInfoIsActiveKey");
    if (!origin || !cmds || !cmdID) { gCmdDebug = @"(command list not available)"; return; }
    cmds(origin(), dispatch_get_main_queue(), ^(CFArrayRef list) {
        NSMutableArray *ids = [NSMutableArray array];
        NSNumber *loved = nil;
        for (id info in (__bridge NSArray *)list) {
            if (cmdOn && !cmdOn((__bridge CFTypeRef)info)) continue;
            int cmd = cmdID((__bridge CFTypeRef)info);
            [ids addObject:@(cmd)];
            // Love command's "active" flag = this song is loved.
            if (cmd == 21 && cmdValue) {
                CFTypeRef v = cmdValue((__bridge CFTypeRef)info, (__bridge CFStringRef)activeKey);
                if (v) { id obj = (__bridge_transfer id)v; if ([obj respondsToSelector:@selector(boolValue)]) loved = @([obj boolValue]); }
            }
        }
        if (loved) gNPLiked = loved;
        if (gDebug) gCmdDebug = [NSString stringWithFormat:@"app=%@ loved=%@ [%@]", gNPApp ?: @"?", loved ?: @"?", [ids componentsJoinedByString:@","]];
    });
}

static void FetchIsPlaying(void) {
    MRIsPlayingFn f = MediaRemote() ? (MRIsPlayingFn)dlsym(MediaRemote(), "MRMediaRemoteGetNowPlayingApplicationIsPlaying") : NULL;
    if (f) f(dispatch_get_main_queue(), ^(Boolean p) { gIsPlaying = p; });
}

static void FetchNowPlaying(void);
// MediaRemote tells us right away when the song or play state changes.
static void RegisterNowPlayingNotifications(void) {
    if (!MediaRemote()) return;
    void (*reg)(dispatch_queue_t) = (void (*)(dispatch_queue_t))dlsym(MediaRemote(), "MRMediaRemoteRegisterForNowPlayingNotifications");
    if (reg) reg(dispatch_get_main_queue());
    NSArray *names = @[
        MRConst("kMRMediaRemoteNowPlayingInfoDidChangeNotification", @"kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
        MRConst("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification", @"kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
        MRConst("kMRMediaRemoteNowPlayingApplicationDidChangeNotification", @"kMRMediaRemoteNowPlayingApplicationDidChangeNotification"),
    ];
    for (NSString *n in names)
        [[NSNotificationCenter defaultCenter] addObserverForName:n object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if (!gTimer) return;          // Control Center isn't open
            gLastFetch = 0;               // skip the once-a-second throttle
            FetchNowPlaying();
        }];
}

static void FetchNowPlaying(void) {
    static MRGetInfoFn getInfo;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) getInfo = (MRGetInfoFn)dlsym(h, "MRMediaRemoteGetNowPlayingInfo");
    });
    CFTimeInterval now = CACurrentMediaTime();
    if (!getInfo || now - gLastFetch < 0.9) return;
    gLastFetch = now;
    FetchIsPlaying();
    FetchAppAndCommands();
    getInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
        NSDictionary *d = (__bridge NSDictionary *)info;
        NSString *title = d[@"kMRMediaRemoteNowPlayingInfoTitle"];
        NSString *artist = d[@"kMRMediaRemoteNowPlayingInfoArtist"];
        NSData *data = d[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
        gNPTitle = [title isKindOfClass:[NSString class]] && title.length ? title : nil;
        gNPArtist = [artist isKindOfClass:[NSString class]] ? artist : nil;
        id liked = d[@"kMRMediaRemoteNowPlayingInfoIsLiked"];
        if ([liked respondsToSelector:@selector(boolValue)]) gNPLiked = @([liked boolValue]);
        if (gDebug) {
            NSMutableArray *k = [NSMutableArray array];
            for (NSString *key in d) {
                NSString *lk = key.lowercaseString;
                if ([lk containsString:@"like"] || [lk containsString:@"love"] || [lk containsString:@"favor"] ||
                    [lk containsString:@"rating"] || [lk containsString:@"wish"] || [lk containsString:@"library"])
                    [k addObject:[NSString stringWithFormat:@"%@=%@", [key stringByReplacingOccurrencesOfString:@"kMRMediaRemoteNowPlayingInfo" withString:@""], d[key]]];
            }
            if (k.count) gCmdDebug = [gCmdDebug stringByAppendingFormat:@" keys:%@", [k componentsJoinedByString:@","]];
        }
        if (!gNPTitle) { gArtwork = nil; gArtworkData = nil; }
        else if ([data isKindOfClass:[NSData class]] && data.length && ![data isEqualToData:gArtworkData]) {
            gArtworkData = data;
            gArtwork = [UIImage imageWithData:data];
        }
        if (gTimer) { @try { Tick(); } @catch (__unused id e) {} }
    });
}

static void CollectViews(UIView *v, int depth, Class cls, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (s.tag == OVERLAY_TAG) continue;
        if ([s isKindOfClass:cls]) [out addObject:s];
        if (depth < 10) CollectViews(s, depth + 1, cls, out);
    }
}

// Everything Apple draws in the module's top-right corner (the small AirPlay
// icon and its label). 0.1.1 only found MPRouteLabel, so the icon stayed.
// The module's container: the highest ancestor that's still about the module's size.
static UIView *ModuleContainer(UIView *module) {
    UIView *best = module, *p = module.superview;
    for (int d = 0; p && d < 5; d++, p = p.superview) {
        if (p.bounds.size.width <= module.bounds.size.width + 40 && p.bounds.size.height <= module.bounds.size.height + 40) best = p;
        else break;
    }
    return best;
}

// Everything Apple draws in the top-right corner of the music module: the
// small AirPlay icon may belong to the module's container, not the module.
static NSArray *TopRightViews(UIView *module) {
    UIView *root = ModuleContainer(module);
    NSMutableArray *all = [NSMutableArray array], *out = [NSMutableArray array];
    CollectViews(root, 0, [UIView class], all);
    CGSize S = module.bounds.size;
    UIView *overlay = [module viewWithTag:OVERLAY_TAG];
    for (UIView *v in all) {
        if (v == module || [module isDescendantOfView:v]) continue;       // containers of the module
        if (overlay && [v isDescendantOfView:overlay]) continue;          // ours
        if (v.bounds.size.width < 4 || v.bounds.size.width > S.width * 0.4 || v.bounds.size.height > S.height * 0.4) continue;
        CGRect r = [v convertRect:v.bounds toView:module];
        NSString *n = NSStringFromClass([v class]);
        BOOL corner = CGRectGetMidX(r) > S.width * 0.66 && CGRectGetMidY(r) < S.height * 0.34;
        BOOL routey = [n containsString:@"Route"] || [n containsString:@"Routing"] || [v.accessibilityLabel.lowercaseString containsString:@"airplay"];
        if (corner || routey) [out addObject:v];
    }
    return out;
}

// Apple's previous / play / next: the three visible buttons in the bottom row.
static NSArray *FindTransport(UIView *module) {
    NSMutableArray *ctls = [NSMutableArray array];
    CollectViews(module, 0, [UIControl class], ctls);
    CGSize S = module.bounds.size;
    NSMutableArray *row = [NSMutableArray array];
    for (UIControl *c in ctls) {
        if (c.hidden || (c.alpha < 0.01 && !objc_getAssociatedObject(c, kHidByUs)) || c.bounds.size.width < 16) continue; // ours stay findable
        if ([c isKindOfClass:[UISlider class]]) continue;
        NSString *cn = NSStringFromClass([c class]);
        if ([cn containsString:@"Route"] || [cn containsString:@"Routing"] || [c.accessibilityLabel.lowercaseString containsString:@"airplay"]) continue;
        CGPoint p = [c.superview convertPoint:c.center toView:module];
        if (p.y < S.height * 0.45 || CGRectGetMidX([c convertRect:c.bounds toView:module]) > S.width) continue;
        // Skip containers that hold other controls.
        BOOL container = NO;
        for (UIControl *o in ctls) if (o != c && [o isDescendantOfView:c]) { container = YES; break; }
        if (!container) [row addObject:c];
    }
    if (row.count < 3) return nil;
    // Keep the controls on the most common row (same height ±12pt).
    NSMutableArray *best = nil;
    for (UIControl *a in row) {
        CGFloat ya = [a.superview convertPoint:a.center toView:module].y;
        NSMutableArray *same = [NSMutableArray array];
        for (UIControl *b in row) if (fabs([b.superview convertPoint:b.center toView:module].y - ya) < 12) [same addObject:b];
        if (same.count > best.count) best = same;
    }
    [best sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = [a.superview convertPoint:a.center toView:module].x, y = [b.superview convertPoint:b.center toView:module].x;
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    if (best.count < 3) return nil;
    NSUInteger mid = best.count / 2;
    return @[best[mid - 1], best[mid], best[mid + 1]];
}

static const void *kOurTransform = &kOurTransform;
__attribute__((unused)) static void SetOurTransform(UIView *v, CGAffineTransform t) {
    NSValue *last = objc_getAssociatedObject(v, kOurTransform);
    BOOL ours = CGAffineTransformIsIdentity(v.transform) || (last && CGAffineTransformEqualToTransform(v.transform, last.CGAffineTransformValue));
    if (!ours) return; // Apple is animating it; leave it alone
    if (!CGAffineTransformEqualToTransform(v.transform, t)) v.transform = t;
    objc_setAssociatedObject(v, kOurTransform, [NSValue valueWithCGAffineTransform:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void ClearOurTransform(UIView *v) {
    NSValue *last = objc_getAssociatedObject(v, kOurTransform);
    if (last && CGAffineTransformEqualToTransform(v.transform, last.CGAffineTransformValue)) v.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(v, kOurTransform, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - spring physics (runs every screen refresh while something moves)

@interface C26Spring : NSObject
@property (nonatomic, weak) UIView *view;
@property (nonatomic) CGFloat x, y, sx, sy, vx, vy, vsx, vsy;  // current + velocity
@property (nonatomic) CGFloat tx, ty, tsx, tsy;                // targets
@property (nonatomic) CGFloat angle;                           // stretch axis
@property (nonatomic) CGFloat k, c;                            // stiffness, damping
@end
@implementation C26Spring
- (instancetype)init { if ((self = [super init])) { _sx = _sy = _tsx = _tsy = 1; _k = 320; _c = 24; } return self; }
- (BOOL)settled {
    return fabs(_x - _tx) < 0.02 && fabs(_y - _ty) < 0.02 && fabs(_sx - _tsx) < 0.0005 && fabs(_sy - _tsy) < 0.0005 &&
           fabs(_vx) < 0.05 && fabs(_vy) < 0.05 && fabs(_vsx) < 0.002 && fabs(_vsy) < 0.002;
}
- (void)step:(CGFloat)dt {
    int n = 4; CGFloat h = dt / n;
    for (int i = 0; i < n; i++) {
        _vx += (-_k * (_x - _tx) - _c * _vx) * h;   _x += _vx * h;
        _vy += (-_k * (_y - _ty) - _c * _vy) * h;   _y += _vy * h;
        _vsx += (-_k * (_sx - _tsx) - _c * _vsx) * h; _sx += _vsx * h;
        _vsy += (-_k * (_sy - _tsy) - _c * _vsy) * h; _sy += _vsy * h;
    }
}
- (CGAffineTransform)transform {
    CGAffineTransform t = CGAffineTransformMakeTranslation(_x, _y);
    t = CGAffineTransformRotate(t, _angle);
    t = CGAffineTransformScale(t, _sx, _sy);
    return CGAffineTransformRotate(t, -_angle);
}
@end

static const void *kSpring = &kSpring;
static NSHashTable *gActiveSprings;
static CADisplayLink *gSpringLink;

@interface C26SpringTicker : NSObject
+ (instancetype)shared;
@end
@implementation C26SpringTicker
+ (instancetype)shared { static C26SpringTicker *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26SpringTicker new]; }); return t; }
- (void)step:(CADisplayLink *)link {
    CGFloat dt = link.targetTimestamp - link.timestamp;
    if (dt <= 0 || dt > 0.05) dt = 1.0 / 120.0;
    for (C26Spring *s in [gActiveSprings allObjects]) {
        UIView *v = s.view;
        if (!v) { [gActiveSprings removeObject:s]; continue; }
        [s step:dt];
        if ([s settled]) {
            s.x = s.tx; s.y = s.ty; s.sx = s.tsx; s.sy = s.tsy; s.vx = s.vy = s.vsx = s.vsy = 0;
            [gActiveSprings removeObject:s];
        }
        v.transform = [s transform];
    }
    if (!gActiveSprings.count) { [gSpringLink invalidate]; gSpringLink = nil; }
}
@end

static C26Spring *SpringFor(UIView *v) {
    C26Spring *s = objc_getAssociatedObject(v, kSpring);
    if (!s) { s = [C26Spring new]; s.view = v; objc_setAssociatedObject(v, kSpring, s, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    return s;
}

static void WakeSpring(C26Spring *s) {
    if (!gActiveSprings) gActiveSprings = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
    [gActiveSprings addObject:s];
    if (!gSpringLink) {
        gSpringLink = [CADisplayLink displayLinkWithTarget:[C26SpringTicker shared] selector:@selector(step:)];
        if (@available(iOS 15.0, *)) gSpringLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
        [gSpringLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}


@interface C26Transport : NSObject
+ (instancetype)shared;
@end
@implementation C26Transport
+ (instancetype)shared { static C26Transport *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26Transport new]; }); return t; }
- (void)down:(UIButton *)b {
    // Press: sink quickly.
    C26Spring *s = SpringFor(b);
    s.k = 700; s.c = 40; s.tsx = s.tsy = 0.84; s.tx = s.ty = 0; s.angle = 0;
    WakeSpring(s);
    [UIView animateWithDuration:0.12 animations:^{ b.alpha = 0.75; }];
}
- (void)up:(UIButton *)b {
    // Release: pop past full size and settle.
    C26Spring *s = SpringFor(b);
    s.k = 320; s.c = 13; s.tsx = s.tsy = 1; s.tx = s.ty = 0;
    s.vsx += 2.4; s.vsy += 2.4;
    WakeSpring(s);
    [UIView animateWithDuration:0.2 animations:^{ b.alpha = 1; }];
}
// Next / previous: the arrows fling in the skip direction and spring home,
// leaving a ghost that keeps going and fades.
- (void)swoosh:(UIButton *)b dir:(CGFloat)dir {
    UIImageView *iv = b.imageView;
    if (iv.image) {
        UIImageView *ghost = [[UIImageView alloc] initWithImage:iv.image];
        ghost.tintColor = b.tintColor;
        ghost.frame = iv.frame;
        ghost.alpha = 0.55;
        ghost.userInteractionEnabled = NO;
        [b addSubview:ghost];
        [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            ghost.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(24 * dir, 0), 1.15, 0.9);
            ghost.alpha = 0;
        } completion:^(BOOL d) { [ghost removeFromSuperview]; }];
    }
    C26Spring *s = SpringFor(iv);
    s.k = 420; s.c = 16; s.tx = s.ty = 0; s.tsx = s.tsy = 1; s.angle = 0;
    s.vx += 520 * dir;           // fling
    s.vsx += 1.4; s.vsy -= 0.7;  // stretch along the fling
    WakeSpring(s);
}
- (void)tap:(UIButton *)b {
    [self up:b];
    if (b.tag == 6) { gSkipDir = -1; [self swoosh:b dir:-1]; SendMR(5); }
    else if (b.tag == 8) { gSkipDir = 1; [self swoosh:b dir:1]; SendMR(4); }
    else {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        SendMR(2);
        gIsPlaying = !gIsPlaying;
        // Play <-> pause morph: shrink, swap, spring back.
        NSString *sym = gIsPlaying ? @"pause.fill" : @"play.fill";
        objc_setAssociatedObject(b, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightSemibold]];
        [b setImage:img forState:UIControlStateNormal];
        // Morph: the new icon grows out of a dot with a springy overshoot.
        C26Spring *s = SpringFor(b.imageView);
        s.sx = s.sy = 0.2; s.vsx = s.vsy = 0;
        s.k = 380; s.c = 14; s.tsx = s.tsy = 1; s.tx = s.ty = 0; s.angle = 0;
        WakeSpring(s);
    }
    // Pick up the new song / state right away.
    for (NSNumber *delay in @[@0.12, @0.35, @0.8]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gLastFetch = 0; FetchNowPlaying(); });
    }
}
@end

static C26PassView *BuildOverlay(UIView *module) {
    C26PassView *o = [C26PassView new];
    o.tag = OVERLAY_TAG;

    UIImageView *art = [UIImageView new];
    art.tag = 1;
    art.contentMode = UIViewContentModeScaleAspectFill;
    art.clipsToBounds = YES;
    art.layer.cornerCurve = kCACornerCurveContinuous;
    art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14];
    [o addSubview:art];

    UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    glass.tag = 2;
    glass.clipsToBounds = YES;
    glass.layer.cornerCurve = kCACornerCurveContinuous;
    glass.userInteractionEnabled = NO;
    [o addSubview:glass];

    // Apple's own AirPlay picker button: tapping it opens the real AirPlay menu.
    AVRoutePickerView *air = [AVRoutePickerView new];
    air.tag = 3;
    air.tintColor = UIColor.whiteColor;
    air.activeTintColor = [UIColor colorWithRed:0.25 green:0.55 blue:1 alpha:1];
    air.prioritizesVideoDevices = NO;
    [o addSubview:air];

    UILabel *title = [UILabel new];
    title.tag = 4;
    title.textColor = UIColor.whiteColor;
    title.lineBreakMode = NSLineBreakByTruncatingTail;
    [o addSubview:title];

    UILabel *artist = [UILabel new];
    artist.tag = 5;
    artist.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    artist.lineBreakMode = NSLineBreakByTruncatingTail;
    [o addSubview:artist];

    // Our previous / play / next (iOS 26 placement).
    NSArray *syms = @[@"backward.fill", @"play.fill", @"forward.fill"];
    for (int i = 0; i < 3; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = 6 + i;
        b.tintColor = UIColor.whiteColor;
        [b setImage:[UIImage systemImageNamed:syms[i] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:(i == 1 ? 30 : 22) weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
        [b addTarget:[C26Transport shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [b addTarget:[C26Transport shared] action:@selector(down:) forControlEvents:UIControlEventTouchDown];
        [b addTarget:[C26Transport shared] action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [o addSubview:b];
    }

    [module addSubview:o];
    return o;
}

static void SetFrame(UIView *v, CGRect f) { if (!CGRectEqualToRect(v.frame, f)) v.frame = f; }

static void CrossfadeText(UILabel *l, NSString *text) {
    if ([l.text isEqualToString:text ?: @""]) return;
    [UIView transitionWithView:l duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ l.text = text ?: @""; } completion:nil];
}

static void RemoveOverlays(UIView *module) {
    for (NSNumber *tag in @[@(OVERLAY_TAG), @(EXP_TAG)]) {
        UIView *o = [module viewWithTag:tag.integerValue];
        if (o.superview == module) [o removeFromSuperview];
    }
}

static void UnstyleModule(UIView *module) {
    RemoveOverlays(module);
    RestoreMusic();
    for (UIView *b in FindTransport(module)) { ClearOurTransform(b); ClearOurTransform(b.superview); ClearOurTransform(b.superview.superview); }
}

static const void *kMode = &kMode;
// Small <-> expanded: put back everything the other mode changed first.
static void SwitchMode(UIView *module, NSString *mode) {
    if ([objc_getAssociatedObject(module, kMode) isEqualToString:mode]) return;
    UnstyleModule(module);
    objc_setAssociatedObject(module, kMode, mode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - expanded player (iOS 26 style)

@interface C26Expanded : NSObject
+ (instancetype)shared;
@end
@implementation C26Expanded
+ (instancetype)shared { static C26Expanded *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26Expanded new]; }); return t; }
- (void)airplay:(UIButton *)b {
    // Press the AirPlay picker's own button (the whole capsule is tappable).
    UIView *picker = [b.superview viewWithTag:22];
    NSMutableArray *btns = [NSMutableArray array];
    CollectViews(picker, 0, [UIButton class], btns);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [(UIButton *)btns.firstObject sendActionsForControlEvents:UIControlEventTouchUpInside];
}
- (void)star:(UIButton *)b {
    if (!gNPTitle) return;
    BOOL loved = gNPLiked ? gNPLiked.boolValue : [gLikedLocally isEqualToString:gNPTitle];
    SendLove(!loved);
    gNPLiked = @(!loved);
    gLikedLocally = loved ? nil : gNPTitle;
    NSString *sym = loved ? @"star" : @"star.fill";
    objc_setAssociatedObject(b, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    // Confirm with Music shortly after.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gLastFetch = 0; FetchNowPlaying(); });

    if (loved) {
        // Un-love: a small deflate.
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        b.transform = CGAffineTransformMakeScale(0.75, 0.75);
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:2 options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
        return;
    }
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];

    // Squish, then pop back with a spring.
    b.transform = CGAffineTransformMakeScale(0.55, 0.55);
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.42 initialSpringVelocity:10
                        options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];

    // Burst of little stars and sparkles flying out.
    UIView *host = b.superview;
    CGPoint c = b.center;
    for (int i = 0; i < 10; i++) {
        UIImageView *p = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:(i % 2 ? @"star.fill" : @"sparkle")
                                                             withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:(i % 3 ? 9 : 12) weight:UIImageSymbolWeightBold]]];
        p.tintColor = i % 3 ? UIColor.whiteColor : [UIColor colorWithRed:1 green:0.86 blue:0.35 alpha:1];
        p.center = c;
        p.userInteractionEnabled = NO;
        p.transform = CGAffineTransformMakeScale(0.2, 0.2);
        [host addSubview:p];
        CGFloat ang = i * (M_PI * 2 / 10) + (i % 2 ? 0.2 : -0.1);
        CGFloat dist = 30 + (i % 3) * 9;
        [UIView animateWithDuration:0.6 delay:0.03 * (i % 3) options:UIViewAnimationOptionCurveEaseOut animations:^{
            p.center = CGPointMake(c.x + cos(ang) * dist, c.y + sin(ang) * dist);
            p.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(1.0, 1.0), ang);
        } completion:nil];
        [UIView animateWithDuration:0.35 delay:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            p.alpha = 0;
            p.transform = CGAffineTransformMakeScale(0.3, 0.3);
        } completion:^(BOOL d) { [p removeFromSuperview]; }];
    }
}
@end

static C26PassView *BuildExpandedOverlay(UIView *module) {
    C26PassView *o = [C26PassView new];
    o.tag = EXP_TAG;

    UIVisualEffectView *cap = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    cap.tag = 21;
    cap.clipsToBounds = YES;
    cap.layer.cornerCurve = kCACornerCurveContinuous;
    [o addSubview:cap];

    AVRoutePickerView *picker = [AVRoutePickerView new];
    picker.tag = 22;
    picker.tintColor = UIColor.whiteColor;
    picker.activeTintColor = [UIColor colorWithRed:0.25 green:0.55 blue:1 alpha:1];
    picker.prioritizesVideoDevices = NO;
    picker.userInteractionEnabled = NO;   // the capsule button below handles taps
    [cap.contentView addSubview:picker];

    UILabel *l = [UILabel new];
    l.tag = 23;
    l.text = @"AirPlay";
    l.textColor = UIColor.whiteColor;
    l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [cap.contentView addSubview:l];

    UIButton *tap = [UIButton buttonWithType:UIButtonTypeCustom];
    tap.tag = 25;
    [tap addTarget:[C26Expanded shared] action:@selector(airplay:) forControlEvents:UIControlEventTouchUpInside];
    [cap.contentView addSubview:tap];

    UIButton *star = [UIButton buttonWithType:UIButtonTypeCustom];
    star.tag = 24;
    star.tintColor = [UIColor colorWithWhite:1 alpha:0.85];
    [star addTarget:[C26Expanded shared] action:@selector(star:) forControlEvents:UIControlEventTouchUpInside];
    [o addSubview:star];

    [module addSubview:o];
    return o;
}

static void StyleExpanded(UIView *module) {
    SwitchMode(module, @"expanded");
    if (!gEnabled || !gMusic) { UnstyleModule(module); return; }
    FetchNowPlaying();
    CGSize S = module.bounds.size;

    C26PassView *o = (C26PassView *)[module viewWithTag:EXP_TAG];
    if (o.superview != module) o = BuildExpandedOverlay(module);
    [module bringSubviewToFront:o];
    SetFrame(o, module.bounds);

    // Hide Apple's AirPlay icons (header and row) and the route name ("iPhone").
    NSMutableArray *all = [NSMutableArray array];
    CollectViews(module, 0, [UIView class], all);
    UIView *volume = nil;
    for (UIView *v in all) {
        if ([v isDescendantOfView:o]) continue;
        NSString *n = NSStringFromClass([v class]);
        if ([n containsString:@"Route"] || [n containsString:@"Routing"] || [v.accessibilityLabel.lowercaseString containsString:@"airplay"]) {
            if (v.bounds.size.width < S.width * 0.6) HideMusic(v);
            continue;
        }
        // Lowest wide slider = volume.
        if ([n containsString:@"Slider"] && v.bounds.size.width > S.width * 0.5 && !v.hidden) {
            CGRect r = [v convertRect:v.bounds toView:module];
            if (!volume || CGRectGetMidY(r) > CGRectGetMidY([volume convertRect:volume.bounds toView:module])) volume = v;
        }
    }

    // "AirPlay" capsule centered under the volume slider.
    UIView *cap = [o viewWithTag:21];
    if (volume) {
        CGRect vr = [volume convertRect:volume.bounds toView:module];
        // Small, and tucked right under the slider so it stays clear of
        // anything another tweak draws further down.
        CGFloat w = 84, h = 28;
        CGFloat y = MIN(round(CGRectGetMaxY(vr) + 8), S.height - h - 6);
        SetFrame(cap, CGRectMake(round(S.width / 2 - w / 2), y, w, h));
        cap.layer.cornerRadius = h / 2;
        SetFrame([cap viewWithTag:22], CGRectMake(9, (h - 15) / 2, 15, 15));
        SetFrame([cap viewWithTag:23], CGRectMake(28, 0, w - 33, h));
        SetFrame([cap viewWithTag:25], CGRectMake(0, 0, w, h));
        cap.hidden = NO;
    } else cap.hidden = YES;

    // Star left of the previous button, same spacing as the row.
    UIButton *star = (UIButton *)[o viewWithTag:24];
    NSArray *tr = FindTransport(module);
    if (tr.count >= 2) {
        UIView *a = tr[0], *b = tr[1];
        CGPoint pa = [a.superview convertPoint:a.center toView:module], pb = [b.superview convertPoint:b.center toView:module];
        CGFloat gap = MAX(pb.x - pa.x, 44), d = 44;
        SetFrame(star, CGRectMake(round(pa.x - gap - d / 2), round(pa.y - d / 2), d, d));
        // Favorites are an Apple Music thing: no star for Spotify and others.
        star.hidden = ![gNPApp isEqualToString:@"com.apple.Music"];
    } else star.hidden = YES;
    BOOL liked = gNPLiked ? gNPLiked.boolValue : (gNPTitle && [gLikedLocally isEqualToString:gNPTitle]);
    NSString *sym = liked ? @"star.fill" : @"star";
    if (![objc_getAssociatedObject(star, kLastValue) isEqual:sym]) {
        objc_setAssociatedObject(star, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [star setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    }
    gMusicDebug = [NSString stringWithFormat:@"expanded %.0fx%.0f volume=%@ transport=%lu liked=%@",
                   S.width, S.height, volume ? NSStringFromClass([volume class]) : @"none", (unsigned long)tr.count, gNPLiked ?: @"?"];
}

static void StyleModule(UIView *module) {
    CGSize S = module.bounds.size;
    // Compact (square) module only; the expanded one is left alone.
    if (S.width < 120 || S.width > 240 || fabs(S.width - S.height) > 40) { StyleExpanded(module); return; }
    SwitchMode(module, @"compact");
    if (!gEnabled || !gMusic) { UnstyleModule(module); return; }

    FetchNowPlaying();

    C26PassView *o = (C26PassView *)[module viewWithTag:OVERLAY_TAG];
    if (o.superview != module) o = BuildOverlay(module);
    [module bringSubviewToFront:o];
    SetFrame(o, module.bounds);

    CGFloat s = S.width / 163.0, m = 14 * s;
    UIImageView *art = (UIImageView *)[o viewWithTag:1];
    UIView *glass = [o viewWithTag:2];
    UIView *air = [o viewWithTag:3];
    UILabel *title = (UILabel *)[o viewWithTag:4], *artist = (UILabel *)[o viewWithTag:5];

    CGFloat a = round(56 * s), d = round(42 * s);
    SetFrame(art, CGRectMake(m, m, a, a));
    art.layer.cornerRadius = 12 * s;
    SetFrame(glass, CGRectMake(S.width - m - d, m, d, d));
    SetFrame(air, CGRectInset(glass.frame, round(10 * s), round(10 * s)));
    glass.layer.cornerRadius = d / 2;
    air.hidden = glass.hidden = NO;

    UIFont *tf = [UIFont systemFontOfSize:16 * s weight:UIFontWeightSemibold];
    UIFont *af = [UIFont systemFontOfSize:16 * s weight:UIFontWeightRegular];
    if (![title.font isEqual:tf]) title.font = tf;
    if (![artist.font isEqual:af]) artist.font = af;

    BOOL playing = gNPTitle != nil;
    CGFloat ty = playing ? m + a + 7 * s : m + a + 16 * s;
    SetFrame(title, CGRectMake(m + 2 * s, ty, S.width - 2 * m, ceil(tf.lineHeight)));
    SetFrame(artist, CGRectMake(m + 2 * s, ty + ceil(tf.lineHeight), S.width - 2 * m, ceil(af.lineHeight)));
    CrossfadeText(title, playing ? gNPTitle : @"Not Playing");
    CrossfadeText(artist, playing ? gNPArtist : @"");
    artist.hidden = !playing;

    // Artwork when playing; an empty gray square when not (like iOS 26).
    UIImage *img = playing ? gArtwork : nil;
    if (art.image != img) {
        if (gSkipDir && img) {
            CATransition *tr2 = [CATransition animation];
            tr2.type = kCATransitionPush;
            tr2.subtype = gSkipDir > 0 ? kCATransitionFromRight : kCATransitionFromLeft;
            tr2.duration = 0.32;
            tr2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.3 :1.0];
            [art.layer addAnimation:tr2 forKey:@"c26.skip"];
            art.image = img;
            gSkipDir = 0;
        } else {
            [UIView transitionWithView:art duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{ art.image = img; } completion:nil];
        }
    }

    // Our previous / play / next: tight, centered, low (like iOS 26).
    CGFloat ty2 = round(S.height * 0.84), bw = round(42 * s);
    for (int i = 0; i < 3; i++) {
        UIButton *b = (UIButton *)[o viewWithTag:6 + i];
        CGFloat cx = S.width / 2 + (i - 1) * 46 * s;
        SetFrame(b, CGRectMake(round(cx - bw / 2), ty2 - bw / 2, bw, bw));
    }
    UIButton *pp = (UIButton *)[o viewWithTag:7];
    NSString *ppSym = gIsPlaying ? @"pause.fill" : @"play.fill";
    if (![objc_getAssociatedObject(pp, kLastValue) isEqual:ppSym]) {
        objc_setAssociatedObject(pp, kLastValue, ppSym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImage *img = [UIImage systemImageNamed:ppSym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightSemibold]];
        [UIView transitionWithView:pp duration:0.18 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                        animations:^{ [pp setImage:img forState:UIControlStateNormal]; } completion:nil];
    }
    // Apple's own row is hidden (it scales/positions itself, so it can't be moved).
    NSArray *tr = FindTransport(module);
    for (UIView *b in tr) HideMusic(b);

    // Hide Apple's labels and small AirPlay icon (ours replace them).
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(module, 0, [UILabel class], labels);
    for (UILabel *l in labels) {
        CGRect r = [l convertRect:l.bounds toView:module];
        if (CGRectGetMidY(r) < S.height * 0.75) HideMusic(l);
    }
    NSArray *corner = TopRightViews(module);
    for (UIView *v in corner) HideMusic(v);
    NSMutableArray *cornerNames = [NSMutableArray array];
    for (UIView *v in corner) [cornerNames addObject:NSStringFromClass([v class])];
    gMusicDebug = [NSString stringWithFormat:@"%@ %.0fx%.0f corner=%lu hidden-transport=%lu playing=%d np=%@ art=%d",
                   NSStringFromClass([module class]), S.width, S.height,
                   (unsigned long)cornerNames.count, (unsigned long)tr.count, gIsPlaying,
                   gNPTitle ?: @"(none)", gArtwork != nil];
}

#pragma mark - sliders: colored icons + bounce

// 1 brightness, 2 volume, 0 unknown
static int SliderKind(UIView *slider) {
    NSMutableString *names = [NSMutableString stringWithString:NSStringFromClass([slider class])];
    UIViewController *vc = OwnerVC(slider);
    for (int i = 0; vc && i < 4; i++) { [names appendFormat:@" %@", NSStringFromClass([vc class])]; vc = vc.parentViewController; }
    NSString *n = names.lowercaseString;
    if ([n containsString:@"brightness"] || [n containsString:@"display"]) return 1;
    if ([n containsString:@"volume"] || [n containsString:@"audio"] || [n hasPrefix:@"mru"]) return 2;
    return 0;
}

static float SliderValue(UIView *slider) {
    id v = KV(slider, @"value");
    return [v respondsToSelector:@selector(floatValue)] ? [v floatValue] : -1;
}

static UIView *AppleGlyph(UIView *slider) {
    for (NSString *k in @[@"glyphPackageView", @"glyphImageView", @"glyphView", @"iconView"]) {
        id g = KV(slider, k);
        if ([g isKindOfClass:[UIView class]] && !((UIView *)g).hidden) return g;
    }
    return nil;
}

// Every glyph Apple draws in the slider. There are two (a white one over the
// dark part and a gray one over the white fill), which is why 0.1.1 still
// showed a gray icon behind ours.
static NSArray *AllAppleGlyphs(UIView *slider) {
    NSMutableArray *all = [NSMutableArray array], *out = [NSMutableArray array];
    CollectViews(slider, 0, [UIView class], all);
    for (UIView *v in all) {
        if (v.tag == GLYPH_TAG) continue;
        NSString *n = NSStringFromClass([v class]);
        BOOL glyphish = [n containsString:@"CAPackage"] || [n containsString:@"Glyph"] ||
                        ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image);
        if (glyphish && v.bounds.size.width <= 80 && v.bounds.size.height <= 80) [out addObject:v];
    }
    return out;
}

static NSString *GlyphSymbol(int kind, float v) {
    if (kind == 1) return v < 0.5 ? @"sun.min.fill" : @"sun.max.fill";
    if (v <= 0.001) return @"speaker.slash.fill";
    if (v < 0.34) return @"speaker.wave.1.fill";
    if (v < 0.67) return @"speaker.wave.2.fill";
    return @"speaker.wave.3.fill";
}

static void StyleSlider(UIView *slider) {
    int kind = SliderKind(slider);
    UIView *apple = AppleGlyph(slider);
    UIImageView *mine = (UIImageView *)[slider viewWithTag:GLYPH_TAG];
    if (mine.superview != slider) mine = nil;
    if (!gEnabled || !gColors || !kind || !apple) {
        [mine removeFromSuperview];
        for (UIView *g in AllAppleGlyphs(slider)) ShowOriginal(g);
        return;
    }
    if (!mine) {
        mine = [UIImageView new];
        mine.tag = GLYPH_TAG;
        mine.contentMode = UIViewContentModeCenter;
        mine.userInteractionEnabled = NO;
        [slider addSubview:mine];
    }
    [slider bringSubviewToFront:mine];
    CGRect gr = [apple convertRect:apple.bounds toView:slider];
    CGFloat side = MAX(MAX(gr.size.width, gr.size.height), 30);
    SetFrame(mine, CGRectMake(CGRectGetMidX(gr) - side / 2, CGRectGetMidY(gr) - side / 2, side, side));
    float v = SliderValue(slider);
    NSString *sym = GlyphSymbol(kind, v < 0 ? 0.5 : v);
    if (![objc_getAssociatedObject(mine, kLastValue) isEqual:sym]) {
        UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightSemibold]];
        BOOL first = objc_getAssociatedObject(mine, kLastValue) == nil;
        objc_setAssociatedObject(mine, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (first) mine.image = img;
        else [UIView transitionWithView:mine duration:0.18 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                             animations:^{ mine.image = img; } completion:nil];
    }
    // Like iOS 26: colored when the white fill covers the icon, white when it doesn't.
    CGFloat fillTop = slider.bounds.size.height * (1.0 - MAX(0, MIN(1, v)));
    BOOL covered = CGRectGetMidY(mine.frame) >= fillTop;
    UIColor *c = covered ? (kind == 1 ? SUN_COLOR : VOLUME_COLOR) : UIColor.whiteColor;
    if (![mine.tintColor isEqual:c])
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ mine.tintColor = c; } completion:nil];
    for (UIView *g in AllAppleGlyphs(slider)) HideOriginal(g);
}

#pragma mark - direct brightness tracking + bounce

static const void *kDirect = &kDirect;      // @YES when we drive the slider ourselves
static const void *kStartValue = &kStartValue;
static const void *kApplePan = &kApplePan;

// Brightness: if the slider is a UIControl that reports value changes, turn
// off Apple's drag handler and track the finger ourselves, 1:1 on every
// touch update. Otherwise leave Apple's tracking alone.
static void SetupDirectTracking(UIView *slider) {
    if (objc_getAssociatedObject(slider, kDirect)) return;
    if (SliderKind(slider) != 1 || ![slider isKindOfClass:[UIControl class]]) return;
    if (!(((UIControl *)slider).allControlEvents & UIControlEventValueChanged)) return;
    if (SliderValue(slider) < 0) return;
    id applePan = KV(slider, @"valueChangeGestureRecognizer");
    if (![applePan isKindOfClass:[UIGestureRecognizer class]]) return;
    ((UIGestureRecognizer *)applePan).enabled = NO;
    objc_setAssociatedObject(slider, kApplePan, applePan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(slider, kDirect, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void TeardownDirectTracking(UIView *slider) {
    UIGestureRecognizer *applePan = objc_getAssociatedObject(slider, kApplePan);
    applePan.enabled = YES;
    objc_setAssociatedObject(slider, kDirect, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(slider, kApplePan, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Exact, instant value updates: no spring, no implicit animation, so the fill
// sits right under the finger on every touch update.
static void SetSliderValue(UIView *slider, float v) {
    __block BOOL ok = YES;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [UIView performWithoutAnimation:^{
        SEL animated = NSSelectorFromString(@"setValue:animated:");
        @try {
            if ([slider respondsToSelector:animated]) ((void (*)(id, SEL, float, BOOL))objc_msgSend)(slider, animated, v, NO);
            else [slider setValue:@(v) forKey:@"value"];
        } @catch (__unused id e) { ok = NO; }
        [slider layoutIfNeeded];
    }];
    [CATransaction commit];
    if (ok) [(UIControl *)slider sendActionsForControlEvents:UIControlEventValueChanged];
}

static void IconPop(UIView *v) {
    UIView *glyph = [v viewWithTag:GLYPH_TAG] ?: AppleGlyph(v);
    [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{ glyph.transform = CGAffineTransformMakeScale(1.18, 1.18); }
                     completion:^(BOOL done) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{ glyph.transform = CGAffineTransformIdentity; } completion:nil];
    }];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

// The slider's outer shell: the highest ancestor that's the same size as the
// slider, so the whole capsule stretches, not just the fill inside it.
static UIView *SliderShell(UIView *slider) {
    UIView *best = slider, *p = slider.superview;
    for (int d = 0; p && d < 6; d++, p = p.superview) {
        if (fabs(p.bounds.size.width - slider.bounds.size.width) <= 6 && fabs(p.bounds.size.height - slider.bounds.size.height) <= 6) best = p;
        else if (p.bounds.size.width > slider.bounds.size.width + 6 || p.bounds.size.height > slider.bounds.size.height + 6) break;
    }
    return best;
}

// Stretch for `over` points past an end (dir 1 = top, -1 = bottom), rubber-band style.
static void ApplyStretch(UIView *slider, CGFloat over, int dir) {
    UIView *v = SliderShell(slider);
    CGFloat H = v.bounds.size.height;
    if (H < 1) return;
    C26Spring *s = SpringFor(v);
    CGFloat stretch = (!gBounce || over <= 0) ? 0 : MIN((1.0 - 1.0 / (over * 0.5 / H + 1.0)) * H, H * 0.12);
    CGFloat r = stretch / H;
    // While the finger is down: a stiff, critically damped spring that follows it smoothly.
    s.k = 900; s.c = 60; s.angle = 0;
    s.tx = 0; s.ty = -dir * stretch / 2; s.tsx = 1.0 - r * 0.35; s.tsy = 1.0 + r;
    WakeSpring(s);
}

// Let go: a looser spring so it snaps back and wobbles, carrying the finger's speed.
static void ReleaseStretch(UIView *slider, CGFloat fingerVelocityY) {
    UIView *v = SliderShell(slider);
    C26Spring *s = objc_getAssociatedObject(v, kSpring);
    if (!s) return;
    // Rest: ease back to normal over about half a second, no bounce
    // (a critically damped spring, starting from a standstill).
    (void)fingerVelocityY;
    s.k = 95; s.c = 19.5;
    s.vx = s.vy = s.vsx = s.vsy = 0;
    s.tx = 0; s.ty = 0; s.tsx = 1; s.tsy = 1;
    WakeSpring(s);
}

@interface C26Bouncer : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26Bouncer
+ (instancetype)shared { static C26Bouncer *b; static dispatch_once_t o; dispatch_once(&o, ^{ b = [C26Bouncer new]; }); return b; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
    // When we drive the slider, we own the drag; otherwise ride along with Apple's.
    return objc_getAssociatedObject(a.view, kDirect) == nil;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)b {
    // Control Center's own scrolling waits for our slider drag.
    return objc_getAssociatedObject(a.view, kDirect) != nil && b.view != a.view && [a.view isDescendantOfView:b.view];
}
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    if (!v || !v.superview || !gEnabled) return;
    BOOL direct = objc_getAssociatedObject(v, kDirect) != nil;
    CGFloat H = v.bounds.size.height;
    if (H < 1) return;

    if (g.state == UIGestureRecognizerStateBegan) {
        objc_setAssociatedObject(v, kStartValue, @(SliderValue(v)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(v, kBounce, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        CGFloat over = 0; int dir = 0; float val;
        if (direct) {
            // 1:1: the fill moves exactly as far as the finger, every update.
            float v0 = [objc_getAssociatedObject(v, kStartValue) floatValue];
            float raw = v0 - [g translationInView:v].y / H;
            val = MAX(0, MIN(1, raw));
            if (fabsf(val - SliderValue(v)) > 0.0001) { SetSliderValue(v, val); StyleSlider(v); }
            if (raw > 1) { over = (raw - 1) * H; dir = 1; } else if (raw < 0) { over = -raw * H; dir = -1; }
        } else {
            CGFloat top = v.center.y - H / 2, bottom = v.center.y + H / 2;
            CGFloat y = [g locationInView:v.superview].y;
            if (y < top) { over = top - y; dir = 1; } else if (y > bottom) { over = y - bottom; dir = -1; }
            val = SliderValue(v);
        }
        ApplyStretch(v, over, dir);

        int edge = val >= 0.999 ? 1 : (val <= 0.001 && val >= 0 ? -1 : 0);
        NSNumber *last = objc_getAssociatedObject(v, kBounce);
        if (edge && last && last.intValue != edge) IconPop(v);
        objc_setAssociatedObject(v, kBounce, @(edge), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        objc_setAssociatedObject(v, kBounce, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (direct) SetSliderValue(v, MAX(0, MIN(1, SliderValue(v))));
        ReleaseStretch(v, [g velocityInView:v].y);
    }
}
@end

static const void *kPanAdded = &kPanAdded;
static void AddBounce(UIView *slider) {
    if (gEnabled) SetupDirectTracking(slider); else TeardownDirectTracking(slider);
    if (objc_getAssociatedObject(slider, kPanAdded)) return;
    objc_setAssociatedObject(slider, kPanAdded, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[C26Bouncer shared] action:@selector(pan:)];
    pan.delegate = [C26Bouncer shared];
    pan.cancelsTouchesInView = NO;
    pan.delaysTouchesBegan = NO;
    pan.delaysTouchesEnded = NO;
    [slider addGestureRecognizer:pan];
}

#pragma mark - jelly round buttons (iOS 26 liquid glass press)

static const void *kJelly = &kJelly;
static const void *kJellyStart = &kJellyStart;
static const void *kJellyLast = &kJellyLast;

@interface C26Jelly : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26Jelly
+ (instancetype)shared { static C26Jelly *j; static dispatch_once_t o; dispatch_once(&o, ^{ j = [C26Jelly new]; }); return j; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)press:(UILongPressGestureRecognizer *)g {
    UIView *v = g.view;
    if (!v || !v.superview) return;
    C26Spring *s = SpringFor(v);
    if (!gEnabled || !gJelly) { s.tx = s.ty = 0; s.tsx = s.tsy = 1; WakeSpring(s); return; }
    CGPoint p = [g locationInView:v.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        objc_setAssociatedObject(v, kJellyStart, [NSValue valueWithCGPoint:p], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // Press: swell like soft glass.
        s.k = 420; s.c = 24;
        s.tx = s.ty = 0; s.tsx = s.tsy = 1.08; s.angle = 0;
        WakeSpring(s);
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint st = [objc_getAssociatedObject(v, kJellyStart) CGPointValue];
        CGFloat dx = p.x - st.x, dy = p.y - st.y, dist = hypot(dx, dy);
        // Follow the finger with growing resistance (max ~12pt) and stretch along the drag.
        CGFloat damp = 0.16 / (1.0 + dist / 110.0);
        CGFloat stretch = MIN(dist / 380.0, 0.09);
        s.k = 650; s.c = 42;
        s.tx = dx * damp; s.ty = dy * damp;
        if (dist > 2) s.angle = atan2(dy, dx);
        s.tsx = 1.08 + stretch; s.tsy = 1.08 - stretch * 0.6;
        WakeSpring(s);
        objc_setAssociatedObject(v, kJellyLast, @[[NSValue valueWithCGPoint:p], @(CACurrentMediaTime())], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        // Let go: snap home and wobble, carrying the finger's last speed.
        NSArray *last = objc_getAssociatedObject(v, kJellyLast);
        if (last) {
            CGPoint lp = [last[0] CGPointValue];
            CGFloat dt = MAX(CACurrentMediaTime() - [last[1] doubleValue], 1.0 / 120.0);
            s.vx += MAX(-160, MIN(160, (p.x - lp.x) / dt * 0.12));
            s.vy += MAX(-160, MIN(160, (p.y - lp.y) / dt * 0.12));
        }
        objc_setAssociatedObject(v, kJellyLast, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        s.k = 300; s.c = 10;
        s.tx = s.ty = 0; s.tsx = s.tsy = 1;
        s.vsx += 0.6; s.vsy -= 0.6;   // a little squish so it jiggles
        WakeSpring(s);
    }
}
@end

static void AddJelly(UIView *v) {
    if (objc_getAssociatedObject(v, kJelly)) return;
    objc_setAssociatedObject(v, kJelly, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[C26Jelly shared] action:@selector(press:)];
    lp.minimumPressDuration = 0;
    lp.allowableMovement = CGFLOAT_MAX;
    lp.cancelsTouchesInView = NO;
    lp.delaysTouchesBegan = NO;
    lp.delaysTouchesEnded = NO;
    lp.delegate = [C26Jelly shared];
    [v addGestureRecognizer:lp];
}

#pragma mark - expanded connectivity (hold the Wi-Fi block)

static NSString *ConnTitle(UIView *b) {
    id t = KV(b, @"title");
    if ([t isKindOfClass:[NSString class]] && [t length]) return t;
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(b, 0, [UILabel class], labels);
    for (UILabel *l in labels) if (l.text.length) return l.text;
    return @"";
}

static UIView *RoundButtonIn(UIView *b) {
    id rb = KV(b, @"buttonView");
    if ([rb isKindOfClass:[UIView class]]) return rb;
    NSMutableArray *all = [NSMutableArray array];
    CollectViews(b, 0, [UIView class], all);
    for (UIView *v in all) if ([NSStringFromClass([v class]) containsString:@"RoundButton"]) return v;
    return nil;
}

#pragma mark - live signal bars

// Bars drawn by us: `active` lit, the rest dimmed.
@interface C26Bars : UIView
@property (nonatomic) int active, total;
@property (nonatomic, strong) UIColor *color;
@end
@implementation C26Bars
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) { _active = 4; _total = 4; _color = UIColor.whiteColor; self.userInteractionEnabled = NO; self.backgroundColor = UIColor.clearColor; }
    return self;
}
- (void)setActive:(int)a total:(int)n color:(UIColor *)c {
    if (n < 1) n = 4;
    if (a == _active && n == _total && [c isEqual:_color]) return;
    _active = a; _total = n; _color = c;
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    int n = _total;
    while ((int)self.layer.sublayers.count < n) [self.layer addSublayer:[CALayer layer]];
    while ((int)self.layer.sublayers.count > n) [self.layer.sublayers.lastObject removeFromSuperlayer];
    CGSize S = self.bounds.size;
    CGFloat gap = S.width * 0.1, w = (S.width - gap * (n - 1)) / n;
    for (int i = 0; i < n; i++) {
        CALayer *l = self.layer.sublayers[i];
        CGFloat h = MAX(w, S.height * (0.25 + 0.75 * i / (CGFloat)(n - 1 > 0 ? n - 1 : 1)));
        l.frame = CGRectMake(i * (w + gap), S.height - h, w, h);
        l.cornerRadius = w / 2;
        if (@available(iOS 13.0, *)) l.cornerCurve = kCACornerCurveCircular;
        l.backgroundColor = [_color colorWithAlphaComponent:(i < _active ? 1 : 0.32)].CGColor;
    }
}
@end

static __weak UIView *gSignalView;
static NSString *gBarsDebug = @"-";
static void FindSignalView(UIView *v, int d) {
    if (gSignalView || d > 30) return;
    if ([NSStringFromClass([v class]) containsString:@"CellularSignalView"] && v.window) { gSignalView = v; return; }
    for (UIView *s in v.subviews) FindSignalView(s, d + 1);
}
// Current cellular bars, from the status bar's own signal view.
static void SignalBars(int *active, int *total) {
    static CFTimeInterval last; static int a = 4, n = 4;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - last > 1.0) {
        last = now;
        UIView *sv = gSignalView;
        if (!sv || !sv.window) {
            gSignalView = nil;
            for (UIScene *sc in UIApplication.sharedApplication.connectedScenes)
                if ([sc isKindOfClass:[UIWindowScene class]]) for (UIWindow *w in ((UIWindowScene *)sc).windows) FindSignalView(w, 0);
            if (!gSignalView) for (UIWindow *w in UIApplication.sharedApplication.windows) FindSignalView(w, 0);
            sv = gSignalView;
        }
        id act = KV(sv, @"numberOfActiveBars"), tot = KV(sv, @"numberOfBars");
        NSString *src = @"statusbar";
        if (!act) {
            id tm = nil; Class c = NSClassFromString(@"SBTelephonyManager");
            if ([c respondsToSelector:@selector(sharedTelephonyManager)]) tm = [c performSelector:@selector(sharedTelephonyManager)];
            act = KV(tm, @"signalStrengthBars"); tot = KV(tm, @"maxSignalStrengthBars");
            src = @"telephony";
        }
        if ([act respondsToSelector:@selector(intValue)]) a = [act intValue]; else src = @"none";
        if ([tot respondsToSelector:@selector(intValue)] && [tot intValue] > 0) n = [tot intValue];
        if (a > n) a = n;
        gBarsDebug = [NSString stringWithFormat:@"%d/%d %@ %@", a, n, src, sv ? NSStringFromClass([sv class]) : @""];
    }
    *active = a; *total = n;
}

static void StyleConnButton(UIView *b) {
    NSString *title = ConnTitle(b);
    BOOL cellular = [title containsString:@"Cellular"] || [title containsString:@"Mobile"];
    UIView *round = RoundButtonIn(b);
    if (!round) return;
    C26Bars *bars = (C26Bars *)[round viewWithTag:CELL_TAG];
    if (bars.superview != round || ![bars isKindOfClass:[C26Bars class]]) { [bars removeFromSuperview]; bars = nil; }
    if (!gEnabled || !cellular) { [bars removeFromSuperview]; return; }

    NSMutableArray *all = [NSMutableArray array], *glyphs = [NSMutableArray array];
    CollectViews(round, 0, [UIView class], all);
    for (UIView *v in all) {
        if (v.tag == CELL_TAG || [v isKindOfClass:[C26Bars class]]) continue;
        NSString *n = NSStringFromClass([v class]);
        BOOL g = [n containsString:@"CAPackage"] || [n containsString:@"Glyph"] || ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image);
        if (g && v.bounds.size.width <= round.bounds.size.width * 0.8) [glyphs addObject:v];
    }
    if (!bars) {
        bars = [C26Bars new];
        bars.tag = CELL_TAG;
        [round addSubview:bars];
    }
    [round bringSubviewToFront:bars];
    CGFloat side = round.bounds.size.width, bw = side * 0.38, bh = side * 0.3;
    SetFrame(bars, CGRectMake((side - bw) / 2, (round.bounds.size.height - bh) / 2, bw, bh));
    int a, n; SignalBars(&a, &n);
    [bars setActive:a total:n color:UIColor.whiteColor];
    for (UIView *g in glyphs) HideOriginal(g);
}

#pragma mark - iOS 26 connectivity cards

static NSString *ConnKey(NSString *title) {
    if ([title containsString:@"Airplane"] || [title containsString:@"Aeroplane"]) return @"air";
    if ([title containsString:@"Wi-Fi"] || [title containsString:@"WLAN"]) return @"wifi";
    if ([title containsString:@"AirDrop"]) return @"airdrop";
    if ([title containsString:@"Cellular"] || [title containsString:@"Mobile"]) return @"cell";
    if ([title containsString:@"Bluetooth"]) return @"bt";
    if ([title containsString:@"Hotspot"]) return @"hotspot";
    return title.length ? title : @"?";
}

static NSString *ConnSubtitle(UIView *b) {
    id s = KV(b, @"subtitle");
    if ([s isKindOfClass:[NSString class]] && [s length]) return s;
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(b, 0, [UILabel class], labels);
    NSString *title = ConnTitle(b);
    for (UILabel *l in labels) if (l.text.length && ![l.text isEqualToString:title]) return l.text;
    return @"";
}

static UIImage *BluetoothImage(CGFloat side) {
    static NSMutableDictionary *cache; if (!cache) cache = [NSMutableDictionary dictionary];
    UIImage *c = cache[@(side)]; if (c) return c;
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    UIImage *img = [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGFloat w = side * 0.42, h = side * 0.92, x0 = (side - w) / 2, y0 = (side - h) / 2;
        UIBezierPath *p = [UIBezierPath bezierPath];
        p.lineWidth = side * 0.1; p.lineJoinStyle = kCGLineJoinRound; p.lineCapStyle = kCGLineCapRound;
        [p moveToPoint:CGPointMake(x0, y0 + h * 0.27)];
        [p addLineToPoint:CGPointMake(x0 + w, y0 + h * 0.73)];
        [p addLineToPoint:CGPointMake(x0 + w / 2, y0 + h * 0.97)];
        [p addLineToPoint:CGPointMake(x0 + w / 2, y0 + h * 0.03)];
        [p addLineToPoint:CGPointMake(x0 + w, y0 + h * 0.27)];
        [p addLineToPoint:CGPointMake(x0, y0 + h * 0.73)];
        [UIColor.blackColor setStroke]; [p stroke];
    }];
    img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cache[@(side)] = img;
    return img;
}

static UIImage *ConnIcon(NSString *key) {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold];
    NSArray *names = @{ @"air": @[@"airplane"], @"wifi": @[@"wifi"], @"airdrop": @[@"airdrop", @"dot.radiowaves.left.and.right"],
                        @"cell": @[@"cellularbars", @"antenna.radiowaves.left.and.right"],
                        @"hotspot": @[@"personalhotspot", @"link"] }[key] ?: @[@"circle.grid.2x2.fill"];
    if ([key isEqualToString:@"bt"]) return BluetoothImage(22);
    for (NSString *n in names) { UIImage *i = [UIImage systemImageNamed:n withConfiguration:cfg]; if (i) return i; }
    return nil;
}

static UIColor *ConnOnColor(NSString *key) {
    if ([key isEqualToString:@"air"]) return UIColor.systemOrangeColor;
    if ([key isEqualToString:@"cell"] || [key isEqualToString:@"hotspot"]) return UIColor.systemGreenColor;
    return UIColor.systemBlueColor;
}

@interface C26ConnCard : UIControl
@property (nonatomic, copy) NSString *key;
@property (nonatomic, weak) UIControl *target;   // Apple's round button
@property (nonatomic) BOOL pill, on;
@property (nonatomic, strong) UIView *circle;
@property (nonatomic, strong) UIImageView *icon, *chevron;
@property (nonatomic, strong) UILabel *title, *sub;
@property (nonatomic, strong) CAGradientLayer *sheen;
@property (nonatomic, strong) C26Bars *bars;
@property (nonatomic, weak) UIView *apple;      // Apple's labeled button
@property (nonatomic) CGPoint touchStart;
@end

// Stands in for a gesture recognizer so Apple's long-press handler sees "began".
@interface C26GRProxy : NSProxy
@property (nonatomic, strong) UIGestureRecognizer *gr;
@property (nonatomic) UIGestureRecognizerState fakeState;
@end
@implementation C26GRProxy
- (UIGestureRecognizerState)state { return _fakeState; }
- (BOOL)isKindOfClass:(Class)c { return [_gr isKindOfClass:c]; }
- (BOOL)respondsToSelector:(SEL)s { return [_gr respondsToSelector:s]; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)s { return [_gr methodSignatureForSelector:s]; }
- (void)forwardInvocation:(NSInvocation *)i { [i invokeWithTarget:_gr]; }
@end

static NSString *gMenuDebug = @"-";
static BOOL FireLongPress(UIGestureRecognizer *gr) {
    NSArray *targets = nil;
    @try { targets = [gr valueForKey:@"_targets"]; } @catch (__unused id e) {}
    BOOL fired = NO;
    for (id t in targets) {
        id target = nil; SEL action = NULL;
        @try { target = [t valueForKey:@"_target"]; } @catch (__unused id e) {}
        Ivar iv = class_getInstanceVariable([t class], "_action");
        if (iv) action = *(SEL *)((uint8_t *)(__bridge void *)t + ivar_getOffset(iv));
        if (!target || !action || [NSStringFromClass([target class]) hasPrefix:@"C26"]) continue;
        if (![target respondsToSelector:action]) continue;
        C26GRProxy *p = [C26GRProxy alloc]; p.gr = gr;
        p.fakeState = UIGestureRecognizerStateBegan;
        ((void (*)(id, SEL, id))objc_msgSend)(target, action, p);
        p.fakeState = UIGestureRecognizerStateEnded;
        ((void (*)(id, SEL, id))objc_msgSend)(target, action, p);
        gMenuDebug = [NSString stringWithFormat:@"fired %@ -[%@ %@]", NSStringFromClass([gr class]), NSStringFromClass([target class]), NSStringFromSelector(action)];
        fired = YES;
    }
    return fired;
}

// Open the network / device list Apple shows on a long press.
static void OpenConnMenu(UIView *labeled, UIControl *round) {
    NSMutableArray *views = [NSMutableArray array];
    if (round) [views addObject:round];
    if (labeled) [views addObject:labeled];
    for (UIView *v = round.superview; v && v != labeled; v = v.superview) [views addObject:v];
    UIViewController *vc = OwnerVC(labeled);
    NSMutableArray *vcs = [NSMutableArray array];
    for (UIViewController *p = vc; p; p = p.parentViewController) [vcs addObject:p];
    if (vc.view) [views addObject:vc.view];
    for (UIView *v in views)
        for (UIGestureRecognizer *gr in v.gestureRecognizers) {
            if (!gr.enabled) continue;
            BOOL lp = [gr isKindOfClass:[UILongPressGestureRecognizer class]] || [NSStringFromClass([gr class]) containsString:@"Press"];
            if (lp && [gr isKindOfClass:[UILongPressGestureRecognizer class]] && ((UILongPressGestureRecognizer *)gr).minimumPressDuration < 0.05) continue; // our jelly
            if (lp && FireLongPress(gr)) return;
        }
    for (UIView *v in views)
        for (id<UIInteraction> it in v.interactions)
            if ([it isKindOfClass:[UIContextMenuInteraction class]] && [(id)it respondsToSelector:NSSelectorFromString(@"_presentMenuAtLocation:")]) {
                CGPoint c = CGPointMake(CGRectGetMidX(v.bounds), CGRectGetMidY(v.bounds));
                ((void (*)(id, SEL, CGPoint))objc_msgSend)(it, NSSelectorFromString(@"_presentMenuAtLocation:"), c);
                gMenuDebug = @"context menu";
                return;
            }
    for (UIView *v in views)
        for (id it in v.interactions)
            for (NSString *sel in @[@"_presentMenuAtLocation:", @"_beginInteractionAtLocation:", @"_startInteractionAtLocation:"])
                if ([it respondsToSelector:NSSelectorFromString(sel)]) {
                    CGPoint c = CGPointMake(CGRectGetMidX(v.bounds), CGRectGetMidY(v.bounds));
                    ((void (*)(id, SEL, CGPoint))objc_msgSend)(it, NSSelectorFromString(sel), c);
                    gMenuDebug = [NSString stringWithFormat:@"%@ %@", NSStringFromClass([it class]), sel];
                    return;
                }
    // Nothing worked: list what Apple's objects offer so the next build can call it.
    NSMutableArray *m = [NSMutableArray array];
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"menu|present|expand|detail|long|click|preview" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableArray *objs = [vcs mutableCopy];
    for (UIView *v in views) for (id it in v.interactions) [objs addObject:it];
    for (id o in objs) {
        NSMutableArray *found = [NSMutableArray array];
        for (Class c = [o class]; c && c != [UIViewController class] && c != [NSObject class]; c = class_getSuperclass(c)) {
            unsigned int cnt = 0; Method *ms = class_copyMethodList(c, &cnt);
            for (unsigned int i = 0; i < cnt && found.count < 8; i++) {
                NSString *n = NSStringFromSelector(method_getName(ms[i]));
                if ([n hasPrefix:@"_accessibility"] || [n hasPrefix:@"."]) continue;
                if ([re firstMatchInString:n options:0 range:NSMakeRange(0, n.length)]) [found addObject:n];
            }
            free(ms);
        }
        id del = [o respondsToSelector:@selector(delegate)] && ![o isKindOfClass:[UIViewController class]] ? [o delegate] : nil;
        [m addObject:[NSString stringWithFormat:@"%@%@: %@", NSStringFromClass([o class]), del ? [NSString stringWithFormat:@"(del=%@)", NSStringFromClass([del class])] : @"",
                      [found componentsJoinedByString:@" "]]];
    }
    gMenuDebug = [@"none worked\n   " stringByAppendingString:[m componentsJoinedByString:@"\n   "]];
}
@implementation C26ConnCard
- (instancetype)initWithKey:(NSString *)key pill:(BOOL)pill {
    if (!(self = [super initWithFrame:CGRectZero])) return nil;
    _key = key; _pill = pill;
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:CARD_A];
    self.layer.borderWidth = 1.1;
    self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.32].CGColor;
    if (@available(iOS 13.0, *)) self.layer.cornerCurve = kCACornerCurveContinuous;
    _sheen = [CAGradientLayer layer];
    // liquid-glass light: bright at the top edge, a softer catch at the bottom
    _sheen.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.22].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                      (id)[UIColor colorWithWhite:1 alpha:0].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.1].CGColor];
    _sheen.locations = @[@0, @0.3, @0.8, @1];
    [self.layer addSublayer:_sheen];
    _circle = [UIView new];
    _circle.userInteractionEnabled = NO;
    [self addSubview:_circle];
    _icon = [[UIImageView alloc] initWithImage:ConnIcon(key)];
    _icon.contentMode = UIViewContentModeCenter;
    _icon.tintColor = UIColor.whiteColor;
    [_circle addSubview:_icon];
    _title = [UILabel new];
    _title.font = [UIFont systemFontOfSize:pill ? 15.5 : 15.5 weight:UIFontWeightMedium];
    _title.textColor = UIColor.whiteColor;
    [self addSubview:_title];
    _sub = [UILabel new];
    _sub.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    _sub.textColor = [UIColor colorWithWhite:1 alpha:0.62];
    [self addSubview:_sub];
    if ([key isEqualToString:@"cell"]) {
        _bars = [C26Bars new];
        [_circle addSubview:_bars];
        _icon.hidden = YES;
    }
    if ([@[@"wifi", @"airdrop", @"bt"] containsObject:key]) {
        _chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:10.5 weight:UIImageSymbolWeightSemibold]]];
        _chevron.tintColor = [UIColor colorWithWhite:1 alpha:0.62];
        _chevron.contentMode = UIViewContentModeCenter;
        [self addSubview:_chevron];
    }
    for (UIView *v in @[_title, _sub]) v.userInteractionEnabled = NO;
    [self addTarget:self action:@selector(down) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [self addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [self addTarget:self action:@selector(fire) forControlEvents:UIControlEventTouchUpInside];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize S = self.bounds.size;
    self.layer.cornerRadius = _pill ? S.height / 2 : 30;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _sheen.frame = self.bounds; _sheen.cornerRadius = self.layer.cornerRadius;
    [CATransaction commit];
    CGFloat d = 44;
    CGFloat subW;
    if (_pill) {
        _circle.frame = CGRectMake(14, (S.height - d) / 2, d, d);
        CGFloat x = 14 + d + 12, w = S.width - x - 16;
        _title.frame = CGRectMake(x, S.height / 2 - 20, w, 20);
        subW = MIN(w, [_sub sizeThatFits:CGSizeMake(w, 20)].width);
        _sub.frame = CGRectMake(x, S.height / 2 + 1, subW, 19);
    } else {
        _circle.frame = CGRectMake(14, 14, d, d);
        CGFloat w = S.width - 30;
        _title.frame = CGRectMake(16, S.height - 56, w, 20);
        subW = MIN(w - 16, [_sub sizeThatFits:CGSizeMake(w, 20)].width);
        _sub.frame = CGRectMake(16, S.height - 35, subW, 19);
    }
    _chevron.frame = CGRectMake(CGRectGetMaxX(_sub.frame) + 3, _sub.frame.origin.y, 12, 19);
    _circle.layer.cornerRadius = d / 2;
    _icon.frame = _circle.bounds;
    _bars.frame = CGRectMake((d - 20) / 2, (d - 16) / 2, 20, 16);
}
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    _touchStart = [touch locationInView:self];
    return [super beginTrackingWithTouch:touch withEvent:event];
}
- (BOOL)whiteWhenOff { return [@[@"wifi", @"cell", @"bt", @"airdrop"] containsObject:_key]; }
- (void)takeOff {
    // The plane leaves up-right, comes back in from the lower left, and an
    // orange shine sweeps across the pill.
    UIImageView *ic = _icon;
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        ic.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(34, -26), 0.6, 0.6);
        ic.alpha = 0;
    } completion:^(BOOL f) {
        ic.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(-30, 22), 0.6, 0.6);
        [UIView animateWithDuration:0.55 delay:0.04 usingSpringWithDamping:0.62 initialSpringVelocity:0.6 options:0 animations:^{
            ic.transform = CGAffineTransformIdentity;
            ic.alpha = 1;
        } completion:nil];
    }];
    CAGradientLayer *band = [CAGradientLayer layer];
    UIColor *o = UIColor.systemOrangeColor;
    band.colors = @[(id)[o colorWithAlphaComponent:0].CGColor, (id)[o colorWithAlphaComponent:0.55].CGColor, (id)[o colorWithAlphaComponent:0].CGColor];
    band.startPoint = CGPointMake(0, 0.5); band.endPoint = CGPointMake(1, 0.5);
    CGFloat w = self.bounds.size.width * 0.45;
    band.frame = CGRectMake(-w, 0, w, self.bounds.size.height);
    CALayer *clip = [CALayer layer];
    clip.frame = self.bounds; clip.cornerRadius = self.layer.cornerRadius; clip.masksToBounds = YES;
    [clip addSublayer:band];
    [self.layer insertSublayer:clip above:_sheen];
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"position.x"];
    a.fromValue = @(-w / 2); a.toValue = @(self.bounds.size.width + w / 2);
    a.duration = 0.7; a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    a.removedOnCompletion = NO; a.fillMode = kCAFillModeForwards;
    [band addAnimation:a forKey:@"sweep"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [clip removeFromSuperlayer]; });
    C26Spring *s = SpringFor(self);
    s.k = 260; s.c = 11; s.vsx += 1.1; s.vsy += 1.1; s.vx += 160;
    WakeSpring(s);
}
- (void)down {
    C26Spring *s = SpringFor(self);
    s.k = 650; s.c = 38; s.tsx = s.tsy = _pill ? 0.965 : 0.93; s.tx = s.ty = 0; s.angle = 0;
    WakeSpring(s);
    [UIView animateWithDuration:0.12 animations:^{ self.backgroundColor = [UIColor colorWithWhite:1 alpha:CARD_PRESSED]; }];
}
- (void)relax:(CGFloat)kick {
    C26Spring *s = SpringFor(self);
    s.k = 300; s.c = 13; s.tsx = s.tsy = 1; s.tx = s.ty = 0;
    s.vsx += kick; s.vsy += kick;
    WakeSpring(s);
    BOOL airOn = [_key isEqualToString:@"air"] && _on;
    [UIView animateWithDuration:0.25 animations:^{ self.backgroundColor = airOn ? [UIColor.systemOrangeColor colorWithAlphaComponent:0.22] : [UIColor colorWithWhite:1 alpha:CARD_A]; }];
}
- (void)cancel { [self relax:0]; }
- (void)fire {
    [self relax:_pill ? 0.9 : 1.6];
    // The icon circle does its own little pop as the state flips.
    C26Spring *c = SpringFor(_circle);
    c.sx = c.sy = 0.78; c.k = 360; c.c = 12; c.tsx = c.tsy = 1;
    WakeSpring(c);
    UIControl *t = self.target;
    BOOL arrow = ([_key isEqualToString:@"wifi"] || [_key isEqualToString:@"bt"]) && _touchStart.y > _sub.frame.origin.y - 8;
    if (arrow) { @try { OpenConnMenu(self.apple, t); } @catch (__unused id e) { gMenuDebug = @"menu threw"; } return; }
    if (t && t.enabled) [t sendActionsForControlEvents:UIControlEventTouchUpInside];
    for (NSNumber *d in @[@0.06, @0.2, @0.5])
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { Tick(); } @catch (__unused id e) {} });
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    void (^apply)(void) = ^{
        BOOL white = !on && [self whiteWhenOff];
        self.circle.backgroundColor = on ? ConnOnColor(self.key) : (white ? UIColor.whiteColor : [UIColor colorWithWhite:1 alpha:0.2]);
        self.icon.tintColor = white ? [UIColor colorWithWhite:0.12 alpha:1] : UIColor.whiteColor;
        if ([self.key isEqualToString:@"air"])
            self.backgroundColor = on ? [UIColor.systemOrangeColor colorWithAlphaComponent:0.22] : [UIColor colorWithWhite:1 alpha:CARD_A];
    };
    if (animated && on && [_key isEqualToString:@"air"]) [self takeOff];
    if (animated) [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:apply completion:nil];
    else apply();
}
@end

static const void *kConnMask = &kConnMask;
static __weak UIView *gConnOverlay;  // catches touches in the gaps so Apple's hidden buttons never fire

static NSHashTable *gConnGlass;
static NSString *gGlassDebug = @"-";
static void RemoveConnOverlay(void) {
    UIView *o = gConnOverlay;
    if (o) [o removeFromSuperview];
    for (UIView *g in [gConnGlass allObjects]) {
        g.layer.mask = nil;
        objc_setAssociatedObject(g, kConnMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [gConnGlass removeAllObjects];
    for (UIView *b in [gConnButtons allObjects]) {
        if (objc_getAssociatedObject(b, kConnMask)) {
            b.layer.mask = nil;
            objc_setAssociatedObject(b, kConnMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

// buttons: Apple's expanded CCUILabeledRoundButtons, all visible.
static void StyleConnectivity(NSArray *buttons) {
    if (!gEnabled || !gConn || buttons.count < 3) { RemoveConnOverlay(); return; }
    UIView *sv = ((UIView *)buttons[0]).superview;
    CGRect U = CGRectNull;
    NSMutableDictionary *byKey = [NSMutableDictionary dictionary];
    NSMutableArray *extra = [NSMutableArray array];
    for (UIView *b in buttons) {
        U = CGRectUnion(U, [b convertRect:b.bounds toView:sv]);
        NSString *k = ConnKey(ConnTitle(b));
        if (@[@"air", @"wifi", @"airdrop", @"cell", @"bt", @"hotspot"].count && [@[@"air", @"wifi", @"airdrop", @"cell", @"bt", @"hotspot"] containsObject:k]) byKey[k] = b;
        else [extra addObject:b];
    }
    // The card area: a little wider and taller than Apple's 2x3 grid.
    CGFloat W = U.size.width + 16, gap = 14, pillH = 70;
    CGFloat tileW = (W - gap) / 2, tileH = tileW * 0.96;
    NSMutableArray *rows = [NSMutableArray array];   // each row: array of keys
    if (byKey[@"air"]) [rows addObject:@[@"air"]];
    NSArray *tiles = @[@[@"wifi", @"airdrop"], @[@"cell", @"bt"]];
    for (NSArray *r in tiles) {
        NSMutableArray *have = [NSMutableArray array];
        for (NSString *k in r) if (byKey[k]) [have addObject:k];
        if (have.count) [rows addObject:have];
    }
    if (byKey[@"hotspot"]) [rows addObject:@[@"hotspot"]];
    for (UIView *b in extra) { NSString *k = ConnKey(ConnTitle(b)); byKey[k] = b; [rows addObject:@[k]]; }
    CGFloat H = 0;
    for (NSArray *r in rows) H += (r.count == 1 && ![tiles containsObject:r] && !([r[0] isEqualToString:@"wifi"] || [r[0] isEqualToString:@"airdrop"] || [r[0] isEqualToString:@"cell"] || [r[0] isEqualToString:@"bt"]) ? pillH : tileH);
    H += gap * (rows.count - 1);
    CGRect area = CGRectMake(CGRectGetMidX(U) - W / 2, CGRectGetMidY(U) - H / 2, W, H);

    // Host: the first ancestor big enough to hold the cards without clipping.
    UIView *host = sv; int d = 0;
    while (host.superview && d++ < 4 && !CGRectContainsRect(host.bounds, [sv convertRect:area toView:host])) host = host.superview;
    CGRect frame = [sv convertRect:area toView:host];

    UIView *o = gConnOverlay;
    BOOL fresh = NO;
    if (!o || o.superview != host) {
        [o removeFromSuperview];
        o = [UIView new];
        o.tag = CONN_TAG;
        [host addSubview:o];
        gConnOverlay = o;
        fresh = YES;
    }
    [host bringSubviewToFront:o];
    SetFrame(o, frame);

    // The module's own glass panel behind the cards: siblings on the way up
    // that are material/backdrop views about the size of the module.
    if (!gConnGlass) gConnGlass = [NSHashTable weakObjectsHashTable];
    CGRect areaW = [sv convertRect:area toView:nil];
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    NSMutableArray *gdbg = [NSMutableArray array];
    UIView *child = sv; int up = 0;
    for (UIView *p = sv.superview; p && up < 7; child = p, p = p.superview, up++) {
        for (UIView *s in p.subviews) {
            if (s == child || s == o || s.tag == CONN_TAG) continue;
            NSString *n = NSStringFromClass([s class]);
            if (!([n containsString:@"Material"] || [n containsString:@"Backdrop"] || [n containsString:@"Background"] || [n containsString:@"Blur"])) continue;
            CGRect f = [s convertRect:s.bounds toView:nil];
            if (f.size.width >= screenW * 0.97 || f.size.width < areaW.size.width * 0.8) continue;
            if (!CGRectIntersectsRect(f, areaW)) continue;
            if (!objc_getAssociatedObject(s, kConnMask)) {
                s.layer.mask = [CALayer layer];
                objc_setAssociatedObject(s, kConnMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [gConnGlass addObject:s];
            }
            if (gDebug && gdbg.count < 4) [gdbg addObject:[NSString stringWithFormat:@"%@ %.0fx%.0f", n, f.size.width, f.size.height]];
        }
    }
    if (gDebug) gGlassDebug = gdbg.count ? [gdbg componentsJoinedByString:@", "] : @"none found";

    NSMutableSet *used = [NSMutableSet set];
    CGFloat y = 0; int index = 0;
    for (NSArray *r in rows) {
        BOOL isTile = [r[0] isEqualToString:@"wifi"] || [r[0] isEqualToString:@"airdrop"] || [r[0] isEqualToString:@"cell"] || [r[0] isEqualToString:@"bt"];
        CGFloat h = isTile ? tileH : pillH;
        for (NSUInteger i = 0; i < r.count; i++) {
            NSString *k = r[i];
            UIView *b = byKey[k];
            C26ConnCard *card = nil;
            for (UIView *v in o.subviews) if ([v isKindOfClass:[C26ConnCard class]] && [((C26ConnCard *)v).key isEqualToString:k]) card = (C26ConnCard *)v;
            if (!card) {
                card = [[C26ConnCard alloc] initWithKey:k pill:!isTile];
                [o addSubview:card];
                [card setOn:NO animated:NO];
                objc_setAssociatedObject(card, kLastValue, @(-1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [used addObject:card];
            CGRect f = isTile ? CGRectMake(i * (tileW + gap), y, tileW, h) : CGRectMake(0, y, W, h);
            if (!CGAffineTransformIsIdentity(card.transform) && !fresh) {
                // a spring is running; set the frame through bounds/center so it isn't fought
                card.bounds = CGRectMake(0, 0, f.size.width, f.size.height);
                card.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
            } else SetFrame(card, f);
            UIControl *round = (UIControl *)RoundButtonIn(b);
            card.target = [round isKindOfClass:[UIControl class]] ? round : nil;
            card.apple = b;
            if (card.bars) {
                int a, n; SignalBars(&a, &n);
                BOOL white = !(card.target && card.target.isSelected);
                [card.bars setActive:a total:n color:white ? [UIColor colorWithWhite:0.12 alpha:1] : UIColor.whiteColor];
            }
            NSString *title = ConnTitle(b), *sub = ConnSubtitle(b);
            if (![card.title.text isEqualToString:title]) card.title.text = title;
            if (![card.sub.text isEqualToString:sub]) { card.sub.text = sub; [card setNeedsLayout]; }
            BOOL on = card.target ? card.target.isSelected : NO;
            NSNumber *last = objc_getAssociatedObject(card, kLastValue);
            if (last.intValue != (int)on) {
                [card setOn:on animated:last.intValue != -1];
                objc_setAssociatedObject(card, kLastValue, @(on), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            CGFloat a = (card.target && !card.target.enabled) ? 0.5 : 1;
            if (card.alpha != a && !fresh) card.alpha = a;
            if (fresh) {
                // cards rise in one after another
                card.alpha = 0;
                C26Spring *s = SpringFor(card);
                s.sx = s.sy = 0.86; s.y = 18; s.vx = s.vy = s.vsx = s.vsy = 0;
                s.k = 260; s.c = 17; s.tsx = s.tsy = 1; s.ty = 0; s.tx = 0; s.angle = 0;
                card.transform = [s transform];
                CGFloat delay = 0.035 * index;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    WakeSpring(s);
                    [UIView animateWithDuration:0.22 animations:^{ card.alpha = a; }];
                });
            }
            index++;
            // Apple's own button stays (for state) but draws nothing.
            if (!objc_getAssociatedObject(b, kConnMask)) {
                b.layer.mask = [CALayer layer];
                objc_setAssociatedObject(b, kConnMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
        y += h + gap;
    }
    for (UIView *v in [o.subviews copy]) if ([v isKindOfClass:[C26ConnCard class]] && ![used containsObject:v]) [v removeFromSuperview];
}

#pragma mark - debug

static void UpdateDebug(UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug) { [l removeFromSuperview]; return; }
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
    NSString *text = [NSString stringWithFormat:@" Control26 0.2.2 debug\n music: %@\n cmds: %@\n conn: %@\n sliders: %@", gMusicDebug, gCmdDebug, gConnDebug, gSliderDebug];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    SetFrame(l, CGRectMake(12, 40, width, s.height + 6));
    [w bringSubviewToFront:l];
}

#pragma mark - tick

static void Tick(void) {
    BOOL anyVisible = NO;
    UIWindow *win = nil;
    for (UIView *m in [gMediaViews allObjects]) {
        if (!m.window || !InControlCenter(m)) continue;
        anyVisible = YES; win = m.window;
        @try { StyleModule(m); } @catch (__unused id e) {}
    }
    NSMutableArray *dbg = [NSMutableArray array];
    for (UIView *s in [gSliders allObjects]) {
        if (!s.window || !InControlCenter(s)) continue;
        anyVisible = YES; win = s.window;
        @try { StyleSlider(s); AddBounce(s); } @catch (__unused id e) {}
        if (gDebug) [dbg addObject:[NSString stringWithFormat:@"%@ kind=%d v=%.2f glyphs=%lu track=%@", NSStringFromClass([s class]), SliderKind(s), SliderValue(s),
                                    (unsigned long)AllAppleGlyphs(s).count, objc_getAssociatedObject(s, kDirect) ? @"direct" : @"apple"]];
    }
    if (gDebug) gSliderDebug = [dbg componentsJoinedByString:@"\n  "];
    NSMutableArray *cdbg = [NSMutableArray array], *expanded = [NSMutableArray array];
    for (UIView *b in [gConnButtons allObjects]) {
        if (!b.window || !InControlCenter(b)) continue;
        anyVisible = YES; win = b.window;
        @try { StyleConnButton(b); } @catch (__unused id e) {}
        if (b.bounds.size.width > 100 && !b.hidden && b.alpha > 0.01) [expanded addObject:b];
        if (gDebug && cdbg.count < 3) {
            UIView *r = RoundButtonIn(b);
            CGRect f = [b convertRect:b.bounds toView:nil];
            [cdbg addObject:[NSString stringWithFormat:@"%@ %@ %.0f,%.0f %.0fx%.0f round=%@ sel=%d",
                             ConnTitle(b), NSStringFromClass([b class]), f.origin.x, f.origin.y, f.size.width, f.size.height,
                             r ? NSStringFromClass([r class]) : @"none", [r isKindOfClass:[UIControl class]] ? ((UIControl *)r).isSelected : -1]];
        }
    }
    if (expanded.count) {
        UIView *sv = ((UIView *)expanded[0]).superview;
        [expanded filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *b, id x) { return b.superview == sv; }]];
    }
    @try { StyleConnectivity(expanded); } @catch (__unused id e) {}
    if (gDebug && expanded.count) {
        UIView *wifi = nil;
        for (UIView *b in expanded) if ([ConnKey(ConnTitle(b)) isEqualToString:@"wifi"]) wifi = b;
        UIControl *r = (UIControl *)RoundButtonIn(wifi);
        NSMutableArray *g = [NSMutableArray array];
        for (UIView *v = r; v && v != wifi.superview; v = v.superview)
            for (UIGestureRecognizer *gr in v.gestureRecognizers) [g addObject:NSStringFromClass([gr class])];
        NSUInteger targets = [r isKindOfClass:[UIControl class]] ? r.allTargets.count : 0;
        [cdbg addObject:[NSString stringWithFormat:@"cards=%lu host=%@ wifi targets=%lu gestures=%@", (unsigned long)gConnOverlay.subviews.count,
                         NSStringFromClass([gConnOverlay.superview class]), (unsigned long)targets, [g componentsJoinedByString:@","]]];
        [cdbg addObject:[NSString stringWithFormat:@"bars=%@ glass=%@", gBarsDebug, gGlassDebug]];
        [cdbg addObject:[NSString stringWithFormat:@"menu=%@", gMenuDebug]];
    }
    if (gDebug) gConnDebug = cdbg.count ? [cdbg componentsJoinedByString:@"\n  "] : @"(hold the Wi-Fi block to open it)";
    if (win) UpdateDebug(win);
    // Control Center closed: stop the timer until it opens again.
    if (!anyVisible) { RemoveConnOverlay(); [gTimer invalidate]; gTimer = nil; }
}

#pragma mark - hooks

%group Media
%hook MRUNowPlayingView
- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        if (!gMediaViews) gMediaViews = [NSHashTable weakObjectsHashTable];
        [gMediaViews addObject:self];
        StartTimer();
    }
}
%end
%end

%group SlidersCC
%hook CCUIBaseSliderView
- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        if (!gSliders) gSliders = [NSHashTable weakObjectsHashTable];
        [gSliders addObject:self];
        StartTimer();
    }
}
%end
%end

%group SlidersMRU
%hook MRUContinuousSliderView
- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        if (!gSliders) gSliders = [NSHashTable weakObjectsHashTable];
        [gSliders addObject:self];
        StartTimer();
    }
}
%end
%end

// Keep the views we replaced hidden if Apple tries to show them again.
%hook UILabel
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end

%hook UIImageView
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end

%hook UIControl
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end

%group Conn
%hook CCUILabeledRoundButton
- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        if (!gConnButtons) gConnButtons = [NSHashTable weakObjectsHashTable];
        [gConnButtons addObject:self];
        StartTimer();
    }
}
%end
%end

%group Jelly1
%hook CCUIRoundButton
- (void)didMoveToWindow { %orig; if (self.window && InControlCenter(self)) AddJelly(self); }
%end
%end

%group Jelly2
%hook CCUIButtonModuleView
- (void)didMoveToWindow { %orig; if (self.window && InControlCenter(self)) AddJelly(self); }
%end
%end

%group Glyphs
%hook CCUICAPackageView
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end
%end

static BOOL gMediaHooked, gCCHooked, gMRUHooked, gGlyphHooked, gJ1Hooked, gJ2Hooked;
static void InitJ1(void) { %init(Jelly1); }
static BOOL gConnHooked;
static void InitConn(void) { %init(Conn); }
static void InitJ2(void) { %init(Jelly2); }
static void InitMedia(void)  { %init(Media); }
static void InitCC(void)     { %init(SlidersCC); }
static void InitMRU(void)    { %init(SlidersMRU); }
static void InitGlyphs(void) { %init(Glyphs); }

static void TryLateHooks(void) {
    if (!gMediaHooked && NSClassFromString(@"MRUNowPlayingView"))      { gMediaHooked = YES; InitMedia(); }
    if (!gCCHooked && NSClassFromString(@"CCUIBaseSliderView"))        { gCCHooked = YES; InitCC(); }
    if (!gMRUHooked && NSClassFromString(@"MRUContinuousSliderView"))  { gMRUHooked = YES; InitMRU(); }
    if (!gGlyphHooked && NSClassFromString(@"CCUICAPackageView"))      { gGlyphHooked = YES; InitGlyphs(); }
    if (!gJ1Hooked && NSClassFromString(@"CCUIRoundButton"))           { gJ1Hooked = YES; InitJ1(); }
    if (!gJ2Hooked && NSClassFromString(@"CCUIButtonModuleView"))      { gJ2Hooked = YES; InitJ2(); }
    if (!gConnHooked && NSClassFromString(@"CCUILabeledRoundButton"))  { gConnHooked = YES; InitConn(); }
}

static void StartLateHooks(void) {
    TryLateHooks();
    __block int tries = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        TryLateHooks();
        if ((gMediaHooked && gCCHooked && gMRUHooked && gGlyphHooked && gJ1Hooked && gJ2Hooked && gConnHooked) || ++tries > 120) [t invalidate];
    }];
}

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.springboard"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
    // Control Center's frameworks can load after SpringBoard starts. Check once
    // a second (for up to 2 minutes) and hook each part as soon as it exists.
    StartLateHooks();
    dispatch_async(dispatch_get_main_queue(), ^{ RegisterNowPlayingNotifications(); });
}
