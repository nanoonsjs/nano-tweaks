// ===================== MusicPill settings page (runs in the Settings app) =====================
// A header card at the top, and under the Dynamic Pill switch (when it's on) a little phone that
// shows what to do: swipe up on the pill, it grows into Insights, the moon turns it into the
// Sleep Timer, tap outside and it shrinks back. Like Control26's Control Center card.
// The cells are made at runtime as subclasses of PSTableCell, so Music never needs Preferences.framework.

#define MP_VERSION @"1.7.13"

@interface NSObject (MPPS)
- (id)propertyForKey:(NSString *)k;
- (NSString *)identifier;
- (id)readPreferenceValue:(id)spec;
- (void)insertSpecifier:(id)s afterSpecifier:(id)a animated:(BOOL)an;
- (void)removeSpecifier:(id)s animated:(BOOL)an;
- (id)specifierForID:(NSString *)i;
@end

static void MPSP(id spec, id v, NSString *k) { ((void (*)(id, SEL, id, id))objc_msgSend)(spec, @selector(setProperty:forKey:), v, k); }

#pragma mark - the little phone

@interface MPDemoPhone : UIView
@end
@implementation MPDemoPhone {
    CAShapeLayer *_goo; CADisplayLink *_dl; void (^_tick)(CGFloat); CFTimeInterval _t0, _dur; void (^_done)(void);
    UIView *_screen, *_pill, *_island, *_insights, *_sleep, *_dot, *_splash, *_splashC, *_pillArt;
    CGRect _splashR;
    NSMutableArray<UIView *> *_bars, *_chips;
    NSUInteger _gen;
    CGRect _pillR, _bigR, _sleepR;
}
static UIView *MPBox(UIView *in, CGRect r, CGFloat rad, UIColor *c) {
    UIView *v = [[UIView alloc] initWithFrame:r];
    v.backgroundColor = c; v.layer.cornerRadius = rad; v.layer.cornerCurve = kCACornerCurveContinuous;
    [in addSubview:v];
    return v;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.layer.cornerRadius = 15; self.layer.cornerCurve = kCACornerCurveContinuous; self.layer.borderWidth = 3;
    _screen = [UIView new];
    _screen.layer.cornerRadius = 11; _screen.layer.cornerCurve = kCACornerCurveContinuous; _screen.clipsToBounds = YES;
    _screen.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1];
    [self addSubview:_screen];
    _bars = [NSMutableArray array]; _chips = [NSMutableArray array];
    [self updateColors];
    return self;
}
- (void)updateColors {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    self.layer.borderColor = (dark ? [UIColor colorWithWhite:0.42 alpha:1] : [UIColor colorWithWhite:0.80 alpha:1]).CGColor;
}
- (void)traitCollectionDidChange:(UITraitCollection *)p { [super traitCollectionDidChange:p]; [self updateColors]; }
- (void)build {
    for (UIView *v in [_screen.subviews copy]) [v removeFromSuperview];
    [_bars removeAllObjects]; [_chips removeAllObjects];
    CGSize S = _screen.bounds.size;
    UIColor *g = [UIColor colorWithWhite:1 alpha:0.14], *w = [UIColor colorWithWhite:1 alpha:0.9];
    UIColor *pink = [UIColor colorWithRed:0.98 green:0.24 blue:0.37 alpha:1], *violet = [UIColor colorWithRed:0.55 green:0.42 blue:1 alpha:1];
    // Music behind: a title and a grid of covers
    MPBox(_screen, CGRectMake(6, 13, 26, 4), 2, w);
    for (int i = 0; i < 6; i++) MPBox(_screen, CGRectMake(6 + (i % 2) * ((S.width - 15) / 2 + 3), 22 + (i / 2) * ((S.width - 15) / 2 + 9), (S.width - 15) / 2, (S.width - 15) / 2), 4, i == 0 ? [pink colorWithAlphaComponent:0.7] : g);
    UIView *notch = MPBox(_screen, CGRectMake(S.width / 2 - 12, 0, 24, 6), 3, UIColor.blackColor); (void)notch;
    // tab bar + the pill above it
    UIView *tab = MPBox(_screen, CGRectMake(0, S.height - 15, S.width, 15), 0, [UIColor colorWithWhite:0.14 alpha:0.96]);
    for (int i = 0; i < 4; i++) MPBox(tab, CGRectMake(S.width * (0.14 + i * 0.24) - 2.5, 4, 5, 5), 2.5, i == 0 ? pink : [UIColor colorWithWhite:1 alpha:0.4]);
    _pillR = CGRectMake(4, S.height - 29, S.width - 8, 12);
    _goo = [CAShapeLayer layer]; _goo.fillColor = [UIColor colorWithWhite:0.24 alpha:1].CGColor;
    _goo.strokeColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor; _goo.lineWidth = 0.5;
    _goo.frame = _screen.bounds;
    [_screen.layer addSublayer:_goo];
    _pill = MPBox(_screen, _pillR, 6, [UIColor colorWithWhite:0.24 alpha:1]);
    _pill.layer.borderWidth = 0.5; _pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    _pillArt = MPBox(_pill, CGRectMake(2.5, 2.5, 7, 7), 1.5, pink);
    MPBox(_pill, CGRectMake(13, 4.5, 20, 3), 1.5, w);
    MPBox(_pill, CGRectMake(_pillR.size.width - 9, 3.5, 5, 5), 1, [UIColor colorWithWhite:1 alpha:0.75]);
    // the island (hidden until it grows out of the pill)
    _bigR = CGRectMake(3, 9, S.width - 6, CGRectGetMaxY(_pillR) - 9 + 1);
    _sleepR = CGRectMake(3, CGRectGetMaxY(_bigR) - 46, S.width - 6, 46);
    _island = MPBox(_screen, _pillR, 6, [UIColor colorWithWhite:0.03 alpha:1]);
    _island.clipsToBounds = YES; _island.alpha = 0;
    _island.layer.borderWidth = 0.6; _island.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    CGFloat IW = _bigR.size.width;
    // Insights: title, the moon and close, a pink card with day bars, two chips, a list
    _insights = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IW, _bigR.size.height)];
    MPBox(_insights, CGRectMake(5, 6, 22, 4), 2, w);
    MPBox(_insights, CGRectMake(IW - 19, 5, 6, 6), 3, [UIColor colorWithWhite:1 alpha:0.3]).tag = 5;   // moon
    MPBox(_insights, CGRectMake(IW - 11, 5, 6, 6), 3, [UIColor colorWithWhite:1 alpha:0.3]);
    UIView *hero = MPBox(_insights, CGRectMake(4, 15, IW - 8, 30), 5, [pink colorWithAlphaComponent:0.55]);
    CAGradientLayer *gr = [CAGradientLayer layer]; gr.frame = hero.bounds; gr.cornerRadius = 5;
    gr.colors = @[(id)[pink colorWithAlphaComponent:0.9].CGColor, (id)[violet colorWithAlphaComponent:0.8].CGColor];
    gr.startPoint = CGPointMake(0, 0); gr.endPoint = CGPointMake(1, 1);
    [hero.layer insertSublayer:gr atIndex:0];
    MPBox(hero, CGRectMake(4, 4, 18, 3), 1.5, w);
    CGFloat bw = (IW - 16) / 7;
    for (int i = 0; i < 7; i++) {
        CGFloat h = 6 + (i * 37 % 11) + (i == 4 ? 4 : 0);
        UIView *b = [[UIView alloc] init];
        b.layer.anchorPoint = CGPointMake(0.5, 1);
        b.frame = CGRectMake(4 + i * bw + bw * 0.2, 27 - h, bw * 0.6, h);
        b.backgroundColor = i == 4 ? UIColor.whiteColor : [UIColor colorWithWhite:1 alpha:0.5]; b.layer.cornerRadius = bw * 0.3;
        [hero addSubview:b]; [_bars addObject:b];
    }
    CGFloat hw = (IW - 11) / 2;
    MPBox(_insights, CGRectMake(4, 49, hw, 14), 4, g);
    MPBox(_insights, CGRectMake(7 + hw, 49, hw, 14), 4, g);
    for (int i = 0; i < 3; i++) {
        MPBox(_insights, CGRectMake(4, 68 + i * 10, 7, 7), 1.5, i == 0 ? [pink colorWithAlphaComponent:0.8] : [UIColor colorWithWhite:1 alpha:0.25]);
        MPBox(_insights, CGRectMake(14, 70 + i * 10, IW - 30, 3), 1.5, [UIColor colorWithWhite:1 alpha:0.4]);
    }
    [_island addSubview:_insights];
    // Sleep Timer: moon + title, two rows of chips
    _sleep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IW, _sleepR.size.height)];
    MPBox(_sleep, CGRectMake(5, 5, 6, 6), 3, violet);
    MPBox(_sleep, CGRectMake(14, 6.5, 22, 3.5), 1.75, w);
    CGFloat cw = (IW - 14) / 3;
    for (int i = 0; i < 6; i++) {
        UIView *c = MPBox(_sleep, CGRectMake(4 + (i % 3) * (cw + 3), 16 + (i / 3) * 14, cw, 11), 5.5, [UIColor colorWithWhite:1 alpha:0.14]);
        [_chips addObject:c];
    }
    [_island addSubview:_sleep];
    // the song change splash: grows up out of the pill with the new cover and its name
    _splashR = CGRectMake(3, CGRectGetMaxY(_pillR) - 30, S.width - 6, 30);
    _splash = MPBox(_screen, _pillR, 6, [UIColor colorWithWhite:0.03 alpha:1]);
    _splash.clipsToBounds = YES; _splash.alpha = 0;
    _splash.layer.borderWidth = 0.6; _splash.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    _splashC = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _splashR.size.width, _splashR.size.height)];
    CAGradientLayer *sg = [CAGradientLayer layer]; sg.type = kCAGradientLayerRadial; sg.frame = _splashC.bounds;
    sg.colors = @[(id)[violet colorWithAlphaComponent:0.55].CGColor, (id)[violet colorWithAlphaComponent:0].CGColor];
    sg.startPoint = CGPointMake(0.12, 0.5); sg.endPoint = CGPointMake(0.9, 1.4);
    [_splashC.layer addSublayer:sg];
    UIView *sa = MPBox(_splashC, CGRectMake(4, 4, 22, 22), 4, violet); sa.tag = 11;
    MPBox(_splashC, CGRectMake(31, 6, 12, 2.5), 1.25, pink).tag = 12;
    MPBox(_splashC, CGRectMake(31, 12, _splashR.size.width - 38, 4), 2, w).tag = 13;
    MPBox(_splashC, CGRectMake(31, 19, (_splashR.size.width - 38) * 0.6, 3), 1.5, [UIColor colorWithWhite:1 alpha:0.5]).tag = 14;
    [_splash addSubview:_splashC];
    // the finger
    _dot = MPBox(_screen, CGRectMake(0, 0, 10, 10), 5, [UIColor colorWithWhite:1 alpha:0.9]);
    _dot.layer.shadowColor = UIColor.blackColor.CGColor; _dot.layer.shadowOpacity = 0.5; _dot.layer.shadowRadius = 2; _dot.layer.shadowOffset = CGSizeZero;
    _dot.alpha = 0;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect sr = CGRectInset(self.bounds, 5, 5);
    if (!CGRectEqualToRect(_screen.frame, sr)) { _screen.frame = sr; [self build]; [self restart]; }
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self restart]; }
- (void)restart { _gen++; if (self.window && _pill) [self loop:_gen]; }
- (void)after:(CGFloat)t gen:(NSUInteger)g do:(void (^)(void))b {
    __weak MPDemoPhone *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ MPDemoPhone *s = ws; if (s && s->_gen == g && s.window) b(); });
}
// the pill with a drop of liquid rising out of its top (d = how far up, x = where)
- (UIBezierPath *)gooD:(CGFloat)d x:(CGFloat)x {
    CGRect P = _pillR; CGFloat R = P.size.height / 2, top = CGRectGetMinY(P), bottom = CGRectGetMaxY(P);
    CGFloat r = MIN(R, 2 + d * 0.22), base = r * 1.6 + 3, neck = MAX(0.4, r * 0.7 - d * 0.05), by = top - d;
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(CGRectGetMinX(P) + R, top)];
    if (d > 0.3) {
        [p addLineToPoint:CGPointMake(x - base, top)];
        [p addCurveToPoint:CGPointMake(x - r * 0.95, by + r * 0.3) controlPoint1:CGPointMake(x - base * 0.42, top) controlPoint2:CGPointMake(x - neck, by + r + (top - by - r) * 0.5)];
        [p addArcWithCenter:CGPointMake(x, by) radius:r startAngle:M_PI - 0.31 endAngle:0.31 clockwise:YES];
        [p addCurveToPoint:CGPointMake(x + base, top) controlPoint1:CGPointMake(x + neck, by + r + (top - by - r) * 0.5) controlPoint2:CGPointMake(x + base * 0.42, top)];
    }
    [p addLineToPoint:CGPointMake(CGRectGetMaxX(P) - R, top)];
    [p addArcWithCenter:CGPointMake(CGRectGetMaxX(P) - R, top + R) radius:R startAngle:-M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [p addLineToPoint:CGPointMake(CGRectGetMinX(P) + R, bottom)];
    [p addArcWithCenter:CGPointMake(CGRectGetMinX(P) + R, top + R) radius:R startAngle:M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];
    [p closePath];
    return p;
}
// run a little animation every frame for `dur` seconds (t goes 0 -> 1)
- (void)drive:(CGFloat)dur gen:(NSUInteger)g tick:(void (^)(CGFloat))tick done:(void (^)(void))done {
    [_dl invalidate];
    _tick = tick; _done = done; _dur = dur; _t0 = CACurrentMediaTime();
    _dl = [CADisplayLink displayLinkWithTarget:self selector:@selector(frame:)];
    [_dl addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)frame:(CADisplayLink *)l {
    if (!self.window) { [_dl invalidate]; _dl = nil; return; }
    CGFloat t = MIN(1, (CACurrentMediaTime() - _t0) / MAX(0.01, _dur));
    if (_tick) _tick(t);
    if (t >= 1) { [_dl invalidate]; _dl = nil; void (^d)(void) = _done; _done = nil; _tick = nil; if (d) d(); }
}
- (void)tapAt:(CGPoint)p {
    _dot.center = p; _dot.alpha = 0; _dot.transform = CGAffineTransformMakeScale(1.6, 1.6);
    [UIView animateWithDuration:0.18 animations:^{ self->_dot.alpha = 1; self->_dot.transform = CGAffineTransformMakeScale(0.8, 0.8); } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.25 delay:0.05 options:0 animations:^{ self->_dot.alpha = 0; self->_dot.transform = CGAffineTransformIdentity; } completion:nil];
    }];
}
- (void)loop:(NSUInteger)g {
    // reset
    for (UIView *v in @[_pill, _island, _insights, _sleep, _dot]) [v.layer removeAllAnimations];
    _pill.alpha = 1; _pill.transform = CGAffineTransformIdentity;
    [_dl invalidate]; _dl = nil;
    [CATransaction begin]; [CATransaction setDisableActions:YES]; _goo.path = [self gooD:0 x:CGRectGetMidX(_pillR)].CGPath; _goo.opacity = 1; [CATransaction commit];
    _pill.backgroundColor = UIColor.clearColor; _pill.layer.borderWidth = 0;   // the pill's glass is the goo layer
    _island.alpha = 0; _island.frame = _pillR; _island.layer.cornerRadius = 6; _insights.transform = CGAffineTransformIdentity;
    _insights.alpha = 0; _sleep.alpha = 0;
    _splash.alpha = 0; _splash.frame = _pillR; _splash.layer.cornerRadius = 6; _splashC.alpha = 0;
    _pillArt.backgroundColor = [UIColor colorWithRed:0.98 green:0.24 blue:0.37 alpha:1];
    for (UIView *b in _bars) b.transform = CGAffineTransformMakeScale(1, 0.05);
    for (UIView *c in _chips) { c.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14]; c.alpha = 0; c.transform = CGAffineTransformMakeScale(0.6, 0.6); }
    _dot.alpha = 0;
    CGPoint pc = CGPointMake(CGRectGetMidX(_pillR), CGRectGetMidY(_pillR));
    // 1. finger on the pill, pulls up: a drop of liquid rises out of the pill and follows it, wobbling
    CGFloat gx = CGRectGetMidX(_pillR) + 6;
    [self after:0.5 gen:g do:^{
        self->_dot.center = CGPointMake(gx, CGRectGetMidY(self->_pillR)); self->_dot.transform = CGAffineTransformMakeScale(1.5, 1.5);
        [UIView animateWithDuration:0.2 animations:^{ self->_dot.alpha = 1; self->_dot.transform = CGAffineTransformIdentity; }];
    }];
    [self after:0.8 gen:g do:^{
        CGFloat y0 = CGRectGetMidY(self->_pillR);
        [self drive:0.7 gen:g tick:^(CGFloat t) {
            // eased pull with a springy lag and a little wobble at the end
            CGFloat e = 1 - pow(1 - t, 3);
            CGFloat d = 26 * e + sin(t * M_PI * 3) * 1.6 * (1 - t);
            CGFloat x = gx - 3 * sin(t * M_PI);
            [CATransaction begin]; [CATransaction setDisableActions:YES];
            self->_goo.path = [self gooD:d x:x].CGPath;
            [CATransaction commit];
            self->_dot.center = CGPointMake(x, y0 - 26 * e - 6 * e);
        } done:^{
            // 2. let go: the Dynamic Pill grows out of the drop
            CGFloat r = MIN(self->_pillR.size.height / 2, 2 + 26 * 0.22);
            CGRect c = CGRectMake(gx - r, CGRectGetMinY(self->_pillR) - 26 - r, r * 2, r * 2);
            [UIView animateWithDuration:0.15 animations:^{ self->_dot.alpha = 0; }];
            self->_island.frame = c; self->_island.layer.cornerRadius = r; self->_island.alpha = 1;
            self->_insights.frame = CGRectMake(0, 0, self->_bigR.size.width, self->_bigR.size.height);
            self->_insights.transform = CGAffineTransformMakeScale(0.7, 0.7);
            [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.3 options:0 animations:^{
                self->_island.frame = self->_bigR; self->_island.layer.cornerRadius = 10;
                self->_insights.transform = CGAffineTransformIdentity;
                self->_insights.frame = CGRectMake(0, 0, self->_bigR.size.width, self->_bigR.size.height);
            } completion:nil];
            [UIView animateWithDuration:0.3 delay:0.12 options:0 animations:^{ self->_insights.alpha = 1; } completion:nil];
            // the neck snaps back into the pill
            [self drive:0.25 gen:g tick:^(CGFloat t) {
                CGFloat d = 26 * (1 - t) * (1 - t);
                [CATransaction begin]; [CATransaction setDisableActions:YES]; self->_goo.path = [self gooD:d x:gx].CGPath; [CATransaction commit];
            } done:^{ [UIView animateWithDuration:0.1 animations:^{ self->_pill.alpha = 0; }]; self->_goo.opacity = 0; }];
            for (NSUInteger i = 0; i < self->_bars.count; i++) {
                UIView *b = self->_bars[i];
                [UIView animateWithDuration:0.6 delay:0.3 + i * 0.05 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:0 animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
            }
        }];
    }];
    // 3. tap the moon: it changes shape into the Sleep Timer
    [self after:3.0 gen:g do:^{
        UIView *moon = [self->_insights viewWithTag:5];
        [self tapAt:[moon.superview convertPoint:moon.center toView:self->_screen]];
    }];
    [self after:3.25 gen:g do:^{
        [UIView animateWithDuration:0.15 animations:^{ self->_insights.alpha = 0; }];
        self->_sleep.frame = CGRectMake(0, self->_island.bounds.size.height - self->_sleepR.size.height, self->_sleepR.size.width, self->_sleepR.size.height);
        [UIView animateWithDuration:0.6 delay:0.05 usingSpringWithDamping:0.78 initialSpringVelocity:0 options:0 animations:^{
            self->_island.frame = self->_sleepR; self->_island.layer.cornerRadius = 9;
            self->_sleep.frame = CGRectMake(0, 0, self->_sleepR.size.width, self->_sleepR.size.height);
        } completion:nil];
        [UIView animateWithDuration:0.25 delay:0.2 options:0 animations:^{ self->_sleep.alpha = 1; } completion:nil];
        for (NSUInteger i = 0; i < self->_chips.count; i++) {
            UIView *c = self->_chips[i];
            [UIView animateWithDuration:0.45 delay:0.25 + i * 0.04 usingSpringWithDamping:0.65 initialSpringVelocity:0 options:0 animations:^{ c.alpha = 1; c.transform = CGAffineTransformIdentity; } completion:nil];
        }
    }];
    [self after:4.3 gen:g do:^{
        UIView *c = self->_chips[1];
        [self tapAt:[c.superview convertPoint:c.center toView:self->_screen]];
        [UIView animateWithDuration:0.25 animations:^{ c.backgroundColor = [UIColor colorWithRed:0.55 green:0.45 blue:1 alpha:0.95]; }];
    }];
    // 4. tap outside: it shrinks back into the pill
    [self after:5.2 gen:g do:^{ [self tapAt:CGPointMake(self->_screen.bounds.size.width * 0.5, 32)]; }];
    [self after:5.4 gen:g do:^{
        [UIView animateWithDuration:0.14 animations:^{ self->_sleep.alpha = 0; }];
        [UIView animateWithDuration:0.45 delay:0.04 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
            self->_island.frame = self->_pillR; self->_island.layer.cornerRadius = 6;
        } completion:^(__unused BOOL f) {
            self->_pill.alpha = 1; self->_goo.opacity = 1;
            [UIView animateWithDuration:0.2 animations:^{ self->_island.alpha = 0; }];
            CASpringAnimation *sx = [CASpringAnimation animationWithKeyPath:@"transform.scale.y"]; sx.fromValue = @0.8; sx.toValue = @1;
            sx.damping = 9; sx.stiffness = 300; sx.mass = 1; sx.duration = sx.settlingDuration;
            [self->_pill.layer addAnimation:sx forKey:@"b"];
        }];
    }];
    // 5. a new song starts: the splash grows out of the pill with the new cover, then goes back in
    [self after:6.5 gen:g do:^{
        UIColor *violet = [UIColor colorWithRed:0.55 green:0.42 blue:1 alpha:1];
        [UIView animateWithDuration:0.25 animations:^{ self->_pillArt.backgroundColor = violet; }];
        self->_splash.alpha = 1; self->_splash.frame = self->_pillR;
        self->_splashC.center = CGPointMake(self->_pillR.size.width / 2, self->_pillR.size.height / 2);
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.3 options:0 animations:^{
            self->_splash.frame = self->_splashR; self->_splash.layer.cornerRadius = 9;
            self->_splashC.center = CGPointMake(self->_splashR.size.width / 2, self->_splashR.size.height / 2);
        } completion:nil];
        [UIView animateWithDuration:0.18 delay:0.04 options:0 animations:^{ self->_splashC.alpha = 1; } completion:nil];
        UIView *art = [self->_splashC viewWithTag:11];
        art.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.5 delay:0.1 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:0 animations:^{ art.transform = CGAffineTransformIdentity; } completion:nil];
        for (NSInteger i = 12; i <= 14; i++) {
            UIView *v = [self->_splashC viewWithTag:i]; v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(6, 0);
            [UIView animateWithDuration:0.4 delay:0.16 + (i - 12) * 0.05 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
        }
    }];
    [self after:8.6 gen:g do:^{
        [UIView animateWithDuration:0.12 animations:^{ self->_splashC.alpha = 0; }];
        [UIView animateWithDuration:0.42 delay:0.02 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
            self->_splash.frame = self->_pillR; self->_splash.layer.cornerRadius = 6;
        } completion:^(__unused BOOL f) { [UIView animateWithDuration:0.14 animations:^{ self->_splash.alpha = 0; }]; }];
    }];
    [self after:9.8 gen:g do:^{ [self loop:g]; }];
}
@end

