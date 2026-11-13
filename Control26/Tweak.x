// Control26 1.2.4 - made by nano
// 1.2.4: glass is LiquidAss's own (its blur setting applies); NanoGlass switch turns it on or off
// 1.2.3: glass follows the NanoGlass slider (clear to frosted)
// 1.2.2: with LiquidAss installed, our glass buttons are the same liquid glass as MusicPill
// 1.2: smaller iPhones (4.7"/5.5"): pages fit the screen, Connectivity fits (short names), page icons fit the margin;
//      Style setting (iOS 26 / iOS 18), Module Shapes (round controls, capsule sliders) without other tweaks,
//      clean card corners, - badges sit on the control edge, star no longer covers back on the music player
// 1.1: cover tap removed again; public release
// 1.0.4: tap the cover to open the playing app (Music, Spotify, ...), page icons no longer react to taps (hold and slide)
// 1.0.3: no more freeze when jumping pages, progress bar no longer flashes full while sliding, 4x2 player buttons centered
// 1.0.2: music sliders no longer flicker, Wi-Fi / Bluetooth arrows on the big Connectivity open their settings
// 1.0.1: Apple's AirDrop glyph, smoother page icons and page scrolling (controls shrink, header and + / power stay put),
//        music sliders move from where they are like Apple's (grow while held, stretch at the ends)
// 1.0: first official release
// 0.6.6: Big Music / Connectivity and their copies disappear at once when Control Center closes
// 0.6.5: hold and drag works from anywhere on a control in edit mode, Apple's AirPlay / pause stay hidden after opening the player
// 0.6.4: controls drop in one by one when Control Center opens (iOS 26), Settings > Control Center redesigned
//        like iOS 18 (Customize card with animated phone, Access Within Apps, Reset Control Center)
// 0.6.3: moving controls works again in edit mode, copies of Connectivity / Music for other pages (Add a Control),
//        Control Center stops scrolling into removed pages
// 0.6.2: pages are separate: only the page you're on shows, the others fade out as you swipe
// 0.6.1: real pages (4 x 7 each, up to 6): add one with + by the page icons while editing, empty pages
//        go away, swipes snap to pages, slide along the icons to zoom out and jump; connectivity / music
//        drawn like iOS 26 (no outer box, cards; player card with star + AirPlay pill)
// 0.6.0: big layouts (connectivity 4x4/4x6/4x8 labeled tiles, music 4x2 strip / 4x4 player / 4x6+ big artwork),
//        pages on the right (Favorites / Connectivity / Music, swipe up and down), saved layouts + reset
// 0.5.7: Apple's AirPlay/play icons masked away for good, slider icons stay colored (no flicker),
//        edit mode scrolls (swipe), hold a control to move it
// 0.5.6: Apple's AirPlay/pause icon stays hidden after closing the big player, softer see-through edit glow,
//        Add a Control grows out of its button and back, - badges and handles fade in
// 0.5.5: move controls anywhere (gaps allowed, own layout), edit mode ends when Control Center closes,
//        + / power vanish as soon as it starts closing
// 0.5.4: + and power can be tapped again (they moved out of the content area that gets the touches)
// 0.5.3: fixed the Safe Mode crash (the grid was inside Control Center's module view), grid lines up,
//        + / power on the status bar line, smooth shaped glow, the others make room while you drag,
//        editing hides under Add a Control, volume can't be resized
// 0.5.2: grid read row by row (lines up), + / power above the status bar and hidden in landscape, glow pulse
//        instead of wiggle, sliders can't be resized, connectivity 2x2/4x4/4x6/4x8, music 2x2/4x2/4x4/4x6/4x8,
//        more empty rows to scroll to, safer closing, debug box can be dragged
// 0.5.1: edit mode finds the controls (handles, remove, drag to move), circles only in empty spots and lined up,
//        + and power above the status bar
// 0.5.0: iOS 18/26 edit mode: glass + and power buttons at the top, + opens editing (wiggle, resize
//        handles, 4 x 8 grid of empty spots, remove badges, Add a Control sheet), slide to power off
// 0.3.7: transport animations run on the icon's layer only (no giant icon
//        flash), Control Center's module press-dim is switched off while a
//        music button is held, play/pause: old icon bursts out, new grows in.
// 0.3.6: iOS 26 transport animations: light circle while held, next / previous
//        arrows roll over by one, play / pause shrinks to a dot and grows the
//        new icon. No haptic on pause.
// 0.3.5: smoother glide; expanded player hides Apple's route buttons by
//        position (works when the route shows a Bluetooth speaker icon), AirPlay
//        capsule anchored to the volume slider under the controls; star next
//        to back on the lock screen player too.
// 0.3.4: iOS 26 slider feel: the fill glides toward the finger every frame
//        (smoothed, ~0.1s) instead of snapping, and a flick carries on a bit
//        before easing to a stop.
// 0.3.3: volume tracks the finger 1:1 too, Control Center's scroll waits for
//        any slider drag (no more stalls on fast / slow drags), Auto-Brightness
//        check off the main thread (no open lag), cards appear 10% faster.
// 0.3.2: subtle fade-and-settle when expanded cards appear, music text a bit
//        smaller, Auto-Brightness switched off (setting "Stop Auto-Brightness").
// 0.3.1: tap anywhere on the brightness / volume capsule to open it, no icon
//        inside the expanded slider, Dark Mode / Night Shift / True Tone left
//        as Apple's own round buttons (cards are only for connectivity).
// 0.3.0: expanded cards show instantly (no rise-in, styled on layout),
//        Dark Mode / Night Shift / True Tone get real icons and taps that
//        reach Apple (gesture fallback), artwork shrinks when paused and
//        springs up when playing, "Not Playing" 10% smaller, tap the
//        brightness / volume icon to open the module.
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
#import <substrate.h>
#import <mach-o/dyld.h>
#include "../shared/NanoGlass.h"

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
#define LOCK_TAG    0x43323636
#define CONN_TAG    0x43323635
#define CARD_A      0.24
#define CARD_PRESSED 0.34

static BOOL gNoAuto = YES;
static BOOL gEditUI = YES;
static __weak UIViewController *gCCVC;   // Control Center (edit mode)
static NSString *gEditDebug = @"-";
static void StopAutoBrightness(void);
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
static BOOL gDropIn = YES, gCCPage = YES;
static BOOL gShapes = YES;
static BOOL gStyle18;   // Style: iOS 18 look (flat frosted) instead of iOS 26 liquid glass
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
    gNoAuto  = PrefBool(f, @"noauto", YES);
    gEditUI  = PrefBool(f, @"editui", YES);
    gDropIn  = PrefBool(f, @"dropin", YES);
    gCCPage  = PrefBool(f, @"ccsettings", YES);
    id st = f[@"style"];
    gStyle18 = [st respondsToSelector:@selector(intValue)] && [st intValue] == 18;
    gShapes  = PrefBool(f, @"shapes", YES);
}
static void RestyleAll(void);
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ LoadPrefs(); @try { StopAutoBrightness(); RestyleAll(); } @catch (__unused id e) {} });
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
    if (![v.layer.mask.name isEqualToString:@"c26.gone"]) { CALayer *m = [CALayer layer]; m.name = @"c26.gone"; m.frame = CGRectZero; v.layer.mask = m; }
}
static void RestoreMusic(void) {
    for (UIView *v in [gHiddenMusic allObjects]) ShowOriginal(v);
    [gHiddenMusic removeAllObjects];
}

static void ShowOriginal(UIView *v) {
    if (!v || !objc_getAssociatedObject(v, kHidByUs)) return;
    objc_setAssociatedObject(v, kHidByUs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    v.alpha = 1;
    if ([v.layer.mask.name isEqualToString:@"c26.gone"]) v.layer.mask = nil;
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
    // Each time Control Center opens (at most once a minute, off the main thread).
    static CFTimeInterval lastAuto;
    if (CACurrentMediaTime() - lastAuto > 60) {
        lastAuto = CACurrentMediaTime();
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ @try { StopAutoBrightness(); } @catch (__unused id e) {} });
    }
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
static double gNPElapsed, gNPDuration, gNPRate;   // song position (for the big player)
static NSDate *gNPStamp;
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
        id el = d[@"kMRMediaRemoteNowPlayingInfoElapsedTime"], du = d[@"kMRMediaRemoteNowPlayingInfoDuration"], ra = d[@"kMRMediaRemoteNowPlayingInfoPlaybackRate"], ts = d[@"kMRMediaRemoteNowPlayingInfoTimestamp"];
        gNPElapsed = [el respondsToSelector:@selector(doubleValue)] ? [el doubleValue] : 0;
        gNPDuration = [du respondsToSelector:@selector(doubleValue)] ? [du doubleValue] : 0;
        gNPRate = [ra respondsToSelector:@selector(doubleValue)] ? [ra doubleValue] : 1;
        gNPStamp = [ts isKindOfClass:[NSDate class]] ? ts : [NSDate date];
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

// iOS 26: a soft light circle behind the button while it's held.
- (UIView *)bubbleFor:(UIButton *)b {
    UIView *bub = [b viewWithTag:77];
    if (!bub) {
        bub = [UIView new];
        bub.tag = 77;
        bub.userInteractionEnabled = NO;
        bub.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22];
        bub.alpha = 0;
        [b insertSubview:bub atIndex:0];
        b.clipsToBounds = NO;
    }
    CGFloat d = MAX(b.bounds.size.width, b.bounds.size.height) * 1.08;
    bub.bounds = CGRectMake(0, 0, d, d);
    bub.center = CGPointMake(b.bounds.size.width / 2, b.bounds.size.height / 2);
    bub.layer.cornerRadius = d / 2;
    return bub;
}
// Control Center dims the whole module while a finger is on it. Switch those
// press recognizers off while one of our buttons is held.
static NSHashTable *gPausedPress;
static void HoldModulePress(UIView *b, BOOL hold) {
    if (!gPausedPress) gPausedPress = [NSHashTable weakObjectsHashTable];
    if (hold) {
        for (UIView *p = b.superview; p; p = p.superview) {
            for (UIGestureRecognizer *g in p.gestureRecognizers) {
                NSString *n = NSStringFromClass([g class]);
                BOOL press = [n containsString:@"TouchDuration"] || [n containsString:@"Relationship"] || [n containsString:@"Press"] || [n containsString:@"Click"];
                if (press && g.enabled && ![g isKindOfClass:[UIPanGestureRecognizer class]]) { g.enabled = NO; [gPausedPress addObject:g]; }
            }
            if ([NSStringFromClass([p class]) containsString:@"ModuleContainerView"]) break;
        }
    } else {
        for (UIGestureRecognizer *g in [gPausedPress allObjects]) g.enabled = YES;
        [gPausedPress removeAllObjects];
    }
}

// Presentation-only scale/opacity on the icon layer (the button's own layout
// never sees a transform, so the icon can't blow up).
static void IconAnim(UIView *iv, NSArray *scales, NSArray *alphas, NSArray *times, CFTimeInterval dur, NSString *key) {
    CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    s.values = scales; s.keyTimes = times;
    CAKeyframeAnimation *o = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    o.values = alphas; o.keyTimes = times;
    CAAnimationGroup *g = [CAAnimationGroup animation];
    g.animations = @[s, o]; g.duration = dur;
    g.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.25 :0.8 :0.3 :1.0];
    g.fillMode = kCAFillModeForwards; g.removedOnCompletion = NO;
    [iv.layer addAnimation:g forKey:key];
}

- (void)down:(UIButton *)b {
    HoldModulePress(b, YES);
    UIView *bub = [self bubbleFor:b];
    bub.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        bub.alpha = 1; bub.transform = CGAffineTransformIdentity;
    } completion:nil];
    IconAnim(b.imageView, @[@1, @0.9], @[@1, @1], @[@0, @1], 0.14, @"press");
}
- (void)up:(UIButton *)b {
    HoldModulePress(b, NO);
    UIView *bub = [self bubbleFor:b];
    [UIView animateWithDuration:0.35 delay:0.06 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        bub.alpha = 0; bub.transform = CGAffineTransformMakeScale(1.08, 1.08);
    } completion:nil];
    if ([b.imageView.layer animationForKey:@"press"]) IconAnim(b.imageView, @[@0.9, @1.04, @1], @[@1, @1, @1], @[@0, @0.5, @1], 0.28, @"press");
}

static CAShapeLayer *Triangle(CGSize sz, BOOL right, UIColor *color) {
    CAShapeLayer *l = [CAShapeLayer layer];
    l.bounds = CGRectMake(0, 0, sz.width, sz.height);
    UIBezierPath *p = [UIBezierPath bezierPath];
    if (right) { [p moveToPoint:CGPointMake(0, 0)]; [p addLineToPoint:CGPointMake(sz.width, sz.height / 2)]; [p addLineToPoint:CGPointMake(0, sz.height)]; }
    else       { [p moveToPoint:CGPointMake(sz.width, 0)]; [p addLineToPoint:CGPointMake(0, sz.height / 2)]; [p addLineToPoint:CGPointMake(sz.width, sz.height)]; }
    [p closePath];
    l.path = p.CGPath;
    l.fillColor = color.CGColor;
    l.lineJoin = kCALineJoinRound;
    l.strokeColor = color.CGColor;
    l.lineWidth = sz.height * 0.08;   // soft rounded tips like the SF glyph
    return l;
}

static void AnimateLayer(CALayer *l, CGPoint from, CGPoint to, CGFloat s0, CGFloat s1, CGFloat a0, CGFloat a1, CFTimeInterval dur) {
    CAMediaTimingFunction *ease = [CAMediaTimingFunction functionWithControlPoints:0.25 :0.8 :0.3 :1.0];
    CABasicAnimation *pos = [CABasicAnimation animationWithKeyPath:@"position"];
    pos.fromValue = [NSValue valueWithCGPoint:from]; pos.toValue = [NSValue valueWithCGPoint:to];
    CABasicAnimation *sc = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    sc.fromValue = @(s0); sc.toValue = @(s1);
    CABasicAnimation *op = [CABasicAnimation animationWithKeyPath:@"opacity"];
    op.fromValue = @(a0); op.toValue = @(a1);
    CAAnimationGroup *g = [CAAnimationGroup animation];
    g.animations = @[pos, sc, op]; g.duration = dur; g.timingFunction = ease;
    g.fillMode = kCAFillModeForwards; g.removedOnCompletion = NO;
    l.position = to; l.opacity = a1; l.transform = CATransform3DMakeScale(s1, s1, 1);
    [l addAnimation:g forKey:@"roll"];
}

// Next / previous, like iOS 26: the arrows roll over by one. The front arrow
// slides off and shrinks away, the back one moves up, a new one grows in.
- (void)roll:(UIButton *)b dir:(CGFloat)dir {
    UIImageView *iv = b.imageView;
    CGRect r = iv.frame;
    if (r.size.width < 4) return;
    UIView *box = [b viewWithTag:78];
    [box removeFromSuperview];
    box = [[UIView alloc] initWithFrame:b.bounds];
    box.tag = 78;
    box.userInteractionEnabled = NO;
    [b addSubview:box];
    BOOL right = dir > 0;
    CGFloat tw = r.size.width / 2, th = r.size.height * 0.92;
    CGSize sz = CGSizeMake(tw, th);
    UIColor *col = b.tintColor ?: UIColor.whiteColor;
    CGFloat cy = CGRectGetMidY(r);
    CGPoint slotA = CGPointMake(r.origin.x + tw / 2, cy), slotB = CGPointMake(r.origin.x + tw * 1.5, cy);
    // forward: the leading arrow is the right one (slot B); backward: the left one (slot A).
    CGPoint lead = right ? slotB : slotA, trail = right ? slotA : slotB;
    CGPoint off = CGPointMake(lead.x + tw * 0.75 * dir, cy);
    CAShapeLayer *exiting = Triangle(sz, right, col), *moving = Triangle(sz, right, col), *entering = Triangle(sz, right, col);
    for (CALayer *l in @[exiting, moving, entering]) [box.layer addSublayer:l];
    exiting.position = lead; moving.position = trail; entering.position = trail;
    iv.hidden = YES;
    CFTimeInterval dur = 0.34;
    AnimateLayer(exiting, lead, off, 1, 0.15, 1, 0, dur);
    AnimateLayer(moving, trail, lead, 1, 1, 1, 1, dur);
    AnimateLayer(entering, trail, trail, 0.05, 1, 0, 1, dur);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((dur + 0.02) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        iv.hidden = NO;
        [box removeFromSuperview];
    });
}
- (void)tap:(UIButton *)b {
    [self up:b];
    if (b.tag == 6) { gSkipDir = -1; [self roll:b dir:-1]; SendMR(5); }
    else if (b.tag == 8) { gSkipDir = 1; [self roll:b dir:1]; SendMR(4); }
    else {
        // No haptic. Play <-> pause: the icon shrinks to a dot, then the new one grows out.
        SendMR(2);
        gIsPlaying = !gIsPlaying;
        NSString *sym = gIsPlaying ? @"pause.fill" : @"play.fill";
        objc_setAssociatedObject(b, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightSemibold]];
        UIImageView *iv = b.imageView;
        [iv.layer removeAnimationForKey:@"press"];
        // The old icon bursts outward and fades...
        UIImageView *ghost = [[UIImageView alloc] initWithImage:iv.image];
        ghost.tintColor = b.tintColor; ghost.contentMode = iv.contentMode;
        ghost.frame = iv.frame; ghost.userInteractionEnabled = NO;
        [b addSubview:ghost];
        IconAnim(ghost, @[@1, @1.35], @[@1, @0], @[@0, @1], 0.16, @"out");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [ghost removeFromSuperview]; });
        // ...and the new one grows in from small and settles.
        [b setImage:img forState:UIControlStateNormal];
        IconAnim(iv, @[@0.25, @0.25, @1.06, @1], @[@0, @0, @1, @1], @[@0, @0.25, @0.75, @1], 0.36, @"morph");
    }
    // Pick up the new song / state right away.
    for (NSNumber *delay in @[@0.12, @0.35, @0.8]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gLastFetch = 0; FetchNowPlaying(); });
    }
}
@end

// tap the cover: open the app that's playing (Music, Spotify, ...) and close Control Center
@interface C26AppOpener : NSObject
+ (instancetype)shared;
- (void)open:(id)sender;
@end
@implementation C26AppOpener
+ (instancetype)shared { static C26AppOpener *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26AppOpener new]; }); return s; }
- (void)open:(id)sender {
    NSString *bid = gNPApp.length ? gNPApp : @"com.apple.Music";
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIView *v = ((UIGestureRecognizer *)sender).view;
        [UIView animateWithDuration:0.12 animations:^{ v.transform = CGAffineTransformMakeScale(0.94, 0.94); } completion:^(__unused BOOL f) {
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:0 animations:^{ v.transform = CGAffineTransformIdentity; } completion:nil];
        }];
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    Class W = NSClassFromString(@"LSApplicationWorkspace");
    id ws = [W respondsToSelector:@selector(defaultWorkspace)] ? ((id (*)(id, SEL))objc_msgSend)(W, @selector(defaultWorkspace)) : nil;
    SEL op = NSSelectorFromString(@"openApplicationWithBundleID:");
    if ([ws respondsToSelector:op]) ((BOOL (*)(id, SEL, id))objc_msgSend)(ws, op, bid);
    UIViewController *cc = gCCVC;
    SEL d = @selector(dismissAnimated:withCompletionHandler:);
    if ([cc respondsToSelector:d]) ((void (*)(id, SEL, BOOL, id))objc_msgSend)(cc, d, YES, nil);
}
@end
__attribute__((unused)) static void MakeCoverTappable(UIImageView *art) {
    art.userInteractionEnabled = YES;
    [art addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:[C26AppOpener shared] action:@selector(open:)]];
}
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
    NSArray *trow = FindTransport(module);
    CGFloat rowY = -1, rowRight = S.width;
    if (trow.count >= 3) {
        UIView *nx = trow[2];
        CGRect nr = [nx convertRect:nx.bounds toView:module];
        rowY = CGRectGetMidY(nr); rowRight = CGRectGetMaxX(nr);
    }
    UILabel *titleLabel = nil;
    for (UIView *v in all) if (!titleLabel && [v isKindOfClass:[UILabel class]] && gNPTitle.length && [((UILabel *)v).text isEqualToString:gNPTitle] && ![v isDescendantOfView:o]) titleLabel = (UILabel *)v;
    CGFloat titleY = titleLabel ? CGRectGetMidY([titleLabel convertRect:titleLabel.bounds toView:module]) : -1;
    UIView *volume = nil;
    for (UIView *v in all) {
        if ([v isDescendantOfView:o]) continue;
        NSString *n = NSStringFromClass([v class]);
        if ([n containsString:@"Route"] || [n containsString:@"Routing"] || [v.accessibilityLabel.lowercaseString containsString:@"airplay"]) {
            if (v.bounds.size.width < S.width * 0.6) HideMusic(v);
            continue;
        }
        // Route buttons by position (their icon becomes a speaker on Bluetooth):
        // a small control right of the forward button, or at the end of the title row.
        if ([v isKindOfClass:[UIControl class]] && ![v isKindOfClass:[UISlider class]] && v.bounds.size.width < 70 && ![n containsString:@"Slider"]) {
            CGRect r = [v convertRect:v.bounds toView:module];
            BOOL rightOfRow = rowY > 0 && fabs(CGRectGetMidY(r) - rowY) < 22 && CGRectGetMinX(r) > rowRight + 4;
            BOOL titleEnd = titleY > 0 && fabs(CGRectGetMidY(r) - titleY) < 26 && CGRectGetMidX(r) > S.width * 0.72;
            if (rightOfRow || titleEnd) { HideMusic(v); continue; }
        }
        // Volume: the first wide slider below the playback buttons.
        if ([n containsString:@"Slider"] && v.bounds.size.width > S.width * 0.5 && !v.hidden && v.alpha > 0.01) {
            CGRect r = [v convertRect:v.bounds toView:module];
            if (rowY > 0 && CGRectGetMidY(r) < rowY) continue;
            if (!volume || CGRectGetMidY(r) < CGRectGetMidY([volume convertRect:volume.bounds toView:module])) volume = v;
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
    // everything of Apple's under our overlay stays hidden, also what it brings back after the player was opened
    for (UIView *v in module.subviews) if (v != o) HideMusic(v);

    CGFloat s = S.width / 163.0, m = 14 * s;
    UIImageView *art = (UIImageView *)[o viewWithTag:1];
    UIView *glass = [o viewWithTag:2];
    UIView *air = [o viewWithTag:3];
    UILabel *title = (UILabel *)[o viewWithTag:4], *artist = (UILabel *)[o viewWithTag:5];

    CGFloat a = round(56 * s), d = round(42 * s);
    // Set through bounds/center so the play/pause scale can live on its transform.
    CGRect af0 = CGRectMake(m, m, a, a);
    if (!CGRectEqualToRect(art.bounds, CGRectMake(0, 0, a, a))) art.bounds = CGRectMake(0, 0, a, a);
    if (!CGPointEqualToPoint(art.center, CGPointMake(CGRectGetMidX(af0), CGRectGetMidY(af0)))) art.center = CGPointMake(CGRectGetMidX(af0), CGRectGetMidY(af0));
    art.layer.cornerRadius = 12 * s;
    {
        // Like Music: the artwork sits a little smaller while paused and springs up when playing.
        BOOL big = gNPTitle == nil || gIsPlaying;
        NSNumber *lastBig = objc_getAssociatedObject(art, kBounce);
        if (!lastBig || lastBig.boolValue != big) {
            objc_setAssociatedObject(art, kBounce, @(big), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CGAffineTransform tr = big ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.86, 0.86);
            if (!lastBig) art.transform = tr;
            else [UIView animateWithDuration:big ? 0.6 : 0.45 delay:0 usingSpringWithDamping:big ? 0.55 : 0.85 initialSpringVelocity:big ? 0.8 : 0.2
                                     options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ art.transform = tr; } completion:nil];
        }
    }
    SetFrame(glass, CGRectMake(S.width - m - d, m, d, d));
    SetFrame(air, CGRectInset(glass.frame, round(10 * s), round(10 * s)));
    glass.layer.cornerRadius = d / 2;
    air.hidden = glass.hidden = NO;

    UIFont *tf = [UIFont systemFontOfSize:14.5 * s * (gNPTitle ? 1 : 0.9) weight:UIFontWeightSemibold];   // "Not Playing" 10% smaller
    UIFont *af = [UIFont systemFontOfSize:14.5 * s weight:UIFontWeightRegular];
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

// Tap the brightness / volume icon (bottom of the slider) to open the module.
@interface C26SliderTap : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26SliderTap
+ (instancetype)shared { static C26SliderTap *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26SliderTap new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    UIView *v = g.view;
    CGPoint p = [touch locationInView:v];
    (void)p;
    return gEnabled;   // anywhere on the capsule (a slide is still a slide)
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)tap:(UITapGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateEnded) return;
    for (UIViewController *p = OwnerVC(g.view); p; p = p.parentViewController) {
        if ([NSStringFromClass([p class]) containsString:@"ContainerViewController"] && [p respondsToSelector:NSSelectorFromString(@"expandModule")]) {
            ((void (*)(id, SEL))objc_msgSend)(p, NSSelectorFromString(@"expandModule"));
            return;
        }
    }
}
@end
static void AddIconTap(UIView *slider) {
    for (UIGestureRecognizer *g in slider.gestureRecognizers) if (g.delegate == (id)[C26SliderTap shared]) return;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[C26SliderTap shared] action:@selector(tap:)];
    tap.delegate = [C26SliderTap shared];
    tap.cancelsTouchesInView = NO;
    [slider addGestureRecognizer:tap];
}

