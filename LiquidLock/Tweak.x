// LiquidLock 0.3 - made by nano
// 0.3: no island: the Face ID face itself, in liquid glass, where the lock is. It curls into a glass ring
//      that spins and wobbles like liquid and pops when you unlock.
// 0.2: a Dynamic Island style Face ID for notched iPhones. When Face ID starts looking, a black island drips
//      out of the notch and grows into a rounded square with a Face ID glyph that scans; unlocking turns it
//      into a check, then it pulls back up into the notch with a squish. No match: it shakes like jelly.
//      Apple's own lock stays as it is (it only steps aside while the island is out). Only on iPhones with a
//      notch: Dynamic Island iPhones already have this.
// Apple's lock states (SpringBoardUIServices): 1, 20-22, 9, 11-13, 17-19, 23 locked / coaching;
// 4-8, 10, 14-16 Face ID looking; 2 unlocked; 3 no match. Read every frame (not hooked: the setter differs by iOS).
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <substrate.h>

#define DOM CFSTR("com.nano.liquidlock")

static BOOL gEnabled = YES, gHaptics = YES, gDebug = NO;

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *f = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingString:@"com.nano.liquidlock.plist"]];
        if ([d isKindOfClass:[NSDictionary class]]) { f = d; break; }
    }
    BOOL (^get)(NSString *, BOOL) = ^BOOL(NSString *k, BOOL def) {
        id v = f[k];
        if (!v) { CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)k, DOM); if (cf) v = (__bridge_transfer id)cf; }
        return v ? [v boolValue] : def;
    };
    gEnabled = get(@"enabled", YES);
    gHaptics = get(@"haptics", YES);
    gDebug = get(@"debug", NO);
}

typedef NS_ENUM(int, LLMode) { LLLocked = 0, LLScanning = 1, LLUnlocked = 2, LLFailed = 3 };
static LLMode ModeFor(long long s) {
    switch (s) {
        case 2: return LLUnlocked;
        case 3: return LLFailed;
        case 4: case 5: case 6: case 7: case 8: case 10: case 14: case 15: case 16: return LLScanning;
        default: return LLLocked;
    }
}

@interface SBUIProudLockIconView : UIView
- (long long)state;
@end

static void Haptic(int kind) {
    if (!gHaptics) return;
    if (kind == 2) [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];
    else if (kind == 3) [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    else [[[UIImpactFeedbackGenerator alloc] initWithStyle:kind == 1 ? UIImpactFeedbackStyleMedium : UIImpactFeedbackStyleSoft] impactOccurred];
}
static CASpringAnimation *Spring(NSString *kp, id from, id to, CGFloat stiff, CGFloat damp) {
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:kp];
    a.fromValue = from; a.toValue = to; a.mass = 1; a.stiffness = stiff; a.damping = damp; a.duration = a.settlingDuration;
    return a;
}

#pragma mark - the glass Face ID