#pragma mark - cells

static const void *kMPCellBuilt = &kMPCellBuilt;
static void MPDemoLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    if (!objc_getAssociatedObject(self, kMPCellBuilt)) {
        objc_setAssociatedObject(self, kMPCellBuilt, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *t = [UILabel new]; t.tag = 0x4D5001; t.numberOfLines = 0;
        t.text = @"Try the Dynamic Pill"; t.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold]; t.textColor = UIColor.labelColor;
        UILabel *b = [UILabel new]; b.tag = 0x4D5002; b.numberOfLines = 0;
        b.text = @"Open Music and pull up on the now playing pill: a drop of liquid follows your finger, and when you let go it grows into Insights. Tap the moon for the Sleep Timer, tap anywhere outside to close. With Song Change Splash on, every new song pops up out of the pill.";
        b.font = [UIFont systemFontOfSize:15]; b.textColor = UIColor.secondaryLabelColor;
        MPDemoPhone *ph = [[MPDemoPhone alloc] initWithFrame:CGRectMake(0, 0, 66, 132)]; ph.tag = 0x4D5003;
        [cv addSubview:t]; [cv addSubview:b]; [cv addSubview:ph];
    }
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height, m = 18;
    UIView *ph = [cv viewWithTag:0x4D5003];
    ph.frame = CGRectMake(W - 66 - 22, (H - 132) / 2, 66, 132);
    CGFloat tw = CGRectGetMinX(ph.frame) - m - 16;
    UILabel *t = (UILabel *)[cv viewWithTag:0x4D5001], *b = (UILabel *)[cv viewWithTag:0x4D5002];
    CGFloat th = ceil([t sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height), bh = ceil([b sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height);
    CGFloat y = MAX(12, (H - th - 6 - bh) / 2);
    t.frame = CGRectMake(m, y, tw, th);
    b.frame = CGRectMake(m, y + th + 6, tw, bh);
}
static UIImage *MPIcon(void) {
    for (NSString *p in @[@"/var/jb/usr/share/MusicPill/icon.png", @"/usr/share/MusicPill/icon.png", @"/var/jb/Library/PreferenceLoader/Preferences/MusicPill@3x.png"]) {
        UIImage *i = [UIImage imageWithContentsOfFile:p];
        if (i) return i;
    }
    return nil;
}
static void MPHeaderLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    if (!objc_getAssociatedObject(self, kMPCellBuilt)) {
        objc_setAssociatedObject(self, kMPCellBuilt, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIImageView *ic = [[UIImageView alloc] initWithImage:MPIcon()]; ic.tag = 0x4D5011;
        ic.layer.cornerRadius = 16; ic.layer.cornerCurve = kCACornerCurveContinuous; ic.clipsToBounds = YES;
        UILabel *t = [UILabel new]; t.tag = 0x4D5012; t.text = @"MusicPill";
        t.font = [UIFont systemFontOfSize:26 weight:UIFontWeightHeavy]; t.textColor = UIColor.labelColor;
        UILabel *s = [UILabel new]; s.tag = 0x4D5013; s.numberOfLines = 2;
        s.text = [NSString stringWithFormat:@"Apple Music, iOS 26 style\nVersion %@ · made by nano", MP_VERSION];
        s.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium]; s.textColor = UIColor.secondaryLabelColor;
        [cv addSubview:ic]; [cv addSubview:t]; [cv addSubview:s];
        // the icon floats a little, like it's on glass
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
        a.fromValue = @(-1.5); a.toValue = @(1.5); a.duration = 1.8; a.autoreverses = YES; a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [ic.layer addAnimation:a forKey:@"float"];
    }
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    CGFloat H = cv.bounds.size.height, W = cv.bounds.size.width;
    UIView *ic = [cv viewWithTag:0x4D5011];
    ic.frame = CGRectMake(18, (H - 68) / 2, 68, 68);
    [cv viewWithTag:0x4D5012].frame = CGRectMake(100, H / 2 - 30, W - 116, 32);
    [cv viewWithTag:0x4D5013].frame = CGRectMake(100, H / 2 + 2, W - 116, 38);
}
static Class MPCellClass(const char *name, IMP layout) {
    Class sup = NSClassFromString(@"PSTableCell");
    if (!sup) return nil;
    Class c = objc_getClass(name);
    if (!c) {
        c = objc_allocateClassPair(sup, name, 0);
        class_addMethod(c, @selector(layoutSubviews), layout, "v@:");
        objc_registerClassPair(c);
    }
    return c;
}