static void StyleSlider(UIView *slider) {
    if (slider.bounds.size.height < 300) AddIconTap(slider);   // compact sliders only
    else {
        // Expanded slider: clean, no icon inside (the big icon sits above it).
        [[slider viewWithTag:GLYPH_TAG] removeFromSuperview];
        if (gEnabled) for (UIView *g in AllAppleGlyphs(slider)) HideOriginal(g);
        return;
    }
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
    int kind = SliderKind(slider);
    if ((kind != 1 && kind != 2) || ![slider isKindOfClass:[UIControl class]]) return;
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

#pragma mark - smooth slider (iOS 26 glide)

static const void *kGlide = &kGlide;
@interface C26Glide : NSObject
@property (nonatomic, weak) UIView *slider;
@property (nonatomic) float target, cur;
@property (nonatomic) BOOL dragging;
@end
@implementation C26Glide
@end
static NSHashTable *gGlides;
static CADisplayLink *gGlideLink;
static void StyleSlider(UIView *slider);
@interface C26GlideTicker : NSObject
+ (instancetype)shared;
@end
@implementation C26GlideTicker
+ (instancetype)shared { static C26GlideTicker *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26GlideTicker new]; }); return t; }
- (void)step:(CADisplayLink *)l {
    CGFloat dt = l.targetTimestamp - l.timestamp;
    if (dt <= 0 || dt > 0.05) dt = 1.0 / 60;
    float a = 1 - expf(-(float)dt * 17);   // ~0.13s to catch up: smooth, still responsive
    for (C26Glide *g in [gGlides allObjects]) {
        UIView *s = g.slider;
        if (!s) { [gGlides removeObject:g]; continue; }
        float d = g.target - g.cur;
        if (fabsf(d) < 0.0008 && !g.dragging) {
            g.cur = g.target;
            SetSliderValue(s, g.cur); StyleSlider(s);
            [gGlides removeObject:g];
            continue;
        }
        g.cur += d * a;
        SetSliderValue(s, g.cur);
        StyleSlider(s);
    }
    if (!gGlides.count) { [gGlideLink invalidate]; gGlideLink = nil; }
}
@end
static C26Glide *GlideFor(UIView *slider) {
    C26Glide *g = objc_getAssociatedObject(slider, kGlide);
    if (!g) { g = [C26Glide new]; g.slider = slider; objc_setAssociatedObject(slider, kGlide, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    return g;
}
static void GlideTo(UIView *slider, float target) {
    C26Glide *g = GlideFor(slider);
    if (![gGlides containsObject:g]) g.cur = SliderValue(slider);
    g.target = MAX(0, MIN(1, target));
    if (!gGlides) gGlides = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
    [gGlides addObject:g];
    if (!gGlideLink) {
        gGlideLink = [CADisplayLink displayLinkWithTarget:[C26GlideTicker shared] selector:@selector(step:)];
        if (@available(iOS 15.0, *)) gGlideLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
        [gGlideLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
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
    // Control Center's own scrolling waits for any slider drag.
    return b.view != a.view && [a.view isDescendantOfView:b.view];
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
            // iOS 26 glide: the fill follows the finger smoothly (never jumps).
            float v0 = [objc_getAssociatedObject(v, kStartValue) floatValue];
            float raw = v0 - [g translationInView:v].y / H;
            val = MAX(0, MIN(1, raw));
            GlideFor(v).dragging = YES;
            GlideTo(v, val);
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
        if (direct) {
            // A flick carries on a little in the direction you were going.
            C26Glide *gl = GlideFor(v);
            gl.dragging = NO;
            float vy = [g velocityInView:v].y;
            float carry = MAX(-0.2f, MIN(0.2f, -vy / H * 0.085f));
            GlideTo(v, gl.target + carry);
        }
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
    if ([title containsString:@"Dark Mode"]) return @"dark";
    if ([title containsString:@"Night Shift"]) return @"night";
    if ([title containsString:@"True Tone"]) return @"truetone";
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

// Apple's AirDrop glyph: rings open at the bottom. Their private symbol when it's there, else drawn the same way.
static UIImage *AirDropImage(CGFloat side) {
    static UIImage *img;
    if (img) return img;
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold];
    SEL ps = NSSelectorFromString(@"_systemImageNamed:withConfiguration:");
    if ([UIImage respondsToSelector:ps]) {
        for (NSString *n in @[@"airdrop", @"airdrop.fill"]) {
            UIImage *i = ((UIImage *(*)(id, SEL, NSString *, id))objc_msgSend)([UIImage class], ps, n, cfg);
            if (i) { img = [i imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]; return img; }
        }
    }
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    img = [r imageWithActions:^(__unused UIGraphicsImageRendererContext *c) {
        CGPoint o = CGPointMake(side / 2, side / 2 + side * 0.02);
        CGFloat R = side * 0.46, lw = side * 0.095;
        CGFloat gap = 34 * M_PI / 180;   // half of the opening at the bottom
        for (NSNumber *f in @[@0.30, @0.64, @0.98]) {
            CGFloat rr = R * f.doubleValue - lw / 2;
            UIBezierPath *p = [UIBezierPath bezierPathWithArcCenter:o radius:rr startAngle:M_PI_2 + gap endAngle:M_PI_2 - gap + 2 * M_PI clockwise:YES];
            p.lineWidth = lw; p.lineCapStyle = kCGLineCapRound;
            [UIColor.blackColor setStroke]; [p stroke];
        }
    }];
    img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return img;
}
static UIImage *ConnIcon(NSString *key) {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold];
    if ([key isEqualToString:@"airdrop"]) return AirDropImage(24);
    NSArray *names = @{ @"air": @[@"airplane"], @"wifi": @[@"wifi"], @"airdrop": @[@"airdrop", @"dot.radiowaves.left.and.right"],
                        @"cell": @[@"cellularbars", @"antenna.radiowaves.left.and.right"],
                        @"hotspot": @[@"personalhotspot", @"link"],
                        @"dark": @[@"circle.lefthalf.filled", @"moon.fill"],
                        @"night": @[@"sun.horizon.fill", @"sun.haze.fill", @"moon.stars.fill"],
                        @"truetone": @[@"sun.max.fill"] }[key] ?: @[@"circle.grid.2x2.fill"];
    if ([key isEqualToString:@"bt"]) return BluetoothImage(22);
    for (NSString *n in names) { UIImage *i = [UIImage systemImageNamed:n withConfiguration:cfg]; if (i) return i; }
    return nil;
}

static UIColor *ConnOnColor(NSString *key) {
    if ([key isEqualToString:@"air"]) return UIColor.systemOrangeColor;
    if ([key isEqualToString:@"cell"] || [key isEqualToString:@"hotspot"]) return UIColor.systemGreenColor;
    if ([key isEqualToString:@"night"]) return UIColor.systemOrangeColor;
    if ([key isEqualToString:@"dark"]) return [UIColor colorWithWhite:0.15 alpha:1];
    return UIColor.systemBlueColor;
}

// Settings > Wi-Fi / Bluetooth from Control Center (Control Center closes)
static void OpenSettingsPane(NSString *pane) {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    NSURL *u = [NSURL URLWithString:[@"prefs:root=" stringByAppendingString:pane]];
    BOOL ok = NO;
    Class W = NSClassFromString(@"LSApplicationWorkspace");
    id ws = [W respondsToSelector:@selector(defaultWorkspace)] ? ((id (*)(id, SEL))objc_msgSend)(W, @selector(defaultWorkspace)) : nil;
    SEL os = NSSelectorFromString(@"openSensitiveURL:withOptions:");
    if ([ws respondsToSelector:os]) ok = ((BOOL (*)(id, SEL, id, id))objc_msgSend)(ws, os, u, nil);
    if (!ok) [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
    UIViewController *cc = gCCVC;
    SEL d = @selector(dismissAnimated:withCompletionHandler:);
    if ([cc respondsToSelector:d]) ((void (*)(id, SEL, BOOL, id))objc_msgSend)(cc, d, YES, nil);
}
static NSString *ShortConnName(NSString *t) {
    NSDictionary *m = @{@"Airplane Mode": @"Airplane", @"Personal Hotspot": @"Hotspot", @"Cellular Data": @"Cellular", @"Mobile Data": @"Mobile"};
    return m[t] ?: t;
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

// Press Apple's round button: its control actions if it has any, otherwise
// its tap gesture (Display toggles like Dark Mode use a gesture).
static NSString *gPressDebug = @"-";
static void PressApple(UIControl *round, UIView *labeled) {
    if (round.allTargets.count) {
        [round sendActionsForControlEvents:UIControlEventTouchUpInside];
        [round sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
        gPressDebug = [NSString stringWithFormat:@"actions on %@", NSStringFromClass([round class])];
        return;
    }
    for (UIView *v = round; v; v = v.superview) {
        for (UIGestureRecognizer *gr in v.gestureRecognizers) {
            if (![gr isKindOfClass:[UITapGestureRecognizer class]] || !gr.enabled) continue;
            NSArray *targets = nil;
            @try { targets = [gr valueForKey:@"_targets"]; } @catch (__unused id e) {}
            for (id tg in targets) {
                id target = nil; SEL action = NULL;
                @try { target = [tg valueForKey:@"_target"]; } @catch (__unused id e) {}
                Ivar iv = class_getInstanceVariable([tg class], "_action");
                if (iv) action = *(SEL *)((uint8_t *)(__bridge void *)tg + ivar_getOffset(iv));
                if (!target || !action || ![target respondsToSelector:action] || [NSStringFromClass([target class]) hasPrefix:@"C26"]) continue;
                C26GRProxy *p = [C26GRProxy alloc]; p.gr = gr; p.fakeState = UIGestureRecognizerStateEnded;
                ((void (*)(id, SEL, id))objc_msgSend)(target, action, p);
                gPressDebug = [NSString stringWithFormat:@"tap -[%@ %@]", NSStringFromClass([target class]), NSStringFromSelector(action)];
                return;
            }
        }
        if (v == labeled) break;
    }
    [round sendActionsForControlEvents:UIControlEventTouchUpInside];
    gPressDebug = @"no actions or taps found";
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
    _sheen.masksToBounds = YES;   // stays inside the rounded corners (no stray white lines)
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
    _title.adjustsFontSizeToFitWidth = YES; _title.minimumScaleFactor = 0.8;
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
    BOOL small = S.width < 150;
    self.layer.cornerRadius = _pill ? S.height / 2 : (gStyle18 ? 22 : (small ? 24 : 30));
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _sheen.frame = self.bounds; _sheen.cornerRadius = self.layer.cornerRadius;
    _sheen.hidden = gStyle18;
    self.layer.borderWidth = gStyle18 ? 0 : 1.1;
    [CATransaction commit];
    // a short name when the full one won't fit (Airplane Mode -> Airplane, Personal Hotspot -> Hotspot)
    NSString *full = objc_getAssociatedObject(self, @selector(title)) ?: _title.text;
    CGFloat d = MIN(44, MAX(30, (_pill ? S.height - 20 : S.width * 0.32)));
    CGFloat subW;
    if (_pill) {
        CGFloat lx = small ? 10 : 14;
        _circle.frame = CGRectMake(lx, (S.height - d) / 2, d, d);
        CGFloat x = lx + d + (small ? 8 : 12), w = S.width - x - (small ? 10 : 16);
        NSString *want = full;
        if (full.length && [full sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.5 weight:UIFontWeightMedium]}].width * 0.8 > w) want = ShortConnName(full);
        if (want.length && ![_title.text isEqualToString:want]) _title.text = want;
        _title.frame = CGRectMake(x, S.height / 2 - 20, w, 20);
        subW = MIN(w, [_sub sizeThatFits:CGSizeMake(w, 20)].width);
        _sub.frame = CGRectMake(x, S.height / 2 + 1, subW, 19);
    } else {
        _circle.frame = CGRectMake(14, 14, d, d);
        CGFloat w = S.width - 30;
        if (full.length && ![_title.text isEqualToString:full]) _title.text = full;
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
    // the network name / arrows: open Wi-Fi or Bluetooth settings instead of switching it
    if (([_key isEqualToString:@"wifi"] || [_key isEqualToString:@"bt"]) && _chevron && !_pill) {
        CGRect zone = CGRectInset(CGRectUnion(_sub.frame, _chevron.frame), -14, -14);
        if (CGRectContainsPoint(zone, _touchStart)) { [self relax:0.4]; OpenSettingsPane([_key isEqualToString:@"wifi"] ? @"WIFI" : @"Bluetooth"); return; }
    }
    [self relax:_pill ? 0.9 : 1.6];
    // The icon circle does its own little pop as the state flips.
    C26Spring *c = SpringFor(_circle);
    c.sx = c.sy = 0.78; c.k = 360; c.c = 12; c.tsx = c.tsy = 1;
    WakeSpring(c);
    UIControl *t = self.target;
    BOOL arrow = ([_key isEqualToString:@"wifi"] || [_key isEqualToString:@"bt"]) && _touchStart.y > _sub.frame.origin.y - 8;
    if (arrow) { @try { OpenConnMenu(self.apple, t); } @catch (__unused id e) { gMenuDebug = @"menu threw"; } return; }
    if (t && t.enabled) PressApple(t, self.apple);
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
    // Only the connectivity module (Wi-Fi, Bluetooth...). Others, like the
    // brightness module's Dark Mode / Night Shift / True Tone, stay Apple's.
    BOOL connectivity = NO;
    for (UIView *b in buttons) if ([@[@"air", @"wifi", @"airdrop", @"cell", @"bt", @"hotspot"] containsObject:ConnKey(ConnTitle(b))]) connectivity = YES;
    if (!connectivity) { RemoveConnOverlay(); return; }
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
    CGFloat y = 0;
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
            if (![objc_getAssociatedObject(card, @selector(title)) isEqual:title]) { objc_setAssociatedObject(card, @selector(title), title, OBJC_ASSOCIATION_COPY_NONATOMIC); card.title.text = title; [card setNeedsLayout]; }
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
                // A small, quick settle: fade in from just slightly smaller.
                card.alpha = 0;
                card.transform = CGAffineTransformMakeScale(0.96, 0.96);
                [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.3
                                    options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    card.alpha = a; card.transform = CGAffineTransformIdentity;
                } completion:nil];
            }

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

// the debug box can be dragged anywhere; it stays where you leave it
@interface C26DebugDrag : NSObject @end
@implementation C26DebugDrag
- (void)drag:(UIPanGestureRecognizer *)g {
    UIView *l = g.view;
    CGPoint t = [g translationInView:l.superview];
    l.center = CGPointMake(l.center.x + t.x, l.center.y + t.y);
    [g setTranslation:CGPointZero inView:l.superview];
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setDouble:l.frame.origin.x forKey:@"c26.debugX"]; [d setDouble:l.frame.origin.y forKey:@"c26.debugY"];
    }
}
@end
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
        l.userInteractionEnabled = YES;
        static C26DebugDrag *dd; if (!dd) dd = [C26DebugDrag new];
        [l addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:dd action:@selector(drag:)]];
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSString *text = [NSString stringWithFormat:@" Control26 1.2 debug\n music: %@\n cmds: %@\n conn: %@\n sliders: %@\n edit: %@ cc=%@", gMusicDebug, gCmdDebug, gConnDebug, gSliderDebug, gEditDebug, gCCVC ? NSStringFromClass([gCCVC class]) : @"-"];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    BOOL dragging = NO;
    for (UIGestureRecognizer *gr in l.gestureRecognizers) if (gr.state == UIGestureRecognizerStateBegan || gr.state == UIGestureRecognizerStateChanged) dragging = YES;
    if (!dragging) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        CGFloat x = [d objectForKey:@"c26.debugX"] ? [d doubleForKey:@"c26.debugX"] : 12, y = [d objectForKey:@"c26.debugY"] ? [d doubleForKey:@"c26.debugY"] : 40;
        x = MAX(0, MIN(x, w.bounds.size.width - 60)); y = MAX(0, MIN(y, w.bounds.size.height - 60));
        SetFrame(l, CGRectMake(x, y, width, s.height + 6));
    }
    [w bringSubviewToFront:l];
}

#pragma mark - lock screen star

static BOOL InLockScreen(UIView *v) {
    int d = 0;
    for (UIView *p = v; p && d < 40; p = p.superview, d++) {
        NSString *n = NSStringFromClass([p class]);
        if ([n hasPrefix:@"CS"] || [n containsString:@"CoverSheet"] || [n containsString:@"DashBoard"]) return YES;
    }
    return NO;
}

// iOS 26 lock screen player: a star (Love) right next to the back button.
static void StyleLockStar(UIView *m) {
    C26PassView *o = (C26PassView *)[m viewWithTag:LOCK_TAG];
    if (o.superview != m) o = nil;
    if (!gEnabled || !gMusic) { [o removeFromSuperview]; return; }
    // The lock screen can stay up a long time: ask for song info only every few seconds.
    static CFTimeInterval lastFetch;
    if (CACurrentMediaTime() - lastFetch > 3) { lastFetch = CACurrentMediaTime(); FetchNowPlaying(); }
    NSArray *tr = FindTransport(m);
    if (!o) {
        o = [C26PassView new];
        o.tag = LOCK_TAG;
        UIButton *star = [UIButton buttonWithType:UIButtonTypeCustom];
        star.tag = 24;
        star.tintColor = [UIColor colorWithWhite:1 alpha:0.75];
        [star addTarget:[C26Expanded shared] action:@selector(star:) forControlEvents:UIControlEventTouchUpInside];
        [o addSubview:star];
        [m addSubview:o];
    }
    [m bringSubviewToFront:o];
    SetFrame(o, m.bounds);
    UIButton *star = (UIButton *)[o viewWithTag:24];
    if (tr.count < 3 || ![gNPApp isEqualToString:@"com.apple.Music"]) { star.hidden = YES; return; }
    UIView *a = tr[0], *b = tr[1];
    CGPoint pa = [a.superview convertPoint:a.center toView:m], pb = [b.superview convertPoint:b.center toView:m];
    CGFloat gap = MAX(pb.x - pa.x, 40), d = 44;
    SetFrame(star, CGRectMake(round(pa.x - gap - d / 2), round(pa.y - d / 2), d, d));
    star.hidden = NO;
    BOOL liked = gNPLiked ? gNPLiked.boolValue : (gNPTitle && [gLikedLocally isEqualToString:gNPTitle]);
    NSString *sym = liked ? @"star.fill" : @"star";
    if (![objc_getAssociatedObject(star, kLastValue) isEqual:sym]) {
        objc_setAssociatedObject(star, kLastValue, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [star setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    }
}

#pragma mark - iOS 18/26 edit mode: + and power buttons, resize, Add a Control

typedef struct { unsigned long long width, height; } C26Size;
typedef struct { unsigned long long x, y; } C26Point;
typedef struct { C26Point origin; C26Size size; } C26Rect;

#define TOPPLUS_TAG  0x43323640
#define TOPPOWER_TAG 0x43323641
#define GRID_TAG     0x43323642
#define EDITUI_TAG   0x43323643
#define ADDBTN_TAG   0x43323644
#define ADDSHEET_TAG 0x43323645
#define POWERUI_TAG  0x43323646
#define BIG_TAG      0x43323650
#define PAGES_TAG    0x43323651
#define PAGEDOTS_TAG 0x43323652
#define PRESET_TAG   0x43323653
#define PRESETBTN_TAG 0x43323654
// each page is 4 across and as many rows as fit the screen: 7 on bigger iPhones, 5-6 on 4.7"/5.5" ones
static int PageRows(void) {
    static int rows;
    if (rows) return rows;
    CGSize sc = UIScreen.mainScreen.bounds.size;
    CGFloat W = MIN(sc.width, sc.height), H = MAX(sc.width, sc.height);
    BOOL notch = H / W > 2.0;
    CGFloat pitch = W * 0.225, top = notch ? 180 : 150;
    rows = (int)floor((H - top - 16) / pitch);
    rows = MAX(4, MIN(7, rows));
    return rows;
}
#define PAGE_ROWS (PageRows())
static int PagesWanted(void);
static int PageCount(void);
static void CompactPages(void);
static void ApplyPageVisibility(void);
static void StyleCopies(void);
static int CurrentPage(void);
static void AddCopy(NSString *kind);
static void PlacePresetButton(UIView *e);
static void StyleBigModules(void);
static void PlaceDots(void);

static BOOL gEditing = NO, gResizing = NO, gClosing = NO;
static CFTimeInterval gClosingAt;
static __weak id gSettingsMgr;
static NSMutableDictionary *gProto;          // module id -> "w,h" (Apple's size)
@interface C26EditLock : NSObject @end
@implementation C26EditLock @end
static const void *kEditIdent = &kEditIdent;
static const void *kWiggleOff = &kWiggleOff;

static NSUserDefaults *LayoutDefaults(void) {
    static NSUserDefaults *d;
    if (!d) d = [[NSUserDefaults alloc] initWithSuiteName:@"com.nano.control26.layout"];
    return d;
}
static NSDictionary *SavedSizes(void) { NSDictionary *s = [LayoutDefaults() dictionaryForKey:@"sizes"]; return [s isKindOfClass:[NSDictionary class]] ? s : @{}; }
static BOOL ParseSize(id s, C26Size *out) {
    if (![s isKindOfClass:[NSString class]]) return NO;
    NSArray *p = [s componentsSeparatedByString:@","];
    if (p.count != 2) return NO;
    long w = [p[0] integerValue], h = [p[1] integerValue];
    if (w < 1 || h < 1 || w > 4 || h > 8) return NO;
    out->width = (unsigned long long)w; out->height = (unsigned long long)h;
    return YES;
}

// Sizes: Control Center asks the settings manager how big each module is.
static id (*origModSettings)(id, SEL, id, C26Size);
static id ModSettings(id self, SEL _cmd, id ident, C26Size proto) {
    gSettingsMgr = self;
    id r = origModSettings(self, _cmd, ident, proto);
    @try {
        if (![ident isKindOfClass:[NSString class]] || !r) return r;
        SEL ls = @selector(layoutSizeForInterfaceOrientation:);
        @synchronized ([C26EditLock class]) {
            if (!gProto) gProto = [NSMutableDictionary dictionary];
            if (!gProto[ident] && [r respondsToSelector:ls]) {
                C26Size ps = ((C26Size (*)(id, SEL, long long))objc_msgSend)(r, ls, 1);
                gProto[ident] = [NSString stringWithFormat:@"%llu,%llu", ps.width, ps.height];
            }
        }
        if (!gEnabled || !gEditUI) return r;
        C26Size sz;
        if (!ParseSize(SavedSizes()[ident], &sz)) return r;
        Class C = NSClassFromString(@"CCUIModuleSettings");
        SEL init2 = @selector(initWithPortraitLayoutSize:landscapeLayoutSize:);
        if (!C || ![C instancesRespondToSelector:init2]) return r;
        C26Size land = sz;
        if ([r respondsToSelector:ls]) land = ((C26Size (*)(id, SEL, long long))objc_msgSend)(r, ls, 4);
        id o = ((id (*)(id, SEL, C26Size, C26Size))objc_msgSend)([C alloc], init2, sz, land);
        return o ?: r;
    } @catch (__unused id e) { return r; }
}

static UIViewController *FindCCVC(UIView *v) {
    for (UIResponder *r = v; r; r = r.nextResponder)
        if ([r isKindOfClass:[UIViewController class]] && [NSStringFromClass([r class]) containsString:@"ModularControlCenterOverlayViewController"]) return (UIViewController *)r;
    return nil;
}
static UIViewController *CollectionVC(void) {
    id c = KV(gCCVC, @"moduleCollectionViewController");
    if (!c) {
        Class M = NSClassFromString(@"CCUIModularControlCenterViewController");
        SEL s = NSSelectorFromString(@"_sharedCollectionViewController");
        if ([M respondsToSelector:s]) c = ((id (*)(id, SEL))objc_msgSend)(M, s);
    }
    return [c isKindOfClass:[UIViewController class]] ? c : nil;
}
static UIView *CollectionView(void) {
    UIViewController *c = CollectionVC();
    id v = KV(c, @"moduleCollectionView");
    if (![v isKindOfClass:[UIView class]]) v = c.viewIfLoaded;
    return v;
}
// Where every module is: id -> view, and its spot in Control Center's grid.
#define COPY_PREFIX @"c26.copy."
#define COPYROOT_TAG 0x43323655
static BOOL IsCopy(NSString *k) { return [k isKindOfClass:[NSString class]] && [k hasPrefix:COPY_PREFIX]; }
static NSArray *SavedCopies(void) { NSArray *a = [LayoutDefaults() arrayForKey:@"copies"]; return [a isKindOfClass:[NSArray class]] ? a : @[]; }
static C26Size CopyDefaultSize(NSString *k) { C26Size s = {4, [k containsString:@"connectivity"] ? 4 : 2}; return s; }
static __weak UIView *gCopyRoot;
static NSMutableDictionary *gCopyViews;     // copy id -> our view
static BOOL gNeedRelayout;
static NSDictionary *ModuleMap(void) {
    UIViewController *c = CollectionVC();
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    id d = KV(c, @"moduleContainerViewByIdentifier");
    if ([d isKindOfClass:[NSDictionary class]]) for (id k in d) { id v = d[k]; if ([k isKindOfClass:[NSString class]] && [v isKindOfClass:[UIView class]]) out[k] = v; }
    if (!out.count) {
        id vcs = KV(c, @"moduleViewControllerByIdentifier");
        if ([vcs isKindOfClass:[NSDictionary class]]) for (id k in vcs) { id vc = vcs[k]; UIView *v = [vc isKindOfClass:[UIViewController class]] ? ((UIViewController *)vc).viewIfLoaded : nil; if (v && [k isKindOfClass:[NSString class]]) out[k] = v; }
    }
    for (NSString *k in SavedCopies()) { UIView *v = gCopyViews[k]; if (v.window && !v.hidden) out[k] = v; }
    return out;
}
static BOOL LayoutRectFor(NSString *ident, C26Rect *out) {
    UIViewController *c = CollectionVC();
    SEL s = NSSelectorFromString(@"_activePositionProvider");
    id pp = [c respondsToSelector:s] ? ((id (*)(id, SEL))objc_msgSend)(c, s) : nil;
    SEL l = @selector(layoutRectForIdentifier:);
    if (![pp respondsToSelector:l]) return NO;
    C26Rect r = ((C26Rect (*)(id, SEL, id))objc_msgSend)(pp, l, ident);
    if (r.size.width < 1 || r.size.height < 1 || r.size.width > 8 || r.size.height > 8 || r.origin.x > 8 || r.origin.y > 40) return NO;
    *out = r;
    return YES;
}
typedef struct { CGFloat xs[4]; CGFloat ys[48]; CGFloat pitch, edge; int rows; BOOL ok; } C26Grid;
// a module's frame in another view's space, the same way the handles are placed (center + bounds)
static CGRect ModFrameIn(UIView *m, UIView *to) {
    CGRect r = CGRectMake(m.center.x - m.bounds.size.width / 2, m.center.y - m.bounds.size.height / 2, m.bounds.size.width, m.bounds.size.height);
    return [m.superview convertRect:r toView:to];
}
// the grid, read off where the modules really are: each column's x and each row's y
static C26Grid GridIn(UIView *cv) {
    C26Grid g; memset(&g, 0, sizeof(g));
    UIViewController *c = CollectionVC();
    id lo = KV(c, @"layoutOptions");
    if (!lo) lo = KV(cv, @"layoutOptions");
    CGFloat edge = [KV(lo, @"itemEdgeSize") doubleValue], sp = [KV(lo, @"itemSpacing") doubleValue];
    NSDictionary *mm = ModuleMap();
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *k in mm) {
        UIView *v = mm[k]; C26Rect r;
        if (IsCopy(k) || !v.window || v.hidden || !LayoutRectFor(k, &r)) continue;
        CGRect f = ModFrameIn(v, cv);
        if (edge <= 0 && r.size.width == 1 && r.size.height == 1) edge = f.size.width;
        [items addObject:@[@(r.origin.x), @(r.origin.y), @(r.size.width), @(r.size.height), [NSValue valueWithCGRect:f]]];
    }
    if (!items.count || edge <= 0) return g;
    if (sp <= 0) sp = edge * 0.25;
    BOOL hx[4] = {NO, NO, NO, NO}, hy[48]; memset(hy, 0, sizeof(hy));
    int rows = 0;
    for (NSArray *it in items) {
        int x = [it[0] intValue], y = [it[1] intValue], w = [it[2] intValue], h = [it[3] intValue];
        CGRect f = [it[4] CGRectValue];
        rows = MAX(rows, y + h);
        if (x < 4 && !hx[x]) { g.xs[x] = CGRectGetMinX(f); hx[x] = YES; }
        int ex = x + w - 1; if (ex < 4 && ex >= 0 && !hx[ex]) { g.xs[ex] = CGRectGetMaxX(f) - edge; hx[ex] = YES; }
        if (y < 48 && !hy[y]) { g.ys[y] = CGRectGetMinY(f); hy[y] = YES; }
        int ey = y + h - 1; if (ey < 48 && ey >= 0 && !hy[ey]) { g.ys[ey] = CGRectGetMaxY(f) - edge; hy[ey] = YES; }
    }
    CGFloat pitch = edge + sp;
    // fill the gaps from the nearest known column / row
    for (int i = 0; i < 4; i++) if (!hx[i]) { int k = -1; for (int j = 0; j < 4; j++) if (hx[j] && (k < 0 || abs(j - i) < abs(k - i))) k = j; if (k < 0) return g; g.xs[i] = g.xs[k] + (i - k) * pitch; }
    for (int i = 0; i < 48; i++) if (!hy[i]) { int k = -1; for (int j = 0; j < 48; j++) if (hy[j] && (k < 0 || abs(j - i) < abs(k - i))) k = j; if (k < 0) return g; g.ys[i] = g.ys[k] + (i - k) * pitch; }
    g.edge = edge; g.pitch = pitch; g.rows = rows; g.ok = YES;
    return g;
}
static CGRect GridCell(C26Grid g, int col, int row) {
    col = MAX(0, MIN(3, col)); row = MAX(0, MIN(47, row));
    return CGRectMake(g.xs[col], g.ys[row], g.edge, g.edge);
}
// what sizes each control can be (the sliders stay as they are)
static NSArray *AllowedSizesAll(NSString *ident);
static NSArray *AllowedSizes(NSString *ident) {
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *z in AllowedSizesAll(ident)) if ([[z componentsSeparatedByString:@","].lastObject intValue] <= PAGE_ROWS) [out addObject:z];
    return out;
}
static NSArray *AllowedSizesAll(NSString *ident) {
    NSString *l = ident.lowercaseString;
    if (IsCopy(ident)) return [l containsString:@"connectivity"] ? @[@"4,4", @"4,6", @"4,7"] : @[@"4,2", @"4,4", @"4,6", @"4,7"];
    if ([l containsString:@"audio"] || [l containsString:@"volume"] || [l hasSuffix:@".displaymodule"] || [l containsString:@"brightness"]) return @[];
    if ([l containsString:@"connectivity"]) return @[@"2,2", @"4,4", @"4,6", @"4,7"];
    if ([l containsString:@"nowplaying"] || [l containsString:@"mediacontrols"]) return @[@"2,2", @"4,2", @"4,4", @"4,6", @"4,7"];
    return @[@"1,1", @"2,1", @"1,2", @"2,2", @"4,2", @"4,4"];
}

