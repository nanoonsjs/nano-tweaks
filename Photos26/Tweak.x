// Photos26 1.0.1 - made by nano
// 1.0.1: player capsule only for videos, scrubber finds the real player
//        (asset duration, on-screen layer), Apple's frame strip hidden while
//        ours works, top glass fixed, smaller glass buttons.
// iOS 26 style photo/video viewer for iOS 16 Photos:
//  Bottom: [share circle]  [heart | info | adjust]  [trash circle]
//  Videos: a floating glass player above the thumbnails:
//          [play]  [scrubber]  [mute]
//  Top:    glass circle behind back, glass capsule behind the date,
//          glass circle behind "...", Edit moves to the bottom (adjust).
//
// How it stays safe:
//  - Apple's buttons are never moved or re-laid-out. Their views are hidden
//    with an empty layer mask, and our own buttons call Apple's buttons, so
//    every action (share sheet, delete sheet, favorite...) is Apple's own.
//  - Our views live inside the toolbar / nav bar, so they show and hide with
//    Apple's chrome (tap the photo to hide the bars).
//  - Frames are set only when they change, with a busy flag against re-entry.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define DOM_NS @"com.user.photos26"
#define DOM CFSTR("com.user.photos26")
#define NOTIFY CFSTR("com.user.photos26/prefschanged")
#define BOTTOM_TAG 0x50473630
#define TOP_TAG    0x50473631
#define DEBUG_TAG  0x50473632

static BOOL gEnabled = YES, gTopBar = YES, gPlayer = YES, gDebug = NO;

static const void *kMasked = &kMasked;
static const void *kBusy = &kBusy;
static const void *kStyled = &kStyled;
static const void *kShift = &kShift;

#pragma mark - prefs

// Photos is sandboxed and can't read our prefs through cfprefsd, so read the
// plist file directly (Dopamine keeps tweak prefs under /var/jb), then fall back.
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
    gTopBar  = PrefBool(f, @"topbar", YES);
    gPlayer  = PrefBool(f, @"player", YES);
    gDebug   = PrefBool(f, @"debug", NO);
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{ LoadPrefs(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ LoadPrefs(); });
}

#pragma mark - helpers