static NSString *MPIdent(id s) { return [s respondsToSelector:@selector(identifier)] ? ((NSString *(*)(id, SEL))objc_msgSend)(s, @selector(identifier)) : nil; }

#pragma mark - Pill Glass preview

// 1.6.2: a little Music screen with the pill on it, using the real glass code. It follows the Pill Glass slider
// live while you drag it, so you see clear vs tinted before you let go.
@interface MPGlassPreview : NSObject
@property (nonatomic, weak) UIView *panel;
@property (nonatomic, weak) UIVisualEffectView *glass;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) CGFloat shown;
@end
@implementation MPGlassPreview
- (UISlider *)findSlider {
    UIView *tv = self.panel; while (tv && ![tv isKindOfClass:[UITableView class]]) tv = tv.superview;
    for (UITableViewCell *cell in ((UITableView *)tv).visibleCells) {
        id spec = nil; @try { spec = [cell valueForKey:@"specifier"]; } @catch (__unused id e) {}
        if (![[spec propertyForKey:@"key"] isEqual:@"pillglass"]) continue;
        NSMutableArray *q = [NSMutableArray arrayWithObject:cell]; int n = 0;
        while (q.count && n++ < 60) { UIView *v = q.firstObject; [q removeObjectAtIndex:0]; if ([v isKindOfClass:[UISlider class]]) return (UISlider *)v; [q addObjectsFromArray:v.subviews]; }
    }
    return nil;
}
- (void)tick {
    UIView *p = self.panel;
    if (!p.window) { [self.link invalidate]; self.link = nil; return; }
    UISlider *sl = [self findSlider];
    CGFloat v = sl ? sl.value : self.shown;
    if (self.shown < 0 || fabs(v - self.shown) > 0.002) {
        self.shown = v;
        GlassLook(self.glass, v, p.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark);
    }
}
@end
static const void *kGlassPrev = &kGlassPrev;
static void MPGlassDemoLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.selectionStyle = UITableViewCellSelectionStyleNone;
    UIView *cv = self.contentView;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height;
    UIView *panel = [cv viewWithTag:0x4D504750];
    BOOL light = self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark;
    if (!panel) {
        panel = [UIView new]; panel.tag = 0x4D504750; panel.clipsToBounds = YES;
        panel.layer.cornerRadius = 20; panel.layer.cornerCurve = kCACornerCurveContinuous;
        [cv addSubview:panel];
        // a bit of Music behind the pill: covers and text, so you can see through the glass
        NSArray *cols = @[@[[UIColor colorWithRed:0.98 green:0.36 blue:0.42 alpha:1], [UIColor colorWithRed:0.99 green:0.66 blue:0.3 alpha:1]],
                          @[[UIColor colorWithRed:0.35 green:0.3 blue:0.95 alpha:1], [UIColor colorWithRed:0.25 green:0.75 blue:1 alpha:1]],
                          @[[UIColor colorWithRed:0.2 green:0.8 blue:0.55 alpha:1], [UIColor colorWithRed:0.95 green:0.9 blue:0.3 alpha:1]],
                          @[[UIColor colorWithRed:0.75 green:0.3 blue:0.9 alpha:1], [UIColor colorWithRed:1 green:0.45 blue:0.75 alpha:1]]];
        for (int i = 0; i < 4; i++) {
            CAGradientLayer *c = [CAGradientLayer layer]; c.name = [NSString stringWithFormat:@"cover%d", i];
            c.colors = @[(id)[cols[i][0] CGColor], (id)[cols[i][1] CGColor]]; c.startPoint = CGPointZero; c.endPoint = CGPointMake(1, 1);
            c.cornerRadius = 10; [panel.layer addSublayer:c];
        }
        UILabel *h = [UILabel new]; h.tag = 11; h.text = @"Top Picks for You"; h.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold]; [panel addSubview:h];
        // the pill
        UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:nil]; g.tag = 12; g.clipsToBounds = YES;
        g.layer.cornerCurve = kCACornerCurveContinuous; g.layer.borderWidth = 0.75;
        [panel addSubview:g];
        UIView *art = [UIView new]; art.tag = 13; art.layer.cornerRadius = 6; art.clipsToBounds = YES;
        CAGradientLayer *ag = [CAGradientLayer layer]; ag.colors = @[(id)[cols[3][0] CGColor], (id)[cols[0][1] CGColor]]; ag.frame = CGRectMake(0, 0, 32, 32); [art.layer addSublayer:ag];
        [g.contentView addSubview:art];
        UILabel *t = [UILabel new]; t.tag = 14; t.text = @"Song Title"; t.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]; [g.contentView addSubview:t];
        UILabel *a = [UILabel new]; a.tag = 15; a.text = @"Artist"; a.font = [UIFont systemFontOfSize:12]; [g.contentView addSubview:a];
        for (int i = 0; i < 2; i++) {
            UIImageView *b = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:i ? @"forward.fill" : @"pause.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold]]];
            b.tag = 16 + i; b.contentMode = UIViewContentModeCenter; [g.contentView addSubview:b];
        }
        MPGlassPreview *pv = [MPGlassPreview new]; pv.panel = panel; pv.glass = g; pv.shown = -1;
        objc_setAssociatedObject(self, kGlassPrev, pv, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    panel.frame = CGRectMake(16, 8, W - 32, H - 16);
    CGFloat pw = panel.bounds.size.width, ph = panel.bounds.size.height;
    panel.backgroundColor = light ? [UIColor colorWithWhite:0.97 alpha:1] : UIColor.blackColor;
    UILabel *h = (UILabel *)[panel viewWithTag:11]; h.frame = CGRectMake(14, 10, pw - 28, 20); h.textColor = UIColor.labelColor;
    CGFloat cs = (pw - 28 - 3 * 10) / 4;
    for (CALayer *l in panel.layer.sublayers) if ([l.name hasPrefix:@"cover"]) {
        int i = [[l.name substringFromIndex:5] intValue];
        l.frame = CGRectMake(14 + i * (cs + 10), 38, cs, MIN(cs, ph - 50));
    }
    UIVisualEffectView *g = (UIVisualEffectView *)[panel viewWithTag:12];
    CGFloat gh = 54;
    g.frame = CGRectMake(10, ph - gh - 10, pw - 20, gh); g.layer.cornerRadius = gh / 2;
    // the same glass as the pill: dark glass, or frosted white in light mode
    NSNumber *was = objc_getAssociatedObject(g, kGlassPrev);
    if (!was || was.boolValue != light) {
        objc_setAssociatedObject(g, kGlassPrev, @(light), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        objc_setAssociatedObject(g, kGlassFx, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        g.effect = [UIBlurEffect effectWithStyle:light ? UIBlurEffectStyleSystemUltraThinMaterialLight : UIBlurEffectStyleSystemThinMaterialDark];
        UIView *frost = [g.contentView viewWithTag:0x4D50574C];
        if (light && !frost) { frost = [[UIView alloc] initWithFrame:g.contentView.bounds]; frost.tag = 0x4D50574C; frost.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; frost.backgroundColor = [UIColor colorWithWhite:1 alpha:0.62]; [g.contentView insertSubview:frost atIndex:0]; }
        if (!light) [frost removeFromSuperview];
        MPGlassPreview *pv = objc_getAssociatedObject(self, kGlassPrev); pv.shown = -1;
    }
    CGFloat a = 36;
    [g.contentView viewWithTag:13].frame = CGRectMake(10, (gh - a) / 2, a, a);
    ((CALayer *)[g.contentView viewWithTag:13].layer.sublayers.firstObject).frame = CGRectMake(0, 0, a, a);
    UILabel *t = (UILabel *)[g.contentView viewWithTag:14], *ar = (UILabel *)[g.contentView viewWithTag:15];
    t.frame = CGRectMake(56, 9, pw - 160, 18); ar.frame = CGRectMake(56, 27, pw - 160, 16);
    t.textColor = UIColor.labelColor; ar.textColor = UIColor.secondaryLabelColor;
    for (int i = 0; i < 2; i++) { UIImageView *b = (UIImageView *)[g.contentView viewWithTag:16 + i]; b.frame = CGRectMake(pw - 20 - (2 - i) * 42 - 6, 0, 42, gh); b.tintColor = UIColor.labelColor; }
    MPGlassPreview *pv = objc_getAssociatedObject(self, kGlassPrev);
    if (panel.window && !pv.link) {
        pv.link = [CADisplayLink displayLinkWithTarget:pv selector:@selector(tick)];
        [pv.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    pv.shown = -1;
}

#pragma mark - the page

static BOOL MPIsOurPage(NSArray *arr) {
    for (id s in arr) if ([s respondsToSelector:@selector(identifier)] && [MPIdent(s) isEqualToString:@"MP_HEADER"]) return YES;
    return NO;
}
static id MPFind(NSArray *arr, NSString *ident) {
    for (id s in arr) if ([s respondsToSelector:@selector(identifier)] && [MPIdent(s) isEqualToString:ident]) return s;
    return nil;
}
static const void *kMPDemoSpec = &kMPDemoSpec;
static BOOL MPDynamicOn(id ctl, id sw) {
    id v = sw ? [ctl readPreferenceValue:sw] : nil;
    if (!v) v = [sw propertyForKey:@"default"];
    return [v boolValue];
}
static NSArray *(*origMPSpecs)(id, SEL);
static NSArray *MPSpecs(id self, SEL _cmd) {
    NSArray *a = origMPSpecs(self, _cmd);
    @try {
        if (![a isKindOfClass:[NSArray class]] || !MPIsOurPage(a)) return a;
        id head = MPFind(a, @"MP_HEADER"), demo = MPFind(a, @"MP_DEMO"), sw = MPFind(a, @"MP_DYNAMIC"), gdemo = MPFind(a, @"MP_GLASSDEMO");
        Class gc = MPCellClass("MPGlassDemoCell", (IMP)MPGlassDemoLayout);
        if (gdemo && gc && [gdemo propertyForKey:@"cellClass"] != gc) MPSP(gdemo, gc, @"cellClass");
        Class hc = MPCellClass("MPHeaderCell", (IMP)MPHeaderLayout), dc = MPCellClass("MPDemoCell", (IMP)MPDemoLayout);
        if (head && hc && [head propertyForKey:@"cellClass"] != hc) MPSP(head, hc, @"cellClass");
        if (demo && dc && [demo propertyForKey:@"cellClass"] != dc) MPSP(demo, dc, @"cellClass");
        if (demo) objc_setAssociatedObject(self, kMPDemoSpec, demo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // the demo only shows while Dynamic Pill is on
        if (demo && !MPDynamicOn(self, sw)) {
            NSMutableArray *m = [a mutableCopy]; [m removeObject:demo];
            Ivar iv = class_getInstanceVariable(NSClassFromString(@"PSListController"), "_specifiers");
            if (iv) object_setIvarWithStrongDefault(self, iv, m);
            return m;
        }
    } @catch (__unused id e) {}
    return a;
}
static void (*origMPSetPref)(id, SEL, id, id);
static void MPSetPref(id self, SEL _cmd, id value, id spec) {
    origMPSetPref(self, _cmd, value, spec);
    @try {
        if (![MPIdent(spec) isEqualToString:@"MP_DYNAMIC"]) return;
        id demo = objc_getAssociatedObject(self, kMPDemoSpec);
        if (!demo) return;
        Ivar iv = class_getInstanceVariable(NSClassFromString(@"PSListController"), "_specifiers");
        NSArray *cur = iv ? object_getIvar(self, iv) : nil;
        BOOL shown = [cur containsObject:demo];
        if ([value boolValue] && !shown) [self insertSpecifier:demo afterSpecifier:spec animated:YES];
        else if (![value boolValue] && shown) [self removeSpecifier:demo animated:YES];
    } @catch (__unused id e) {}
}
static void StartSettings(void) {
    Class PS = NSClassFromString(@"PSListController");
    if (!PS) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ StartSettings(); });
        return;
    }
    MSHookMessageEx(PS, @selector(specifiers), (IMP)MPSpecs, (IMP *)&origMPSpecs);
    MSHookMessageEx(PS, @selector(setPreferenceValue:specifier:), (IMP)MPSetPref, (IMP *)&origMPSetPref);
}
