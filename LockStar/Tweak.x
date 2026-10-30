// LockStar 0.1.0 - made by nano
// iOS 26 favorite star on the Lock Screen / Dynamic Island now-playing player:
// it sits left of the back button (mirroring AirPlay on the right), shows if the
// song is favorited, and toggles it with a pop + sparks.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <substrate.h>

#define DOM CFSTR("com.nano.lockstar")
#define STAR_TAG 0x4C535452
#define DBG_TAG  0x4C534442

static BOOL gEnabled = YES, gDebug = NO;
static BOOL gFav = NO, gFavKnown = NO;
static CFTimeInterval gFavLock;
static NSString *gFavKey = @"-", *gLastCmd = @"-";
static NSHashTable *gStars;

#pragma mark - prefs

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingString:@"com.nano.lockstar.plist"]];
        if ([d isKindOfClass:[NSDictionary class]]) { f = d; break; }
    }
    id e = f[@"enabled"], g = f[@"debug"];
    if (!e) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("enabled"), DOM); if (cf) e = (__bridge_transfer id)cf; }
    if (!g) { CFPropertyListRef cf = CFPreferencesCopyAppValue(CFSTR("debug"), DOM); if (cf) g = (__bridge_transfer id)cf; }
    gEnabled = e ? [e boolValue] : YES;
    gDebug = g ? [g boolValue] : NO;
}

#pragma mark - MediaRemote

typedef void (*MRGetInfo)(dispatch_queue_t, void (^)(CFDictionaryRef));
typedef Boolean (*MRSend)(unsigned int, CFDictionaryRef);
static void *MR(const char *sym) {
    static void *h;
    if (!h) h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    return h ? dlsym(h, sym) : NULL;
}
#define MR_LIKE 106   // like / love (favorite); with the negative option it undoes it

static void SetStar(UIButton *b, BOOL on, BOOL animated);
static void RefreshAll(void) {
    for (UIButton *b in [gStars allObjects]) if (b.window) SetStar(b, gFav, NO);
}
// Reads whether the playing song is favorited (any "liked/loved/favorite" flag).
static void QueryFav(void) {
    MRGetInfo get = (MRGetInfo)MR("MRMediaRemoteGetNowPlayingInfo");
    if (!get) return;
    get(dispatch_get_main_queue(), ^(CFDictionaryRef cd) {
        NSDictionary *d = (__bridge NSDictionary *)cd;
        if (CACurrentMediaTime() < gFavLock) return;
        NSString *found = nil; BOOL val = NO;
        for (NSString *k in d) {
            NSString *l = k.lowercaseString;
            if (([l containsString:@"liked"] || [l containsString:@"loved"] || [l containsString:@"favorite"]) && ![l containsString:@"dislike"] && [d[k] respondsToSelector:@selector(boolValue)]) {
                found = k; val = [d[k] boolValue]; break;
            }
        }
        gFavKey = found ? [found stringByReplacingOccurrencesOfString:@"kMRMediaRemoteNowPlayingInfo" withString:@""] : @"none";
        gFavKnown = found != nil;
        if (found) { gFav = val; RefreshAll(); }
    });
}

#pragma mark - star

static void SetStar(UIButton *b, BOOL on, BOOL animated) {
    NSNumber *cur = objc_getAssociatedObject(b, @selector(SetStar));
    if (cur && cur.boolValue == on && !animated) return;
    objc_setAssociatedObject(b, @selector(SetStar), @(on), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CGFloat pt = b.bounds.size.height > 40 ? 24 : 21;
    [b setImage:[UIImage systemImageNamed:on ? @"star.fill" : @"star" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    if (!animated) return;
    // Pop, then a ring and sparks when it turns on.
    b.imageView.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.62 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:1.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        b.imageView.transform = CGAffineTransformIdentity;
    } completion:nil];
    if (!on) return;
    UIColor *col = b.tintColor ?: UIColor.whiteColor;
    CGPoint c = CGPointMake(b.bounds.size.width / 2, b.bounds.size.height / 2);
    UIView *ring = [[UIView alloc] initWithFrame:CGRectMake(c.x - 20, c.y - 20, 40, 40)];
    ring.userInteractionEnabled = NO; ring.layer.cornerRadius = 20;
    ring.layer.borderWidth = 2; ring.layer.borderColor = col.CGColor;
    [b addSubview:ring];
    ring.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ ring.transform = CGAffineTransformMakeScale(1.7, 1.7); ring.alpha = 0; } completion:^(BOOL f) { [ring removeFromSuperview]; }];
    for (int i = 0; i < 8; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(c.x - 2.5, c.y - 2.5, 5, 5)];
        dot.userInteractionEnabled = NO; dot.layer.cornerRadius = 2.5; dot.backgroundColor = col;
        [b addSubview:dot];
        CGFloat ang = i * M_PI / 4 + M_PI / 8;
        [UIView animateWithDuration:0.55 delay:0.04 options:UIViewAnimationOptionCurveEaseOut animations:^{
            dot.center = CGPointMake(c.x + cos(ang) * 40, c.y + sin(ang) * 40);
            dot.transform = CGAffineTransformMakeScale(0.3, 0.3); dot.alpha = 0;
        } completion:^(BOOL f) { [dot removeFromSuperview]; }];
    }
}