static id KV(id obj, NSString *key) {
    if (!obj) return nil;
    @try { return [obj valueForKey:key]; } @catch (__unused id e) { return nil; }
}
static void SetFrame(UIView *v, CGRect r) { if (!CGRectEqualToRect(v.frame, r)) v.frame = r; }
static void Mask(UIView *v) {
    if (!v || objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = [CALayer layer];
    objc_setAssociatedObject(v, kMasked, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void Unmask(UIView *v) {
    if (!v || !objc_getAssociatedObject(v, kMasked)) return;
    v.layer.mask = nil;
    objc_setAssociatedObject(v, kMasked, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// What a bar item is, from its label and its SF Symbol name.
static NSString *ItemKind(UIBarButtonItem *it) {
    NSMutableString *s = [NSMutableString string];
    if (it.accessibilityLabel) [s appendString:it.accessibilityLabel];
    if (it.title) [s appendString:it.title];
    UIImage *img = it.image;
    UIView *v = KV(it, @"view");
    if (!img && [it.customView isKindOfClass:[UIButton class]]) img = [(UIButton *)it.customView imageForState:UIControlStateNormal];
    if (img) [s appendString:img.description];
    if (v.accessibilityLabel) [s appendString:v.accessibilityLabel];
    NSString *l = s.lowercaseString;
    if ([l containsString:@"square.and.arrow.up"] || [l containsString:@"share"]) return @"share";
    if ([l containsString:@"trash"] || [l containsString:@"delete"]) return @"trash";
    if ([l containsString:@"heart"] || [l containsString:@"favorite"]) return @"heart";
    if ([l containsString:@"info"]) return @"info";
    if ([l containsString:@"speaker"] || [l containsString:@"mute"]) return @"mute";
    if ([l containsString:@"pause"] || [l containsString:@"play"]) return @"play";
    if ([l containsString:@"ellipsis"] || [l containsString:@"more"]) return @"more";
    if ([l isEqualToString:@"edit"] || [l hasPrefix:@"edit"]) return @"edit";
    return @"?";
}
static NSString *ItemSymbolText(UIBarButtonItem *it) {
    UIImage *img = it.image;
    if (!img && [it.customView isKindOfClass:[UIButton class]]) img = [(UIButton *)it.customView imageForState:UIControlStateNormal];
    return [img.description lowercaseString] ?: @"";
}

static NSString *gForwardDebug = @"-";
// Press Apple's own bar button.
static void Forward(UIBarButtonItem *it) {
    if (!it) { gForwardDebug = @"no item"; return; }
    if (it.action && it.target) {
        [[UIApplication sharedApplication] sendAction:it.action to:it.target from:it forEvent:nil];
        gForwardDebug = [NSString stringWithFormat:@"action %@", NSStringFromSelector(it.action)]; return;
    }
    if (it.action) {
        [[UIApplication sharedApplication] sendAction:it.action to:nil from:it forEvent:nil];
        gForwardDebug = [NSString stringWithFormat:@"chain %@", NSStringFromSelector(it.action)]; return;
    }
    UIView *v = it.customView ?: KV(it, @"view");
    NSMutableArray *stack = [NSMutableArray arrayWithObject:v ?: [UIView new]];
    while (stack.count) {
        UIView *x = stack.firstObject; [stack removeObjectAtIndex:0];
        if ([x isKindOfClass:[UIControl class]]) {
            [(UIControl *)x sendActionsForControlEvents:UIControlEventTouchUpInside];
            if (@available(iOS 14.0, *)) [(UIControl *)x sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
            gForwardDebug = [NSString stringWithFormat:@"control %@", NSStringFromClass([x class])]; return;
        }
        [stack addObjectsFromArray:x.subviews];
    }
    if (@available(iOS 14.0, *)) {
        id pa = it.primaryAction;
        SEL s = NSSelectorFromString(@"performWithSender:target:");
        if (pa && [pa respondsToSelector:s]) { ((void (*)(id, SEL, id, id))objc_msgSend)(pa, s, it, nil); gForwardDebug = @"primaryAction"; return; }
    }
    gForwardDebug = @"nothing to press";
}

#pragma mark - glass

@interface PGGlass : UIView
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) CAGradientLayer *rim;
@property (nonatomic, strong) CAShapeLayer *rimMask;
@end
@implementation PGGlass
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    _blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    _blur.userInteractionEnabled = NO;
    _blur.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) _blur.layer.cornerCurve = kCACornerCurveContinuous;
    UIView *tint = [UIView new];
    tint.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.55];
    tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_blur.contentView addSubview:tint];
    [self addSubview:_blur];
    // Liquid-glass rim: brighter at the top-left and bottom-right edges.
    _rim = [CAGradientLayer layer];
    _rim.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.42].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.08].CGColor,
                    (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.28].CGColor];
    _rim.locations = @[@0, @0.35, @0.65, @1];
    _rim.startPoint = CGPointMake(0, 0); _rim.endPoint = CGPointMake(1, 1);
    _rimMask = [CAShapeLayer layer];
    _rimMask.fillColor = UIColor.clearColor.CGColor;
    _rimMask.strokeColor = UIColor.blackColor.CGColor;
    _rimMask.lineWidth = 1.1;
    _rim.mask = _rimMask;
    [self.layer addSublayer:_rim];
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.25;
    self.layer.shadowRadius = 10;
    self.layer.shadowOffset = CGSizeMake(0, 3);
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat r = self.bounds.size.height / 2;
    _blur.frame = self.bounds;
    _blur.layer.cornerRadius = r;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _rim.frame = self.bounds;
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.55, 0.55) cornerRadius:r];
    _rimMask.path = p.CGPath;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:r].CGPath;
    [CATransaction commit];
}
@end

#pragma mark - our buttons

@interface PGButton : UIButton
@property (nonatomic, copy) NSString *kind;
@end
@implementation PGButton
@end

static UIImage *Sym(NSString *name, CGFloat size) {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:size weight:UIImageSymbolWeightMedium];
    return [UIImage systemImageNamed:name withConfiguration:c];
}

