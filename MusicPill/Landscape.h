// ===================== MusicPill landscape =====================
// Turn the phone sideways in Music and MusicPill's own full-screen glass player appears.
// While it shows, Music is allowed to rotate for real, so iOS puts the home bar along the
// landscape bottom and hides the status bar. Turn back and it goes away (Music is upright again).
// Also: a smaller pill while you're on the Library tab.
// (Included from Tweak.x after Extras.h.)
#import <AVKit/AVKit.h>

#define gLandscape gLandscapePref
#define gLibMini gLibMiniPref

static BOOL gLSActive;   // our landscape player is up (Music may rotate)

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

// the song's lyrics from your library (Music keeps them for many songs; not timed)
static NSString *XLyrics(NSString *title, NSString *artist) {
    if (!title.length) return nil;
    @try {
        MPMediaQuery *q = [MPMediaQuery songsQuery];
        [q addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:title forProperty:MPMediaItemPropertyTitle]];
        for (MPMediaItem *it in q.items) {
            if (artist.length && it.artist.length && ![it.artist isEqualToString:artist]) continue;
            NSString *l = it.lyrics;
            if (l.length) return l;
        }
    } @catch (__unused id e) {}
    return nil;
}

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
    int areas[3][4] = {{0, 0, 3, 3}, {1, 1, 5, 5}, {3, 3, 6, 6}};
    for (int a = 0; a < 3; a++) {
        double best = -1; CGFloat br_ = 0.3, bg_ = 0.1, bb_ = 0.2;
        for (int y = areas[a][1]; y < areas[a][3]; y++) for (int x = areas[a][0]; x < areas[a][2]; x++) {
            unsigned char *p = px + (y * n + x) * 4;
            CGFloat r = p[0] / 255.0, g = p[1] / 255.0, b = p[2] / 255.0;
            CGFloat mx = MAX(r, MAX(g, b)), mn = MIN(r, MIN(g, b));
            double score = (mx - mn) * 1.4 + mx * 0.6;
            if (score > best) { best = score; br_ = r; bg_ = g; bb_ = b; }
        }
        UIColor *bc = [UIColor colorWithRed:br_ green:bg_ blue:bb_ alpha:1];
        CGFloat h, sa, br, al; [bc getHue:&h saturation:&sa brightness:&br alpha:&al];
        [cols addObject:[UIColor colorWithHue:h saturation:MIN(1, sa * 1.15) brightness:MIN(0.72, MAX(0.28, br)) alpha:1]];
    }
    return cols;
}

// glass: a capsule or circle of light frosted glass with a bright rim
static UIVisualEffectView *XLiquid(CGRect f, CGFloat radius) {
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    g.frame = f; g.clipsToBounds = YES;
    g.layer.cornerRadius = radius; g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 1; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.32].CGColor;
    g.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
    CAGradientLayer *shine = [CAGradientLayer layer];
    shine.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.22].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    shine.locations = @[@0, @0.5]; shine.frame = g.bounds;
    [g.contentView.layer addSublayer:shine];
    return g;
}
static UIButton *XIconButton(NSString *sym, CGFloat d, CGFloat pt, BOOL glass) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.bounds = CGRectMake(0, 0, d, d);
    if (glass) { UIVisualEffectView *g = XLiquid(b.bounds, d / 2); g.userInteractionEnabled = NO; g.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; [b addSubview:g]; }
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor;
    [b bringSubviewToFront:b.imageView];
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
    _fill = [UIView new]; _fill.userInteractionEnabled = NO; _fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.92];
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
- (void)setValue:(double)v { if (_dragging) return; if (fabs(v - _value) < 0.0005) return; _value = v; [self setNeedsLayout]; }
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

