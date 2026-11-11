// ===================== MusicPill: Dynamic Pill extras =====================
// - Hold to peek: hold the pill and it grows a little (like holding the Dynamic Island): cover, song,
//   a live lyric line and the time bar. Let go and it shrinks back. (With Dynamic Pill on.)
// - Song change splash: a new song makes the pill grow for a moment with the big cover and title. (Switch.)
// - Share card: a story-size picture of what you're playing, from Insights' share button.
// Included from Tweak.x after Landscape.h.

#pragma mark - shared bits

// a full-window holder that only keeps touches on what's inside it
@interface MPPassView : UIView
@end
@implementation MPPassView
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { UIView *h = [super hitTest:p withEvent:e]; return h == self ? nil : h; }
@end

static CGRect XPillOnScreen(UIView **outPill) {
    MPMiniPill *pill = (MPMiniPill *)gPillObj;
    UIView *v = ([pill isKindOfClass:[MPMiniPill class]] && pill.window && !pill.hidden && pill.alpha > 0.05) ? pill : nil;
    if (!v) { UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil; if (mini.window && mini.alpha > 0.05) v = mini; }
    if (outPill) *outPill = v;
    return v ? [v convertRect:v.bounds toView:v.window] : CGRectZero;
}
// a dark island shape like the Dynamic Pill's
static UIView *XIslandShape(CGRect f) {
    UIView *shape = [[UIView alloc] initWithFrame:f];
    shape.clipsToBounds = YES; shape.layer.cornerCurve = kCACornerCurveContinuous; shape.layer.cornerRadius = f.size.height / 2;
    shape.layer.borderWidth = 0.8; shape.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    shape.userInteractionEnabled = NO;
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark]];
    blur.frame = shape.bounds; blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [shape addSubview:blur];
    UIView *ink = [[UIView alloc] initWithFrame:shape.bounds];
    ink.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55]; ink.autoresizingMask = blur.autoresizingMask;
    [shape addSubview:ink];
    return shape;
}
// grow out of the pill into `to`, contents fade in; returns the shape (inside a full-window holder)
static UIView *XGrowFromPill(UIView *pill, CGRect to, UIView *content, UIView **outShape) {
    UIWindow *w = pill.window; if (!w) return nil;
    CGRect from = [pill convertRect:pill.bounds toView:w];
    UIView *holder = [[MPPassView alloc] initWithFrame:w.bounds];
    holder.userInteractionEnabled = NO;
    UIView *shape = XIslandShape(from);
    UIView *snap = [pill snapshotViewAfterScreenUpdates:NO];
    if (snap) { snap.frame = shape.bounds; snap.tag = 0x534E; snap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; [shape addSubview:snap]; }
    content.frame = CGRectMake(0, 0, to.size.width, to.size.height);
    content.center = CGPointMake(from.size.width / 2, from.size.height / 2);
    content.alpha = 0; content.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [shape addSubview:content];
    [holder addSubview:shape];
    [w addSubview:holder];
    [UIView animateWithDuration:0.46 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        shape.frame = to; shape.layer.cornerRadius = MIN(34, to.size.height / 2);
        content.center = CGPointMake(to.size.width / 2, to.size.height / 2);
        content.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:0.1 animations:^{ snap.alpha = 0; }];
    [UIView animateWithDuration:0.16 delay:0.03 options:UIViewAnimationOptionCurveEaseOut animations:^{ content.alpha = 1; } completion:nil];
    if (outShape) *outShape = shape;
    return holder;
}
// shrink back onto the pill (fresh picture of it fades in), then gone
static void XShrinkToPill(UIView *holder, UIView *shape, UIView *content, UIView *pill) {
    if (!holder.superview) return;
    CGRect to = pill.window ? [pill convertRect:pill.bounds toView:holder] : shape.frame;
    CALayer *pl = shape.layer.presentationLayer;
    CGRect cur = pl ? pl.frame : shape.frame;
    [shape.layer removeAllAnimations]; shape.frame = cur;
    [[shape viewWithTag:0x534E] removeFromSuperview];
    UIView *snap = pill.window ? [pill snapshotViewAfterScreenUpdates:NO] : nil;
    if (snap) {
        snap.alpha = 0; snap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        snap.frame = CGRectMake((cur.size.width - to.size.width) / 2, cur.size.height - to.size.height, to.size.width, to.size.height);
        [shape addSubview:snap];
    }
    [UIView animateWithDuration:0.1 animations:^{ content.alpha = 0; content.transform = CGAffineTransformMakeScale(0.94, 0.94); }];
    CGRect mid = CGRectMake(cur.origin.x, CGRectGetMinY(to), cur.size.width, to.size.height);
    [UIView animateWithDuration:0.36 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        shape.frame = mid; shape.layer.cornerRadius = to.size.height / 2;
        content.center = CGPointMake(mid.size.width / 2, mid.size.height / 2);
    } completion:nil];
    [UIView animateWithDuration:0.42 delay:0.04 usingSpringWithDamping:0.76 initialSpringVelocity:0 options:0 animations:^{
        shape.frame = to;
        content.center = CGPointMake(to.size.width / 2, to.size.height / 2);
    } completion:^(__unused BOOL f) { [holder removeFromSuperview]; }];
    [UIView animateWithDuration:0.14 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{ snap.alpha = 1; } completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [holder removeFromSuperview]; });
}
// the size an expanded pill gets: from the pill's bottom, at least a comfortable width, on screen
static CGRect XExpandRect(CGRect pr, CGFloat H) {
    CGFloat SW = UIScreen.mainScreen.bounds.size.width;
    CGFloat W = MIN(SW - 16, MAX(pr.size.width + 12, MIN(360, SW - 32)));
    CGFloat x = MAX(8, MIN(SW - 8 - W, CGRectGetMidX(pr) - W / 2));
    return CGRectMake(x, CGRectGetMaxY(pr) - H + 2, W, H);
}
static CFTimeInterval gPeekBlockUntil;   // while peeking (and just after), Music may not open the player
static BOOL XPillBusy(void) {
    UIWindow *w = gLastTabBar.window;
    if (!w || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return YES;
    if (gIsland.window || [MPLandscape shared].superview) return YES;
    UIViewController *pp = PresentedPlayer(w.rootViewController);
    return pp != nil && !pp.isBeingDismissed;
}

#pragma mark - hold to peek

@interface MPPeek : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation MPPeek {
    UIView *_holder, *_shape, *_content;
    __weak UIView *_pill;
    UILabel *_title, *_artist, *_lyric, *_el, *_rem;
    UIImageView *_art;
    UIView *_track, *_fill;
    dispatch_source_t _timer;
    MPLyrics *_lyrics; NSString *_lyricsKey; NSInteger _line;
    NSHashTable *_paused;
}
+ (instancetype)shared { static MPPeek *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPPeek new]; }); return s; }
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g { return gPillHold && gRound && !XPillBusy(); }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return NO; }
// Music's own hold menu waits while we peek
- (void)pauseMusicMenu:(UIView *)near pause:(BOOL)p {
    if (p) {
        _paused = [NSHashTable weakObjectsHashTable];
        UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
        for (UIView *root in @[mini ?: (id)NSNull.null, near ?: (id)NSNull.null]) {
            if (![root isKindOfClass:[UIView class]]) continue;
            NSMutableArray *st = [NSMutableArray arrayWithObject:root]; int g = 0;
            while (st.count && g++ < 200) {
                UIView *v = st.lastObject; [st removeLastObject];
                for (UIGestureRecognizer *r in v.gestureRecognizers) {
                    if (!r.enabled || r.delegate == (id)self) continue;
                    r.enabled = NO; [_paused addObject:r];   // taps, Music's hold menu, our swipe: all wait
                }
                [st addObjectsFromArray:v.subviews];
            }
        }
    } else {
        for (UIGestureRecognizer *r in [_paused allObjects]) r.enabled = YES;
        [_paused removeAllObjects];
    }
}
- (void)held:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) [self open];
    else if (g.state >= UIGestureRecognizerStateEnded) [self close];
}
- (void)open {
    if (_holder) return;
    UIView *pill = nil; CGRect pr = XPillOnScreen(&pill);
    if (!pill || pr.size.width < 50) return;
    [self pauseMusicMenu:pill pause:YES];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    _pill = pill;
    CGFloat H = 158;
    CGRect to = XExpandRect(pr, H); CGFloat W = to.size.width;
    gPeekBlockUntil = CACurrentMediaTime() + 3600;
    UIView *c = [UIView new];
    _art = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 64, 64)];
    _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES; _art.layer.cornerRadius = 12; _art.layer.cornerCurve = kCACornerCurveContinuous;
    _art.image = gXArt; [c addSubview:_art];
    _title = XLabel(gXTitle ?: @"", 17, UIFontWeightBold, nil); _title.frame = CGRectMake(92, 18, W - 108, 22); _title.adjustsFontSizeToFitWidth = NO; _title.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:_title];
    _artist = XLabel(gXArtist ?: @"", 14, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]); _artist.frame = CGRectMake(92, 40, W - 108, 18); _artist.adjustsFontSizeToFitWidth = NO; _artist.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:_artist];
    _lyric = XLabel(gXAlbum ?: @"", 14, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.85]); _lyric.frame = CGRectMake(92, 60, W - 108, 20); _lyric.adjustsFontSizeToFitWidth = NO; _lyric.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:_lyric];
    _el = XLabel(@"0:00", 12, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); _el.frame = CGRectMake(16, H - 44, 50, 14); [c addSubview:_el];
    _rem = XLabel(@"-0:00", 12, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); _rem.textAlignment = NSTextAlignmentRight; _rem.frame = CGRectMake(W - 66, H - 44, 50, 14); [c addSubview:_rem];
    _track = [[UIView alloc] initWithFrame:CGRectMake(16, H - 26, W - 32, 6)]; _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22]; _track.layer.cornerRadius = 3; _track.clipsToBounds = YES; [c addSubview:_track];
    _fill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 6)]; _fill.backgroundColor = UIColor.whiteColor; [_track addSubview:_fill];
    _content = c;
    UIView *shape = nil;
    _holder = XGrowFromPill(pill, to, c, &shape);
    _shape = shape;
    _line = -2;
    [self loadLyrics];
    [self tick];
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.2 * NSEC_PER_SEC), (uint64_t)(0.03 * NSEC_PER_SEC));
    __weak MPPeek *ws = self;
    dispatch_source_set_event_handler(_timer, ^{ @try { [ws tick]; } @catch (__unused id e) {} });
    dispatch_resume(_timer);
}
- (void)loadLyrics {
    NSString *key = [NSString stringWithFormat:@"%@|%@", gXTitle ?: @"", gXArtist ?: @""];
    if ([key isEqualToString:_lyricsKey]) return;
    _lyricsKey = key; _lyrics = nil; _line = -2;
    __weak MPPeek *ws = self;
    XFetchLyrics(gXTitle, gXArtist, gXAlbum, gXDuration, ^(MPLyrics *l) {
        MPPeek *s = ws; if (!s || ![key isEqualToString:s->_lyricsKey]) return;
        s->_lyrics = l.times.count ? l : nil;   // only timed lyrics can follow the song
        s->_line = -2;
        [s tick];
    });
}
- (void)tick {
    if (!_holder) return;
    double e = XElapsedNow(), D = gXDuration;
    _el.text = XTime(e); _rem.text = [@"-" stringByAppendingString:XTime(MAX(0, D - e))];
    _fill.frame = CGRectMake(0, 0, _track.bounds.size.width * (D > 0 ? MAX(0, MIN(1, e / D)) : 0), 6);
    if (_art.image != gXArt) _art.image = gXArt;
    if (![_title.text isEqualToString:gXTitle ?: @""]) { _title.text = gXTitle ?: @""; _artist.text = gXArtist ?: @""; [self loadLyrics]; }
    // the line being sung right now (or the album when there are no timed lyrics)
    NSInteger cur = -1;
    for (NSUInteger i = 0; i < _lyrics.times.count; i++) { if ([_lyrics.times[i] doubleValue] <= e + 0.25) cur = i; else break; }
    if (cur == _line) return;
    _line = cur;
    NSString *t = !_lyrics ? (gXAlbum ?: @"") : (cur >= 0 ? _lyrics.lines[cur] : @"♪");
    UILabel *l = _lyric;
    [UIView transitionWithView:l duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ l.text = t; l.textColor = self->_lyrics ? UIColor.whiteColor : [UIColor colorWithWhite:1 alpha:0.6]; } completion:nil];
}
- (void)close {
    gPeekBlockUntil = CACurrentMediaTime() + 0.45;
    if (_timer) { dispatch_source_cancel(_timer); _timer = nil; }
    [self pauseMusicMenu:nil pause:NO];
    UIView *h = _holder, *s = _shape, *c = _content, *p = _pill;
    _holder = nil; _shape = nil; _content = nil;
    if (h) XShrinkToPill(h, s, c, p);
}
@end
static void AddPeek(UIView *v) {
    static const void *kPeek = &kPeek;
    if (!v || objc_getAssociatedObject(v, kPeek)) return;
    objc_setAssociatedObject(v, kPeek, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[MPPeek shared] action:@selector(held:)];
    lp.minimumPressDuration = 0.25; lp.allowableMovement = 14; lp.cancelsTouchesInView = YES;
    lp.delegate = [MPPeek shared];
    [v addGestureRecognizer:lp];
}

