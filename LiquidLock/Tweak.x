// LiquidLock 0.1 - made by nano
// A liquid Face ID unlock on the Lock Screen. Apple's padlock (SBUIProudLockIconView) is hidden and
// drawn again by us, reacting to Apple's own lock states:
//   1, 20-22, 9, 11-13, 17-19, 23, 0 : locked (coaching states keep the padlock)
//   4, 5, 6, 7, 8, 10, 14-16          : Face ID is looking -> the padlock melts into a glass drop
//   2                                 : unlocked -> the drop pops back into a padlock that bursts open
//   3                                 : no match -> jelly shake
// (states read from SpringBoardUIServices: updateLockForBiometricMatchFailure sets 3,
//  _updateScanningState sets 5)
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <substrate.h>

#define DOM CFSTR("com.nano.liquidlock")
#define LL_TAG 0x4C4C4F4B

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

typedef NS_ENUM(int, LLMode) { LLLocked = 0, LLScanning = 1, LLUnlocked = 2 };
static LLMode ModeFor(long long s) {
    switch (s) {
        case 2: return LLUnlocked;
        case 4: case 5: case 6: case 7: case 8: case 10: case 14: case 15: case 16: return LLScanning;
        default: return LLLocked;
    }
}

@interface SBUIProudLockIconView : UIView
- (long long)state;
@end

#pragma mark - the liquid padlock

@interface LLLock : UIView
@property (nonatomic) LLMode mode;
@property (nonatomic, strong) UIColor *tint;
- (void)goTo:(LLMode)m animated:(BOOL)a;
- (void)shake;
- (void)debugState:(long long)s;
@end