static void XRequestOrientationFwd(UIWindow *w, UIInterfaceOrientationMask mask);
@interface MPLandscape : UIView
+ (instancetype)shared;
- (void)showIn:(UIWindow *)w turn:(UIDeviceOrientation)o;
- (void)hide;
@end
@implementation MPLandscape {
    UIView *_bg, *_tint, *_root, *_insights, *_artHost, *_controls;
    NSArray<CALayer *> *_blobs;
    UIImageView *_art;
    UILabel *_title, *_artist, *_album, *_el, *_rem;
    MPScrub *_scrub;
    UIButton *_prev, *_play, *_next, *_close, *_stats, *_lyricsBtn;
    MPVolumeView *_vol;
    AVRoutePickerView *_route;
    UIView *_routeGlass;
    UITextView *_lyrics;
    NSString *_lyricsSong;
    BOOL _showLyrics;
    UIImage *_shownArt;
    dispatch_source_t _timer;
}
+ (instancetype)shared { static MPLandscape *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [[MPLandscape alloc] initWithFrame:CGRectZero]; }); return s; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.backgroundColor = UIColor.blackColor;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _bg = [UIView new]; _bg.clipsToBounds = YES; [self addSubview:_bg];
    NSMutableArray *blobs = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        CAGradientLayer *g = [CAGradientLayer layer]; g.type = kCAGradientLayerRadial;
        g.startPoint = CGPointMake(0.5, 0.5); g.endPoint = CGPointMake(1, 1);
        [_bg.layer addSublayer:g]; [blobs addObject:g];
    }
    _blobs = blobs;
    _tint = [UIView new]; _tint.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30]; [self addSubview:_tint];
    _root = [UIView new]; [self addSubview:_root];

    _artHost = [UIView new];
    _artHost.layer.shadowColor = UIColor.blackColor.CGColor; _artHost.layer.shadowOpacity = 0.5; _artHost.layer.shadowRadius = 28; _artHost.layer.shadowOffset = CGSizeMake(0, 16);
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerRadius = 22; _art.layer.cornerCurve = kCACornerCurveContinuous; _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [_artHost addSubview:_art]; [_root addSubview:_artHost];

    _lyrics = [UITextView new];
    _lyrics.editable = NO; _lyrics.selectable = NO; _lyrics.backgroundColor = UIColor.clearColor;
    _lyrics.showsVerticalScrollIndicator = NO; _lyrics.textContainerInset = UIEdgeInsetsMake(40, 0, 80, 0);
    _lyrics.alpha = 0; _lyrics.hidden = YES;
    CAGradientLayer *fade = [CAGradientLayer layer];   // soft fade at the top and bottom edges
    fade.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
    fade.locations = @[@0, @0.12, @0.85, @1];
    _lyrics.layer.mask = fade;
    [_root addSubview:_lyrics];

    _title = XLabel(@"", 28, UIFontWeightBold, nil); _title.adjustsFontSizeToFitWidth = NO; _title.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_title];
    _artist = XLabel(@"", 21, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.72]); _artist.adjustsFontSizeToFitWidth = NO; _artist.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_artist];
    _album = XLabel(@"", 15, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.5]); _album.adjustsFontSizeToFitWidth = NO; _album.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_album];
    _scrub = [MPScrub new]; [_root addSubview:_scrub];
    __weak MPLandscape *ws = self;
    _scrub.moving = ^(double v) { MPLandscape *s = ws; s->_el.text = XTime(v * gXDuration); s->_rem.text = [@"-" stringByAppendingString:XTime(gXDuration * (1 - v))]; };
    _scrub.done = ^(double v) { if (gXDuration > 0) { XSeek(v * gXDuration); gXElapsed = v * gXDuration; gXStamp = CFAbsoluteTimeGetCurrent(); } };
    _el = XLabel(@"0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); [_root addSubview:_el];
    _rem = XLabel(@"-0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); _rem.textAlignment = NSTextAlignmentRight; [_root addSubview:_rem];

    // back / play / next sit together in one floating glass capsule (iOS 26)
    _controls = XLiquid(CGRectMake(0, 0, 280, 84), 42);
    _controls.layer.shadowColor = UIColor.blackColor.CGColor;
    [_root addSubview:_controls];
    _prev = XIconButton(@"backward.fill", 64, 24, NO); _play = XIconButton(@"play.fill", 76, 34, NO); _next = XIconButton(@"forward.fill", 64, 24, NO);
    for (UIButton *b in @[_prev, _play, _next]) {
        [b addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        [_root addSubview:b];
    }
    _vol = [[MPVolumeView alloc] init];
    _vol.tintColor = UIColor.whiteColor;
    if ([_vol respondsToSelector:@selector(setShowsRouteButton:)]) ((void (*)(id, SEL, BOOL))objc_msgSend)(_vol, @selector(setShowsRouteButton:), NO);
    [_root addSubview:_vol];
    // AirPlay: the normal AirPlay icon in its own glass circle
    _routeGlass = XLiquid(CGRectMake(0, 0, 44, 44), 22); _routeGlass.userInteractionEnabled = YES; [_root addSubview:_routeGlass];
    _route = [[AVRoutePickerView alloc] initWithFrame:_routeGlass.bounds];
    _route.tintColor = UIColor.whiteColor; _route.activeTintColor = MusicPink();
    if ([_route respondsToSelector:@selector(setPrioritizesVideoDevices:)]) _route.prioritizesVideoDevices = NO;
    [((UIVisualEffectView *)_routeGlass).contentView addSubview:_route];

    _lyricsBtn = XIconButton(@"quote.bubble.fill", 44, 17, YES); [_lyricsBtn addTarget:self action:@selector(toggleLyrics) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_lyricsBtn];
    _stats = XIconButton(@"chart.bar.fill", 44, 16, YES); [_stats addTarget:self action:@selector(toggleInsights) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_stats];
    _close = XIconButton(@"chevron.down", 44, 16, YES); [_close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_close];
    return self;
}
- (void)down:(UIButton *)b { [UIView animateWithDuration:0.12 animations:^{ b.transform = CGAffineTransformMakeScale(0.84, 0.84); }]; }
- (void)up:(UIButton *)b { [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.42 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil]; }
- (void)tap:(UIButton *)b {
    [self up:b];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b == _play) { XSend(2); gXPlaying = !gXPlaying; [self refresh]; }
    else {
        XSend(b == _next ? 4 : 5);
        // the cover nudges the way you skipped
        CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        CGFloat d = b == _next ? -18 : 18; k.values = @[@0, @(d), @(-d * 0.25), @0]; k.keyTimes = @[@0, @0.3, @0.7, @1]; k.duration = 0.5; k.additive = YES;
        [_artHost.layer addAnimation:k forKey:@"skip"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ XPoll(); });
    }
}
- (void)toggleLyrics {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    _showLyrics = !_showLyrics;
    _lyricsBtn.tintColor = _showLyrics ? MusicPink() : UIColor.whiteColor;
    if (_showLyrics) { _lyrics.hidden = NO; [self loadLyrics]; }
    [UIView animateWithDuration:0.65 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self layoutSubviews];
        self->_lyrics.alpha = self->_showLyrics ? 1 : 0;
    } completion:^(__unused BOOL f) { if (!self->_showLyrics) self->_lyrics.hidden = YES; }];
}
- (void)loadLyrics {
    NSString *key = [NSString stringWithFormat:@"%@|%@", gXTitle ?: @"", gXArtist ?: @""];
    if ([key isEqualToString:_lyricsSong]) return;
    _lyricsSong = key;
    NSString *l = XLyrics(gXTitle, gXArtist);
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new]; ps.lineSpacing = 8; ps.paragraphSpacing = 14;
    if (l.length) {
        _lyrics.attributedText = [[NSAttributedString alloc] initWithString:l attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24 weight:UIFontWeightBold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.92], NSParagraphStyleAttributeName: ps}];
    } else {
        _lyrics.attributedText = [[NSAttributedString alloc] initWithString:@"No lyrics for this song.\n\nMusic only keeps lyrics for some songs in your library. Open the song's lyrics in Music once, then try again." attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.6], NSParagraphStyleAttributeName: ps}];
    }
    [_lyrics setContentOffset:CGPointZero animated:NO];
}
- (void)toggleInsights {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    if (_insights) {
        UIView *v = _insights; _insights = nil;
        [UIView animateWithDuration:0.3 animations:^{ v.alpha = 0; v.transform = CGAffineTransformMakeScale(0.96, 0.96); self->_root.alpha = 1; } completion:^(__unused BOOL f) { [v removeFromSuperview]; }];
        return;
    }
    UIVisualEffectView *panel = XGlass(30);
    CGRect b = self.bounds; UIEdgeInsets sa = self.safeAreaInsets;
    panel.frame = CGRectMake(MAX(16, sa.left), 14, b.size.width - MAX(16, sa.left) - MAX(16, sa.right), b.size.height - 14 - MAX(14, sa.bottom));
    [MPInsightsCtl buildIn:panel.contentView size:panel.bounds.size closeTarget:self action:@selector(toggleInsights)];
    [self insertSubview:panel belowSubview:_lyricsBtn];
    _insights = panel;
    panel.alpha = 0; panel.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ panel.alpha = 1; panel.transform = CGAffineTransformIdentity; self->_root.alpha = 0; } completion:nil];
}
- (void)safeAreaInsetsDidChange { [super safeAreaInsetsDidChange]; [self setNeedsLayout]; }
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect B = self.bounds; CGFloat W = B.size.width, H = B.size.height;
    UIEdgeInsets sa = self.safeAreaInsets;
    CGFloat L = MAX(24, sa.left + 8), R = MAX(24, sa.right + 8), Bot = MAX(16, sa.bottom);
    _bg.frame = B; _tint.frame = B; _root.frame = B;
    BOOL ly = _showLyrics;
    // top row: lyrics on the left; Insights and close on the right
    _lyricsBtn.center = CGPointMake(L + 22, 34);
    _close.center = CGPointMake(W - R - 22, 34);
    _stats.center = CGPointMake(W - R - 76, 34);
    // left: the cover (with lyrics: smaller, top-left, lyrics beside it)
    CGFloat leftW = W * 0.5 - L;
    CGFloat d = ly ? MIN(110, H * 0.3) : MIN(H - 70 - Bot, leftW - 10);
    CGRect af = ly ? CGRectMake(L, 64, d, d) : CGRectMake(L + (leftW - d) / 2, 60 + (H - 60 - Bot - d) / 2, d, d);
    _artHost.bounds = CGRectMake(0, 0, af.size.width, af.size.height); _artHost.center = CGPointMake(CGRectGetMidX(af), CGRectGetMidY(af));
    _artHost.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_artHost.bounds cornerRadius:ly ? 14 : 22].CGPath;
    _art.frame = _artHost.bounds; _art.layer.cornerRadius = ly ? 14 : 22;
    _lyrics.frame = CGRectMake(L + (ly ? d + 20 : 0), 54, leftW - (ly ? d + 20 : 0), H - 54 - Bot);
    CAGradientLayer *fade = (CAGradientLayer *)_lyrics.layer.mask;
    [CATransaction begin]; [CATransaction setDisableActions:YES]; fade.frame = _lyrics.bounds; [CATransaction commit];
    // right: song, progress, glass controls, volume + AirPlay
    CGFloat x = W * 0.5 + 18, rw = W - x - R;
    CGFloat top = MAX(64, (H - Bot - 270) / 2 + 18);
    _title.frame = CGRectMake(x, top, rw, 34);
    _artist.frame = CGRectMake(x, top + 36, rw, 26);
    _album.frame = CGRectMake(x, top + 63, rw, 20);
    _scrub.frame = CGRectMake(x, top + 98, rw, 22);
    _el.frame = CGRectMake(x, top + 122, 80, 16);
    _rem.frame = CGRectMake(x + rw - 80, top + 122, 80, 16);
    CGFloat cy = top + 190, cx = x + rw / 2, cw = MIN(rw, 300);
    _controls.frame = CGRectMake(cx - cw / 2, cy - 42, cw, 84);
    _controls.layer.cornerRadius = 42;
    for (CALayer *l in ((UIVisualEffectView *)_controls).contentView.layer.sublayers) if ([l isKindOfClass:[CAGradientLayer class]]) l.frame = _controls.bounds;
    _play.center = CGPointMake(cx, cy);
    _prev.center = CGPointMake(cx - cw * 0.32, cy);
    _next.center = CGPointMake(cx + cw * 0.32, cy);
    _vol.frame = CGRectMake(x, top + 252, rw - 56, 30);
    _routeGlass.frame = CGRectMake(x + rw - 44, top + 245, 44, 44);
    _route.frame = _routeGlass.bounds;
    NSArray *spots = @[[NSValue valueWithCGPoint:CGPointMake(W * 0.2, H * 0.3)], [NSValue valueWithCGPoint:CGPointMake(W * 0.78, H * 0.25)], [NSValue valueWithCGPoint:CGPointMake(W * 0.55, H * 0.9)]];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (NSUInteger i = 0; i < _blobs.count; i++) { CALayer *l = _blobs[i]; l.bounds = CGRectMake(0, 0, W * 1.1, W * 1.1); if (![l animationForKey:@"drift"]) l.position = [spots[i] CGPointValue]; }
    [CATransaction commit];
}
- (void)drift {
    for (NSUInteger i = 0; i < _blobs.count; i++) {
        CALayer *l = _blobs[i];
        [l removeAnimationForKey:@"drift"];
        CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        CGPoint p = l.position; CGFloat r = self.bounds.size.width * 0.12;
        a.values = @[[NSValue valueWithCGPoint:p], [NSValue valueWithCGPoint:CGPointMake(p.x + r, p.y - r * 0.6)], [NSValue valueWithCGPoint:CGPointMake(p.x - r * 0.7, p.y + r * 0.5)], [NSValue valueWithCGPoint:p]];
        a.duration = 14 + i * 5; a.repeatCount = HUGE_VALF; a.calculationMode = kCAAnimationCubic;
        [l addAnimation:a forKey:@"drift"];
    }
}
- (void)applyBackground {
    BOOL plain = HighContrast();   // Increase Contrast: a plain dark background, nothing moving
    _bg.hidden = plain;
    _tint.backgroundColor = plain ? [UIColor colorWithWhite:0.07 alpha:1] : [UIColor colorWithWhite:0 alpha:0.30];
    if (plain) return;
    NSArray *cols = XColorsOf(gXArt);
    for (NSUInteger i = 0; i < _blobs.count; i++) {
        CAGradientLayer *g = (CAGradientLayer *)_blobs[i];
        UIColor *c = cols[i % cols.count];
        NSArray *to = @[(id)[c colorWithAlphaComponent:0.95].CGColor, (id)[c colorWithAlphaComponent:0].CGColor];
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"colors"]; a.fromValue = g.colors ?: to; a.toValue = to; a.duration = 1.0;
        g.colors = to; [g addAnimation:a forKey:@"colors"];
    }
    if (![_blobs.firstObject animationForKey:@"drift"]) [self drift];
}
- (void)refresh {
    if (gXArt != _shownArt) {
        _shownArt = gXArt;
        [UIView transitionWithView:_art duration:0.45 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self->_art.image = gXArt; } completion:nil];
        [self applyBackground];
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
        [_play setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:34 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    }
    CGAffineTransform at = gXPlaying ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);   // the cover shrinks a little while paused
    if (!CGAffineTransformEqualToTransform(_artHost.transform, at)) [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self->_artHost.transform = at; } completion:nil];
    if (_showLyrics) {
        [self loadLyrics];
        // lyrics roll along with the song (they aren't timed, so this follows how far into the song you are)
        if (!_lyrics.isDragging && !_lyrics.isDecelerating && gXDuration > 0) {
            CGFloat maxY = MAX(0, _lyrics.contentSize.height - _lyrics.bounds.size.height);
            CGFloat want = maxY * MAX(0, MIN(1, (e - 8) / MAX(1, gXDuration - 20)));
            if (fabs(_lyrics.contentOffset.y - want) > 1) [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction animations:^{ self->_lyrics.contentOffset = CGPointMake(0, want); } completion:nil];
        }
    }
}
- (void)placeIn:(UIWindow *)w turn:(UIDeviceOrientation)o {
    // normally Music has turned for real; if it didn't, turn just our view (old way)
    CGRect wb = w.bounds;
    self.transform = CGAffineTransformIdentity;
    if (wb.size.width >= wb.size.height) { self.frame = wb; }
    else {
        self.bounds = CGRectMake(0, 0, wb.size.height, wb.size.width);
        self.center = CGPointMake(CGRectGetMidX(wb), CGRectGetMidY(wb));
        self.transform = CGAffineTransformMakeRotation(o == UIDeviceOrientationLandscapeRight ? -M_PI_2 : M_PI_2);
    }
    [self setNeedsLayout];
}
- (void)showIn:(UIWindow *)w turn:(UIDeviceOrientation)o {
    if (self.superview == w) { [self placeIn:w turn:o]; return; }
    [self removeFromSuperview];
    [w addSubview:self];
    [self placeIn:w turn:o];
    XPoll();
    _shownArt = nil;
    [self setNeedsLayout]; [self layoutIfNeeded];
    [self refresh];
    CGAffineTransform rest = self.transform;
    self.alpha = 0; self.transform = CGAffineTransformScale(rest, 1.06, 1.06);
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{ self.alpha = 1; self.transform = rest; } completion:nil];
    // contents arrive one after another
    NSArray *parts = @[_artHost, _title, _artist, _album, _scrub, _controls, _vol, _routeGlass];
    for (NSUInteger i = 0; i < parts.count; i++) {
        UIView *v = parts[i]; CGAffineTransform keep = v.transform;
        v.alpha = 0; v.transform = CGAffineTransformConcat(keep, CGAffineTransformMakeTranslation(0, 16));
        [UIView animateWithDuration:0.6 delay:0.08 + i * 0.035 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ v.alpha = 1; v.transform = keep; } completion:nil];
    }
    for (UIButton *b in @[_prev, _play, _next]) { b.alpha = 0; [UIView animateWithDuration:0.4 delay:0.3 options:0 animations:^{ b.alpha = 1; } completion:nil]; }
    if (!_timer) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.25 * NSEC_PER_SEC), (uint64_t)(0.05 * NSEC_PER_SEC));
        __weak MPLandscape *ws = self;
        dispatch_source_set_event_handler(_timer, ^{ @try { [ws refresh]; } @catch (__unused id e) {} });
        dispatch_resume(_timer);
    }
}
- (void)closeTapped {
    UIWindow *w = self.window;
    gLSActive = NO;
    [self hide];
    if (w) XRequestOrientationFwd(w, UIInterfaceOrientationMaskPortrait);
}
- (void)hide {
    if (!self.superview) return;
    if (_timer) { dispatch_source_cancel(_timer); _timer = nil; }
    if (_insights) { [_insights removeFromSuperview]; _insights = nil; _root.alpha = 1; }
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ self.alpha = 0; self.transform = CGAffineTransformScale(self.transform, 0.96, 0.96); } completion:^(__unused BOOL f) { if (!gLSActive) { [self removeFromSuperview]; self.transform = CGAffineTransformIdentity; self.alpha = 1; } }];
}
@end