// Module lists (what Settings > Control Center edits)
static id CCProvider(void) {
    Class P = NSClassFromString(@"CCSModuleSettingsProvider");
    return [P respondsToSelector:@selector(sharedProvider)] ? ((id (*)(id, SEL))objc_msgSend)(P, @selector(sharedProvider)) : nil;
}
static NSArray *IdList(NSString *key) { id a = KV(CCProvider(), key); return [a isKindOfClass:[NSArray class]] ? a : @[]; }
static void SetUserEnabled(NSArray *a) {
    id p = CCProvider();
    SEL s = @selector(setAndSaveOrderedUserEnabledModuleIdentifiers:);
    if ([p respondsToSelector:s]) ((void (*)(id, SEL, id))objc_msgSend)(p, s, a);
}

static void UpdateEditUI(BOOL animated);
static void RelayoutCC(void) {
    UIViewController *c = CollectionVC();
    if (!c || gClosing || !gCCVC.viewIfLoaded.window) return;
    Class IM = NSClassFromString(@"CCUIModuleInstanceManager");
    id im = [IM respondsToSelector:@selector(sharedInstance)] ? ((id (*)(id, SEL))objc_msgSend)(IM, @selector(sharedInstance)) : nil;
    SEL lay = @selector(moduleInstancesLayoutChangedForModuleInstanceManager:);
    SEL ref = NSSelectorFromString(@"_refreshPositionProviders");
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        @try {
            UIViewController *ov = gCCVC;
            if (ov && [ov respondsToSelector:lay]) ((void (*)(id, SEL, id))objc_msgSend)(ov, lay, im);
            else if ([c respondsToSelector:lay]) ((void (*)(id, SEL, id))objc_msgSend)(c, lay, im);
            if ([c respondsToSelector:ref]) ((void (*)(id, SEL))objc_msgSend)(c, ref);
            UIView *cv = CollectionView();
            [cv setNeedsLayout]; [cv layoutIfNeeded];
            [ov.viewIfLoaded setNeedsLayout]; [ov.viewIfLoaded layoutIfNeeded];
            StyleCopies();
            UpdateEditUI(NO);
        } @catch (__unused id e) {}
    } completion:nil];
}
// ---- free placement: our own layout, so a control can sit anywhere (gaps allowed) ----
// pos: module id -> "x,y" where you put it; posOrder: newest first (it wins when two overlap).
// Everything without a spot fills the first free gaps, in Control Center's own order.
static const void *kFreeMap = &kFreeMap, *kFreeRows = &kFreeRows;
static NSDictionary *SavedPos(void) { NSDictionary *d = [LayoutDefaults() dictionaryForKey:@"pos"]; return [d isKindOfClass:[NSDictionary class]] ? d : @{}; }
static NSArray *SavedPosOrder(void) { NSArray *a = [LayoutDefaults() arrayForKey:@"posOrder"]; return [a isKindOfClass:[NSArray class]] ? a : @[]; }
static NSDictionary *FreeLayout(NSArray *ids, NSArray *sizes, int cols, int *outRows) {
    NSDictionary *pos = SavedPos();
    NSArray *cps = SavedCopies();
    if ((!pos.count && PagesWanted() <= 1 && !cps.count) || ids.count != sizes.count) return nil;
    if (cps.count) {
        NSMutableArray *i2 = [ids mutableCopy], *s2 = [sizes mutableCopy];
        NSDictionary *ss = SavedSizes();
        for (NSString *c in cps) { C26Size sz; if (!ParseSize(ss[c], &sz)) sz = CopyDefaultSize(c); [i2 addObject:c]; [s2 addObject:[NSValue valueWithBytes:&sz objCType:@encode(C26Size)]]; }
        ids = i2; sizes = s2;
    }
    enum { MR = 64 };
    static BOOL occ[MR][8];
    memset(occ, 0, sizeof(occ));
    NSMutableDictionary *sz = [NSMutableDictionary dictionary], *out = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < ids.count; i++) {
        C26Size s = {1, 1};
        id v = sizes[i];
        if ([v isKindOfClass:[NSValue class]]) [(NSValue *)v getValue:&s size:sizeof(s)];
        if (s.width < 1) s.width = 1;
        if (s.height < 1) s.height = 1;
        if (s.width > (unsigned long long)cols) s.width = cols;
        if (s.height > PAGE_ROWS) s.height = PAGE_ROWS;
        sz[ids[i]] = [NSValue valueWithBytes:&s objCType:@encode(C26Size)];
    }
    BOOL (^fits)(int, int, int, int) = ^BOOL(int x, int y, int w, int h) {
        if (x < 0 || y < 0 || x + w > cols || y + h > 6 * PAGE_ROWS) return NO;
        if (y / PAGE_ROWS != (y + h - 1) / PAGE_ROWS) return NO;   // stays on one page
        for (int yy = y; yy < y + h; yy++) for (int xx = x; xx < x + w; xx++) if (occ[yy][xx]) return NO;
        return YES;
    };
    void (^put)(NSString *, int, int, int, int) = ^(NSString *k, int x, int y, int w, int h) {
        for (int yy = y; yy < y + h; yy++) for (int xx = x; xx < x + w; xx++) occ[yy][xx] = YES;
        C26Rect r = {{(unsigned long long)x, (unsigned long long)y}, {(unsigned long long)w, (unsigned long long)h}};
        out[k] = [NSValue valueWithBytes:&r objCType:@encode(C26Rect)];
    };
    NSMutableArray *order = [SavedPosOrder() mutableCopy];
    for (NSString *k in pos) if (![order containsObject:k]) [order addObject:k];
    int rows = 0;
    for (NSString *k in order) {
        NSValue *v = sz[k]; id p = pos[k];
        if (!v || ![p isKindOfClass:[NSString class]]) continue;
        C26Size s; [v getValue:&s size:sizeof(s)];
        NSArray *xy = [p componentsSeparatedByString:@","];
        if (xy.count != 2) continue;
        int x = [xy[0] intValue], y = [xy[1] intValue];
        if (x + (int)s.width > cols) x = cols - (int)s.width;
        if (fits(x, y, (int)s.width, (int)s.height)) { put(k, x, y, (int)s.width, (int)s.height); rows = MAX(rows, y + (int)s.height); }
    }
    for (NSString *k in ids) {
        if (out[k]) continue;
        C26Size s; [sz[k] getValue:&s size:sizeof(s)];
        BOOL done = NO;
        for (int y = 0; y < MR && !done; y++) for (int x = 0; x + (int)s.width <= cols && !done; x++)
            if (fits(x, y, (int)s.width, (int)s.height)) { put(k, x, y, (int)s.width, (int)s.height); rows = MAX(rows, y + (int)s.height); done = YES; }
    }
    if (rows > PAGE_ROWS || PagesWanted() > 1) rows = MAX((rows + PAGE_ROWS - 1) / PAGE_ROWS, PagesWanted()) * PAGE_ROWS + 1;   // whole pages (+1 so the last one can scroll fully up)
    if (outRows) *outRows = rows;
    return out;
}
static BOOL IsPortraitProvider(id pp) {
    UIViewController *c = CollectionVC();
    SEL s = NSSelectorFromString(@"_positionProviderForInterfaceOrientation:");
    if (c && [c respondsToSelector:s]) return ((id (*)(id, SEL, long long))objc_msgSend)(c, s, 1) == pp;
    SEL m = NSSelectorFromString(@"maximumLayoutSize");
    if ([pp respondsToSelector:m]) { C26Size mx = ((C26Size (*)(id, SEL))objc_msgSend)(pp, m); return mx.width == 4; }
    return NO;
}
static void (*origRegen)(id, SEL, id, id);
static void Regen(id self, SEL _cmd, id ids, id sizes) {
    origRegen(self, _cmd, ids, sizes);
    @try {
        NSDictionary *m = nil; int rows = 0;
        if (gEnabled && gEditUI && [ids isKindOfClass:[NSArray class]] && [sizes isKindOfClass:[NSArray class]] && IsPortraitProvider(self))
            m = FreeLayout(ids, sizes, 4, &rows);
        objc_setAssociatedObject(self, kFreeMap, m, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, kFreeRows, m ? @(rows) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } @catch (__unused id e) {}
}
static C26Rect (*origLRect)(id, SEL, id);
static C26Rect LRect(id self, SEL _cmd, id ident) {
    NSDictionary *m = objc_getAssociatedObject(self, kFreeMap);
    NSValue *v = ident ? m[ident] : nil;
    if (v) { C26Rect r; [v getValue:&r size:sizeof(r)]; return r; }
    return origLRect(self, _cmd, ident);
}
static C26Size (*origLSize)(id, SEL);
static C26Size LSize(id self, SEL _cmd) {
    C26Size s = origLSize(self, _cmd);
    NSNumber *rows = objc_getAssociatedObject(self, kFreeRows);
    if (rows && rows.intValue > 0) s.height = (unsigned long long)rows.intValue;
    return s;
}
// pin every control where it is now (the first time you move one)
static void FreezeLayout(void) {
    NSMutableDictionary *pos = [NSMutableDictionary dictionary];
    NSMutableArray *items = [NSMutableArray array];
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) {
        C26Rect r;
        if (!LayoutRectFor(k, &r)) continue;
        pos[k] = [NSString stringWithFormat:@"%llu,%llu", r.origin.x, r.origin.y];
        [items addObject:@[k, @(r.origin.y * 8 + r.origin.x)]];
    }
    [items sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) { return [a[1] compare:b[1]]; }];
    NSMutableArray *order = [NSMutableArray array];
    for (NSArray *it in items) [order addObject:it[0]];
    [LayoutDefaults() setObject:pos forKey:@"pos"];
    [LayoutDefaults() setObject:order forKey:@"posOrder"];
}
static void SetPos(NSString *ident, int x, int y) {
    if (!SavedPos().count) FreezeLayout();
    NSMutableDictionary *pos = [SavedPos() mutableCopy];
    NSMutableArray *order = [SavedPosOrder() mutableCopy];
    pos[ident] = [NSString stringWithFormat:@"%d,%d", x, y];
    [order removeObject:ident]; [order insertObject:ident atIndex:0];
    [LayoutDefaults() setObject:pos forKey:@"pos"];
    [LayoutDefaults() setObject:order forKey:@"posOrder"];
}
// a control you resize keeps its spot and pushes the others away
static void PinFront(NSString *ident) {
    NSDictionary *pos = SavedPos();
    if (!pos.count) return;
    C26Rect r;
    if (LayoutRectFor(ident, &r)) SetPos(ident, (int)r.origin.x, (int)r.origin.y);
}
// after a move: everyone stays where they ended up
static void RePinAll(void) {
    if (!SavedPos().count) return;
    NSArray *order = SavedPosOrder();
    NSMutableDictionary *pos = [NSMutableDictionary dictionary];
    for (NSString *k in ModuleMap()) { C26Rect r; if (LayoutRectFor(k, &r)) pos[k] = [NSString stringWithFormat:@"%llu,%llu", r.origin.x, r.origin.y]; }
    NSMutableArray *o2 = [order mutableCopy];
    for (NSString *k in pos) if (![o2 containsObject:k]) [o2 addObject:k];
    [LayoutDefaults() setObject:pos forKey:@"pos"];
    [LayoutDefaults() setObject:o2 forKey:@"posOrder"];
}

static void SaveSize(NSString *ident, C26Size s) {
    NSMutableDictionary *d = [SavedSizes() mutableCopy];
    NSString *v = [NSString stringWithFormat:@"%llu,%llu", s.width, s.height];
    NSString *pv; @synchronized ([C26EditLock class]) { pv = gProto[ident]; }
    if ([pv isEqualToString:v]) [d removeObjectForKey:ident]; else d[ident] = v;
    [LayoutDefaults() setObject:d forKey:@"sizes"];
}

// glass circle / capsule button
static UIButton *GlassButton(NSString *symbol, CGFloat pt) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    UIVisualEffectView *fx = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    fx.userInteractionEnabled = NO; fx.clipsToBounds = YES; fx.tag = 1;
    fx.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    fx.layer.borderWidth = 1; fx.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    fx.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [b addSubview:fx];
    if (symbol) [b setImage:[UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor;
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.layer.cornerCurve = kCACornerCurveContinuous;
    return b;
}
static void RoundGlass(UIButton *b) {
    UIView *fx = [b viewWithTag:1];
    fx.frame = b.bounds;
    fx.layer.borderWidth = gStyle18 ? 0 : 1;
    fx.layer.cornerRadius = MIN(b.bounds.size.width, b.bounds.size.height) / 2;
    if (b.imageView) [b bringSubviewToFront:b.imageView];
    if (b.titleLabel) [b bringSubviewToFront:b.titleLabel];
    NGApply(fx);   // 1.2.2: with LiquidAss, the same liquid glass as MusicPill
}
static void Pop(UIView *v) {
    [UIView animateWithDuration:0.12 animations:^{ v.transform = CGAffineTransformMakeScale(0.88, 0.88); } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:0 animations:^{ v.transform = CGAffineTransformIdentity; } completion:nil];
    }];
}

static void EnterEdit(void);
static void ExitEdit(BOOL animated);
static UIView *EditRoot(BOOL make);
static void ShowPowerOff(void);
static void ShowAddSheet(void);
static CGAffineTransform SheetFromButton(UIView *panel);
static void RemoveModule(NSString *ident);

@interface C26EditCtl : NSObject
+ (instancetype)shared;
@end
static NSString *gMoveIdent;
static const void *kPageMask;
// the control under a point (edit layer space): the smallest one, on the page you're looking at
static NSString *ModuleAtPoint(CGPoint p) {
    UIView *e = EditRoot(NO);
    if (!e) return nil;
    NSDictionary *mm = ModuleMap();
    NSString *best = nil; CGFloat area = CGFLOAT_MAX;
    for (NSString *k in mm) {
        UIView *m = mm[k];
        if (!m.window || m.hidden) continue;
        CALayer *pm = objc_getAssociatedObject(m, kPageMask);
        if (pm && m.layer.mask == pm && pm.opacity < 0.5) continue;
        CGRect f = ModFrameIn(m, e);
        if (!CGRectContainsPoint(CGRectInset(f, -4, -4), p)) continue;
        if (f.size.width * f.size.height < area) { area = f.size.width * f.size.height; best = k; }
    }
    return best;
}
@interface C26MoveGate : NSObject <UIGestureRecognizerDelegate>
@end
@implementation C26MoveGate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if (!gEditing || gClosing) return NO;
    UIView *root = gCCVC.viewIfLoaded, *e = EditRoot(NO);
    if (!root || !e || e.hidden) return NO;
    if ([root viewWithTag:ADDSHEET_TAG] || [root viewWithTag:PRESET_TAG] || [root viewWithTag:POWERUI_TAG]) return NO;
    CGPoint p = [g locationInView:e];
    UIView *h = [root hitTest:[g locationInView:root] withEvent:nil];
    for (UIView *x = h; x && x != root; x = x.superview) {
        if ([x isKindOfClass:[UIControl class]]) return NO;              // + / power / page icons / badges
        if (x.superview == e && (x.tag == 1 || x.tag == 2)) return NO;    // resize handle, minus badge
    }
    return ModuleAtPoint(p) != nil;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return NO; }
@end
static void InstallMoveGesture(void) {
    UIView *root = gCCVC.viewIfLoaded;
    if (!root) return;
    for (UIGestureRecognizer *x in root.gestureRecognizers) if ([x.name isEqualToString:@"c26.move"]) { x.enabled = YES; return; }
    static C26MoveGate *gate; if (!gate) gate = [C26MoveGate new];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[C26EditCtl shared] action:@selector(move:)];
    lp.name = @"c26.move"; lp.minimumPressDuration = 0.2; lp.allowableMovement = 14;
    lp.cancelsTouchesInView = YES; lp.delegate = gate;
    [root addGestureRecognizer:lp];
}
@implementation C26EditCtl {
    C26Size _start, _last;
    CGFloat _px, _py;
    CGPoint _grab;
    NSString *_hover;
    CGFloat _scroll0;
}
+ (instancetype)shared { static C26EditCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26EditCtl new]; }); return s; }
- (void)plus:(UIButton *)b { Pop(b); [[UISelectionFeedbackGenerator new] selectionChanged]; if (gEditing) ExitEdit(YES); else EnterEdit(); }
- (void)power:(UIButton *)b { Pop(b); [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred]; ShowPowerOff(); }
- (void)add:(UIButton *)b { Pop(b); ShowAddSheet(); }
- (void)minus:(UIButton *)b {
    NSString *ident = objc_getAssociatedObject(b, kEditIdent);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (ident) RemoveModule(ident);
}
- (void)resize:(UIPanGestureRecognizer *)g {
    NSString *ident = objc_getAssociatedObject(g.view, kEditIdent);
    UIView *cv = CollectionView();
    if (!ident || !cv) return;
    if (g.state == UIGestureRecognizerStateBegan) {
        gResizing = YES;
        C26Grid gr = GridIn(cv);
        _px = _py = MAX(20, gr.pitch);
        C26Rect lr;
        if (LayoutRectFor(ident, &lr)) _start = lr.size; else { _start.width = 1; _start.height = 1; }
        _last = _start;
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        return;
    }
    if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [g translationInView:cv];
        double w = _start.width + t.x / _px, h = _start.height + t.y / _py;
        C26Size n = _last; double bestD = 1e9;
        for (NSString *a in AllowedSizes(ident)) {
            C26Size c; if (!ParseSize(a, &c)) continue;
            double d = ((double)c.width - w) * ((double)c.width - w) + ((double)c.height - h) * ((double)c.height - h);
            if (d < bestD) { bestD = d; n = c; }
        }
        if (n.width != _last.width || n.height != _last.height) {
            _last = n;
            PinFront(ident);
            SaveSize(ident, n);
            [[UISelectionFeedbackGenerator new] selectionChanged];
            RelayoutCC();
        }
        return;
    }
    gResizing = NO;
    UpdateEditUI(YES);
}
// hold and drag a control anywhere: it lands on the spot under it (gaps are fine), the ones in
// the way step aside while you drag, and everything stays put when you let go
// swiping over a control while editing scrolls Control Center (with a little glide at the end)
- (void)scroll:(UIPanGestureRecognizer *)g {
    if (gResizing) return;
    UIScrollView *sv = KV(gCCVC, @"overlayScrollView");
    if (![sv isKindOfClass:[UIScrollView class]]) return;
    CGFloat minY = -sv.adjustedContentInset.top, maxY = MAX(minY, sv.contentSize.height + sv.adjustedContentInset.bottom - sv.bounds.size.height);
    if (g.state == UIGestureRecognizerStateBegan) { [sv.layer removeAllAnimations]; _scroll0 = sv.contentOffset.y; return; }
    CGFloat y = _scroll0 - [g translationInView:sv.superview].y;
    if (y < minY) y = minY - (minY - y) * 0.35;
    if (y > maxY) y = maxY + (y - maxY) * 0.35;
    if (g.state == UIGestureRecognizerStateChanged) { sv.contentOffset = CGPointMake(sv.contentOffset.x, y); return; }
    CGFloat v = [g velocityInView:sv.superview].y;
    CGFloat end = MIN(maxY, MAX(minY, y - v * 0.22));
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ sv.contentOffset = CGPointMake(sv.contentOffset.x, end); } completion:^(__unused BOOL f) { UpdateEditUI(NO); }];
}
- (void)move:(UIGestureRecognizer *)g {
    NSString *ident = objc_getAssociatedObject(g.view, kEditIdent);
    if (!ident) {
        if (g.state == UIGestureRecognizerStateBegan) gMoveIdent = ModuleAtPoint([g locationInView:EditRoot(NO)]);
        ident = gMoveIdent;
        if (g.state != UIGestureRecognizerStateBegan && g.state != UIGestureRecognizerStateChanged) gMoveIdent = nil;
    }
    UIView *e = EditRoot(NO), *cv = CollectionView();
    NSDictionary *mm = ModuleMap();
    UIView *mv = mm[ident];
    if (!ident || !mv || !e || !cv) return;
    CGPoint p = [g locationInView:e];
    if (g.state == UIGestureRecognizerStateBegan) {
        gResizing = YES;
        if (!SavedPos().count) FreezeLayout();
        CGRect f = ModFrameIn(mv, e);
        _grab = CGPointMake(p.x - CGRectGetMidX(f), p.y - CGRectGetMidY(f));
        _hover = nil;
        mv.layer.zPosition = 500;
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
        for (UIView *x in e.subviews) if ([objc_getAssociatedObject(x, kEditIdent) isEqual:ident] && x != g.view) x.hidden = YES;
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ mv.transform = CGAffineTransformMakeScale(1.08, 1.08); } completion:nil];
        return;
    }
    if (g.state == UIGestureRecognizerStateChanged) {
        CGRect f = ModFrameIn(mv, e);
        CGPoint want = CGPointMake(p.x - _grab.x, p.y - _grab.y);
        mv.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.08, 1.08), CGAffineTransformMakeTranslation(want.x - CGRectGetMidX(f), want.y - CGRectGetMidY(f)));
        // the spot under the control's top-left corner
        C26Grid gr = GridIn(cv);
        C26Rect lr;
        if (!gr.ok || !LayoutRectFor(ident, &lr)) return;
        CGPoint tl = [e convertPoint:CGPointMake(want.x - f.size.width / 2, want.y - f.size.height / 2) toView:cv];
        int col = 0, row = 0; CGFloat bx = CGFLOAT_MAX, by = CGFLOAT_MAX;
        for (int i = 0; i < 4; i++) { CGFloat d = fabs(gr.xs[i] - tl.x); if (d < bx) { bx = d; col = i; } }
        for (int i = 0; i < 6 * PAGE_ROWS; i++) { CGFloat d = fabs(gr.ys[i] - tl.y); if (d < by) { by = d; row = i; } }
        col = MAX(0, MIN(col, 4 - (int)lr.size.width));
        NSString *key = [NSString stringWithFormat:@"%d,%d", col, row];
        if (![key isEqualToString:_hover]) {
            _hover = key;
            SetPos(ident, col, row);
            [[UISelectionFeedbackGenerator new] selectionChanged];
            RelayoutCC();
        }
        return;
    }
    gResizing = NO; _hover = nil;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ mv.transform = CGAffineTransformIdentity; } completion:^(__unused BOOL f) { mv.layer.zPosition = 0; }];
    for (UIView *x in e.subviews) if ([objc_getAssociatedObject(x, kEditIdent) isEqual:ident]) x.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RePinAll(); UpdateEditUI(YES); });
}
- (void)closeSheet:(id)x {
    UIView *sheet = [gCCVC.viewIfLoaded viewWithTag:ADDSHEET_TAG];
    UIView *panel = [sheet viewWithTag:2];
    if (!sheet || objc_getAssociatedObject(sheet, kEditIdent)) return;
    objc_setAssociatedObject(sheet, kEditIdent, @"closing", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CGAffineTransform to = SheetFromButton(panel);
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.92 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        sheet.backgroundColor = UIColor.clearColor;
        panel.transform = to;
        panel.alpha = 0;
    } completion:^(__unused BOOL f) { [sheet removeFromSuperview]; UpdateEditUI(YES); }];
}
- (void)pick:(UIButton *)b {
    NSString *ident = objc_getAssociatedObject(b, kEditIdent);
    if (!ident) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    if ([ident hasPrefix:@"copy:"]) { NSString *kind = [ident substringFromIndex:5]; [self closeSheet:nil]; dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ AddCopy(kind); }); return; }
    NSMutableArray *a = [IdList(@"orderedUserEnabledModuleIdentifiers") mutableCopy];
    if (![a containsObject:ident]) [a addObject:ident];
    SetUserEnabled(a);
    [self closeSheet:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RelayoutCC(); });
}
@end

