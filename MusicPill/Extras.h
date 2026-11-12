// ===================== MusicPill extras =====================
// Hold the pill: a glass menu with Up Next, Sleep Timer and Music Insights.
// Animated waveform on the pill while music plays. Listening log for Insights.
// (Included from Tweak.x just before %ctor, so everything above is available here.)

#define gPillHold gPillHoldPref
static void ShareNowPlayingFwd(UIView *from);
#define gWave gWavePref
#define gTapOpen gTapOpenPref

#pragma mark - now playing (MediaRemote), polled once a second

static NSString *gXTitle, *gXArtist, *gXAlbum;
static UIImage *gXArt;   // the cover (from MediaRemote)
static BOOL gXPlaying;
static double gXElapsed, gXDuration, gXRate;
static CFAbsoluteTime gXStamp;
static void XSend(int cmd) {
    typedef Boolean (*SendFn)(int, CFDictionaryRef);
    static SendFn send; static dispatch_once_t o;
    dispatch_once(&o, ^{ void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY); if (h) send = (SendFn)dlsym(h, "MRMediaRemoteSendCommand"); });
    if (send) send(cmd, NULL);
}
static void XPoll(void) {
    typedef void (*InfoFn)(dispatch_queue_t, void (^)(CFDictionaryRef));
    typedef void (*PlayingFn)(dispatch_queue_t, void (^)(Boolean));
    static InfoFn info; static PlayingFn playing; static dispatch_once_t o;
    dispatch_once(&o, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) { info = (InfoFn)dlsym(h, "MRMediaRemoteGetNowPlayingInfo"); playing = (PlayingFn)dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"); }
    });
    if (info) info(dispatch_get_main_queue(), ^(CFDictionaryRef d) {
        NSDictionary *x = (__bridge NSDictionary *)d;
        id t = x[@"kMRMediaRemoteNowPlayingInfoTitle"], a = x[@"kMRMediaRemoteNowPlayingInfoArtist"];
        gXTitle = [t isKindOfClass:[NSString class]] ? t : nil;
        gXArtist = [a isKindOfClass:[NSString class]] ? a : nil;
        id al = x[@"kMRMediaRemoteNowPlayingInfoAlbum"]; gXAlbum = [al isKindOfClass:[NSString class]] ? al : nil;
        static NSData *lastArt;
        NSData *ad = x[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
        if ([ad isKindOfClass:[NSData class]] && ![ad isEqualToData:lastArt]) { lastArt = ad; gXArt = [UIImage imageWithData:ad]; }
        gXElapsed = [x[@"kMRMediaRemoteNowPlayingInfoElapsedTime"] doubleValue];
        gXDuration = [x[@"kMRMediaRemoteNowPlayingInfoDuration"] doubleValue];
        gXRate = [x[@"kMRMediaRemoteNowPlayingInfoPlaybackRate"] doubleValue];
        NSDate *ts = x[@"kMRMediaRemoteNowPlayingInfoTimestamp"];
        gXStamp = [ts isKindOfClass:[NSDate class]] ? ts.timeIntervalSinceReferenceDate : CFAbsoluteTimeGetCurrent();
    });
    if (playing) playing(dispatch_get_main_queue(), ^(Boolean p) { gXPlaying = p; });
}
static double XRemaining(void) {
    if (gXDuration <= 0) return -1;
    double e = gXElapsed + (gXRate > 0 ? (CFAbsoluteTimeGetCurrent() - gXStamp) * gXRate : 0);
    return gXDuration - e;
}

#pragma mark - listening log (for Insights)

static NSString *XDayKey(NSDate *d) {
    static NSDateFormatter *f; if (!f) { f = [NSDateFormatter new]; f.dateFormat = @"yyyy-MM-dd"; f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; }
    return [f stringFromDate:d];
}
static NSMutableDictionary *gXLog;
static CFAbsoluteTime gXLastSave;
static void XLoad(void) {
    if (!gXLog) {
        NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"mp.insights"];
        gXLog = [NSMutableDictionary dictionary];
        for (NSString *k in @[@"days", @"songs", @"artists", @"weekSongs", @"weekArtists"]) gXLog[k] = [saved[k] isKindOfClass:[NSDictionary class]] ? [saved[k] mutableCopy] : [NSMutableDictionary dictionary];
        gXLog[@"week"] = saved[@"week"] ?: @"";
    }
}
static void XLogTick(double secs) {
    XLoad();
    if (!gXPlaying || !gXTitle.length || secs <= 0 || secs > 5) return;
    // this week's lists start over every Monday
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
    NSDate *ws = nil; [cal rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&ws interval:NULL forDate:[NSDate date]];
    NSString *wk = XDayKey(ws ?: [NSDate date]);
    if (![gXLog[@"week"] isEqual:wk]) { gXLog[@"week"] = wk; gXLog[@"weekSongs"] = [NSMutableDictionary dictionary]; gXLog[@"weekArtists"] = [NSMutableDictionary dictionary]; }
    NSString *song = gXArtist.length ? [NSString stringWithFormat:@"%@\n%@", gXTitle, gXArtist] : gXTitle;
    NSString *day = XDayKey([NSDate date]);
    void (^add)(NSString *, NSString *) = ^(NSString *bucket, NSString *key) {
        NSMutableDictionary *b = gXLog[bucket];
        b[key] = @([b[key] doubleValue] + secs);
    };
    add(@"days", day); add(@"songs", song); add(@"weekSongs", song);
    if (gXArtist.length) { add(@"artists", gXArtist); add(@"weekArtists", gXArtist); }
    if (CFAbsoluteTimeGetCurrent() - gXLastSave > 30) {
        gXLastSave = CFAbsoluteTimeGetCurrent();
        // keep the lists small: the 300 biggest songs, 60 days
        NSMutableDictionary *songs = gXLog[@"songs"];
        if (songs.count > 400) {
            NSArray *keep = [[songs keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator].allObjects;
            for (NSString *k in [keep subarrayWithRange:NSMakeRange(300, keep.count - 300)]) [songs removeObjectForKey:k];
        }
        NSMutableDictionary *days = gXLog[@"days"];
        if (days.count > 60) { NSArray *ks = [days.allKeys sortedArrayUsingSelector:@selector(compare:)]; for (NSString *k in [ks subarrayWithRange:NSMakeRange(0, ks.count - 60)]) [days removeObjectForKey:k]; }
        [[NSUserDefaults standardUserDefaults] setObject:gXLog forKey:@"mp.insights"];
    }
}

#pragma mark - sleep timer

static CFAbsoluteTime gSleepEnd;      // 0 = off
static int gSleepPick;                // the chip you picked (minutes, -1 end of song, 0 off)
static BOOL gSleepEndOfSong;
static void SleepTick(void) {
    if (gSleepEndOfSong) {
        double rem = XRemaining();
        if (gXPlaying && rem >= 0 && rem < 1.2) { XSend(1); gSleepEndOfSong = NO; [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess]; }
        return;
    }
    if (gSleepEnd > 0 && CFAbsoluteTimeGetCurrent() >= gSleepEnd) { gSleepEnd = 0; gSleepPick = 0; XSend(1); }
}
static NSString *SleepStatus(void) {
    if (gSleepEndOfSong) return @"End of song";
    if (gSleepEnd <= 0) return nil;
    int s = (int)MAX(0, gSleepEnd - CFAbsoluteTimeGetCurrent());
    return s >= 3600 ? [NSString stringWithFormat:@"%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60] : [NSString stringWithFormat:@"%d:%02d", s / 60, s % 60];
}

#pragma mark - glass panel helpers

static UIVisualEffectView *XGlass(CGFloat radius) {
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    g.layer.cornerRadius = radius; g.layer.cornerCurve = kCACornerCurveContinuous; g.clipsToBounds = YES;
    g.layer.borderWidth = 0.8; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    g.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
    return g;
}
// a squishy press that adds on top of whatever transform the view has (the pill keeps its own)
static void XJelly(UIView *v) {
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
    a.additive = YES; a.fromValue = @(-0.07); a.toValue = @0;
    a.mass = 1; a.stiffness = 320; a.damping = 11; a.initialVelocity = 0;
    a.duration = a.settlingDuration;
    [v.layer addAnimation:a forKey:@"mp.jelly"];
}
static UILabel *XLabel(NSString *t, CGFloat size, UIFontWeight w, UIColor *c) {
    UILabel *l = [UILabel new]; l.text = t; l.font = [UIFont systemFontOfSize:size weight:w]; l.textColor = c ?: UIColor.whiteColor;
    l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.7;
    return l;
}

// A full-screen layer with a dimmed background; tap outside to close. Content slides up from the bottom.
@interface MPSheet : UIView
@property (nonatomic, strong) UIVisualEffectView *panel;
@property (nonatomic, copy) void (^onTick)(void);
@property (nonatomic, weak) UIView *source;   // grows out of this (the pill) and goes back into it
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h;
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h from:(UIView *)src;
- (void)close;
@end
@implementation MPSheet
static __weak UIView *gSheetSource;   // the pill the last menu came out of
static CGAffineTransform XFromRect(CGRect panel, CGRect r) {
    CGFloat sx = MAX(0.05, r.size.width / panel.size.width), sy = MAX(0.05, r.size.height / panel.size.height);
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(CGRectGetMidX(r) - CGRectGetMidX(panel), CGRectGetMidY(r) - CGRectGetMidY(panel)), sx, sy);
}
static UIVisualEffect *XGlassEffect(void) { return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]; }
// the rim fades with the glass (a layer border doesn't animate with UIView animations)
static void XRim(CALayer *l, CGFloat to, CFTimeInterval dur) {
    CGColorRef c = [UIColor colorWithWhite:1 alpha:to].CGColor;
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    a.fromValue = (__bridge id)(l.presentationLayer ?: l).borderColor; a.toValue = (__bridge id)c; a.duration = dur;
    a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    l.borderColor = c;
    [l addAnimation:a forKey:@"rim"];
}
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h { return [self showIn:w height:h from:gSheetSource]; }
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h from:(UIView *)src {
    if (src.window != w) src = nil;
    MPSheet *s = [[MPSheet alloc] initWithFrame:w.bounds];
    s.source = src;
    s.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [s addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:s action:@selector(bgTap:)]];
    CGFloat W = w.bounds.size.width - 24;
    s.panel = XGlass(34);
    CGFloat bottom = w.bounds.size.height - h - MAX(16, w.safeAreaInsets.bottom), y = bottom;
    CGRect pr = src ? [src convertRect:src.bounds toView:w] : CGRectZero;
    if (src) y = MIN(CGRectGetMinY(pr) - 12 - h, bottom);   // just above the pill when there's room
    y = MAX(w.safeAreaInsets.top + 8, y);
    s.panel.frame = CGRectMake(12, y, W, h);
    [s addSubview:s.panel];
    [w addSubview:s];
    // starts as clear glass in the pill's shape (or below the screen), then the glass fills in as it grows
    s.panel.effect = nil;
    s.panel.layer.borderColor = [UIColor colorWithWhite:1 alpha:0].CGColor;
    s.panel.contentView.alpha = 0;
    s.panel.transform = src ? XFromRect(s.panel.frame, pr) : CGAffineTransformMakeTranslation(0, h + 60);
    if (src) {   // the pill gives a little push as the menu leaves it
        CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
        a.additive = YES; a.fromValue = @0.06; a.toValue = @0; a.stiffness = 300; a.damping = 12; a.duration = a.settlingDuration;
        [src.layer addAnimation:a forKey:@"mp.launch"];
    }
    [UIView animateWithDuration:0.72 delay:0 usingSpringWithDamping:0.74 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        s.panel.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        s.backgroundColor = [UIColor colorWithWhite:0 alpha:0.32];
        s.panel.effect = XGlassEffect();
    } completion:nil];
    XRim(s.panel.layer, 0.22, 0.4);
    [UIView animateWithDuration:0.3 delay:0.14 options:UIViewAnimationOptionCurveEaseOut animations:^{ s.panel.contentView.alpha = 1; } completion:nil];
    return s;
}
- (void)bgTap:(UITapGestureRecognizer *)g { if (!CGRectContainsPoint(self.panel.frame, [g locationInView:self])) [self close]; }
- (void)close {
    if (self.tag == 0x4D50) return;   // already closing
    self.tag = 0x4D50;
    self.userInteractionEnabled = NO;
    UIView *src = self.source;
    BOOL back = src && src.window == self.window;
    CGRect pr = back ? [src convertRect:src.bounds toView:self] : CGRectZero;
    CGAffineTransform to = back ? XFromRect(self.panel.frame, pr) : CGAffineTransformMakeTranslation(0, self.panel.bounds.size.height + 60);
    // contents go first, then the glass melts away while it shrinks back into the pill: nothing is left behind
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ self.panel.contentView.alpha = 0; } completion:nil];
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.panel.transform = to;
    } completion:nil];
    [UIView animateWithDuration:0.3 delay:0.06 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.panel.effect = nil;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    } completion:^(__unused BOOL f) { [self removeFromSuperview]; }];
    XRim(self.panel.layer, 0, 0.28);
    if (back) {   // and the pill takes it back in with a little squish
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.24 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
            a.additive = YES; a.fromValue = @0.05; a.toValue = @0; a.stiffness = 320; a.damping = 11; a.duration = a.settlingDuration;
            [src.layer addAnimation:a forKey:@"mp.absorb"];
        });
    }
}
@end