#pragma mark - letting Music rotate while the landscape player is up

static UIInterfaceOrientationMask (*origAppMask)(id, SEL, id, id);
static UIInterfaceOrientationMask AppMask(id self, SEL _cmd, id app, id w) {
    if (gLSActive) return UIInterfaceOrientationMaskAllButUpsideDown;
    return origAppMask ? origAppMask(self, _cmd, app, w) : UIInterfaceOrientationMaskPortrait;
}
static UIInterfaceOrientationMask (*origVCMask)(id, SEL);
static UIInterfaceOrientationMask VCMask(id self, SEL _cmd) { return gLSActive ? UIInterfaceOrientationMaskAllButUpsideDown : origVCMask(self, _cmd); }
static BOOL (*origVCRotate)(id, SEL);
static BOOL VCRotate(id self, SEL _cmd) { return gLSActive ? YES : origVCRotate(self, _cmd); }
static BOOL (*origSBHidden)(id, SEL);
static BOOL SBHidden(id self, SEL _cmd) { return gLSActive ? YES : origSBHidden(self, _cmd); }
static id (*origChildSB)(id, SEL);
static id ChildSB(id self, SEL _cmd) { return gLSActive ? nil : origChildSB(self, _cmd); }
static NSMutableSet *gXHookedVC;
static void HookVCClass(Class c) {
    // Music's own view controllers say "portrait only" in their own code: answer for them while we're up
    if (!c) return;
    if (!gXHookedVC) gXHookedVC = [NSMutableSet set];
    for (Class k = c; k && k != [UIViewController class]; k = class_getSuperclass(k)) {
        NSString *n = NSStringFromClass(k);
        if ([gXHookedVC containsObject:n]) continue;
        [gXHookedVC addObject:n];
        unsigned int cnt = 0; Method *ms = class_copyMethodList(k, &cnt);
        for (unsigned int i = 0; i < cnt; i++) {
            SEL s = method_getName(ms[i]);
            if (s == @selector(supportedInterfaceOrientations)) {
                IMP orig = method_getImplementation(ms[i]);
                IMP rep = imp_implementationWithBlock(^UIInterfaceOrientationMask(id me) { return gLSActive ? UIInterfaceOrientationMaskAllButUpsideDown : ((UIInterfaceOrientationMask (*)(id, SEL))orig)(me, s); });
                method_setImplementation(ms[i], rep);
            } else if (s == @selector(prefersStatusBarHidden)) {
                IMP orig = method_getImplementation(ms[i]);
                IMP rep = imp_implementationWithBlock(^BOOL(id me) { return gLSActive ? YES : ((BOOL (*)(id, SEL))orig)(me, s); });
                method_setImplementation(ms[i], rep);
            }
        }
        free(ms);
    }
}
static UIInterfaceOrientationMask (*origUIAppMask)(id, SEL, id);
static UIInterfaceOrientationMask UIAppMask(id self, SEL _cmd, id w) { return gLSActive ? UIInterfaceOrientationMaskAllButUpsideDown : origUIAppMask(self, _cmd, w); }
static void InstallRotationHooks(void) {
    static BOOL done; if (done) return; done = YES;
    if ([UIApplication instancesRespondToSelector:@selector(supportedInterfaceOrientationsForWindow:)])
        MSHookMessageEx([UIApplication class], @selector(supportedInterfaceOrientationsForWindow:), (IMP)UIAppMask, (IMP *)&origUIAppMask);
    MSHookMessageEx([UIViewController class], @selector(supportedInterfaceOrientations), (IMP)VCMask, (IMP *)&origVCMask);
    MSHookMessageEx([UIViewController class], @selector(shouldAutorotate), (IMP)VCRotate, (IMP *)&origVCRotate);
    MSHookMessageEx([UIViewController class], @selector(prefersStatusBarHidden), (IMP)SBHidden, (IMP *)&origSBHidden);
    MSHookMessageEx([UIViewController class], @selector(childViewControllerForStatusBarHidden), (IMP)ChildSB, (IMP *)&origChildSB);
    id del = UIApplication.sharedApplication.delegate;
    SEL ms = @selector(application:supportedInterfaceOrientationsForWindow:);
    if (del && [del respondsToSelector:ms]) MSHookMessageEx([del class], ms, (IMP)AppMask, (IMP *)&origAppMask);
    else if (del) class_addMethod([del class], ms, (IMP)AppMask, "Q@:@@");
}
static void XRequestOrientation(UIWindow *w, UIInterfaceOrientationMask mask) {
    UIViewController *rv = w.rootViewController;
    HookVCClass(rv.class);
    for (UIViewController *p = rv.presentedViewController; p; p = p.presentedViewController) HookVCClass(p.class);
    if (@available(iOS 16.0, *)) {
        [rv setNeedsUpdateOfSupportedInterfaceOrientations];
        for (UIViewController *p = rv.presentedViewController; p; p = p.presentedViewController) [p setNeedsUpdateOfSupportedInterfaceOrientations];
        UIWindowScene *sc = w.windowScene;
        if (sc) {
            UIWindowSceneGeometryPreferencesIOS *pref = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:mask];
            [sc requestGeometryUpdateWithPreferences:pref errorHandler:^(__unused NSError *e) {}];
        }
    } else {
        [UIViewController attemptRotationToDeviceOrientation];
    }
    [rv setNeedsStatusBarAppearanceUpdate];
    if ([rv respondsToSelector:@selector(setNeedsUpdateOfHomeIndicatorAutoHidden)]) [rv setNeedsUpdateOfHomeIndicatorAutoHidden];
}