// Press: squish in; release: pop out past full size.
static void Squish(UIView *v, BOOL down) {
    if (down) {
        [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0.8
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

// Container that only catches touches on our buttons and the scrubber.
@interface PGPass : UIView @end
@implementation PGPass
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    if (self.hidden || self.alpha < 0.01) return nil;
    for (UIView *s in [self.subviews reverseObjectEnumerator]) {
        if (s.hidden || s.alpha < 0.01 || !s.userInteractionEnabled) continue;
        UIView *h = [s hitTest:[self convertPoint:p toView:s] withEvent:e];
        if (h) return h;
    }
    return nil;
}
@end

#pragma mark - state

static __weak UIToolbar *gToolbar;
static __weak UINavigationBar *gNavBar;
static __weak UIBarButtonItem *gEditItem;
static NSMutableDictionary *gItems;        // kind -> weak box of Apple's item
static __weak AVPlayer *gAVPlayer;
static CADisplayLink *gLink;
static BOOL gScrubbing;
static NSString *gBottomDebug = @"-", *gTopDebug = @"-", *gVideoDebug = @"-";

@interface PGBox : NSObject
@property (nonatomic, weak) id obj;
@end
@implementation PGBox
@end

static UIBarButtonItem *AppleItem(NSString *kind) { return ((PGBox *)gItems[kind]).obj; }

@interface PGTarget : NSObject
+ (instancetype)shared;
@end

static void StartLink(void);

#pragma mark - video player (AVPlayer from the visible AVPlayerLayer)

static double Dur(AVPlayer *p) {
    CMTime d = p.currentItem.duration;
    if (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) return CMTimeGetSeconds(d);
    // The asset's length (looked up once per item, it can be slow).
    static const void *kDur = &kDur;
    AVPlayerItem *it = p.currentItem;
    if (!it) return 0;
    NSNumber *c = objc_getAssociatedObject(it, kDur);
    if (c) return c.doubleValue;
    d = it.asset.duration;
    double s = (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) ? CMTimeGetSeconds(d) : 0;
    objc_setAssociatedObject(it, kDur, @(s), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return s;
}

static NSString *gPlayersDebug = @"";
// The player on screen: among all AVPlayerLayers, the visible one over the
// middle of the screen with a real length; playing ones win.
static AVPlayer *CurrentPlayer(UIWindow *w) {
    if (!w) return nil;
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w.layer];
    int guard = 0;
    while (stack.count && guard++ < 8000) {
        CALayer *l = stack.lastObject; [stack removeLastObject];
        if (l.hidden || l.opacity < 0.01) continue;
        if ([l isKindOfClass:[AVPlayerLayer class]] && ((AVPlayerLayer *)l).player) [found addObject:l];
        if (l.sublayers.count) [stack addObjectsFromArray:l.sublayers];
    }
    CGPoint mid = CGPointMake(CGRectGetMidX(w.bounds), CGRectGetMidY(w.bounds));
    AVPlayer *best = nil; int bestScore = -1;
    NSMutableArray *dbg = [NSMutableArray array];
    for (AVPlayerLayer *l in found) {
        AVPlayer *p = l.player;
        CGRect f = [l convertRect:l.bounds toLayer:w.layer];
        int score = 0;
        if (CGRectContainsPoint(f, mid)) score += 4;
        if (CGRectIntersectsRect(f, w.bounds) && f.size.width > 50) score += 2;
        if (Dur(p) > 0) score += 3;
        if (p.rate > 0) score += 1;
        if (dbg.count < 4) [dbg addObject:[NSString stringWithFormat:@"[%.1f/%.1f r%.0f s%d %.0fx%.0f]", CMTimeGetSeconds(p.currentTime), Dur(p), p.rate, score, f.size.width, f.size.height]];
        if (score > bestScore) { bestScore = score; best = p; }
    }
    gPlayersDebug = [NSString stringWithFormat:@"%lu layers %@", (unsigned long)found.count, [dbg componentsJoinedByString:@""]];
    return best;
}

#pragma mark - bottom bar

static PGGlass *GlassIn(UIView *c, NSString *key) {
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGGlass class]] && [v.accessibilityIdentifier isEqualToString:key]) return (PGGlass *)v;
    PGGlass *g = [PGGlass new];
    g.accessibilityIdentifier = key;
    [c insertSubview:g atIndex:0];
    return g;
}

