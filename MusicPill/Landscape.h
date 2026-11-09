// ===================== MusicPill landscape =====================
// Turn the phone sideways in Music and MusicPill's own full-screen player appears.
// While it shows, Music is allowed to turn for real, so iOS puts the home bar along the
// landscape bottom and hides the status bar. Turn back and it goes away.
// Lyrics: timed lyrics from LRCLIB (free lyrics database), else the ones in your library.
// Also: a smaller pill while you're on the Library tab.
// (Included from Tweak.x after Extras.h.)
#import <AVKit/AVKit.h>

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

#pragma mark - lyrics

// One song's lyrics: timed lines (times[i] seconds) or just plain text (times empty).
@interface MPLyrics : NSObject
@property (nonatomic, strong) NSArray<NSString *> *lines;
@property (nonatomic, strong) NSArray<NSNumber *> *times;
@end
@implementation MPLyrics @end

static MPLyrics *XParseLRC(NSString *lrc) {
    if (!lrc.length) return nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+):(\\d+(?:[.:]\\d+)?)\\]" options:0 error:nil];
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *raw in [lrc componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSArray *ms = [re matchesInString:raw options:0 range:NSMakeRange(0, raw.length)];
        if (!ms.count) continue;
        NSTextCheckingResult *lastM = ms.lastObject;
        NSString *text = [[raw substringFromIndex:NSMaxRange(lastM.range)] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        for (NSTextCheckingResult *m in ms) {
            double t = [[raw substringWithRange:[m rangeAtIndex:1]] doubleValue] * 60 + [[[raw substringWithRange:[m rangeAtIndex:2]] stringByReplacingOccurrencesOfString:@":" withString:@"."] doubleValue];
            [pairs addObject:@[@(t), text.length ? text : @"♪"]];
        }
    }
    if (!pairs.count) return nil;
    [pairs sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) { return [a[0] compare:b[0]]; }];
    MPLyrics *l = [MPLyrics new];
    NSMutableArray *lines = [NSMutableArray array], *times = [NSMutableArray array];
    for (NSArray *p in pairs) {
        if ([p[1] isEqualToString:@"♪"] && [lines.lastObject isEqualToString:@"♪"]) continue;
        [times addObject:p[0]]; [lines addObject:p[1]];
    }
    l.lines = lines; l.times = times;
    return l;
}
static MPLyrics *XPlainLyrics(NSString *text) {
    if (!text.length) return nil;
    NSMutableArray *lines = [NSMutableArray array];
    for (NSString *s in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *t = [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (t.length) [lines addObject:t];
    }
    if (!lines.count) return nil;
    MPLyrics *l = [MPLyrics new]; l.lines = lines; l.times = @[];
    return l;
}
// "Song (feat. X)" / "Song - Remastered 2011" -> "Song"
static NSString *XCleanTitle(NSString *t) {
    NSString *s = t ?: @"";
    for (NSString *cut in @[@" (", @" [", @" - "]) { NSRange r = [s rangeOfString:cut]; if (r.location != NSNotFound && r.location > 0) s = [s substringToIndex:r.location]; }
    return s;
}
static NSString *XLibraryLyrics(NSString *title, NSString *artist) {
    @try {
        MPMediaQuery *q = [MPMediaQuery songsQuery];
        [q addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:title forProperty:MPMediaItemPropertyTitle]];
        for (MPMediaItem *it in q.items) {
            if (artist.length && it.artist.length && ![it.artist isEqualToString:artist]) continue;
            if (it.lyrics.length) return it.lyrics;
        }
    } @catch (__unused id e) {}
    return nil;
}
static NSDictionary *XGetJSON(NSString *path, NSDictionary *query) {
    NSURLComponents *c = [NSURLComponents componentsWithString:[@"https://lrclib.net" stringByAppendingString:path]];
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *k in query) [items addObject:[NSURLQueryItem queryItemWithName:k value:query[k]]];
    c.queryItems = items;
    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:c.URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:8];
    [rq setValue:@"MusicPill (https://github.com/nanoonsjs/nano-tweaks)" forHTTPHeaderField:@"User-Agent"];
    __block NSData *data = nil; __block NSInteger code = 0;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[NSURLSession.sharedSession dataTaskWithRequest:rq completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        data = d; code = [r isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)r).statusCode : 0;
        dispatch_semaphore_signal(sem);
    }] resume];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)));
    if (code != 200 || !data) return nil;
    id j = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([j isKindOfClass:[NSDictionary class]]) return j;
    if ([j isKindOfClass:[NSArray class]]) {   // search: take the first one with timed lyrics, else the first with any
        for (NSDictionary *d in j) if ([d isKindOfClass:[NSDictionary class]] && [d[@"syncedLyrics"] isKindOfClass:[NSString class]]) return d;
        for (NSDictionary *d in j) if ([d isKindOfClass:[NSDictionary class]] && [d[@"plainLyrics"] isKindOfClass:[NSString class]]) return d;
    }
    return nil;
}
static MPLyrics *XFromJSON(NSDictionary *d) {
    if (!d) return nil;
    id syn = d[@"syncedLyrics"], pl = d[@"plainLyrics"];
    MPLyrics *l = [syn isKindOfClass:[NSString class]] ? XParseLRC(syn) : nil;
    if (!l && [pl isKindOfClass:[NSString class]]) l = XPlainLyrics(pl);
    return l;
}
// Looks the song up (in the background) and hands back lyrics, or nil if there are none.
static void XFetchLyrics(NSString *title, NSString *artist, NSString *album, double dur, void (^done)(MPLyrics *l)) {
    static NSMutableDictionary *cache; if (!cache) cache = [NSMutableDictionary dictionary];
    NSString *key = [NSString stringWithFormat:@"%@|%@", title ?: @"", artist ?: @""];
    id hit = cache[key];
    if (hit) { done(hit == NSNull.null ? nil : hit); return; }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        MPLyrics *l = nil;
        @try {
            if (title.length && artist.length) {
                NSMutableDictionary *q = [@{@"track_name": title, @"artist_name": artist} mutableCopy];
                if (album.length) q[@"album_name"] = album;
                if (dur > 0) q[@"duration"] = [NSString stringWithFormat:@"%d", (int)round(dur)];
                l = XFromJSON(XGetJSON(@"/api/get", q));
                if (!l) l = XFromJSON(XGetJSON(@"/api/search", @{@"track_name": title, @"artist_name": artist}));
                NSString *clean = XCleanTitle(title);
                if (!l && ![clean isEqualToString:title]) l = XFromJSON(XGetJSON(@"/api/search", @{@"track_name": clean, @"artist_name": artist}));
                if (!l) l = XFromJSON(XGetJSON(@"/api/search", @{@"q": [NSString stringWithFormat:@"%@ %@", clean, artist]}));
            }
        } @catch (__unused id e) {}
        if (!l) l = XPlainLyrics(XLibraryLyrics(title, artist));
        dispatch_async(dispatch_get_main_queue(), ^{
            cache[key] = l ?: (id)NSNull.null;
            done(l);
        });
    });
}

