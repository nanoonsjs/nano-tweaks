// ===================== MusicPill landscape =====================
// Music itself only works upright. Turn the phone sideways and MusicPill's own full-screen
// glass player appears (artwork left, controls right, colors from the cover); turn it back
// and it goes away. The Insights button shows the dashboard in two columns.
// Also: a smaller pill while you're on the Library tab.
// (Included from Tweak.x after Extras.h.)

#define gLandscape gLandscapePref
#define gLibMini gLibMiniPref

static void XSeek(double t) {
    typedef void (*SeekFn)(double);
    static SeekFn seek; static dispatch_once_t o;
    dispatch_once(&o, ^{ void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY); if (h) seek = (SeekFn)dlsym(h, "MRMediaRemoteSetElapsedTime"); });
    if (seek) seek(t);
}
static double XElapsedNow(void) {
    double e = gXElapsed + (gXRate > 0 ? (CFAbsoluteTimeGetCurrent() - gXStamp) * gXRate : 0);
    return gXDuration > 0 ? MAX(0, MIN(gXDuration, e)) : MAX(0, e);
}
static NSString *XTime(double s) { int t = (int)MAX(0, round(s)); return [NSString stringWithFormat:@"%d:%02d", t / 60, t % 60]; }

// a few strong colors from the cover (for the moving background)
static NSArray<UIColor *> *XColorsOf(UIImage *img) {
    if (!img.CGImage) return @[[UIColor colorWithRed:0.35 green:0.1 blue:0.2 alpha:1], [UIColor colorWithRed:0.12 green:0.1 blue:0.3 alpha:1], [UIColor colorWithRed:0.25 green:0.05 blue:0.12 alpha:1]];
    int n = 6;
    unsigned char px[6 * 6 * 4] = {0};
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(px, n, n, 8, n * 4, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, n, n), img.CGImage);
    CGContextRelease(ctx); CGColorSpaceRelease(cs);
    NSMutableArray *cols = [NSMutableArray array];
    // pick the most colorful cells from three areas (top-left, middle, bottom-right)
    int areas[3][4] = {{0, 0, 3, 3}, {1, 1, 5, 5}, {3, 3, 6, 6}};
    for (int a = 0; a < 3; a++) {
        double best = -1; UIColor *bc = nil;
        for (int y = areas[a][1]; y < areas[a][3]; y++) for (int x = areas[a][0]; x < areas[a][2]; x++) {
            unsigned char *p = px + (y * n + x) * 4;
            CGFloat r = p[0] / 255.0, g = p[1] / 255.0, b = p[2] / 255.0;
            CGFloat mx = MAX(r, MAX(g, b)), mn = MIN(r, MIN(g, b));
            double score = (mx - mn) * 1.4 + mx * 0.6;
            if (score > best) { best = score; bc = [UIColor colorWithRed:r green:g blue:b alpha:1]; }
        }
        CGFloat h, sa, br, al; [bc getHue:&h saturation:&sa brightness:&br alpha:&al];
        [cols addObject:[UIColor colorWithHue:h saturation:MIN(1, sa * 1.15) brightness:MIN(0.75, MAX(0.28, br)) alpha:1]];
    }
    return cols;
}

// a round floating glass button
static UIButton *XGlassButton(NSString *sym, CGFloat d, CGFloat pt) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.bounds = CGRectMake(0, 0, d, d);
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    g.frame = b.bounds; g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerRadius = d / 2; g.layer.borderWidth = 1; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
    g.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    g.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [b addSubview:g];
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor;
    [b bringSubviewToFront:b.imageView];
    b.layer.shadowColor = UIColor.blackColor.CGColor; b.layer.shadowOpacity = 0.25; b.layer.shadowRadius = 12; b.layer.shadowOffset = CGSizeMake(0, 6);
    return b;
}

