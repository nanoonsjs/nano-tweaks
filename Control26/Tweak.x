// Control26 0.1.4 - made by nano
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

#define DOM_NS @"com.user.control26"
#define DOM CFSTR("com.user.control26")
#define NOTIFY CFSTR("com.user.control26/prefschanged")
#define OVERLAY_TAG 0x43323630
#define GLYPH_TAG   0x43323631
#define DEBUG_TAG   0x43323632

static BOOL gEnabled = YES, gMusic = YES, gColors = YES, gBounce = YES, gDebug = NO, gJelly = YES;

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

static NSHashTable *gMediaViews, *gSliders;
static NSTimer *gTimer;
static NSString *gMusicDebug = @"-", *gSliderDebug = @"-";
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
static void FetchIsPlaying(void) {
    MRIsPlayingFn f = MediaRemote() ? (MRIsPlayingFn)dlsym(MediaRemote(), "MRMediaRemoteGetNowPlayingApplicationIsPlaying") : NULL;
    if (f) f(dispatch_get_main_queue(), ^(Boolean p) { gIsPlaying = p; });
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
    getInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
        NSDictionary *d = (__bridge NSDictionary *)info;
        NSString *title = d[@"kMRMediaRemoteNowPlayingInfoTitle"];
        NSString *artist = d[@"kMRMediaRemoteNowPlayingInfoArtist"];
        NSData *data = d[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
        gNPTitle = [title isKindOfClass:[NSString class]] && title.length ? title : nil;
        gNPArtist = [artist isKindOfClass:[NSString class]] ? artist : nil;
        if (!gNPTitle) { gArtwork = nil; gArtworkData = nil; }
        else if ([data isKindOfClass:[NSData class]] && data.length && ![data isEqualToData:gArtworkData]) {
            gArtworkData = data;
            gArtwork = [UIImage imageWithData:data];
        }
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

@interface C26Transport : NSObject
+ (instancetype)shared;
@end
@implementation C26Transport
+ (instancetype)shared { static C26Transport *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26Transport new]; }); return t; }
- (void)down:(UIButton *)b {
    [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{ b.transform = CGAffineTransformMakeScale(0.82, 0.82); b.alpha = 0.7; } completion:nil];
}
- (void)up:(UIButton *)b {
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{ b.transform = CGAffineTransformIdentity; b.alpha = 1; } completion:nil];
}
- (void)tap:(UIButton *)b {
    [self up:b];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b.tag == 6) SendMR(5);
    else if (b.tag == 8) SendMR(4);
    else { SendMR(2); gIsPlaying = !gIsPlaying; }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ FetchIsPlaying(); });
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

static void UnstyleModule(UIView *module) {
    UIView *o = [module viewWithTag:OVERLAY_TAG];
    if (o.superview == module) [o removeFromSuperview];
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(module, 0, [UILabel class], labels);
    for (UILabel *l in labels) ShowOriginal(l);
    for (UIView *v in TopRightViews(module)) ShowOriginal(v);
    NSArray *tr = FindTransport(module);
    for (UIView *b in tr) { ShowOriginal(b); ClearOurTransform(b); ClearOurTransform(b.superview); ClearOurTransform(b.superview.superview); }
}