@interface LSTarget : NSObject
+ (instancetype)shared;
@end
@implementation LSTarget
+ (instancetype)shared { static LSTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [LSTarget new]; }); return t; }
- (void)tap:(UIButton *)b {
    MRSend send = (MRSend)MR("MRMediaRemoteSendCommand");
    BOOL willFav = !gFav;
    NSDictionary *opts = willFav ? @{} : @{@"kMRMediaRemoteOptionIsNegative": @YES};
    Boolean ok = send ? send(MR_LIKE, (__bridge CFDictionaryRef)opts) : false;
    gLastCmd = [NSString stringWithFormat:@"%@ sent=%d", willFav ? @"fav" : @"unfav", ok];
    gFav = willFav; gFavLock = CACurrentMediaTime() + 1.5;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    for (UIButton *s in [gStars allObjects]) if (s.window) SetStar(s, gFav, s == b);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ QueryFav(); });
}
@end

#pragma mark - placement

static NSString *Cls(UIView *v) { return NSStringFromClass([v class]); }
static void Collect(UIView *v, int depth, NSMutableArray *route, NSMutableArray *transport) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.tag == STAR_TAG || s.tag == DBG_TAG) continue;
        NSString *n = Cls(s);
        if ([s isKindOfClass:[UIControl class]] || [n containsString:@"Button"]) {
            if ([n containsString:@"Rout"] || [s.accessibilityIdentifier containsString:@"oute"]) [route addObject:s];
            else if ([n containsString:@"Transport"]) [transport addObject:s];
        }
        if (depth < 12) Collect(s, depth + 1, route, transport);
    }
}
// Lays the star out inside a now-playing view: same height as the transport
// row, mirrored from AirPlay (or just left of the back button).
static void PlaceStar(UIView *np) {
    if (!np.window) return;
    UIButton *star = (UIButton *)[np viewWithTag:STAR_TAG];
    UILabel *dbg = (UILabel *)[np viewWithTag:DBG_TAG];
    if (!gEnabled) { star.hidden = YES; dbg.hidden = YES; return; }
    NSMutableArray *route = [NSMutableArray array], *tr = [NSMutableArray array];
    Collect(np, 0, route, tr);
    // The back button = leftmost transport button.
    UIView *back = nil;
    for (UIView *b in tr) if (!back || [b convertPoint:CGPointZero toView:np].x < [back convertPoint:CGPointZero toView:np].x) back = b;
    UIView *rt = route.firstObject;
    NSString *info = [NSString stringWithFormat:@"%@ tr=%lu route=%@ fav=%@:%d %@", Cls(np), (unsigned long)tr.count, rt ? Cls(rt) : @"none", gFavKey, gFav, gLastCmd];
    if (!back) {
        star.hidden = YES;
        if (gDebug) {
            if (!dbg) { dbg = [UILabel new]; dbg.tag = DBG_TAG; dbg.numberOfLines = 0; dbg.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular]; dbg.textColor = UIColor.yellowColor; dbg.userInteractionEnabled = NO; [np addSubview:dbg]; }
            dbg.text = [@"no back: " stringByAppendingString:info]; dbg.hidden = NO;
            dbg.frame = CGRectMake(8, 0, np.bounds.size.width - 16, 40);
        } else dbg.hidden = YES;
        return;
    }
    CGRect bf = [back convertRect:back.bounds toView:np];
    CGFloat D = MAX(36, MIN(48, bf.size.height));
    CGFloat cx;
    if (rt) {
        CGRect rf = [rt convertRect:rt.bounds toView:np];
        cx = np.bounds.size.width - CGRectGetMidX(rf);   // mirror of AirPlay
        if (cx > CGRectGetMinX(bf) - D / 2) cx = CGRectGetMinX(bf) - D / 2 - 14;
    } else cx = CGRectGetMinX(bf) - D / 2 - 18;
    if (!star) {
        star = [UIButton buttonWithType:UIButtonTypeCustom];
        star.tag = STAR_TAG;
        star.adjustsImageWhenHighlighted = NO;
        [star addTarget:[LSTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [np addSubview:star];
        if (!gStars) gStars = [NSHashTable weakObjectsHashTable];
        [gStars addObject:star];
        QueryFav();
    }
    // Same colour as Music's own buttons there.
    UIColor *tint = back.tintColor ?: UIColor.whiteColor;
    UIImageView *bi = nil;
    for (UIView *s in back.subviews) if ([s isKindOfClass:[UIImageView class]]) { bi = (UIImageView *)s; break; }
    if (bi.tintColor) tint = bi.tintColor;
    if (![star.tintColor isEqual:tint]) star.tintColor = tint;
    CGRect sf = CGRectMake(round(cx - D / 2), round(CGRectGetMidY(bf) - D / 2), D, D);
    if (!CGRectEqualToRect(star.frame, sf) && !star.imageView.layer.animationKeys.count) star.frame = sf;
    star.hidden = NO;
    if (np.subviews.lastObject != star) [np bringSubviewToFront:star];
    if (!objc_getAssociatedObject(star, @selector(SetStar))) SetStar(star, gFav, NO);
    if (gDebug) {
        if (!dbg) { dbg = [UILabel new]; dbg.tag = DBG_TAG; dbg.numberOfLines = 0; dbg.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular]; dbg.textColor = UIColor.yellowColor; dbg.userInteractionEnabled = NO; [np addSubview:dbg]; }
        dbg.text = info; dbg.hidden = NO;
        dbg.frame = CGRectMake(8, 0, np.bounds.size.width - 16, 30);
    } else dbg.hidden = YES;
}

