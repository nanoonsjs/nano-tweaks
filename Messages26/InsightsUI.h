// ===================== Messages26: Conversation Insights =====================
// 1.7: swipe up on the search pill (conversation list) and it opens like MusicPill's Dynamic Pill: messages, emojis,
// busiest days, photos / videos, voice messages, most-used words, and the people you text most (tap one for
// that conversation). Counted on the phone by M26Keeper (Insights.m) in the Messages background service.
// Included from Tweak.x after the search pill code.

#define INS_DIR @"/var/mobile/Library/SMS/M26Unsent"

#pragma mark - asking M26Keeper

static NSString *gInsReq;
static void (^gInsCB)(NSDictionary *);
static void InsDone(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef ui) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *r = [NSDictionary dictionaryWithContentsOfFile:INS_DIR @"/insights_res.plist"];
        if (!gInsCB || ![r[@"req"] isEqualToString:gInsReq]) return;
        void (^cb)(NSDictionary *) = gInsCB; gInsCB = nil;
        cb(r);
    });
}
static void InsAsk(NSString *chat, void (^cb)(NSDictionary *)) {
    static dispatch_once_t o;
    dispatch_once(&o, ^{ CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, InsDone, CFSTR("com.nano.messages26/insights.done"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately); });
    NSString *rid = [NSUUID UUID].UUIDString;
    gInsReq = rid; gInsCB = cb;
    [[NSFileManager defaultManager] createDirectoryAtPath:INS_DIR withIntermediateDirectories:YES attributes:nil error:nil];
    [@{@"chat": chat ?: @"*", @"id": rid} writeToFile:INS_DIR @"/insights_req.plist" atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/insights.req"), NULL, NULL, YES);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([gInsReq isEqualToString:rid] && gInsCB) { void (^c2)(NSDictionary *) = gInsCB; gInsCB = nil; c2(@{@"error": @"No answer from the Messages background service. Respring (or reinstall Messages26) and try again."}); }
    });
}
// a chat id (phone / email / group id) as the name Messages shows
static NSString *InsName(NSString *cid, NSString *fallback) {
    Class CL = NSClassFromString(@"CKConversationList"); SEL sh = NSSelectorFromString(@"sharedConversationList");
    id list = [CL respondsToSelector:sh] ? ((id (*)(id, SEL))objc_msgSend)(CL, sh) : nil;
    NSArray *convs = nil; @try { convs = [list valueForKey:@"conversations"]; } @catch (__unused id e) {}
    for (id conv in convs) {
        NSString *k = nil; @try { k = [conv valueForKeyPath:@"chat.chatIdentifier"]; } @catch (__unused id e) {}
        if (![k isEqualToString:cid]) continue;
        for (NSString *nk in @[@"displayName", @"name"]) { NSString *n = nil; @try { n = [conv valueForKey:nk]; } @catch (__unused id e) {} if ([n isKindOfClass:[NSString class]] && n.length) return n; }
    }
    if (fallback.length) return fallback;
    return [cid hasPrefix:@"chat"] ? @"Group" : cid;
}
static NSString *InsNum(long n) { NSNumberFormatter *f = [NSNumberFormatter new]; f.numberStyle = NSNumberFormatterDecimalStyle; return [f stringFromNumber:@(n)]; }

#pragma mark - the Dynamic Pill (MusicPill's island, for the search pill)

// 1.7.2: works like MusicPill's Dynamic Pill: swipe up and the pill stretches with your finger, let go and it
// grows into a dark island with Insights on one spring; pull it down (or tap outside) and it closes the way
// the Dynamic Island does: top first, sides a beat behind, landing on the pill with a squishy bounce.
static CGFloat InsCurve(CGFloat p) { p = MAX(0, MIN(1, p)); return p * p * (3 - 2 * p); }
static CGFloat InsStep(CGFloat a, CGFloat b, CGFloat x) { x = MAX(0, MIN(1, (x - a) / (b - a))); return x * x * (3 - 2 * x); }
static CGFloat InsLerp(CGFloat a, CGFloat b, CGFloat t) { return a + (b - a) * t; }

@interface M26Insights : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *shape, *content, *snap;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIActivityIndicatorView *spin;
@property (nonatomic, strong) UILabel *loading;
@property (nonatomic, strong) NSDictionary *allData;
@property (nonatomic, weak) UIView *pill;
@property (nonatomic) CGFloat cw;
@property (nonatomic) BOOL dark;
@end
static __weak M26Insights *gIns;