// Apple-style lyrics: the line being sung is bright, the rest dim; it rolls to keep up. Tap a line to jump there.
@interface MPLyricsView : UIScrollView <UIScrollViewDelegate>
@property (nonatomic, strong) MPLyrics *lyrics;
@property (nonatomic, copy) NSString *message;
- (void)follow:(double)t animated:(BOOL)a;
@end
@implementation MPLyricsView { NSMutableArray<UILabel *> *_labels; NSInteger _cur; CFTimeInterval _userUntil; UILabel *_msg; CGFloat _laidW; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.showsVerticalScrollIndicator = NO; self.alwaysBounceVertical = YES; self.delegate = self;
    _labels = [NSMutableArray array]; _cur = -2;
    _msg = XLabel(@"", 19, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]);
    _msg.numberOfLines = 0; _msg.adjustsFontSizeToFitWidth = NO; [self addSubview:_msg];
    CAGradientLayer *fade = [CAGradientLayer layer];
    fade.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
    fade.locations = @[@0, @0.2, @0.8, @1];
    self.layer.mask = fade;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLine:)]];
    return self;
}
- (void)setMessage:(NSString *)m { _message = m; _msg.text = m; _msg.hidden = !m.length; [self setNeedsLayout]; }
- (void)setLyrics:(MPLyrics *)l {
    _lyrics = l;
    for (UILabel *x in _labels) [x removeFromSuperview];
    [_labels removeAllObjects];
    BOOL timed = l.times.count > 0;
    for (NSString *s in l.lines) {
        UILabel *x = XLabel(s, timed ? 28 : 24, UIFontWeightBold, UIColor.whiteColor);
        x.numberOfLines = 0; x.adjustsFontSizeToFitWidth = NO;
        x.alpha = timed ? 0.3 : 0.85;
        [self addSubview:x]; [_labels addObject:x];
    }
    _cur = -2; _laidW = 0;
    self.contentOffset = CGPointMake(0, -self.contentInset.top);
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CAGradientLayer *fade = (CAGradientLayer *)self.layer.mask;
    [CATransaction begin]; [CATransaction setDisableActions:YES]; fade.frame = (CGRect){self.contentOffset, self.bounds.size}; [CATransaction commit];
    CGFloat W = self.bounds.size.width;
    _msg.frame = CGRectMake(0, 0, W, 120);
    if (fabs(W - _laidW) < 0.5) return;
    _laidW = W;
    CGFloat y = 0;
    for (UILabel *x in _labels) {
        CGAffineTransform keep = x.transform; x.transform = CGAffineTransformIdentity;
        CGSize s = [x sizeThatFits:CGSizeMake(W - 16, CGFLOAT_MAX)];
        x.layer.anchorPoint = CGPointMake(0, 0.5);
        x.frame = CGRectMake(0, y, W - 16, ceil(s.height));
        x.transform = keep;
        y += ceil(s.height) + (_lyrics.times.count ? 22 : 12);
    }
    self.contentSize = CGSizeMake(W, y);
    self.contentInset = UIEdgeInsetsMake(self.bounds.size.height * 0.5 - 20, 0, self.bounds.size.height * 0.5, 0);
    _cur = -2;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)s { _userUntil = CACurrentMediaTime() + 3.5; }
- (void)scrollViewDidEndDragging:(UIScrollView *)s willDecelerate:(BOOL)d { _userUntil = CACurrentMediaTime() + 3; }
- (void)tapLine:(UITapGestureRecognizer *)g {
    if (!_lyrics.times.count) return;
    CGPoint p = [g locationInView:self];
    for (NSUInteger i = 0; i < _labels.count; i++) if (CGRectContainsPoint(CGRectInset(_labels[i].frame, 0, -10), p)) {
        double t = [_lyrics.times[i] doubleValue];
        XSeek(t); gXElapsed = t; gXStamp = CFAbsoluteTimeGetCurrent();
        [[UISelectionFeedbackGenerator new] selectionChanged];
        _userUntil = 0; [self follow:t animated:YES];
        return;
    }
}
- (void)follow:(double)t animated:(BOOL)a {
    if (!_labels.count) return;
    NSInteger cur;
    if (_lyrics.times.count) {
        cur = -1;
        for (NSUInteger i = 0; i < _lyrics.times.count; i++) { if ([_lyrics.times[i] doubleValue] <= t + 0.25) cur = i; else break; }
        if (cur == _cur) return;
        _cur = cur;
        [UIView animateWithDuration:a ? 0.45 : 0 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
            for (NSUInteger i = 0; i < self->_labels.count; i++) {
                UILabel *x = self->_labels[i];
                BOOL on = (NSInteger)i == cur;
                x.alpha = on ? 1 : ((NSInteger)i < cur ? 0.28 : 0.36);
                x.transform = on ? CGAffineTransformMakeScale(1.04, 1.04) : CGAffineTransformIdentity;
            }
        } completion:nil];
        if (CACurrentMediaTime() < _userUntil || self.isTracking) return;
        UILabel *x = _labels[MAX(0, cur)];
        CGFloat want = CGRectGetMidY(x.frame) - self.bounds.size.height * 0.5;   // in the middle
        want = MAX(-self.contentInset.top, MIN(want, self.contentSize.height - self.bounds.size.height * 0.5));
        [UIView animateWithDuration:a ? 0.7 : 0 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ self.contentOffset = CGPointMake(0, want); } completion:nil];
    } else {
        // not timed: roll along with how far into the song you are
        if (CACurrentMediaTime() < _userUntil || self.isTracking || gXDuration <= 0) return;
        CGFloat maxY = MAX(0, self.contentSize.height - self.bounds.size.height * 0.5);
        CGFloat want = -self.contentInset.top + (maxY + self.contentInset.top) * MAX(0, MIN(1, (t - 10) / MAX(1, gXDuration - 25)));
        if (fabs(self.contentOffset.y - want) > 1) [UIView animateWithDuration:a ? 0.26 : 0 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ self.contentOffset = CGPointMake(0, want); } completion:nil];
    }
}
@end