// The Face ID face, made of liquid glass (frosted, see-through, with a bright rim), floating where Apple's lock
// is. While it looks for you the face glances around and the brackets breathe. When it knows you, the brackets
// curl into a glass ring that spins and wobbles like liquid, squeezes into a drop and pops. No match: jelly shake.
@interface LLIsland : UIView
- (void)openAt:(CGPoint)c;
- (void)success:(void (^)(void))done;
- (void)fail;
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done;
@property (nonatomic, readonly) BOOL isOut;
@end
@implementation LLIsland {
    UIView *_box;                          // the glyph, positioned at the lock
    UIVisualEffectView *_glass;            // glass, masked to the strokes
    UIView *_maskV;
    CAShapeLayer *_mCorners, *_mFace;      // masks (the glass shows through these strokes)
    CAShapeLayer *_rim, *_rimFace, *_shine;// light on the glass
    BOOL _out, _closing;
    CFTimeInterval _openedAt;
    CGFloat _g;
}
- (BOOL)isOut { return _out; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    CGFloat g = 46; _g = g;
    _box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, g, g)];
    _box.alpha = 0;
    _box.layer.shadowColor = UIColor.blackColor.CGColor; _box.layer.shadowOpacity = 0.22; _box.layer.shadowRadius = 5; _box.layer.shadowOffset = CGSizeMake(0, 2);
    [self addSubview:_box];
    _glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    _glass.frame = CGRectInset(_box.bounds, -12, -12);
    UIView *tint = [[UIView alloc] initWithFrame:_glass.bounds]; tint.backgroundColor = [UIColor colorWithWhite:1 alpha:0.42];
    [_glass.contentView addSubview:tint];
    _maskV = [[UIView alloc] initWithFrame:_glass.bounds];
    _mCorners = [self strokeLayer:5.2 color:UIColor.blackColor];
    _mFace = [self strokeLayer:4.4 color:UIColor.blackColor];
    [_maskV.layer addSublayer:_mCorners]; [_maskV.layer addSublayer:_mFace];
    _glass.maskView = _maskV;
    [_box addSubview:_glass];
    // the light: a bright edge on the glass, a softer one on the face, and a glint that travels
    _rim = [self strokeLayer:5.2 color:[UIColor colorWithWhite:1 alpha:0.5]];
    _rimFace = [self strokeLayer:4.4 color:[UIColor colorWithWhite:1 alpha:0.42]];
    _shine = [self strokeLayer:1.6 color:[UIColor colorWithWhite:1 alpha:0.95]];
    _shine.strokeStart = 0; _shine.strokeEnd = 0.12;
    for (CAShapeLayer *l in @[_rim, _rimFace, _shine]) { l.frame = _glass.frame; [_box.layer addSublayer:l]; }
    [self setCornersPath:[self cornersPath] animated:NO];
    UIBezierPath *face = [self facePath];
    _mFace.path = face.CGPath; _rimFace.path = face.CGPath;
    return self;
}
- (CAShapeLayer *)strokeLayer:(CGFloat)w color:(UIColor *)c {
    CAShapeLayer *l = [CAShapeLayer layer];
    l.frame = CGRectMake(0, 0, _g + 24, _g + 24);
    l.fillColor = UIColor.clearColor.CGColor; l.strokeColor = c.CGColor; l.lineWidth = w;
    l.lineCap = kCALineCapRound; l.lineJoin = kCALineJoinRound;
    return l;
}
// all paths are in the glass's coordinates (12 pt margin around the glyph)
- (UIBezierPath *)cornersPath {
    CGFloat g = _g, o = 12, L = g * 0.27, R = g * 0.17;
    UIBezierPath *p = [UIBezierPath bezierPath];
    CGPoint P[4][4] = {
        {{o, o + L}, {o, o + R}, {o, o}, {o + L, o}},
        {{o + g - L, o}, {o + g - R, o}, {o + g, o}, {o + g, o + L}},
        {{o + g, o + g - L}, {o + g, o + g - R}, {o + g, o + g}, {o + g - L, o + g}},
        {{o + L, o + g}, {o + R, o + g}, {o, o + g}, {o, o + g - L}}};
    for (int i = 0; i < 4; i++) {
        [p moveToPoint:P[i][0]]; [p addLineToPoint:P[i][1]];
        CGPoint end = i == 0 ? CGPointMake(o + R, o) : i == 1 ? CGPointMake(o + g, o + R) : i == 2 ? CGPointMake(o + g - R, o + g) : CGPointMake(o, o + g - R);
        [p addQuadCurveToPoint:end controlPoint:P[i][2]];
        [p addLineToPoint:P[i][3]];
    }
    return p;
}
// the same four pieces, bent into a ring (so the brackets can curl into it)
- (UIBezierPath *)ringPath:(CGFloat)r {
    CGFloat c = _g / 2 + 12;
    UIBezierPath *p = [UIBezierPath bezierPath];
    double starts[4] = {M_PI, M_PI * 1.5, 0, M_PI * 0.5};
    for (int i = 0; i < 4; i++) {
        double a0 = starts[i], a1 = a0 + M_PI / 2, e = 0.12;
        CGPoint (^pt)(double) = ^CGPoint(double a) { return CGPointMake(c + r * cos(a), c + r * sin(a)); };
        [p moveToPoint:pt(a0)]; [p addLineToPoint:pt(a0 + e)];
        double am = (a0 + a1) / 2, k = r / cos((a1 - a0 - 2 * e) / 2);
        [p addQuadCurveToPoint:pt(a1 - e) controlPoint:CGPointMake(c + k * cos(am), c + k * sin(am))];
        [p addLineToPoint:pt(a1)];
    }
    return p;
}
- (UIBezierPath *)facePath {
    CGFloat g = _g, o = 12;
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(o + g * 0.33, o + g * 0.34)]; [p addLineToPoint:CGPointMake(o + g * 0.33, o + g * 0.43)];
    [p moveToPoint:CGPointMake(o + g * 0.67, o + g * 0.34)]; [p addLineToPoint:CGPointMake(o + g * 0.67, o + g * 0.43)];
    [p moveToPoint:CGPointMake(o + g * 0.5, o + g * 0.34)]; [p addLineToPoint:CGPointMake(o + g * 0.5, o + g * 0.57)]; [p addLineToPoint:CGPointMake(o + g * 0.44, o + g * 0.57)];
    [p moveToPoint:CGPointMake(o + g * 0.33, o + g * 0.69)]; [p addQuadCurveToPoint:CGPointMake(o + g * 0.67, o + g * 0.69) controlPoint:CGPointMake(o + g * 0.5, o + g * 0.81)];
    return p;
}
- (void)setCornersPath:(UIBezierPath *)to animated:(BOOL)a {
    for (CAShapeLayer *l in @[_mCorners, _rim, _shine]) {
        if (a) {
            CAShapeLayer *pl = l.presentationLayer;
            CASpringAnimation *s = Spring(@"path", (id)pl.path ?: (id)l.path, (id)to.CGPath, 260, 14);
            [l addAnimation:s forKey:@"path"];
        }
        l.path = to.CGPath;
    }
}
- (void)openAt:(CGPoint)c {
    _box.center = c;
    if (_out && !_closing) return;
    _out = YES; _closing = NO; _openedAt = CACurrentMediaTime();
    [_box.layer removeAllAnimations];
    for (CALayer *l in @[_mFace, _rimFace]) { [l removeAllAnimations]; l.opacity = 1; }
    [self setCornersPath:[self cornersPath] animated:NO];
    for (CALayer *l in @[_mCorners, _rim, _shine]) [l removeAllAnimations];
    // it surfaces like a bubble: from small and soft to its size with a wobble
    _box.alpha = 1;
    CASpringAnimation *in = Spring(@"transform.scale", @0.45, @1, 300, 14);
    CABasicAnimation *f = [CABasicAnimation animationWithKeyPath:@"opacity"]; f.fromValue = @0; f.toValue = @1; f.duration = 0.18;
    [_box.layer addAnimation:in forKey:@"in"]; [_box.layer addAnimation:f forKey:@"fade"];
    [self scanMotion];
}
- (void)scanMotion {
    CABasicAnimation *br = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    br.fromValue = @1; br.toValue = @1.07; br.duration = 0.6; br.autoreverses = YES; br.repeatCount = HUGE_VALF;
    br.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    for (CALayer *l in @[_mCorners, _rim, _shine]) { l.anchorPoint = CGPointMake(0.5, 0.5); l.frame = _glass.frame; [l addAnimation:br forKey:@"breathe"]; }
    _mCorners.frame = _maskV.bounds;
    // the face looks around
    CAKeyframeAnimation *look = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    look.values = @[@0, @2.4, @2.4, @0, @-2.4, @-2.4, @0]; look.keyTimes = @[@0, @0.15, @0.35, @0.5, @0.65, @0.85, @1]; look.duration = 1.6; look.repeatCount = HUGE_VALF;
    CAKeyframeAnimation *nod = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    nod.values = @[@0, @-1, @0, @1.2, @0]; nod.duration = 2.1; nod.repeatCount = HUGE_VALF;
    for (CALayer *l in @[_mFace, _rimFace]) { [l addAnimation:look forKey:@"look"]; [l addAnimation:nod forKey:@"nod"]; }
    // a glint runs around the glass
    CABasicAnimation *g0 = [CABasicAnimation animationWithKeyPath:@"strokeStart"]; g0.fromValue = @0; g0.toValue = @0.88;
    CABasicAnimation *g1 = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; g1.fromValue = @0.12; g1.toValue = @1;
    CAAnimationGroup *gg = [CAAnimationGroup animation]; gg.animations = @[g0, g1]; gg.duration = 1.3; gg.repeatCount = HUGE_VALF;
    [_shine addAnimation:gg forKey:@"glint"];
}
- (void)stopScan {
    for (CALayer *l in @[_mCorners, _rim, _shine, _mFace, _rimFace]) { [l removeAnimationForKey:@"breathe"]; [l removeAnimationForKey:@"look"]; [l removeAnimationForKey:@"nod"]; [l removeAnimationForKey:@"glint"]; }
}
// recognized: the face melts away, the brackets curl into a glass ring that spins and wobbles like liquid,
// squeezes into a drop and pops
- (void)success:(void (^)(void))done {
    __weak LLIsland *ws = self;
    CGFloat wait = MAX(0, 0.25 - (CACurrentMediaTime() - _openedAt));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LLIsland *s = ws; if (!s || !s->_out || s->_closing) { if (done) done(); return; }
        s->_closing = YES;
        [s stopScan];
        CABasicAnimation *ff = [CABasicAnimation animationWithKeyPath:@"opacity"]; ff.fromValue = @1; ff.toValue = @0; ff.duration = 0.16;
        CABasicAnimation *fs = [CABasicAnimation animationWithKeyPath:@"transform.scale"]; fs.fromValue = @1; fs.toValue = @0.6; fs.duration = 0.2;
        for (CALayer *l in @[s->_mFace, s->_rimFace]) { [l addAnimation:ff forKey:@"out"]; [l addAnimation:fs forKey:@"shrink"]; l.opacity = 0; }
        // curl into a ring
        [s setCornersPath:[s ringPath:s->_g * 0.4] animated:YES];
        s->_shine.strokeStart = 0; s->_shine.strokeEnd = 0.2;
        Haptic(3);
        // the ring spins and wobbles like liquid
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"]; spin.fromValue = @0; spin.toValue = @(M_PI * 1.6); spin.duration = 0.75;
        spin.beginTime = CACurrentMediaTime() + 0.18; spin.fillMode = kCAFillModeBoth; spin.removedOnCompletion = NO;
        spin.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4 :0 :0.2 :1];
        CAKeyframeAnimation *wx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"]; wx.values = @[@1, @1.16, @0.88, @1.1, @0.94, @1];
        CAKeyframeAnimation *wy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"]; wy.values = @[@1, @0.86, @1.12, @0.92, @1.05, @1];
        for (CAKeyframeAnimation *k in @[wx, wy]) { k.duration = 0.75; k.beginTime = CACurrentMediaTime() + 0.18; k.fillMode = kCAFillModeBackwards; }
        [s->_box.layer addAnimation:spin forKey:@"spin"]; [s->_box.layer addAnimation:wx forKey:@"wx"]; [s->_box.layer addAnimation:wy forKey:@"wy"];
        // then it squeezes into a drop and pops
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LLIsland *s2 = ws; if (!s2) { if (done) done(); return; }
            [s2 setCornersPath:[s2 ringPath:s2->_g * 0.12] animated:YES];
            CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            pop.values = @[@1, @0.8, @1.5]; pop.keyTimes = @[@0, @0.55, @1]; pop.duration = 0.32; pop.fillMode = kCAFillModeForwards; pop.removedOnCompletion = NO;
            CABasicAnimation *fo = [CABasicAnimation animationWithKeyPath:@"opacity"]; fo.fromValue = @1; fo.toValue = @0; fo.beginTime = CACurrentMediaTime() + 0.16; fo.duration = 0.16;
            fo.fillMode = kCAFillModeForwards; fo.removedOnCompletion = NO;
            [s2->_box.layer addAnimation:pop forKey:@"pop"]; [s2->_box.layer addAnimation:fo forKey:@"fo"];
            Haptic(0);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.34 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                LLIsland *s3 = ws; if (s3) { s3->_box.alpha = 0; [s3->_box.layer removeAllAnimations]; s3->_out = NO; s3->_closing = NO; }
                if (done) done();
            });
        });
    });
}
// no match: a jelly shake
- (void)fail {
    CAKeyframeAnimation *tx = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    tx.values = @[@0, @-12, @10, @-7, @4, @-2, @0];
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"]; sx.values = @[@1, @1.12, @0.92, @1.06, @0.97, @1.01, @1];
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"]; sy.values = @[@1, @0.9, @1.08, @0.95, @1.03, @0.99, @1];
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[tx, sx, sy]; g.duration = 0.6;
    g.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_box.layer addAnimation:g forKey:@"jelly"];
    Haptic(2);
}
// gone: it sinks back down into a bubble and fades
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done {
    if (!_out || (_closing && a)) { if (done && !_closing) done(); return; }
    [self stopScan];
    if (!a) { [_box.layer removeAllAnimations]; _box.alpha = 0; _out = NO; _closing = NO; if (done) done(); return; }
    _closing = YES;
    __weak LLIsland *ws = self;
    [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self->_box.alpha = 0; self->_box.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(__unused BOOL f) {
        LLIsland *s = ws; if (s) { s->_box.transform = CGAffineTransformIdentity; s->_out = NO; s->_closing = NO; }
        if (done) done();
    }];
}
@end