#pragma mark - Sleep Timer sheet

@interface MPSleepCtl : NSObject
+ (instancetype)shared;
@property (nonatomic, weak) MPSheet *sheet;
@property (nonatomic, weak) UILabel *status;
@property (nonatomic, strong) NSMutableArray *chips;
@property (nonatomic, copy) void (^closer)(void);
- (void)buildIn:(UIView *)c width:(CGFloat)W close:(void (^)(void))close;
@end
@implementation MPSleepCtl
+ (instancetype)shared { static MPSleepCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPSleepCtl new]; }); return s; }
- (void)showIn:(UIWindow *)w {
    MPSheet *sh = [MPSheet showIn:w height:300];
    self.sheet = sh;
    __weak MPSheet *wsh = sh;
    [self buildIn:sh.panel.contentView width:sh.panel.bounds.size.width close:^{ [wsh close]; }];
}
- (void)buildIn:(UIView *)c width:(CGFloat)W close:(void (^)(void))close {
    self.closer = close;
    UIImageView *moon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"moon.zzz.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightSemibold]]];
    moon.tintColor = [UIColor colorWithRed:0.62 green:0.55 blue:1 alpha:1]; moon.frame = CGRectMake(22, 22, 30, 30); moon.contentMode = UIViewContentModeCenter;
    [c addSubview:moon];
    UILabel *t = XLabel(@"Sleep Timer", 22, UIFontWeightBold, nil); t.frame = CGRectMake(60, 22, W - 130, 30); [c addSubview:t];
    UILabel *st = XLabel(@"", 15, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]); st.frame = CGRectMake(22, 58, W - 44, 20); [c addSubview:st];
    self.status = st;
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem];
    [x setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    x.tintColor = UIColor.whiteColor; x.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    x.frame = CGRectMake(W - 58, 20, 38, 38); x.layer.cornerRadius = 19;
    [x addTarget:self action:@selector(closeTap) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:x];
    NSArray *opts = @[@[@"15 min", @15], @[@"30 min", @30], @[@"45 min", @45], @[@"1 hour", @60], @[@"End of Song", @-1], @[@"Off", @0]];
    self.chips = [NSMutableArray array];
    CGFloat gap = 10, cw = (W - 44 - gap * 2) / 3, ch = 58;
    for (NSUInteger i = 0; i < opts.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(22 + (i % 3) * (cw + gap), 96 + (i / 3) * (ch + gap), cw, ch);
        b.layer.cornerRadius = ch / 2; b.layer.cornerCurve = kCACornerCurveContinuous;
        b.layer.borderWidth = 0.8; b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        [b setTitle:opts[i][0] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.tag = [opts[i][1] intValue];
        [b addTarget:self action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
        [c addSubview:b]; [self.chips addObject:b];
        b.alpha = 0; b.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [UIView animateWithDuration:0.5 delay:0.12 + i * 0.03 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.alpha = 1; b.transform = CGAffineTransformIdentity; } completion:nil];
    }
    [self update];
}
- (void)closeTap { if (self.closer) self.closer(); }
- (void)pick:(UIButton *)b {
    XJelly(b);
    [[UISelectionFeedbackGenerator new] selectionChanged];
    gSleepEndOfSong = b.tag == -1;
    gSleepPick = (int)b.tag;
    gSleepEnd = b.tag > 0 ? CFAbsoluteTimeGetCurrent() + b.tag * 60 : 0;
    [self update];
    if (b.tag != 0) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (self.closer) self.closer(); });
}
- (void)update {
    NSString *s = SleepStatus();
    self.status.text = s ? (gSleepEndOfSong ? @"Music stops at the end of this song" : [NSString stringWithFormat:@"Music stops in %@", s]) : @"Pick when music should stop";
    int cur = gSleepEndOfSong ? -1 : (gSleepEnd > 0 ? gSleepPick : 0);
    for (UIButton *b in self.chips) {
        BOOL on = b.tag == cur;
        b.backgroundColor = on ? [UIColor colorWithRed:0.55 green:0.45 blue:1 alpha:0.85] : [UIColor colorWithWhite:1 alpha:0.10];
    }
}
@end

#pragma mark - Up Next (Music's own queue: reorder, remove, add)

static void OpenUpNext(UIView *mini) {
    UIWindow *w = mini.window ?: UIApplication.sharedApplication.keyWindow;
    if (!PlayerIsUp(w, NULL) && mini) OpenPlayer(mini);
    __block int tries = 0;
    __block void (^find)(void);
    find = ^{
        UIView *player = nil;
        if (PlayerIsUp(w, &player)) {
            // the queue button: bottom right of the full player
            UIButton *best = nil; CGFloat bx = 0;
            NSMutableArray *q = [NSMutableArray arrayWithObject:player]; int n = 0;
            while (q.count && n++ < 1500) {
                UIView *v = q.firstObject; [q removeObjectAtIndex:0];
                if ([v isKindOfClass:[UIButton class]] && !v.hidden && v.alpha > 0.1) {
                    CGRect r = [v convertRect:v.bounds toView:w];
                    if (CGRectGetMinY(r) > w.bounds.size.height * 0.78 && CGRectGetMidX(r) > w.bounds.size.width * 0.6 && r.size.width < 70 && CGRectGetMidX(r) > bx) { best = (UIButton *)v; bx = CGRectGetMidX(r); }
                }
                [q addObjectsFromArray:v.subviews];
            }
            if (best) { if (!best.selected) [best sendActionsForControlEvents:UIControlEventTouchUpInside]; find = nil; return; }
        }
        if (++tries < 12) { void (^again)(void) = find; dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), again); }
        else find = nil;
    };
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), find);
}

#pragma mark - Music Insights

static NSString *XDur(double s) {
    long m = (long)(s / 60);
    if (m >= 60) return [NSString stringWithFormat:@"%ldh %ldm", m / 60, m % 60];
    return [NSString stringWithFormat:@"%ldm", MAX(0L, m)];
}
static NSArray *XTopN(NSDictionary *d, NSUInteger n) {
    NSArray *ks = [d keysSortedByValueUsingComparator:^NSComparisonResult(id a, id b) { return [b compare:a]; }];
    return ks.count > n ? [ks subarrayWithRange:NSMakeRange(0, n)] : ks;
}
// cover art for a song from your library (cached)
static UIImage *XArtFor(NSString *title, NSString *artist, CGFloat side) {
    static NSCache *cache; if (!cache) cache = [NSCache new];
    NSString *key = [NSString stringWithFormat:@"%@|%@", title ?: @"", artist ?: @""];
    id hit = [cache objectForKey:key];
    if (hit) return [hit isKindOfClass:[UIImage class]] ? hit : nil;
    UIImage *img = nil;
    @try {
        MPMediaQuery *q = [MPMediaQuery songsQuery];
        if (title.length) [q addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:title forProperty:MPMediaItemPropertyTitle]];
        else if (artist.length) [q addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:artist forProperty:MPMediaItemPropertyArtist]];
        for (MPMediaItem *it in q.items) {
            if (artist.length && title.length && ![it.artist isEqualToString:artist]) continue;
            img = [it.artwork imageWithSize:CGSizeMake(side * 3, side * 3)];
            if (img) break;
        }
    } @catch (__unused id e) {}
    [cache setObject:img ?: (id)[NSNull null] forKey:key];
    return img;
}
static UIView *XCardView(CGRect f) {
    UIView *card = [[UIView alloc] initWithFrame:f];
    card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    card.layer.cornerRadius = 26; card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 0.6; card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    return card;
}
static UIImageView *XArtView(UIImage *img, CGRect f, CGFloat radius) {
    UIImageView *iv = [[UIImageView alloc] initWithFrame:f];
    iv.image = img; iv.contentMode = UIViewContentModeScaleAspectFill; iv.clipsToBounds = YES;
    iv.layer.cornerRadius = radius; iv.layer.cornerCurve = kCACornerCurveContinuous;
    iv.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    if (!img) {
        UIImageView *note = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"music.note" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:f.size.width * 0.35 weight:UIImageSymbolWeightMedium]]];
        note.tintColor = [UIColor colorWithWhite:1 alpha:0.45]; note.contentMode = UIViewContentModeCenter; note.frame = iv.bounds; [iv addSubview:note];
    }
    return iv;
}
static void XAppear(UIView *v, int i) {
    v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(0, 24);
    [UIView animateWithDuration:0.6 delay:0.08 + i * 0.06 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
}
// one row of a list: rank, cover, title / subtitle, value on the right
static UIView *XRow(CGFloat W, int rank, UIImage *art, NSString *title, NSString *sub, NSString *value) {
    UIView *r = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 60)];
    UILabel *n = XLabel([NSString stringWithFormat:@"%d", rank], 15, UIFontWeightBold, [UIColor colorWithWhite:1 alpha:0.45]);
    n.textAlignment = NSTextAlignmentCenter; n.frame = CGRectMake(8, 20, 20, 20); [r addSubview:n];
    [r addSubview:XArtView(art, CGRectMake(34, 8, 44, 44), 10)];
    UILabel *t = XLabel(title, 16, UIFontWeightSemibold, nil); t.adjustsFontSizeToFitWidth = NO; t.lineBreakMode = NSLineBreakByTruncatingTail;
    t.frame = CGRectMake(90, 11, W - 90 - 80, 20); [r addSubview:t];
    UILabel *s = XLabel(sub, 13, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.55]); s.adjustsFontSizeToFitWidth = NO; s.lineBreakMode = NSLineBreakByTruncatingTail;
    s.frame = CGRectMake(90, 31, W - 90 - 80, 18); [r addSubview:s];
    UILabel *v = XLabel(value, 14, UIFontWeightSemibold, [UIColor colorWithWhite:1 alpha:0.75]); v.textAlignment = NSTextAlignmentRight;
    v.frame = CGRectMake(W - 86, 20, 72, 20); [r addSubview:v];
    return r;
}