static PGButton *ButtonIn(UIView *c, NSString *kind) {
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGButton class]] && [((PGButton *)v).kind isEqualToString:kind]) return (PGButton *)v;
    PGButton *b = [PGButton buttonWithType:UIButtonTypeSystem];
    b.kind = kind;
    b.tintColor = UIColor.whiteColor;
    [b addTarget:[PGTarget shared] action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [b addTarget:[PGTarget shared] action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [b addTarget:[PGTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:b];
    return b;
}

static void SetSym(PGButton *b, NSString *name, CGFloat size) {
    if ([b.accessibilityValue isEqualToString:name]) return;
    b.accessibilityValue = name;
    UIImage *img = Sym(name, size);
    [UIView transitionWithView:b duration:0.18 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction animations:^{
        [b setImage:img forState:UIControlStateNormal];
    } completion:nil];
}

@interface PGScrubber : UIView
@property (nonatomic, strong) UIView *track, *fill;
@property (nonatomic) CGFloat progress;
@end
@implementation PGScrubber
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _track = [UIView new]; _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.28]; _track.userInteractionEnabled = NO;
    _fill = [UIView new]; _fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.92]; _fill.userInteractionEnabled = NO;
    [self addSubview:_track]; [_track addSubview:_fill];
    _track.clipsToBounds = YES;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:tap];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = gScrubbing ? 10 : 6;
    _track.frame = CGRectMake(0, (self.bounds.size.height - h) / 2, self.bounds.size.width, h);
    _track.layer.cornerRadius = h / 2;
    _fill.frame = CGRectMake(0, 0, MAX(h, _track.bounds.size.width * _progress), h);
    _fill.layer.cornerRadius = h / 2;
}
- (void)setProgress:(CGFloat)p { _progress = MAX(0, MIN(1, p)); [self setNeedsLayout]; }
- (void)pan:(UIGestureRecognizer *)g {
    AVPlayer *pl = gAVPlayer;
    CGFloat p = [g locationInView:self].x / MAX(1, self.bounds.size.width);
    if (g.state == UIGestureRecognizerStateBegan) {
        gScrubbing = YES;
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{ [self layoutIfNeeded]; [self setNeedsLayout]; [self layoutIfNeeded]; } completion:nil];
    }
    self.progress = p;
    double dur = Dur(pl);
    if (pl && dur > 0)
        [pl seekToTime:CMTimeMakeWithSeconds(dur * self.progress, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || [g isKindOfClass:[UITapGestureRecognizer class]]) {
        gScrubbing = NO;
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{ [self setNeedsLayout]; [self layoutIfNeeded]; } completion:nil];
    }
}
@end

static UIView *FindFilmstrip(UIView *v, int d) {
    if (d > 18) return nil;
    CGFloat W = UIScreen.mainScreen.bounds.size.width;
    for (UIView *s in v.subviews) {
        NSString *n = NSStringFromClass([s class]);
        if (([n containsString:@"Scrubber"] || [n containsString:@"Filmstrip"]) && s.bounds.size.width >= W * 0.8 && s.bounds.size.height >= 20 && s.bounds.size.height <= 120 && !s.hidden && s.alpha > 0.01) return s;
        UIView *r = FindFilmstrip(s, d + 1);
        if (r) return r;
    }
    return nil;
}