#pragma mark - pieces

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

// a plain icon button; pressing shows a soft round highlight behind it (like Apple's player)
static UIButton *XIconButton(NSString *sym, CGFloat d, CGFloat pt) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.bounds = CGRectMake(0, 0, d, d);
    UIView *hl = [[UIView alloc] initWithFrame:b.bounds];
    hl.userInteractionEnabled = NO; hl.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16]; hl.layer.cornerRadius = d / 2;
    hl.alpha = 0; hl.tag = 77; hl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [b addSubview:hl];
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor;
    b.adjustsImageWhenHighlighted = NO;
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

#pragma mark - the landscape player

static void XRequestOrientationFwd(UIWindow *w, UIInterfaceOrientationMask mask);
@interface MPLandscape : UIView
+ (instancetype)shared;
- (void)showIn:(UIWindow *)w turn:(UIDeviceOrientation)o;
- (void)hide;
- (void)hideNow;
@end
@implementation MPLandscape {
    UIView *_bg, *_tint, *_root, *_insights, *_artHost;
    NSArray<CALayer *> *_blobs;
    UIImageView *_art, *_spkLo, *_spkHi;
    UILabel *_title, *_artist, *_album, *_el, *_rem;
    MPScrub *_scrub;
    UIButton *_prev, *_play, *_next, *_close, *_stats, *_lyricsBtn;
    MPVolumeView *_vol;
    int _volLevel; BOOL _volFull, _volMute, _volHooked;
    UIView *_mini, *_miniFill;
    AVRoutePickerView *_route;
    MPLyricsView *_lyrics;
    NSString *_lyricsSong;
    BOOL _showLyrics;
    UIImage *_shownArt;
    dispatch_source_t _timer;
}
+ (instancetype)shared { static MPLandscape *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [[MPLandscape alloc] initWithFrame:CGRectZero]; }); return s; }
- (UIButton *)control:(NSString *)sym size:(CGFloat)d pt:(CGFloat)pt action:(SEL)a {
    UIButton *b = XIconButton(sym, d, pt);
    [b addTarget:self action:a forControlEvents:UIControlEventTouchUpInside];
    [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    return b;
}
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
    _tint = [UIView new]; _tint.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30]; [self addSubview:_tint];
    _root = [UIView new]; [self addSubview:_root];

    _artHost = [UIView new];
    // the cover is a control too: tap = play / pause, swipe = change song (used by "Big Cover With Lyrics")
    UITapGestureRecognizer *at = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(artTap)];
    [_artHost addGestureRecognizer:at];
    for (NSNumber *d in @[@(UISwipeGestureRecognizerDirectionLeft), @(UISwipeGestureRecognizerDirectionRight)]) {
        UISwipeGestureRecognizer *sw = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(artSwipe:)];
        sw.direction = d.unsignedIntegerValue; [_artHost addGestureRecognizer:sw];
    }
    _artHost.layer.shadowColor = UIColor.blackColor.CGColor; _artHost.layer.shadowOpacity = 0.45; _artHost.layer.shadowRadius = 24; _artHost.layer.shadowOffset = CGSizeMake(0, 14);
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerCurve = kCACornerCurveContinuous; _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [_artHost addSubview:_art]; [_root addSubview:_artHost];

    _lyrics = [MPLyricsView new]; _lyrics.alpha = 0; _lyrics.hidden = YES; [_root addSubview:_lyrics];

    _title = XLabel(@"", 28, UIFontWeightBold, nil); _title.adjustsFontSizeToFitWidth = NO; _title.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_title];
    _artist = XLabel(@"", 21, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.7]); _artist.adjustsFontSizeToFitWidth = NO; _artist.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_artist];
    _album = XLabel(@"", 15, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.5]); _album.adjustsFontSizeToFitWidth = NO; _album.lineBreakMode = NSLineBreakByTruncatingTail; [_root addSubview:_album];
    _scrub = [MPScrub new]; [_root addSubview:_scrub];
    _mini = [UIView new]; _mini.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2]; _mini.layer.cornerRadius = 2; _mini.clipsToBounds = YES; _mini.alpha = 0;
    _miniFill = [UIView new]; _miniFill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85]; [_mini addSubview:_miniFill]; [_root addSubview:_mini];
    __weak MPLandscape *ws = self;
    _scrub.moving = ^(double v) { MPLandscape *s = ws; s->_el.text = XTime(v * gXDuration); s->_rem.text = [@"-" stringByAppendingString:XTime(gXDuration * (1 - v))]; };
    _scrub.done = ^(double v) { if (gXDuration > 0) { XSeek(v * gXDuration); gXElapsed = v * gXDuration; gXStamp = CFAbsoluteTimeGetCurrent(); } };
    _el = XLabel(@"0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); [_root addSubview:_el];
    _rem = XLabel(@"-0:00", 13, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.55]); _rem.textAlignment = NSTextAlignmentRight; [_root addSubview:_rem];

    _prev = [self control:@"backward.fill" size:64 pt:30 action:@selector(tap:)];
    _play = [self control:@"play.fill" size:76 pt:42 action:@selector(tap:)];
    _next = [self control:@"forward.fill" size:64 pt:30 action:@selector(tap:)];
    for (UIButton *b in @[_prev, _play, _next]) [_root addSubview:b];

    UIImageSymbolConfiguration *sc = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold];
    _spkLo = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"speaker.fill" withConfiguration:sc]];
    _spkHi = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"speaker.wave.3.fill" withConfiguration:sc]];
    for (UIImageView *v in @[_spkLo, _spkHi]) { v.tintColor = [UIColor colorWithWhite:1 alpha:0.55]; v.contentMode = UIViewContentModeCenter; [_root addSubview:v]; }
    _vol = [[MPVolumeView alloc] init];
    _vol.tintColor = UIColor.whiteColor;
    if ([_vol respondsToSelector:@selector(setShowsRouteButton:)]) ((void (*)(id, SEL, BOOL))objc_msgSend)(_vol, @selector(setShowsRouteButton:), NO);
    [_root addSubview:_vol];
    UIGraphicsImageRendererFormat *kf = [UIGraphicsImageRendererFormat defaultFormat];
    UIImage *knob = [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(30, 30) format:kf] imageWithActions:^(UIGraphicsImageRendererContext *c) {
        CGContextSetShadowWithColor(c.CGContext, CGSizeMake(0, 1.5), 4, [UIColor colorWithWhite:0 alpha:0.35].CGColor);
        [UIColor.whiteColor setFill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(5, 5, 20, 20)] fill];
    }];
    [_vol setVolumeThumbImage:knob forState:UIControlStateNormal];
    [_vol setVolumeThumbImage:knob forState:UIControlStateHighlighted];
    // AirPlay: the normal AirPlay icon
    _route = [[AVRoutePickerView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    _route.tintColor = UIColor.whiteColor; _route.activeTintColor = MusicPink();
    if ([_route respondsToSelector:@selector(setPrioritizesVideoDevices:)]) _route.prioritizesVideoDevices = NO;
    [_root addSubview:_route];

    _lyricsBtn = [self control:@"quote.bubble" size:44 pt:19 action:@selector(toggleLyrics)]; [self addSubview:_lyricsBtn];
    [_route removeFromSuperview]; [self addSubview:_route];   // AirPlay sits up top with the other buttons
    _stats = [self control:@"chart.bar.fill" size:44 pt:18 action:@selector(toggleInsights)]; [self addSubview:_stats];
    _close = [self control:@"chevron.down" size:44 pt:19 action:@selector(closeTapped)]; [self addSubview:_close];
    return self;
}
// little life for the icons
- (void)hop:(UIView *)v kind:(int)k {
    CALayer *l = v.layer;
    if (k == 0) {   // bounce + tilt (lyrics)
        CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"]; s.values = @[@1, @1.3, @0.9, @1.06, @1]; s.keyTimes = @[@0, @0.3, @0.55, @0.8, @1]; s.duration = 0.55;
        CAKeyframeAnimation *r = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"]; r.values = @[@0, @(-0.25), @0.18, @(-0.06), @0]; r.keyTimes = s.keyTimes; r.duration = 0.55;
        [l addAnimation:s forKey:@"hop.s"]; [l addAnimation:r forKey:@"hop.r"];
    } else if (k == 1) {   // bars grow up from the bottom (Insights)
        CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"]; s.values = @[@1, @0.35, @1.25, @0.95, @1]; s.keyTimes = @[@0, @0.2, @0.55, @0.8, @1]; s.duration = 0.6;
        CAKeyframeAnimation *t = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"]; t.values = @[@0, @5, @(-2), @0.5, @0]; t.keyTimes = s.keyTimes; t.duration = 0.6;
        [l addAnimation:s forKey:@"hop.s"]; [l addAnimation:t forKey:@"hop.t"];
    } else if (k == 2) {   // a nod down (close)
        CAKeyframeAnimation *t = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"]; t.values = @[@0, @7, @(-2), @0]; t.keyTimes = @[@0, @0.4, @0.75, @1]; t.duration = 0.4;
        [l addAnimation:t forKey:@"hop.t"];
    } else if (k == 3) {   // loud: the waves pulse out
        CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"]; s.values = @[@1, @1.45, @0.92, @1.12, @1]; s.keyTimes = @[@0, @0.3, @0.55, @0.8, @1]; s.duration = 0.6;
        CAKeyframeAnimation *t = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"]; t.values = @[@0, @3, @(-1), @0]; t.keyTimes = @[@0, @0.3, @0.7, @1]; t.duration = 0.5;
        [l addAnimation:s forKey:@"hop.s"]; [l addAnimation:t forKey:@"hop.t"];
    } else {   // muted: a little shake
        CAKeyframeAnimation *t = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"]; t.values = @[@0, @(-4), @4, @(-3), @2, @0]; t.duration = 0.45;
        CAKeyframeAnimation *s = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"]; s.values = @[@1, @1.2, @1]; s.duration = 0.35;
        [l addAnimation:t forKey:@"hop.t"]; [l addAnimation:s forKey:@"hop.s"];
    }
}
- (BOOL)bigCover { return gLSArtLyricsPref && _showLyrics; }
- (void)artTap {
    if (![self bigCover]) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    XSend(2); gXPlaying = !gXPlaying;
    // a play / pause sign blooms on the cover
    UIImageView *sign = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:gXPlaying ? @"play.fill" : @"pause.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:54 weight:UIImageSymbolWeightBold]]];
    sign.tintColor = UIColor.whiteColor; sign.contentMode = UIViewContentModeCenter;
    sign.layer.shadowColor = UIColor.blackColor.CGColor; sign.layer.shadowOpacity = 0.4; sign.layer.shadowRadius = 12;
    sign.frame = _artHost.bounds; sign.alpha = 0; sign.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [_artHost addSubview:sign];
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:0 animations:^{ sign.alpha = 1; sign.transform = CGAffineTransformIdentity; } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.35 delay:0.3 options:0 animations:^{ sign.alpha = 0; sign.transform = CGAffineTransformMakeScale(1.25, 1.25); } completion:^(__unused BOOL d) { [sign removeFromSuperview]; }];
    }];
    [self refresh];
}
- (void)artSwipe:(UISwipeGestureRecognizer *)g {
    if (![self bigCover]) return;
    BOOL next = g.direction == UISwipeGestureRecognizerDirectionLeft;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    XSend(next ? 4 : 5);
    // the cover flicks out the way you swiped and springs back in with the new one
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    CGFloat d = next ? -60 : 60; k.values = @[@0, @(d), @(-d * 0.15), @0]; k.keyTimes = @[@0, @0.35, @0.7, @1]; k.duration = 0.55; k.additive = YES;
    CAKeyframeAnimation *r = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
    r.values = @[@0, @(next ? 0.35 : -0.35), @0]; r.duration = 0.55; r.additive = YES;
    [_artHost.layer addAnimation:k forKey:@"swipe"]; [_artHost.layer addAnimation:r forKey:@"swipeR"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ XPoll(); });
}
- (UISlider *)volSlider { for (UIView *v in _vol.subviews) if ([v isKindOfClass:[UISlider class]]) return (UISlider *)v; return nil; }
// the speaker icons follow the volume: more waves as it gets louder, a pulse at full, a slash and a shake at zero
- (void)volChanged {
    UISlider *sl = [self volSlider]; if (!sl) return;
    float v = sl.value;
    int lvl = v <= 0.001 ? 0 : (v < 0.34 ? 1 : (v < 0.67 ? 2 : 3));
    if (lvl != _volLevel) {
        NSString *hi = lvl == 0 ? @"speaker.fill" : [NSString stringWithFormat:@"speaker.wave.%d.fill", lvl];
        UIImageSymbolConfiguration *sc = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold];
        [UIView transitionWithView:_spkHi duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self->_spkHi.image = [UIImage systemImageNamed:hi withConfiguration:sc]; } completion:nil];
        [UIView transitionWithView:_spkLo duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self->_spkLo.image = [UIImage systemImageNamed:lvl == 0 ? @"speaker.slash.fill" : @"speaker.fill" withConfiguration:sc]; } completion:nil];
        if (_volLevel >= 0) {   // a small pop each time a wave comes or goes
            CAKeyframeAnimation *p = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"]; p.values = @[@1, @1.18, @1]; p.duration = 0.25;
            [_spkHi.layer addAnimation:p forKey:@"lvl"];
        }
        _volLevel = lvl;
    }
    BOOL full = v >= 0.999, mute = v <= 0.001;
    if (full && !_volFull) { [self hop:_spkHi kind:3]; _spkHi.tintColor = UIColor.whiteColor; [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid] impactOccurred]; }
    if (!full && _volFull) _spkHi.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
    if (mute && !_volMute) { [self hop:_spkLo kind:4]; _spkLo.tintColor = UIColor.whiteColor; [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid] impactOccurred]; }
    if (!mute && _volMute) _spkLo.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
    _volFull = full; _volMute = mute;
}
- (void)down:(UIButton *)b {
    UIView *hl = [b viewWithTag:77];
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformMakeScale(0.86, 0.86); hl.alpha = 1; } completion:nil];
}
- (void)up:(UIButton *)b {
    UIView *hl = [b viewWithTag:77];
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
    [UIView animateWithDuration:0.35 delay:0.05 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ hl.alpha = 0; } completion:nil];
}
- (void)tap:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b == _play) { XSend(2); gXPlaying = !gXPlaying; [self refresh]; }
    else {
        XSend(b == _next ? 4 : 5);
        CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        CGFloat d = b == _next ? -16 : 16; k.values = @[@0, @(d), @(-d * 0.25), @0]; k.keyTimes = @[@0, @0.3, @0.7, @1]; k.duration = 0.5; k.additive = YES;
        [_artHost.layer addAnimation:k forKey:@"skip"];
        CAKeyframeAnimation *ar = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        ar.values = @[@0, @(-d * 0.6), @(d * 0.15), @0]; ar.keyTimes = @[@0, @0.35, @0.7, @1]; ar.duration = 0.4; ar.additive = YES;
        [b.imageView.layer addAnimation:ar forKey:@"slide"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ XPoll(); });
    }
}
- (void)setSym:(UIButton *)b name:(NSString *)n pt:(CGFloat)pt {
    [b setImage:[UIImage systemImageNamed:n withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
}
- (void)toggleLyrics {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    _showLyrics = !_showLyrics;
    [self setSym:_lyricsBtn name:_showLyrics ? @"quote.bubble.fill" : @"quote.bubble" pt:19];
    [self hop:_lyricsBtn.imageView kind:0];
    if (_showLyrics) { _lyrics.hidden = NO; [self loadLyrics]; }
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self layoutNow];
        self->_lyrics.alpha = self->_showLyrics ? 1 : 0;
        self->_album.alpha = self->_showLyrics ? 0 : 1;
    } completion:^(__unused BOOL f) { if (!self->_showLyrics) self->_lyrics.hidden = YES; }];
    if (_showLyrics) [_lyrics follow:XElapsedNow() animated:NO];
}
- (void)loadLyrics {
    NSString *key = [NSString stringWithFormat:@"%@|%@", gXTitle ?: @"", gXArtist ?: @""];
    if ([key isEqualToString:_lyricsSong]) return;
    _lyricsSong = key;
    _lyrics.lyrics = nil;
    _lyrics.message = @"Loading lyrics…";
    __weak MPLandscape *ws = self;
    XFetchLyrics(gXTitle, gXArtist, gXAlbum, gXDuration, ^(MPLyrics *l) {
        MPLandscape *s = ws; if (!s || ![key isEqualToString:s->_lyricsSong]) return;
        s->_lyrics.message = l ? nil : @"No lyrics found for this song.";
        s->_lyrics.lyrics = l;
        [s->_lyrics layoutIfNeeded];
        [s->_lyrics follow:XElapsedNow() animated:NO];
    });
}
- (void)toggleInsights {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    [self hop:_stats.imageView kind:1];
    if (_insights) {
        UIView *v = _insights; _insights = nil;
        [self setSym:_stats name:@"chart.bar.fill" pt:18]; _stats.tintColor = UIColor.whiteColor;
        [UIView animateWithDuration:0.3 animations:^{
            v.alpha = 0; v.transform = CGAffineTransformMakeScale(0.96, 0.96); self->_root.alpha = 1;
            self->_close.alpha = 1; self->_lyricsBtn.alpha = 1; self->_stats.alpha = 1; self->_route.alpha = 1;
        } completion:^(__unused BOOL f) { [v removeFromSuperview]; }];
        _close.userInteractionEnabled = _lyricsBtn.userInteractionEnabled = _stats.userInteractionEnabled = _route.userInteractionEnabled = YES;
        return;
    }
    UIVisualEffectView *panel = XGlass(30);
    CGRect b = self.bounds; UIEdgeInsets sa = self.safeAreaInsets;
    CGFloat L = MAX(16, sa.left), R = MAX(16, sa.right);
    panel.frame = CGRectMake(L, 12, b.size.width - L - R, b.size.height - 12 - MAX(12, sa.bottom));
    [MPInsightsCtl buildIn:panel.contentView size:panel.bounds.size closeTarget:self action:@selector(toggleInsights)];
    [self insertSubview:panel belowSubview:_lyricsBtn];
    _insights = panel;
    _stats.tintColor = MusicPink();
    _close.userInteractionEnabled = _lyricsBtn.userInteractionEnabled = _stats.userInteractionEnabled = _route.userInteractionEnabled = NO;   // only Insights' own close shows
    panel.alpha = 0; panel.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        panel.alpha = 1; panel.transform = CGAffineTransformIdentity; self->_root.alpha = 0;
        self->_close.alpha = 0; self->_lyricsBtn.alpha = 0; self->_stats.alpha = 0; self->_route.alpha = 0;
    } completion:nil];
}
- (void)safeAreaInsetsDidChange { [super safeAreaInsetsDidChange]; [self setNeedsLayout]; }
- (void)layoutSubviews { [super layoutSubviews]; [self layoutNow]; }
- (void)layoutNow {
    CGRect B = self.bounds; CGFloat W = B.size.width, H = B.size.height;
    if (W < 10) return;
    UIEdgeInsets sa = self.safeAreaInsets;
    CGFloat L = MAX(24, sa.left + 6), R = MAX(24, sa.right + 6), Bot = MAX(14, sa.bottom);
    _bg.frame = B; _tint.frame = B; _root.frame = B;
    BOOL ly = _showLyrics;
    // top row: lyrics on the left; Insights and close on the right
    _lyricsBtn.center = CGPointMake(L + 18, 32);
    _close.center = CGPointMake(W - R - 18, 32);
    _stats.center = CGPointMake(W - R - 68, 32);
    _route.frame = CGRectMake(W - R - 118 - 20, 12, 40, 40);

    CGFloat x, cw, top;   // the column with the song, bar and controls
    BOOL big = gLSArtLyricsPref && ly;
    for (UIView *v in @[_title, _artist, _scrub, _el, _rem, _prev, _play, _next, _vol, _spkLo, _spkHi]) v.alpha = big ? 0 : 1;
    if (!big) _album.alpha = ly ? 0 : 1; else _album.alpha = 0;
    _artHost.userInteractionEnabled = big;
    _mini.alpha = big ? 1 : 0;
    if (big) {
        CGFloat leftW = W * 0.5 - L;
        CGFloat d = MIN(H - 64 - Bot, leftW - 10);
        CGRect af = CGRectMake(L + (leftW - d) / 2, 50 + (H - 50 - Bot - d) / 2 - 6, d, d);
        [self placeArt:af radius:20];
        _mini.frame = CGRectMake(af.origin.x + 8, CGRectGetMaxY(af) + 12, d - 16, 4);
        CGFloat lx = W * 0.5 + 10;
        _lyrics.frame = CGRectMake(lx, 0, W - lx - R, H);
        x = W * 0.5 + 16; cw = W - x - R; top = H;   // controls are hidden
    } else if (!ly) {
        // cover on the left half, everything else on the right half
        CGFloat leftW = W * 0.5 - L;
        CGFloat d = MIN(H - 64 - Bot, leftW - 10);
        CGRect af = CGRectMake(L + (leftW - d) / 2, 56 + (H - 56 - Bot - d) / 2, d, d);
        [self placeArt:af radius:20];
        x = W * 0.5 + 16; cw = W - x - R;
        top = MAX(60, (H - Bot - 262) / 2 + 22);
        _title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        _artist.font = [UIFont systemFontOfSize:21 weight:UIFontWeightMedium];
        _title.frame = CGRectMake(x, top, cw, 34);
        _artist.frame = CGRectMake(x, top + 36, cw, 26);
        _album.frame = CGRectMake(x, top + 63, cw, 20);
        top += 96;
        _lyrics.frame = CGRectMake(W * 0.52, 56, W * 0.48 - R, H - 56 - Bot);
    } else {
        // lyrics on the right; the cover (small), song and controls stay on the left
        cw = MIN(W * 0.42 - L, 380); x = L;
        CGFloat block = 72 + 20 + 22 + 18 + 70 + 44;   // cover row, bar, times, controls, volume
        top = MAX(58, (H - Bot - block) / 2 + 18);
        [self placeArt:CGRectMake(x, top, 72, 72) radius:10];
        _title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        _artist.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _title.frame = CGRectMake(x + 86, top + 12, cw - 86, 25);
        _artist.frame = CGRectMake(x + 86, top + 38, cw - 86, 21);
        _album.frame = CGRectMake(x + 86, top + 60, cw - 86, 18);
        top += 72 + 18;
        CGFloat lx = x + cw + 34;
        _lyrics.frame = CGRectMake(lx, 0, W - lx - R, H);
    }
    if (big) { [self placeBlobs:W h:H]; return; }
    _scrub.frame = CGRectMake(x, top, cw, 22);
    _el.frame = CGRectMake(x, top + 24, 80, 16);
    _rem.frame = CGRectMake(x + cw - 80, top + 24, 80, 16);
    CGFloat cy = top + (ly ? 84 : 90), cx = x + cw / 2, gap = MIN(cw * 0.3, ly ? 92 : 104);
    _play.center = CGPointMake(cx, cy);
    _prev.center = CGPointMake(cx - gap, cy);
    _next.center = CGPointMake(cx + gap, cy);
    CGFloat vy = cy + (ly ? 58 : 66);
    _spkLo.bounds = CGRectMake(0, 0, 24, 20); _spkLo.center = CGPointMake(x + 10, vy);
    _spkHi.bounds = CGRectMake(0, 0, 26, 20); _spkHi.center = CGPointMake(x + cw - 10, vy);
    _vol.frame = CGRectMake(x + 32, vy - 15, cw - 64, 30);
    if (!_volHooked) { UISlider *sl = [self volSlider]; if (sl) { _volHooked = YES; _volLevel = -1; [sl addTarget:self action:@selector(volChanged) forControlEvents:UIControlEventValueChanged]; [self volChanged]; } }

    [self placeBlobs:W h:H];
}
- (void)placeBlobs:(CGFloat)W h:(CGFloat)H {
    NSArray *spots = @[[NSValue valueWithCGPoint:CGPointMake(W * 0.2, H * 0.3)], [NSValue valueWithCGPoint:CGPointMake(W * 0.78, H * 0.25)], [NSValue valueWithCGPoint:CGPointMake(W * 0.55, H * 0.9)]];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (NSUInteger i = 0; i < _blobs.count; i++) { CALayer *l = _blobs[i]; l.bounds = CGRectMake(0, 0, W * 1.1, W * 1.1); if (![l animationForKey:@"drift"]) l.position = [spots[i] CGPointValue]; }
    [CATransaction commit];
}
- (void)placeArt:(CGRect)af radius:(CGFloat)r {
    // bounds + center (not frame) so the paused shrink (a transform) stays right
    _artHost.bounds = CGRectMake(0, 0, af.size.width, af.size.height); _artHost.center = CGPointMake(CGRectGetMidX(af), CGRectGetMidY(af));
    _art.frame = _artHost.bounds; _art.layer.cornerRadius = r;
    _artHost.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_artHost.bounds cornerRadius:r].CGPath;
    _artHost.layer.shadowRadius = r > 12 ? 24 : 10;
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
    if (plain) { for (CALayer *l in _blobs) [l removeAllAnimations]; return; }
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
    NSString *tt = gXTitle ?: @"Not Playing";
    if (![_title.text isEqualToString:tt]) _title.text = tt;
    _artist.text = gXArtist ?: @""; _album.text = gXAlbum ?: @"";
    double e = XElapsedNow();
    if (!_scrub.dragging) {
        _scrub.value = gXDuration > 0 ? e / gXDuration : 0;
        _el.text = XTime(e); _rem.text = [@"-" stringByAppendingString:XTime(MAX(0, gXDuration - e))];
    }
    NSString *sym = gXPlaying ? @"pause.fill" : @"play.fill";
    if (![_play.accessibilityValue isEqualToString:sym]) {
        BOOL first = _play.accessibilityValue == nil;
        _play.accessibilityValue = sym;
        if (first) [self setSym:_play name:sym pt:42];
        else {
            [UIView transitionWithView:_play duration:0.22 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction animations:^{ [self setSym:self->_play name:sym pt:42]; } completion:nil];
            CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"]; k.values = @[@0.7, @1.12, @1]; k.keyTimes = @[@0, @0.6, @1]; k.duration = 0.35;
            [_play.imageView.layer addAnimation:k forKey:@"morph"];
        }
    }
    if (_mini.alpha > 0) _miniFill.frame = CGRectMake(0, 0, _mini.bounds.size.width * (gXDuration > 0 ? MAX(0, MIN(1, e / gXDuration)) : 0), 4);
    // hardware volume buttons move the slider too
    if (_volHooked) [self volChanged];
    CGAffineTransform at = gXPlaying ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);   // the cover shrinks a little while paused
    if (!CGAffineTransformEqualToTransform(_artHost.transform, at)) [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self->_artHost.transform = at; } completion:nil];
    if (_showLyrics) { [self loadLyrics]; [_lyrics follow:e animated:YES]; }
}
- (void)placeIn:(UIWindow *)w turn:(UIDeviceOrientation)o {
    // normally Music has turned for real; if it didn't, turn just our view
    CGRect wb = w.bounds;
    CGAffineTransform t = CGAffineTransformIdentity;
    if (wb.size.width >= wb.size.height) { self.transform = t; self.frame = wb; }
    else {
        self.transform = CGAffineTransformIdentity;
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
    [self layoutIfNeeded];
    [self refresh];
    CGAffineTransform rest = self.transform;
    self.alpha = 0; self.transform = CGAffineTransformScale(rest, 1.06, 1.06);
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{ self.alpha = 1; self.transform = rest; } completion:nil];
    NSArray *parts = @[_artHost, _title, _artist, _album, _scrub, _prev, _play, _next, _vol, _route];
    for (NSUInteger i = 0; i < parts.count; i++) {
        UIView *v = parts[i]; CGAffineTransform keep = v.transform; CGFloat a = v.alpha;
        v.alpha = 0; v.transform = CGAffineTransformConcat(keep, CGAffineTransformMakeTranslation(0, 16));
        [UIView animateWithDuration:0.6 delay:0.08 + i * 0.03 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ v.alpha = a; v.transform = keep; } completion:nil];
    }
    if (!_timer) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.2 * NSEC_PER_SEC), (uint64_t)(0.03 * NSEC_PER_SEC));
        __weak MPLandscape *ws = self;
        dispatch_source_set_event_handler(_timer, ^{ @try { [ws refresh]; } @catch (__unused id e) {} });
        dispatch_resume(_timer);
    }
}
- (void)closeTapped {
    [self hop:_close.imageView kind:2];
    UIWindow *w = self.window;
    gLSActive = NO;
    [self hide];
    if (w) XRequestOrientationFwd(w, UIInterfaceOrientationMaskPortrait);
}
- (void)hideNow {
    if (_timer) { dispatch_source_cancel(_timer); _timer = nil; }
    if (_insights) { [_insights removeFromSuperview]; _insights = nil; }
    _root.alpha = 1; _close.alpha = _lyricsBtn.alpha = _stats.alpha = _route.alpha = 1;
    _close.userInteractionEnabled = _lyricsBtn.userInteractionEnabled = _stats.userInteractionEnabled = _route.userInteractionEnabled = YES;
    _stats.tintColor = UIColor.whiteColor;
    [self.layer removeAllAnimations];
    [self removeFromSuperview];
    self.transform = CGAffineTransformIdentity; self.alpha = 1;
}
- (void)hide {
    if (!self.superview) return;
    if (_timer) { dispatch_source_cancel(_timer); _timer = nil; }
    if (_insights) { [_insights removeFromSuperview]; _insights = nil; _root.alpha = 1; _close.alpha = _lyricsBtn.alpha = 1; _close.userInteractionEnabled = _lyricsBtn.userInteractionEnabled = YES; _stats.tintColor = UIColor.whiteColor; }
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

static void LSPillBack(void);
static void XRequestOrientationFwd(UIWindow *w, UIInterfaceOrientationMask mask) { XRequestOrientation(w, mask); if (mask == UIInterfaceOrientationMaskPortrait) LSPillBack(); }
// Music's bar carries our shrink (a transform). If Music turns with that on, it sizes the bar through it and the
// pill comes back bigger every time. So the bar goes back to plain size before turning, and gets the pill size again
// only once Music is upright and settled.
static CGSize gLSMiniSize;
static void LSPillPlain(void) {
    UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
    if (!mini) return;
    if (gLSMiniSize.width < 1) gLSMiniSize = mini.bounds.size;
    [mini.layer removeAllAnimations];
    mini.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(mini, kApplied, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(mini, kDragT, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ApplyPillST(mini);
}
static void LSPillBack(void) {
    gLSSettle = CACurrentMediaTime() + 1.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (gLSActive) return;
        UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
        if (mini) {
            CGSize want = gLSMiniSize;
            // still too big (Music didn't size it back): put the upright size back
            if (want.width > 1 && mini.bounds.size.width > want.width + 1 && mini.superview.bounds.size.width < mini.bounds.size.width) mini.bounds = CGRectMake(0, 0, want.width, want.height);
            mini.transform = CGAffineTransformIdentity;
            objc_setAssociatedObject(mini, kApplied, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (objc_getAssociatedObject(mini, kStyled)) ApplyPillTransform(mini, YES);
        }
        gLSMiniSize = CGSizeZero;
        SyncPill();
    });
}
@interface MPOrient : NSObject @end
@implementation MPOrient
+ (void)changed:(NSNotification *)n {
    UIWindow *w = gLastTabBar.window ?: UIApplication.sharedApplication.keyWindow;
    if (!gLandscape || !gRound || !w) {
        if (gLSActive) { gLSActive = NO; [[MPLandscape shared] hide]; if (w) XRequestOrientation(w, UIInterfaceOrientationMaskPortrait); LSPillBack(); }
        return;
    }
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    UIDeviceOrientation o = UIDevice.currentDevice.orientation;
    if (UIDeviceOrientationIsLandscape(o)) {
        InstallRotationHooks();
        BOOL was = gLSActive;
        if (!was) LSPillPlain();
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
        LSPillBack();
    }
}
@end
static void StartLandscape(void) {
    [UIDevice.currentDevice beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:[MPOrient class] selector:@selector(changed:) name:UIDeviceOrientationDidChangeNotification object:nil];
    // going Home: the landscape player goes away right then (it stayed stuck on top when you came back in portrait)
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *n) {
        if (!gLSActive && ![MPLandscape shared].superview) return;
        UIWindow *w = gLastTabBar.window ?: [MPLandscape shared].window;
        gLSActive = NO;
        [[MPLandscape shared] hideNow];
        if (w) XRequestOrientation(w, UIInterfaceOrientationMaskPortrait);
        LSPillBack();
    }];
    // coming back: if the phone is still sideways, it comes back up
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *n) {
        if ([MPLandscape shared].superview && !gLSActive) [[MPLandscape shared] hideNow];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation)) [MPOrient changed:nil];
        });
    }];
}

// a smaller pill while you're on the Library tab
static BOOL OnLibraryTab(void) {
    UITabBar *tb = gLastTabBar;
    if (!gLibMini || !tb.selectedItem) return NO;
    NSUInteger i = [tb.items indexOfObject:tb.selectedItem];
    NSString *t = tb.selectedItem.title.lowercaseString;
    return [t containsString:@"library"] || [t containsString:@"mediateca"] || [t containsString:@"biblioth"] || (i == 3 && tb.items.count == 5 && !t.length);
}