@implementation LLLock {
    CAShapeLayer *_body, *_shackle, *_shine;
    CALayer *_holder;
    UILabel *_dbg;
    CGFloat _S;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.tag = LL_TAG;
    _holder = [CALayer layer];
    [self.layer addSublayer:_holder];
    _shackle = [CAShapeLayer layer]; _shackle.fillColor = UIColor.clearColor.CGColor; _shackle.lineCap = kCALineCapRound;
    _body = [CAShapeLayer layer];
    _shine = [CAShapeLayer layer]; _shine.fillColor = UIColor.clearColor.CGColor; _shine.lineCap = kCALineCapRound; _shine.opacity = 0;
    for (CALayer *l in @[_shackle, _body, _shine]) [_holder addSublayer:l];
    _tint = UIColor.whiteColor;
    _mode = LLLocked;
    return self;
}
// shapes, in a box of side S centered in the view
- (CGRect)box { CGFloat S = _S; return CGRectMake((self.bounds.size.width - S) / 2, (self.bounds.size.height - S) / 2, S, S); }
- (UIBezierPath *)bodyPath:(LLMode)m {
    CGRect b = [self box]; CGFloat S = b.size.width;
    if (m == LLScanning) {
        // a drop of liquid: round, a bit bigger, pointed at the top
        CGFloat r = S * 0.36, cx = CGRectGetMidX(b), cy = CGRectGetMinY(b) + S * 0.6;
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(cx, cy - r * 1.5)];
        [p addCurveToPoint:CGPointMake(cx + r, cy) controlPoint1:CGPointMake(cx + r * 0.2, cy - r * 1.2) controlPoint2:CGPointMake(cx + r, cy - r * 0.55)];
        [p addCurveToPoint:CGPointMake(cx, cy + r) controlPoint1:CGPointMake(cx + r, cy + r * 0.55) controlPoint2:CGPointMake(cx + r * 0.55, cy + r)];
        [p addCurveToPoint:CGPointMake(cx - r, cy) controlPoint1:CGPointMake(cx - r * 0.55, cy + r) controlPoint2:CGPointMake(cx - r, cy + r * 0.55)];
        [p addCurveToPoint:CGPointMake(cx, cy - r * 1.5) controlPoint1:CGPointMake(cx - r, cy - r * 0.55) controlPoint2:CGPointMake(cx - r * 0.2, cy - r * 1.2)];
        [p closePath];
        return p;
    }
    // the padlock's body, drawn with the same 4 curves so the two shapes melt into each other
    CGFloat w = S * 0.66, h = S * 0.5, x0 = CGRectGetMidX(b) - w / 2, y0 = CGRectGetMinY(b) + S * 0.44, rr = S * 0.1, cx = CGRectGetMidX(b);
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(cx, y0)];
    [p addCurveToPoint:CGPointMake(x0 + w, y0 + h / 2) controlPoint1:CGPointMake(x0 + w - rr, y0) controlPoint2:CGPointMake(x0 + w, y0)];
    [p addCurveToPoint:CGPointMake(cx, y0 + h) controlPoint1:CGPointMake(x0 + w, y0 + h) controlPoint2:CGPointMake(x0 + w - rr, y0 + h)];
    [p addCurveToPoint:CGPointMake(x0, y0 + h / 2) controlPoint1:CGPointMake(x0 + rr, y0 + h) controlPoint2:CGPointMake(x0, y0 + h)];
    [p addCurveToPoint:CGPointMake(cx, y0) controlPoint1:CGPointMake(x0, y0) controlPoint2:CGPointMake(x0 + rr, y0)];
    [p closePath];
    return p;
}
- (UIBezierPath *)shacklePath:(BOOL)open {
    CGRect b = [self box]; CGFloat S = b.size.width;
    CGFloat w = S * 0.42, top = CGRectGetMinY(b) + S * 0.08, base = CGRectGetMinY(b) + S * 0.46, cx = CGRectGetMidX(b);
    CGFloat lift = open ? S * 0.16 : 0;
    UIBezierPath *p = [UIBezierPath bezierPath];
    // right leg stays in the body, the left leg comes out when it opens
    [p moveToPoint:CGPointMake(cx + w / 2, base)];
    [p addLineToPoint:CGPointMake(cx + w / 2, top + w / 2 - lift)];
    [p addArcWithCenter:CGPointMake(cx, top + w / 2 - lift) radius:w / 2 startAngle:0 endAngle:M_PI clockwise:NO];
    [p addLineToPoint:CGPointMake(cx - w / 2, open ? top + w / 2 - lift + S * 0.08 : base)];
    return p;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat S = MIN(self.bounds.size.width, self.bounds.size.height);
    if (S < 4) return;
    BOOL changed = fabs(S - _S) > 0.5;
    _S = S;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _holder.frame = self.bounds;
    for (CALayer *l in @[_shackle, _body, _shine]) l.frame = self.bounds;
    _shackle.lineWidth = MAX(1.5, S * 0.1);
    _shine.lineWidth = MAX(1, S * 0.05);
    [self paint];
    if (changed) {
        _body.path = [self bodyPath:_mode].CGPath;
        _shackle.path = [self shacklePath:_mode == LLUnlocked].CGPath;
        _shackle.strokeEnd = _mode == LLScanning ? 0 : 1;
        [self shinePath];
    }
    [CATransaction commit];
    _dbg.frame = CGRectMake(-60, self.bounds.size.height + 2, self.bounds.size.width + 120, 14);
}
- (void)paint {
    _body.fillColor = _tint.CGColor; _shackle.strokeColor = _tint.CGColor;
    _shine.strokeColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
}
- (void)setTint:(UIColor *)t { if (!t || [t isEqual:_tint]) return; _tint = t; [CATransaction begin]; [CATransaction setDisableActions:YES]; [self paint]; [CATransaction commit]; }
- (void)shinePath {
    CGRect b = [self box]; CGFloat S = b.size.width, r = S * 0.24;
    _shine.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(b), CGRectGetMinY(b) + S * 0.6) radius:r startAngle:M_PI * 1.05 endAngle:M_PI * 1.4 clockwise:YES].CGPath;
}
static CASpringAnimation *LLSpring(NSString *kp, id from, id to, CGFloat stiff, CGFloat damp) {
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:kp];
    a.fromValue = from; a.toValue = to; a.mass = 1; a.stiffness = stiff; a.damping = damp; a.duration = a.settlingDuration;
    return a;
}
- (void)haptic:(int)kind {
    if (!gHaptics) return;
    if (kind == 2) [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];
    else [[[UIImpactFeedbackGenerator alloc] initWithStyle:kind == 1 ? UIImpactFeedbackStyleMedium : UIImpactFeedbackStyleSoft] impactOccurred];
}
- (void)goTo:(LLMode)m animated:(BOOL)animated {
    LLMode was = _mode;
    if (m == was && animated) return;
    _mode = m;
    if (_S < 4) return;
    UIBezierPath *bodyTo = [self bodyPath:m];
    UIBezierPath *shTo = [self shacklePath:m == LLUnlocked];
    if (!animated) {
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        _body.path = bodyTo.CGPath; _shackle.path = shTo.CGPath; _shackle.strokeEnd = m == LLScanning ? 0 : 1;
        [_holder removeAllAnimations]; [_shine removeAllAnimations]; _shine.opacity = 0;
        [CATransaction commit];
        return;
    }
    CALayer *pb = _body.presentationLayer;
    id bodyFrom = (id)((CAShapeLayer *)pb).path ?: (id)_body.path;
    [_body removeAnimationForKey:@"path"];
    if (m == LLScanning) {
        // melts: the shackle sinks into the body and the body swells into a drop, which then breathes and swirls
        CABasicAnimation *sh = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; sh.fromValue = @(_shackle.strokeEnd); sh.toValue = @0; sh.duration = 0.22;
        sh.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [_shackle addAnimation:sh forKey:@"end"]; _shackle.strokeEnd = 0;
        CASpringAnimation *bp = LLSpring(@"path", bodyFrom, (id)bodyTo.CGPath, 260, 13);
        [_body addAnimation:bp forKey:@"path"]; _body.path = bodyTo.CGPath;
        CABasicAnimation *br = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        br.fromValue = @1; br.toValue = @1.07; br.duration = 0.75; br.autoreverses = YES; br.repeatCount = HUGE_VALF; br.beginTime = CACurrentMediaTime() + 0.3;
        br.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_holder addAnimation:br forKey:@"breathe"];
        // wobble: the drop leans left and right a little, like liquid
        CAKeyframeAnimation *wob = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
        wob.values = @[@0, @0.06, @-0.05, @0.03, @0]; wob.duration = 1.6; wob.repeatCount = HUGE_VALF;
        [_body addAnimation:wob forKey:@"wobble"];
        // the light swirls around the drop
        [self shinePath];
        _shine.opacity = 1;
        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"]; fade.fromValue = @0; fade.toValue = @1; fade.duration = 0.25;
        [_shine addAnimation:fade forKey:@"fade"];
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @0; spin.toValue = @(M_PI * 2); spin.duration = 1.1; spin.repeatCount = HUGE_VALF;
        CGRect b = [self box];
        _shine.anchorPoint = CGPointMake(CGRectGetMidX(b) / MAX(1, self.bounds.size.width), (CGRectGetMinY(b) + b.size.height * 0.6) / MAX(1, self.bounds.size.height));
        _shine.frame = self.bounds;
        [_shine addAnimation:spin forKey:@"spin"];
        return;
    }
    // leaving the drop (or relocking): stop the liquid motion
    [_holder removeAnimationForKey:@"breathe"]; [_body removeAnimationForKey:@"wobble"];
    if (_shine.opacity > 0) {
        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"]; fade.fromValue = @1; fade.toValue = @0; fade.duration = 0.15;
        [_shine addAnimation:fade forKey:@"fade"]; _shine.opacity = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self->_shine removeAnimationForKey:@"spin"]; });
    }
    // the drop pops back into a padlock (a squishy spring), the shackle grows back out
    CASpringAnimation *bp = LLSpring(@"path", bodyFrom, (id)bodyTo.CGPath, 320, 14);
    [_body addAnimation:bp forKey:@"path"]; _body.path = bodyTo.CGPath;
    if (_shackle.strokeEnd < 1) {
        CABasicAnimation *sh = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; sh.fromValue = @0; sh.toValue = @1; sh.duration = 0.28; sh.beginTime = CACurrentMediaTime() + 0.06;
        sh.fillMode = kCAFillModeBackwards; sh.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [_shackle addAnimation:sh forKey:@"end"]; _shackle.strokeEnd = 1;
    }
    CALayer *ps = _shackle.presentationLayer;
    id shFrom = (id)((CAShapeLayer *)ps).path ?: (id)_shackle.path;
    CASpringAnimation *sp = LLSpring(@"path", shFrom, (id)shTo.CGPath, m == LLUnlocked ? 220 : 300, m == LLUnlocked ? 9 : 16);
    if (m == LLUnlocked) { sp.beginTime = CACurrentMediaTime() + 0.16; sp.fillMode = kCAFillModeBackwards; }
    [_shackle addAnimation:sp forKey:@"path"]; _shackle.path = shTo.CGPath;
    if (m == LLUnlocked) {
        // the whole lock squashes and springs up, and the liquid splashes out
        CASpringAnimation *sy = LLSpring(@"transform.scale.y", @0.78, @1, 300, 10); sy.initialVelocity = 3;
        CASpringAnimation *sx = LLSpring(@"transform.scale.x", @1.18, @1, 300, 10);
        [_holder addAnimation:sy forKey:@"sy"]; [_holder addAnimation:sx forKey:@"sx"];
        [self splash];
        [self haptic:0];
    }
}
- (void)splash {
    CGRect b = [self box]; CGFloat S = b.size.width;
    CGPoint c = CGPointMake(CGRectGetMidX(b), CGRectGetMinY(b) + S * 0.66);
    // a ring of liquid
    CAShapeLayer *ring = [CAShapeLayer layer];
    ring.frame = self.bounds; ring.fillColor = UIColor.clearColor.CGColor; ring.strokeColor = [_tint colorWithAlphaComponent:0.8].CGColor; ring.lineWidth = S * 0.08;
    ring.path = [UIBezierPath bezierPathWithArcCenter:c radius:S * 0.3 startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    [self.layer addSublayer:ring];
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"path"];
    grow.toValue = (id)[UIBezierPath bezierPathWithArcCenter:c radius:S * 1.05 startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
    CABasicAnimation *thin = [CABasicAnimation animationWithKeyPath:@"lineWidth"]; thin.toValue = @0.5;
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"]; fade.toValue = @0;
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[grow, thin, fade]; g.duration = 0.55;
    g.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.15 :0.8 :0.3 :1];
    g.fillMode = kCAFillModeForwards; g.removedOnCompletion = NO;
    [ring addAnimation:g forKey:@"splash"];
    // little droplets fly out
    NSMutableArray *drops = [NSMutableArray arrayWithObject:ring];
    for (int i = 0; i < 6; i++) {
        double ang = -M_PI / 2 + (i - 2.5) * 0.55 + ((i * 37) % 10) / 40.0;
        CGFloat d = S * (0.16 + (i % 3) * 0.03);
        CALayer *dl = [CALayer layer];
        dl.bounds = CGRectMake(0, 0, d, d); dl.cornerRadius = d / 2; dl.backgroundColor = _tint.CGColor; dl.position = c;
        [self.layer addSublayer:dl];
        CGFloat dist = S * (0.85 + (i % 2) * 0.3);
        CAKeyframeAnimation *mv = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        UIBezierPath *path = [UIBezierPath bezierPath]; [path moveToPoint:c];
        CGPoint end = CGPointMake(c.x + cos(ang) * dist, c.y + sin(ang) * dist + S * 0.25);
        [path addQuadCurveToPoint:end controlPoint:CGPointMake(c.x + cos(ang) * dist * 0.7, c.y + sin(ang) * dist * 0.9)];
        mv.path = path.CGPath;
        CABasicAnimation *sc = [CABasicAnimation animationWithKeyPath:@"transform.scale"]; sc.fromValue = @1; sc.toValue = @0.2;
        CABasicAnimation *op = [CABasicAnimation animationWithKeyPath:@"opacity"]; op.fromValue = @1; op.toValue = @0;
        CAAnimationGroup *gg = [CAAnimationGroup animation]; gg.animations = @[mv, sc, op]; gg.duration = 0.6;
        gg.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        gg.fillMode = kCAFillModeForwards; gg.removedOnCompletion = NO;
        [dl addAnimation:gg forKey:@"fly"];
        [drops addObject:dl];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ for (CALayer *l in drops) [l removeFromSuperlayer]; });
}
// no match: the padlock comes back and wobbles like jelly
- (void)shake {
    if (_mode != LLLocked) [self goTo:LLLocked animated:YES];
    CAKeyframeAnimation *tx = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    CGFloat d = MAX(6, _S * 0.28);
    tx.values = @[@0, @(-d), @(d * 0.85), @(-d * 0.6), @(d * 0.35), @(-d * 0.15), @0];
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    sx.values = @[@1, @1.14, @0.9, @1.08, @0.96, @1.02, @1];
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    sy.values = @[@1, @0.88, @1.1, @0.94, @1.04, @0.99, @1];
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[tx, sx, sy]; g.duration = 0.6;
    g.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_holder addAnimation:g forKey:@"jelly"];
    [self haptic:2];
}
- (void)debugState:(long long)s {
    if (!gDebug) { [_dbg removeFromSuperview]; _dbg = nil; return; }
    if (!_dbg) {
        _dbg = [UILabel new]; _dbg.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightSemibold];
        _dbg.textColor = UIColor.whiteColor; _dbg.textAlignment = NSTextAlignmentCenter; [self addSubview:_dbg]; self.clipsToBounds = NO;
    }
    NSString *old = _dbg.text.length ? [_dbg.text componentsSeparatedByString:@" "].lastObject : @"";
    _dbg.text = [NSString stringWithFormat:@"%@ %lld", old, s];
    [self setNeedsLayout];
}
@end