@interface MPInsightsCtl : NSObject
+ (void)showIn:(UIWindow *)w;
+ (void)buildIn:(UIView *)c size:(CGSize)size closeTarget:(id)closeT action:(SEL)closeA;
@end
@implementation MPInsightsCtl
+ (void)showIn:(UIWindow *)w {
    CGFloat H = w.bounds.size.height - w.safeAreaInsets.top - 24;
    MPSheet *sh = [MPSheet showIn:w height:H];
    [self buildIn:sh.panel.contentView size:sh.panel.bounds.size closeTarget:sh action:@selector(close)];
}
// Lays the dashboard out in any container: one column upright, two columns when it's wide (landscape).
+ (void)buildIn:(UIView *)c size:(CGSize)size closeTarget:(id)closeT action:(SEL)closeA {
    XLoad();
    [[NSUserDefaults standardUserDefaults] setObject:gXLog forKey:@"mp.insights"];
    CGFloat W = size.width, H = size.height;
    BOOL wide = W > 600;
    UIColor *pink = [UIColor colorWithRed:1 green:0.25 blue:0.42 alpha:1], *violet = [UIColor colorWithRed:0.55 green:0.38 blue:1 alpha:1];

    // header
    UILabel *t = XLabel(@"Insights", 30, UIFontWeightHeavy, nil); t.frame = CGRectMake(22, 22, W - 90, 36); [c addSubview:t];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
    NSDate *ws = nil; [cal rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&ws interval:NULL forDate:[NSDate date]];
    ws = ws ?: [NSDate date];
    NSDateFormatter *mf = [NSDateFormatter new]; mf.dateFormat = @"MMM d";
    UILabel *sub = XLabel([NSString stringWithFormat:@"Week of %@", [mf stringFromDate:ws]], 15, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.55]);
    sub.frame = CGRectMake(22, 58, W - 90, 20); [c addSubview:sub];
    UIButton *x = [UIButton buttonWithType:UIButtonTypeSystem];
    [x setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    x.tintColor = UIColor.whiteColor; x.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    x.frame = CGRectMake(W - 58, 22, 38, 38); x.layer.cornerRadius = 19;
    [x addTarget:closeT action:closeA forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:x];

    UIScrollView *sc = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 92, W, H - 92)];
    sc.showsVerticalScrollIndicator = NO; sc.alwaysBounceVertical = YES;
    [c addSubview:sc];
    // left column: the week (hero, streak, today); right column: artist, songs, all time
    CGFloat cw = wide ? (W - 44) / 2 : W - 32, lx = 16, rx = wide ? 28 + cw : 16;
    CGFloat y = 4;
    int idx = 0;

    // ---- this week: big number, change vs last week, bars per day
    NSDictionary *days = gXLog[@"days"];
    double vals[7], total = 0, last = 0, mx = 1;
    for (int i = 0; i < 7; i++) {
        NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:i toDate:ws options:0];
        NSDate *p = [cal dateByAddingUnit:NSCalendarUnitDay value:i - 7 toDate:ws options:0];
        vals[i] = [days[XDayKey(d)] doubleValue]; total += vals[i]; mx = MAX(mx, vals[i]);
        last += [days[XDayKey(p)] doubleValue];
    }
    UIView *hero = XCardView(CGRectMake(lx, y, cw, 250));
    CAGradientLayer *gr = [CAGradientLayer layer];
    gr.frame = hero.bounds; gr.cornerRadius = 26;
    gr.colors = @[(id)[pink colorWithAlphaComponent:0.55].CGColor, (id)[violet colorWithAlphaComponent:0.35].CGColor, (id)[UIColor colorWithWhite:0 alpha:0].CGColor];
    gr.startPoint = CGPointMake(0, 0); gr.endPoint = CGPointMake(1, 1);
    [hero.layer insertSublayer:gr atIndex:0];
    UILabel *hh = XLabel(@"LISTENING THIS WEEK", 12, UIFontWeightBold, [UIColor colorWithWhite:1 alpha:0.75]); hh.frame = CGRectMake(18, 16, cw - 36, 16); [hero addSubview:hh];
    UILabel *big = XLabel(XDur(total), 44, UIFontWeightHeavy, nil); big.frame = CGRectMake(18, 34, cw - 36, 52); [hero addSubview:big];
    if (last > 60) {
        double pct = (total - last) / last * 100;
        UILabel *chg = XLabel([NSString stringWithFormat:@"%@ %.0f%% vs last week", pct >= 0 ? @"▲" : @"▼", fabs(pct)], 13, UIFontWeightSemibold, pct >= 0 ? [UIColor colorWithRed:0.45 green:1 blue:0.6 alpha:1] : [UIColor colorWithRed:1 green:0.6 blue:0.6 alpha:1]);
        chg.frame = CGRectMake(18, 86, cw - 36, 18); [hero addSubview:chg];
    }
    NSArray *dn = @[@"M", @"T", @"W", @"T", @"F", @"S", @"S"];
    NSInteger today = ([cal component:NSCalendarUnitWeekday fromDate:[NSDate date]] + 5) % 7;
    CGFloat bw = (cw - 36) / 7, base = 214, maxH = 90;
    for (int i = 0; i < 7; i++) {
        CGFloat bh = MAX(6, maxH * vals[i] / mx);
        UIView *track = [[UIView alloc] initWithFrame:CGRectMake(18 + i * bw + bw * 0.22, base - maxH, bw * 0.56, maxH)];
        track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06]; track.layer.cornerRadius = bw * 0.28; [hero addSubview:track];
        UIView *bar = [[UIView alloc] init];
        bar.layer.anchorPoint = CGPointMake(0.5, 1);
        bar.frame = CGRectMake(18 + i * bw + bw * 0.22, base - bh, bw * 0.56, bh);
        bar.backgroundColor = i == today ? UIColor.whiteColor : [UIColor colorWithWhite:1 alpha:0.45];
        bar.layer.cornerRadius = bw * 0.28;
        [hero addSubview:bar];
        bar.transform = CGAffineTransformMakeScale(1, 0.02);
        [UIView animateWithDuration:0.8 delay:0.25 + i * 0.05 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:0 animations:^{ bar.transform = CGAffineTransformIdentity; } completion:nil];
        UILabel *l = XLabel(dn[i], 12, i == today ? UIFontWeightBold : UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:i == today ? 1 : 0.55]);
        l.textAlignment = NSTextAlignmentCenter; l.frame = CGRectMake(18 + i * bw, base + 6, bw, 16); [hero addSubview:l];
    }
    [sc addSubview:hero]; XAppear(hero, idx++); y += 250 + 12;

    // ---- today and streak
    int streak = 0;
    for (int i = 0; i < 60; i++) {
        NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:[NSDate date] options:0];
        if ([days[XDayKey(d)] doubleValue] >= 60) streak++; else if (i > 0) break;
    }
    CGFloat hw = (cw - 12) / 2;
    NSArray *chips = @[@[@"flame.fill", streak == 1 ? @"1 day" : [NSString stringWithFormat:@"%d days", streak], @"Listening streak", [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1]],
                       @[@"clock.fill", XDur([days[XDayKey([NSDate date])] doubleValue]), @"Today", violet]];
    for (int i = 0; i < 2; i++) {
        UIView *ch = XCardView(CGRectMake(lx + i * (hw + 12), y, hw, 92));
        UIImageView *ic = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:chips[i][0] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold]]];
        ic.tintColor = chips[i][3]; ic.frame = CGRectMake(16, 14, 24, 24); ic.contentMode = UIViewContentModeCenter; [ch addSubview:ic];
        UILabel *v = XLabel(chips[i][1], 24, UIFontWeightHeavy, nil); v.frame = CGRectMake(16, 40, hw - 32, 28); [ch addSubview:v];
        UILabel *s = XLabel(chips[i][2], 13, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.55]); s.frame = CGRectMake(16, 66, hw - 32, 16); [ch addSubview:s];
        [sc addSubview:ch]; XAppear(ch, idx++);
    }
    y += 92 + 12;
    CGFloat yLeft = y;
    if (wide) y = 4;   // the right column starts at the top again

    // ---- top artist this week
    NSString *topArtist = XTopN(gXLog[@"weekArtists"], 1).firstObject;
    if (topArtist) {
        UIView *ac = XCardView(CGRectMake(rx, y, cw, 110));
        UIImageView *av = XArtView(XArtFor(nil, topArtist, 78), CGRectMake(16, 16, 78, 78), 39);
        av.layer.borderWidth = 2; av.layer.borderColor = [pink colorWithAlphaComponent:0.8].CGColor; [ac addSubview:av];
        UILabel *h = XLabel(@"TOP ARTIST", 12, UIFontWeightBold, pink); h.frame = CGRectMake(110, 22, cw - 126, 16); [ac addSubview:h];
        UILabel *n = XLabel(topArtist, 22, UIFontWeightHeavy, nil); n.frame = CGRectMake(110, 40, cw - 126, 28); [ac addSubview:n];
        UILabel *m = XLabel([NSString stringWithFormat:@"%@ this week", XDur([gXLog[@"weekArtists"][topArtist] doubleValue])], 14, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]);
        m.frame = CGRectMake(110, 68, cw - 126, 18); [ac addSubview:m];
        [sc addSubview:ac]; XAppear(ac, idx++); y += 110 + 12;
    }

    // ---- top songs this week
    NSArray *tops = XTopN(gXLog[@"weekSongs"], 5);
    UILabel *s1 = XLabel(@"Top Songs This Week", 20, UIFontWeightBold, nil); s1.frame = CGRectMake(rx + 6, y + 6, cw, 26); [sc addSubview:s1]; y += 40;
    if (tops.count) {
        UIView *lc = XCardView(CGRectMake(rx, y, cw, tops.count * 60 + 8));
        for (NSUInteger i = 0; i < tops.count; i++) {
            NSArray *p = [tops[i] componentsSeparatedByString:@"\n"];
            UIView *row = XRow(cw, (int)i + 1, XArtFor(p.firstObject, p.count > 1 ? p[1] : nil, 44), p.firstObject, p.count > 1 ? p[1] : @"", XDur([gXLog[@"weekSongs"][tops[i]] doubleValue]));
            row.frame = CGRectMake(0, 4 + i * 60, cw, 60); [lc addSubview:row];
        }
        [sc addSubview:lc]; XAppear(lc, idx++); y += lc.bounds.size.height + 12;
    } else {
        UILabel *e = XLabel(@"Play some music and your week shows up here.", 14, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.5]); e.frame = CGRectMake(rx + 6, y, cw, 20); [sc addSubview:e]; y += 32;
    }

    // ---- all time, from your library's play counts (worked out in the background)
    UILabel *s2 = XLabel(@"All Time", 20, UIFontWeightBold, nil); s2.frame = CGRectMake(rx + 6, y + 6, cw, 26); [sc addSubview:s2]; y += 40;
    UIView *allCard = XCardView(CGRectMake(rx, y, cw, 5 * 60 + 8 + 70));
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spin.color = UIColor.whiteColor; spin.center = CGPointMake(cw / 2, allCard.bounds.size.height / 2); [spin startAnimating]; [allCard addSubview:spin];
    [sc addSubview:allCard]; XAppear(allCard, idx++);
    y += allCard.bounds.size.height + 12;
    UILabel *foot = XLabel(@"This week counts what you've played since turning this on. All Time comes from your library's play counts.", 12, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.4]);
    foot.numberOfLines = 0; foot.adjustsFontSizeToFitWidth = NO; foot.frame = CGRectMake(rx + 6, y, cw - 12, 34); [sc addSubview:foot];
    y += 50;
    sc.contentSize = CGSizeMake(W, MAX(y, yLeft));
    __weak UIView *weakCard = allCard;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray *items = [NSMutableArray array]; double libTime = 0;
        NSMutableDictionary *ar = [NSMutableDictionary dictionary];
        @try {
            for (MPMediaItem *it in [MPMediaQuery songsQuery].items) {
                NSUInteger pc = it.playCount; if (!pc) continue;
                libTime += pc * it.playbackDuration;
                [items addObject:@[@(pc), it.title ?: @"", it.artist ?: @""]];
                if (it.artist.length) ar[it.artist] = @([ar[it.artist] unsignedLongValue] + pc);
            }
        } @catch (__unused id e) {}
        [items sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) { return [b[0] compare:a[0]]; }];
        NSArray *top5 = items.count > 5 ? [items subarrayWithRange:NSMakeRange(0, 5)] : items;
        NSString *libArtist = XTopN(ar, 1).firstObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *card = weakCard; if (!card) return;
            [spin removeFromSuperview];
            UILabel *tt = XLabel(XDur(libTime), 22, UIFontWeightHeavy, nil); tt.frame = CGRectMake(18, 14, cw / 2 - 24, 28); [card addSubview:tt];
            UILabel *tl = XLabel(@"Total listening", 13, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.55]); tl.frame = CGRectMake(18, 42, cw / 2 - 24, 16); [card addSubview:tl];
            UILabel *ta = XLabel(libArtist ?: @"–", 22, UIFontWeightHeavy, nil); ta.frame = CGRectMake(cw / 2 + 6, 14, cw / 2 - 24, 28); [card addSubview:ta];
            UILabel *tal = XLabel(@"Most played artist", 13, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.55]); tal.frame = CGRectMake(cw / 2 + 6, 42, cw / 2 - 24, 16); [card addSubview:tal];
            for (NSUInteger i = 0; i < top5.count; i++) {
                NSArray *it = top5[i];
                UIView *row = XRow(cw, (int)i + 1, XArtFor(it[1], it[2], 44), it[1], it[2], [NSString stringWithFormat:@"%@ plays", it[0]]);
                row.frame = CGRectMake(0, 70 + i * 60, cw, 60); row.alpha = 0; [card addSubview:row];
                [UIView animateWithDuration:0.4 delay:i * 0.05 options:0 animations:^{ row.alpha = 1; } completion:nil];
            }
        });
    });
}
@end

#pragma mark - swipe up on the pill: glass menu