@implementation M26Insights {
    CADisplayLink *_link; CFTimeInterval _lastT;
    CGFloat _prog, _vel, _goal, _zeta;   // 0 = open island, 1 = the pill
    CGRect _P, _to, _from;
}
- (instancetype)initWithPill:(UIView *)pill {
    UIWindow *w = pill.window;
    if (!(self = [super initWithFrame:w.bounds])) return nil;
    self.pill = pill; self.dark = YES;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;   // the island is always dark, like the real one
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    UIEdgeInsets sa = w.safeAreaInsets;
    CGFloat W = w.bounds.size.width, H = w.bounds.size.height;
    _from = [pill convertRect:pill.bounds toView:w];
    CGFloat bottom = MIN(H - MAX(10, sa.bottom - 8), CGRectGetMaxY(_from) + 4);
    _to = CGRectMake(8, sa.top + 6, W - 16, bottom - sa.top - 6);
    self.cw = _to.size.width;

    // the shape: deep dark glass with a faint rim, like the Dynamic Island
    UIView *shape = [[UIView alloc] initWithFrame:_from];
    shape.clipsToBounds = YES; shape.layer.cornerCurve = kCACornerCurveContinuous; shape.layer.cornerRadius = _from.size.height / 2;
    shape.layer.borderWidth = 0.8; shape.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark]];
    blur.frame = shape.bounds; blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [shape addSubview:blur];
    UIView *ink = [[UIView alloc] initWithFrame:shape.bounds];
    ink.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55]; ink.autoresizingMask = blur.autoresizingMask;
    [shape addSubview:ink];
    // the pill's picture, kept at its size at the bottom while the island grows out of it
    UIView *snap = [pill snapshotViewAfterScreenUpdates:NO];
    if (snap) { snap.frame = CGRectMake(0, 0, _from.size.width, _from.size.height); snap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; [shape addSubview:snap]; }
    self.snap = snap;
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _to.size.width, _to.size.height)];
    content.center = CGPointMake(_from.size.width / 2, _from.size.height / 2);
    content.alpha = 0; content.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [shape addSubview:content];
    self.shape = shape; self.content = content;

    self.scroll = [[UIScrollView alloc] initWithFrame:content.bounds];
    self.scroll.alwaysBounceVertical = YES; self.scroll.showsVerticalScrollIndicator = NO;
    [content addSubview:self.scroll];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem];
    [x setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    x.tintColor = UIColor.whiteColor; x.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    x.frame = CGRectMake(_to.size.width - 58, 22, 38, 38); x.layer.cornerRadius = 19;
    [x addTarget:self action:@selector(collapse) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:x];
    self.spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spin.color = UIColor.whiteColor; self.spin.center = CGPointMake(_to.size.width / 2, _to.size.height * 0.4); [self.spin startAnimating];
    [content addSubview:self.spin];
    self.loading = [[UILabel alloc] initWithFrame:CGRectMake(0, _to.size.height * 0.4 + 30, _to.size.width, 22)];
    self.loading.text = @"Counting your messages…"; self.loading.textAlignment = NSTextAlignmentCenter;
    self.loading.textColor = [UIColor colorWithWhite:1 alpha:0.6]; self.loading.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [content addSubview:self.loading];

    [self addSubview:shape];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgTap:)];
    [self addGestureRecognizer:tap];
    UIPanGestureRecognizer *down = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pullDown:)];
    down.delegate = self; [shape addGestureRecognizer:down];
    return self;
}
- (void)open {
    UIView *shape = self.shape, *content = self.content, *snap = self.snap;
    [UIView performWithoutAnimation:^{ self.pill.alpha = 0; }];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    // one spring out of the pill: quick, a touch of overshoot, settles like the Dynamic Island
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.35 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{
        shape.frame = self->_to; shape.layer.cornerRadius = 44;
        content.center = CGPointMake(self->_to.size.width / 2, self->_to.size.height / 2);
        content.transform = CGAffineTransformIdentity;
        snap.frame = CGRectMake((self->_to.size.width - self->_from.size.width) / 2, self->_to.size.height - self->_from.size.height, self->_from.size.width, self->_from.size.height);
    } completion:nil];
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ snap.alpha = 0; } completion:nil];
    [UIView animateWithDuration:0.16 delay:0.03 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{ content.alpha = 1; } completion:nil];
    [UIView animateWithDuration:0.35 animations:^{ self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3]; }];
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if (![g isKindOfClass:[UIPanGestureRecognizer class]]) return YES;
    CGPoint p = [g locationInView:self.shape], v = [(UIPanGestureRecognizer *)g velocityInView:self.shape];
    return v.y > fabs(v.x) && (p.y < 96 || self.scroll.contentOffset.y <= 0);
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return NO; }
- (CGRect)pillRect {
    UIView *p = self.pill;
    CGRect r = p.window == self.window ? [p convertRect:p.bounds toView:self] : _from;
    return r.size.width < 20 ? _from : r;
}
// the top edge leads, the sides and the bottom follow a beat behind
- (CGRect)rectFor:(CGFloat)pr {
    CGRect P = _P, T = _to;
    CGFloat e = InsCurve(pr);
    CGFloat top = InsLerp(CGRectGetMinY(T), CGRectGetMinY(P), MAX(-0.04, MIN(1.06, pr))), bottom = InsLerp(CGRectGetMaxY(T), CGRectGetMaxY(P), e);
    CGFloat w = InsLerp(T.size.width, P.size.width, e), cx = InsLerp(CGRectGetMidX(T), CGRectGetMidX(P), e);
    return CGRectMake(cx - w / 2, top, w, MAX(P.size.height, bottom - top));
}
- (void)beginMove {
    _P = [self pillRect];
    UIView *fresh = nil;
    if (self.pill.window) {
        CGFloat a0 = self.pill.alpha;
        [UIView performWithoutAnimation:^{ self.pill.alpha = 1; }];
        fresh = [self.pill snapshotViewAfterScreenUpdates:YES];
        [UIView performWithoutAnimation:^{ self.pill.alpha = a0; }];
    }
    if (fresh) { fresh.alpha = self.snap.alpha; [self.snap removeFromSuperview]; self.snap = fresh; [self.shape addSubview:fresh]; }
    self.snap.autoresizingMask = UIViewAutoresizingNone;
    [self.shape bringSubviewToFront:self.snap];
    [self.shape.layer removeAllAnimations]; [self.content.layer removeAllAnimations]; [self.snap.layer removeAllAnimations];
    self.content.layer.shouldRasterize = YES; self.content.layer.rasterizationScale = UIScreen.mainScreen.scale;
}
- (void)show:(CGFloat)pr {
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    [UIView performWithoutAnimation:^{ [self morphTo:[self rectFor:pr] progress:MAX(0, MIN(1, pr))]; }];
    [CATransaction commit];
}
- (void)morphTo:(CGRect)f progress:(CGFloat)p {
    CGRect P = _P, T = _to;
    self.shape.frame = f;
    CGFloat e = InsCurve(p);
    self.shape.layer.cornerRadius = MIN(f.size.height / 2, InsLerp(44, P.size.height / 2, e));
    self.shape.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16 * (1 - InsStep(0, 0.35, p))].CGColor;
    CGFloat sc = MIN(1, MAX(f.size.width / MAX(1, T.size.width), f.size.height / MAX(1, T.size.height)));
    self.content.transform = CGAffineTransformMakeScale(sc, sc);
    self.content.center = CGPointMake(f.size.width / 2, f.size.height / 2);
    self.content.alpha = 1 - InsStep(0.12, 0.62, p);
    self.snap.frame = CGRectMake((f.size.width - P.size.width) / 2, f.size.height - P.size.height, P.size.width, P.size.height);
    self.snap.alpha = InsStep(0.25, 0.75, p);
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3 * (1 - MIN(1, p))];
}
- (void)pullDown:(UIPanGestureRecognizer *)g {
    if (self.tag == 0x4D50) return;
    if (g.state == UIGestureRecognizerStateBegan) { [_link invalidate]; _link = nil; [self beginMove]; }
    CGFloat span = MAX(1, CGRectGetMinY(_P) - CGRectGetMinY(_to));
    CGFloat dy = MAX(0, [g translationInView:self].y);
    CGFloat pr = dy / span; if (pr > 1) pr = 1 + (1 - 1 / ((pr - 1) * 2.2 + 1)) * 0.06;
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) { _prog = pr; [self show:pr]; return; }
    CGFloat vy = [g velocityInView:self].y;
    if (g.state == UIGestureRecognizerStateEnded && (_prog > 0.28 || vy > 600)) { [self collapseWithVelocity:vy]; return; }
    _vel = -fabs(vy) / span * 0.5; _goal = 0; _zeta = 0.84;
    [self runSpring];
}
- (void)runSpring {
    if (!_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(springStep:)];
        if (@available(iOS 15.0, *)) _link.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
        [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    _lastT = 0;
}
- (void)springStep:(CADisplayLink *)l {
    CFTimeInterval now = l.targetTimestamp > 0 ? l.targetTimestamp : CACurrentMediaTime();
    double dt = _lastT > 0 ? MIN(1.0 / 30, now - _lastT) : 1.0 / 60; _lastT = now;
    double w = 2 * M_PI / (_goal >= 1 ? 0.5 : 0.32), k = w * w, c = 2 * _zeta * w;
    int n = MAX(1, (int)ceil(dt / (1.0 / 240))); double h = dt / n;
    for (int i = 0; i < n; i++) { double a = -k * (_prog - _goal) - c * _vel; _vel += a * h; _prog += _vel * h; }
    [self show:_prog];
    if (_goal >= 1 && self.tag == 0x4D50 && _prog >= 0.985) { [self landed]; return; }
    if (fabs(_prog - _goal) < 0.0015 && fabs(_vel) < 0.02) {
        [_link invalidate]; _link = nil;
        _prog = _goal; [self show:_goal];
        if (_goal >= 1) [self landed]; else self.content.layer.shouldRasterize = NO;
    }
}
- (void)bgTap:(UITapGestureRecognizer *)g { if (!CGRectContainsPoint(self.shape.frame, [g locationInView:self])) [self collapse]; }
- (void)collapse { [self collapseWithVelocity:0]; }
- (void)close { [self collapse]; }
- (void)collapseWithVelocity:(CGFloat)vy {
    if (self.tag == 0x4D50) return;
    self.tag = 0x4D50; gInsCB = nil;
    self.userInteractionEnabled = NO;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
    CALayer *pl = self.shape.layer.presentationLayer;
    CGRect cur = pl ? pl.frame : self.shape.frame;
    BOOL moving = _link != nil;
    if (!moving) [self beginMove];
    CGFloat span = MAX(1, CGRectGetMinY(_P) - CGRectGetMinY(_to));
    if (!moving) _prog = CGRectGetMinY(cur) > CGRectGetMinY(_to) + 1 ? MAX(0, (CGRectGetMinY(cur) - CGRectGetMinY(_to)) / span) : 0;
    _vel = vy > 0 ? MIN(6, vy / span) : (moving ? _vel : 0);
    _goal = 1; _zeta = 0.9;
    [self runSpring];
    __weak UIView *wp = self.pill;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ UIView *p = wp; if (p && p.alpha < 0.01) p.alpha = 1; if (self.superview && self.tag != 0x4D51) [self landed]; });
}
static void InsLandBounce(CALayer *L) {
    CASpringAnimation *sx = [CASpringAnimation animationWithKeyPath:@"transform.scale.x"]; sx.fromValue = @1.07; sx.toValue = @1;
    CASpringAnimation *sy = [CASpringAnimation animationWithKeyPath:@"transform.scale.y"]; sy.fromValue = @0.86; sy.toValue = @1;
    CASpringAnimation *ty = [CASpringAnimation animationWithKeyPath:@"transform.translation.y"]; ty.fromValue = @3; ty.toValue = @0;
    for (CASpringAnimation *a in @[sx, sy, ty]) { a.mass = 1; a.stiffness = 300; a.damping = 10; a.initialVelocity = 2; a.duration = a.settlingDuration; }
    [L addAnimation:sx forKey:@"m26.landx"]; [L addAnimation:sy forKey:@"m26.landy"]; [L addAnimation:ty forKey:@"m26.landt"];
}
- (void)landed {
    if (!self.superview || self.tag == 0x4D51) return;
    self.tag = 0x4D51;
    [_link invalidate]; _link = nil;
    UIView *pill = self.pill;
    [UIView performWithoutAnimation:^{ pill.alpha = 1; }];
    if (pill.window) InsLandBounce(pill.layer);
    InsLandBounce(self.shape.layer);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.26 delay:0.02 options:UIViewAnimationOptionCurveEaseInOut animations:^{ self.alpha = 0; } completion:^(__unused BOOL f) { [self removeFromSuperview]; }];
}