static void LayoutBottom(UIToolbar *tb) {
    PGPass *c = (PGPass *)[tb viewWithTag:BOTTOM_TAG];
    if (c.superview != tb) c = nil;
    if (!gEnabled) { c.hidden = YES; for (UIBarButtonItem *it in tb.items) Unmask(KV(it, @"view")); return; }

    // Which of Apple's buttons are here?
    NSMutableDictionary *found = [NSMutableDictionary dictionary];
    NSMutableArray *kinds = [NSMutableArray array];
    for (UIBarButtonItem *it in tb.items) {
        UIView *v = KV(it, @"view");
        if (![v isKindOfClass:[UIView class]] || !v.window) continue;
        NSString *k = ItemKind(it);
        [kinds addObject:k];
        if (![k isEqualToString:@"?"]) { PGBox *b = [PGBox new]; b.obj = it; found[k] = b; }
    }
    // Only the photo/video viewer toolbar: it has both share and trash.
    if (!found[@"share"] || !found[@"trash"]) { c.hidden = YES; for (UIBarButtonItem *it in tb.items) Unmask(KV(it, @"view")); gBottomDebug = [NSString stringWithFormat:@"not viewer: %@", [kinds componentsJoinedByString:@","]]; return; }
    gItems = found;
    gToolbar = tb;
    gBottomDebug = [kinds componentsJoinedByString:@","];

    if (!c) {
        c = [PGPass new];
        c.tag = BOTTOM_TAG;
        [tb addSubview:c];
        // Toolbar background: clear, so the glass floats over the photo.
        __weak UIToolbar *wt = tb;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIToolbar *t = wt;
            if (!t || objc_getAssociatedObject(t, kStyled)) return;
            objc_setAssociatedObject(t, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIToolbarAppearance *a = [UIToolbarAppearance new];
            [a configureWithTransparentBackground];
            t.standardAppearance = a; t.compactAppearance = a; t.scrollEdgeAppearance = a; t.compactScrollEdgeAppearance = a;
        });
    }
    c.hidden = NO;
    if (tb.clipsToBounds) tb.clipsToBounds = NO;
    [tb bringSubviewToFront:c];
    SetFrame(c, tb.bounds);
    for (UIBarButtonItem *it in tb.items) Mask(KV(it, @"view"));

    // Row geometry: centered on Apple's own button row.
    CGFloat W = tb.bounds.size.width, D = 44, cy = 0; int cnt = 0;
    for (UIBarButtonItem *it in tb.items) { UIView *v = KV(it, @"view"); if (v.window) { cy += CGRectGetMidY([v convertRect:v.bounds toView:tb]); cnt++; } }
    cy = cnt ? round(cy / cnt) : 25;
    CGFloat sideX = 18;

    PGGlass *gl = GlassIn(c, @"share"), *gm = GlassIn(c, @"mid"), *gr = GlassIn(c, @"trash");
    SetFrame(gl, CGRectMake(sideX, cy - D / 2, D, D));
    SetFrame(gr, CGRectMake(W - sideX - D, cy - D / 2, D, D));
    CGFloat mw = 150;
    SetFrame(gm, CGRectMake(round((W - mw) / 2), cy - D / 2, mw, D));

    PGButton *bShare = ButtonIn(c, @"share"), *bTrash = ButtonIn(c, @"trash");
    PGButton *bHeart = ButtonIn(c, @"heart"), *bInfo = ButtonIn(c, @"info"), *bEdit = ButtonIn(c, @"edit");
    SetSym(bShare, @"square.and.arrow.up", 17);
    SetSym(bTrash, @"trash", 17);
    BOOL fav = [ItemSymbolText(AppleItem(@"heart")) containsString:@"heart.fill"];
    SetSym(bHeart, fav ? @"heart.fill" : @"heart", 17);
    bHeart.tintColor = UIColor.whiteColor;
    SetSym(bInfo, @"info.circle", 18);
    SetSym(bEdit, @"slider.horizontal.3", 17);
    bInfo.hidden = !AppleItem(@"info");
    bHeart.hidden = !AppleItem(@"heart");
    SetFrame(bShare, gl.frame); SetFrame(bTrash, gr.frame);
    CGFloat third = mw / 3;
    SetFrame(bHeart, CGRectMake(gm.frame.origin.x, gm.frame.origin.y, third, D));
    SetFrame(bInfo, CGRectMake(gm.frame.origin.x + third, gm.frame.origin.y, third, D));
    SetFrame(bEdit, CGRectMake(gm.frame.origin.x + third * 2, gm.frame.origin.y, third, D));

    // Video player capsule (only for videos: Apple shows play/pause then).
    // Videos only: Apple's play button is really showing (photos can keep a hidden one).
    UIBarButtonItem *playItem = AppleItem(@"play");
    UIView *pv = KV(playItem, @"view");
    BOOL video = gPlayer && playItem && playItem.enabled && pv.window && !pv.hidden && pv.alpha > 0.01 && pv.bounds.size.width > 2;
    for (UIView *p = pv.superview; p && p != tb && video; p = p.superview) if (p.hidden || p.alpha < 0.01) video = NO;
    gBottomDebug = [gBottomDebug stringByAppendingFormat:@" video=%d", video];
    static __weak UIView *gFilm;
    UIView *film = FindFilmstrip(tb.window, 0);
    if (film) gFilm = film;
    // Apple's own frame strip goes away while our scrubber has a real player.
    AVPlayer *pl = gAVPlayer;
    BOOL ours = video && pl && Dur(pl) > 0;
    if (gFilm) { if (ours) Mask(gFilm); else Unmask(gFilm); }
    PGGlass *gv = GlassIn(c, @"video");
    PGButton *bPlay = ButtonIn(c, @"play"), *bMute = ButtonIn(c, @"mute");
    PGScrubber *scrub = nil;
    for (UIView *v in c.subviews) if ([v isKindOfClass:[PGScrubber class]]) scrub = (PGScrubber *)v;
    if (!scrub) { scrub = [PGScrubber new]; [c addSubview:scrub]; }
    gv.hidden = bPlay.hidden = bMute.hidden = scrub.hidden = !video;
    if (video) {
        CGFloat filmTop = film ? [film convertRect:film.bounds toView:tb].origin.y : -58;
        CGFloat vy = MIN(filmTop, -40) - 12 - D;
        CGFloat vx = 26, vw = W - vx * 2;
        SetFrame(gv, CGRectMake(vx, vy, vw, D));
        BOOL playing = [ItemSymbolText(AppleItem(@"play")) containsString:@"pause"];
        SetSym(bPlay, playing ? @"pause.fill" : @"play.fill", 18);
        NSString *m = ItemSymbolText(AppleItem(@"mute"));
        SetSym(bMute, ([m containsString:@"slash"] || [m containsString:@"mute"]) ? @"speaker.slash.fill" : @"speaker.wave.2.fill", 16);
        bMute.hidden = !AppleItem(@"mute");
        SetFrame(bPlay, CGRectMake(vx + 4, vy, 44, D));
        SetFrame(bMute, CGRectMake(vx + vw - 48, vy, 44, D));
        CGFloat sx = vx + 52, ex = vx + vw - (AppleItem(@"mute") ? 56 : 20);
        SetFrame(scrub, CGRectMake(sx, vy, ex - sx, D));
        StartLink();
    }
}

