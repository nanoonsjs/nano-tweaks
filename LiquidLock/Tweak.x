// LiquidLock 0.2 - made by nano
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

#pragma mark - the island

// One black shape hanging from the notch. Its top sits behind the notch (black on black), so it looks like
// the notch itself drips down and grows.
@interface LLIsland : UIView
- (void)open;
- (void)success:(void (^)(void))done;
- (void)fail;
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done;
@property (nonatomic, readonly) BOOL isOut;
@end
@implementation LLIsland {
    CAShapeLayer *_blob;              // the black island
    CALayer *_glyph;                  // Face ID glyph holder
    CAShapeLayer *_corners, *_face, *_check, *_dots;
    CGRect _notch, _big;
    BOOL _out, _closing;
    CFTimeInterval _openedAt;
}
- (BOOL)isOut { return _out; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    CGFloat W = f.size.width;
    // the notch: about 38% of the screen wide, ~32 pt tall (iPhone X - 14)
    CGFloat nw = round(W * 0.375), nh = 31;
    _notch = CGRectMake((W - nw) / 2, -nh, nw, nh * 2);              // tucked up behind the notch
    CGFloat bw = 124, bh = 132;
    _big = CGRectMake((W - bw) / 2, -40, bw, bh + 40);               // hangs from the notch, 132 pt visible
    _blob = [CAShapeLayer layer]; _blob.fillColor = UIColor.blackColor.CGColor; _blob.frame = self.bounds;
    _blob.path = [self pathFor:_notch r:20].CGPath;
    _blob.opacity = 0;   // only there while it's out (so it never shows beside the real notch)
    [self.layer addSublayer:_blob];
    _glyph = [CALayer layer];
    CGFloat g = 62;
    _glyph.bounds = CGRectMake(0, 0, g, g);
    _glyph.position = CGPointMake(W / 2, CGRectGetMaxY(_big) - (bh - 4) / 2 - 2);
    _glyph.opacity = 0;
    [self.layer addSublayer:_glyph];
    UIColor *white = UIColor.whiteColor;
    // the four corner brackets of the Face ID glyph
    _corners = [CAShapeLayer layer]; _corners.frame = _glyph.bounds; _corners.fillColor = UIColor.clearColor.CGColor;
    _corners.strokeColor = white.CGColor; _corners.lineWidth = 4; _corners.lineCap = kCALineCapRound;
    _corners.path = [self cornersPath:g].CGPath;
    // the face: eyes, nose, smile
    _face = [CAShapeLayer layer]; _face.frame = _glyph.bounds; _face.fillColor = UIColor.clearColor.CGColor;
    _face.strokeColor = white.CGColor; _face.lineWidth = 3.6; _face.lineCap = kCALineCapRound; _face.lineJoin = kCALineJoinRound;
    _face.path = [self facePath:g].CGPath;
    // the dots that orbit while it scans
    _dots = [CAShapeLayer layer]; _dots.frame = _glyph.bounds; _dots.fillColor = UIColor.clearColor.CGColor;
    _dots.strokeColor = [white colorWithAlphaComponent:0.9].CGColor; _dots.lineWidth = 3; _dots.lineCap = kCALineCapRound;
    _dots.lineDashPattern = @[@0.1, @9];
    _dots.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(_glyph.bounds, -10, -10)].CGPath;
    _dots.opacity = 0;
    // the check
    _check = [CAShapeLayer layer]; _check.frame = _glyph.bounds; _check.fillColor = UIColor.clearColor.CGColor;
    _check.strokeColor = white.CGColor; _check.lineWidth = 5; _check.lineCap = kCALineCapRound; _check.lineJoin = kCALineJoinRound;
    UIBezierPath *ck = [UIBezierPath bezierPath];
    [ck moveToPoint:CGPointMake(g * 0.28, g * 0.52)]; [ck addLineToPoint:CGPointMake(g * 0.44, g * 0.68)]; [ck addLineToPoint:CGPointMake(g * 0.74, g * 0.34)];
    _check.path = ck.CGPath; _check.strokeEnd = 0;
    for (CALayer *l in @[_dots, _corners, _face, _check]) [_glyph addSublayer:l];
    return self;
}
// a rounded rectangle; the top corners are hidden behind the notch anyway
- (UIBezierPath *)pathFor:(CGRect)r r:(CGFloat)rad { return [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:MIN(rad, MIN(r.size.width, r.size.height) / 2 - 0.5)]; }
- (UIBezierPath *)cornersPath:(CGFloat)g {
    CGFloat L = g * 0.26, R = g * 0.16;
    UIBezierPath *p = [UIBezierPath bezierPath];
    // top-left, top-right, bottom-right, bottom-left
    [p moveToPoint:CGPointMake(0, L)]; [p addLineToPoint:CGPointMake(0, R)]; [p addQuadCurveToPoint:CGPointMake(R, 0) controlPoint:CGPointZero]; [p addLineToPoint:CGPointMake(L, 0)];
    [p moveToPoint:CGPointMake(g - L, 0)]; [p addLineToPoint:CGPointMake(g - R, 0)]; [p addQuadCurveToPoint:CGPointMake(g, R) controlPoint:CGPointMake(g, 0)]; [p addLineToPoint:CGPointMake(g, L)];
    [p moveToPoint:CGPointMake(g, g - L)]; [p addLineToPoint:CGPointMake(g, g - R)]; [p addQuadCurveToPoint:CGPointMake(g - R, g) controlPoint:CGPointMake(g, g)]; [p addLineToPoint:CGPointMake(g - L, g)];
    [p moveToPoint:CGPointMake(L, g)]; [p addLineToPoint:CGPointMake(R, g)]; [p addQuadCurveToPoint:CGPointMake(0, g - R) controlPoint:CGPointMake(0, g)]; [p addLineToPoint:CGPointMake(0, g - L)];
    return p;
}
- (UIBezierPath *)facePath:(CGFloat)g {
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(g * 0.34, g * 0.34)]; [p addLineToPoint:CGPointMake(g * 0.34, g * 0.42)];
    [p moveToPoint:CGPointMake(g * 0.66, g * 0.34)]; [p addLineToPoint:CGPointMake(g * 0.66, g * 0.42)];
    [p moveToPoint:CGPointMake(g * 0.5, g * 0.34)]; [p addLineToPoint:CGPointMake(g * 0.5, g * 0.56)]; [p addLineToPoint:CGPointMake(g * 0.44, g * 0.56)];
    [p moveToPoint:CGPointMake(g * 0.34, g * 0.68)]; [p addQuadCurveToPoint:CGPointMake(g * 0.66, g * 0.68) controlPoint:CGPointMake(g * 0.5, g * 0.8)];
    return p;
}
- (void)morphBlobTo:(CGRect)r radius:(CGFloat)rad stiff:(CGFloat)k damp:(CGFloat)d {
    CAShapeLayer *pl = _blob.presentationLayer;
    id from = (id)pl.path ?: (id)_blob.path;
    UIBezierPath *to = [self pathFor:r r:rad];
    [_blob removeAnimationForKey:@"path"];
    CASpringAnimation *a = Spring(@"path", from, (id)to.CGPath, k, d);
    [_blob addAnimation:a forKey:@"path"];
    _blob.path = to.CGPath;
}
// out of the notch: it drips down first (narrow), then spreads into the square with a wobble
- (void)open {
    if (_out && !_closing) return;
    _out = YES; _closing = NO; _openedAt = CACurrentMediaTime();
    _blob.opacity = 1;
    [_glyph removeAllAnimations]; [_check removeAllAnimations]; _check.strokeEnd = 0;
    CGRect drip = CGRectMake(CGRectGetMidX(_big) - 30, _big.origin.y, 60, _big.size.height * 0.62);
    [self morphBlobTo:drip radius:30 stiff:520 damp:26];
    __weak LLIsland *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.09 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LLIsland *s = ws; if (!s || !s->_out || s->_closing) return;
        [s morphBlobTo:s->_big radius:44 stiff:300 damp:17];
    });
    // the glyph fades and zooms in, the face scans
    _glyph.opacity = 1; _corners.opacity = 1; _face.opacity = 1;
    CASpringAnimation *gz = Spring(@"transform.scale", @0.4, @1, 280, 16); gz.beginTime = CACurrentMediaTime() + 0.08; gz.fillMode = kCAFillModeBackwards;
    CABasicAnimation *gf = [CABasicAnimation animationWithKeyPath:@"opacity"]; gf.fromValue = @0; gf.toValue = @1; gf.duration = 0.2; gf.beginTime = CACurrentMediaTime() + 0.08; gf.fillMode = kCAFillModeBackwards;
    [_glyph addAnimation:gz forKey:@"in"]; [_glyph addAnimation:gf forKey:@"fade"];
    [self scanMotion];
    Haptic(0);
}
- (void)scanMotion {
    // the brackets breathe, the face blinks softly, the dots orbit
    CABasicAnimation *br = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    br.fromValue = @1; br.toValue = @1.08; br.duration = 0.55; br.autoreverses = YES; br.repeatCount = HUGE_VALF;
    br.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_corners addAnimation:br forKey:@"breathe"];
    CAKeyframeAnimation *look = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    look.values = @[@0, @2.5, @0, @-2.5, @0]; look.duration = 1.4; look.repeatCount = HUGE_VALF;
    [_face addAnimation:look forKey:@"look"];
    _dots.opacity = 1;
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"]; spin.fromValue = @0; spin.toValue = @(M_PI * 2); spin.duration = 1.2; spin.repeatCount = HUGE_VALF;
    CABasicAnimation *head = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; head.fromValue = @0.15; head.toValue = @0.85; head.duration = 0.9; head.autoreverses = YES; head.repeatCount = HUGE_VALF;
    [_dots addAnimation:spin forKey:@"spin"]; [_dots addAnimation:head forKey:@"head"];
}
- (void)stopScan {
    [_corners removeAnimationForKey:@"breathe"]; [_face removeAnimationForKey:@"look"];
    [_dots removeAllAnimations]; _dots.opacity = 0;
}
// recognized: the face melts away, the brackets pull into a ring, the check draws itself, then back into the notch
- (void)success:(void (^)(void))done {
    if (!_out) [self open];
    __weak LLIsland *ws = self;
    // let it be seen for a moment even if Face ID was instant
    CGFloat wait = MAX(0, 0.28 - (CACurrentMediaTime() - _openedAt));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LLIsland *s = ws; if (!s || !s->_out || s->_closing) { if (done) done(); return; }
        [s stopScan];
        CABasicAnimation *ff = [CABasicAnimation animationWithKeyPath:@"opacity"]; ff.fromValue = @1; ff.toValue = @0; ff.duration = 0.14;
        [s->_face addAnimation:ff forKey:@"out"]; s->_face.opacity = 0;
        CASpringAnimation *pull = Spring(@"transform.scale", @1.12, @0.0, 240, 22); pull.duration = 0.3;
        CABasicAnimation *cf = [CABasicAnimation animationWithKeyPath:@"opacity"]; cf.fromValue = @1; cf.toValue = @0; cf.duration = 0.2;
        [s->_corners addAnimation:pull forKey:@"pull"]; [s->_corners addAnimation:cf forKey:@"out"]; s->_corners.opacity = 0;
        CABasicAnimation *draw = [CABasicAnimation animationWithKeyPath:@"strokeEnd"]; draw.fromValue = @0; draw.toValue = @1; draw.duration = 0.32; draw.beginTime = CACurrentMediaTime() + 0.08; draw.fillMode = kCAFillModeBackwards;
        draw.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.3 :0 :0.2 :1];
        [s->_check addAnimation:draw forKey:@"draw"]; s->_check.strokeEnd = 1;
        CASpringAnimation *pop = Spring(@"transform.scale", @0.7, @1, 360, 13); pop.beginTime = CACurrentMediaTime() + 0.08; pop.fillMode = kCAFillModeBackwards;
        [s->_check addAnimation:pop forKey:@"pop"];
        // the island gives a happy little bounce
        CASpringAnimation *sq = Spring(@"transform.scale", @1.06, @1, 300, 12);
        [s->_blob addAnimation:sq forKey:@"happy"];
        Haptic(3);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.62 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [ws closeAnimated:YES done:done]; });
    });
}
// no match: shakes like jelly
- (void)fail {
    if (!_out) [self open];
    CAKeyframeAnimation *tx = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    tx.values = @[@0, @-16, @14, @-10, @6, @-3, @0];
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"]; sx.values = @[@1, @1.07, @0.95, @1.04, @0.98, @1.01, @1];
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"]; sy.values = @[@1, @0.95, @1.05, @0.97, @1.02, @0.99, @1];
    CAAnimationGroup *g = [CAAnimationGroup animation]; g.animations = @[tx, sx, sy]; g.duration = 0.62;
    g.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.layer addAnimation:g forKey:@"jelly"];
    Haptic(2);
}
// back up into the notch: it narrows into a drip and is pulled up, with a squish at the end
- (void)closeAnimated:(BOOL)a done:(void (^)(void))done {
    if (!_out) { if (done) done(); return; }
    _closing = YES;
    [self stopScan];
    if (!a) { [_blob removeAllAnimations]; _blob.path = [self pathFor:_notch r:20].CGPath; _blob.opacity = 0; _glyph.opacity = 0; _out = NO; _closing = NO; if (done) done(); return; }
    CABasicAnimation *gf = [CABasicAnimation animationWithKeyPath:@"opacity"]; gf.fromValue = @1; gf.toValue = @0; gf.duration = 0.16;
    CABasicAnimation *gs = [CABasicAnimation animationWithKeyPath:@"transform.scale"]; gs.fromValue = @1; gs.toValue = @0.5; gs.duration = 0.2;
    [_glyph addAnimation:gf forKey:@"fade"]; [_glyph addAnimation:gs forKey:@"shrink"]; _glyph.opacity = 0;
    CGRect drip = CGRectMake(CGRectGetMidX(_big) - 34, _big.origin.y, 68, _big.size.height * 0.55);
    [self morphBlobTo:drip radius:34 stiff:600 damp:32];
    __weak LLIsland *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LLIsland *s = ws; if (!s || !s->_closing) return;
        [s morphBlobTo:s->_notch radius:20 stiff:420 damp:24];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.34 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LLIsland *s2 = ws; if (s2 && s2->_closing) { s2->_out = NO; s2->_closing = NO; s2->_blob.opacity = 0; }
            if (done) done();
        });
    });
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
            [self.island open];
            break;
        case LLUnlocked:
            if (ModeFor(was) == LLScanning || self.island.isOut) {
                [self iconHidden:YES];
                [self.island success:^{ [ws iconHidden:NO]; }];
            }
            break;
        case LLFailed:
            [self iconHidden:YES];
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