@interface MPHoldCtl : NSObject
+ (instancetype)shared;
- (void)showMenuFrom:(UIView *)v;
@property (nonatomic, weak) UIView *from;
@property (nonatomic, weak) MPSheet *menu;
@end
@implementation MPHoldCtl
+ (instancetype)shared { static MPHoldCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPHoldCtl new]; }); return s; }
- (void)showMenuFrom:(UIView *)v {
    UIWindow *w = v.window;
    if (!w || self.menu.window) return;
    self.from = v;
    gSheetSource = v;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    MPSheet *sh = [MPSheet showIn:w height:2 * 62 + 24 from:v];
    self.menu = sh;
    UIView *c = sh.panel.contentView; CGFloat W = sh.panel.bounds.size.width;
    NSString *sleep = SleepStatus();
    NSArray *rows = @[@[@"moon.zzz.fill", @"Sleep Timer", sleep ? [NSString stringWithFormat:@"On · %@", sleep] : @"Stop music after a while"],
                      @[@"chart.bar.fill", @"Insights", @"Your week, top artists and songs"]];
    for (NSUInteger i = 0; i < rows.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(10, 12 + i * 62, W - 20, 58); b.tag = i;
        b.layer.cornerRadius = 22; b.layer.cornerCurve = kCACornerCurveContinuous;
        [b addTarget:self action:@selector(row:) forControlEvents:UIControlEventTouchUpInside];
        [b addTarget:self action:@selector(rowDown:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [b addTarget:self action:@selector(rowUp:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        UIView *ic = [[UIView alloc] initWithFrame:CGRectMake(10, 9, 40, 40)];
        ic.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12]; ic.layer.cornerRadius = 20; ic.userInteractionEnabled = NO;
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:rows[i][0] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]]];
        iv.tintColor = i == 0 ? [UIColor colorWithRed:0.66 green:0.58 blue:1 alpha:1] : [UIColor colorWithRed:1 green:0.3 blue:0.45 alpha:1];
        iv.contentMode = UIViewContentModeCenter; iv.frame = ic.bounds; [ic addSubview:iv];
        [b addSubview:ic];
        UILabel *t = XLabel(rows[i][1], 17, UIFontWeightSemibold, nil); t.frame = CGRectMake(62, 9, W - 100, 22); t.userInteractionEnabled = NO; [b addSubview:t];
        UILabel *s = XLabel(rows[i][2], 13, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.55]); s.frame = CGRectMake(62, 31, W - 100, 18); s.userInteractionEnabled = NO; [b addSubview:s];
        [c addSubview:b];
        b.alpha = 0; b.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, 18), 0.94, 0.94);
        [UIView animateWithDuration:0.55 delay:0.12 + i * 0.06 usingSpringWithDamping:0.72 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.alpha = 1; b.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)rowDown:(UIButton *)b { [UIView animateWithDuration:0.15 animations:^{ b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10]; b.transform = CGAffineTransformMakeScale(0.97, 0.97); }]; }
- (void)rowUp:(UIButton *)b { [UIView animateWithDuration:0.3 animations:^{ b.backgroundColor = UIColor.clearColor; b.transform = CGAffineTransformIdentity; }]; }
- (void)row:(UIButton *)b {
    [self rowUp:b];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    UIWindow *w = self.menu.window;
    UIView *from = self.from;
    [self.menu close];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!w) return;
        (void)from;
        if (b.tag == 0) [[MPSleepCtl shared] showIn:w];
        else [MPInsightsCtl showIn:w];
    });
}
@end


#pragma mark - swipe up on the pill: it grows into Insights (like holding the Dynamic Island)