static void RemoveModule(NSString *ident) {
    if (IsCopy(ident)) {
        NSMutableArray *c = [SavedCopies() mutableCopy]; [c removeObject:ident]; [LayoutDefaults() setObject:c forKey:@"copies"];
        NSMutableDictionary *p = [SavedPos() mutableCopy]; [p removeObjectForKey:ident]; [LayoutDefaults() setObject:p forKey:@"pos"];
        UIView *v = gCopyViews[ident];
        [UIView animateWithDuration:0.25 animations:^{ v.alpha = 0; v.transform = CGAffineTransformMakeScale(0.8, 0.8); } completion:^(__unused BOOL f) { [v removeFromSuperview]; }];
        [gCopyViews removeObjectForKey:ident];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RelayoutCC(); });
        return;
    }
    NSMutableArray *a = [IdList(@"orderedUserEnabledModuleIdentifiers") mutableCopy];
    if (![a containsObject:ident]) return;
    [a removeObject:ident];
    SetUserEnabled(a);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RelayoutCC(); });
}

// + (top left) and power (top right), between the status bar and the first row
static void PlaceTopButtons(UIViewController *vc) {
    if (!vc.isViewLoaded) return;
    // they sit above Control Center's content area, so they live in its root view (taps outside
    // the content area never reached them before)
    UIView *host = vc.view;
    { UIView *old = KV(vc, @"overlayContainerView"); if ([old isKindOfClass:[UIView class]] && old != host) { [[old viewWithTag:TOPPLUS_TAG] removeFromSuperview]; [[old viewWithTag:TOPPOWER_TAG] removeFromSuperview]; } }
    UIButton *plus = (UIButton *)[host viewWithTag:TOPPLUS_TAG], *pw = (UIButton *)[host viewWithTag:TOPPOWER_TAG];
    if (!gEnabled || !gEditUI) { [plus removeFromSuperview]; [pw removeFromSuperview]; return; }
    UIView *cv = CollectionView();
    UIWindow *w = host.window;
    if (!w || cv.window != w) return;
    if (!plus) {
        plus = GlassButton(@"plus", 17); plus.tag = TOPPLUS_TAG;
        [plus addTarget:[C26EditCtl shared] action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
        [host addSubview:plus];
    }
    if (!pw) {
        pw = GlassButton(@"power", 17); pw.tag = TOPPOWER_TAG;
        [pw addTarget:[C26EditCtl shared] action:@selector(power:) forControlEvents:UIControlEventTouchUpInside];
        [host addSubview:pw];
    }
    BOOL landscape = w.bounds.size.width > w.bounds.size.height;
    plus.hidden = landscape; pw.hidden = landscape;
    if (landscape) return;
    C26Grid gr = GridIn(cv);
    if (!gr.ok) return;
    CGRect r0 = [cv convertRect:GridCell(gr, 0, 0) toView:nil], r3 = [cv convertRect:GridCell(gr, 3, 0) toView:nil];
    CGFloat d = 38;
    // on the top status bar line (where iOS 18/26 puts them), lined up with the outer columns
    CGFloat top = w.safeAreaInsets.top;
    CGFloat cy = top > 30 ? top - 6 : MAX(top, 20) + 6;
    CGRect pf = [w convertRect:CGRectMake(CGRectGetMinX(r0) + 4, cy - d / 2, d, d) toView:host];
    CGRect wf = [w convertRect:CGRectMake(CGRectGetMaxX(r3) - d - 4, cy - d / 2, d, d) toView:host];
    if (!CGRectEqualToRect(plus.frame, pf) && CGAffineTransformIsIdentity(plus.transform)) { plus.frame = pf; RoundGlass(plus); }
    if (!CGRectEqualToRect(pw.frame, wf) && CGAffineTransformIsIdentity(pw.transform)) { pw.frame = wf; RoundGlass(pw); }
    NSString *sym = gEditing ? @"checkmark" : @"plus";
    if (![objc_getAssociatedObject(plus, kEditIdent) isEqual:sym]) {
        objc_setAssociatedObject(plus, kEditIdent, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [UIView transitionWithView:plus duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [plus setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
        } completion:nil];
    }
    if (gClosing) {
        if (CACurrentMediaTime() - gClosingAt > 1.2 && !w.hidden) gClosing = NO;
        else { plus.alpha = 0; pw.alpha = 0; return; }
    }
    // fade with Control Center's content (it fades in and out when opening / closing)
    CGFloat a = 1;
    for (UIView *q = cv; q && q != host; q = q.superview) a *= q.alpha;
    if (fabs(plus.alpha - a) > 0.01 && ![plus.layer animationForKey:@"opacity"]) { plus.alpha = a; pw.alpha = a; }
    if (host.subviews.lastObject != pw) { [host bringSubviewToFront:plus]; [host bringSubviewToFront:pw]; }
    if (!gEditing) gEditDebug = [NSString stringWithFormat:@"top cy=%.0f safeTop=%.0f row0=%.0f,%.0f", cy, top, r0.origin.x, r0.origin.y];
}

// the faint circles in the empty spots. They live in our own layer: inside Control Center's
// module view they got moved by its layout and crashed SpringBoard when it closed.
static const void *kGridSize = &kGridSize;
static void BuildGrid(UIView *cv, UIView *e) {
    if (!e || !cv) return;
    UIView *g = [e viewWithTag:GRID_TAG];
    if (!g) {
        g = [[UIView alloc] initWithFrame:CGRectZero];
        g.tag = GRID_TAG; g.userInteractionEnabled = NO; g.clipsToBounds = NO;
        [e insertSubview:g atIndex:0];
    }
    if (e.subviews.firstObject != g) [e sendSubviewToBack:g];
    C26Grid gr = GridIn(cv);
    if (!gr.ok) return;
    NSMutableSet *taken = [NSMutableSet set];
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) {
        C26Rect r; UIView *v = mm[k];
        if (!v.window || v.hidden || !LayoutRectFor(k, &r)) continue;
        for (unsigned long long y = r.origin.y; y < r.origin.y + r.size.height; y++)
            for (unsigned long long x = r.origin.x; x < r.origin.x + r.size.width; x++) [taken addObject:[NSString stringWithFormat:@"%llu,%llu", x, y]];
    }
    int rows = MIN(6 * PAGE_ROWS, PAGE_ROWS * PageCount());
    // where Control Center's content starts right now (it can scroll)
    CGPoint o = [cv convertPoint:CGPointZero toView:e];
    g.frame = CGRectMake(o.x, o.y, 10, 10);
    NSString *sig = [NSString stringWithFormat:@"%.1f,%.1f,%.1f,%d|%@", gr.xs[0], gr.ys[0], gr.pitch, rows, [[taken allObjects] sortedArrayUsingSelector:@selector(compare:)]];
    if ([objc_getAssociatedObject(g, kEditIdent) isEqual:sig]) return;
    BOOL first = objc_getAssociatedObject(g, kEditIdent) == nil;
    objc_setAssociatedObject(g, kEditIdent, sig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    for (CALayer *l in [g.layer.sublayers copy]) [l removeFromSuperlayer];
    int i = 0;
    for (int y = 0; y < rows; y++) for (int x = 0; x < 4; x++) {
        if ([taken containsObject:[NSString stringWithFormat:@"%d,%d", x, y]]) continue;
        CGRect c = CGRectInset(GridCell(gr, x, y), 2, 2);
        CALayer *l = [CALayer layer];
        l.frame = c; l.cornerRadius = c.size.width / 2; l.name = [NSString stringWithFormat:@"p%d", y / PAGE_ROWS];
        l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.075].CGColor;
        l.borderWidth = 1; l.borderColor = [UIColor colorWithWhite:1 alpha:0.10].CGColor;
        [g.layer addSublayer:l];
        if (first) {
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"opacity"];
            a.fromValue = @0; a.toValue = @1; a.duration = 0.35; a.beginTime = CACurrentMediaTime() + MIN(i, 20) * 0.012; a.fillMode = kCAFillModeBackwards;
            [l addAnimation:a forKey:@"in"];
        }
        i++;
    }
}

static UIView *EditRoot(BOOL make) {
    UIView *root = gCCVC.viewIfLoaded;
    if (!root) return nil;
    UIView *e = [root viewWithTag:EDITUI_TAG];
    if (!e && make) {
        e = [[C26PassView alloc] initWithFrame:root.bounds];
        e.tag = EDITUI_TAG;
        e.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [root addSubview:e];
    }
    return e;
}
static UIView *HandleView(void) {
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
    CAShapeLayer *arc = [CAShapeLayer layer];
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(8, 27)];
    [p addQuadCurveToPoint:CGPointMake(27, 8) controlPoint:CGPointMake(27, 27)];
    arc.path = p.CGPath; arc.fillColor = UIColor.clearColor.CGColor;
    arc.strokeColor = UIColor.whiteColor.CGColor; arc.lineWidth = 4.5; arc.lineCap = kCALineCapRound;
    arc.shadowColor = UIColor.blackColor.CGColor; arc.shadowOpacity = 0.35; arc.shadowRadius = 3; arc.shadowOffset = CGSizeZero;
    [h.layer addSublayer:arc];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[C26EditCtl shared] action:@selector(resize:)];
    pan.maximumNumberOfTouches = 1;
    [h addGestureRecognizer:pan];
    return h;
}

// the control's own outline: its background's corner radius (round buttons come out round)
// ---- module shapes: round 1x1 controls, capsule sliders, rounded bigger modules (iOS 18 / 26), works without other tweaks ----
static BOOL OtherGlassTweak(void) {
    static int v = -1;
    if (v < 0) { v = 0; for (uint32_t i = 0; i < _dyld_image_count(); i++) { const char *n = _dyld_get_image_name(i); if (n && (strcasestr(n, "liquidass") || strcasestr(n, "liquidglass"))) { v = 1; break; } } }
    return v == 1;
}
static void ShapeModule(UIView *m, BOOL on) {
    CALayer *rim = nil;
    for (CALayer *l in m.layer.sublayers) if ([l.name isEqualToString:@"c26.rim"]) rim = l;
    CGSize S = m.bounds.size;
    if (!on || S.width < 20 || S.height < 20) { [rim removeFromSuperlayer]; return; }
    CGFloat mn = MIN(S.width, S.height);
    CGFloat radius = mn < 100 ? mn / 2 : MIN(gStyle18 ? 36 : 40, mn * 0.25);
    // Apple's own backgrounds (material views) take the shape
    NSMutableArray *st = [NSMutableArray arrayWithObject:m]; int n = 0;
    while (st.count && n++ < 60) {
        UIView *v = st.firstObject; [st removeObjectAtIndex:0];
        if (v.tag == BIG_TAG) continue;
        BOOL full = v.bounds.size.width >= S.width * 0.9 && v.bounds.size.height >= S.height * 0.9;
        if (!full) continue;
        NSString *cn = NSStringFromClass(v.class);
        if (v != m && ([cn containsString:@"Material"] || [cn containsString:@"Background"] || [cn containsString:@"VisualEffect"])) {
            if (fabs(v.layer.cornerRadius - radius) > 0.5) v.layer.cornerRadius = radius;
            if (@available(iOS 13.0, *)) if (v.layer.cornerCurve != kCACornerCurveContinuous) v.layer.cornerCurve = kCACornerCurveContinuous;
            if (!v.clipsToBounds) v.clipsToBounds = YES;
        }
        [st addObjectsFromArray:v.subviews];
    }
    // iOS 26: a thin light rim like liquid glass (left out if another glass tweak draws its own)
    BOOL wantRim = !gStyle18 && !OtherGlassTweak();
    if (!wantRim) { [rim removeFromSuperlayer]; return; }
    if (!rim) {
        rim = [CALayer layer]; rim.name = @"c26.rim";
        rim.borderColor = [UIColor colorWithWhite:1 alpha:0.26].CGColor; rim.borderWidth = 1.1;
        if (@available(iOS 13.0, *)) rim.cornerCurve = kCACornerCurveContinuous;
        [m.layer addSublayer:rim];
    }
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (!CGRectEqualToRect(rim.frame, m.bounds)) rim.frame = m.bounds;
    if (fabs(rim.cornerRadius - radius) > 0.5) rim.cornerRadius = radius;
    if (m.layer.sublayers.lastObject != rim) { [rim removeFromSuperlayer]; [m.layer addSublayer:rim]; }
    [CATransaction commit];
}
static BOOL ModuleExpanded(UIView *moduleView);
static void StyleShapes(void) {
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) {
        if (IsCopy(k)) continue;
        UIView *m = mm[k];
        BOOL on = gEnabled && gShapes && m.window && !ModuleExpanded(m) && ![m viewWithTag:BIG_TAG];
        @try { ShapeModule(m, on); } @catch (__unused id e) {}
    }
}
// after the Style setting changes: everything we drew lays itself out again with the new look
static void RestyleAll(void) {
    NSMutableArray *st = [NSMutableArray array];
    for (UIView *m in ModuleMap().allValues) [st addObject:m];
    int n = 0;
    while (st.count && n++ < 800) {
        UIView *v = st.firstObject; [st removeObjectAtIndex:0];
        if ([v isKindOfClass:NSClassFromString(@"C26ConnCard")] || v.tag == BIG_TAG) [v setNeedsLayout];
        if ([v isKindOfClass:[UIButton class]] && [[v viewWithTag:1] isKindOfClass:[UIVisualEffectView class]]) RoundGlass((UIButton *)v);
        [st addObjectsFromArray:v.subviews];
    }
}
static CGFloat ModuleRadius(UIView *m, CGRect f) {
    CGFloat W = m.bounds.size.width, H = m.bounds.size.height, best = 0;
    NSMutableArray *st = [NSMutableArray arrayWithObject:m]; int n = 0;
    while (st.count && n++ < 120) {
        UIView *v = st.firstObject; [st removeObjectAtIndex:0];
        if (v.hidden || v.alpha < 0.05) continue;
        if (v.bounds.size.width >= W * 0.9 && v.bounds.size.height >= H * 0.9) {
            best = MAX(best, v.layer.cornerRadius);
            [st addObjectsFromArray:v.subviews];
        }
    }
    if (best <= 0) best = MIN(W, H) * 0.28;
    return MIN(best, MIN(W, H) / 2);
}
// editing look: a soft white outline around each control that slowly breathes (no wiggle)
static void GlowFor(UIView *e, NSString *ident, CGRect f, CGFloat radius) {
    CGRect gf = CGRectInset(f, -3, -3);
    UIView *gw = nil;
    for (UIView *x in e.subviews) if (x.tag == 4 && [objc_getAssociatedObject(x, kEditIdent) isEqual:ident]) gw = x;
    CAShapeLayer *ring = nil, *halo = nil;
    if (!gw) {
        gw = [[UIView alloc] initWithFrame:gf]; gw.tag = 4; gw.userInteractionEnabled = NO;
        objc_setAssociatedObject(gw, kEditIdent, ident, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        halo = [CAShapeLayer layer]; halo.name = @"halo";
        halo.fillColor = UIColor.clearColor.CGColor; halo.strokeColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor; halo.lineWidth = 3;
        halo.shadowColor = UIColor.whiteColor.CGColor; halo.shadowOffset = CGSizeZero; halo.shadowRadius = 9; halo.shadowOpacity = 0.45;
        ring = [CAShapeLayer layer]; ring.name = @"ring";
        ring.fillColor = UIColor.clearColor.CGColor; ring.strokeColor = UIColor.clearColor.CGColor; ring.lineWidth = 0;
        [gw.layer addSublayer:halo]; [gw.layer addSublayer:ring];
        CABasicAnimation *b = [CABasicAnimation animationWithKeyPath:@"opacity"];
        b.fromValue = @0.2; b.toValue = @0.85; b.duration = 1.6; b.autoreverses = YES; b.repeatCount = HUGE_VALF;
        b.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [halo addAnimation:b forKey:@"breathe"];
        CABasicAnimation *r = [CABasicAnimation animationWithKeyPath:@"opacity"];
        r.fromValue = @0.55; r.toValue = @1; r.duration = 1.5; r.autoreverses = YES; r.repeatCount = HUGE_VALF;
        r.timingFunction = b.timingFunction;
        [ring addAnimation:r forKey:@"breathe"];
        gw.alpha = 0;
        [e insertSubview:gw atIndex:0];
        [UIView animateWithDuration:0.4 animations:^{ gw.alpha = 1; }];
    }
    for (CALayer *l in gw.layer.sublayers) { if ([l.name isEqualToString:@"ring"]) ring = (CAShapeLayer *)l; else if ([l.name isEqualToString:@"halo"]) halo = (CAShapeLayer *)l; }
    if (!CGRectEqualToRect(gw.frame, gf) || ![objc_getAssociatedObject(gw, kGridSize) isEqual:@(radius)]) {
        objc_setAssociatedObject(gw, kGridSize, @(radius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        gw.frame = gf;
        CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(gw.bounds, 1, 1) cornerRadius:radius + 2].CGPath;
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        ring.frame = gw.bounds; halo.frame = gw.bounds;
        ring.path = path; halo.path = path;
        [CATransaction commit];
    }
}
__attribute__((unused)) static void StartWiggle(UIView *v) {
    if ([v.layer animationForKey:@"c26.wiggle"]) return;
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    double a = 0.011;
    k.values = @[@(-a), @(a), @(-a)];
    k.duration = 0.26 + (arc4random_uniform(60) / 1000.0);
    k.repeatCount = HUGE_VALF; k.additive = YES;
    k.beginTime = CACurrentMediaTime() + (arc4random_uniform(100) / 1000.0);
    [v.layer addAnimation:k forKey:@"c26.wiggle"];
}

static void UpdateEditUI(BOOL animated) {
    UIView *cv = CollectionView(), *e = EditRoot(gEditing);
    if (!gEditing) return;
    if (!cv.window || !e) return;
    [[cv viewWithTag:GRID_TAG] removeFromSuperview];   // old versions put it inside Control Center
    BuildGrid(cv, e);
    NSSet *removable = [NSSet setWithArray:[IdList(@"orderedUserEnabledModuleIdentifiers") arrayByAddingObjectsFromArray:SavedCopies()]];
    NSMutableSet *seen = [NSMutableSet set];
    NSDictionary *mm = ModuleMap();
    NSArray *mods = mm.allValues;
    for (NSString *ident in mm) {
        UIView *m = mm[ident];
        if (!m.window || m.hidden) continue;
        [seen addObject:ident];
        if (m.userInteractionEnabled) { m.userInteractionEnabled = NO; objc_setAssociatedObject(m, kWiggleOff, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        CGRect f = ModFrameIn(m, e);
        CGFloat rr = ModuleRadius(m, f);
        CGFloat inset = rr * 0.293;   // where the rounded corner actually is (45 degrees on the arc)
        if (m.layer.zPosition < 1) GlowFor(e, ident, f, rr);
        // resize handle in the bottom-right corner
        UIView *h = nil, *mb = nil, *dg = nil;
        for (UIView *x in e.subviews) if ([objc_getAssociatedObject(x, kEditIdent) isEqual:ident]) { if (x.tag == 1) h = x; else if (x.tag == 2) mb = x; else if (x.tag == 3) dg = x; }
        // the control itself: hold and drag to move it (controls you added)
        if (YES) {
            if (!dg) {
                dg = [[UIView alloc] initWithFrame:f]; dg.tag = 3;
                objc_setAssociatedObject(dg, kEditIdent, ident, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                UIPanGestureRecognizer *sp = [[UIPanGestureRecognizer alloc] initWithTarget:[C26EditCtl shared] action:@selector(scroll:)];
                sp.maximumNumberOfTouches = 1;
                [dg addGestureRecognizer:sp];
                [e insertSubview:dg atIndex:0];
            }
            if (!gResizing && !CGRectEqualToRect(dg.frame, f)) dg.frame = f;
        } else if (dg) { [dg removeFromSuperview]; dg = nil; }
        BOOL canResize = AllowedSizes(ident).count > 0;
        if (!canResize && h) { [h removeFromSuperview]; h = nil; }
        if (canResize && !h) { h = HandleView(); h.tag = 1; objc_setAssociatedObject(h, kEditIdent, ident, OBJC_ASSOCIATION_RETAIN_NONATOMIC); h.alpha = 0; [e addSubview:h]; }
        CGPoint hc = CGPointMake(CGRectGetMaxX(f) - MAX(13, inset), CGRectGetMaxY(f) - MAX(13, inset));
        // the minus badge (only controls you added can be removed)
        BOOL canRemove = [removable containsObject:ident];
        if (canRemove && !mb) {
            UIButton *b = GlassButton(@"minus", 13); b.tag = 2;
            b.frame = CGRectMake(0, 0, 26, 26); RoundGlass(b);
            objc_setAssociatedObject(b, kEditIdent, ident, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [b addTarget:[C26EditCtl shared] action:@selector(minus:) forControlEvents:UIControlEventTouchUpInside];
            b.alpha = 0; [e addSubview:b]; mb = b;
        }
        if (!canRemove && mb) { [mb removeFromSuperview]; mb = nil; }
        CGPoint bc = CGPointMake(CGRectGetMinX(f) + MAX(6, inset), CGRectGetMinY(f) + MAX(6, inset));   // on the control's edge, not off in the corner
        BOOL fresh = (h && h.alpha < 1) || (mb && mb.alpha < 1);
        if (fresh) { if (h.alpha < 1) h.center = hc; if (mb.alpha < 1) { mb.center = bc; mb.transform = CGAffineTransformMakeScale(0.6, 0.6); } }
        void (^place)(void) = ^{ h.center = hc; h.alpha = 1; mb.center = bc; mb.alpha = 1; mb.transform = CGAffineTransformIdentity; };
        if (animated || fresh) [UIView animateWithDuration:fresh ? 0.45 : 0.35 delay:fresh ? 0.08 : 0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:place completion:nil];
        else place();
    }
    for (UIView *x in [e.subviews copy]) {
        NSString *i = objc_getAssociatedObject(x, kEditIdent);
        if (x.tag >= 1 && x.tag <= 4 && i && ![seen containsObject:i]) [x removeFromSuperview];
    }
    // "Add a Control" at the bottom
    UIView *root = gCCVC.viewIfLoaded;
    UIButton *add = (UIButton *)[e viewWithTag:ADDBTN_TAG];
    if (!add) {
        add = GlassButton(@"plus.circle.fill", 17); add.tag = ADDBTN_TAG;
        [add setTitle:@"  Add a Control" forState:UIControlStateNormal];
        add.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [add addTarget:[C26EditCtl shared] action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
        add.alpha = 0; [e addSubview:add];
    }
    CGFloat aw = 210, ah = 50;
    CGRect af = CGRectMake((root.bounds.size.width - aw) / 2, root.bounds.size.height - root.safeAreaInsets.bottom - ah - 18, aw, ah);
    if (!CGRectEqualToRect(add.frame, af) && CGAffineTransformIsIdentity(add.transform)) { add.frame = af; RoundGlass(add); }
    if (add.alpha < 1 && ![add.layer animationForKey:@"opacity"]) [UIView animateWithDuration:0.3 animations:^{ add.alpha = 1; }];
    PlacePresetButton(e);
    UIView *sheet = [root viewWithTag:ADDSHEET_TAG] ?: [root viewWithTag:PRESET_TAG];
    e.hidden = sheet != nil;
    if (!sheet && e.superview.subviews.lastObject != e) [e.superview bringSubviewToFront:e];
    gEditDebug = [NSString stringWithFormat:@"editing mods=%lu saved=%lu", (unsigned long)mods.count, (unsigned long)SavedSizes().count];
}

static void EnterEdit(void) {
    if (gEditing || !gCCVC) return;
    gEditing = YES;
    [[UISelectionFeedbackGenerator new] selectionChanged];
    UpdateEditUI(YES);
    @try { InstallMoveGesture(); } @catch (__unused id ex) {}
    UIView *e = EditRoot(NO);
    e.alpha = 0;
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ e.alpha = 1; } completion:nil];
    PlaceTopButtons(gCCVC);
}
static void ExitEdit(BOOL animated) {
    if (!gEditing) return;
    @try {
    gEditing = NO; gResizing = NO;
    UIView *cv = CollectionView(), *e = EditRoot(NO), *g = [cv viewWithTag:GRID_TAG];   // g: only from old versions
    for (UIView *m in ModuleMap().allValues) {
        [m.layer removeAnimationForKey:@"c26.wiggle"]; m.layer.zPosition = 0;
        if (objc_getAssociatedObject(m, kWiggleOff)) { m.userInteractionEnabled = YES; objc_setAssociatedObject(m, kWiggleOff, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    }
    [[gCCVC.viewIfLoaded viewWithTag:ADDSHEET_TAG] removeFromSuperview];
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{ e.alpha = 0; g.alpha = 0; } completion:^(__unused BOOL f) { [e removeFromSuperview]; [g removeFromSuperview]; }];
    } else { [e removeFromSuperview]; [g removeFromSuperview]; }
    if (gCCVC && !gClosing) PlaceTopButtons(gCCVC);
    CompactPages();
    } @catch (__unused id ex) { gEditing = NO; }
}

// where the Add a Control button is: the sheet grows out of it and shrinks back into it
static CGAffineTransform SheetFromButton(UIView *panel) {
    UIView *root = panel.superview.superview ?: panel.superview;
    UIView *add = [EditRoot(NO) viewWithTag:ADDBTN_TAG];
    CGRect b = add ? [add.superview convertRect:add.frame toView:panel.superview] : CGRectMake(CGRectGetMidX(root.bounds) - 100, CGRectGetMaxY(root.bounds) - 90, 200, 50);
    CGRect p = panel.frame;
    if (p.size.width < 1 || p.size.height < 1) return CGAffineTransformIdentity;
    CGFloat sx = b.size.width / p.size.width, sy = b.size.height / p.size.height;
    return CGAffineTransformConcat(CGAffineTransformMakeScale(sx, sy), CGAffineTransformMakeTranslation(CGRectGetMidX(b) - CGRectGetMidX(p), CGRectGetMidY(b) - CGRectGetMidY(p)));
}
// Add a Control: every control that isn't in Control Center yet
static NSString *ModuleName(NSString *ident, NSBundle *b) {
    NSString *n = [b objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [b objectForInfoDictionaryKey:@"CFBundleName"];
    if (![n isKindOfClass:[NSString class]] || !n.length) n = [ident componentsSeparatedByString:@"."].lastObject;
    n = [n stringByReplacingOccurrencesOfString:@"Module" withString:@""];
    NSMutableString *o = [NSMutableString string];
    for (NSUInteger i = 0; i < n.length; i++) {
        unichar c = [n characterAtIndex:i];
        if (i > 0 && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:c] && ![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[n characterAtIndex:i - 1]] && [n characterAtIndex:i - 1] != ' ') [o appendString:@" "];
        [o appendFormat:@"%C", c];
    }
    return [o stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
static void ShowAddSheet(void) {
    UIView *root = gCCVC.viewIfLoaded;
    if (!root || [root viewWithTag:ADDSHEET_TAG]) return;
    Class IM = NSClassFromString(@"CCUIModuleInstanceManager");
    id im = [IM respondsToSelector:@selector(sharedInstance)] ? ((id (*)(id, SEL))objc_msgSend)(IM, @selector(sharedInstance)) : nil;
    id repo = KV(im, @"repository");
    NSSet *loadable = KV(repo, @"loadableModuleIdentifiers");
    if (![loadable isKindOfClass:[NSSet class]]) loadable = [NSSet set];
    NSMutableSet *have = [NSMutableSet setWithArray:IdList(@"orderedUserEnabledModuleIdentifiers")];
    [have addObjectsFromArray:IdList(@"orderedFixedModuleIdentifiers")];
    [have addObjectsFromArray:IdList(@"orderedUserEnabledFixedModuleIdentifiers")];
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *ident in loadable) {
        if ([have containsObject:ident]) continue;
        id meta = [repo respondsToSelector:@selector(moduleMetadataForModuleIdentifier:)] ? ((id (*)(id, SEL, id))objc_msgSend)(repo, @selector(moduleMetadataForModuleIdentifier:), ident) : nil;
        NSURL *u = KV(meta, @"moduleBundleURL");
        NSBundle *b = [u isKindOfClass:[NSURL class]] ? [NSBundle bundleWithURL:u] : nil;
        UIImage *icon = b ? [UIImage imageNamed:@"SettingsIcon" inBundle:b compatibleWithTraitCollection:nil] : nil;
        [items addObject:@{@"id": ident, @"name": ModuleName(ident, b), @"icon": icon ?: [NSNull null]}];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    // a second Connectivity / Music for another page
    [items insertObject:@{@"id": @"copy:nowplaying", @"name": @"Music", @"icon": [UIImage systemImageNamed:@"music.note"]} atIndex:0];
    [items insertObject:@{@"id": @"copy:connectivity", @"name": @"Connectivity", @"icon": [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"]} atIndex:0];

    EditRoot(NO).hidden = YES;
    UIView *sheet = [[UIView alloc] initWithFrame:root.bounds];
    sheet.tag = ADDSHEET_TAG; sheet.backgroundColor = UIColor.clearColor;
    sheet.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIButton *dim = [UIButton buttonWithType:UIButtonTypeCustom];
    dim.frame = sheet.bounds; dim.autoresizingMask = sheet.autoresizingMask;
    [dim addTarget:[C26EditCtl shared] action:@selector(closeSheet:) forControlEvents:UIControlEventTouchUpInside];
    [sheet addSubview:dim];
    CGFloat W = root.bounds.size.width, H = MIN(root.bounds.size.height * 0.62, 560);
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    panel.tag = 2;
    panel.frame = CGRectMake(8, root.bounds.size.height - H - 8, W - 16, H);
    panel.layer.cornerRadius = 38; panel.layer.cornerCurve = kCACornerCurveContinuous; panel.clipsToBounds = YES;
    panel.layer.borderWidth = 1; panel.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    [sheet addSubview:panel];
    UIView *pc = panel.contentView;
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, panel.bounds.size.width, 28)];
    t.text = @"Add a Control"; t.textAlignment = NSTextAlignmentCenter; t.textColor = UIColor.whiteColor;
    t.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    [pc addSubview:t];
    UIButton *x = GlassButton(@"xmark", 14);
    x.frame = CGRectMake(panel.bounds.size.width - 52, 16, 36, 36); RoundGlass(x);
    [x addTarget:[C26EditCtl shared] action:@selector(closeSheet:) forControlEvents:UIControlEventTouchUpInside];
    [pc addSubview:x];
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 66, panel.bounds.size.width, H - 66)];
    sv.showsVerticalScrollIndicator = NO; sv.alwaysBounceVertical = YES;
    [pc addSubview:sv];
    CGFloat cols = 4, tileW = (panel.bounds.size.width - 24) / cols, tileH = 104, icon = 62;
    NSUInteger i = 0;
    for (NSDictionary *it in items) {
        CGFloat cx = 12 + (i % 4) * tileW, cy = 8 + (i / 4) * tileH;
        UIButton *tile = [UIButton buttonWithType:UIButtonTypeCustom];
        tile.frame = CGRectMake(cx, cy, tileW, tileH);
        objc_setAssociatedObject(tile, kEditIdent, it[@"id"], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [tile addTarget:[C26EditCtl shared] action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake((tileW - icon) / 2, 0, icon, icon)];
        circle.userInteractionEnabled = NO;
        circle.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14]; circle.layer.cornerRadius = icon / 2;
        circle.layer.borderWidth = 1; circle.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectInset(circle.bounds, 15, 15)];
        id img = it[@"icon"];
        iv.image = [img isKindOfClass:[UIImage class]] ? img : [UIImage systemImageNamed:@"square.grid.2x2.fill"];
        iv.contentMode = UIViewContentModeScaleAspectFit; iv.tintColor = UIColor.whiteColor;
        iv.layer.cornerRadius = 7; iv.clipsToBounds = YES;
        [circle addSubview:iv];
        [tile addSubview:circle];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(2, icon + 6, tileW - 4, 32)];
        l.text = it[@"name"]; l.numberOfLines = 2; l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium]; l.textColor = [UIColor colorWithWhite:1 alpha:0.9];
        l.userInteractionEnabled = NO;
        [tile addSubview:l];
        [sv addSubview:tile];
        i++;
    }
    if (!items.count) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, sv.bounds.size.width - 40, 60)];
        l.text = @"Every control is already in Control Center."; l.numberOfLines = 0; l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor colorWithWhite:1 alpha:0.6]; l.font = [UIFont systemFontOfSize:15];
        [sv addSubview:l];
    }
    sv.contentSize = CGSizeMake(sv.bounds.size.width, 16 + ceil(items.count / cols) * tileH + 20);
    [root addSubview:sheet];
    panel.transform = SheetFromButton(panel);
    panel.alpha = 0.2;
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:0 animations:^{
        sheet.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        panel.transform = CGAffineTransformIdentity;
        panel.alpha = 1;
    } completion:nil];
    NSUInteger k = 0;
    for (UIView *tile in sv.subviews) {
        tile.alpha = 0; tile.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.85, 0.85), CGAffineTransformMakeTranslation(0, 14));
        [UIView animateWithDuration:0.45 delay:0.12 + MIN(k, 24) * 0.018 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ tile.alpha = 1; tile.transform = CGAffineTransformIdentity; } completion:nil];
        k++;
    }
}