#pragma mark - hooks

static const void *kEmptyMask = &kEmptyMask;
// Apple's own drawing (the padlock, the Face ID glyph, the "camera covered" glyph) is kept but made invisible
static void HideApple(UIView *icon) {
    for (UIView *v in icon.subviews) {
        if (v.tag == LL_TAG) continue;
        BOOL hide = gEnabled;
        if (hide && !objc_getAssociatedObject(v, kEmptyMask)) { v.layer.mask = [CALayer layer]; objc_setAssociatedObject(v, kEmptyMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        else if (!hide && objc_getAssociatedObject(v, kEmptyMask)) { v.layer.mask = nil; objc_setAssociatedObject(v, kEmptyMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    }
    // the padlock itself can be a layer, not a view
    for (CALayer *l in icon.layer.sublayers) {
        if (l.delegate && [(id)l.delegate isKindOfClass:[UIView class]]) continue;
        if (gEnabled && l.opacity > 0) { [l setValue:@YES forKey:@"ll.hid"]; l.opacity = 0; }
        else if (!gEnabled && [[l valueForKey:@"ll.hid"] boolValue]) { [l setValue:nil forKey:@"ll.hid"]; l.opacity = 1; }
    }
}
static LLLock *LockIn(UIView *icon, BOOL make) {
    LLLock *ll = (LLLock *)[icon viewWithTag:LL_TAG];
    if (![ll isKindOfClass:[LLLock class]]) ll = nil;
    if (!ll && make) {
        ll = [[LLLock alloc] initWithFrame:icon.bounds];
        ll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [icon addSubview:ll];
        long long s = 1; @try { s = [(SBUIProudLockIconView *)icon state]; } @catch (__unused id e) {}
        [ll goTo:ModeFor(s) animated:NO];
    }
    return ll;
}
static void Tint(UIView *icon, LLLock *ll) {
    UIColor *c = nil;
    @try { c = [icon valueForKey:@"contentColor"]; } @catch (__unused id e) {}
    ll.tint = [c isKindOfClass:[UIColor class]] ? c : UIColor.whiteColor;
}

%hook SBUIProudLockIconView
- (void)layoutSubviews {
    %orig;
    if (!gEnabled) { [LockIn(self, NO) removeFromSuperview]; HideApple(self); return; }
    LLLock *ll = LockIn(self, YES);
    ll.frame = self.bounds;
    [self bringSubviewToFront:ll];
    Tint(self, ll);
    HideApple(self);
}
- (void)setState:(long long)s animated:(BOOL)a updateText:(BOOL)t options:(long long)o completion:(id)c {
    long long was = 1; @try { was = [self state]; } @catch (__unused id e) {}
    %orig;
    if (!gEnabled) return;
    LLLock *ll = LockIn(self, YES);
    [ll debugState:s];
    HideApple(self);
    Tint(self, ll);
    if (s == 3 && was != 3) { [ll shake]; return; }
    [ll goTo:ModeFor(s) animated:a && self.window != nil];
}
%end

static void InitHooks(void) { static BOOL done; if (done) return; done = YES; %init; }
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) { LoadPrefs(); }

#include "../shared/NanoSettings.h"

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if ([bid isEqualToString:@"com.apple.Preferences"]) { StartNanoSettings(); return; }
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.liquidlock/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    // SpringBoardUIServices is loaded by SpringBoard: hook once the class is there
    if (objc_getClass("SBUIProudLockIconView")) { InitHooks(); return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        __block int tries = 0;
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *tm) {
            if (objc_getClass("SBUIProudLockIconView")) { InitHooks(); [tm invalidate]; }
            else if (++tries > 120) [tm invalidate];
        }];
    });
}
