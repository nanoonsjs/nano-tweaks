// LockStar 0.3.0 - made by nano
// 0.3.0: all SpringBoard windows scanned, buttons found by their symbols too, floating debug strip.
// 0.2.1: players found by their back / AirPlay buttons (not class names); Apple Music only.
// iOS 26 favorite star on the Lock Screen / Dynamic Island now-playing player:
// it sits left of the back button (mirroring AirPlay on the right), shows if the
// song is favorited, and toggles it with a pop + sparks.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <substrate.h>
#import <objc/message.h>

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

// Only Apple Music: its favorites are what the star changes.
static BOOL MusicIsPlaying(void) {
    Class mc = objc_getClass("SBMediaController");
    id m = [mc respondsToSelector:@selector(sharedInstance)] ? [mc performSelector:@selector(sharedInstance)] : nil;
    id app = nil;
    @try { app = [m valueForKey:@"nowPlayingApplication"]; } @catch (__unused id e) {}
    NSString *bid = nil;
    @try { bid = [app valueForKey:@"bundleIdentifier"]; } @catch (__unused id e) {}
    return [bid isEqualToString:@"com.apple.Music"];
}
static BOOL Showing(UIView *v) {
    for (UIView *p = v; p; p = p.superview) if (p.hidden || p.alpha < 0.02) return NO;
    return v.window != nil;
}
// The symbol a button shows (its image, or an image view / layer inside it).
static NSString *Glyph(UIView *v, int depth) {
    if ([v isKindOfClass:[UIButton class]] && [(UIButton *)v currentImage]) return [(UIButton *)v currentImage].description.lowercaseString;
    if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image) return ((UIImageView *)v).image.description.lowercaseString;
    if (depth > 4) return nil;
    for (UIView *s in v.subviews) { NSString *g = Glyph(s, depth + 1); if (g) return g; }
    return nil;
}
static BOOL IsPrevious(UIView *v) {
    NSString *a = v.accessibilityLabel.lowercaseString ?: @"";
    NSString *i = v.accessibilityIdentifier.lowercaseString ?: @"";
    NSString *g = Glyph(v, 0) ?: @"";
    return [a containsString:@"previous"] || [a containsString:@"rewind"] || [a isEqualToString:@"back"] || [i containsString:@"previous"] || [i containsString:@"backward"] || [i containsString:@"leftbutton"] ||
           [g containsString:@"backward"] || [Cls(v) containsString:@"LeftButton"];
}
static BOOL IsRoute(UIView *v) {
    NSString *n = Cls(v), *a = v.accessibilityLabel.lowercaseString ?: @"";
    NSString *g = Glyph(v, 0) ?: @"";
    return [n containsString:@"Rout"] || [a containsString:@"airplay"] || [a containsString:@"destination"] || [a containsString:@"route"] || [g containsString:@"airplay"];
}
static NSMutableOrderedSet *gSeen;
static void Find(UIView *v, int depth, NSMutableArray *prev, NSMutableArray *route) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.02 || s.tag == STAR_TAG || s.tag == DBG_TAG) continue;
        if ([s isKindOfClass:[UIControl class]] || [Cls(s) containsString:@"Button"]) {
            NSString *cn = Cls(s);
            if (gSeen.count < 10 && ([cn hasPrefix:@"MRU"] || [cn containsString:@"Transport"] || [cn containsString:@"Media"] || [cn containsString:@"NowPlaying"]))
                [gSeen addObject:[NSString stringWithFormat:@"%@[%@|%@]", cn, s.accessibilityLabel ?: @"", [Glyph(s, 0) ?: @"" substringToIndex:MIN((NSUInteger)24, (Glyph(s, 0) ?: @"").length)]]];
            if (IsPrevious(s)) [prev addObject:s];
            else if (IsRoute(s)) [route addObject:s];
        }
        if (depth < 28) Find(s, depth + 1, prev, route);
    }
}
static UIView *Common(UIView *a, UIView *b) {
    for (UIView *p = a.superview; p; p = p.superview) if ([b isDescendantOfView:p]) return p;
    return nil;
}
static void Debug(UIView *host, NSString *text) {
    UILabel *dbg = (UILabel *)[host viewWithTag:DBG_TAG];
    if (!gDebug) { dbg.hidden = YES; return; }
    if (!dbg) { dbg = [UILabel new]; dbg.tag = DBG_TAG; dbg.numberOfLines = 0; dbg.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular]; dbg.textColor = UIColor.yellowColor; dbg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6]; dbg.userInteractionEnabled = NO; [host addSubview:dbg]; }
    dbg.text = text; dbg.hidden = NO;
    CGSize sz = [dbg sizeThatFits:CGSizeMake(host.bounds.size.width - 16, 200)];
    dbg.frame = CGRectMake(8, 0, host.bounds.size.width - 16, sz.height);
    [host bringSubviewToFront:dbg];
}
// Places a star in the container holding one player's back + AirPlay buttons.
static void PlaceStar(UIView *back, UIView *rt) {
    UIView *host = rt ? Common(back, rt) : back.superview.superview;
    if (!host) return;
    UIButton *star = (UIButton *)[host viewWithTag:STAR_TAG];
    BOOL music = MusicIsPlaying();
    if (!gEnabled || !music) { star.hidden = YES; Debug(host, [NSString stringWithFormat:@"LockStar: hidden (enabled=%d appleMusic=%d)", gEnabled, music]); return; }
    CGRect bf = [back convertRect:back.bounds toView:host];
    CGFloat D = MAX(36, MIN(48, bf.size.height));
    CGFloat cx;
    if (rt) {
        CGRect rf = [rt convertRect:rt.bounds toView:host];
        cx = host.bounds.size.width - CGRectGetMidX(rf);   // mirror of AirPlay
        if (cx > CGRectGetMinX(bf) - D / 2) cx = CGRectGetMinX(bf) - D / 2 - 14;
    } else cx = CGRectGetMinX(bf) - D / 2 - 18;
    if (!star) {
        star = [UIButton buttonWithType:UIButtonTypeCustom];
        star.tag = STAR_TAG;
        star.adjustsImageWhenHighlighted = NO;
        [star addTarget:[LSTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [host addSubview:star];
        if (!gStars) gStars = [NSHashTable weakObjectsHashTable];
        [gStars addObject:star];
        QueryFav();
    }
    UIColor *tint = back.tintColor ?: UIColor.whiteColor;
    for (UIView *s in back.subviews) if ([s isKindOfClass:[UIImageView class]] && s.tintColor) { tint = s.tintColor; break; }
    if (![star.tintColor isEqual:tint]) star.tintColor = tint;
    CGRect sf = CGRectMake(round(cx - D / 2), round(CGRectGetMidY(bf) - D / 2), D, D);
    if (!CGRectEqualToRect(star.frame, sf) && !star.imageView.layer.animationKeys.count) star.frame = sf;
    star.hidden = NO;
    if (host.subviews.lastObject != star) [host bringSubviewToFront:star];
    if (!objc_getAssociatedObject(star, @selector(SetStar))) SetStar(star, gFav, NO);
    Debug(host, [NSString stringWithFormat:@"LockStar: back=%@ '%@' route=%@ host=%@ fav=%@:%d %@", Cls(back), back.accessibilityLabel, rt ? Cls(rt) : @"none", Cls(host), gFavKey, gFav, gLastCmd]);
}
// Looks through SpringBoard's windows for now-playing players (Lock Screen,
// Dynamic Island, Notification Center) and gives each a star.
static void Scan(void) {
    NSMutableArray *prev = [NSMutableArray array], *route = [NSMutableArray array];
    NSMutableOrderedSet *wins = [NSMutableOrderedSet orderedSet];
    SEL all = NSSelectorFromString(@"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    if ([UIWindow respondsToSelector:all]) {
        NSArray *a = ((NSArray *(*)(id, SEL, BOOL, BOOL))objc_msgSend)([UIWindow class], all, YES, YES);
        if ([a isKindOfClass:[NSArray class]]) [wins addObjectsFromArray:a];
    }
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes)
        if ([sc isKindOfClass:[UIWindowScene class]]) [wins addObjectsFromArray:((UIWindowScene *)sc).windows];
    [wins addObjectsFromArray:UIApplication.sharedApplication.windows];
    gSeen = [NSMutableOrderedSet orderedSet];
    int nwin = 0;
    for (UIWindow *w in wins) if (!w.hidden && w.alpha > 0.02 && w.tag != DBG_TAG) { nwin++; Find(w, 0, prev, route); }
    for (UIView *b in prev) {
        if (!Showing(b)) continue;
        UIView *rt = nil; CGFloat best = 1e9;
        CGPoint bc = [b convertPoint:CGPointMake(b.bounds.size.width / 2, b.bounds.size.height / 2) toView:nil];
        for (UIView *r in route) {
            if (r.window != b.window || !Showing(r)) continue;
            CGPoint rc = [r convertPoint:CGPointMake(r.bounds.size.width / 2, r.bounds.size.height / 2) toView:nil];
            CGFloat d = fabs(rc.y - bc.y) * 4 + fabs(rc.x - bc.x);
            if (fabs(rc.y - bc.y) < 40 && d < best) { best = d; rt = r; }
        }
        @try { PlaceStar(b, rt); } @catch (__unused id e) {}
    }
    for (UIButton *s in [gStars allObjects]) if (!s.window) [s removeFromSuperview];
    // A floating debug strip at the top of the screen, whatever is showing.
    static UIWindow *dw;
    if (!gDebug) { dw.hidden = YES; return; }
    if (!dw) {
        UIWindowScene *scene = nil;
        for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) if ([sc isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)sc; break; }
        dw = scene ? [[UIWindow alloc] initWithWindowScene:scene] : [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        dw.tag = DBG_TAG; dw.windowLevel = 10000000; dw.userInteractionEnabled = NO; dw.backgroundColor = UIColor.clearColor;
        UILabel *l = [UILabel new]; l.tag = 1; l.numberOfLines = 0; l.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular];
        l.textColor = UIColor.yellowColor; l.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
        [dw addSubview:l];
    }
    dw.frame = UIScreen.mainScreen.bounds; dw.hidden = NO;
    UILabel *l = (UILabel *)[dw viewWithTag:1];
    l.text = [NSString stringWithFormat:@" LockStar 0.3.0 | wins=%d prev=%lu route=%lu music=%d fav=%@:%d %@\n %@", nwin, (unsigned long)prev.count, (unsigned long)route.count, MusicIsPlaying(), gFavKey, gFav, gLastCmd, [gSeen.array componentsJoinedByString:@"\n "]];
    CGSize sz = [l sizeThatFits:CGSizeMake(dw.bounds.size.width - 16, 400)];
    l.frame = CGRectMake(8, 50, dw.bounds.size.width - 16, sz.height);
}

#pragma mark - hooks

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
    // Players come and go (lock, Dynamic Island, swipes): look a few times a second.
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer *tm) { @try { Scan(); } @catch (__unused id e) {} }];
    });
}