#pragma mark - top bar

static UIView *FindBackButton(UINavigationBar *nb) {
    NSMutableArray *stack = [NSMutableArray arrayWithArray:nb.subviews];
    int guard = 0;
    while (stack.count && guard++ < 300) {
        UIView *v = stack.firstObject; [stack removeObjectAtIndex:0];
        NSString *n = NSStringFromClass([v class]);
        if ([n containsString:@"BackButton"] && v.bounds.size.width > 4 && !v.hidden) return v;
        [stack addObjectsFromArray:v.subviews];
    }
    return nil;
}

static UIView *GlyphIn(UIView *v, int d) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.bounds.size.width < 2) continue;
        if ([s isKindOfClass:[UIImageView class]] && ((UIImageView *)s).image) return s;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) return s;
        if (d < 5) { UIView *g = GlyphIn(s, d + 1); if (g) return g; }
    }
    return nil;
}

static void LayoutTop(UINavigationBar *nb) {
    UIView *c = [nb viewWithTag:TOP_TAG];
    if (c.superview != nb) c = nil;
    UINavigationItem *top = nb.topItem;
    UIBarButtonItem *edit = nil, *more = nil;
    for (UIBarButtonItem *it in top.rightBarButtonItems) {
        NSString *k = ItemKind(it);
        if ([k isEqualToString:@"edit"]) edit = it;
        else if ([k isEqualToString:@"more"]) more = it;
    }
    UIView *back = FindBackButton(nb);
    BOOL viewer = edit && more && gToolbar && gToolbar.window == nb.window && ![gToolbar viewWithTag:BOTTOM_TAG].hidden;
    UIView *editView = KV(edit, @"view");
    if (!gEnabled || !gTopBar || !viewer) {
        if (gTopBar && gEnabled) gTopDebug = [NSString stringWithFormat:@"skip: edit=%d more=%d toolbar=%d rights=%lu", edit != nil, more != nil, gToolbar != nil, (unsigned long)top.rightBarButtonItems.count];
        c.hidden = YES;
        if (editView) { Unmask(editView); editView.userInteractionEnabled = YES; }
        if (back && objc_getAssociatedObject(back, kShift)) { back.transform = CGAffineTransformIdentity; objc_setAssociatedObject(back, kShift, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        return;
    }
    gEditItem = edit;
    gNavBar = nb;
    if (!c) {
        c = [UIView new];
        c.tag = TOP_TAG;
        c.userInteractionEnabled = NO;
        [nb insertSubview:c atIndex:0];
        __weak UINavigationBar *wn = nb;
        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationBar *n = wn;
            if (!n || objc_getAssociatedObject(n, kStyled)) return;
            objc_setAssociatedObject(n, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UINavigationBarAppearance *a = [UINavigationBarAppearance new];
            [a configureWithTransparentBackground];
            n.standardAppearance = a; n.compactAppearance = a; n.scrollEdgeAppearance = a;
            if (@available(iOS 15.0, *)) n.compactScrollEdgeAppearance = a;
            n.tintColor = UIColor.whiteColor;
        });
    }
    c.hidden = NO;
    if (nb.clipsToBounds) nb.clipsToBounds = NO;
    // Glass goes just above the bar's background, under Apple's buttons.
    UIView *bg = nil;
    for (UIView *s in nb.subviews) if ([NSStringFromClass([s class]) containsString:@"Background"]) bg = s;
    if (bg && [nb.subviews indexOfObject:c] != [nb.subviews indexOfObject:bg] + 1) [nb insertSubview:c aboveSubview:bg];
    SetFrame(c, nb.bounds);

    // Edit lives in the bottom capsule now.
    if (editView) { Mask(editView); if (editView.userInteractionEnabled) editView.userInteractionEnabled = NO; }

    CGFloat D = 42;
    // Back: move it in from the edge so it sits in its circle.
    PGGlass *gb = GlassIn(c, @"back");
    gb.hidden = !back;
    if (back) {
        UIView *g = GlyphIn(back, 0) ?: back;
        CGRect gr = [g convertRect:g.bounds toView:nb];
        CGFloat curX = CGRectGetMidX(gr) - back.transform.tx;
        CGFloat dx = round((15 + D / 2) - curX);
        if (fabs(back.transform.tx - dx) > 0.5) back.transform = CGAffineTransformMakeTranslation(dx, 0);
        objc_setAssociatedObject(back, kShift, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SetFrame(gb, CGRectMake(15, round(CGRectGetMidY(gr) - D / 2), D, D));
    }
    // "..." circle.
    UIView *moreView = KV(more, @"view");
    PGGlass *gm = GlassIn(c, @"more");
    gm.hidden = !moreView.window;
    if (moreView.window) {
        UIView *g = GlyphIn(moreView, 0) ?: moreView;
        CGRect r = [g convertRect:g.bounds toView:nb];
        SetFrame(gm, CGRectMake(round(CGRectGetMidX(r) - D / 2), round(CGRectGetMidY(r) - D / 2), D, D));
    }
    // Date capsule behind the title.
    UIView *title = top.titleView;
    if (!title) {
        NSMutableArray *stack = [NSMutableArray arrayWithArray:nb.subviews];
        int guard = 0;
        while (stack.count && guard++ < 300) {
            UIView *v = stack.firstObject; [stack removeObjectAtIndex:0];
            if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length && fabs(CGRectGetMidX([v convertRect:v.bounds toView:nb]) - nb.bounds.size.width / 2) < 30) { title = v; break; }
            [stack addObjectsFromArray:v.subviews];
        }
    }
    PGGlass *gt = GlassIn(c, @"title");
    gt.hidden = !title.window;
    if (title.window) {
        // Fit the widest line of text.
        CGFloat tw = 0; CGRect tr = [title convertRect:title.bounds toView:nb];
        NSMutableArray *labels = [NSMutableArray array];
        if ([title isKindOfClass:[UILabel class]]) [labels addObject:title];
        NSMutableArray *stack = [NSMutableArray arrayWithArray:title.subviews];
        while (stack.count) { UIView *v = stack.lastObject; [stack removeLastObject]; if ([v isKindOfClass:[UILabel class]]) [labels addObject:v]; [stack addObjectsFromArray:v.subviews]; }
        for (UILabel *l in labels) tw = MAX(tw, [l sizeThatFits:CGSizeMake(400, 40)].width);
        CGFloat w = MAX(tw + 64, 150), h = MAX(D, MIN(56, tr.size.height + 12));
        SetFrame(gt, CGRectMake(round(CGRectGetMidX(tr) - w / 2), round(CGRectGetMidY(tr) - h / 2), round(w), round(h)));
    }
    gTopDebug = [NSString stringWithFormat:@"back=%@ title=%@ more=%d edit=%d", NSStringFromClass([back class]), NSStringFromClass([title class]), moreView != nil, editView != nil];
}

#pragma mark - debug

static void UpdateDebug(UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug || !w) { [l removeFromSuperview]; return; }
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
    NSString *text = [NSString stringWithFormat:@" Photos26 1.0.1 debug\n bottom: %@\n top: %@\n video: %@\n last tap: %@", gBottomDebug, gTopDebug, gVideoDebug, gForwardDebug];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize sz = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    SetFrame(l, CGRectMake(12, w.bounds.size.height * 0.3, width, sz.height + 6));
    [w bringSubviewToFront:l];
}