// Slide to power off (iOS 26 look)
static void PowerOffNow(void) {
    Class F = NSClassFromString(@"FBSystemService");
    id s = [F respondsToSelector:@selector(sharedInstance)] ? ((id (*)(id, SEL))objc_msgSend)(F, @selector(sharedInstance)) : nil;
    SEL a = NSSelectorFromString(@"shutdownAndReboot:");
    if ([s respondsToSelector:a]) { ((void (*)(id, SEL, BOOL))objc_msgSend)(s, a, NO); return; }
    SEL b = NSSelectorFromString(@"powerDown");
    id app = UIApplication.sharedApplication;
    if ([app respondsToSelector:b]) ((void (*)(id, SEL))objc_msgSend)(app, b);
}
@interface C26PowerUI : NSObject
+ (instancetype)shared;
@end
@implementation C26PowerUI { CGFloat _x0; }
+ (instancetype)shared { static C26PowerUI *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26PowerUI new]; }); return s; }
- (void)cancel:(id)x {
    UIView *ui = nil;
    for (UIWindow *w in UIApplication.sharedApplication.windows) { UIView *v = [w viewWithTag:POWERUI_TAG]; if (v) ui = v; }
    [UIView animateWithDuration:0.25 animations:^{ ui.alpha = 0; } completion:^(__unused BOOL f) { [ui removeFromSuperview]; }];
}
- (void)drag:(UIPanGestureRecognizer *)g {
    UIView *knob = g.view, *track = knob.superview;
    CGFloat maxX = track.bounds.size.width - knob.bounds.size.width / 2 - 6, minX = knob.bounds.size.width / 2 + 6;
    UILabel *hint = (UILabel *)[track viewWithTag:3];
    if (g.state == UIGestureRecognizerStateBegan) _x0 = knob.center.x;
    CGFloat x = MIN(maxX, MAX(minX, _x0 + [g translationInView:track].x));
    if (g.state == UIGestureRecognizerStateChanged) { knob.center = CGPointMake(x, knob.center.y); hint.alpha = MAX(0, 1 - (x - minX) / ((maxX - minX) * 0.6)); return; }
    if (g.state == UIGestureRecognizerStateEnded && x >= maxX - 4) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
        UIView *ui = track.superview;
        [UIView animateWithDuration:0.35 animations:^{ ui.backgroundColor = UIColor.blackColor; for (UIView *s in ui.subviews) s.alpha = 0; } completion:^(__unused BOOL f) { PowerOffNow(); }];
        return;
    }
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{ knob.center = CGPointMake(minX, knob.center.y); hint.alpha = 1; } completion:nil];
}
@end
static void ShowPowerOff(void) {
    UIWindow *w = gCCVC.viewIfLoaded.window;
    if (!w || [w viewWithTag:POWERUI_TAG]) return;
    UIVisualEffectView *ui = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    ui.frame = w.bounds; ui.tag = POWERUI_TAG; ui.alpha = 0;
    ui.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
    CGFloat tw = MIN(w.bounds.size.width - 56, 320), th = 68;
    UIView *track = [[UIView alloc] initWithFrame:CGRectMake((w.bounds.size.width - tw) / 2, w.safeAreaInsets.top + 70, tw, th)];
    track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16]; track.layer.cornerRadius = th / 2;
    track.layer.borderWidth = 1; track.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(th, 0, tw - th - 12, th)];
    hint.tag = 3; hint.text = @"slide to power off"; hint.textAlignment = NSTextAlignmentCenter;
    hint.textColor = [UIColor colorWithWhite:1 alpha:0.85]; hint.font = [UIFont systemFontOfSize:19 weight:UIFontWeightMedium];
    [track addSubview:hint];
    UIView *knob = [[UIView alloc] initWithFrame:CGRectMake(6, 6, th - 12, th - 12)];
    knob.backgroundColor = UIColor.whiteColor; knob.layer.cornerRadius = (th - 12) / 2;
    UIImageView *pi = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"power" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightBold]]];
    pi.tintColor = UIColor.systemRedColor; pi.center = CGPointMake(knob.bounds.size.width / 2, knob.bounds.size.height / 2);
    [knob addSubview:pi];
    [knob addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:[C26PowerUI shared] action:@selector(drag:)]];
    [track addSubview:knob];
    [ui.contentView addSubview:track];
    UIButton *cancel = GlassButton(@"xmark", 20);
    cancel.frame = CGRectMake((w.bounds.size.width - 64) / 2, w.bounds.size.height - w.safeAreaInsets.bottom - 120, 64, 64); RoundGlass(cancel);
    [cancel addTarget:[C26PowerUI shared] action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [ui.contentView addSubview:cancel];
    UILabel *cl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(cancel.frame) + 8, w.bounds.size.width, 20)];
    cl.text = @"Cancel"; cl.textAlignment = NSTextAlignmentCenter; cl.textColor = UIColor.whiteColor; cl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [ui.contentView addSubview:cl];
    [w addSubview:ui];
    [UIView animateWithDuration:0.3 animations:^{ ui.alpha = 1; }];
}

// Control Center's own gestures stay out of the way while editing
static BOOL (*origDTap)(id, SEL, id);
static BOOL DTap(id self, SEL _cmd, id g) { if (gEditing) { dispatch_async(dispatch_get_main_queue(), ^{ ExitEdit(YES); }); return NO; } return origDTap(self, _cmd, g); }
static BOOL (*origDPan)(id, SEL, id);
static BOOL DPan(id self, SEL _cmd, id g) { return gEditing ? NO : origDPan(self, _cmd, g); }
static BOOL (*origDFlick)(id, SEL, id);
static BOOL DFlick(id self, SEL _cmd, id g) { return gEditing ? NO : origDFlick(self, _cmd, g); }
static BOOL (*origSPan)(id, SEL, id);
static BOOL SPan(id self, SEL _cmd, id g) {
    if (gResizing) return NO;
    if (gEditing) {
        UIView *e = EditRoot(NO);
        if (e && !e.hidden && [g isKindOfClass:[UIGestureRecognizer class]]) { UIView *h = [e hitTest:[(UIGestureRecognizer *)g locationInView:e] withEvent:nil]; if (h) return NO; }
    }
    return origSPan(self, _cmd, g);
}
static BOOL gScrOn;
static void (*origOVScroll)(id, SEL, id);
static void OVScroll(id self, SEL _cmd, id sv) {
    origOVScroll(self, _cmd, sv);
    static CFTimeInterval lastHeavy;
    CFTimeInterval now = CACurrentMediaTime();
    BOOL heavy = !gScrOn || now - lastHeavy > 0.25;   // the full refresh at most 4 times a second while a page glides
    if (heavy) lastHeavy = now;
    if (heavy && gEditing && !gResizing && !gClosing) { @try { UpdateEditUI(NO); } @catch (__unused id e) {} }
    if (!gClosing) { @try { StyleCopies(); ApplyPageVisibility(); if (heavy) PlaceDots(); } @catch (__unused id e) {} }
}
static void (*origOVLayout)(id, SEL);
static void OVLayout(UIViewController *self, SEL _cmd) {
    origOVLayout(self, _cmd);
    gCCVC = self;
    if (gClosing) return;
    @try { PlaceTopButtons(self); if (gEditing && !gResizing) UpdateEditUI(NO); } @catch (__unused id e) {}
}
static void HideTopButtons(BOOL animated) {
    UIView *root = gCCVC.viewIfLoaded;
    UIView *a = [root viewWithTag:TOPPLUS_TAG], *b = [root viewWithTag:TOPPOWER_TAG];
    if (animated) [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ a.alpha = 0; b.alpha = 0; } completion:nil];
    else { a.alpha = 0; b.alpha = 0; }
}
// our own Big Music / Big Connectivity views and the copies go away at once when Control Center closes
static void HideOurModules(BOOL hide) {
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    @try {
        NSMutableArray *vs = [NSMutableArray array];
        if (gCopyRoot) [vs addObject:gCopyRoot];
        for (UIView *m in ModuleMap().allValues) { UIView *bv = [m viewWithTag:BIG_TAG]; if (bv) [vs addObject:bv]; }
        for (UIView *v in vs) {
            if (hide) { [v.layer removeAllAnimations]; v.alpha = 0; }
            else if (v.alpha < 1 && ![v.layer animationForKey:@"opacity"]) v.alpha = 1;
        }
    } @catch (__unused id e) {}
    [CATransaction commit];
}
static void ApplyShrink(double s);
static double gShrink, gShrinkV, gShrinkT;
static void StartClosing(void) {
    gClosing = YES; gClosingAt = CACurrentMediaTime();
    if (gShrink != 1) { gShrink = gShrinkT = 1; gShrinkV = 0; @try { ApplyShrink(1); } @catch (__unused id e) {} }
    HideOurModules(YES);
    HideTopButtons(YES);
    @try { if (gEditing) ExitEdit(NO); } @catch (__unused id e) {}
    @try { ApplyPageVisibility(); } @catch (__unused id e) {}
    @try { [[gCCVC.viewIfLoaded viewWithTag:PAGEDOTS_TAG] setAlpha:0]; [[gCCVC.viewIfLoaded viewWithTag:PRESET_TAG] removeFromSuperview]; } @catch (__unused id e) {}
}
static id (*origBeginDismiss)(id, SEL, BOOL, BOOL);
static id BeginDismiss(id self, SEL _cmd, BOOL animated, BOOL interactive) { StartClosing(); return origBeginDismiss(self, _cmd, animated, interactive); }
static void (*origDismissAnim)(id, SEL, BOOL, id);
static void DismissAnim(id self, SEL _cmd, BOOL animated, id done) { StartClosing(); origDismissAnim(self, _cmd, animated, done); }
static id (*origBeginPresent)(id, SEL, BOOL, BOOL);
static void DropInModules(UIViewController *ov);
static id BeginPresent(id self, SEL _cmd, BOOL animated, BOOL interactive) {
    gClosing = NO;
    @try { if (gEditing) ExitEdit(NO); } @catch (__unused id e) {}
    HideOurModules(NO);
    id r = origBeginPresent(self, _cmd, animated, interactive);
    @try { DropInModules(self); } @catch (__unused id e) {}
    return r;
}
static void (*origWillDismiss)(id, SEL);
static void WillDismiss(id self, SEL _cmd) {
    StartClosing();
    origWillDismiss(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{ @try { [[C26PowerUI shared] cancel:nil]; } @catch (__unused id e) {} });
}

static BOOL gEditHooked, gSettingsHooked;
static void TryEditHooks(void) {
    #define EH(C, sel, fn, orig) if (class_getInstanceMethod(C, sel)) MSHookMessageEx(C, sel, (IMP)fn, (IMP *)&orig)
    Class SM = NSClassFromString(@"CCUIModuleSettingsManager");
    if (!gSettingsHooked && SM) { gSettingsHooked = YES; EH(SM, @selector(moduleSettingsForModuleIdentifier:prototypeSize:), ModSettings, origModSettings); }
    Class OV = NSClassFromString(@"CCUIModularControlCenterOverlayViewController");
    if (!gEditHooked && OV) {
        gEditHooked = YES;
        EH(OV, @selector(viewWillLayoutSubviews), OVLayout, origOVLayout);
        EH(OV, @selector(scrollViewDidScroll:), OVScroll, origOVScroll);
        EH(OV, NSSelectorFromString(@"_dismissalTapGestureRecognizerShouldBegin:"), DTap, origDTap);
        EH(OV, NSSelectorFromString(@"_dismissalPanGestureRecognizerShouldBegin:"), DPan, origDPan);
        EH(OV, NSSelectorFromString(@"_dismissalFlickGestureRecognizerShouldBegin:"), DFlick, origDFlick);
        EH(OV, NSSelectorFromString(@"_scrollPanGestureRecognizerShouldBegin:"), SPan, origSPan);
        EH(OV, NSSelectorFromString(@"_willDismissView"), WillDismiss, origWillDismiss);
        EH(OV, NSSelectorFromString(@"_beginDismissalAnimated:interactive:"), BeginDismiss, origBeginDismiss);
        EH(OV, @selector(dismissAnimated:withCompletionHandler:), DismissAnim, origDismissAnim);
        EH(OV, NSSelectorFromString(@"_beginPresentationAnimated:interactive:"), BeginPresent, origBeginPresent);
        Class PP = NSClassFromString(@"CCUIControlCenterPositionProvider");
        if (PP) {
            EH(PP, @selector(regenerateRectsWithOrderedIdentifiers:orderedSizes:), Regen, origRegen);
            EH(PP, @selector(layoutRectForIdentifier:), LRect, origLRect);
            EH(PP, @selector(layoutSize), LSize, origLSize);
        }
    }
}

#pragma mark - big connectivity / music layouts, pages, layout presets


static double NowElapsed(void) {
    double e = gNPElapsed;
    if (gNPStamp && gIsPlaying) e += -[gNPStamp timeIntervalSinceNow] * (gNPRate > 0 ? gNPRate : 1);
    if (gNPDuration > 0) e = MIN(e, gNPDuration);
    return MAX(0, e);
}
static NSString *TimeText(double t) { int s = (int)llround(t); return [NSString stringWithFormat:@"%d:%02d", s / 60, s % 60]; }

// system volume (what the volume buttons change)
static id AVSys(void) {
    static id s;
    if (!s) {
        dlopen("/System/Library/PrivateFrameworks/Celestial.framework/Celestial", RTLD_LAZY);
        Class A = NSClassFromString(@"AVSystemController");
        if ([A respondsToSelector:NSSelectorFromString(@"sharedAVSystemController")]) s = ((id (*)(id, SEL))objc_msgSend)(A, NSSelectorFromString(@"sharedAVSystemController"));
    }
    return s;
}
static float GetVolume(void) {
    id s = AVSys(); float v = 0.5f; NSString *name = nil;
    SEL g = NSSelectorFromString(@"getActiveCategoryVolume:andName:");
    if ([s respondsToSelector:g]) ((BOOL (*)(id, SEL, float *, NSString **))objc_msgSend)(s, g, &v, &name);
    return v;
}
static void SetVolume(float v) {
    id s = AVSys(); SEL set = NSSelectorFromString(@"setActiveCategoryVolumeTo:");
    if ([s respondsToSelector:set]) ((BOOL (*)(id, SEL, float))objc_msgSend)(s, set, MAX(0, MIN(1, v)));
}
static void SeekTo(double t) {
    void *h = MediaRemote();
    void (*fn)(double) = h ? (void (*)(double))dlsym(h, "MRMediaRemoteSetElapsedTime") : NULL;
    if (fn) { fn(t); gNPElapsed = t; gNPStamp = [NSDate date]; }
}

// A thin glass slider (progress / volume)
@interface C26Bar : UIControl
@property (nonatomic) float value;
@property (nonatomic) BOOL dragging;
@property (nonatomic, strong) UIView *track, *fill;
@property (nonatomic, copy) void (^changed)(float v, BOOL done);
- (void)setLiveValue:(float)v;
@end
@implementation C26Bar { float _startV; CGFloat _startX, _over; CFTimeInterval _hold; }
// updates from the system: ignored while you hold it and for a moment after (until the new value
// comes back), and tiny wobbles don't redraw it
- (void)setLiveValue:(float)v {
    if (_dragging || CACurrentMediaTime() < _hold || !isfinite(v)) return;
    v = MAX(0, MIN(1, v));
    if (fabsf(v - _value) < 0.003) return;
    _value = v;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    CGFloat fw = _track.bounds.size.width * _value;
    if (fabs(_fill.frame.size.width - fw) > 0.25) _fill.frame = CGRectMake(0, 0, fw, _track.bounds.size.height);
    [CATransaction commit];
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _track = [UIView new]; _track.userInteractionEnabled = NO; _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25]; _track.clipsToBounds = YES;
    _fill = [UIView new]; _fill.userInteractionEnabled = NO; _fill.backgroundColor = UIColor.whiteColor;
    [_track addSubview:_fill]; [self addSubview:_track];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width, h = _dragging ? 13 : 7;
    // past either end the bar stretches a little that way (rubber band), like Apple's
    CGFloat extra = MIN(W * 0.06, fabs(_over) * W * 0.35);
    CGFloat x = _over < 0 ? -extra : 0, w = W + extra + (_dragging ? 0 : 0);
    CGFloat grow = _dragging ? 4 : 0;   // a touch wider while held
    _track.frame = CGRectMake(x - grow, (self.bounds.size.height - h) / 2, w + grow * 2, h);
    _track.layer.cornerRadius = h / 2;
    CGFloat fw = _track.bounds.size.width * MAX(0, MIN(1, _value));
    _fill.frame = CGRectMake(0, 0, fw, h);
}
- (void)setValue:(float)v { _value = v; [self setNeedsLayout]; }
- (BOOL)beginTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    // no jump to the finger: it moves from where it is, by how far you slide
    _dragging = YES; _startV = _value; _startX = [t locationInView:self].x; _over = 0;
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ [self layoutSubviews]; } completion:nil];
    return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    CGFloat raw = _startV + ([t locationInView:self].x - _startX) / MAX(1, self.bounds.size.width);
    float v = MAX(0, MIN(1, raw));
    BOOL hitEnd = (v == 0 || v == 1) && _value != v;
    _value = v;
    CGFloat o = raw - (CGFloat)v;
    if (fabs(o) < 0.001) o = 0;
    _over = o == 0 ? 0 : (o > 0 ? 1 : -1) * (1 - 1 / (fabs(o) * 3 + 1)) * 0.5;   // eases off the further you pull
    [self layoutSubviews];
    if (hitEnd) [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (_changed) _changed(_value, NO);
    return YES;
}
- (void)endTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    _dragging = NO; _over = 0; _hold = CACurrentMediaTime() + 1.6;
    if (_changed) _changed(_value, YES);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ [self layoutSubviews]; } completion:nil];
}
- (void)cancelTrackingWithEvent:(UIEvent *)e { [self endTrackingWithTouch:nil withEvent:e]; }
@end