#pragma mark - hooks

static UIView *NowPlayingRoot(UIView *v) {
    UIView *best = nil;
    for (UIView *p = v; p; p = p.superview) {
        NSString *n = Cls(p);
        if ([n containsString:@"NowPlayingView"] || ([n containsString:@"MRUNowPlaying"] && [n hasSuffix:@"View"] && p.bounds.size.width > 200)) best = p;
        if ([p isKindOfClass:[UIWindow class]]) break;
    }
    return best;
}
static IMP gTransportLayoutOrig;
static void TransportLayout(UIView *self, SEL _cmd) {
    if (gTransportLayoutOrig) ((void (*)(id, SEL))gTransportLayoutOrig)(self, _cmd);
    @try {
        UIView *np = NowPlayingRoot(self) ?: self.superview;
        if (np) PlaceStar(np);
    } @catch (__unused id e) {}
}

static void PrefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    LoadPrefs();
    dispatch_async(dispatch_get_main_queue(), ^{ for (UIButton *b in [gStars allObjects]) [b.superview setNeedsLayout]; });
}

%ctor {
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.lockstar/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    // Song changes: refresh the star.
    [[NSNotificationCenter defaultCenter] addObserverForName:@"kMRMediaRemoteNowPlayingInfoDidChangeNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) { QueryFav(); }];
    void (*reg)(dispatch_queue_t) = (void (*)(dispatch_queue_t))MR("MRMediaRemoteRegisterForNowPlayingNotifications");
    if (reg) reg(dispatch_get_main_queue());
    // The transport row of every now-playing view (Lock Screen, Dynamic Island).
    const char *names[] = { "MRUNowPlayingTransportControlsView", "MRUTransportControlsView", "MRUNowPlayingControlsView" };
    for (int i = 0; i < 3; i++) {
        Class c = objc_getClass(names[i]);
        if (c) { MSHookMessageEx(c, @selector(layoutSubviews), (IMP)TransportLayout, &gTransportLayoutOrig); break; }
    }
}
