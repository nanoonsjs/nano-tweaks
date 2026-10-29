// Control26 0.1.1 - made by nano
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

@interface MRUNowPlayingView : UIView @end
@interface CCUIBaseSliderView : UIView @end
@interface MRUContinuousSliderView : UIView @end
@interface CCUICAPackageView : UIView @end

#define DOM_NS @"com.user.control26"
#define DOM CFSTR("com.user.control26")
#define NOTIFY CFSTR("com.user.control26/prefschanged")
#define OVERLAY_TAG 0x43323630
#define GLYPH_TAG   0x43323631
#define DEBUG_TAG   0x43323632

static BOOL gEnabled = YES, gMusic = YES, gColors = YES, gBounce = YES, gDebug = NO;

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

static void Forward(UIControl *c) {
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

// Apple's AirPlay button: by name, by accessibility label, or by position
// (the control in the top-right corner of the module).
static UIView *FindRouteButton(UIView *module) {
    NSMutableArray *all = [NSMutableArray array];
    CollectViews(module, 0, [UIView class], all);
    CGSize S = module.bounds.size;
    UIView *byPos = nil;
    for (UIView *v in all) {
        if (v.hidden || v.bounds.size.width < 8) continue;
        NSString *n = NSStringFromClass([v class]);
        NSString *ax = v.accessibilityLabel.lowercaseString ?: @"";
        if ([n containsString:@"Route"] || [n containsString:@"Routing"] || [ax containsString:@"airplay"]) return v;
        CGRect r = [v convertRect:v.bounds toView:module];
        if (!byPos && [v isKindOfClass:[UIControl class]] && CGRectGetMidX(r) > S.width * 0.72 && CGRectGetMidY(r) < S.height * 0.3) byPos = v;
    }
    return byPos;
}

// Apple's previous / play / next, left to right.
static NSArray *FindTransport(UIView *module, UIView *route) {
    NSMutableArray *ctls = [NSMutableArray array];
    CollectViews(module, 0, [UIControl class], ctls);
    CGSize S = module.bounds.size;
    NSMutableArray *out = [NSMutableArray array];
    for (UIControl *c in ctls) {
        if (c == route || [route isDescendantOfView:c] || [c isDescendantOfView:route]) continue;
        CGPoint p = [c.superview convertPoint:c.center toView:module];
        if (p.y > S.height * 0.45 && c.bounds.size.width >= 16 && c.bounds.size.width <= S.width * 0.45) [out addObject:c];
    }
    [out sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = [a.superview convertPoint:a.center toView:module].x, y = [b.superview convertPoint:b.center toView:module].x;
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    return out.count == 3 ? out : nil;
}

static const void *kOurTransform = &kOurTransform;
static void SetOurTransform(UIView *v, CGAffineTransform t) {
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

@interface C26Target : NSObject
+ (instancetype)shared;
@property (nonatomic, weak) UIView *route;
@end
@implementation C26Target
+ (instancetype)shared { static C26Target *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [C26Target new]; }); return t; }
- (void)airplay:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIView *r = self.route;
    if ([r isKindOfClass:[UIControl class]] && ((UIControl *)r).allControlEvents) Forward((UIControl *)r);
    else [r accessibilityActivate];
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

    UIButton *air = [UIButton buttonWithType:UIButtonTypeCustom];
    air.tag = 3;
    [air setImage:[UIImage systemImageNamed:@"airplayaudio" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    air.tintColor = UIColor.whiteColor;
    [air addTarget:[C26Target shared] action:@selector(airplay:) forControlEvents:UIControlEventTouchUpInside];
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
    UIView *route = FindRouteButton(module);
    ShowOriginal(route);
    for (UIView *b in FindTransport(module, route)) ClearOurTransform(b);
}

static void StyleModule(UIView *module) {
    CGSize S = module.bounds.size;
    // Compact (square) module only; the expanded one is left alone.
    if (S.width < 120 || S.width > 240 || fabs(S.width - S.height) > 40) { UnstyleModule(module); return; }
    if (!gEnabled || !gMusic) { UnstyleModule(module); return; }

    FetchNowPlaying();
    UIView *route = FindRouteButton(module);
    [C26Target shared].route = route;

    C26PassView *o = (C26PassView *)[module viewWithTag:OVERLAY_TAG];
    if (o.superview != module) o = BuildOverlay(module);
    [module bringSubviewToFront:o];
    SetFrame(o, module.bounds);

    CGFloat s = S.width / 163.0, m = 14 * s;
    UIImageView *art = (UIImageView *)[o viewWithTag:1];
    UIView *glass = [o viewWithTag:2];
    UIButton *air = (UIButton *)[o viewWithTag:3];
    UILabel *title = (UILabel *)[o viewWithTag:4], *artist = (UILabel *)[o viewWithTag:5];

    CGFloat a = round(56 * s), d = round(42 * s);
    SetFrame(art, CGRectMake(m, m, a, a));
    art.layer.cornerRadius = 12 * s;
    SetFrame(glass, CGRectMake(S.width - m - d, m, d, d));
    SetFrame(air, glass.frame);
    glass.layer.cornerRadius = d / 2;
    air.hidden = glass.hidden = route == nil;

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

    // Apple's previous / play / next: closer together, centered, near the bottom.
    NSArray *tr = FindTransport(module, route);
    for (NSUInteger i = 0; i < tr.count; i++) {
        UIView *b = tr[i];
        CGPoint c = [b.superview convertPoint:b.center toView:module];
        CGPoint target = CGPointMake(S.width / 2 + ((CGFloat)i - 1) * 46 * s, S.height * 0.83);
        SetOurTransform(b, CGAffineTransformMakeTranslation(round(target.x - c.x), round(target.y - c.y)));
    }

    // Hide Apple's labels and small AirPlay icon (ours replace them).
    NSMutableArray *labels = [NSMutableArray array];
    CollectViews(module, 0, [UILabel class], labels);
    for (UILabel *l in labels) {
        CGRect r = [l convertRect:l.bounds toView:module];
        if (CGRectGetMidY(r) < S.height * 0.75) HideOriginal(l);
    }
    if (route) HideOriginal(route);
    gMusicDebug = [NSString stringWithFormat:@"%@ %.0fx%.0f route=%@ transport=%lu np=%@ art=%d",
                   NSStringFromClass([module class]), S.width, S.height,
                   route ? NSStringFromClass([route class]) : @"none", (unsigned long)tr.count,
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
        ShowOriginal(apple);
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
    UIColor *c = kind == 1 ? SUN_COLOR : VOLUME_COLOR;
    if (![mine.tintColor isEqual:c]) mine.tintColor = c;
    HideOriginal(apple);
}

// Bounce: stretch the slider when the finger goes past its top/bottom.
@interface C26Bouncer : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation C26Bouncer
+ (instancetype)shared { static C26Bouncer *b; static dispatch_once_t o; dispatch_once(&o, ^{ b = [C26Bouncer new]; }); return b; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    if (!v || !v.superview) return;
    if (!gEnabled || !gBounce) { if (!CGAffineTransformIsIdentity(v.transform)) v.transform = CGAffineTransformIdentity; return; }
    if (g.state == UIGestureRecognizerStateChanged) {
        CGFloat H = v.bounds.size.height;
        if (H < 1) return;
        CGFloat top = v.center.y - H / 2, bottom = v.center.y + H / 2;
        CGFloat y = [g locationInView:v.superview].y;
        CGFloat over = 0; int dir = 0;
        if (y < top) { over = top - y; dir = 1; } else if (y > bottom) { over = y - bottom; dir = -1; }
        // Rubber band: the further past the end, the harder it gets to stretch.
        CGFloat stretch = over > 0 ? MIN((1.0 - 1.0 / (over * 0.5 / H + 1.0)) * H, H * 0.12) : 0;
        CGFloat r = stretch / H;
        CGAffineTransform t = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -dir * stretch / 2), 1.0 - r * 0.35, 1.0 + r);
        // Ease into each new stretch instead of jumping touch-to-touch.
        [UIView animateWithDuration:0.08 delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{ v.transform = t; } completion:nil];

        // Icon pop when the value reaches the very top or bottom.
        float val = SliderValue(v);
        NSNumber *last = objc_getAssociatedObject(v, kBounce);
        int edge = val >= 0.999 ? 1 : (val <= 0.001 && val >= 0 ? -1 : 0);
        if (edge && (!last || last.intValue != edge)) {
            UIView *glyph = [v viewWithTag:GLYPH_TAG] ?: AppleGlyph(v);
            [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^{ glyph.transform = CGAffineTransformMakeScale(1.18, 1.18); }
                             completion:^(BOOL done) {
                [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{ glyph.transform = CGAffineTransformIdentity; } completion:nil];
            }];
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        }
        objc_setAssociatedObject(v, kBounce, @(edge), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        objc_setAssociatedObject(v, kBounce, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!CGAffineTransformIsIdentity(v.transform))
            [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{ v.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
@end

static const void *kPanAdded = &kPanAdded;
static void AddBounce(UIView *slider) {
    if (objc_getAssociatedObject(slider, kPanAdded)) return;
    objc_setAssociatedObject(slider, kPanAdded, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[C26Bouncer shared] action:@selector(pan:)];
    pan.delegate = [C26Bouncer shared];
    pan.cancelsTouchesInView = NO;
    pan.delaysTouchesBegan = NO;
    pan.delaysTouchesEnded = NO;
    [slider addGestureRecognizer:pan];
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
    NSString *text = [NSString stringWithFormat:@" Control26 0.1.1 debug\n music: %@\n sliders: %@", gMusicDebug, gSliderDebug];
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
        @try { StyleSlider(s); if (gEnabled && gBounce) AddBounce(s); } @catch (__unused id e) {}
        if (gDebug) [dbg addObject:[NSString stringWithFormat:@"%@ kind=%d v=%.2f glyph=%@", NSStringFromClass([s class]), SliderKind(s), SliderValue(s),
                                    AppleGlyph(s) ? NSStringFromClass([AppleGlyph(s) class]) : @"none"]];
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

%hook UIControl
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end

%group Glyphs
%hook CCUICAPackageView
- (void)setAlpha:(CGFloat)a {
    if (a > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
%end
%end

static BOOL gMediaHooked, gCCHooked, gMRUHooked, gGlyphHooked;
static void InitMedia(void)  { %init(Media); }
static void InitCC(void)     { %init(SlidersCC); }
static void InitMRU(void)    { %init(SlidersMRU); }
static void InitGlyphs(void) { %init(Glyphs); }

static void TryLateHooks(void) {
    if (!gMediaHooked && NSClassFromString(@"MRUNowPlayingView"))      { gMediaHooked = YES; InitMedia(); }
    if (!gCCHooked && NSClassFromString(@"CCUIBaseSliderView"))        { gCCHooked = YES; InitCC(); }
    if (!gMRUHooked && NSClassFromString(@"MRUContinuousSliderView"))  { gMRUHooked = YES; InitMRU(); }
    if (!gGlyphHooked && NSClassFromString(@"CCUICAPackageView"))      { gGlyphHooked = YES; InitGlyphs(); }
}

static void StartLateHooks(void) {
    TryLateHooks();
    __block int tries = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        TryLateHooks();
        if ((gMediaHooked && gCCHooked && gMRUHooked && gGlyphHooked) || ++tries > 120) [t invalidate];
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