#pragma mark - song change splash

@interface MPSplash : NSObject
+ (instancetype)shared;
- (void)show;
@end
@implementation MPSplash {
    UIView *_holder, *_shape, *_content; __weak UIView *_pill;
    CADisplayLink *_link; CGRect _lastPill; CGFloat _H;
    NSUInteger _gen;
    BOOL _compact;                 // the pill is minimized: the bubble version
    UIImageView *_art; CAGradientLayer *_glow; UIImage *_shownArt;
}
// minimized pill: a floating bubble above the bar, centered on the screen
static CGRect XSplashBubbleRect(CGRect pr) {
    CGFloat SW = UIScreen.mainScreen.bounds.size.width, W = MIN(SW - 32, 300), H = 64;
    return CGRectMake(round((SW - W) / 2), CGRectGetMinY(pr) - 12 - H, W, H);
}
+ (instancetype)shared { static MPSplash *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPSplash new]; }); return s; }
- (BOOL)up { return _holder.superview != nil; }
- (void)show {
    UIView *pill = nil; CGRect pr = XPillOnScreen(&pill);
    if (!pill || pr.size.width < 30 || XPillBusy() || [self up]) return;
    if (gCollapsed) { [self showBubble:pill rect:pr]; return; }
    _compact = NO;
    _H = 112;
    CGRect to = XExpandRect(pr, _H); CGFloat W = to.size.width;
    UIView *c = [UIView new];
    UIImageView *art = [[UIImageView alloc] initWithFrame:CGRectMake(14, 14, 84, 84)];
    art.image = gXArt; art.contentMode = UIViewContentModeScaleAspectFill; art.clipsToBounds = YES;
    art.layer.cornerRadius = 16; art.layer.cornerCurve = kCACornerCurveContinuous;
    [c addSubview:art];
    if (!art.image) { art.image = [UIImage systemImageNamed:@"music.note"]; art.contentMode = UIViewContentModeCenter; art.tintColor = [UIColor colorWithWhite:1 alpha:0.6]; art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1]; }
    _art = art; _shownArt = gXArt;
    // a soft glow of the cover's color behind everything
    CAGradientLayer *glow = [CAGradientLayer layer]; glow.type = kCAGradientLayerRadial;
    UIColor *gc = XColorsOf(gXArt).firstObject ?: MusicPink();
    glow.colors = @[(id)[gc colorWithAlphaComponent:0.55].CGColor, (id)[gc colorWithAlphaComponent:0].CGColor];
    glow.startPoint = CGPointMake(0.15, 0.5); glow.endPoint = CGPointMake(0.9, 1.4);
    glow.frame = CGRectMake(0, 0, W, _H);
    [c.layer insertSublayer:glow atIndex:0];
    _glow = glow;
    MPWave *wave = [[MPWave alloc] initWithFrame:CGRectMake(112, 20, 22, 16)]; wave.backgroundColor = UIColor.clearColor; [c addSubview:wave]; [wave setPlaying:YES];
    UILabel *k = XLabel(@"NOW PLAYING", 11, UIFontWeightBold, MusicPink()); k.frame = CGRectMake(138, 21, W - 152, 14); [c addSubview:k];
    UILabel *t = XLabel(gXTitle ?: @"", 19, UIFontWeightBold, nil); t.frame = CGRectMake(112, 40, W - 126, 24); t.adjustsFontSizeToFitWidth = NO; t.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:t];
    UILabel *a = XLabel(gXArtist ?: @"", 15, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]); a.frame = CGRectMake(112, 64, W - 126, 20); a.adjustsFontSizeToFitWidth = NO; a.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:a];
    // the words come in one after another, from the right
    NSArray *slide = @[k, t, a];
    for (NSUInteger i = 0; i < slide.count; i++) {
        UIView *v = slide[i]; v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(18, 0);
        [UIView animateWithDuration:0.5 delay:0.12 + i * 0.05 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
    }
    UIView *shape = nil;
    UIView *h = XGrowFromPill(pill, to, c, &shape);
    if (!h) return;
    _holder = h; _shape = shape; _content = c; _pill = pill; _lastPill = pr;
    // tap it to open the player
    h.userInteractionEnabled = YES; shape.userInteractionEnabled = YES;
    [shape addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)]];
    UIView *pass = [[UIView alloc] initWithFrame:h.bounds]; (void)pass;
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values = @[@0.7, @1.08, @0.97, @1]; pop.keyTimes = @[@0, @0.45, @0.75, @1]; pop.duration = 0.5; pop.beginTime = CACurrentMediaTime() + 0.08;
    pop.fillMode = kCAFillModeBackwards;
    [art.layer addAnimation:pop forKey:@"pop"];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
    [_link invalidate];
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(follow)];
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    NSUInteger g = ++_gen;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (self->_gen == g) [self hide]; });
}
// 1.4.6: minimized pill: a bubble lifts off the little pill, floats up and opens wide above the bar;
// the cover spins in, the words slide up. Going away it does the same backwards and drops back in.
- (void)showBubble:(UIView *)pill rect:(CGRect)pr {
    UIWindow *w = pill.window; if (!w) return;
    _compact = YES; _H = 64;
    CGRect to = XSplashBubbleRect(pr); CGFloat W = to.size.width, H = to.size.height;
    UIView *holder = [[MPPassView alloc] initWithFrame:w.bounds]; holder.userInteractionEnabled = NO;
    CGFloat d = MIN(pr.size.height, pr.size.width);
    CGRect seed = CGRectMake(CGRectGetMidX(pr) - d / 2, CGRectGetMidY(pr) - d / 2, d, d);
    UIView *shape = XIslandShape(seed);
    shape.layer.cornerRadius = d / 2;
    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, H)];
    c.alpha = 0;
    CAGradientLayer *glow = [CAGradientLayer layer]; glow.type = kCAGradientLayerRadial;
    UIColor *gc = XColorsOf(gXArt).firstObject ?: MusicPink();
    glow.colors = @[(id)[gc colorWithAlphaComponent:0.6].CGColor, (id)[gc colorWithAlphaComponent:0].CGColor];
    glow.startPoint = CGPointMake(0.08, 0.5); glow.endPoint = CGPointMake(0.75, 1.6); glow.frame = c.bounds;
    [c.layer addSublayer:glow]; _glow = glow;
    UIImageView *art = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 44, 44)];
    art.image = gXArt; art.contentMode = UIViewContentModeScaleAspectFill; art.clipsToBounds = YES;
    art.layer.cornerRadius = 22;
    if (!art.image) { art.image = [UIImage systemImageNamed:@"music.note"]; art.contentMode = UIViewContentModeCenter; art.tintColor = [UIColor colorWithWhite:1 alpha:0.6]; art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1]; }
    [c addSubview:art]; _art = art; _shownArt = gXArt;
    UILabel *t = XLabel(gXTitle ?: @"", 16, UIFontWeightBold, nil); t.frame = CGRectMake(64, 13, W - 64 - 44, 20); t.adjustsFontSizeToFitWidth = NO; t.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:t];
    UILabel *a = XLabel(gXArtist ?: @"", 13, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]); a.frame = CGRectMake(64, 33, W - 64 - 44, 17); a.adjustsFontSizeToFitWidth = NO; a.lineBreakMode = NSLineBreakByTruncatingTail; [c addSubview:a];
    MPWave *wave = [[MPWave alloc] initWithFrame:CGRectMake(W - 36, 24, 22, 16)]; wave.backgroundColor = UIColor.clearColor; [c addSubview:wave]; [wave setPlaying:YES];
    c.center = CGPointMake(d / 2, d / 2);
    [shape addSubview:c];
    [holder addSubview:shape]; [w addSubview:holder];
    _holder = holder; _shape = shape; _content = c; _pill = pill; _lastPill = pr;
    holder.userInteractionEnabled = YES; shape.userInteractionEnabled = YES;
    [shape addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)]];
    // 1. the bubble lifts off the pill
    CGRect lift = CGRectMake(CGRectGetMidX(pr) - H * 0.42, CGRectGetMidY(to) - H * 0.42, H * 0.84, H * 0.84);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        shape.frame = lift; shape.layer.cornerRadius = lift.size.height / 2;
        c.center = CGPointMake(lift.size.width / 2, lift.size.height / 2);
    } completion:^(__unused BOOL f) {
        // 2. it opens wide with a little overshoot
        [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            shape.frame = to; shape.layer.cornerRadius = H / 2;
            c.center = CGPointMake(W / 2, H / 2);
        } completion:nil];
        [UIView animateWithDuration:0.2 delay:0.05 options:0 animations:^{ c.alpha = 1; } completion:nil];
    }];
    // the cover spins in, the words rise
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spin.fromValue = @(-M_PI * 0.9); spin.toValue = @0; spin.duration = 0.75; spin.beginTime = CACurrentMediaTime() + 0.18;
    spin.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0.9 :0.25 :1]; spin.fillMode = kCAFillModeBackwards;
    [art.layer addAnimation:spin forKey:@"spin"];
    for (NSUInteger i = 0; i < 2; i++) {
        UIView *v = i ? a : t; v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(0, 10);
        [UIView animateWithDuration:0.5 delay:0.3 + i * 0.06 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
    [_link invalidate];
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(follow)];
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    NSUInteger g = ++_gen;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (self->_gen == g) [self hide]; });
}
// the cover can arrive a moment after the song changes: swap it in with a crossfade
- (void)updateArt {
    if (!_art || !gXArt || gXArt == _shownArt) return;
    _shownArt = gXArt;
    UIImageView *art = _art;
    [UIView transitionWithView:art duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        art.image = gXArt; art.contentMode = UIViewContentModeScaleAspectFill; art.backgroundColor = nil;
    } completion:nil];
    UIColor *gc = XColorsOf(gXArt).firstObject ?: MusicPink();
    _glow.colors = @[(id)[gc colorWithAlphaComponent:_compact ? 0.6 : 0.55].CGColor, (id)[gc colorWithAlphaComponent:0].CGColor];
}
// the pill minimizes / expands while you scroll: the splash moves with it, and anything that covers the pill closes it
- (void)follow {
    if (!_holder.superview) { [_link invalidate]; _link = nil; return; }
    if (XPillBusy()) { [self hide]; return; }
    UIView *pill = nil; CGRect pr = XPillOnScreen(&pill);
    if (!pill) { [self hide]; return; }
    [self updateArt];
    if (_compact != gCollapsed) { [self hide]; return; }   // the pill changed mode: this splash's shape no longer fits
    if (pill != _pill) _pill = pill;
    if (fabs(CGRectGetMaxY(pr) - CGRectGetMaxY(_lastPill)) < 0.5 && fabs(CGRectGetMidX(pr) - CGRectGetMidX(_lastPill)) < 0.5 && fabs(pr.size.width - _lastPill.size.width) < 0.5) return;
    _lastPill = pr;
    CGRect to = _compact ? XSplashBubbleRect(pr) : XExpandRect(pr, _H);
    UIView *shape = _shape, *c = _content;
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        shape.frame = to;
        c.center = CGPointMake(to.size.width / 2, to.size.height / 2);
    } completion:nil];
}
- (void)tapped {
    UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
    [self hide];
    if (mini) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ OpenPlayer(mini); });
}
- (void)hide {
    _gen++;
    [_link invalidate]; _link = nil;
    UIView *h = _holder, *s = _shape, *c = _content, *p = _pill;
    _holder = nil; _shape = nil; _content = nil; _art = nil; _glow = nil;
    if (!h) return;
    h.userInteractionEnabled = NO;
    if (!_compact) { XShrinkToPill(h, s, c, p); return; }
    CALayer *pl = s.layer.presentationLayer; CGRect cur = pl ? pl.frame : s.frame;
    [s.layer removeAllAnimations]; s.frame = cur;
    CGRect pr = p.window ? [p convertRect:p.bounds toView:h] : cur;
    CGFloat H = cur.size.height;
    CGRect ball = CGRectMake(CGRectGetMidX(pr) - H * 0.42, CGRectGetMidY(cur) - H * 0.42, H * 0.84, H * 0.84);
    CGFloat d = MIN(pr.size.height, pr.size.width);
    CGRect drop = CGRectMake(CGRectGetMidX(pr) - d / 2, CGRectGetMidY(pr) - d / 2, d, d);
    [UIView animateWithDuration:0.14 animations:^{ c.alpha = 0; }];
    [UIView animateWithDuration:0.34 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:0 animations:^{
        s.frame = ball; s.layer.cornerRadius = ball.size.height / 2;
        c.center = CGPointMake(ball.size.width / 2, ball.size.height / 2);
    } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            s.frame = drop; s.layer.cornerRadius = d / 2; s.alpha = 0;
        } completion:^(__unused BOOL f2) { [h removeFromSuperview]; }];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [h removeFromSuperview]; });
}
@end
static NSString *gSplashLast;
static CFTimeInterval gSplashChangedAt;
static UIImage *gSplashArtAtChange;
// 1.4.6: right away. The splash comes up as soon as the new song's name is in; it waits at most a
// moment for the new cover (and swaps it in live if it's later than that).
static void SplashTick(void) {
    if (!gSplashPref || !gRound) { gSplashLast = gXTitle; return; }
    NSString *now = gXTitle.length ? [NSString stringWithFormat:@"%@|%@", gXTitle, gXArtist ?: @""] : nil;
    if (!now) return;
    if (!gSplashLast) { gSplashLast = now; return; }   // not when Music opens
    if (![now isEqualToString:gSplashLast]) {
        gSplashLast = now; gSplashChangedAt = CACurrentMediaTime(); gSplashArtAtChange = gXArt;
        if ([[MPSplash shared] up]) [[MPSplash shared] hide];   // a quicker skip: the old one goes first
    }
    if (gSplashChangedAt <= 0) return;
    BOOL artIn = gXArt && gXArt != gSplashArtAtChange;
    CFTimeInterval waited = CACurrentMediaTime() - gSplashChangedAt;
    if ([[MPSplash shared] up] && waited < 0.3) return;   // the old one is still going away
    if (artIn || waited > 0.25) {
        gSplashChangedAt = 0;
        [[MPSplash shared] show];
    }
}
// MediaRemote tells us the moment the song changes; ask for the new info and check quickly a few times
static void SplashKick(void) {
    XPoll();
    for (NSNumber *d in @[@0.06, @0.14, @0.26, @0.4, @0.6]) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (d.doubleValue >= 0.26) XPoll();
        SplashTick();
    });
}
static void StartSplashWatch(void) {
    static BOOL done; if (done) return; done = YES;
    void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    void (*reg)(dispatch_queue_t) = h ? (void (*)(dispatch_queue_t))dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications") : NULL;
    if (reg) reg(dispatch_get_main_queue());
    for (NSString *n in @[@"kMRMediaRemoteNowPlayingInfoDidChangeNotification", @"kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification", @"MPMusicPlayerControllerNowPlayingItemDidChangeNotification"])
        [[NSNotificationCenter defaultCenter] addObserverForName:n object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *x) { if (gSplashPref) SplashKick(); }];
    @try { [[MPMusicPlayerController systemMusicPlayer] beginGeneratingPlaybackNotifications]; } @catch (__unused id e) {}
}