// ease used for the sides/corners: they follow a beat behind the top edge, like the Dynamic Island
static CGFloat XMorphCurve(CGFloat p) { p = MAX(0, MIN(1, p)); return p * p * (3 - 2 * p); }
static CGFloat XStep(CGFloat a, CGFloat b, CGFloat x) { x = MAX(0, MIN(1, (x - a) / (b - a))); return x * x * (3 - 2 * x); }
@interface MPIsland : UIView <UIGestureRecognizerDelegate>
+ (void)expandFrom:(UIView *)pill;
+ (void)expandFrom:(UIView *)pill circle:(CGRect)circle;
+ (void)expandFrom:(UIView *)pill preview:(UIView *)card;
- (void)collapse;
@end
@implementation MPIsland {
    UIView *_shape, *_content, *_snap;
    __weak UIView *_pill;
    CADisplayLink *_link; CFTimeInterval _lastT;
    CGFloat _prog, _vel, _goal, _zeta;   // 0 = open island, 1 = the pill: one spring, every frame
    CGRect _P;                            // where it closes to, fixed for the whole move
    UIView *_insightsC; CGRect _insightsTo;   // kept while the Sleep Timer is showing, for Back
    CGRect _from, _to;
    CGFloat _fromR;
}
static __weak MPIsland *gIsland;
static void XGooAbsorb(UIView *pill, CGRect circleWin);   // MPGoo, below
static CGFloat gDropX = -1;                               // where the last drop was (window x)
// 1.5.1: the island goes back the way it came: it shrinks into a drop of liquid above the pill, which is then
// sucked back down into the pill
static CGRect XDropAbove(CGRect pillWin) {
    // the same drop the pull makes at this height (1.5.6 shape), so the hand-off is seamless
    CGFloat d = 60, t = MIN(1, d / 80); t = 1 - (1 - t) * (1 - t);
    CGFloat r = MIN(pillWin.size.height * 0.5, 6 + 22 * t);
    CGFloat f = MAX(0, MIN(1, (d - 4) / 56)); f = f * f * (3 - 2 * f);
    CGFloat x = gDropX >= 0 ? gDropX : CGRectGetMidX(pillWin);
    CGFloat m = pillWin.size.height / 2 + r * 0.5;
    x = MAX(CGRectGetMinX(pillWin) + m, MIN(CGRectGetMaxX(pillWin) - m, x));
    CGFloat cy = CGRectGetMinY(pillWin) + 0.5 - d + r * 0.8 * (1 - f);
    return CGRectMake(x - r, cy - r, r * 2, r * 2);
}
static CGRect XPillRect(UIView *pill, UIView *in) {
    // the pill as it looks right now (its shrink and position included)
    CALayer *pl = pill.layer.presentationLayer ?: pill.layer;
    CGRect r = [pill.superview.layer convertRect:pl.frame toLayer:in.layer];
    return r.size.width > 20 ? r : [pill convertRect:pill.bounds toView:in];
}
+ (void)expandFrom:(UIView *)pill { [self expandFrom:pill circle:CGRectNull]; }
// 1.5.7: from the preview card (the peek you pulled up): the card itself grows into the island
static __weak UIView *gPreviewCard;
+ (void)expandFrom:(UIView *)pill preview:(UIView *)card {
    gPreviewCard = card;
    [self expandFrom:pill circle:[card convertRect:card.bounds toView:nil]];
    gPreviewCard = nil;
}
// circle: 1.4.11, the island grows out of the liquid drop you pulled up (window coords), not the pill
+ (void)expandFrom:(UIView *)pill circle:(CGRect)circle {
    UIWindow *w = pill.window;
    if (!w || gIsland.window) return;
    gSheetSource = pill;
    MPIsland *v = [[MPIsland alloc] initWithFrame:w.bounds];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    gIsland = v;
    // 1.4.5: the pill you SEE is our drawn pill (Music's own bar is invisible under it): the island takes its
    // picture and spot from that one, and hides it while the island is up, so it never shows behind
    UIView *seenPill = pill;
    id po = gPillObj;
    if ([po isKindOfClass:[UIView class]] && ((UIView *)po).window == w && !((UIView *)po).hidden && ((UIView *)po).alpha > 0.05) seenPill = po;
    v->_pill = seenPill;
    // the island starts exactly where the pill is on screen right now: still stretched up by your swipe
    NSValue *dragV = objc_getAssociatedObject(pill, kDragT);
    CGRect rest = [seenPill convertRect:seenPill.bounds toView:w];
    CGRect seen = rest;
    if (dragV) {
        CATransform3D t = dragV.CATransform3DValue;
        CGFloat sx = t.m11, sy = t.m22, dx = t.m41, dy = t.m42;
        seen = CGRectMake(CGRectGetMidX(rest) - rest.size.width * sx / 2 + dx, CGRectGetMidY(rest) - rest.size.height * sy / 2 + dy, rest.size.width * sx, rest.size.height * sy);
    }
    BOOL fromDrop = !CGRectIsNull(circle) && circle.size.width > 2;
    BOOL fromCard = fromDrop && gPreviewCard != nil;
    if (fromDrop) seen = circle;
    for (NSString *k in @[@"mp.bounce", @"mp.release", @"mp.touchdown", @"mp.jelly", @"mp.absorb"]) [pill.layer removeAnimationForKey:k];
    v->_from = rest;
    v->_fromR = v->_from.size.height / 2;
    UIEdgeInsets sa = w.safeAreaInsets;
    CGFloat W = w.bounds.size.width, H = w.bounds.size.height;
    CGFloat bottom = MIN(H - MAX(10, sa.bottom - 8), CGRectGetMaxY(v->_from) + 4);
    v->_to = CGRectMake(8, sa.top + 6, W - 16, bottom - sa.top - 6);

    // the shape: starts exactly as the pill, the pill's picture inside it, then it grows
    UIView *shape = [[UIView alloc] initWithFrame:seen];
    shape.clipsToBounds = YES; shape.layer.cornerCurve = kCACornerCurveContinuous; shape.layer.cornerRadius = fromCard ? gPreviewCard.layer.cornerRadius : seen.size.height / 2;
    shape.layer.borderWidth = 0.8; shape.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark]];
    blur.frame = shape.bounds; blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [shape addSubview:blur];
    UIView *ink = [[UIView alloc] initWithFrame:shape.bounds];   // deep and dark like the island
    ink.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55]; ink.autoresizingMask = blur.autoresizingMask;
    [shape addSubview:ink];
    UIView *snap = fromDrop ? nil : [seenPill snapshotViewAfterScreenUpdates:NO];
    // the pill's picture keeps its size and stays at the bottom while the island grows up out of it (no stretching)
    if (snap) { snap.frame = CGRectMake((seen.size.width - rest.size.width) / 2, seen.size.height - rest.size.height, rest.size.width, rest.size.height); snap.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; [shape addSubview:snap]; }
    v->_snap = snap;
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, v->_to.size.width, v->_to.size.height)];
    content.center = CGPointMake(seen.size.width / 2, seen.size.height / 2);
    content.alpha = 0; content.transform = fromDrop ? CGAffineTransformMakeScale(0.7, 0.7) : CGAffineTransformMakeScale(0.94, 0.94);
    if (fromCard) {
        // exactly as the preview shows it: scaled down, its top in view
        CGFloat ps = seen.size.width / v->_to.size.width;
        content.alpha = 1; content.transform = CGAffineTransformMakeScale(ps, ps);
        content.center = CGPointMake(seen.size.width / 2, v->_to.size.height * ps / 2);
    }
    [shape addSubview:content];
    [MPInsightsCtl buildIn:content size:content.bounds.size closeTarget:v action:@selector(collapse)];
    // Sleep Timer sits in the header next to close
    UIButton *moon = [UIButton buttonWithType:UIButtonTypeSystem];
    NSString *sleep = SleepStatus();
    [moon setImage:[UIImage systemImageNamed:sleep ? @"moon.zzz.fill" : @"moon.zzz" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    moon.tintColor = sleep ? [UIColor colorWithRed:0.66 green:0.58 blue:1 alpha:1] : UIColor.whiteColor;
    moon.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    moon.frame = CGRectMake(content.bounds.size.width - 104, 22, 38, 38); moon.layer.cornerRadius = 19;
    [moon addTarget:v action:@selector(sleepTap) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:moon];
    // share a story card of the song, and Music's own song menu
    NSArray *extra = @[@[@"square.and.arrow.up", NSStringFromSelector(@selector(shareTap:))]];
    for (NSUInteger i = 0; i < extra.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setImage:[UIImage systemImageNamed:extra[i][0] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
        b.tintColor = UIColor.whiteColor; b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
        b.frame = CGRectMake(content.bounds.size.width - 150 - i * 46, 22, 38, 38); b.layer.cornerRadius = 19;
        [b addTarget:v action:NSSelectorFromString(extra[i][1]) forControlEvents:UIControlEventTouchUpInside];
        [content addSubview:b];
    }
    v->_shape = shape; v->_content = content;
    [v addSubview:shape];
    [w addSubview:v];
    if (seenPill != pill) {
        // from the drop the island needs a moment to grow over the pill before the pill steps away
        if (fromDrop) { __weak UIView *ws = seenPill; dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ UIView *sp = ws; if (sp && gIsland.window) [UIView performWithoutAnimation:^{ sp.alpha = 0; }]; }); }
        else [UIView performWithoutAnimation:^{ seenPill.alpha = 0; }];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:v action:@selector(bgTap:)];
    [v addGestureRecognizer:tap];
    UIPanGestureRecognizer *down = [[UIPanGestureRecognizer alloc] initWithTarget:v action:@selector(pullDown:)];
    down.delegate = v; [shape addGestureRecognizer:down];

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    // 1.3.2: the pill is never hidden (hiding it made Music lay the bar out again, so it jumped half a second
    // after closing). The island always covers it; the swipe stretch is let go once the island is over it.
    __weak UIView *wp = pill;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *pp = wp; if (!pp) return;
        objc_setAssociatedObject(pp, kDragT, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ApplyPillST(pp);
    });
    // one spring, straight out of the pill (the same curve every time)
    // one spring out of the pill: quick, a touch of overshoot, settles like the Dynamic Island
    if (fromCard) {
        // the preview opens up into the island with a liquid wobble
        [gPreviewCard removeFromSuperview];
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            shape.frame = v->_to; shape.layer.cornerRadius = 44;
            content.center = CGPointMake(v->_to.size.width / 2, v->_to.size.height / 2);
            content.transform = CGAffineTransformIdentity;
            v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        } completion:nil];
        return;
    }
    if (fromDrop) {
        // 1.5.1: liquid: the drop swells and stretches up like it's being poured upward, then spreads out
        // into the island with a wobble
        CGRect c = seen; CGFloat r = c.size.width / 2;
        CGRect tall = CGRectMake(CGRectGetMidX(c) - r * 1.25, CGRectGetMaxY(c) - r * 5.2, r * 2.5, r * 5.2);
        tall.origin.y = MAX(v->_to.origin.y, tall.origin.y);
        content.layer.shouldRasterize = YES; content.layer.rasterizationScale = UIScreen.mainScreen.scale;
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
            shape.frame = tall; shape.layer.cornerRadius = tall.size.width / 2;
            content.center = CGPointMake(tall.size.width / 2, tall.size.height / 2);
        } completion:^(__unused BOOL f) {
            [UIView animateWithDuration:0.46 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.8 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                shape.frame = v->_to; shape.layer.cornerRadius = 44;
                content.center = CGPointMake(v->_to.size.width / 2, v->_to.size.height / 2);
                content.transform = CGAffineTransformIdentity;
            } completion:^(__unused BOOL f2) { content.layer.shouldRasterize = NO; }];
        }];
        [UIView animateWithDuration:0.18 delay:0.07 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{ content.alpha = 1; } completion:nil];
        [UIView animateWithDuration:0.3 animations:^{ v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3]; }];
        return;
    }
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.35 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{
        shape.frame = v->_to;
        shape.layer.cornerRadius = 44;
        content.center = CGPointMake(v->_to.size.width / 2, v->_to.size.height / 2);
        content.transform = CGAffineTransformIdentity;
    } completion:nil];
    // the pill's picture hands over to Insights right away, so the island is never an empty dark box
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ snap.alpha = 0; } completion:nil];
    [UIView animateWithDuration:0.16 delay:0.03 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{ content.alpha = 1; } completion:nil];
    [UIView animateWithDuration:0.35 animations:^{ v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3]; }];
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    // UIKit also asks this view about its own tap (tap outside to close): that one always goes.
    // (1.2.86 asked a tap for its speed here, which crashed Music.)
    if (![g isKindOfClass:[UIPanGestureRecognizer class]]) return YES;
    CGPoint p = [g locationInView:_shape], vel = [(UIPanGestureRecognizer *)g velocityInView:_shape];
    return p.y < 96 && vel.y > fabs(vel.x);   // pull down on the header
}
// pull the island down: it follows your finger and turns back into the pill as it goes
- (CGRect)pillRect {
    UIView *pill = _pill;
    CGRect r = pill.window == self.window ? [pill convertRect:pill.bounds toView:self] : _from;
    return r.size.width < 20 ? _from : r;
}
static CGFloat XLerp(CGFloat a, CGFloat b, CGFloat t) { return a + (b - a) * t; }
// The shape at a point of the close: the top edge leads, the sides and the bottom follow a beat behind.
// Past 1 (a rubber-band pull or the spring's last bit) it keeps going smoothly instead of stopping.
- (CGRect)rectFor:(CGFloat)pr {
    CGRect P = _P, T = _to;
    CGFloat e = XMorphCurve(pr);
    CGFloat top = XLerp(CGRectGetMinY(T), CGRectGetMinY(P), MAX(-0.04, MIN(1.06, pr))), bottom = XLerp(CGRectGetMaxY(T), CGRectGetMaxY(P), e);
    CGFloat w = XLerp(T.size.width, P.size.width, e), cx = XLerp(CGRectGetMidX(T), CGRectGetMidX(P), e);
    return CGRectMake(cx - w / 2, top, w, MAX(P.size.height, bottom - top));
}
- (void)beginMove {
    _P = [_pill isKindOfClass:[MPMiniPill class]] ? XDropAbove([self pillRect]) : [self pillRect];
    UIView *fresh = nil;
    if (_pill.window) {
        CGFloat a0 = _pill.alpha;
        [UIView performWithoutAnimation:^{ self->_pill.alpha = 1; }];
        fresh = [_pill snapshotViewAfterScreenUpdates:a0 < 0.99];
        [UIView performWithoutAnimation:^{ self->_pill.alpha = a0; }];
    }
    if (fresh) { fresh.alpha = _snap.alpha; [_snap removeFromSuperview]; _snap = fresh; [_shape addSubview:fresh]; }
    _snap.autoresizingMask = UIViewAutoresizingNone;
    [_shape bringSubviewToFront:_snap];
    [_shape.layer removeAllAnimations]; [_content.layer removeAllAnimations]; [_snap.layer removeAllAnimations];
    // one flat picture while it moves: smooth even with all of Insights inside
    _content.layer.shouldRasterize = YES; _content.layer.rasterizationScale = UIScreen.mainScreen.scale;
}
- (void)show:(CGFloat)pr {
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    [UIView performWithoutAnimation:^{ [self morphTo:[self rectFor:pr] progress:MAX(0, MIN(1, pr))]; }];
    [CATransaction commit];
}
- (void)pullDown:(UIPanGestureRecognizer *)g {
    if (self.tag == 0x4D50) return;
    if (g.state == UIGestureRecognizerStateBegan) {
        [_link invalidate]; _link = nil;
        [self beginMove];
    }
    CGFloat span = MAX(1, CGRectGetMinY(_P) - CGRectGetMinY(_to));
    CGFloat dy = MAX(0, [g translationInView:self].y);
    CGFloat pr = dy / span; if (pr > 1) pr = 1 + (1 - 1 / ((pr - 1) * 2.2 + 1)) * 0.06;   // rubber band past the pill
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) { _prog = pr; [self show:pr]; return; }
    CGFloat vy = [g velocityInView:self].y;
    if (g.state == UIGestureRecognizerStateEnded && (_prog > 0.28 || vy > 600)) { [self collapseWithVelocity:vy]; return; }
    // not far enough: back up, on the same spring
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
    // a real spring (like iOS's own): response 0.42s, then integrate in small steps so it's the same at 60 or 120Hz
    double w = 2 * M_PI / 0.32, k = w * w, c = 2 * _zeta * w;
    int n = MAX(1, (int)ceil(dt / (1.0 / 240)));
    double h = dt / n;
    for (int i = 0; i < n; i++) { double a = -k * (_prog - _goal) - c * _vel; _vel += a * h; _prog += _vel * h; }
    [self show:_prog];
    if (fabs(_prog - _goal) < 0.0015 && fabs(_vel) < 0.02) {
        [_link invalidate]; _link = nil;
        _prog = _goal; [self show:_goal];
        if (_goal >= 1) [self landed];
        else { _content.layer.shouldRasterize = NO; }
    }
}
// Everything about the island at one point between open (0) and the pill (1).
- (void)morphTo:(CGRect)f progress:(CGFloat)p {
    CGRect P = CGRectIsEmpty(_P) ? [self pillRect] : _P, T = _to;
    _shape.frame = f;
    CGFloat e = XMorphCurve(p);
    _shape.layer.cornerRadius = MIN(f.size.height / 2, XLerp(44, P.size.height / 2, e));
    // the outline only belongs to the open island: it melts away as it closes (no half-border floating above the pill)
    _shape.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16 * (1 - XStep(0, 0.35, p))].CGColor;
    // Insights shrinks with the island and fades as the pill fades in; the two always overlap (never an empty box)
    CGFloat sc = MIN(1, MAX(f.size.width / MAX(1, T.size.width), f.size.height / MAX(1, T.size.height)));
    _content.transform = CGAffineTransformMakeScale(sc, sc);
    _content.center = CGPointMake(f.size.width / 2, f.size.height / 2);
    _content.alpha = 1 - XStep(0.12, 0.62, p);
    // the pill's own picture: its real size, at the bottom where the pill is, fading in
    _snap.frame = CGRectMake((f.size.width - P.size.width) / 2, f.size.height - P.size.height, P.size.width, P.size.height);
    _snap.alpha = [_pill isKindOfClass:[MPMiniPill class]] ? 0 : XStep(0.25, 0.75, p);
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3 * (1 - MIN(1, p))];
}
- (void)bgTap:(UITapGestureRecognizer *)g { if (!CGRectContainsPoint(_shape.frame, [g locationInView:self])) [self collapse]; }
- (void)shareTap:(UIButton *)b { [[UISelectionFeedbackGenerator new] selectionChanged]; ShareNowPlayingFwd(b); }
- (void)menuTap {
    [self collapse];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
        UIContextMenuInteraction *mi = mini ? MenuInteractionNear(mini) : nil;
        if (mi) OpenMenu(mini, mi);
    });
}
- (void)sleepTap {
    // the island changes shape into the Sleep Timer (like the Dynamic Island going from one activity to another)
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIView *old = _content, *shape = _shape;
    CGFloat h = 300;
    CGRect to = CGRectMake(_to.origin.x, CGRectGetMaxY(_to) - h, _to.size.width, h);
    UIView *nc = [[UIView alloc] initWithFrame:CGRectMake(0, 0, to.size.width, h)];
    __weak MPIsland *ws = self;
    [[MPSleepCtl shared] buildIn:nc width:to.size.width close:^{ [ws collapse]; }];
    // 1.5.1: Back, right beside the X, goes back to Insights
    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    [back setImage:[UIImage systemImageNamed:@"chevron.left" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    back.tintColor = UIColor.whiteColor; back.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    back.frame = CGRectMake(to.size.width - 104, 20, 38, 38); back.layer.cornerRadius = 19;
    [back addTarget:self action:@selector(backTap) forControlEvents:UIControlEventTouchUpInside];
    [nc addSubview:back];
    _insightsC = old; _insightsTo = _to;
    nc.alpha = 0; nc.transform = CGAffineTransformMakeScale(0.92, 0.92);
    // keep the new contents pinned to the bottom of the shape while it shrinks
    nc.center = CGPointMake(to.size.width / 2, shape.bounds.size.height - h / 2);
    [shape addSubview:nc];
    _content = nc;
    old.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ old.alpha = 0; old.transform = CGAffineTransformMakeScale(0.94, 0.94); } completion:nil];
    CGRect squeeze = CGRectInset(shape.frame, 6, 0);
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ shape.frame = squeeze; nc.center = CGPointMake(squeeze.size.width / 2, squeeze.size.height - h / 2); } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.76 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            shape.frame = to;
            shape.layer.cornerRadius = 40;
            nc.center = CGPointMake(to.size.width / 2, h / 2);
        } completion:nil];
    }];
    [UIView animateWithDuration:0.42 delay:0.2 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ nc.alpha = 1; nc.transform = CGAffineTransformIdentity; } completion:nil];
    _to = to;
}
// back from the Sleep Timer to Insights: the island grows back and Insights comes back in
- (void)backTap {
    if (!_insightsC || self.tag == 0x4D50) return;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIView *sleepC = _content, *ins = _insightsC, *shape = _shape;
    CGRect to = _insightsTo;
    _content = ins; _to = to; _insightsC = nil;
    [shape bringSubviewToFront:ins];
    ins.transform = CGAffineTransformMakeScale(0.94, 0.94);
    ins.center = CGPointMake(shape.bounds.size.width / 2, shape.bounds.size.height - to.size.height / 2);
    [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ sleepC.alpha = 0; sleepC.transform = CGAffineTransformMakeScale(0.94, 0.94); } completion:^(__unused BOOL f) { [sleepC removeFromSuperview]; }];
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        shape.frame = to; shape.layer.cornerRadius = 44;
        ins.center = CGPointMake(to.size.width / 2, to.size.height / 2);
        ins.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL f) { ins.userInteractionEnabled = YES; }];
    [UIView animateWithDuration:0.3 delay:0.12 options:0 animations:^{ ins.alpha = 1; } completion:nil];
}
- (void)collapse { [self collapseWithVelocity:0]; }
// closing, like the Dynamic Island going back: the contents tuck away, the top comes down first,
// then the sides pull in with a tiny squish, and it lands exactly on the pill (a fresh picture of it
// fades in on the way, so the swap at the end is invisible)
- (void)collapseWithVelocity:(CGFloat)vy {
    if (self.tag == 0x4D50) return;
    self.tag = 0x4D50;
    self.userInteractionEnabled = NO;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
    // start from exactly what's on screen
    CALayer *pl = _shape.layer.presentationLayer;
    CGRect cur = pl ? pl.frame : _shape.frame;
    BOOL moving = _link != nil;
    if (!moving) [self beginMove];
    if (!moving && CGRectGetMinY(cur) > CGRectGetMinY(_to) + 1) {
        CGFloat span = MAX(1, CGRectGetMinY(_P) - CGRectGetMinY(_to));
        _prog = MAX(0, (CGRectGetMinY(cur) - CGRectGetMinY(_to)) / span);
    } else if (!moving) _prog = 0;
    CGFloat span = MAX(1, CGRectGetMinY(_P) - CGRectGetMinY(_to));
    _vel = vy > 0 ? MIN(6, vy / span) : (moving ? _vel : 0);
    _goal = 1; _zeta = 0.9;
    [self runSpring];
    // safety: always gone, pill always there
    __weak UIView *wp = _pill;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ UIView *p = wp; if (p && p.alpha < 0.01) p.alpha = 1; if (self.superview && self.tag != 0x4D51) [self landed]; });
}
// 1.4.7: landed on the pill: the real pill is back underneath, both give the same squishy bounce together,
// and the island fades away smoothly during it, so what's left is the real pill bouncing into place.
static void XLandBounce(CALayer *L) {
    CASpringAnimation *sx = [CASpringAnimation animationWithKeyPath:@"transform.scale.x"];
    sx.fromValue = @1.07; sx.toValue = @1;
    CASpringAnimation *sy = [CASpringAnimation animationWithKeyPath:@"transform.scale.y"];
    sy.fromValue = @0.86; sy.toValue = @1;
    CASpringAnimation *ty = [CASpringAnimation animationWithKeyPath:@"transform.translation.y"];
    ty.fromValue = @3; ty.toValue = @0;
    for (CASpringAnimation *a in @[sx, sy, ty]) { a.mass = 1; a.stiffness = 300; a.damping = 10; a.initialVelocity = 2; a.duration = a.settlingDuration; a.additive = NO; }
    [L addAnimation:sx forKey:@"mp.landx"]; [L addAnimation:sy forKey:@"mp.landy"]; [L addAnimation:ty forKey:@"mp.landt"];
}
- (void)landed {
    if (!self.superview || self.tag == 0x4D51) return;
    self.tag = 0x4D51;
    [_link invalidate]; _link = nil;
    UIView *pill = _pill;
    if (pill.alpha < 0.99) [UIView performWithoutAnimation:^{ pill.alpha = 1; }];
    if ([pill isKindOfClass:[MPMiniPill class]] && pill.window) {
        // the drop takes over right where the island became one, and gets sucked into the pill
        XGooAbsorb(pill, [self convertRect:_P toView:nil]);
        [UIView animateWithDuration:0.08 animations:^{ self.alpha = 0; } completion:^(__unused BOOL f) { [self removeFromSuperview]; }];
        return;
    }
    if (pill.window) XLandBounce(pill.layer);
    XLandBounce(_shape.layer);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [UIView animateWithDuration:0.26 delay:0.02 options:UIViewAnimationOptionCurveEaseInOut animations:^{ self.alpha = 0; } completion:^(__unused BOOL f) { [self removeFromSuperview]; }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (self.superview) [self removeFromSuperview]; });
}
@end