static void XRequestOrientationFwd(UIWindow *w, UIInterfaceOrientationMask mask) { XRequestOrientation(w, mask); }
@interface MPOrient : NSObject @end
@implementation MPOrient
+ (void)changed:(NSNotification *)n {
    UIWindow *w = gLastTabBar.window ?: UIApplication.sharedApplication.keyWindow;
    if (!gLandscape || !gRound || !w) {
        if (gLSActive) { gLSActive = NO; [[MPLandscape shared] hide]; if (w) XRequestOrientation(w, UIInterfaceOrientationMaskPortrait); }
        return;
    }
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    UIDeviceOrientation o = UIDevice.currentDevice.orientation;
    if (UIDeviceOrientationIsLandscape(o)) {
        InstallRotationHooks();
        BOOL was = gLSActive;
        gLSActive = YES;
        XRequestOrientation(w, o == UIDeviceOrientationLandscapeLeft ? UIInterfaceOrientationMaskLandscapeRight : UIInterfaceOrientationMaskLandscapeLeft);
        // show once Music has turned (bounds are wide); keep it laid out to the window after that
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((was ? 0.05 : 0.12) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (gLSActive) [[MPLandscape shared] showIn:w turn:o]; });
        // the turn can finish a moment later: fit again once it has
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (gLSActive) [[MPLandscape shared] showIn:w turn:o]; });
    } else if (o == UIDeviceOrientationPortrait && gLSActive) {
        gLSActive = NO;
        [[MPLandscape shared] hide];
        XRequestOrientation(w, UIInterfaceOrientationMaskPortrait);
    }
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