#pragma mark - share card (story size)

static UIImage *MakeShareCard(void) {
    CGSize S = CGSizeMake(1080, 1920);
    NSArray *cols = XColorsOf(gXArt);
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat]; fmt.scale = 1;
    return [[[UIGraphicsImageRenderer alloc] initWithSize:S format:fmt] imageWithActions:^(UIGraphicsImageRendererContext *rc) {
        CGContextRef ctx = rc.CGContext;
        [[UIColor colorWithWhite:0.04 alpha:1] setFill]; CGContextFillRect(ctx, CGRectMake(0, 0, S.width, S.height));
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGPoint spots[3] = {{220, 420}, {900, 760}, {420, 1600}};
        for (int i = 0; i < 3; i++) {
            UIColor *c = cols[i % cols.count];
            CGFloat comps[8]; [c getRed:&comps[0] green:&comps[1] blue:&comps[2] alpha:&comps[3]];
            comps[3] = 0.9; comps[4] = comps[0]; comps[5] = comps[1]; comps[6] = comps[2]; comps[7] = 0;
            CGGradientRef gr = CGGradientCreateWithColorComponents(cs, comps, (CGFloat[]){0, 1}, 2);
            CGContextDrawRadialGradient(ctx, gr, spots[i], 0, spots[i], 1000, 0);
            CGGradientRelease(gr);
        }
        CGColorSpaceRelease(cs);
        [[UIColor colorWithWhite:0 alpha:0.25] setFill]; CGContextFillRect(ctx, CGRectMake(0, 0, S.width, S.height));
        // the cover, big, with a soft shadow
        CGRect ar = CGRectMake(150, 430, 780, 780);
        CGContextSaveGState(ctx);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 40), 90, [UIColor colorWithWhite:0 alpha:0.55].CGColor);
        [[UIColor blackColor] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:ar cornerRadius:56] fill];
        CGContextRestoreGState(ctx);
        CGContextSaveGState(ctx);
        [[UIBezierPath bezierPathWithRoundedRect:ar cornerRadius:56] addClip];
        [gXArt drawInRect:ar];
        CGContextRestoreGState(ctx);
        NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new]; ps.alignment = NSTextAlignmentCenter; ps.lineBreakMode = NSLineBreakByTruncatingTail;
        [@"LISTENING TO" drawInRect:CGRectMake(80, 300, 920, 50) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:36 weight:UIFontWeightBold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.7], NSParagraphStyleAttributeName: ps, NSKernAttributeName: @4}];
        [(gXTitle ?: @"") drawInRect:CGRectMake(80, 1280, 920, 90) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:68 weight:UIFontWeightHeavy], NSForegroundColorAttributeName: UIColor.whiteColor, NSParagraphStyleAttributeName: ps}];
        [(gXArtist ?: @"") drawInRect:CGRectMake(80, 1380, 920, 64) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:46 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.75], NSParagraphStyleAttributeName: ps}];
        // a glass pill with a little waveform, like the now playing pill
        CGRect pillR = CGRectMake(340, 1540, 400, 96);
        [[UIColor colorWithWhite:1 alpha:0.16] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:pillR cornerRadius:48] fill];
        [[UIColor colorWithWhite:1 alpha:0.35] setStroke];
        UIBezierPath *rim = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(pillR, 1.5, 1.5) cornerRadius:46.5]; rim.lineWidth = 3; [rim stroke];
        [UIColor.whiteColor setFill];
        CGFloat hs[9] = {20, 38, 56, 30, 64, 44, 26, 50, 22};
        for (int i = 0; i < 9; i++) [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(pillR.origin.x + 92 + i * 26, CGRectGetMidY(pillR) - hs[i] / 2, 12, hs[i]) cornerRadius:6] fill];
        [@"MusicPill" drawInRect:CGRectMake(80, 1780, 920, 44) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.45], NSParagraphStyleAttributeName: ps}];
    }];
}
static void ShareNowPlaying(UIView *from) {
    if (!gXTitle.length) return;
    UIImage *img = MakeShareCard();
    UIActivityViewController *av = [[UIActivityViewController alloc] initWithActivityItems:@[img] applicationActivities:nil];
    UIViewController *top = from.window.rootViewController;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top = top.presentedViewController;
    av.popoverPresentationController.sourceView = from;
    av.popoverPresentationController.sourceRect = from.bounds;
    [top presentViewController:av animated:YES completion:nil];
}