// The big player (4x2 up to a whole page), drawn like iOS 26
@interface C26BigPlayer : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIImageView *art;
@property (nonatomic, strong) UILabel *title, *artist, *elapsed, *remain;
@property (nonatomic, strong) C26Bar *progress, *volume;
@property (nonatomic, strong) UIButton *prev, *play, *next, *star;
@property (nonatomic, strong) UIImageView *volLo, *volHi;
@property (nonatomic, strong) AVRoutePickerView *route;
@property (nonatomic, strong) UIView *airCap;
@property (nonatomic) int mode;   // 2: strip, 4: player, 6+: big artwork
@end
@implementation C26BigPlayer
- (UIButton *)btn:(NSString *)sym pt:(CGFloat)pt cmd:(int)cmd {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor; b.tag = cmd;
    [b addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown];
    [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self addSubview:b];
    return b;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.tag = BIG_TAG;
    _card = [UIView new]; _card.userInteractionEnabled = NO;
    _card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    _card.layer.borderWidth = gStyle18 ? 0 : 1; _card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    _card.layer.cornerCurve = kCACornerCurveContinuous;
    [self addSubview:_card];
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerCurve = kCACornerCurveContinuous; _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [self addSubview:_art];
    _title = [UILabel new]; _title.textColor = UIColor.whiteColor; _title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _artist = [UILabel new]; _artist.textColor = [UIColor colorWithWhite:1 alpha:0.62]; _artist.font = [UIFont systemFontOfSize:16];
    _elapsed = [UILabel new]; _remain = [UILabel new];
    for (UILabel *l in @[_elapsed, _remain]) { l.textColor = [UIColor colorWithWhite:1 alpha:0.6]; l.font = [UIFont monospacedDigitSystemFontOfSize:12.5 weight:UIFontWeightMedium]; }
    _remain.textAlignment = NSTextAlignmentRight;
    for (UILabel *l in @[_title, _artist, _elapsed, _remain]) [self addSubview:l];
    _progress = [C26Bar new];
    __weak C26BigPlayer *ws = self;
    _progress.changed = ^(float v, BOOL done) { C26BigPlayer *s = ws; if (gNPDuration > 0) { s.elapsed.text = TimeText(v * gNPDuration); if (done) SeekTo(v * gNPDuration); } };
    [self addSubview:_progress];
    _volume = [C26Bar new];
    _volume.changed = ^(float v, BOOL done) { SetVolume(v); };
    [self addSubview:_volume];
    _volLo = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"speaker.fill"]];
    _volHi = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"speaker.wave.3.fill"]];
    for (UIImageView *i in @[_volLo, _volHi]) { i.tintColor = [UIColor colorWithWhite:1 alpha:0.62]; i.contentMode = UIViewContentModeScaleAspectFit; [self addSubview:i]; }
    _prev = [self btn:@"backward.fill" pt:28 cmd:5];
    _play = [self btn:@"play.fill" pt:38 cmd:2];
    _next = [self btn:@"forward.fill" pt:28 cmd:4];
    _star = [self btn:@"star" pt:21 cmd:-1];
    _star.tintColor = [UIColor colorWithWhite:1 alpha:0.7];
    // AirPlay: a capsule with Apple's route picker on top of it
    _airCap = [UIView new]; _airCap.userInteractionEnabled = NO;
    _airCap.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14];
    UIImageView *ai = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"airplayaudio" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightSemibold]]];
    ai.tintColor = [UIColor colorWithWhite:1 alpha:0.85]; ai.tag = 1;
    UILabel *al = [UILabel new]; al.text = @"AirPlay"; al.tag = 2; al.textColor = [UIColor colorWithWhite:1 alpha:0.85]; al.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [_airCap addSubview:ai]; [_airCap addSubview:al];
    [self addSubview:_airCap];
    _route = [[AVRoutePickerView alloc] initWithFrame:CGRectZero];
    _route.tintColor = UIColor.whiteColor; _route.activeTintColor = UIColor.systemBlueColor;
    _route.clipsToBounds = YES;
    [self addSubview:_route];
    return self;
}
- (void)down:(UIButton *)b { [UIView animateWithDuration:0.15 animations:^{ b.transform = CGAffineTransformMakeScale(0.82, 0.82); b.alpha = 0.7; }]; }
- (void)up:(UIButton *)b { [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:0 animations:^{ b.transform = CGAffineTransformIdentity; b.alpha = 1; } completion:nil]; }
- (void)tap:(UIButton *)b {
    [self up:b];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b.tag == -1) { BOOL on = !gNPLiked.boolValue; gNPLiked = @(on); SendLove(on); [self refresh]; return; }
    SendMR((int)b.tag);
    if (b.tag == 2) { gIsPlaying = !gIsPlaying; [self refresh]; }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gLastFetch = 0; FetchNowPlaying(); });
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize S = self.bounds.size;
    _card.frame = self.bounds; _card.layer.borderWidth = gStyle18 ? 0 : 1;
    _card.layer.cornerRadius = MIN(40, MIN(S.width, S.height) * 0.22);
    if (_mode <= 2) {
        CGFloat pad = 16, a = S.height - pad * 2;
        _art.frame = CGRectMake(pad, pad, a, a); _art.layer.cornerRadius = 12;
        CGFloat x = pad + a + 16, w = S.width - x - pad;
        _title.frame = CGRectMake(x, pad + 2, w - 46, 22); _artist.frame = CGRectMake(x, pad + 25, w - 46, 20);
        _route.frame = CGRectMake(S.width - pad - 38, pad, 38, 38); _route.alpha = 1; _route.layer.cornerRadius = 19;
        _route.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14];
        CGFloat cy = pad + a * 0.66;
        // three evenly spaced buttons, play/pause in the middle of the text column
        CGFloat third = w / 3;
        _prev.frame = CGRectMake(x + third * 0.5 - 22, cy - 22, 44, 44);
        _play.frame = CGRectMake(x + third * 1.5 - 25, cy - 25, 50, 50);
        _next.frame = CGRectMake(x + third * 2.5 - 22, cy - 22, 44, 44);
        _progress.frame = CGRectMake(x, S.height - pad - 10, w, 14);
        _elapsed.hidden = _remain.hidden = _volume.hidden = _volLo.hidden = _volHi.hidden = _star.hidden = _airCap.hidden = YES;
        return;
    }
    _elapsed.hidden = _remain.hidden = _volume.hidden = _volLo.hidden = _volHi.hidden = _star.hidden = _airCap.hidden = NO;
    _route.backgroundColor = UIColor.clearColor;
    CGFloat pad = MIN(28, S.width * 0.075), W = S.width - pad * 2;
    BOOL big = _mode >= 6;
    // what sits under the artwork
    CGFloat restH = 56 + 50 + 74 + 50 + 46;
    CGFloat a = big ? MIN(W, S.height - pad * 2 - restH - 12) : 64;
    CGFloat contentH = (big ? a + 22 : a + 18) + restH;
    CGFloat y = MAX(pad, (S.height - contentH) / 2);
    if (big) {
        _art.frame = CGRectMake((S.width - a) / 2, y, a, a); _art.layer.cornerRadius = 16;
        y += a + 22;
        _title.frame = CGRectMake(pad, y, W, 22); _artist.frame = CGRectMake(pad, y + 24, W, 21);
    } else {
        _art.frame = CGRectMake(pad, y, a, a); _art.layer.cornerRadius = 12;
        _title.frame = CGRectMake(pad + a + 14, y + a / 2 - 22, W - a - 14, 22); _artist.frame = CGRectMake(pad + a + 14, y + a / 2 + 2, W - a - 14, 21);
        y += a + 18 - 56;
    }
    y += 56;
    _progress.frame = CGRectMake(pad, y, W, 16);
    _elapsed.frame = CGRectMake(pad, y + 20, 70, 16); _remain.frame = CGRectMake(S.width - pad - 70, y + 20, 70, 16);
    y += 50;
    CGFloat cy = y + 37;
    _play.frame = CGRectMake((S.width - 70) / 2, cy - 35, 70, 70);
    _star.frame = CGRectMake(pad - 6, cy - 22, 44, 44);
    CGFloat room = S.width / 2 - 35 - (CGRectGetMaxX(_star.frame) + 2);   // space between the star and play
    CGFloat bw = MIN(58, MAX(40, room - 8)), sp = MIN(26, MAX(2, room - bw));
    _prev.frame = CGRectMake(S.width / 2 - 35 - sp - bw, cy - bw / 2, bw, bw);
    _next.frame = CGRectMake(S.width / 2 + 35 + sp, cy - bw / 2, bw, bw);
    y += 74;
    CGFloat vy = y + 25;
    _volLo.frame = CGRectMake(pad, vy - 8, 15, 16); _volHi.frame = CGRectMake(S.width - pad - 24, vy - 8, 24, 16);
    _volume.frame = CGRectMake(pad + 28, vy - 8, W - 62, 16);
    y += 50;
    CGFloat cw = 132, ch = 42;
    _airCap.frame = CGRectMake((S.width - cw) / 2, y, cw, ch); _airCap.layer.cornerRadius = ch / 2;
    [_airCap viewWithTag:1].frame = CGRectMake(20, (ch - 20) / 2, 22, 20);
    [_airCap viewWithTag:2].frame = CGRectMake(48, 0, cw - 56, ch);
    _route.frame = _airCap.frame; _route.alpha = 0.02;
}
- (void)refresh {
    FetchNowPlaying();
    if (_art.image != gArtwork) [UIView transitionWithView:_art duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self.art.image = gArtwork; } completion:nil];
    NSString *t = gNPTitle ?: @"Not Playing", *a = gNPArtist ?: @"";
    if (![_title.text isEqualToString:t]) _title.text = t;
    if (![_artist.text isEqualToString:a]) _artist.text = a;
    NSString *ps = gIsPlaying ? @"pause.fill" : @"play.fill";
    if (![objc_getAssociatedObject(_play, kLastValue) isEqual:ps]) {
        objc_setAssociatedObject(_play, kLastValue, ps, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [UIView transitionWithView:_play duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.play setImage:[UIImage systemImageNamed:ps withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:(self.mode >= 4 ? 40 : 30) weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
        } completion:nil];
    }
    NSString *ss = gNPLiked.boolValue ? @"star.fill" : @"star";
    if (![objc_getAssociatedObject(_star, kLastValue) isEqual:ss]) {
        objc_setAssociatedObject(_star, kLastValue, ss, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_star setImage:[UIImage systemImageNamed:ss withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    }
    if (!_progress.dragging) {
        double e = NowElapsed();
        [_progress setLiveValue:gNPDuration > 0 ? e / gNPDuration : 0];
        _elapsed.text = gNPTitle ? TimeText(e) : @"--:--";
        _remain.text = gNPDuration > 0 ? [@"-" stringByAppendingString:TimeText(gNPDuration - e)] : @"--:--";
    }
    if (!_volume.dragging) [_volume setLiveValue:GetVolume()];
}
@end

// The big connectivity block: Apple's expanded cards, laid out for the size it has
@interface C26BigConn : UIView
@property (nonatomic) int rows;
@property (nonatomic, weak) UIView *apple;   // where Apple's real buttons are
@end
@implementation C26BigConn
- (instancetype)initWithFrame:(CGRect)f { if ((self = [super initWithFrame:f])) self.tag = BIG_TAG; return self; }
- (NSArray *)plan {
    if (_rows >= 7 && PAGE_ROWS >= 7) return @[@[@"air"], @[@"wifi", @"airdrop"], @[@"cell", @"bt"], @[@"hotspot"]];
    if (_rows >= 6) return @[@[@"air", @"hotspot"], @[@"wifi", @"airdrop"], @[@"cell", @"bt"]];
    return @[@[@"air", @"wifi"], @[@"airdrop", @"cell"], @[@"bt", @"hotspot"]];
}
- (BOOL)tileRow:(NSArray *)r { return _rows >= 6 && r.count == 2 && ([r containsObject:@"wifi"] || [r containsObject:@"cell"]); }
- (void)refresh {
    NSMutableDictionary *byKey = [NSMutableDictionary dictionary];
    Class L = NSClassFromString(@"CCUILabeledRoundButton");
    NSMutableArray *bs = [NSMutableArray array];
    if (L && self.apple) CollectViews(self.apple, 0, L, bs);
    for (UIView *b in bs) { NSString *k = ConnKey(ConnTitle(b)); if (!byKey[k]) byKey[k] = b; }
    NSArray *plan = [self plan];
    CGSize S = self.bounds.size;
    if (S.width < 40 || S.height < 40) return;   // not laid out yet
    CGFloat gap = S.width < 330 ? 10 : 14, pillH = S.width < 330 ? 60 : 70, tileW = (S.width - gap) / 2, tileH = tileW * 0.96;
    int tiles = 0, pills = 0;
    for (NSArray *r in plan) { if ([self tileRow:r]) tiles++; else pills++; }
    CGFloat need = pills * pillH + tiles * tileH + gap * (plan.count - 1);
    if (need > S.height && tiles) tileH = MAX(pillH, (S.height - pills * pillH - gap * (plan.count - 1)) / tiles);
    if (need > S.height && !tiles) pillH = MAX(44, (S.height - gap * (plan.count - 1)) / plan.count);
    CGFloat y = 0;
    NSMutableSet *used = [NSMutableSet set];
    for (NSArray *r in plan) {
        BOOL tile = [self tileRow:r];
        CGFloat h = tile ? tileH : pillH;
        CGFloat w = (S.width - gap * (r.count - 1)) / r.count;
        for (NSUInteger i = 0; i < r.count; i++) {
            NSString *k = r[i];
            UIView *b = byKey[k];
            C26ConnCard *card = nil;
            for (UIView *v in self.subviews) if ([v isKindOfClass:[C26ConnCard class]] && [((C26ConnCard *)v).key isEqualToString:k] && ((C26ConnCard *)v).pill == !tile) card = (C26ConnCard *)v;
            if (!card) {
                card = [[C26ConnCard alloc] initWithKey:k pill:!tile];
                [card setOn:NO animated:NO];
                objc_setAssociatedObject(card, kLastValue, @(-1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                card.alpha = 0; [self addSubview:card];
                [UIView animateWithDuration:0.3 animations:^{ card.alpha = 1; }];
            }
            [used addObject:card];
            CGRect f = CGRectMake(i * (w + gap), y, w, h);
            if (!CGAffineTransformIsIdentity(card.transform)) { card.bounds = CGRectMake(0, 0, f.size.width, f.size.height); card.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f)); }
            else SetFrame(card, f);
            UIControl *round = (UIControl *)RoundButtonIn(b);
            card.target = [round isKindOfClass:[UIControl class]] ? round : nil;
            card.apple = b;
            NSString *title = b ? ConnTitle(b) : @{@"air": @"Airplane Mode", @"wifi": @"Wi-Fi", @"airdrop": @"AirDrop", @"cell": @"Cellular Data", @"bt": @"Bluetooth", @"hotspot": @"Personal Hotspot"}[k];
            BOOL on = card.target ? card.target.isSelected : NO;
            NSString *sub = b ? ConnSubtitle(b) : @"";
            if (!sub.length || [sub isEqualToString:title]) sub = on ? @"On" : @"Off";
            if (![objc_getAssociatedObject(card, @selector(title)) isEqual:title]) { objc_setAssociatedObject(card, @selector(title), title, OBJC_ASSOCIATION_COPY_NONATOMIC); card.title.text = title; [card setNeedsLayout]; }
            if (![card.sub.text isEqualToString:sub]) { card.sub.text = sub; [card setNeedsLayout]; }
            if (card.bars) { int a, n; SignalBars(&a, &n); [card.bars setActive:a total:n color:on ? UIColor.whiteColor : [UIColor colorWithWhite:0.12 alpha:1]]; }
            NSNumber *last = objc_getAssociatedObject(card, kLastValue);
            if (last.intValue != (int)on) { [card setOn:on animated:last.intValue != -1]; objc_setAssociatedObject(card, kLastValue, @(on), OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            card.enabled = card.target != nil && !gEditing;
            CGFloat al = card.target ? (card.target.enabled ? 1 : 0.5) : 0.4;
            if (fabs(card.alpha - al) > 0.01 && ![card.layer animationForKey:@"opacity"]) card.alpha = al;
        }
        y += h + gap;
    }
    for (UIView *v in [self.subviews copy]) if ([v isKindOfClass:[C26ConnCard class]] && ![used containsObject:v]) [v removeFromSuperview];
}
@end

// Apple's own drawing of a module (content and its glass) goes away while ours shows
static void MaskContent(UIView *m, UIView *keep, BOOL hide) {
    for (UIView *v in m.subviews) {
        if (v == keep) continue;
        BOOL masked = [v.layer.mask.name isEqualToString:@"c26.big"];
        if (hide && !masked) { CALayer *mk = [CALayer layer]; mk.name = @"c26.big"; v.layer.mask = mk; }
        if (!hide && masked) v.layer.mask = nil;
    }
}
static BOOL ModuleExpanded(UIView *moduleView) {
    id x = KV(moduleView.nextResponder, @"expanded");
    return [x respondsToSelector:@selector(boolValue)] && [x boolValue];
}
static void StyleBigModules(void) {
    if (gClosing) { HideOurModules(YES); return; }
    HideOurModules(NO);
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) {
        NSString *l = k.lowercaseString;
        BOOL conn = [l containsString:@"connectivity"], music = [l containsString:@"nowplaying"] || [l containsString:@"mediacontrols"];
        if ((!conn && !music) || IsCopy(k)) continue;
        UIView *m = mm[k];
        C26Rect r;
        BOOL big = gEnabled && gEditUI && m.window && LayoutRectFor(k, &r) && r.size.width >= 4 && !ModuleExpanded(m) && (conn ? r.size.height >= 4 : r.size.height >= 2);
        UIView *bv = [m viewWithTag:BIG_TAG];
        if (!big) { if (bv) { [bv removeFromSuperview]; MaskContent(m, nil, NO); } continue; }
        if (!bv) {
            bv = conn ? [[C26BigConn alloc] initWithFrame:m.bounds] : [[C26BigPlayer alloc] initWithFrame:m.bounds];
            bv.alpha = 0;
            [m addSubview:bv];
            [UIView animateWithDuration:0.35 animations:^{ bv.alpha = 1; }];
        }
        MaskContent(m, bv, YES);
        if (m.subviews.lastObject != bv) [m bringSubviewToFront:bv];
        if (!CGRectEqualToRect(bv.frame, m.bounds)) bv.frame = m.bounds;
        bv.userInteractionEnabled = !gEditing;
        if (conn) { C26BigConn *c = (C26BigConn *)bv; c.rows = (int)r.size.height; c.apple = m; [c refresh]; }
        else { C26BigPlayer *p = (C26BigPlayer *)bv; int md = r.size.height >= 6 ? 6 : (r.size.height >= 4 ? 4 : 2); if (p.mode != md) { p.mode = md; [p setNeedsLayout]; objc_setAssociatedObject(p.play, kLastValue, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); } [p refresh]; }
    }
}

// A second Connectivity / Music on another page: drawn by us, it works the real one.
static void StyleCopies(void) {
    if (gClosing) { if (gCopyRoot) gCopyRoot.alpha = 0; return; }
    UIView *root = gCCVC.viewIfLoaded, *cv = CollectionView();
    NSArray *cps = SavedCopies();
    if (!gCopyViews) gCopyViews = [NSMutableDictionary dictionary];
    for (NSString *k in [gCopyViews allKeys]) if (![cps containsObject:k] || !root) { [gCopyViews[k] removeFromSuperview]; [gCopyViews removeObjectForKey:k]; }
    if (!root || !cv.window || !cps.count || !gEnabled || !gEditUI) { [gCopyRoot removeFromSuperview]; return; }
    UIView *cr = gCopyRoot;
    if (!cr || cr.superview != root) {
        [cr removeFromSuperview];
        cr = [[C26PassView alloc] initWithFrame:root.bounds];
        cr.tag = COPYROOT_TAG; gCopyRoot = cr;
        UIView *content = KV(gCCVC, @"overlayContainerView");
        if ([content isKindOfClass:[UIView class]] && content.superview == root) [root insertSubview:cr aboveSubview:content]; else [root addSubview:cr];
    }
    if (!CGRectEqualToRect(cr.frame, root.bounds)) cr.frame = root.bounds;
    UIView *e = EditRoot(NO);
    if (e && [root.subviews indexOfObject:cr] > [root.subviews indexOfObject:e]) [root insertSubview:cr belowSubview:e];
    C26Grid gr = GridIn(cv);
    UIView *realConn = nil;
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) if (!IsCopy(k) && [k.lowercaseString containsString:@"connectivity"]) realConn = mm[k];
    for (NSString *k in cps) {
        C26Rect r;
        if (!gr.ok || !LayoutRectFor(k, &r)) { [gCopyViews[k] setHidden:YES]; continue; }
        BOOL conn = [k containsString:@"connectivity"];
        UIView *v = gCopyViews[k];
        if (!v) {
            v = conn ? [[C26BigConn alloc] initWithFrame:CGRectZero] : [[C26BigPlayer alloc] initWithFrame:CGRectZero];
            v.alpha = 0; [cr addSubview:v]; gCopyViews[k] = v;
            [UIView animateWithDuration:0.35 animations:^{ v.alpha = 1; }];
        }
        v.hidden = NO;
        CGRect a = GridCell(gr, (int)r.origin.x, (int)r.origin.y), b = GridCell(gr, (int)(r.origin.x + r.size.width - 1), (int)(r.origin.y + r.size.height - 1));
        CGRect f = [cv convertRect:CGRectUnion(a, b) toView:cr];
        if (CGAffineTransformIsIdentity(v.transform)) { if (!CGRectEqualToRect(v.frame, f)) v.frame = f; }
        else { v.bounds = CGRectMake(0, 0, f.size.width, f.size.height); v.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f)); }
        if (gEditing) v.userInteractionEnabled = NO;
        if (conn) { C26BigConn *c = (C26BigConn *)v; c.rows = (int)r.size.height; c.apple = realConn; [c refresh]; }
        else { C26BigPlayer *p = (C26BigPlayer *)v; int md = r.size.height >= 6 ? 6 : (r.size.height >= 4 ? 4 : 2); if (p.mode != md) { p.mode = md; [p setNeedsLayout]; objc_setAssociatedObject(p.play, kLastValue, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); } [p refresh]; }
    }
}
// a new copy goes in the first free spot on the page you're looking at
static void AddCopy(NSString *kind) {
    if (!SavedPos().count) FreezeLayout();
    NSString *ident = [NSString stringWithFormat:@"%@%@.%llu", COPY_PREFIX, kind, (unsigned long long)([NSDate date].timeIntervalSince1970 * 1000)];
    C26Size sz = CopyDefaultSize(ident);
    int page = CurrentPage();
    BOOL occ[7][4]; memset(occ, 0, sizeof(occ));
    for (NSString *k in ModuleMap()) {
        C26Rect r;
        if (!LayoutRectFor(k, &r) || (int)r.origin.y / PAGE_ROWS != page) continue;
        for (unsigned long long y = r.origin.y; y < r.origin.y + r.size.height; y++) for (unsigned long long x = r.origin.x; x < r.origin.x + r.size.width && x < 4; x++) { int yy = (int)y - page * PAGE_ROWS; if (yy >= 0 && yy < PAGE_ROWS) occ[yy][x] = YES; }
    }
    int fx = -1, fy = -1;
    for (int y = 0; y + (int)sz.height <= PAGE_ROWS && fx < 0; y++) for (int x = 0; x + (int)sz.width <= 4 && fx < 0; x++) {
        BOOL ok = YES;
        for (int yy = y; yy < y + (int)sz.height && ok; yy++) for (int xx = x; xx < x + (int)sz.width; xx++) if (occ[yy][xx]) { ok = NO; break; }
        if (ok) { fx = x; fy = y; }
    }
    NSMutableArray *cps = [SavedCopies() mutableCopy];
    [cps addObject:ident];
    [LayoutDefaults() setObject:cps forKey:@"copies"];
    if (fx >= 0) SetPos(ident, fx, page * PAGE_ROWS + fy);
    RelayoutCC();
}