#pragma mark - the pill follows your finger: sideways = skip (jelly), up = menu

static CGFloat XRubber(CGFloat x, CGFloat lim) { CGFloat a = fabs(x); return (x < 0 ? -1 : 1) * lim * (1 - 1 / (a / lim * 0.6 + 1)); }
static void SetDrag(UIView *v, CGFloat dx, CGFloat dy) {
    CGFloat sx = 1 + MIN(0.045, fabs(dx) / 900) - MIN(0.025, fabs(dy) / 1400), sy = 1 - MIN(0.03, fabs(dx) / 1300) + MIN(0.045, fabs(dy) / 700);
    CATransform3D t = CATransform3DScale(CATransform3DMakeTranslation(dx, dy, 0), sx, sy, 1);
    objc_setAssociatedObject(v, kDragT, [NSValue valueWithCATransform3D:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ApplyPillST(v);
}
static void ReleaseDrag(UIView *v, CGFloat vx, CGFloat vy) {
    CATransform3D from = v.layer.sublayerTransform;
    objc_setAssociatedObject(v, kDragT, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ApplyPillST(v);
    CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"sublayerTransform"];
    a.fromValue = [NSValue valueWithCATransform3D:from]; a.toValue = [NSValue valueWithCATransform3D:v.layer.sublayerTransform];
    a.mass = 1; a.stiffness = 260; a.damping = 12; a.initialVelocity = MIN(12, (fabs(vx) + fabs(vy)) / 400);
    a.duration = a.settlingDuration;
    [v.layer addAnimation:a forKey:@"mp.release"];
}

// The jelly bounce after you let go: plays on the pill itself (added on top of its own size/position),
// so it always shows. go = a skip: it first flicks further the way you swiped, then wobbles home.
static void XBounce(UIView *v, CGFloat dx, CGFloat dy, BOOL go) {
    NSValue *d = objc_getAssociatedObject(v, kDragT);
    objc_setAssociatedObject(v, kDragT, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ApplyPillST(v);
    [v.layer removeAnimationForKey:@"mp.release"];
    (void)d;
    CGFloat sxd = MIN(0.045, fabs(dx) / 900), syd = MIN(0.045, fabs(dy) / 700);
    NSArray *kt = @[@0, @0.22, @0.5, @0.75, @1];
    CAKeyframeAnimation *tx = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    tx.values = go ? @[@(dx), @(dx * 1.2), @(-dx * 0.16), @(dx * 0.05), @0] : @[@(dx), @(-dx * 0.18), @(dx * 0.07), @(-dx * 0.02), @0];
    CAKeyframeAnimation *ty = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    ty.values = @[@(dy), @(-dy * 0.2), @(dy * 0.08), @0, @0];
    CAKeyframeAnimation *sx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    sx.values = @[@(sxd - syd * 0.5), @(-0.025), @(0.015), @(-0.005), @0];
    CAKeyframeAnimation *sy = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    sy.values = @[@(syd - sxd * 0.7), @(0.03), @(-0.015), @(0.005), @0];
    CAAnimationGroup *g = [CAAnimationGroup animation];
    for (CAKeyframeAnimation *k in @[tx, ty, sx, sy]) { k.additive = YES; k.keyTimes = kt; k.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]]; }
    g.animations = @[tx, ty, sx, sy];
    g.duration = go ? 0.7 : 0.6;
    [v.layer addAnimation:g forKey:@"mp.bounce"];
}
@interface MPPillPan : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
// 1.4.11: swiping up on the pill: the pill's own glass stretches up into a drop of dark, glossy liquid that
// follows your finger on a springy, wobbly neck. The drop and the pill are ONE piece of glass (the pill's
// glass is swapped for it while you pull), so they blend perfectly, in dark and light mode. Let go, or pull
// it high, and the Dynamic Pill opens out of the drop itself.
@interface MPGoo : NSObject
- (void)beginOn:(UIView *)pill touchX:(CGFloat)x;
- (void)followX:(CGFloat)x d:(CGFloat)d;
- (CGRect)dropRectInWindow;
- (void)retract;
- (void)detach;
@end
@implementation MPGoo {
    __weak UIView *_pill; UIView *_holder, *_maskV, *_tint; UIVisualEffectView *_glassV;
    CAShapeLayer *_shape, *_rim, *_shine, *_inkMask; CAGradientLayer *_ink;
    CADisplayLink *_link; CFTimeInterval _last;
    CGFloat _tx, _td;              // where the finger wants it
    CGFloat _x, _d, _vx, _vd;      // the drop (springy, wobbles)
    CGFloat _bx, _vbx;             // the neck's foot (follows slower, so the neck leans)
    CGFloat _rScale;               // 1 normally; shrinks to 0 when the drop leaves
    int _mode;                     // 0 follow, 1 retract, 2 detached
    BOOL _light, _absorbing;
}
- (void)beginOn:(UIView *)pill touchX:(CGFloat)x {
    UIView *host = pill.superview;
    if (!host) return;
    [self cleanup];
    _pill = pill; _mode = 0; _rScale = 1; _absorbing = NO;
    CGRect P = pill.frame;
    _tx = _x = _bx = MAX(CGRectGetMinX(P), MIN(CGRectGetMaxX(P), x)); _td = _d = 0; _vx = _vd = _vbx = 0;
    _light = pill.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark;
    _holder = [[UIView alloc] initWithFrame:host.bounds]; _holder.userInteractionEnabled = NO;
    // the same glass as the pill
    _glassV = [[UIVisualEffectView alloc] initWithEffect:_light ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight] : TabGlassEffect()];
    _glassV.frame = _holder.bounds; _glassV.userInteractionEnabled = NO;
    if (_light) { _tint = [[UIView alloc] initWithFrame:_glassV.bounds]; _tint.backgroundColor = [UIColor colorWithWhite:1 alpha:0.62]; [_glassV.contentView addSubview:_tint]; }
    // the drop itself goes inky and glossy (dark mode), fading back to the pill's glass down the neck
    _ink = [CAGradientLayer layer]; _ink.frame = _holder.bounds;
    UIColor *inkC = _light ? [UIColor colorWithWhite:0.0 alpha:0.10] : [UIColor colorWithWhite:0.0 alpha:0.55];
    _ink.colors = @[(id)inkC.CGColor, (id)[inkC colorWithAlphaComponent:0].CGColor];
    _inkMask = [CAShapeLayer layer]; _inkMask.fillColor = UIColor.blackColor.CGColor; _ink.mask = _inkMask;
    [_glassV.contentView.layer addSublayer:_ink];
    // the album glow the pill has
    UIView *pg = [pill respondsToSelector:@selector(glass)] ? [pill valueForKey:@"glass"] : nil;
    _maskV = [[UIView alloc] initWithFrame:_holder.bounds];
    _shape = [CAShapeLayer layer]; _shape.fillColor = UIColor.blackColor.CGColor;
    [_maskV.layer addSublayer:_shape];
    _glassV.maskView = _maskV;
    [_holder addSubview:_glassV];
    _rim = [CAShapeLayer layer]; _rim.fillColor = UIColor.clearColor.CGColor;
    _rim.strokeColor = (_light ? [UIColor colorWithWhite:0 alpha:0.08] : [UIColor colorWithWhite:1 alpha:0.2]).CGColor;
    _rim.lineWidth = _light ? 0.8 : 0.75;
    _shine = [CAShapeLayer layer]; _shine.fillColor = UIColor.clearColor.CGColor;
    _shine.strokeColor = [UIColor colorWithWhite:1 alpha:_light ? 0.9 : 0.55].CGColor; _shine.lineWidth = 1.4; _shine.lineCap = kCALineCapRound;
    _shine.shadowColor = UIColor.whiteColor.CGColor; _shine.shadowOpacity = _light ? 0 : 0.5; _shine.shadowRadius = 2; _shine.shadowOffset = CGSizeZero;
    [_holder.layer addSublayer:_rim]; [_holder.layer addSublayer:_shine];
    if (_light) { _holder.layer.shadowColor = UIColor.blackColor.CGColor; _holder.layer.shadowOpacity = 0.12; _holder.layer.shadowRadius = 12; _holder.layer.shadowOffset = CGSizeMake(0, 4); }
    [host insertSubview:_holder belowSubview:pill];
    // the pill's glass steps aside: from now on the pill sits on this one piece of glass
    pg.hidden = YES; (void)pg;
    [self draw];
    _last = 0;
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
    if (@available(iOS 15.0, *)) _link.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)followX:(CGFloat)x d:(CGFloat)d {
    UIView *pill = _pill; if (!pill.superview || _mode != 0) return;
    CGPoint px = [pill.window convertPoint:CGPointMake(x, 0) toView:pill.superview];
    _tx = px.x; _td = MAX(0, d);
}
- (void)retract { _mode = 1; _td = 0; }
// a drop (window circle) sitting above the pill is sucked down into it
- (void)absorbInto:(UIView *)pill circle:(CGRect)cw {
    [self beginOn:pill touchX:0];
    UIView *host = pill.superview; if (!host) return;
    CGRect c = [pill.window convertRect:cw toView:host];
    CGFloat top = CGRectGetMinY(pill.frame) + 0.5;
    _x = _tx = _bx = CGRectGetMidX(c);
    _d = MAX(0, top - CGRectGetMidY(c)); _vd = -160;
    _mode = 1; _td = 0; _absorbing = YES;
    [self draw];
}
- (void)detach { _mode = 2; _td = 0; }
- (void)step:(CADisplayLink *)l {
    CFTimeInterval now = CACurrentMediaTime(); double dt = _last > 0 ? MIN(1.0 / 30, now - _last) : 1.0 / 60; _last = now;
    // the drop chases the finger on a bouncy spring; the neck's foot on a lazier one
    double wD = 2 * M_PI / (_mode == 1 ? (_absorbing ? 0.22 : 0.26) : 0.16), zD = _mode == 1 ? 0.66 : 0.58;
    double wB = 2 * M_PI / 0.32, zB = 0.72;
    int n = 6; double h = dt / n;
    for (int i = 0; i < n; i++) {
        double ax = -wD * wD * (_x - _tx) - 2 * zD * wD * _vx; _vx += ax * h; _x += _vx * h;
        double ad = -wD * wD * (_d - _td) - 2 * zD * wD * _vd; _vd += ad * h; _d += _vd * h;
        double ab = -wB * wB * (_bx - _x) - 2 * zB * wB * _vbx; _vbx += ab * h; _bx += _vbx * h;
    }
    if (_mode == 2) { _rScale = MAX(0, _rScale - dt * 12); }
    if (_mode != 0 && _d < 0.5 && fabs(_vd) < 8) { [self cleanup]; return; }
    [self draw];
}
- (CGRect)dropRectInWindow {
    UIView *pill = _pill; CGRect P = pill.frame;
    CGFloat r = [self radiusFor:_d P:P];
    CGFloat cx = [self dropX:_x r:r P:P], by = [self dropY:_d r:r P:P];
    return [pill.superview convertRect:CGRectMake(cx - r, by - r, r * 2, r * 2) toView:pill.window];
}
// 1.5.6: the drop grows quickly at first and slows as it gets big
- (CGFloat)radiusFor:(CGFloat)d P:(CGRect)P {
    CGFloat t = MIN(1, MAX(0, d) / 80); t = 1 - (1 - t) * (1 - t);
    return MIN(P.size.height * 0.5, 6 + 22 * t);
}
// how formed the drop is: 0 = a soft bump on the pill, 1 = a round drop on a thin neck
static CGFloat GooForm(CGFloat d) { CGFloat x = MAX(0, MIN(1, (d - 4) / 56)); return x * x * (3 - 2 * x); }
// the drop's middle: at first it sits mostly inside the pill (just a bump), then it rises out
- (CGFloat)dropY:(CGFloat)d r:(CGFloat)r P:(CGRect)P { return CGRectGetMinY(P) + 0.5 - MAX(0, d) + r * 0.8 * (1 - GooForm(d)); }
// 1.5.10: the drop itself can rise anywhere along the top edge, all the way to the round ends; only its foot
// stays on the flat part, so near the ends the neck leans out toward the drop
- (CGFloat)dropX:(CGFloat)x r:(CGFloat)r P:(CGRect)P {
    CGFloat m = P.size.height / 2 + r * 0.5;   // stops just short of the round ends
    return MAX(CGRectGetMinX(P) + m, MIN(CGRectGetMaxX(P) - m, x));
}
- (CGFloat)clampX:(CGFloat)x r:(CGFloat)r P:(CGRect)P {
    CGFloat R = P.size.height / 2, base = r * 1.9 + 12;
    return MAX(CGRectGetMinX(P) + R + base, MIN(CGRectGetMaxX(P) - R - base, x));
}
- (void)draw {
    UIView *pill = _pill; if (!pill.superview) return;
    CGRect P = pill.frame;
    CGFloat d = MAX(0, _d);
    CGFloat R = P.size.height / 2, top = CGRectGetMinY(P), bottom = CGRectGetMaxY(P);
    // squash and stretch with the speed: moving fast it gets taller and thinner
    CGFloat stretch = MIN(0.22, fabs(_vd) / 2600);
    CGFloat r0 = [self radiusFor:d P:P] * _rScale;
    CGFloat rx = r0 * (1 - stretch * 0.5), ry = r0 * (1 + stretch);
    CGFloat cx = [self dropX:_x r:r0 P:P], fx = [self clampX:_bx r:r0 P:P];
    CGFloat form = GooForm(d);
    // surface tension: while you hold it, it quivers a tiny bit
    if (_mode == 0) { CGFloat q = sin(CACurrentMediaTime() * 9) * 0.025 * (1 - form * 0.5); ry *= 1 + q; rx *= 1 - q * 0.6; }
    CGFloat by = [self dropY:d r:r0 P:P];
    // a wide soft foot at first (a bump), narrowing into a neck that pinches thinner as it rises
    CGFloat base = r0 * (1.9 - 0.3 * form) + 8 + 4 * form;
    CGFloat neck = r0 * (1.05 - 0.75 * form) + 0.9 * form;
    CGFloat lean = (cx - fx) * 0.5;
    UIBezierPath *p = [UIBezierPath bezierPath];
    // the pill (a capsule) with the drop rising out of its top edge, as one outline
    [p moveToPoint:CGPointMake(CGRectGetMinX(P) + R, top)];
    if (r0 > 0.5 && d > 0.5) {
        [p addLineToPoint:CGPointMake(fx - base, top)];
        CGPoint lt = CGPointMake(cx - rx * 0.95, MIN(top - 0.3, by + ry * 0.3)), rt = CGPointMake(cx + rx * 0.95, MIN(top - 0.3, by + ry * 0.3));
        [p addCurveToPoint:lt controlPoint1:CGPointMake(fx - base * 0.42, top) controlPoint2:CGPointMake(cx - neck + lean * 0.2, MIN(top, by + ry + (top - by - ry) * 0.5))];
        // the drop: an ellipse top from left to right
        int segs = 18; double a0 = M_PI - 0.31, a1 = 2 * M_PI + 0.31;
        for (int i = 1; i <= segs; i++) { double a = a0 + (a1 - a0) * i / segs; [p addLineToPoint:CGPointMake(cx + rx * cos(a), MIN(top - 0.3, by + ry * sin(a)))]; }
        [p addLineToPoint:rt];
        [p addCurveToPoint:CGPointMake(fx + base, top) controlPoint1:CGPointMake(cx + neck + lean * 0.2, MIN(top, by + ry + (top - by - ry) * 0.5)) controlPoint2:CGPointMake(fx + base * 0.42, top)];
    }
    [p addLineToPoint:CGPointMake(CGRectGetMaxX(P) - R, top)];
    [p addArcWithCenter:CGPointMake(CGRectGetMaxX(P) - R, top + R) radius:R startAngle:-M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [p addLineToPoint:CGPointMake(CGRectGetMinX(P) + R, bottom)];
    [p addArcWithCenter:CGPointMake(CGRectGetMinX(P) + R, top + R) radius:R startAngle:M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];
    [p closePath];
    // ink only on the drop and neck
    UIBezierPath *inkP = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetMinX(P), by - ry - 4, P.size.width, MAX(0, top - (by - ry - 4)) + 2)];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    _shape.path = p.CGPath; _rim.path = p.CGPath;
    _inkMask.path = inkP.CGPath;
    _ink.startPoint = CGPointMake(0.5, (by - ry) / MAX(1, _holder.bounds.size.height));
    _ink.endPoint = CGPointMake(0.5, (top + 2) / MAX(1, _holder.bounds.size.height));
    _ink.opacity = MIN(1, d / 24);
    _shine.path = r0 > 3 ? [UIBezierPath bezierPathWithOvalInRect:CGRectMake(cx - rx + 2.5, by - ry + 2.5, rx * 2 - 5, ry * 2 - 5)].CGPath : nil;
    _shine.strokeStart = 0.55; _shine.strokeEnd = 0.82;
    _shine.opacity = MIN(1, d / 26);
    if (_light) _holder.layer.shadowPath = p.CGPath;
    [CATransaction commit];
}
- (void)cleanup {
    [_link invalidate]; _link = nil;
    UIView *pill = _pill;
    if (_holder && _mode == 1 && pill.window) {
        // swallowed: the pill gives a squishy bounce
        XLandBounce(pill.layer);
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:_absorbing ? UIImpactFeedbackStyleSoft : UIImpactFeedbackStyleLight] impactOccurred];
    }
    _absorbing = NO;
    UIView *pg = [pill respondsToSelector:@selector(glass)] ? [pill valueForKey:@"glass"] : nil;
    pg.hidden = NO;
    [_holder removeFromSuperview]; _holder = nil;
}
@end
static MPGoo *gGoo;
static void XGooAbsorb(UIView *pill, CGRect circleWin) {
    if (!gGoo) gGoo = [MPGoo new];
    [gGoo absorbInto:pill circle:circleWin];
}

