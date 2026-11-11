// LiquidLock 0.5 - made by nano
// 0.5: unlocking is Apple-like (white ring spins, then a check), and the face has two animations that take turns.
// 0.4: lock-sized, plain (no glass), the face also replaces the lock on the passcode screen, and unlocking turns
//      it into a glowing blue ring that spins, wobbles and bursts into blue sparks.
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

#pragma mark - the Face ID face

// The Face ID face, the size of Apple's lock and the same color, where the lock is. While Face ID looks for you
// (and on the passcode screen) it looks around and the brackets breathe. When it knows you, the brackets curl
// into a ring that turns into a glowing blue ring: it spins, wobbles like liquid, squeezes into a drop and
// bursts into blue sparks. No match: a jelly shake.
@interface LLIsland : UIView
- (void)openAt:(CGPoint)c;
- (void)success:(void (^)(void))done;
- (void)fail;
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done;
@property (nonatomic, readonly) BOOL isOut;
@property (nonatomic, strong) UIColor *tint;
@end
@implementation LLIsland {
    UIView *_box;
    CAShapeLayer *_corners, *_face, *_eyeL, *_eyeR, *_check;
    int _variant;                    // which of the two face animations plays this time
    BOOL _out, _closing;
    CFTimeInterval _openedAt;
    CGFloat _g;
}
- (BOOL)isOut { return _out; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    CGFloat g = 24; _g = g;   // about the size of Apple's lock
    _box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, g, g)];
    _box.alpha = 0;
    [self addSubview:_box];
    _tint = UIColor.whiteColor;
    _corners = [self stroke:2.5]; _face = [self stroke:2.1]; _eyeL = [self stroke:2.1]; _eyeR = [self stroke:2.1]; _check = [self stroke:2.6];
    CGFloat e = g;
    _corners.path = [self cornersPath].CGPath; _face.path = [self facePath].CGPath;
    UIBezierPath *el = [UIBezierPath bezierPath]; [el moveToPoint:CGPointMake(e * 0.33, e * 0.34)]; [el addLineToPoint:CGPointMake(e * 0.33, e * 0.43)];
    UIBezierPath *er = [UIBezierPath bezierPath]; [er moveToPoint:CGPointMake(e * 0.67, e * 0.34)]; [er addLineToPoint:CGPointMake(e * 0.67, e * 0.43)];
    _eyeL.path = el.CGPath; _eyeR.path = er.CGPath;
    // eyes blink around their own middle
    _eyeL.anchorPoint = CGPointMake(0.33, 0.385); _eyeR.anchorPoint = CGPointMake(0.67, 0.385);
    _eyeL.frame = CGRectMake(0, 0, g, g); _eyeR.frame = CGRectMake(0, 0, g, g);
    UIBezierPath *ck = [UIBezierPath bezierPath];
    [ck moveToPoint:CGPointMake(e * 0.3, e * 0.52)]; [ck addLineToPoint:CGPointMake(e * 0.45, e * 0.67)]; [ck addLineToPoint:CGPointMake(e * 0.72, e * 0.36)];
    _check.path = ck.CGPath; _check.strokeEnd = 0;
    for (CALayer *l in @[_corners, _face, _eyeL, _eyeR, _check]) [_box.layer addSublayer:l];
    return self;
}
- (void)setTint:(UIColor *)t {
    if (!t || [t isEqual:_tint]) return;
    _tint = t;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (CAShapeLayer *l in @[_corners, _face, _eyeL, _eyeR, _check]) l.strokeColor = t.CGColor;
    [CATransaction commit];
}
- (CAShapeLayer *)stroke:(CGFloat)w {
    CAShapeLayer *l = [CAShapeLayer layer]; l.frame = CGRectMake(0, 0, _g, _g);
    l.fillColor = UIColor.clearColor.CGColor; l.strokeColor = UIColor.whiteColor.CGColor; l.lineWidth = w;
    l.lineCap = kCALineCapRound; l.lineJoin = kCALineJoinRound;
    return l;
}
- (UIBezierPath *)cornersPath {
    CGFloat g = _g, L = g * 0.27, R = g * 0.17;
    UIBezierPath *p = [UIBezierPath bezierPath];
    CGPoint P[4][4] = {{{0, L}, {0, R}, {0, 0}, {L, 0}}, {{g - L, 0}, {g - R, 0}, {g, 0}, {g, L}},
                       {{g, g - L}, {g, g - R}, {g, g}, {g - L, g}}, {{L, g}, {R, g}, {0, g}, {0, g - L}}};
    CGPoint E[4] = {{R, 0}, {g, R}, {g - R, g}, {0, g - R}};
    for (int i = 0; i < 4; i++) { [p moveToPoint:P[i][0]]; [p addLineToPoint:P[i][1]]; [p addQuadCurveToPoint:E[i] controlPoint:P[i][2]]; [p addLineToPoint:P[i][3]]; }
    return p;
}
// the same four pieces bent into a ring (the brackets curl into it)
- (UIBezierPath *)ringPath:(CGFloat)r center:(CGPoint)c {
    UIBezierPath *p = [UIBezierPath bezierPath];
    double starts[4] = {M_PI, M_PI * 1.5, 0, M_PI * 0.5};
    for (int i = 0; i < 4; i++) {
        double a0 = starts[i], a1 = a0 + M_PI / 2, e = 0.12, am = (a0 + a1) / 2, k = r / cos((a1 - a0 - 2 * e) / 2);
        [p moveToPoint:CGPointMake(c.x + r * cos(a0), c.y + r * sin(a0))];
        [p addLineToPoint:CGPointMake(c.x + r * cos(a0 + e), c.y + r * sin(a0 + e))];
        [p addQuadCurveToPoint:CGPointMake(c.x + r * cos(a1 - e), c.y + r * sin(a1 - e)) controlPoint:CGPointMake(c.x + k * cos(am), c.y + k * sin(am))];
        [p addLineToPoint:CGPointMake(c.x + r * cos(a1), c.y + r * sin(a1))];
    }
    return p;
}
- (UIBezierPath *)facePath {
    CGFloat g = _g;
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(g * 0.5, g * 0.34)]; [p addLineToPoint:CGPointMake(g * 0.5, g * 0.57)]; [p addLineToPoint:CGPointMake(g * 0.44, g * 0.57)];
    [p moveToPoint:CGPointMake(g * 0.33, g * 0.69)]; [p addQuadCurveToPoint:CGPointMake(g * 0.67, g * 0.69) controlPoint:CGPointMake(g * 0.5, g * 0.81)];
    return p;
}
- (void)reset {
    [_box.layer removeAllAnimations]; _box.transform = CGAffineTransformIdentity;
    for (CALayer *l in @[_corners, _face, _eyeL, _eyeR, _check]) [l removeAllAnimations];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _corners.path = [self cornersPath].CGPath; _corners.strokeEnd = 1; _corners.strokeStart = 0;
    for (CALayer *l in @[_corners, _face, _eyeL, _eyeR]) l.opacity = 1;
    _check.strokeEnd = 0; _check.opacity = 1;
    [CATransaction commit];
}
- (void)openAt:(CGPoint)c {
    _box.center = CGPointMake(round(c.x), round(c.y));
    if (_out && !_closing) return;
    _out = YES; _closing = NO; _openedAt = CACurrentMediaTime();
    _variant = 1 - _variant;   // the two face animations take turns
    [self reset];
    // the lock turns into the face: it pops in with a little overshoot
    _box.alpha = 1;
    CASpringAnimation *in = Spring(@"transform.scale", @0.3, @1, 340, 15);
    CABasicAnimation *f = [CABasicAnimation animationWithKeyPath:@"opacity"]; f.fromValue = @0; f.toValue = @1; f.duration = 0.14;
    [_box.layer addAnimation:in forKey:@"in"]; [_box.layer addAnimation:f forKey:@"fade"];
    // the brackets draw in from their corners
    CABasicAnimation *draw = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; draw.fromValue = @0.4; draw.toValue = @1; draw.duration = 0.3;
    [_corners addAnimation:draw forKey:@"draw"];
    [self scanMotion];
}
- (void)scanMotion {
    CABasicAnimation *br = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    br.fromValue = @1; br.toValue = @1.1; br.duration = 0.55; br.autoreverses = YES; br.repeatCount = HUGE_VALF;
    br.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_corners addAnimation:br forKey:@"breathe"];
    NSArray *faceParts = @[_face, _eyeL, _eyeR];
    if (_variant == 0) {
        // 1. looking around: the face glances left and right, nods a little, and blinks
        CAKeyframeAnimation *look = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        look.values = @[@0, @1.6, @1.6, @0, @-1.6, @-1.6, @0]; look.keyTimes = @[@0, @0.15, @0.35, @0.5, @0.65, @0.85, @1]; look.duration = 1.6; look.repeatCount = HUGE_VALF;
        CAKeyframeAnimation *nod = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
        nod.values = @[@0, @-0.8, @0, @0.9, @0]; nod.duration = 2.1; nod.repeatCount = HUGE_VALF;
        for (CALayer *l in faceParts) { [l addAnimation:look forKey:@"look"]; [l addAnimation:nod forKey:@"nod"]; }
        CAKeyframeAnimation *blink = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
        blink.values = @[@1, @1, @0.15, @1, @1]; blink.keyTimes = @[@0, @0.84, @0.89, @0.94, @1]; blink.duration = 2.4; blink.repeatCount = HUGE_VALF;
        [_eyeL addAnimation:blink forKey:@"blink"]; [_eyeR addAnimation:blink forKey:@"blink"];
    } else {
        // 2. playful: the head tilts side to side, it winks, and the smile grows
        CAKeyframeAnimation *tilt = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
        tilt.values = @[@0, @0.2, @0.2, @0, @-0.2, @-0.2, @0]; tilt.keyTimes = @[@0, @0.18, @0.35, @0.5, @0.68, @0.85, @1]; tilt.duration = 1.9; tilt.repeatCount = HUGE_VALF;
        tilt.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_box.layer addAnimation:tilt forKey:@"tilt"];   // the whole face tilts around its middle
        CAKeyframeAnimation *wink = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
        wink.values = @[@1, @1, @0.12, @0.12, @1, @1]; wink.keyTimes = @[@0, @0.3, @0.36, @0.5, @0.56, @1]; wink.duration = 1.9; wink.repeatCount = HUGE_VALF;
        [_eyeR addAnimation:wink forKey:@"blink"];
        CAKeyframeAnimation *smile = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        smile.values = @[@1, @1.12, @1, @1, @1.1, @1]; smile.keyTimes = @[@0, @0.3, @0.5, @0.7, @0.85, @1]; smile.duration = 1.9; smile.repeatCount = HUGE_VALF;
        [_face addAnimation:smile forKey:@"smile"];
    }
}
- (void)stopScan {
    for (CALayer *l in @[_corners, _face, _eyeL, _eyeR]) for (NSString *k in @[@"breathe", @"look", @"nod", @"blink", @"tilt", @"smile"]) [l removeAnimationForKey:k];
    [_box.layer removeAnimationForKey:@"tilt"];
}
// recognized, like Apple's but smoother: the face fades, the brackets curl into a ring that spins as an arc,
// the ring closes, a check draws itself inside with a pop, then it all shrinks away into the open lock
- (void)success:(void (^)(void))done {
    __weak LLIsland *ws = self;
    CGFloat wait = MAX(0, 0.2 - (CACurrentMediaTime() - _openedAt));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LLIsland *s = ws; if (!s || !s->_out || s->_closing) { if (done) done(); return; }
        s->_closing = YES;
        [s stopScan];
        CGFloat g = s->_g;
        CABasicAnimation *ff = [CABasicAnimation animationWithKeyPath:@"opacity"]; ff.fromValue = @1; ff.toValue = @0; ff.duration = 0.14;
        CABasicAnimation *fs = [CABasicAnimation animationWithKeyPath:@"transform.scale"]; fs.fromValue = @1; fs.toValue = @0.7; fs.duration = 0.16;
        for (CALayer *l in @[s->_face, s->_eyeL, s->_eyeR]) { [l addAnimation:ff forKey:@"out"]; [l addAnimation:fs forKey:@"shrink"]; l.opacity = 0; }
        // curl into a ring
        UIBezierPath *ring = [s ringPath:g * 0.44 center:CGPointMake(g / 2, g / 2)];
        CASpringAnimation *curl = Spring(@"path", (id)s->_corners.path, (id)ring.CGPath, 330, 18);
        [s->_corners addAnimation:curl forKey:@"curl"]; s->_corners.path = ring.CGPath;
        // spins as an arc, like the Face ID spinner
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"]; spin.fromValue = @0; spin.toValue = @(M_PI * 2.5); spin.duration = 0.5;
        spin.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.35 :0 :0.25 :1];
        CAKeyframeAnimation *arc = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"]; arc.values = @[@1, @0.7, @0.75, @1]; arc.keyTimes = @[@0, @0.3, @0.7, @1]; arc.duration = 0.5;
        [s->_corners addAnimation:spin forKey:@"spin"]; [s->_corners addAnimation:arc forKey:@"arc"];
        // the check draws itself and pops
        CABasicAnimation *draw = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; draw.fromValue = @0; draw.toValue = @1; draw.duration = 0.26;
        draw.beginTime = CACurrentMediaTime() + 0.42; draw.fillMode = kCAFillModeBackwards;
        draw.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.3 :0 :0.2 :1];
        [s->_check addAnimation:draw forKey:@"draw"]; s->_check.strokeEnd = 1;
        CASpringAnimation *pop = Spring(@"transform.scale", @1.18, @1, 360, 12); pop.beginTime = CACurrentMediaTime() + 0.6; pop.fillMode = kCAFillModeBackwards;
        [s->_box.layer addAnimation:pop forKey:@"pop"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ Haptic(3); });
        // then it shrinks away and the open lock comes back
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LLIsland *s2 = ws; if (!s2) { if (done) done(); return; }
            [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                s2->_box.alpha = 0; s2->_box.transform = CGAffineTransformMakeScale(0.5, 0.5);
            } completion:^(__unused BOOL f) {
                LLIsland *s3 = ws; if (s3) { s3->_box.transform = CGAffineTransformIdentity; [s3 reset]; s3->_out = NO; s3->_closing = NO; }
                if (done) done();
            }];
        });
    });
}
- (void)burstAt:(CGPoint)c {
    NSArray *cols = @[[UIColor colorWithRed:0.12 green:0.45 blue:1 alpha:1], [UIColor colorWithRed:0.25 green:0.85 blue:1 alpha:1], [UIColor colorWithRed:0.55 green:0.4 blue:1 alpha:1]];
    NSMutableArray *ls = [NSMutableArray array];
    // a flash ring
    CAShapeLayer *ring = [CAShapeLayer layer]; ring.frame = self.bounds;
    ring.fillColor = UIColor.clearColor.CGColor; ring.strokeColor = [cols[0] colorWithAlphaComponent:0.9].CGColor; ring.lineWidth = 2.5;
    ring.path = [UIBezierPath bezierPathWithArcCenter:c radius:4 startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    ring.shadowColor = [cols[0] CGColor]; ring.shadowOpacity = 1; ring.shadowRadius = 5; ring.shadowOffset = CGSizeZero;
    [self.layer addSublayer:ring]; [ls addObject:ring];
    CABasicAnimation *gr = [CABasicAnimation animationWithKeyPath:@"path"]; gr.toValue = (id)[UIBezierPath bezierPathWithArcCenter:c radius:26 startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    CABasicAnimation *th = [CABasicAnimation animationWithKeyPath:@"lineWidth"]; th.toValue = @0.3;
    CABasicAnimation *fo = [CABasicAnimation animationWithKeyPath:@"opacity"]; fo.toValue = @0;
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[gr, th, fo]; g.duration = 0.45;
    g.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.15 :0.8 :0.3 :1]; g.fillMode = kCAFillModeForwards; g.removedOnCompletion = NO;
    [ring addAnimation:g forKey:@"b"];
    // sparks
    for (int i = 0; i < 10; i++) {
        double ang = i * (M_PI * 2 / 10) + 0.2;
        CGFloat d = 2.4 + (i % 3) * 0.8, dist = 20 + (i % 4) * 5;
        CALayer *sp = [CALayer layer]; sp.bounds = CGRectMake(0, 0, d, d); sp.cornerRadius = d / 2; sp.position = c;
        UIColor *col = cols[i % 3]; sp.backgroundColor = col.CGColor;
        sp.shadowColor = col.CGColor; sp.shadowOpacity = 1; sp.shadowRadius = 2.5; sp.shadowOffset = CGSizeZero;
        [self.layer addSublayer:sp]; [ls addObject:sp];
        CABasicAnimation *mv = [CABasicAnimation animationWithKeyPath:@"position"]; mv.toValue = [NSValue valueWithCGPoint:CGPointMake(c.x + cos(ang) * dist, c.y + sin(ang) * dist)];
        CABasicAnimation *sc = [CABasicAnimation animationWithKeyPath:@"transform.scale"]; sc.toValue = @0.2;
        CABasicAnimation *op = [CABasicAnimation animationWithKeyPath:@"opacity"]; op.toValue = @0;
        CAAnimationGroup *gg = [CAAnimationGroup animation]; gg.animations = @[mv, sc, op]; gg.duration = 0.5;
        gg.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :0.7 :0.3 :1]; gg.fillMode = kCAFillModeForwards; gg.removedOnCompletion = NO;
        [sp addAnimation:gg forKey:@"fly"];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ for (CALayer *l in ls) [l removeFromSuperlayer]; });
}
// no match: a jelly shake
- (void)fail {
    CAKeyframeAnimation *tx = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    tx.values = @[@0, @-9, @8, @-5, @3, @-1.5, @0];
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"]; sx.values = @[@1, @1.14, @0.9, @1.07, @0.96, @1.01, @1];
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"]; sy.values = @[@1, @0.88, @1.1, @0.95, @1.03, @0.99, @1];
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[tx, sx, sy]; g.duration = 0.6;
    g.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_box.layer addAnimation:g forKey:@"jelly"];
    Haptic(2);
}
// back to the lock: it shrinks away
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done {
    if (!_out || _closing) { if (done && !_closing) done(); return; }
    [self stopScan];
    if (!a) { [self reset]; _box.alpha = 0; _out = NO; if (done) done(); return; }
    _closing = YES;
    __weak LLIsland *ws = self;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self->_box.alpha = 0; self->_box.transform = CGAffineTransformMakeScale(0.4, 0.4);
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
@property (nonatomic, weak) UIView *passcode;
@property (nonatomic) NSUInteger frames;
@property (nonatomic) BOOL onPasscode;
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
- (void)ensureIsland:(UIWindow *)w {
    if (!self.island || self.island.superview != w) {
        [self.island removeFromSuperview];
        self.island = [[LLIsland alloc] initWithFrame:w.bounds];
        [w addSubview:self.island];
    }
    [w bringSubviewToFront:self.island];
}
- (void)tick {
    UIView *icon = self.icon;
    UIWindow *w = icon.window;
    if (!icon || !w) { [self.island closeAnimated:NO done:nil]; [self.island removeFromSuperview]; [self stop]; return; }
    if (!gEnabled || !HasNotch(w)) { if (self.island.isOut) { [self.island closeAnimated:NO done:nil]; [self iconHidden:NO]; } return; }
    long long s = 1; @try { s = [(SBUIProudLockIconView *)icon state]; } @catch (__unused id e) {}
    // the passcode screen: the lock up top becomes the face, looking around the whole time
    self.frames++;
    if (self.frames % 6 == 0) {
        UIView *pc = self.passcode;
        if (!pc || pc.window != w) {
            pc = nil;
            NSMutableArray *st = [NSMutableArray arrayWithObject:w]; int guard = 0;
            while (st.count && guard++ < 1500 && !pc) {
                UIView *v = st.lastObject; [st removeLastObject];
                if ([NSStringFromClass(v.class) containsString:@"PasscodeLockView"]) pc = v; else [st addObjectsFromArray:v.subviews];
            }
            self.passcode = pc;
        }
        BOOL shown = NO;
        if (pc && pc.window) { shown = YES; for (UIView *p = pc; p; p = p.superview) if (p.hidden || p.alpha < 0.3) { shown = NO; break; } }
        if (shown != self.onPasscode) {
            self.onPasscode = shown;
            [self ensureIsland:w];
            if (shown && ModeFor(s) != LLUnlocked) { [self iconHidden:YES]; [self.island openAt:[icon convertPoint:CGPointMake(icon.bounds.size.width / 2, icon.bounds.size.height / 2) toView:w]]; }
            else if (!shown && self.island.isOut && ModeFor(s) == LLLocked) { __weak LLWatch *ws = self; [self.island closeAnimated:YES done:^{ [ws iconHidden:NO]; }]; }
        }
    }
    if (self.island.isOut) {
        UIColor *c = nil; @try { c = [icon valueForKey:@"contentColor"]; } @catch (__unused id e) {}
        if ([c isKindOfClass:[UIColor class]]) self.island.tint = c;
    }
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
    [self ensureIsland:w];
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
            if (self.island.isOut && !self.onPasscode) {
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