// ---- pages: Control Center becomes pages of 4 x 7 spots; swipe up / down between them ----
static int PagesWanted(void) { NSInteger n = [LayoutDefaults() integerForKey:@"pages"]; return (int)MAX(1, MIN(6, n)); }
static int UsedPages(void) {
    int maxRow = 0;
    NSDictionary *mm = ModuleMap();
    for (NSString *k in mm) { C26Rect r; if (LayoutRectFor(k, &r)) maxRow = MAX(maxRow, (int)(r.origin.y + r.size.height)); }
    return MAX(1, (maxRow + PAGE_ROWS - 1) / PAGE_ROWS);
}
static int PageCount(void) { return MAX(UsedPages(), gEditing ? PagesWanted() : 1); }
static UIScrollView *CCScroll(void) { id s = KV(gCCVC, @"overlayScrollView"); return [s isKindOfClass:[UIScrollView class]] ? s : nil; }
static CGFloat PageOffset(int p) {
    UIScrollView *sv = CCScroll(); UIView *cv = CollectionView();
    C26Grid gr = GridIn(cv);
    CGFloat rest = -sv.adjustedContentInset.top;
    if (!gr.ok || p <= 0) return rest;
    CGFloat t0 = [cv convertPoint:CGPointMake(0, gr.ys[0]) toView:sv].y, tp = [cv convertPoint:CGPointMake(0, gr.ys[MIN(47, p * PAGE_ROWS)]) toView:sv].y;
    CGFloat maxOff = MAX(rest, sv.contentSize.height + sv.adjustedContentInset.bottom - sv.bounds.size.height);
    return MIN(maxOff, rest + tp - t0);
}
static int CurrentPage(void) {
    UIScrollView *sv = CCScroll();
    int best = 0; CGFloat bd = CGFLOAT_MAX;
    for (int p = 0; p < PageCount(); p++) { CGFloat d = fabs(PageOffset(p) - sv.contentOffset.y); if (d < bd) { bd = d; best = p; } }
    return best;
}
// One frame-by-frame spring driver: page scrolling (so every frame updates the fades and copies,
// not just the end) and shrinking the controls while you scrub the page icons.
static double gShrink = 1, gShrinkV, gShrinkT = 1;
static double gScrY, gScrV, gScrT;
static void ApplyShrink(double s) {
    CATransform3D t = fabs(s - 1) < 0.0005 ? CATransform3DIdentity : CATransform3DMakeScale(s, s, 1);
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (UIView *m in ModuleMap().allValues) if (!CATransform3DEqualToTransform(m.layer.sublayerTransform, t)) m.layer.sublayerTransform = t;
    UIView *e = gEditing ? EditRoot(NO) : nil;
    for (UIView *x in e.subviews) if (x.tag == 4) x.layer.sublayerTransform = t;   // the glow follows its control
    [CATransaction commit];
}
@interface C26Springs : NSObject
+ (instancetype)shared;
- (void)kick;
@end
@implementation C26Springs { CADisplayLink *_dl; CFTimeInterval _last; }
+ (instancetype)shared { static C26Springs *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26Springs new]; }); return s; }
- (void)kick {
    if (_dl) return;
    _last = 0;
    _dl = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
    if (@available(iOS 15.0, *)) _dl.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 60);
    [_dl addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)step:(CADisplayLink *)d {
    double dt = _last ? MIN(0.05, d.timestamp - _last) : 1 / 60.0;
    _last = d.timestamp;
    BOOL busy = NO;
    @try {
        if (gShrink != gShrinkT || gShrinkV != 0) {
            double k = 300, c = 2 * sqrt(k) * 0.78;
            gShrinkV += (k * (gShrinkT - gShrink) - c * gShrinkV) * dt;
            gShrink += gShrinkV * dt;
            if (fabs(gShrinkT - gShrink) < 0.0004 && fabs(gShrinkV) < 0.003) { gShrink = gShrinkT; gShrinkV = 0; } else busy = YES;
            ApplyShrink(gShrink);
        }
        if (gScrOn) {
            UIScrollView *sv = CCScroll();
            if (!sv || sv.tracking || gClosing) gScrOn = NO;
            else {
                double k = 190, c = 2 * sqrt(k) * 0.92;
                gScrV += (k * (gScrT - gScrY) - c * gScrV) * dt;
                gScrY += gScrV * dt;
                if (fabs(gScrT - gScrY) < 0.4 && fabs(gScrV) < 6) { gScrY = gScrT; gScrOn = NO; }
                else busy = YES;
                sv.contentOffset = CGPointMake(sv.contentOffset.x, gScrY);
                if (!gScrOn && gEditing) UpdateEditUI(NO);
            }
        }
    } @catch (__unused id e) { busy = NO; }
    if (!busy) { [_dl invalidate]; _dl = nil; }
}
@end
static void SetShrink(double target) { gShrinkT = target; [[C26Springs shared] kick]; }
static void ScrollToPage(int p) {
    UIScrollView *sv = CCScroll();
    if (!sv) return;
    CGFloat y = PageOffset(MAX(0, MIN(PageCount() - 1, p)));
    if (!gScrOn) { [sv setContentOffset:sv.contentOffset animated:NO]; gScrY = sv.contentOffset.y; gScrV = 0; }
    gScrT = y; gScrOn = YES;
    [[C26Springs shared] kick];
}
// a swipe always lands on a page
static void (*origWillEnd)(id, SEL, id, CGPoint, CGPoint *);
static void WillEnd(id self, SEL _cmd, UIScrollView *sv, CGPoint v, CGPoint *target) {
    if (origWillEnd) origWillEnd(self, _cmd, sv, v, target);
    @try {
        if (!target || sv != CCScroll() || !gEnabled || !gEditUI || PageCount() < 2) return;
        int cur = CurrentPage(), n = PageCount();
        int p = cur;
        if (v.y > 0.25) p = cur + 1; else if (v.y < -0.25) p = cur - 1;
        else { CGFloat bd = CGFLOAT_MAX; for (int i = 0; i < n; i++) { CGFloat d = fabs(PageOffset(i) - target->y); if (d < bd) { bd = d; p = i; } } }
        p = MAX(0, MIN(n - 1, p));
        target->y = PageOffset(p);
        if (p != cur) [[UISelectionFeedbackGenerator new] selectionChanged];
    } @catch (__unused id e) {}
}
static void InstallPaging(UIViewController *vc) {
    static BOOL done;
    UIScrollView *sv = CCScroll();
    if (done || !sv || !vc) return;
    done = YES;
    Class C = [vc class];
    SEL s = @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:);
    if (class_getInstanceMethod(C, s) && class_getMethodImplementation(C, s) != (IMP)WillEnd) MSHookMessageEx(C, s, (IMP)WillEnd, (IMP *)&origWillEnd);
    else class_addMethod(C, s, (IMP)WillEnd, "v@:@{CGPoint=dd}^{CGPoint=dd}");
    // the scroll view remembers what its delegate can do when the delegate is set
    id d = sv.delegate; sv.delegate = nil; sv.delegate = d;
}
// empty pages go away when editing ends (later pages move up)
static void CompactPages(void) {
    NSDictionary *pos = SavedPos();
    int used = UsedPages();
    BOOL fewer = used < PagesWanted();
    [LayoutDefaults() setInteger:used forKey:@"pages"];
    if (fewer) { if (gClosing) gNeedRelayout = YES; else RelayoutCC(); }
    if (!pos.count) return;
    NSMutableSet *busy = [NSMutableSet set];
    for (NSString *k in ModuleMap()) { C26Rect r; if (LayoutRectFor(k, &r)) [busy addObject:@((int)r.origin.y / PAGE_ROWS)]; }
    NSMutableDictionary *np = [pos mutableCopy];
    BOOL changed = NO;
    for (int p = used - 1; p >= 0; p--) {
        if ([busy containsObject:@(p)]) continue;
        for (NSString *k in pos) {
            NSArray *xy = [np[k] componentsSeparatedByString:@","];
            if (xy.count != 2) continue;
            int y = [xy[1] intValue];
            if (y >= (p + 1) * PAGE_ROWS) { np[k] = [NSString stringWithFormat:@"%@,%d", xy[0], y - PAGE_ROWS]; changed = YES; }
        }
    }
    if (changed) { [LayoutDefaults() setObject:np forKey:@"pos"]; if (gClosing) gNeedRelayout = YES; else RelayoutCC(); }
}
static const void *kPageMask = &kPageMask;
static void ApplyPageVisibility(void) {
    UIScrollView *sv = CCScroll();
    if (!sv) return;
    int n = PageCount();
    BOOL on = gEnabled && gEditUI && n > 1 && !gClosing;
    CGFloat f = 0;
    if (on) { CGFloat o0 = PageOffset(0), o1 = PageOffset(1), ph = o1 - o0; if (ph > 1) f = (sv.contentOffset.y - o0) / ph; else on = NO; }
    NSDictionary *mm = ModuleMap();
    NSMutableDictionary *alphaById = [NSMutableDictionary dictionary];
    for (NSString *k in mm) {
        UIView *m = mm[k]; C26Rect r;
        int q = LayoutRectFor(k, &r) ? (int)r.origin.y / PAGE_ROWS : 0;
        CGFloat a = on ? MAX(0, MIN(1, 1 - fabs(q - f) * 1.4)) : 1;
        alphaById[k] = @(a);
        if (ModuleExpanded(m)) a = 1;
        CALayer *mk = objc_getAssociatedObject(m, kPageMask);
        if (a >= 0.999) {
            if (mk && m.layer.mask == mk) m.layer.mask = nil;
            objc_setAssociatedObject(m, kPageMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
            if (!mk) { mk = [CALayer layer]; mk.backgroundColor = UIColor.blackColor.CGColor; objc_setAssociatedObject(m, kPageMask, mk, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            if (m.layer.mask != mk && !m.layer.mask) m.layer.mask = mk;
            [CATransaction begin]; [CATransaction setDisableActions:YES];
            mk.frame = CGRectInset(m.bounds, -40, -40); mk.opacity = a;
            [CATransaction commit];
        }
        // half-hidden controls of the next page can't be tapped by accident
        if (!gEditing) m.userInteractionEnabled = a > 0.5;
    }
    // the edit layer (glow, handles, badges, circles) follows the same pages
    UIView *e = gEditing ? EditRoot(NO) : nil;
    for (UIView *x in e.subviews) {
        NSString *i = objc_getAssociatedObject(x, kEditIdent);
        if (x.tag < 1 || x.tag > 4 || ![i isKindOfClass:[NSString class]]) continue;
        NSNumber *a = alphaById[i];
        if (a && fabs(x.alpha - a.doubleValue) > 0.01 && ![x.layer animationForKey:@"opacity"]) x.alpha = a.doubleValue;
        x.userInteractionEnabled = !a || a.doubleValue > 0.5;
    }
    UIView *g = [e viewWithTag:GRID_TAG];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (CALayer *l in g.layer.sublayers) { int q = [[l.name substringFromIndex:1] intValue]; l.opacity = on ? MAX(0, MIN(1, 1 - fabs(q - f) * 1.4)) : 1; }
    [CATransaction commit];
}
// the page icons on the right: tap one, or slide your finger along them
@interface C26PageCtl : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26PageCtl { int _hover; }
+ (instancetype)shared { static C26PageCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26PageCtl new]; }); return s; }
- (void)dot:(UIButton *)b { [[UISelectionFeedbackGenerator new] selectionChanged]; ScrollToPage((int)b.tag - 100); }
- (void)addPage:(UIButton *)b {
    Pop(b);
    int n = MIN(6, PageCount() + 1);
    [LayoutDefaults() setInteger:n forKey:@"pages"];
    if (!SavedPos().count) FreezeLayout();
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    RelayoutCC();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ScrollToPage(n - 1); });
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    // the + (add page) button keeps its own tap
    for (UIView *v = t.view; v && v != g.view; v = v.superview) if ([v isKindOfClass:[UIButton class]] && (v.tag < 100 || v.tag >= 110)) return NO;
    return YES;
}
- (void)scrub:(UIGestureRecognizer *)g {
    UIView *dots = g.view;
    UIScrollView *sv = CCScroll();
    if (sv && !CGAffineTransformIsIdentity(sv.transform)) sv.transform = CGAffineTransformIdentity;   // older versions scaled it
    int n = PageCount();
    CGFloat y = [g locationInView:dots].y;
    int idx = MAX(0, MIN(n - 1, (int)floor(y / 54)));
    BOOL live = g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged;
    if (g.state == UIGestureRecognizerStateBegan) { _hover = -1; SetShrink(0.9); }
    // magnify like the Dock: the icon under your finger the most, its neighbours a bit
    for (UIView *b in dots.subviews) if (b.tag >= 100 && b.tag < 110) {
        CGFloat t = live ? MAX(0, 1 - fabs(y - b.center.y) / 80) : 0;
        t = t * t * (3 - 2 * t);
        CGAffineTransform want = CGAffineTransformScale(CGAffineTransformMakeTranslation(-10 * t, 0), 1 + 0.6 * t, 1 + 0.6 * t);
        if (g.state == UIGestureRecognizerStateBegan || !live)
            [UIView animateWithDuration:live ? 0.3 : 0.45 delay:0 usingSpringWithDamping:live ? 0.8 : 0.72 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = want; } completion:nil];
        else b.transform = want;
    }
    if (live) {
        if (idx != _hover) { _hover = idx; [[UISelectionFeedbackGenerator new] selectionChanged]; ScrollToPage(idx); }
        return;
    }
    SetShrink(1);
}
@end
static NSString *PageSymbol(int p) {
    if (p == 0) return @"heart.fill";
    NSDictionary *mm = ModuleMap();
    NSString *best = nil; unsigned long long area = 0;
    for (NSString *k in mm) {
        C26Rect r;
        if (!LayoutRectFor(k, &r) || (int)r.origin.y / PAGE_ROWS != p) continue;
        if (r.size.width * r.size.height > area) { area = r.size.width * r.size.height; best = k.lowercaseString; }
    }
    if ([best containsString:@"connectivity"]) return @"antenna.radiowaves.left.and.right";
    if ([best containsString:@"nowplaying"] || [best containsString:@"media"]) return @"music.note";
    if ([best containsString:@"home"]) return @"house.fill";
    return best ? @"square.grid.2x2.fill" : @"circle";
}
static void PlaceDots(void) {
    UIView *root = gCCVC.viewIfLoaded;
    if (!root) return;
    InstallPaging(gCCVC);
    UIView *dots = [root viewWithTag:PAGEDOTS_TAG];
    BOOL landscape = root.bounds.size.width > root.bounds.size.height;
    int n = PageCount();
    BOOL show = gEnabled && gEditUI && !landscape && !gClosing && (n > 1 || gEditing);
    if (!dots) {
        dots = [[UIView alloc] initWithFrame:CGRectZero]; dots.tag = PAGEDOTS_TAG; dots.alpha = 0;
        // starts as soon as you rest a finger on the icons (no need to move first)
        UILongPressGestureRecognizer *pg = [[UILongPressGestureRecognizer alloc] initWithTarget:[C26PageCtl shared] action:@selector(scrub:)];
        pg.minimumPressDuration = 0.12; pg.allowableMovement = CGFLOAT_MAX;
        pg.delegate = (id<UIGestureRecognizerDelegate>)[C26PageCtl shared];
        [dots addGestureRecognizer:pg];
        [root addSubview:dots];
    }
    int cur = CurrentPage();
    NSString *sig = [NSString stringWithFormat:@"%d|%d", n, gEditing];
    NSMutableString *syms = [NSMutableString string];
    for (int p = 0; p < n; p++) [syms appendFormat:@"%@,", PageSymbol(p)];
    sig = [sig stringByAppendingString:syms];
    if (![objc_getAssociatedObject(dots, kEditIdent) isEqual:sig]) {
        objc_setAssociatedObject(dots, kEditIdent, sig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        for (UIView *v in [dots.subviews copy]) [v removeFromSuperview];
        for (int p = 0; p < n; p++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.tag = 100 + p;
            [b setImage:[UIImage systemImageNamed:PageSymbol(p) withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
            b.frame = CGRectMake(0, p * 54, 36, 44);
            b.userInteractionEnabled = NO;   // tapping an icon is off; hold and slide along them instead
            [dots addSubview:b];
        }
        if (gEditing && n < 6) {
            UIButton *add = GlassButton(@"plus", 14);
            add.frame = CGRectMake(2, n * 54 + 4, 32, 32); RoundGlass(add);
            [add addTarget:[C26PageCtl shared] action:@selector(addPage:) forControlEvents:UIControlEventTouchUpInside];
            [dots addSubview:add];
        }
    }
    CGFloat h = n * 54 + (gEditing ? 44 : 0);
    // sit in the space right of the controls; on narrow phones that space is small, so the icons get smaller
    CGFloat right = root.bounds.size.width - 40;
    UIView *gcv = CollectionView();
    C26Grid gg = gcv ? GridIn(gcv) : (C26Grid){0};
    if (gg.ok) right = CGRectGetMaxX([gcv convertRect:GridCell(gg, 3, 0) toView:root]);
    CGFloat margin = MAX(12, root.bounds.size.width - right);
    CGFloat sc = margin >= 40 ? 1 : MAX(0.5, (margin - 2) / 36);
    CGRect f = CGRectMake(right + (margin - 36) / 2, (root.bounds.size.height - h) / 2, 36, h);
    if (margin >= 40) f.origin.x = root.bounds.size.width - 40;
    CGAffineTransform dt = sc < 1 ? CGAffineTransformMakeScale(sc, sc) : CGAffineTransformIdentity;
    // bounds + center work with a scale applied (frame doesn't)
    CGRect bb = CGRectMake(0, 0, 36, h); CGPoint cc = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
    if (!CGRectEqualToRect(dots.bounds, bb)) dots.bounds = bb;
    if (!CGPointEqualToPoint(dots.center, cc)) dots.center = cc;
    if (!CGAffineTransformEqualToTransform(dots.transform, dt)) dots.transform = dt;
    for (UIView *b in dots.subviews) if (b.tag >= 100 && b.tag < 110) b.tintColor = [UIColor colorWithWhite:1 alpha:(b.tag - 100 == cur) ? 1 : 0.42];
    CGFloat a = show ? 1 : 0;
    if (fabs(dots.alpha - a) > 0.01 && ![dots.layer animationForKey:@"opacity"]) [UIView animateWithDuration:0.25 animations:^{ dots.alpha = a; }];
    dots.userInteractionEnabled = show;
    if (root.subviews.lastObject != dots) [root bringSubviewToFront:dots];
}

// ---- layout presets ----
static NSDictionary *Presets(void) { NSDictionary *d = [LayoutDefaults() dictionaryForKey:@"presets"]; return [d isKindOfClass:[NSDictionary class]] ? d : @{}; }
static void SavePreset(NSString *name) {
    NSMutableDictionary *all = [Presets() mutableCopy];
    all[name] = @{@"pos": SavedPos(), @"posOrder": SavedPosOrder(), @"sizes": SavedSizes(), @"enabled": IdList(@"orderedUserEnabledModuleIdentifiers")};
    [LayoutDefaults() setObject:all forKey:@"presets"];
}
static void ApplyLayout(NSDictionary *p) {
    NSDictionary *pos = [p[@"pos"] isKindOfClass:[NSDictionary class]] ? p[@"pos"] : @{};
    NSArray *ord = [p[@"posOrder"] isKindOfClass:[NSArray class]] ? p[@"posOrder"] : @[];
    NSDictionary *sizes = [p[@"sizes"] isKindOfClass:[NSDictionary class]] ? p[@"sizes"] : @{};
    [LayoutDefaults() setObject:pos forKey:@"pos"];
    [LayoutDefaults() setObject:ord forKey:@"posOrder"];
    [LayoutDefaults() setObject:sizes forKey:@"sizes"];
    NSArray *en = p[@"enabled"];
    if ([en isKindOfClass:[NSArray class]] && en.count) SetUserEnabled(en);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RelayoutCC(); UpdateEditUI(YES); });
}
static void ShowPresets(void);
@interface C26PresetCtl : NSObject
+ (instancetype)shared;
@end
@implementation C26PresetCtl
+ (instancetype)shared { static C26PresetCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [C26PresetCtl new]; }); return s; }
- (void)open:(UIButton *)b { Pop(b); ShowPresets(); }
- (void)close:(id)x {
    UIView *sh = [gCCVC.viewIfLoaded viewWithTag:PRESET_TAG];
    UIView *panel = [sh viewWithTag:2];
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.92 initialSpringVelocity:0 options:0 animations:^{ sh.backgroundColor = UIColor.clearColor; panel.transform = CGAffineTransformMakeScale(0.85, 0.85); panel.alpha = 0; } completion:^(__unused BOOL f) { [sh removeFromSuperview]; EditRoot(NO).hidden = NO; }];
}
- (void)save:(id)x {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Save Layout" message:@"Give this layout a name." preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"My Layout"; tf.autocapitalizationType = UITextAutocapitalizationTypeWords; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x2) {
        NSString *n = [a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (!n.length) n = [NSString stringWithFormat:@"Layout %lu", (unsigned long)Presets().count + 1];
        SavePreset(n);
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
        [[gCCVC.viewIfLoaded viewWithTag:PRESET_TAG] removeFromSuperview];
        ShowPresets();
    }]];
    [gCCVC presentViewController:a animated:YES completion:nil];
}
- (void)apply:(UIButton *)b {
    NSString *n = objc_getAssociatedObject(b, kEditIdent);
    NSDictionary *p = Presets()[n];
    if (!p) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    ApplyLayout(p);
    [self close:nil];
}
- (void)del:(UIButton *)b {
    NSString *n = objc_getAssociatedObject(b, kEditIdent);
    NSMutableDictionary *all = [Presets() mutableCopy];
    [all removeObjectForKey:n];
    [LayoutDefaults() setObject:all forKey:@"presets"];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    [[gCCVC.viewIfLoaded viewWithTag:PRESET_TAG] removeFromSuperview];
    ShowPresets();
}
- (void)reset:(id)x {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Reset Layout?" message:@"Every control goes back to Apple's order and size." preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *x2) {
        [LayoutDefaults() removeObjectForKey:@"pos"]; [LayoutDefaults() removeObjectForKey:@"posOrder"]; [LayoutDefaults() removeObjectForKey:@"sizes"];
        [self close:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RelayoutCC(); UpdateEditUI(YES); });
    }]];
    [gCCVC presentViewController:a animated:YES completion:nil];
}
@end
static UIButton *SheetRow(NSString *title, NSString *sym, UIColor *tint, CGRect f) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = f; b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12]; b.layer.cornerRadius = f.size.height / 2; b.layer.cornerCurve = kCACornerCurveContinuous;
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    b.contentEdgeInsets = UIEdgeInsetsMake(0, 18, 0, 18); b.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    b.tintColor = tint; [b setTitleColor:tint forState:UIControlStateNormal];
    return b;
}
static void ShowPresets(void) {
    UIView *root = gCCVC.viewIfLoaded;
    if (!root || [root viewWithTag:PRESET_TAG]) return;
    EditRoot(NO).hidden = YES;
    UIView *sh = [[UIView alloc] initWithFrame:root.bounds]; sh.tag = PRESET_TAG;
    UIButton *dim = [UIButton buttonWithType:UIButtonTypeCustom]; dim.frame = sh.bounds;
    [dim addTarget:[C26PresetCtl shared] action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [sh addSubview:dim];
    NSArray *names = [Presets().allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    CGFloat W = root.bounds.size.width - 32, rowH = 54, H = 70 + (names.count + 2) * (rowH + 10) + 20;
    H = MIN(H, root.bounds.size.height * 0.7);
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    panel.tag = 2; panel.frame = CGRectMake(16, (root.bounds.size.height - H) / 2, W, H);
    panel.layer.cornerRadius = 36; panel.layer.cornerCurve = kCACornerCurveContinuous; panel.clipsToBounds = YES;
    panel.layer.borderWidth = 1; panel.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    [sh addSubview:panel];
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, W, 28)];
    t.text = @"Layouts"; t.textAlignment = NSTextAlignmentCenter; t.textColor = UIColor.whiteColor; t.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    [panel.contentView addSubview:t];
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 66, W, H - 66)];
    [panel.contentView addSubview:sv];
    CGFloat y = 4;
    UIButton *save = SheetRow(@"Save Current Layout", @"plus.circle.fill", UIColor.systemBlueColor, CGRectMake(16, y, W - 32, rowH));
    [save addTarget:[C26PresetCtl shared] action:@selector(save:) forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:save]; y += rowH + 10;
    for (NSString *n in names) {
        UIButton *r = SheetRow(n, @"square.grid.2x2.fill", UIColor.whiteColor, CGRectMake(16, y, W - 32 - rowH - 10, rowH));
        objc_setAssociatedObject(r, kEditIdent, n, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [r addTarget:[C26PresetCtl shared] action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];
        [sv addSubview:r];
        UIButton *d = SheetRow(@"", @"trash.fill", UIColor.systemRedColor, CGRectMake(W - 16 - rowH, y, rowH, rowH));
        d.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter; d.contentEdgeInsets = UIEdgeInsetsZero; d.titleEdgeInsets = UIEdgeInsetsZero;
        objc_setAssociatedObject(d, kEditIdent, n, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [d addTarget:[C26PresetCtl shared] action:@selector(del:) forControlEvents:UIControlEventTouchUpInside];
        [sv addSubview:d];
        y += rowH + 10;
    }
    UIButton *reset = SheetRow(@"Reset to Apple's Layout", @"arrow.counterclockwise", UIColor.systemRedColor, CGRectMake(16, y, W - 32, rowH));
    [reset addTarget:[C26PresetCtl shared] action:@selector(reset:) forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:reset]; y += rowH + 10;
    sv.contentSize = CGSizeMake(W, y + 10);
    [root addSubview:sh];
    panel.transform = CGAffineTransformMakeScale(0.85, 0.85); panel.alpha = 0;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ sh.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3]; panel.transform = CGAffineTransformIdentity; panel.alpha = 1; } completion:nil];
}
// the Layouts button (left of Add a Control) while editing
static void PlacePresetButton(UIView *e) {
    UIButton *b = (UIButton *)[e viewWithTag:PRESETBTN_TAG];
    UIView *add = [e viewWithTag:ADDBTN_TAG];
    if (!add) return;
    if (!b) {
        b = GlassButton(@"square.stack.3d.up.fill", 17); b.tag = PRESETBTN_TAG;
        [b addTarget:[C26PresetCtl shared] action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
        b.alpha = 0; [e addSubview:b];
        [UIView animateWithDuration:0.35 animations:^{ b.alpha = 1; }];
    }
    CGFloat d = add.bounds.size.height;
    CGRect f = CGRectMake(CGRectGetMinX(add.frame) - d - 12, CGRectGetMinY(add.frame), d, d);
    if (!CGRectEqualToRect(b.frame, f) && CGAffineTransformIsIdentity(b.transform)) { b.frame = f; RoundGlass(b); }
}

#pragma mark - tick

static void Tick(void) {
    BOOL anyVisible = NO;
    UIWindow *win = nil;
    for (UIView *m in [gMediaViews allObjects]) {
        if (m.window && !InControlCenter(m) && InLockScreen(m) && !m.hidden) {
            anyVisible = YES;
            @try { StyleLockStar(m); } @catch (__unused id e) {}
            continue;
        }
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
    // edit mode / top buttons
    @try {
        if (!gCCVC) for (UIView *s in [gSliders allObjects]) { UIViewController *o = s.window ? FindCCVC(s) : nil; if (o) { gCCVC = o; break; } }
        if (gCCVC.viewIfLoaded.window && !gClosing) { PlaceTopButtons(gCCVC); if (gEditing && !gResizing) UpdateEditUI(NO); StyleBigModules(); StyleShapes(); StyleCopies(); PlaceDots(); ApplyPageVisibility(); if (gNeedRelayout) { gNeedRelayout = NO; RelayoutCC(); } }
    } @catch (__unused id e) {}
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
        [cdbg addObject:[NSString stringWithFormat:@"menu=%@ press=%@", gMenuDebug, gPressDebug]];
    }
    if (gDebug) gConnDebug = cdbg.count ? [cdbg componentsJoinedByString:@"\n  "] : @"(hold the Wi-Fi block to open it)";
    if (win) UpdateDebug(win);
    // Control Center closed: stop the timer until it opens again.
    if (!anyVisible) { @try { ExitEdit(NO); } @catch (__unused id e) {} RemoveConnOverlay(); [gTimer invalidate]; gTimer = nil; }
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
- (void)layoutSubviews {
    %orig;
    // Expanded module laying out: style it on the very next turn, not on the timer.
    static BOOL queued;
    if (queued || !self.window || self.bounds.size.width < 100) return;
    queued = YES;
    dispatch_async(dispatch_get_main_queue(), ^{ queued = NO; @try { Tick(); } @catch (__unused id e) {} });
}
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
    @try { TryEditHooks(); } @catch (__unused id e) {}
}

static void StartLateHooks(void) {
    TryLateHooks();
    __block int tries = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        TryLateHooks();
        if ((gMediaHooked && gCCHooked && gMRUHooked && gGlyphHooked && gJ1Hooked && gJ2Hooked && gConnHooked && gEditHooked && gSettingsHooked) || ++tries > 120) [t invalidate];
    }];
}

// Turn off Auto-Brightness through CoreBrightness (what Settings uses).
static void StopAutoBrightness(void) {
    if (!gEnabled || !gNoAuto) return;
    static id client;
    if (!client) {
        dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY);
        Class c = NSClassFromString(@"BrightnessSystemClient");
        if (c) client = [c new];
    }
    SEL set = NSSelectorFromString(@"setProperty:forKey:");
    if (client && [client respondsToSelector:set])
        ((void (*)(id, SEL, id, id))objc_msgSend)(client, set, @NO, @"DisplayBrightnessAuto");
}

#pragma mark - opening animation (iOS 26 drop-in)

// Each control drops in from above, one after another, top row first.
// Additive layer animations only, so nothing fights Apple's own transforms.
static CFTimeInterval gLastDrop;
static void DropInModules(UIViewController *ov) {
    if (!gEnabled || !gDropIn) return;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - gLastDrop < 0.6) return;
    gLastDrop = now;
    UIView *root = [ov isKindOfClass:[UIViewController class]] ? ov.viewIfLoaded : nil;
    if (!root) return;
    NSDictionary *mods = ModuleMap();
    NSMutableArray *items = [NSMutableArray array];
    CGFloat top = CGFLOAT_MAX, bottom = 0;
    for (NSString *k in mods) {
        UIView *v = mods[k];
        if (!v.window || v.hidden || v.alpha < 0.01) continue;
        CGRect f = [v convertRect:v.bounds toView:root];
        if (CGRectIsEmpty(f) || !CGRectIntersectsRect(f, root.bounds)) continue;
        [items addObject:@[v, [NSValue valueWithCGRect:f]]];
        top = MIN(top, CGRectGetMinY(f)); bottom = MAX(bottom, CGRectGetMinY(f));
    }
    if (!items.count) return;
    CGFloat span = MAX(1, bottom - top), W = MAX(1, root.bounds.size.width);
    for (NSArray *it in items) {
        UIView *v = it[0]; CGRect f = [it[1] CGRectValue];
        CFTimeInterval delay = 0.30 * (CGRectGetMinY(f) - top) / span + 0.06 * CGRectGetMinX(f) / W;
        CALayer *l = v.layer;
        CFTimeInterval begin = [l convertTime:CACurrentMediaTime() fromLayer:nil] + delay;
        CASpringAnimation *t = [CASpringAnimation animationWithKeyPath:@"transform.translation.y"];
        t.additive = YES; t.fromValue = @(-46); t.toValue = @0;
        t.mass = 1; t.stiffness = 210; t.damping = 17; t.initialVelocity = 0;
        t.duration = t.settlingDuration;
        CASpringAnimation *sc = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
        sc.additive = YES; sc.fromValue = @(-0.14); sc.toValue = @0;
        sc.mass = 1; sc.stiffness = 210; sc.damping = 15; sc.duration = sc.settlingDuration;
        CABasicAnimation *o = [CABasicAnimation animationWithKeyPath:@"opacity"];
        o.additive = YES; o.fromValue = @(-1); o.toValue = @0; o.duration = 0.26;
        o.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        for (CAAnimation *a in @[t, sc, o]) { a.beginTime = begin; a.fillMode = kCAFillModeBackwards; a.removedOnCompletion = YES; }
        [l addAnimation:t forKey:@"c26.drop.y"];
        [l addAnimation:sc forKey:@"c26.drop.s"];
        [l addAnimation:o forKey:@"c26.drop.o"];
    }
}