static void StyleModule(UIView *module) {
    CGSize S = module.bounds.size;
    // Compact (square) module only; the expanded one is left alone.
    if (S.width < 120 || S.width > 240 || fabs(S.width - S.height) > 40) { UnstyleModule(module); return; }
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
    SetFrame(air, glass.frame);
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
        [UIView transitionWithView:art duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ art.image = img; } completion:nil];
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
    for (UIView *b in tr) HideOriginal(b);

    // Hide Apple's labels and small AirPlay icon (ours replace them).
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(module, 0, [UILabel class], labels);
    for (UILabel *l in labels) {
        CGRect r = [l convertRect:l.bounds toView:module];
        if (CGRectGetMidY(r) < S.height * 0.75) HideOriginal(l);
    }
    NSArray *corner = TopRightViews(module);
    for (UIView *v in corner) HideOriginal(v);
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
    if (!gBounce || H < 1 || over <= 0) { if (!CGAffineTransformIsIdentity(v.transform)) v.transform = CGAffineTransformIdentity; return; }
    CGFloat stretch = MIN((1.0 - 1.0 / (over * 0.5 / H + 1.0)) * H, H * 0.12);
    CGFloat r = stretch / H;
    v.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -dir * stretch / 2), 1.0 - r * 0.35, 1.0 + r);
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
        UIView *shell = SliderShell(v);
        if (!CGAffineTransformIsIdentity(shell.transform)) {
            // Spring back carrying the finger's speed, so it bounces off naturally.
            CGFloat stretchNow = fabs(shell.transform.ty) * 2;
            CGFloat speed = fabs([g velocityInView:v].y);
            CGFloat initialV = stretchNow > 1 ? MIN(speed / stretchNow, 20) : 0;
            UISpringTimingParameters *spring = [[UISpringTimingParameters alloc] initWithDampingRatio:0.58 initialVelocity:CGVectorMake(initialV, initialV)];
            UIViewPropertyAnimator *anim = [[UIViewPropertyAnimator alloc] initWithDuration:0.6 timingParameters:spring];
            [anim addAnimations:^{ shell.transform = CGAffineTransformIdentity; }];
            [anim startAnimation];
        }
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

@interface C26Jelly : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26Jelly
+ (instancetype)shared { static C26Jelly *j; static dispatch_once_t o; dispatch_once(&o, ^{ j = [C26Jelly new]; }); return j; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)press:(UILongPressGestureRecognizer *)g {
    UIView *v = g.view;
    if (!v || !v.superview) return;
    if (!gEnabled || !gJelly) { if (!CGAffineTransformIsIdentity(v.transform)) v.transform = CGAffineTransformIdentity; return; }
    CGPoint p = [g locationInView:v.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        objc_setAssociatedObject(v, kJellyStart, [NSValue valueWithCGPoint:p], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // Lift: a soft swell like glass being pressed.
        UIViewPropertyAnimator *a = [[UIViewPropertyAnimator alloc] initWithDuration:0.35 dampingRatio:0.7 animations:^{
            v.transform = CGAffineTransformMakeScale(1.07, 1.07);
        }];
        [a startAnimation];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint s = [objc_getAssociatedObject(v, kJellyStart) CGPointValue];
        CGFloat dx = p.x - s.x, dy = p.y - s.y, dist = hypot(dx, dy);
        // Lean toward the finger (with resistance) and stretch along the drag.
        // Follows the finger a little, with more resistance the further it goes (max ~10pt).
        CGFloat damp = 0.14 / (1.0 + dist / 120.0);
        CGFloat ox = dx * damp, oy = dy * damp;
        CGFloat stretch = MIN(dist / 400.0, 0.08);
        CGFloat angle = atan2(dy, dx);
        CGAffineTransform t = CGAffineTransformMakeTranslation(ox, oy);
        t = CGAffineTransformRotate(t, angle);
        t = CGAffineTransformScale(t, 1.07 + stretch, 1.07 - stretch * 0.6);
        t = CGAffineTransformRotate(t, -angle);
        UIViewPropertyAnimator *a = [[UIViewPropertyAnimator alloc] initWithDuration:0.12 curve:UIViewAnimationCurveEaseOut animations:^{ v.transform = t; }];
        [a startAnimation];
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        // Release: wobble back to rest.
        UISpringTimingParameters *spring = [[UISpringTimingParameters alloc] initWithDampingRatio:0.45 initialVelocity:CGVectorMake(0, 0)];
        UIViewPropertyAnimator *a = [[UIViewPropertyAnimator alloc] initWithDuration:0.6 timingParameters:spring];
        [a addAnimations:^{ v.transform = CGAffineTransformIdentity; }];
        [a startAnimation];
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
    NSString *text = [NSString stringWithFormat:@" Control26 0.1.4 debug\n music: %@\n sliders: %@", gMusicDebug, gSliderDebug];
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
    if (win) UpdateDebug(win);
    // Control Center closed: stop the timer until it opens again.
    if (!anyVisible) { [gTimer invalidate]; gTimer = nil; }
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
}

static void StartLateHooks(void) {
    TryLateHooks();
    __block int tries = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        TryLateHooks();
        if ((gMediaHooked && gCCHooked && gMRUHooked && gGlyphHooked && gJ1Hooked && gJ2Hooked) || ++tries > 120) [t invalidate];
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
}