static void StartPeekGuard(void);
static void StartPeek(void) {
    static dispatch_source_t t;
    if (t) return;
    StartPeekGuard();
    StartSplashWatch();
    t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(t, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), (uint64_t)(0.25 * NSEC_PER_SEC), (uint64_t)(0.05 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(t, ^{
        @try {
            SplashTick();
            UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
            MPMiniPill *pill = (MPMiniPill *)gPillObj;
            if (mini && gRound) AddPeek(mini);
            if ([pill isKindOfClass:[MPMiniPill class]]) AddPeek(pill);
        } @catch (__unused id e) {}
    });
    dispatch_resume(t);
}

// while you hold to peek, Music's own hold (which opens the player) is kept from opening it
static void (*origMPPresent)(UIViewController *, SEL, UIViewController *, BOOL, id);
static void MPPresent(UIViewController *self, SEL _cmd, UIViewController *vc, BOOL anim, id completion) {
    if (CACurrentMediaTime() < gPeekBlockUntil && IsPlayerVC(vc)) return;
    origMPPresent(self, _cmd, vc, anim, completion);
}
static void StartPeekGuard(void) {
    static BOOL done; if (done) return; done = YES;
    MSHookMessageEx([UIViewController class], @selector(presentViewController:animated:completion:), (IMP)MPPresent, (IMP *)&origMPPresent);
}