// the progress bar: drag from where it is (like Apple's), grows while held
@interface MPScrub : UIControl
@property (nonatomic) double value;   // 0...1
@property (nonatomic, readonly) BOOL dragging;
@property (nonatomic, copy) void (^done)(double v);
@property (nonatomic, copy) void (^moving)(double v);
@end
@implementation MPScrub { UIView *_track, *_fill; double _start; CGFloat _x0; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _track = [UIView new]; _track.userInteractionEnabled = NO; _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22]; _track.clipsToBounds = YES;
    _fill = [UIView new]; _fill.userInteractionEnabled = NO; _fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    [_track addSubview:_fill]; [self addSubview:_track];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = _dragging ? 12 : 6, W = self.bounds.size.width;
    _track.frame = CGRectMake(_dragging ? -4 : 0, (self.bounds.size.height - h) / 2, W + (_dragging ? 8 : 0), h);
    _track.layer.cornerRadius = h / 2;
    _fill.frame = CGRectMake(0, 0, _track.bounds.size.width * MAX(0, MIN(1, _value)), h);
}
- (void)setValue:(double)v { if (_dragging) return; _value = v; [self setNeedsLayout]; }
- (BOOL)beginTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    _dragging = YES; _start = _value; _x0 = [t locationInView:self].x;
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ [self layoutSubviews]; } completion:nil];
    return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    _value = MAX(0, MIN(1, _start + ([t locationInView:self].x - _x0) / MAX(1, self.bounds.size.width)));
    [self layoutSubviews];
    if (self.moving) self.moving(_value);
    return YES;
}
- (void)endTrackingWithTouch:(UITouch *)t withEvent:(UIEvent *)e {
    _dragging = NO;
    if (self.done) self.done(_value);
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ [self layoutSubviews]; } completion:nil];
}
- (void)cancelTrackingWithEvent:(UIEvent *)e { [self endTrackingWithTouch:nil withEvent:e]; }
@end