#pragma mark - taps and the per-frame update

@implementation PGTarget
+ (instancetype)shared { static PGTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [PGTarget new]; }); return t; }
- (void)down:(PGButton *)b { Squish(b, YES); }
- (void)up:(PGButton *)b { Squish(b, NO); }
- (void)tap:(PGButton *)b {
    Squish(b, NO);
    NSString *k = b.kind;
    if ([k isEqualToString:@"edit"]) Forward(gEditItem);
    else Forward(AppleItem(k));
    if ([k isEqualToString:@"heart"]) {
        // little heart pop
        [UIView animateWithDuration:0.1 animations:^{ b.imageView.transform = CGAffineTransformMakeScale(1.35, 1.35); } completion:^(BOOL d) {
            [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.8 options:0 animations:^{ b.imageView.transform = CGAffineTransformIdentity; } completion:nil];
        }];
    }
    // Apple's buttons change (heart fills, play becomes pause): refresh soon.
    for (NSNumber *d in @[@0.05, @0.25, @0.6])
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIToolbar *t = gToolbar; if (t) { @try { LayoutBottom(t); } @catch (__unused id e) {} }
        });
}
- (void)tick:(CADisplayLink *)link {
    UIToolbar *tb = gToolbar;
    UIView *c = [tb viewWithTag:BOTTOM_TAG];
    if (!tb.window || !c || c.hidden) { [gLink invalidate]; gLink = nil; return; }
    static NSUInteger frame; frame++;
    @try {
        if (frame % 12 == 0) LayoutBottom(tb);
        PGScrubber *scrub = nil;
        for (UIView *v in c.subviews) if ([v isKindOfClass:[PGScrubber class]]) scrub = (PGScrubber *)v;
        if (scrub && !scrub.hidden) {
            if (frame % 15 == 1 || !gAVPlayer) gAVPlayer = CurrentPlayer(tb.window);
            AVPlayer *p = gAVPlayer;
            CMTime dur = p.currentItem.duration, now = p.currentTime;
            (void)dur;
            if (p && Dur(p) > 0 && !gScrubbing) scrub.progress = CMTimeGetSeconds(now) / Dur(p);
            gVideoDebug = [NSString stringWithFormat:@"using %.1f/%.1f r%.1f | %@", CMTimeGetSeconds(now), Dur(p), p.rate, gPlayersDebug];
        }
        if (frame % 10 == 0) UpdateDebug(tb.window);
        UINavigationBar *nb = gNavBar;
        if ((!nb || nb.window != tb.window) && frame % 30 == 3) {
            NSMutableArray *stack = [NSMutableArray arrayWithObject:tb.window];
            int guard = 0; nb = nil;
            while (stack.count && guard++ < 3000 && !nb) {
                UIView *v = stack.lastObject; [stack removeLastObject];
                if ([v isKindOfClass:[UINavigationBar class]] && !v.hidden && v.alpha > 0.01 && ((UINavigationBar *)v).topItem.rightBarButtonItems.count) nb = (UINavigationBar *)v;
                else [stack addObjectsFromArray:v.subviews];
            }
            if (nb) gNavBar = nb;
        }
        if (nb && frame % 12 == 6) LayoutTop(nb);
    } @catch (__unused id e) {}
}
@end

static void StartLink(void) {
    if (gLink) return;
    gLink = [CADisplayLink displayLinkWithTarget:[PGTarget shared] selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) gLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    [gLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - hooks

%hook UIToolbar
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try { LayoutBottom(self); if ([self viewWithTag:BOTTOM_TAG] && ![self viewWithTag:BOTTOM_TAG].hidden) StartLink(); } @catch (__unused id e) {}
    objc_setAssociatedObject(self, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
// Our player capsule floats above the toolbar, outside its bounds.
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *c = [self viewWithTag:BOTTOM_TAG];
    if (c && !c.hidden && self.alpha > 0.01 && !self.hidden) {
        UIView *h = [c hitTest:[self convertPoint:p toView:c] withEvent:e];
        if (h) return h;
    }
    return %orig;
}
%end

%hook UINavigationBar
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try { LayoutTop(self); } @catch (__unused id e) {}
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