#pragma mark building the cards
- (UIView *)card:(CGFloat)y height:(CGFloat)h {
    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(16, y, self.cw - 32, h)];
    c.backgroundColor = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:self.dark ? 0.07 : 0.045];
    c.layer.cornerRadius = 24; c.layer.cornerCurve = kCACornerCurveContinuous;
    [self.scroll addSubview:c];
    return c;
}
- (UILabel *)label:(NSString *)t size:(CGFloat)s weight:(UIFontWeight)w color:(UIColor *)col in:(UIView *)v frame:(CGRect)fr {
    UILabel *l = [[UILabel alloc] initWithFrame:fr]; l.text = t; l.font = [UIFont systemFontOfSize:s weight:w]; l.textColor = col;
    l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.6; [v addSubview:l]; return l;
}
- (UILabel *)cardTitle:(NSString *)t in:(UIView *)c { return [self label:t.uppercaseString size:13 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:c frame:CGRectMake(18, 14, c.bounds.size.width - 36, 18)]; }
- (void)show:(NSDictionary *)d chat:(NSString *)chat name:(NSString *)name {
    [self.spin stopAnimating]; self.loading.hidden = YES; self.scroll.layer.shouldRasterize = NO;
    for (UIView *v in self.scroll.subviews.copy) [v removeFromSuperview];
    CGFloat W = self.cw, y = 20;
    BOOL all = [chat isEqualToString:@"*"];
    if (!all) {   // back to everything
        UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
        [back setImage:[UIImage systemImageNamed:@"chevron.left" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
        [back setTitle:@" All" forState:UIControlStateNormal]; back.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        back.frame = CGRectMake(14, y, 80, 34); back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [back addTarget:self action:@selector(backToAll) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:back]; y += 34;
    }
    [self label:all ? @"Insights" : name size:34 weight:UIFontWeightBold color:UIColor.labelColor in:self.scroll frame:CGRectMake(22, y, W - 44, 42)]; y += 42;
    NSString *sub = @"All your conversations";
    double first = [d[@"first"] doubleValue];
    if (first > 0) {
        NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle;
        sub = [NSString stringWithFormat:@"%@ · since %@", all ? @"All conversations" : @"This conversation", [f stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:first]]];
    }
    [self label:sub size:15 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:self.scroll frame:CGRectMake(22, y, W - 44, 20)]; y += 32;
    if (d[@"error"]) {
        UIView *c = [self card:y height:90];
        UILabel *l = [self label:d[@"error"] size:15 weight:UIFontWeightRegular color:UIColor.labelColor in:c frame:CGRectInset(c.bounds, 18, 10)];
        l.numberOfLines = 0; l.adjustsFontSizeToFitWidth = NO;
        self.scroll.contentSize = CGSizeMake(W, y + 120); return;
    }

    // big numbers
    long total = [d[@"total"] longValue];
    UIView *hero = [self card:y height:128];
    [self label:InsNum(total) size:46 weight:UIFontWeightHeavy color:UIColor.labelColor in:hero frame:CGRectMake(18, 14, hero.bounds.size.width - 36, 54)];
    [self label:@"messages" size:15 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:hero frame:CGRectMake(20, 64, 200, 20)];
    // sent vs received bar
    CGFloat bw = hero.bounds.size.width - 36, mf = total ? [d[@"mine"] doubleValue] / total : 0.5;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(18, 94, bw, 10)]; bar.layer.cornerRadius = 5; bar.clipsToBounds = YES;
    bar.backgroundColor = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.15]; [hero addSubview:bar];
    UIView *mb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bw * mf, 10)]; mb.backgroundColor = UIColor.systemBlueColor; [bar addSubview:mb];
    [self label:[NSString stringWithFormat:@"You %@", InsNum([d[@"mine"] longValue])] size:12 weight:UIFontWeightSemibold color:UIColor.systemBlueColor in:hero frame:CGRectMake(18, 106, bw / 2, 16)];
    UILabel *tl = [self label:[NSString stringWithFormat:@"%@ %@", all ? @"Others" : @"Them", InsNum([d[@"theirs"] longValue])] size:12 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:hero frame:CGRectMake(18 + bw / 2, 106, bw / 2, 16)];
    tl.textAlignment = NSTextAlignmentRight;
    y += 128 + 12;

    // tiles
    NSArray *tiles = @[@[@"photo.fill", UIColor.systemOrangeColor, d[@"photos"], @"Photos"], @[@"video.fill", UIColor.systemPinkColor, d[@"videos"], @"Videos"],
                       @[@"waveform", UIColor.systemRedColor, d[@"voice"], @"Voice messages"], @[@"heart.fill", UIColor.systemPurpleColor, d[@"reactions"], @"Reactions"],
                       @[@"calendar", UIColor.systemGreenColor, d[@"activeDays"], @"Days you talked"], @[@"paperclip", UIColor.systemTealColor, d[@"files"], @"Files"]];
    CGFloat tw = (W - 32 - 12) / 2, th = 92;
    for (NSUInteger i = 0; i < tiles.count; i++) {
        NSArray *t = tiles[i];
        UIView *c = [self card:y + (i / 2) * (th + 12) height:th];
        CGRect fr = c.frame; fr.origin.x = 16 + (i % 2) * (tw + 12); fr.size.width = tw; c.frame = fr;
        UIImageView *ic = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:t[0] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]]];
        ic.tintColor = UIColor.whiteColor; ic.contentMode = UIViewContentModeCenter; ic.backgroundColor = t[1];
        ic.frame = CGRectMake(14, 14, 30, 30); ic.layer.cornerRadius = 9; [c addSubview:ic];
        [self label:InsNum([t[2] longValue]) size:26 weight:UIFontWeightBold color:UIColor.labelColor in:c frame:CGRectMake(14, 48, tw - 28, 28)];
        [self label:t[3] size:12 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:c frame:CGRectMake(56, 20, tw - 66, 18)];
    }
    y += ((tiles.count + 1) / 2) * (th + 12);

    // emojis
    NSArray *em = d[@"myEmoji"];
    if (em.count) {
        UIView *c = [self card:y height:118];
        [self cardTitle:@"Your most-used emojis" in:c];
        CGFloat cw = (c.bounds.size.width - 24) / MIN(6, em.count);
        for (NSUInteger i = 0; i < MIN(6, em.count); i++) {
            [self label:em[i][0] size:36 weight:UIFontWeightRegular color:UIColor.labelColor in:c frame:CGRectMake(12 + i * cw, 38, cw, 44)].textAlignment = NSTextAlignmentCenter;
            [self label:InsNum([em[i][1] longValue]) size:12 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:c frame:CGRectMake(12 + i * cw, 84, cw, 16)].textAlignment = NSTextAlignmentCenter;
        }
        y += 118 + 12;
    }

    // busiest days
    NSArray *wd = d[@"weekdays"];
    if (wd.count == 7 && total) {
        UIView *c = [self card:y height:212];
        [self cardTitle:@"Most active days" in:c];
        long mx = 1; NSUInteger best = 0;
        for (NSUInteger i = 0; i < 7; i++) { long v = [wd[i] longValue]; if (v > mx) { mx = v; best = i; } }
        NSArray *names = @[@"M", @"T", @"W", @"T", @"F", @"S", @"S"], *full = @[@"Mondays", @"Tuesdays", @"Wednesdays", @"Thursdays", @"Fridays", @"Saturdays", @"Sundays"];
        CGFloat cw = (c.bounds.size.width - 36) / 7, base = 150, maxH = 96;
        for (NSUInteger i = 0; i < 7; i++) {
            CGFloat h = MAX(4, maxH * [wd[i] doubleValue] / mx);
            UIView *b = [[UIView alloc] initWithFrame:CGRectMake(18 + i * cw + cw * 0.2, base - h, cw * 0.6, h)];
            b.backgroundColor = i == best ? UIColor.systemBlueColor : [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.18];
            b.layer.cornerRadius = MIN(8, cw * 0.3); [c addSubview:b];
            [self label:names[i] size:12 weight:UIFontWeightSemibold color:i == best ? UIColor.systemBlueColor : UIColor.secondaryLabelColor in:c frame:CGRectMake(18 + i * cw, base + 4, cw, 16)].textAlignment = NSTextAlignmentCenter;
        }
        // peak hour and the single busiest day
        NSArray *hr = d[@"hours"]; NSUInteger bh = 0; long hm = -1;
        for (NSUInteger i = 0; i < hr.count; i++) if ([hr[i] longValue] > hm) { hm = [hr[i] longValue]; bh = i; }
        NSString *hs = [NSString stringWithFormat:@"%lu %@", (unsigned long)(bh % 12 == 0 ? 12 : bh % 12), bh < 12 ? @"AM" : @"PM"];
        NSString *line = [NSString stringWithFormat:@"Busiest on %@, around %@", full[best], hs];
        NSArray *bd = d[@"busiest"];
        if (bd.count == 2) {
            NSDateFormatter *in = [NSDateFormatter new]; in.dateFormat = @"yyyy-MM-dd";
            NSDateFormatter *out = [NSDateFormatter new]; out.dateStyle = NSDateFormatterMediumStyle;
            NSDate *dd = [in dateFromString:bd[0]];
            if (dd) line = [line stringByAppendingFormat:@"\nBiggest day: %@ (%@ messages)", [out stringFromDate:dd], InsNum([bd[1] longValue])];
        }
        UILabel *l = [self label:line size:13 weight:UIFontWeightMedium color:UIColor.labelColor in:c frame:CGRectMake(18, 172, c.bounds.size.width - 36, 34)];
        l.numberOfLines = 2; l.adjustsFontSizeToFitWidth = NO;
        y += 212 + 12;
    }

    // words
    NSArray *ws = d[@"myWords"];
    if (ws.count) {
        UIView *c = [self card:y height:60];
        [self cardTitle:@"Your most-used words" in:c];
        CGFloat x = 18, ly = 42, maxW = c.bounds.size.width - 18;
        UIColor *chip = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.1];
        for (NSUInteger i = 0; i < ws.count; i++) {
            UILabel *l = [UILabel new];
            NSMutableAttributedString *a = [[NSMutableAttributedString alloc] initWithString:ws[i][0] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: UIColor.labelColor}];
            [a appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", InsNum([ws[i][1] longValue])] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightMedium], NSForegroundColorAttributeName: UIColor.secondaryLabelColor}]];
            l.attributedText = a; [l sizeToFit];
            CGFloat cw = l.bounds.size.width + 24;
            if (x + cw > maxW) { x = 18; ly += 40; }
            UIView *p = [[UIView alloc] initWithFrame:CGRectMake(x, ly, cw, 32)]; p.backgroundColor = chip; p.layer.cornerRadius = 16;
            l.center = CGPointMake(cw / 2, 16); [p addSubview:l]; [c addSubview:p];
            x += cw + 8;
        }
        CGRect fr = c.frame; fr.size.height = ly + 32 + 16; c.frame = fr;
        y += fr.size.height + 12;
    }

    // the people you text most
    NSArray *top = d[@"top"];
    if (all && top.count) {
        CGFloat rh = 52;
        UIView *c = [self card:y height:44 + top.count * rh];
        [self cardTitle:@"Who you text most" in:c];
        long mx = MAX(1, [top.firstObject[@"count"] longValue]);
        for (NSUInteger i = 0; i < top.count; i++) {
            NSDictionary *t = top[i];
            UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
            row.frame = CGRectMake(0, 40 + i * rh, c.bounds.size.width, rh);
            row.accessibilityIdentifier = t[@"id"]; row.accessibilityLabel = InsName(t[@"id"], t[@"name"]);
            [row addTarget:self action:@selector(openChat:) forControlEvents:UIControlEventTouchUpInside];
            [c addSubview:row];
            [self label:[NSString stringWithFormat:@"%lu", (unsigned long)i + 1] size:15 weight:UIFontWeightBold color:UIColor.secondaryLabelColor in:row frame:CGRectMake(18, 6, 22, 22)];
            [self label:row.accessibilityLabel size:16 weight:UIFontWeightSemibold color:UIColor.labelColor in:row frame:CGRectMake(42, 6, c.bounds.size.width - 150, 22)];
            UILabel *n = [self label:InsNum([t[@"count"] longValue]) size:14 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:row frame:CGRectMake(c.bounds.size.width - 110, 6, 72, 22)];
            n.textAlignment = NSTextAlignmentRight;
            UIImageView *ch = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold]]];
            ch.tintColor = UIColor.tertiaryLabelColor; ch.frame = CGRectMake(c.bounds.size.width - 30, 10, 12, 14); [row addSubview:ch];
            UIView *b = [[UIView alloc] initWithFrame:CGRectMake(42, 33, (c.bounds.size.width - 80) * [t[@"count"] doubleValue] / mx, 6)];
            b.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.75]; b.layer.cornerRadius = 3; b.userInteractionEnabled = NO; [row addSubview:b];
        }
        y += c.bounds.size.height + 12;
    }
    [self label:@"Counted on your iPhone. Nothing leaves it." size:12 weight:UIFontWeightMedium color:UIColor.tertiaryLabelColor in:self.scroll frame:CGRectMake(0, y + 4, W, 16)].textAlignment = NSTextAlignmentCenter;
    self.scroll.contentSize = CGSizeMake(W, y + 60 + 0);
    // the cards float in
    NSArray *vs = self.scroll.subviews; NSUInteger i = 0;
    for (UIView *v in vs) {
        v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(0, 18);
        [UIView animateWithDuration:0.5 delay:0.03 * i++ usingSpringWithDamping:0.85 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)load:(NSString *)chat name:(NSString *)name {
    self.loading.hidden = NO; [self.spin startAnimating];
    for (UIView *v in self.scroll.subviews.copy) [UIView animateWithDuration:0.15 animations:^{ v.alpha = 0; }];
    __weak typeof(self) me = self;
    InsAsk(chat, ^(NSDictionary *d) {
        if (!me.superview) return;
        if ([chat isEqualToString:@"*"] && !d[@"error"]) me.allData = d;
        [me.scroll setContentOffset:CGPointZero animated:NO];
        [me show:d chat:chat name:name];
    });
}
- (void)openChat:(UIButton *)b { [[[UISelectionFeedbackGenerator alloc] init] selectionChanged]; [self load:b.accessibilityIdentifier name:b.accessibilityLabel]; }
- (void)backToAll {
    if (self.allData) { [self.scroll setContentOffset:CGPointZero animated:NO]; [self show:self.allData chat:@"*" name:nil]; }
    else [self load:@"*" name:nil];
}
@end

#pragma mark - pulled up from the search pill

// the swipe stretches the pill up with your finger (like MusicPill's), let go and the island opens out of it
static void InsStretch(UIView *v, CGFloat up) {
    CGFloat d = MAX(0, up), r = 26 * (1 - 1 / (d / 60 + 1));                   // rubber band
    CGFloat sy = 1 + MIN(0.22, d / 420), sx = 1 - MIN(0.05, d / 1600);
    v.layer.transform = CATransform3DScale(CATransform3DMakeTranslation(0, -r - v.bounds.size.height * (sy - 1) / 2, 0), sx, sy, 1);
}
static void InsRelease(UIView *v) {
    CATransform3D from = v.layer.transform;
    v.layer.transform = CATransform3DIdentity;
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"transform"];
    a.fromValue = [NSValue valueWithCATransform3D:from]; a.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    a.mass = 1; a.stiffness = 260; a.damping = 12; a.duration = a.settlingDuration;
    [v.layer addAnimation:a forKey:@"m26.release"];
}
@interface M26InsPan : NSObject <UIGestureRecognizerDelegate>
@end
@implementation M26InsPan
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    if (!gInsOn || gIns.superview) return NO;
    CGPoint v = [g velocityInView:g.view];
    return v.y < 0 && fabs(v.y) > fabs(v.x);   // straight up only (taps stay the pill's)
}
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *pill = g.view; UIWindow *w = pill.window; if (!w) return;
    CGFloat up = -[g translationInView:w].y;
    if (g.state == UIGestureRecognizerStateBegan) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        if ([pill isKindOfClass:[UIControl class]]) [(UIControl *)pill cancelTrackingWithEvent:nil];
        [pill.layer removeAnimationForKey:@"m26.release"];
    }
    if (g.state == UIGestureRecognizerStateChanged) {
        [CATransaction begin]; [CATransaction setDisableActions:YES]; InsStretch(pill, up); [CATransaction commit];
        if (up > 150) { g.enabled = NO; g.enabled = YES; [self openFrom:pill]; }   // pulled far: it opens by itself
    } else if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        if (g.state == UIGestureRecognizerStateEnded && (up > 40 || [g velocityInView:w].y < -450)) [self openFrom:pill];
        else InsRelease(pill);
    }
}
- (void)openFrom:(UIView *)pill {
    if (gIns.superview) return;
    // the island starts from the pill as it looks right now (still stretched)
    M26Insights *s = [[M26Insights alloc] initWithPill:pill];
    CALayer *pl = pill.layer.presentationLayer ?: pill.layer;
    CGRect seen = [pill.superview.layer convertRect:pl.frame toLayer:pill.window.layer];
    pill.layer.transform = CATransform3DIdentity;
    if (seen.size.width > 20) { s.shape.frame = seen; s.shape.layer.cornerRadius = MIN(seen.size.height, seen.size.width) / 2; s.content.center = CGPointMake(seen.size.width / 2, seen.size.height / 2); s.snap.frame = CGRectMake((seen.size.width - pill.bounds.size.width) / 2, seen.size.height - pill.bounds.size.height, pill.bounds.size.width, pill.bounds.size.height); }
    [pill.window addSubview:s];
    gIns = s;
    [s open];
    [s load:@"*" name:nil];
}
@end
static void InsAttach(UIView *pill) {
    if (!pill || objc_getAssociatedObject(pill, "m26ins")) return;
    static M26InsPan *t; if (!t) t = [M26InsPan new];
    UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:t action:@selector(pan:)];
    p.delegate = t; p.cancelsTouchesInView = YES;
    [pill addGestureRecognizer:p];
    objc_setAssociatedObject(pill, "m26ins", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