@interface MPLandscape : UIView
+ (instancetype)shared;
- (void)showRotated:(CGFloat)angle in:(UIWindow *)w;
- (void)hide;
@end
@implementation MPLandscape {
    UIView *_bg, *_tint, *_root, *_insights;
    NSArray<CALayer *> *_blobs;
    UIImageView *_art;
    UILabel *_title, *_artist, *_album, *_el, *_rem;
    MPScrub *_scrub;
    UIButton *_prev, *_play, *_next, *_close, *_stats;
    MPVolumeView *_vol;
    UIImage *_shownArt;
    dispatch_source_t _timer;
    CGFloat _angle;
}
+ (instancetype)shared { static MPLandscape *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [[MPLandscape alloc] initWithFrame:CGRectZero]; }); return s; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.backgroundColor = UIColor.blackColor;
    _bg = [UIView new]; _bg.clipsToBounds = YES; [self addSubview:_bg];
    NSMutableArray *blobs = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        CAGradientLayer *g = [CAGradientLayer layer]; g.type = kCAGradientLayerRadial;
        g.startPoint = CGPointMake(0.5, 0.5); g.endPoint = CGPointMake(1, 1);
        [_bg.layer addSublayer:g]; [blobs addObject:g];
    }
    _blobs = blobs;
    _tint = [UIView new]; _tint.backgroundColor = [UIColor colorWithWhite:0 alpha:0.28]; [self addSubview:_tint];
    _root = [UIView new]; [self addSubview:_root];
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerRadius = 20; _art.layer.cornerCurve = kCACornerCurveContinuous; _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    UIView *artHost = [UIView new]; artHost.tag = 9;
    artHost.layer.shadowColor = UIColor.blackColor.CGColor; artHost.layer.shadowOpacity = 0.45; artHost.layer.shadowRadius = 24; artHost.layer.shadowOffset = CGSizeMake(0, 14);
    [artHost addSubview:_art]; [_root addSubview:artHost];
    _title = XLabel(@"", 28, UIFontWeightBold, nil); _title.adjustsFontSizeToFitWidth = NO; _title.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_title];
    _artist = XLabel(@"", 21, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.72]); _artist.adjustsFontSizeToFitWidth = NO; [_root addSubview:_artist];
    _album = XLabel(@"", 15, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.5]); _album.adjustsFontSizeToFitWidth = NO; [_root addSubview:_album];
    _scrub = [MPScrub new]; [_root addSubview:_scrub];
    __weak MPLandscape *ws = self;
    _scrub.moving = ^(double v) { MPLandscape *s = ws; s->_el.text = XTime(v * gXDuration); s->_rem.text = [@"-" stringByAppendingString:XTime(gXDuration * (1 - v))]; };
    _scrub.done = ^(double v) { if (gXDuration > 0) { XSeek(v * gXDuration); gXElapsed = v * gXDuration; gXStamp = CFAbsoluteTimeGetCurrent(); } };
    _el = XLabel(@"0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); [_root addSubview:_el];
    _rem = XLabel(@"-0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); _rem.textAlignment = NSTextAlignmentRight; [_root addSubview:_rem];
    _prev = XGlassButton(@"backward.fill", 64, 22); _play = XGlassButton(@"play.fill", 84, 32); _next = XGlassButton(@"forward.fill", 64, 22);
    for (UIButton *b in @[_prev, _play, _next]) {
        [b addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        [_root addSubview:b];
    }
    _vol = [[MPVolumeView alloc] init];
    _vol.tintColor = UIColor.whiteColor;
    if ([_vol respondsToSelector:@selector(setShowsRouteButton:)]) ((void (*)(id, SEL, BOOL))objc_msgSend)(_vol, @selector(setShowsRouteButton:), YES);
    [_root addSubview:_vol];
    _close = XGlassButton(@"chevron.down", 40, 15); [_close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_close];
    _stats = XGlassButton(@"chart.bar.fill", 40, 15); [_stats addTarget:self action:@selector(toggleInsights) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_stats];
    return self;
}
- (void)down:(UIButton *)b { [UIView animateWithDuration:0.12 animations:^{ b.transform = CGAffineTransformMakeScale(0.88, 0.88); }]; }
- (void)up:(UIButton *)b { [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil]; }
- (void)tap:(UIButton *)b {
    [self up:b];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b == _play) { XSend(2); gXPlaying = !gXPlaying; [self refresh]; }
    else { XSend(b == _next ? 4 : 5); dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ XPoll(); }); }
}
- (void)toggleInsights {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    if (_insights) {
        UIView *v = _insights; _insights = nil;
        [UIView animateWithDuration:0.3 animations:^{ v.alpha = 0; v.transform = CGAffineTransformMakeScale(0.96, 0.96); self->_root.alpha = 1; } completion:^(__unused BOOL f) { [v removeFromSuperview]; }];
        return;
    }
    UIVisualEffectView *panel = XGlass(30);
    CGRect b = self.bounds; UIEdgeInsets sa = self.window.safeAreaInsets;
    CGFloat side = MAX(sa.top, sa.bottom) + 12;   // the notch side is a long edge now
    panel.frame = CGRectMake(side, 16, b.size.width - side * 2, b.size.height - 32);
    [MPInsightsCtl buildIn:panel.contentView size:panel.bounds.size closeTarget:self action:@selector(toggleInsights)];
    [self insertSubview:panel belowSubview:_close];
    _insights = panel;
    panel.alpha = 0; panel.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ panel.alpha = 1; panel.transform = CGAffineTransformIdentity; self->_root.alpha = 0; } completion:nil];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect B = self.bounds; CGFloat W = B.size.width, H = B.size.height;
    UIEdgeInsets sa = self.window.safeAreaInsets;
    CGFloat side = MAX(sa.top, sa.bottom) + 18;   // after rotating, the notch is on a short side
    _bg.frame = B; _tint.frame = B; _root.frame = B;
    CGFloat d = MIN(H - 64, W * 0.42);
    UIView *artHost = [_root viewWithTag:9];
    artHost.frame = CGRectMake(side, (H - d) / 2, d, d);
    artHost.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:artHost.bounds cornerRadius:20].CGPath;
    _art.frame = artHost.bounds;
    CGFloat x = CGRectGetMaxX(artHost.frame) + 36, rw = W - x - side;
    CGFloat top = (H - 250) / 2;
    _title.frame = CGRectMake(x, top, rw, 34);
    _artist.frame = CGRectMake(x, top + 36, rw, 26);
    _album.frame = CGRectMake(x, top + 63, rw, 20);
    _scrub.frame = CGRectMake(x, top + 98, rw, 22);
    _el.frame = CGRectMake(x, top + 122, 80, 16);
    _rem.frame = CGRectMake(x + rw - 80, top + 122, 80, 16);
    CGFloat cy = top + 186, cx = x + rw / 2;
    _play.center = CGPointMake(cx, cy);
    _prev.center = CGPointMake(cx - 110, cy);
    _next.center = CGPointMake(cx + 110, cy);
    _vol.frame = CGRectMake(x, top + 240, rw, 30);
    _close.center = CGPointMake(W - side + 2, 34);
    _stats.center = CGPointMake(W - side - 50, 34);
    NSArray *spots = @[[NSValue valueWithCGPoint:CGPointMake(W * 0.2, H * 0.3)], [NSValue valueWithCGPoint:CGPointMake(W * 0.75, H * 0.25)], [NSValue valueWithCGPoint:CGPointMake(W * 0.55, H * 0.85)]];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (NSUInteger i = 0; i < _blobs.count; i++) { CALayer *l = _blobs[i]; l.bounds = CGRectMake(0, 0, W * 1.1, W * 1.1); l.position = [spots[i] CGPointValue]; }
    [CATransaction commit];
}
- (void)drift {
    // the color blobs wander slowly, like iOS 26's animated background
    for (NSUInteger i = 0; i < _blobs.count; i++) {
        CALayer *l = _blobs[i];
        if ([l animationForKey:@"drift"]) continue;
        CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        CGPoint p = l.position; CGFloat r = self.bounds.size.width * 0.12;
        a.values = @[[NSValue valueWithCGPoint:p], [NSValue valueWithCGPoint:CGPointMake(p.x + r, p.y - r * 0.6)], [NSValue valueWithCGPoint:CGPointMake(p.x - r * 0.7, p.y + r * 0.5)], [NSValue valueWithCGPoint:p]];
        a.duration = 14 + i * 5; a.repeatCount = HUGE_VALF; a.calculationMode = kCAAnimationCubic;
        [l addAnimation:a forKey:@"drift"];
    }
}
- (void)refresh {
    if (gXArt != _shownArt) {
        _shownArt = gXArt;
        [UIView transitionWithView:_art duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self->_art.image = gXArt; } completion:nil];
        NSArray *cols = XColorsOf(gXArt);
        for (NSUInteger i = 0; i < _blobs.count; i++) {
            CAGradientLayer *g = (CAGradientLayer *)_blobs[i];
            UIColor *c = cols[i % cols.count];
            NSArray *to = @[(id)[c colorWithAlphaComponent:0.95].CGColor, (id)[c colorWithAlphaComponent:0].CGColor];
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"colors"]; a.fromValue = g.colors; a.toValue = to; a.duration = 1.0;
            g.colors = to; [g addAnimation:a forKey:@"colors"];
        }
    }
    if (![_title.text isEqualToString:gXTitle ?: @"Not Playing"]) _title.text = gXTitle ?: @"Not Playing";
    _artist.text = gXArtist ?: @""; _album.text = gXAlbum ?: @"";
    double e = XElapsedNow();
    if (!_scrub.dragging) {
        _scrub.value = gXDuration > 0 ? e / gXDuration : 0;
        _el.text = XTime(e); _rem.text = [@"-" stringByAppendingString:XTime(MAX(0, gXDuration - e))];
    }
    NSString *sym = gXPlaying ? @"pause.fill" : @"play.fill";
    if (![_play.accessibilityValue isEqualToString:sym]) {
        _play.accessibilityValue = sym;
        [_play setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:32 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    }
    // the cover shrinks a little while paused (iOS)
    CGAffineTransform at = gXPlaying ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);
    UIView *artHost = [_root viewWithTag:9];
    if (!CGAffineTransformEqualToTransform(artHost.transform, at)) [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ artHost.transform = at; } completion:nil];
}
- (void)showRotated:(CGFloat)angle in:(UIWindow *)w {
    BOOL fresh = self.superview != w;
    _angle = angle;
    CGSize S = w.bounds.size;
    self.bounds = CGRectMake(0, 0, S.height, S.width);
    self.center = CGPointMake(S.width / 2, S.height / 2);
    if (fresh) {
        [self removeFromSuperview];
        [w addSubview:self];
        self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(angle), 0.9, 0.9);
        self.alpha = 0;
        XPoll();
        [self setNeedsLayout]; [self layoutIfNeeded];
        [self refresh]; [self drift];
        [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{ self.alpha = 1; self.transform = CGAffineTransformMakeRotation(angle); } completion:nil];
        if (!_timer) {
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
            dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.25 * NSEC_PER_SEC), (uint64_t)(0.05 * NSEC_PER_SEC));
            __weak MPLandscape *ws = self;
            dispatch_source_set_event_handler(_timer, ^{ @try { [ws refresh]; } @catch (__unused id e) {} });
            dispatch_resume(_timer);
        }
    } else {
        [UIView animateWithDuration:0.45 animations:^{ self.transform = CGAffineTransformMakeRotation(angle); }];
    }
}
- (void)hide {
    if (!self.superview) return;
    if (_timer) { dispatch_source_cancel(_timer); _timer = nil; }
    if (_insights) { [_insights removeFromSuperview]; _insights = nil; _root.alpha = 1; }
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ self.alpha = 0; self.transform = CGAffineTransformScale(self.transform, 0.92, 0.92); } completion:^(__unused BOOL f) { [self removeFromSuperview]; self.transform = CGAffineTransformIdentity; }];
}
@end