@implementation MPPillPan { int _axis; BOOL _opened; }   // 1 = sideways, 2 = up
// the drop lets go of the pill and becomes the Dynamic Pill: it grows out of the drop, the neck snaps back
- (void)openFrom:(UIView *)v {
    CGRect c = [gGoo dropRectInWindow];
    gDropX = CGRectGetMidX(c);
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    XTouchLight(v, CGPointZero, NO);
    [MPIsland expandFrom:v circle:c];
    [gGoo detach];
}
+ (instancetype)shared { static MPPillPan *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPPillPan new]; }); return s; }
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    if (!gRound) return NO;
    CGPoint v = [g velocityInView:g.view];
    if (fabs(v.x) > fabs(v.y)) { _axis = 1; return gSwipe; }
    if (v.y < 0) { _axis = 2; return gPillHold; }
    return NO;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return NO; }
static void XTouchLight(UIView *pillView, CGPoint p, BOOL on) {
    // inside the pill's glass, so the light stays within its shape
    UIView *v = [pillView viewWithTag:GLASS_TAG];
    if (!v && [pillView isKindOfClass:[MPMiniPill class]]) v = ((MPMiniPill *)pillView).glass;
    if (!v) v = pillView;
    p = [pillView convertPoint:p toView:v];
    CAGradientLayer *gl = nil;
    for (CALayer *l in v.layer.sublayers) if ([l.name isEqualToString:@"mp.touch"]) gl = (CAGradientLayer *)l;
    if (!on) {
        if (gl) { [CATransaction begin]; [CATransaction setAnimationDuration:0.35]; gl.opacity = 0; [CATransaction commit]; }
        return;
    }
    if (!gl) {
        gl = [CAGradientLayer layer]; gl.name = @"mp.touch"; gl.type = kCAGradientLayerRadial;
        gl.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.42].CGColor, (id)[UIColor colorWithWhite:1 alpha:0.12].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        gl.locations = @[@0, @0.45, @1];
        gl.startPoint = CGPointMake(0.5, 0.5); gl.endPoint = CGPointMake(1, 1);
        gl.opacity = 0;
        [v.layer addSublayer:gl];
    }
    CGFloat d = MAX(90, v.bounds.size.height * 2.2);
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    gl.bounds = CGRectMake(0, 0, d, d); gl.position = p; gl.cornerRadius = d / 2;
    [CATransaction commit];
    if (gl.opacity < 1) { [CATransaction begin]; [CATransaction setAnimationDuration:0.18]; gl.opacity = 1; [CATransaction commit]; }
}
// Music's real bar takes the touches but is invisible (masked) while our pill stands in for it:
// the drag, light and bounce have to play on the pill you can see.
static UIView *XVisualPill(UIView *touched) {
    MPMiniPill *pill = (MPMiniPill *)gPillObj;
    if ([pill isKindOfClass:[MPMiniPill class]] && pill.window && !pill.hidden && pill.alpha > 0.05 &&
        (touched == pill || objc_getAssociatedObject(touched, kMiniMask))) return pill;
    return touched;
}
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = XVisualPill(g.view);
    CGPoint t = [g translationInView:v.superview], vel = [g velocityInView:v.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
        CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:@"transform.scale"];   // the glass swells under your finger
        a.additive = YES; a.fromValue = @(-0.03); a.toValue = @0; a.stiffness = 400; a.damping = 16; a.duration = a.settlingDuration;
        [v.layer addAnimation:a forKey:@"mp.touchdown"];
    }
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) XTouchLight(v, [g locationInView:v], YES);
    else XTouchLight(v, CGPointZero, NO);
    if (g.state == UIGestureRecognizerStateBegan) _opened = NO;
    if (_opened) { if (g.state != UIGestureRecognizerStateChanged) XTouchLight(v, CGPointZero, NO); return; }
    if (_axis == 2 && v.window && [v isKindOfClass:[MPMiniPill class]]) {
        if (!gGoo) gGoo = [MPGoo new];
        CGFloat raw = MAX(0, -t.y);
        // 1.5.8: the drop has a height limit: past 80 pt it barely moves (a soft rubber band), never past ~92 pt
        CGFloat d = raw < 80 ? raw : 80 + 12 * (1 - 1 / ((raw - 80) / 40 + 1));
        if (g.state == UIGestureRecognizerStateBegan) { [v.layer removeAnimationForKey:@"mp.release"]; SetDrag(v, 0, 0); [gGoo beginOn:v touchX:[g locationInView:v.superview].x]; }
        if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
            [gGoo followX:[g locationInView:v.window].x d:d];
            // 1.5.9: pulled past the limit, the drop snaps loose and opens right away
            if (raw > 96) { _opened = YES; [self openFrom:v]; }
            return;
        }
        // let go: it opens (unless you barely moved, or pulled back down into the pill)
        // 1.5.6: let go early and it goes back in; it only opens once the drop is big (or with a real flick up)
        BOOL open = g.state == UIGestureRecognizerStateEnded && (raw > 62 || (vel.y < -900 && raw > 20)) && vel.y < 300;
        if (open) { _opened = YES; [self openFrom:v]; return; }
        [gGoo retract];
        XBounce(v, 0, -4, NO);
        return;
    }
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        [v.layer removeAnimationForKey:@"mp.release"];
        if (_axis == 1) SetDrag(v, XRubber(t.x, 38), 0);
        else SetDrag(v, 0, XRubber(MIN(0, t.y), 26));
        return;
    }
    BOOL ended = g.state == UIGestureRecognizerStateEnded;
    if (_axis == 1) {
        BOOL go = ended && (fabs(t.x) > 55 || (fabs(vel.x) > 450 && t.x * vel.x > 0));
        if (go) {
            BOOL next = t.x < 0;
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
            SkipTrack(next);
            id pillObj = gPillObj;
            if (pillObj && pillObj != v && [pillObj respondsToSelector:@selector(refresh)]) [pillObj performSelector:@selector(refresh)];
        }
        XBounce(v, XRubber(t.x, 38), 0, go);
    } else {
        BOOL go = ended && (t.y < -34 || vel.y < -420);
        if (go) [MPIsland expandFrom:v];
        else XBounce(v, 0, XRubber(MIN(0, t.y), 26), NO);
    }
}
@end
static void AddPillPan(UIView *v) {
    static const void *kPan = &kPan;
    if (!v || objc_getAssociatedObject(v, kPan)) return;
    objc_setAssociatedObject(v, kPan, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:[MPPillPan shared] action:@selector(pan:)];
    p.delegate = [MPPillPan shared]; p.maximumNumberOfTouches = 1; p.cancelsTouchesInView = YES;
    [v addGestureRecognizer:p];
}