#pragma mark - watching Apple's lock

static const void *kWatch = &kWatch;
@interface LLWatch : NSObject
@property (nonatomic, weak) UIView *icon;
@property (nonatomic, strong) LLIsland *island;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) long long last;
@property (nonatomic, strong) UILabel *dbg;
@end
@implementation LLWatch
// notched iPhones only: Dynamic Island iPhones have a taller top safe area
static BOOL HasNotch(UIWindow *w) {
    CGFloat top = w.safeAreaInsets.top;
    return top >= 40 && top < 54;
}
- (void)start {
    if (self.link) return;
    self.last = -1;
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    if (@available(iOS 15.0, *)) self.link.preferredFrameRateRange = CAFrameRateRangeMake(20, 30, 30);
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)stop { [self.link invalidate]; self.link = nil; }
- (void)iconHidden:(BOOL)h {
    UIView *icon = self.icon;
    if (h && !icon.layer.mask) icon.layer.mask = [CALayer layer];
    else if (!h && icon.layer.mask && !icon.layer.mask.contents && !icon.layer.mask.sublayers.count) {
        icon.layer.mask = nil;
        // the lock comes back with a little pop
        CASpringAnimation *p = Spring(@"transform.scale", @0.6, @1, 320, 14);
        [icon.layer addAnimation:p forKey:@"ll.pop"];
    }
}
- (void)tick {
    UIView *icon = self.icon;
    UIWindow *w = icon.window;
    if (!icon || !w) { [self.island closeAnimated:NO done:nil]; [self.island removeFromSuperview]; [self stop]; return; }
    if (!gEnabled || !HasNotch(w)) { if (self.island.isOut) { [self.island closeAnimated:NO done:nil]; [self iconHidden:NO]; } return; }
    long long s = 1; @try { s = [(SBUIProudLockIconView *)icon state]; } @catch (__unused id e) {}
    if (s == self.last) return;
    long long was = self.last; self.last = s;
    if (gDebug) {
        if (!self.dbg) { self.dbg = [UILabel new]; self.dbg.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightSemibold]; self.dbg.textColor = UIColor.whiteColor; self.dbg.textAlignment = NSTextAlignmentCenter; }
        if (self.dbg.superview != w) [w addSubview:self.dbg];
        self.dbg.frame = CGRectMake(0, 160, w.bounds.size.width, 14);
        NSString *old = [self.dbg.text componentsSeparatedByString:@" "].lastObject ?: @"";
        self.dbg.text = [NSString stringWithFormat:@"states: %@ %lld", old, s];
    } else { [self.dbg removeFromSuperview]; self.dbg = nil; }
    if (was < 0) return;   // just appeared: no animation for the state it already had
    if (!self.island || self.island.superview != w) {
        [self.island removeFromSuperview];
        self.island = [[LLIsland alloc] initWithFrame:w.bounds];
        [w addSubview:self.island];
    }
    [w bringSubviewToFront:self.island];
    LLMode m = ModeFor(s);
    __weak LLWatch *ws = self;
    switch (m) {
        case LLScanning:
            [self iconHidden:YES];
            [self.island openAt:[icon convertPoint:CGPointMake(icon.bounds.size.width / 2, icon.bounds.size.height / 2) toView:w]];
            break;
        case LLUnlocked:
            if (!self.island.isOut && ModeFor(was) != LLScanning) break;
            if (!self.island.isOut) [self.island openAt:[icon convertPoint:CGPointMake(icon.bounds.size.width / 2, icon.bounds.size.height / 2) toView:w]];
            {
                [self iconHidden:YES];
                [self.island success:^{ [ws iconHidden:NO]; }];
            }
            break;
        case LLFailed:
            if (!self.island.isOut) break;
            [self.island fail];
            break;
        case LLLocked:
            if (self.island.isOut) {
                // a short pause after a failed try, then back in
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((ModeFor(was) == LLFailed ? 0.5 : 0.05) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    LLWatch *s2 = ws; if (!s2) return;
                    long long now = 1; @try { now = [(SBUIProudLockIconView *)s2.icon state]; } @catch (__unused id e) {}
                    if (ModeFor(now) == LLLocked) [s2.island closeAnimated:YES done:^{ [ws iconHidden:NO]; }];
                });
            }
            break;
    }
}
@end

static void Watch(UIView *icon) {
    LLWatch *wt = objc_getAssociatedObject(icon, kWatch);
    if (!wt) { wt = [LLWatch new]; wt.icon = icon; objc_setAssociatedObject(icon, kWatch, wt, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    if (icon.window) [wt start];
}

%hook SBUIProudLockIconView
- (void)didMoveToWindow { %orig; Watch(self); }
- (void)layoutSubviews { %orig; Watch(self); }
%end

static void InitHooks(void) { static BOOL done; if (done) return; done = YES; %init; }
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }

#include "../shared/NanoSettings.h"

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if ([bid isEqualToString:@"com.apple.Preferences"]) { StartNanoSettings(); return; }
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.liquidlock/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    if (objc_getClass("SBUIProudLockIconView")) { InitHooks(); return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        __block int tries = 0;
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *tm) {
            if (objc_getClass("SBUIProudLockIconView")) { InitHooks(); [tm invalidate]; }
            else if (++tries > 120) [tm invalidate];
        }];
    });
}