@interface MPOrient : NSObject @end
@implementation MPOrient
+ (void)changed:(NSNotification *)n {
    if (!gLandscape || !gRound) { [[MPLandscape shared] hide]; return; }
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    UIDeviceOrientation o = UIDevice.currentDevice.orientation;
    UIWindow *w = gLastTabBar.window ?: UIApplication.sharedApplication.keyWindow;
    if (!w) return;
    if (o == UIDeviceOrientationLandscapeLeft) [[MPLandscape shared] showRotated:M_PI_2 in:w];
    else if (o == UIDeviceOrientationLandscapeRight) [[MPLandscape shared] showRotated:-M_PI_2 in:w];
    else if (o == UIDeviceOrientationPortrait) [[MPLandscape shared] hide];
}
@end
static void StartLandscape(void) {
    [UIDevice.currentDevice beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:[MPOrient class] selector:@selector(changed:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

// a smaller pill while you're on the Library tab
static BOOL OnLibraryTab(void) {
    UITabBar *tb = gLastTabBar;
    if (!gLibMini || !tb.selectedItem) return NO;
    NSUInteger i = [tb.items indexOfObject:tb.selectedItem];
    NSString *t = tb.selectedItem.title.lowercaseString;
    return [t containsString:@"library"] || [t containsString:@"mediateca"] || [t containsString:@"biblioth"] || (i == 3 && tb.items.count == 5 && !t.length);
}