#pragma mark - reset (from Settings > Control Center)

static void ResetNote(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            NSUserDefaults *d = LayoutDefaults();
            for (NSString *k in @[@"pos", @"posOrder", @"sizes", @"copies", @"pages"]) [d removeObjectForKey:k];
            [d synchronize];
            Class P = NSClassFromString(@"CCSModuleSettingsProvider");
            SEL s = NSSelectorFromString(@"_defaultUserEnabledModuleIdentifiers");
            id def = [P respondsToSelector:s] ? ((id (*)(id, SEL))objc_msgSend)(P, s) : nil;
            if ([def isKindOfClass:[NSOrderedSet class]]) def = [def array];
            if ([def isKindOfClass:[NSSet class]]) def = [def allObjects];
            if ([def isKindOfClass:[NSArray class]] && [def count]) SetUserEnabled(def);
            if (gEditing) ExitEdit(NO);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { RelayoutCC(); StyleCopies(); } @catch (__unused id e) {} });
        } @catch (__unused id e) {}
    });
}

#pragma mark - Settings > Control Center redesign (runs in the Settings app)

@interface NSObject (C26PS)
+ (id)emptyGroupSpecifier;
+ (id)preferenceSpecifierNamed:(NSString *)n target:(id)t set:(SEL)s get:(SEL)g detail:(Class)d cell:(NSInteger)c edit:(Class)e;
+ (NSInteger)cellTypeFromString:(NSString *)s;
- (id)propertyForKey:(NSString *)k;
- (void)setButtonAction:(SEL)a;
- (NSInteger)cellType;
- (void)setIdentifier:(NSString *)i;
- (UITableView *)table;
- (void)setSpecifiers:(id)s;
@end

static void SP(id spec, id v, NSString *k) { ((void (*)(id, SEL, id, id))objc_msgSend)(spec, @selector(setProperty:forKey:), v, k); }
static NSInteger PSType(NSString *name, NSInteger fallback) {
    Class C = NSClassFromString(@"PSTableCell");
    if ([C respondsToSelector:@selector(cellTypeFromString:)]) return [C cellTypeFromString:name];
    return fallback;
}

// the little phone on the card: swipe down from the top-right, then Control Center pages
@interface C26MiniPhone : UIView
@end
@implementation C26MiniPhone {
    UIView *_screen, *_dot, *_cc, *_strip;
    NSMutableArray<NSArray<UIView *> *> *_pageTiles;
    NSArray<UIView *> *_pips;
    NSUInteger _gen;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.userInteractionEnabled = NO;
        self.layer.cornerRadius = 15; self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 3;
        _screen = [[UIView alloc] init];
        _screen.layer.cornerRadius = 11; _screen.layer.cornerCurve = kCACornerCurveContinuous;
        _screen.clipsToBounds = YES;
        [self addSubview:_screen];
        _cc = [[UIView alloc] init];
        _cc.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.78];
        [_screen addSubview:_cc];
        _strip = [[UIView alloc] init];
        [_cc addSubview:_strip];
        UIView *island = [[UIView alloc] init];
        island.backgroundColor = UIColor.blackColor; island.tag = 7;
        [_screen addSubview:island];
        _dot = [[UIView alloc] init];
        _dot.backgroundColor = UIColor.systemBlueColor;
        [_screen addSubview:_dot];
        NSMutableArray *pips = [NSMutableArray array];
        for (int i = 0; i < 3; i++) { UIView *p = [UIView new]; p.backgroundColor = UIColor.whiteColor; [_cc addSubview:p]; [pips addObject:p]; }
        _pips = pips;
        _pageTiles = [NSMutableArray array];
        [self updateColors];
    }
    return self;
}
- (void)updateColors {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    self.layer.borderColor = (dark ? [UIColor colorWithWhite:0.42 alpha:1] : [UIColor colorWithWhite:0.80 alpha:1]).CGColor;
    _screen.backgroundColor = dark ? [UIColor colorWithRed:0.17 green:0.20 blue:0.30 alpha:1] : [UIColor colorWithRed:0.62 green:0.72 blue:0.92 alpha:1];
}
- (void)traitCollectionDidChange:(UITraitCollection *)p { [super traitCollectionDidChange:p]; [self updateColors]; }
static UIView *Tile(UIView *page, CGRect r, CGFloat radius, UIColor *c) {
    UIView *v = [[UIView alloc] initWithFrame:r];
    v.backgroundColor = c; v.layer.cornerRadius = radius; v.layer.cornerCurve = kCACornerCurveContinuous;
    [page addSubview:v];
    return v;
}
- (void)buildPages {
    for (UIView *v in [_strip.subviews copy]) [v removeFromSuperview];
    [_pageTiles removeAllObjects];
    CGSize S = _screen.bounds.size;
    _strip.frame = CGRectMake(0, 0, S.width, S.height * 3);
    CGFloat pad = 6, gap = 3.2;
    CGFloat cell = (S.width - pad * 2 - gap * 3) / 4;
    UIColor *g = [UIColor colorWithWhite:1 alpha:0.30], *w = [UIColor colorWithWhite:1 alpha:0.92];
    CGFloat y0 = 16;
    CGRect (^R)(int, int, int, int) = ^CGRect(int x, int y, int ww, int hh) {
        return CGRectMake(pad + x * (cell + gap), y0 + y * (cell + gap), ww * cell + (ww - 1) * gap, hh * cell + (hh - 1) * gap);
    };
    for (int p = 0; p < 3; p++) {
        UIView *page = [[UIView alloc] initWithFrame:CGRectMake(0, p * S.height, S.width, S.height)];
        [_strip addSubview:page];
        NSMutableArray *tiles = [NSMutableArray array];
        if (p == 0) {
            // connectivity, music, two small, two sliders, a row of circles
            UIView *conn = Tile(page, R(0, 0, 2, 2), cell * 0.42, g); [tiles addObject:conn];
            CGFloat d = cell * 0.62;
            for (int i = 0; i < 4; i++) {
                CGRect rr = conn.bounds; CGFloat cx = rr.size.width * (i % 2 ? 0.72 : 0.28), cy = rr.size.height * (i / 2 ? 0.72 : 0.28);
                UIView *c = Tile(conn, CGRectMake(cx - d / 2, cy - d / 2, d, d), d / 2, i == 0 ? UIColor.systemOrangeColor : (i < 3 ? UIColor.systemBlueColor : g));
                (void)c;
            }
            [tiles addObject:Tile(page, R(2, 0, 2, 2), cell * 0.42, g)];
            [tiles addObject:Tile(page, R(0, 2, 1, 1), cell / 2, g)];
            [tiles addObject:Tile(page, R(1, 2, 1, 1), cell / 2, w)];
            [tiles addObject:Tile(page, R(2, 2, 1, 2), cell / 2, g)];
            [tiles addObject:Tile(page, R(3, 2, 1, 2), cell / 2, g)];
            [tiles addObject:Tile(page, R(0, 3, 2, 1), cell / 2, g)];
            for (int i = 0; i < 4; i++) [tiles addObject:Tile(page, R(i, 4, 1, 1), cell / 2, i == 1 ? w : g)];
        } else if (p == 1) {
            // a big music player
            UIView *m = Tile(page, R(0, 0, 4, 4), cell * 0.5, g); [tiles addObject:m];
            CGFloat a = m.bounds.size.width * 0.34;
            Tile(m, CGRectMake(m.bounds.size.width * 0.12, m.bounds.size.width * 0.12, a, a), 4, UIColor.systemPinkColor);
            Tile(m, CGRectMake(m.bounds.size.width * 0.12, m.bounds.size.height * 0.62, m.bounds.size.width * 0.76, 2.5), 1.25, w);
            for (int i = 0; i < 3; i++) Tile(m, CGRectMake(m.bounds.size.width * (0.26 + i * 0.2), m.bounds.size.height * 0.75, 6, 6), 3, w);
            for (int i = 0; i < 4; i++) [tiles addObject:Tile(page, R(i, 4, 1, 1), cell / 2, g)];
        } else {
            // a page of round buttons, like a keypad
            for (int y = 0; y < 5; y++) for (int x = 0; x < 4; x++)
                [tiles addObject:Tile(page, R(x, y, 1, 1), cell / 2, (x + y) % 5 == 0 ? w : g)];
        }
        [_pageTiles addObject:tiles];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect sr = CGRectInset(self.bounds, 5, 5);
    if (!CGRectEqualToRect(_screen.frame, sr)) {
        _screen.frame = sr;
        _cc.frame = _screen.bounds;
        [_screen viewWithTag:7].frame = CGRectMake(sr.size.width / 2 - 9, 4, 18, 5);
        [_screen viewWithTag:7].layer.cornerRadius = 2.5;
        _dot.bounds = CGRectMake(0, 0, 7, 7); _dot.layer.cornerRadius = 3.5;
        for (NSUInteger i = 0; i < _pips.count; i++) { _pips[i].frame = CGRectMake(sr.size.width - 4, sr.size.height / 2 - 8 + i * 6, 2.6, 2.6); _pips[i].layer.cornerRadius = 1.3; }
        [self buildPages];
        [self restart];
    }
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self restart]; }
- (void)restart {
    _gen++;
    if (!self.window || CGRectIsEmpty(_screen.bounds)) return;
    [self loop:_gen];
}
- (void)after:(CGFloat)t gen:(NSUInteger)g do:(void (^)(void))b {
    __weak C26MiniPhone *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ C26MiniPhone *s = ws; if (s && s->_gen == g && s.window) b(); });
}
- (void)showPage:(NSUInteger)p {
    CGFloat H = _screen.bounds.size.height;
    for (NSUInteger i = 0; i < _pips.count; i++) _pips[i].alpha = i == p ? 0.95 : 0.35;
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{ self->_strip.transform = CGAffineTransformMakeTranslation(0, -H * p); } completion:nil];
    NSArray *tiles = _pageTiles[p];
    for (NSUInteger i = 0; i < tiles.count; i++) {
        UIView *t = tiles[i];
        t.alpha = 0; t.transform = CGAffineTransformMakeTranslation(0, -7);
        [UIView animateWithDuration:0.45 delay:0.12 + i * 0.025 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{ t.alpha = 1; t.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)loop:(NSUInteger)g {
    CGSize S = _screen.bounds.size;
    _cc.alpha = 0; _strip.transform = CGAffineTransformIdentity;
    _dot.center = CGPointMake(S.width - 9, 7); _dot.alpha = 0; _dot.transform = CGAffineTransformIdentity;
    [self after:0.35 gen:g do:^{
        [UIView animateWithDuration:0.2 animations:^{ self->_dot.alpha = 1; }];
        [UIView animateWithDuration:0.55 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{ self->_dot.center = CGPointMake(S.width - 9, 40); } completion:nil];
        [UIView animateWithDuration:0.2 delay:0.65 options:0 animations:^{ self->_dot.alpha = 0; self->_dot.transform = CGAffineTransformMakeScale(0.4, 0.4); } completion:nil];
    }];
    [self after:1.05 gen:g do:^{
        [UIView animateWithDuration:0.3 animations:^{ self->_cc.alpha = 1; }];
        [self showPage:0];
    }];
    [self after:2.8 gen:g do:^{ [self showPage:1]; }];
    [self after:4.4 gen:g do:^{ [self showPage:2]; }];
    [self after:6.0 gen:g do:^{ [UIView animateWithDuration:0.4 animations:^{ self->_cc.alpha = 0; }]; }];
    [self after:6.8 gen:g do:^{ [self loop:g]; }];
}
@end

// the card cell is made at runtime as a subclass of PSTableCell, so SpringBoard never needs Preferences.framework
static const void *kCardBuilt = &kCardBuilt;
static void CardBuild(UITableViewCell *self) {
    if (objc_getAssociatedObject(self, kCardBuilt)) return;
    objc_setAssociatedObject(self, kCardBuilt, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    UILabel *t = [UILabel new]; t.tag = 0xC2601;
    t.text = @"Customize Control Center";
    t.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    t.textColor = UIColor.labelColor; t.numberOfLines = 0;
    UILabel *b = [UILabel new]; b.tag = 0xC2602;
    b.text = @"Swipe down from the top-right edge to open Control Center. Add, rearrange, and resize any control.";
    b.font = [UIFont systemFontOfSize:15]; b.textColor = UIColor.secondaryLabelColor; b.numberOfLines = 0;
    C26MiniPhone *ph = [[C26MiniPhone alloc] initWithFrame:CGRectMake(0, 0, 66, 132)]; ph.tag = 0xC2603;
    [self.contentView addSubview:t]; [self.contentView addSubview:b]; [self.contentView addSubview:ph];
}
static void CardLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    CardBuild(self);
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    UIView *cv = self.contentView;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height, m = 18;
    UIView *ph = [cv viewWithTag:0xC2603];
    ph.frame = CGRectMake(W - 66 - 22, (H - 132) / 2, 66, 132);
    CGFloat tw = CGRectGetMinX(ph.frame) - m - 16;
    UILabel *t = (UILabel *)[cv viewWithTag:0xC2601], *b = (UILabel *)[cv viewWithTag:0xC2602];
    CGFloat th = ceil([t sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height);
    CGFloat bh = ceil([b sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height);
    CGFloat y = MAX(12, (H - th - 6 - bh) / 2);
    t.frame = CGRectMake(m, y, tw, th);
    b.frame = CGRectMake(m, y + th + 6, tw, bh);
}
static Class CardCellClass(void) {
    static Class c;
    if (c) return c;
    Class sup = NSClassFromString(@"PSTableCell");
    if (!sup) return nil;
    c = objc_getClass("C26CCCardCell");
    if (!c) {
        c = objc_allocateClassPair(sup, "C26CCCardCell", 0);
        class_addMethod(c, @selector(layoutSubviews), (IMP)CardLayout, "v@:");
        objc_registerClassPair(c);
    }
    return c;
}

static void CCResetTap(UIViewController *self, SEL _cmd, id spec) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:@"This will reset your Control Center layout to factory defaults." preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:@"Reset Control Center" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *x) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.control26/reset"), NULL, NULL, YES);
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *pop = a.popoverPresentationController;
    if (pop) { pop.sourceView = self.view; pop.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1); }
    [self presentViewController:a animated:YES completion:nil];
}

static NSMutableDictionary *gCCClassIs;
static BOOL IsCCSettings(Class cls) {
    if (!cls) return NO;
    NSString *name = NSStringFromClass(cls);
    if (!gCCClassIs) gCCClassIs = [NSMutableDictionary dictionary];
    NSNumber *c = gCCClassIs[name];
    if (c) return c.boolValue;
    NSString *bp = [NSBundle bundleForClass:cls].bundlePath ?: @"";
    BOOL yes = [bp.lastPathComponent hasPrefix:@"ControlCenterSettings"] || [name hasPrefix:@"CCSModuleSettings"] || [name hasPrefix:@"CCUIModuleSettings"]
        || ([name rangeOfString:@"ControlCenter"].location != NSNotFound && ![name hasPrefix:@"PS"]);
    gCCClassIs[name] = @(yes);
    return yes;
}

// Apple's list: a switch group (Access Within Apps, Show Home Controls), INCLUDED CONTROLS, MORE CONTROLS.
// Ours: the card, Access Within Apps, Reset.
static NSArray *FilterCCSpecs(UIViewController *ctl, NSArray *arr) {
    if (![arr isKindOfClass:[NSArray class]]) return arr;
    for (id s in arr) if ([[s propertyForKey:@"c26"] boolValue]) return arr;
    NSInteger SW = PSType(@"PSSwitchCell", 6), GR = PSType(@"PSGroupCell", 0);
    id sw = nil; NSUInteger other = 0;
    for (id s in arr) {
        if (![s respondsToSelector:@selector(cellType)]) continue;
        NSInteger t = [s cellType];
        if (t == SW) { if (!sw) sw = s; }
        else if (t != GR) other++;
    }
    if (other < 3) return arr;   // not the page we think it is
    Class S = NSClassFromString(@"PSSpecifier");
    if (!S) return arr;
    NSMutableArray *out = [NSMutableArray array];
    id g0 = [S emptyGroupSpecifier];
    SP(g0, @YES, @"c26");
    [out addObject:g0];
    Class cardC = CardCellClass();
    if (cardC) {
        id card = [S preferenceSpecifierNamed:@"" target:ctl set:NULL get:NULL detail:Nil cell:PSType(@"PSStaticTextCell", -1) edit:Nil];
        SP(card, cardC, @"cellClass");
        SP(card, @164, @"height");
        SP(card, @YES, @"c26");
        [card setIdentifier:@"C26_CARD"];
        [out addObject:card];
    }
    if (sw) {
        id g1 = [S emptyGroupSpecifier];
        SP(g1, @"Allow access to Control Center within apps. When disabled, you can still access Control Center from the Home Screen.", @"footerText");
        SP(g1, @YES, @"c26");
        [out addObject:g1];
        [out addObject:sw];
    }
    id g2 = [S emptyGroupSpecifier];
    SP(g2, @"This will reset your Control Center layout to factory defaults.", @"footerText");
    SP(g2, @YES, @"c26");
    [out addObject:g2];
    id reset = [S preferenceSpecifierNamed:@"Reset Control Center" target:ctl set:NULL get:NULL detail:Nil cell:PSType(@"PSButtonCell", 13) edit:Nil];
    SP(reset, @YES, @"c26");
    [reset setIdentifier:@"C26_RESET"];
    if ([reset respondsToSelector:@selector(setButtonAction:)]) [reset setButtonAction:NSSelectorFromString(@"c26ResetControlCenter:")];
    [out addObject:reset];
    Ivar iv = class_getInstanceVariable(NSClassFromString(@"PSListController"), "_specifiers");
    if (iv) object_setIvarWithStrongDefault(ctl, iv, out);
    return out;
}

static NSArray *(*origPSSpecs)(id, SEL);
static NSArray *PSSpecs(id self, SEL _cmd) {
    NSArray *a = origPSSpecs(self, _cmd);
    if (!IsCCSettings(object_getClass(self))) return a;
    @try { return FilterCCSpecs(self, a); } @catch (__unused id e) { return a; }
}
static NSArray *(*origCCSpecs)(id, SEL);
static NSArray *CCSpecs(id self, SEL _cmd) {
    NSArray *a = origCCSpecs(self, _cmd);
    @try { return FilterCCSpecs(self, a); } @catch (__unused id e) { return a; }
}
static NSInteger CCNoEditStyle(id s, SEL c, id tv, id ip) { return UITableViewCellEditingStyleNone; }
static BOOL CCNo(id s, SEL c, id tv, id ip) { return NO; }
static void CCNoop3(id s, SEL c, id a, id b, id d) {}

static void UnEdit(UIViewController *self) {
    UITableView *tv = [self respondsToSelector:@selector(table)] ? [self table] : nil;
    if (![tv isKindOfClass:[UITableView class]]) return;
    tv.allowsSelectionDuringEditing = YES;
    if (tv.editing) [tv setEditing:NO animated:NO];
}

static void EnsureFiltered(UIViewController *self) {
    Ivar iv = class_getInstanceVariable(NSClassFromString(@"PSListController"), "_specifiers");
    NSArray *cur = iv ? object_getIvar(self, iv) : nil;
    if (![cur isKindOfClass:[NSArray class]] || !cur.count) return;
    for (id s in cur) if ([[s propertyForKey:@"c26"] boolValue]) return;
    NSArray *f = FilterCCSpecs(self, cur);
    if (f != cur && [self respondsToSelector:@selector(setSpecifiers:)]) [(id)self setSpecifiers:[f mutableCopy]];
}

static NSMutableSet *gCCPrepared;
static void PrepareCCClass(Class cls) {
    if (!gCCPrepared) gCCPrepared = [NSMutableSet set];
    NSString *n = NSStringFromClass(cls);
    if ([gCCPrepared containsObject:n]) return;
    [gCCPrepared addObject:n];
    Class PS = NSClassFromString(@"PSListController");
    // methods this class itself defines (not inherited)
    NSMutableSet *own = [NSMutableSet set];
    unsigned int cnt = 0; Method *ml = class_copyMethodList(cls, &cnt);
    for (unsigned int i = 0; i < cnt; i++) [own addObject:NSStringFromSelector(method_getName(ml[i]))];
    free(ml);
    if ([own containsObject:@"specifiers"] && !origCCSpecs)
        MSHookMessageEx(cls, @selector(specifiers), (IMP)CCSpecs, (IMP *)&origCCSpecs);
    // the page's own table code expects its module sections; send everything back to the plain PSListController code
    for (NSString *sn in @[@"numberOfSectionsInTableView:", @"tableView:numberOfRowsInSection:", @"tableView:cellForRowAtIndexPath:",
                           @"tableView:heightForRowAtIndexPath:", @"tableView:estimatedHeightForRowAtIndexPath:",
                           @"tableView:titleForHeaderInSection:", @"tableView:titleForFooterInSection:",
                           @"tableView:viewForHeaderInSection:", @"tableView:viewForFooterInSection:",
                           @"tableView:heightForHeaderInSection:", @"tableView:heightForFooterInSection:",
                           @"tableView:didSelectRowAtIndexPath:", @"tableView:willSelectRowAtIndexPath:",
                           @"tableView:shouldHighlightRowAtIndexPath:", @"tableView:willDisplayCell:forRowAtIndexPath:",
                           @"tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:",
                           @"tableView:moveRowAtIndexPath:toIndexPath:", @"tableView:commitEditingStyle:forRowAtIndexPath:"]) {
        if (![own containsObject:sn]) continue;
        SEL s = NSSelectorFromString(sn);
        Method pm = PS ? class_getInstanceMethod(PS, s) : NULL;
        Method cm = class_getInstanceMethod(cls, s);
        if (pm) class_replaceMethod(cls, s, method_getImplementation(pm), method_getTypeEncoding(pm));
        else if ([sn hasPrefix:@"tableView:willDisplayCell"] || [sn hasPrefix:@"tableView:moveRow"] || [sn hasPrefix:@"tableView:commitEditing"])
            class_replaceMethod(cls, s, (IMP)CCNoop3, method_getTypeEncoding(cm));
    }
    class_replaceMethod(cls, @selector(tableView:editingStyleForRowAtIndexPath:), (IMP)CCNoEditStyle, "q@:@@");
    class_replaceMethod(cls, @selector(tableView:canEditRowAtIndexPath:), (IMP)CCNo, "B@:@@");
    class_replaceMethod(cls, @selector(tableView:canMoveRowAtIndexPath:), (IMP)CCNo, "B@:@@");
    class_replaceMethod(cls, @selector(tableView:shouldIndentWhileEditingRowAtIndexPath:), (IMP)CCNo, "B@:@@");
    class_addMethod(cls, NSSelectorFromString(@"c26ResetControlCenter:"), (IMP)CCResetTap, "v@:@");
}

static void (*origPSLoadView)(id, SEL);
static void PSLoadView(id self, SEL _cmd) {
    BOOL cc = IsCCSettings(object_getClass(self));
    if (cc) @try { PrepareCCClass(object_getClass(self)); } @catch (__unused id e) {}
    origPSLoadView(self, _cmd);
    if (cc) @try { UnEdit(self); } @catch (__unused id e) {}
}
static void (*origPSWillAppear)(id, SEL, BOOL);
static void PSWillAppear(id self, SEL _cmd, BOOL a) {
    BOOL cc = IsCCSettings(object_getClass(self));
    if (cc) @try { PrepareCCClass(object_getClass(self)); } @catch (__unused id e) {}
    origPSWillAppear(self, _cmd, a);
    if (cc) {
        @try { EnsureFiltered(self); UnEdit(self); } @catch (__unused id e) {}
        __weak id ws = self;
        dispatch_async(dispatch_get_main_queue(), ^{ @try { UnEdit(ws); } @catch (__unused id e) {} });
    }
}
static void (*origPSDidAppear)(id, SEL, BOOL);
static void PSDidAppear(id self, SEL _cmd, BOOL a) {
    origPSDidAppear(self, _cmd, a);
    if (IsCCSettings(object_getClass(self))) @try { UnEdit(self); } @catch (__unused id e) {}
}

static void InstallCCSettingsHooks(void) {
    Class PS = NSClassFromString(@"PSListController");
    if (!PS) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ InstallCCSettingsHooks(); });
        return;
    }
    MSHookMessageEx(PS, @selector(specifiers), (IMP)PSSpecs, (IMP *)&origPSSpecs);
    MSHookMessageEx(PS, @selector(loadView), (IMP)PSLoadView, (IMP *)&origPSLoadView);
    MSHookMessageEx(PS, @selector(viewWillAppear:), (IMP)PSWillAppear, (IMP *)&origPSWillAppear);
    MSHookMessageEx(PS, @selector(viewDidAppear:), (IMP)PSDidAppear, (IMP *)&origPSDidAppear);
}

#include "../shared/NanoSettings.h"

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if ([bid isEqualToString:@"com.apple.Preferences"]) {
        StartNanoSettings();
        LoadPrefs();
        if (gEnabled && gCCPage) InstallCCSettingsHooks();
        return;
    }
    if (![bid isEqualToString:@"com.apple.springboard"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ResetNote, CFSTR("com.nano.control26/reset"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
    // Control Center's frameworks can load after SpringBoard starts. Check once
    // a second (for up to 2 minutes) and hook each part as soon as it exists.
    StartLateHooks();
    dispatch_async(dispatch_get_main_queue(), ^{ RegisterNowPlayingNotifications(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { StopAutoBrightness(); } @catch (__unused id e) {} });
}