// Music's own swipe up on the bar (opens the player) is switched off: tap opens it instead.
static NSHashTable *gXOffPans;
static BOOL XIsOurs(UIGestureRecognizer *g) {
    if ([g.delegate isKindOfClass:[MPPillPan class]]) return YES;
    NSArray *targets = nil;
    @try { targets = [g valueForKey:@"_targets"]; } @catch (__unused id e) {}
    for (id tg in targets) { id target = nil; @try { target = [tg valueForKey:@"_target"]; } @catch (__unused id e) {} if ([NSStringFromClass([target class]) hasPrefix:@"MP"]) return YES; }
    return NO;
}
static void XBarSwipes(UIView *mini, BOOL off) {
    if (!gXOffPans) gXOffPans = [NSHashTable weakObjectsHashTable];
    if (!off) { for (UIGestureRecognizer *g in [gXOffPans allObjects]) g.enabled = YES; [gXOffPans removeAllObjects]; return; }
    for (UIView *v = mini; v; v = v.superview) {
        for (UIGestureRecognizer *g in v.gestureRecognizers) {
            if (![g isKindOfClass:[UIPanGestureRecognizer class]] && ![g isKindOfClass:[UISwipeGestureRecognizer class]]) continue;
            if ([v isKindOfClass:[UIScrollView class]] && g == ((UIScrollView *)v).panGestureRecognizer) continue;
            if (XIsOurs(g) || !g.enabled) continue;
            g.enabled = NO; [gXOffPans addObject:g];
        }
        if ([NSStringFromClass([v class]) hasSuffix:@"PaletteContainerView"]) break;
    }
}

// holding the pill: Music's own song menu (the one you get holding a song)
@interface MPHoldMenu : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation MPHoldMenu
+ (instancetype)shared { static MPHoldMenu *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPHoldMenu new]; }); return s; }
- (void)held:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan || gPillHold) return;   // with Dynamic Pill, holding peeks instead (PillPeek.h)
    UIView *mini = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
    UIContextMenuInteraction *mi = mini ? MenuInteractionNear(mini) : nil;
    if (mi) { [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred]; OpenMenu(mini, mi); }
}
@end
static void AddHoldMenu(UIView *pill) {
    static const void *kHM = &kHM;
    if (!pill || objc_getAssociatedObject(pill, kHM)) return;
    objc_setAssociatedObject(pill, kHM, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[MPHoldMenu shared] action:@selector(held:)];
    lp.minimumPressDuration = 0.45;
    [pill addGestureRecognizer:lp];
}

#pragma mark - waveform on the pill (moves like music: every bar finds its own level, smoothly)

@interface MPWave : UIView
- (void)setPlaying:(BOOL)p;
@end
@implementation MPWave { BOOL _on; NSArray<CALayer *> *_bars; CADisplayLink *_link; double _cur[5], _tgt[5], _next[5]; CFTimeInterval _t; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42];
    self.layer.cornerCurve = kCACornerCurveContinuous;
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < 5; i++) { CALayer *l = [CALayer layer]; l.backgroundColor = UIColor.whiteColor.CGColor; [self.layer addSublayer:l]; [a addObject:l]; _cur[i] = 0.2; _tgt[i] = 0.2; }
    _bars = a;
    return self;
}
- (void)didMoveToWindow { [super didMoveToWindow]; if (!self.window) { [_link invalidate]; _link = nil; } else [self kick]; }
- (void)kick {
    if (_link || !self.window) return;
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
    if (@available(iOS 15.0, *)) _link.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)setPlaying:(BOOL)p { _on = p; [self kick]; }
- (void)step:(CADisplayLink *)l {
    CFTimeInterval now = l.timestamp; double dt = _t ? MIN(0.05, now - _t) : 1 / 60.0; _t = now;
    BOOL moving = NO;
    for (int i = 0; i < 5; i++) {
        if (_on && now >= _next[i]) {
            // middle bars reach higher, like a voice/beat; each picks a new level on its own beat
            double peak = (i == 2 ? 1.0 : (i == 1 || i == 3 ? 0.85 : 0.65));
            _tgt[i] = 0.18 + ((double)arc4random_uniform(1000) / 1000.0) * (peak - 0.18);
            _next[i] = now + 0.09 + arc4random_uniform(160) / 1000.0;
        }
        if (!_on) _tgt[i] = 0.18;
        double k = _tgt[i] > _cur[i] ? 18 : 9;   // quick up, softer down
        _cur[i] += (_tgt[i] - _cur[i]) * MIN(1, k * dt);
        if (fabs(_tgt[i] - _cur[i]) > 0.003) moving = YES;
    }
    [self layoutBars];
    if (!_on && !moving) { [_link invalidate]; _link = nil; }
}
- (void)layoutBars {
    CGSize S = self.bounds.size;
    CGFloat bw = MAX(2, S.width * 0.09), gap = bw * 0.7, total = bw * 5 + gap * 4, x0 = (S.width - total) / 2, maxH = S.height * 0.62;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (int i = 0; i < 5; i++) {
        CGFloat h = MAX(bw, maxH * _cur[i]);
        _bars[i].frame = CGRectMake(x0 + i * (bw + gap), (S.height - h) / 2, bw, h);   // grows from the middle, both ways
        _bars[i].cornerRadius = bw / 2;
    }
    [CATransaction commit];
}
- (void)layoutSubviews { [super layoutSubviews]; self.layer.cornerRadius = MIN(self.bounds.size.width, self.bounds.size.height) * 0.32; [self layoutBars]; }
@end
// the cover image in a bar: the left-most square-ish image
static UIImageView *XArtIn(UIView *bar) {
    UIImageView *best = nil; CGFloat bx = CGFLOAT_MAX;
    NSMutableArray *q = [NSMutableArray arrayWithObject:bar]; int n = 0;
    while (q.count && n++ < 300) {
        UIView *v = q.firstObject; [q removeObjectAtIndex:0];
        if ([v isKindOfClass:[UIImageView class]] && !v.hidden && v.alpha > 0.1) {
            CGSize s = v.bounds.size;
            if (s.width >= 28 && s.width <= 70 && fabs(s.width - s.height) < 4) {
                CGFloat x = [v convertPoint:CGPointZero toView:bar].x;
                if (x < bx) { bx = x; best = (UIImageView *)v; }
            }
        }
        [q addObjectsFromArray:v.subviews];
    }
    return best;
}
static void PlaceWave(UIView *bar, UIImageView *art, BOOL show) {
    static const void *kWave = &kWave;
    MPWave *w = objc_getAssociatedObject(bar, kWave);
    if (!show || !art.window) { if (w) { [w removeFromSuperview]; objc_setAssociatedObject(bar, kWave, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); } return; }
    if (!w || w.superview != art.superview) {
        [w removeFromSuperview];
        w = [[MPWave alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(bar, kWave, w, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [art.superview addSubview:w];
    }
    CGFloat d = MAX(16, art.bounds.size.width * 0.42);
    CGRect af = art.frame;
    CGRect f = CGRectMake(CGRectGetMaxX(af) - d - 2, CGRectGetMaxY(af) - d * 0.8 - 2, d, d * 0.8);
    if (!CGRectEqualToRect(w.frame, f)) w.frame = f;
    if (w.superview.subviews.lastObject != w) [w.superview bringSubviewToFront:w];
    [w setPlaying:gXPlaying];
}

#pragma mark - one tick for all of it

static dispatch_source_t gXTimer;
static CFAbsoluteTime gXLast;
static void ExtrasTick(void) {
    XPoll();
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (gXLast > 0) XLogTick(now - gXLast);
    gXLast = now;
    SleepTick();
    if ([MPSleepCtl shared].sheet.window) [[MPSleepCtl shared] update];
    UITabBar *tb = gLastTabBar;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    MPMiniPill *pill = (MPMiniPill *)gPillObj;
    BOOL isPill = [pill isKindOfClass:[MPMiniPill class]];
    BOOL show = gWave && gRound && gEverPlayed && gXTitle.length;
    if (mini) PlaceWave(mini, show ? XArtIn(mini) : nil, show && mini.window && mini.alpha > 0.05);
    if (isPill) PlaceWave(pill, show ? pill.art : nil, show && !pill.hidden && pill.art.image);
    if (mini && gRound) { AddPillPan(mini); XBarSwipes(mini, gTapOpen); }
    if (!gTapOpen || !gRound) XBarSwipes(nil, NO);
    if (isPill) { AddPillPan(pill); AddHoldMenu(pill); }
}
static void StartExtras(void) {
    if (gXTimer) return;
    gXTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(gXTimer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.5 * NSEC_PER_SEC), (uint64_t)(0.1 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(gXTimer, ^{ @try { ExtrasTick(); } @catch (__unused id e) {} });
    dispatch_resume(gXTimer);
}
