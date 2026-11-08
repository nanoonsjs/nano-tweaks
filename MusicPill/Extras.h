// ===================== MusicPill extras =====================
// Hold the pill: a glass menu with Up Next, Sleep Timer and Music Insights.
// Animated waveform on the pill while music plays. Listening log for Insights.
// (Included from Tweak.x just before %ctor, so everything above is available here.)

#define gPillHold gPillHoldPref
#define gWave gWavePref

#pragma mark - now playing (MediaRemote), polled once a second

static NSString *gXTitle, *gXArtist;
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
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h;
- (void)close;
@end
@implementation MPSheet
+ (MPSheet *)showIn:(UIWindow *)w height:(CGFloat)h {
    MPSheet *s = [[MPSheet alloc] initWithFrame:w.bounds];
    s.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [s addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:s action:@selector(bgTap:)]];
    CGFloat W = w.bounds.size.width - 24;
    s.panel = XGlass(34);
    s.panel.frame = CGRectMake(12, w.bounds.size.height - h - MAX(16, w.safeAreaInsets.bottom), W, h);
    [s addSubview:s.panel];
    [w addSubview:s];
    s.panel.transform = CGAffineTransformMakeTranslation(0, h + 60);
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:0 animations:^{
        s.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35]; s.panel.transform = CGAffineTransformIdentity;
    } completion:nil];
    return s;
}
- (void)bgTap:(UITapGestureRecognizer *)g { if (!CGRectContainsPoint(self.panel.frame, [g locationInView:self])) [self close]; }
- (void)close {
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:0 animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0]; self.panel.transform = CGAffineTransformMakeTranslation(0, self.panel.bounds.size.height + 60);
    } completion:^(__unused BOOL f) { [self removeFromSuperview]; }];
}
@end

#pragma mark - Sleep Timer sheet

@interface MPSleepCtl : NSObject
+ (instancetype)shared;
@property (nonatomic, weak) MPSheet *sheet;
@property (nonatomic, weak) UILabel *status;
@property (nonatomic, strong) NSMutableArray *chips;
@end
@implementation MPSleepCtl
+ (instancetype)shared { static MPSleepCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPSleepCtl new]; }); return s; }
- (void)showIn:(UIWindow *)w {
    MPSheet *sh = [MPSheet showIn:w height:300];
    self.sheet = sh;
    UIView *c = sh.panel.contentView; CGFloat W = sh.panel.bounds.size.width;
    UIImageView *moon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"moon.zzz.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightSemibold]]];
    moon.tintColor = [UIColor colorWithRed:0.62 green:0.55 blue:1 alpha:1]; moon.frame = CGRectMake(22, 22, 30, 30); moon.contentMode = UIViewContentModeCenter;
    [c addSubview:moon];
    UILabel *t = XLabel(@"Sleep Timer", 22, UIFontWeightBold, nil); t.frame = CGRectMake(60, 22, W - 80, 30); [c addSubview:t];
    UILabel *st = XLabel(@"", 15, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.6]); st.frame = CGRectMake(22, 58, W - 44, 20); [c addSubview:st];
    self.status = st;
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
    }
    [self update];
}
- (void)pick:(UIButton *)b {
    XJelly(b);
    [[UISelectionFeedbackGenerator new] selectionChanged];
    gSleepEndOfSong = b.tag == -1;
    gSleepPick = (int)b.tag;
    gSleepEnd = b.tag > 0 ? CFAbsoluteTimeGetCurrent() + b.tag * 60 : 0;
    [self update];
    if (b.tag != 0) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self.sheet close]; });
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

#pragma mark - Music Insights sheet

static NSString *XDur(double s) {
    long m = (long)(s / 60);
    if (m >= 60) return [NSString stringWithFormat:@"%ldh %ldm", m / 60, m % 60];
    return [NSString stringWithFormat:@"%ldm", MAX(0L, m)];
}
static NSString *XTop(NSDictionary *d, double *val) {
    NSString *best = nil; double v = -1;
    for (NSString *k in d) { double x = [d[k] doubleValue]; if (x > v) { v = x; best = k; } }
    if (val) *val = v;
    return best;
}
@interface MPInsightsCtl : NSObject
+ (void)showIn:(UIWindow *)w;
@end
@implementation MPInsightsCtl
static UIView *XCard(UIView *parent, CGRect f, NSString *head, NSString *big, NSString *small, UIColor *accent) {
    UIView *card = [[UIView alloc] initWithFrame:f];
    card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    card.layer.cornerRadius = 22; card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 0.6; card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    UILabel *h = XLabel(head.uppercaseString, 12, UIFontWeightSemibold, accent); h.frame = CGRectMake(14, 12, f.size.width - 28, 16); [card addSubview:h];
    UILabel *b = XLabel(big ?: @"–", 20, UIFontWeightBold, nil); b.frame = CGRectMake(14, 32, f.size.width - 28, 26); [card addSubview:b];
    UILabel *s = XLabel(small ?: @"", 13, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.6]); s.frame = CGRectMake(14, 58, f.size.width - 28, 18); [card addSubview:s];
    [parent addSubview:card];
    return card;
}
+ (void)showIn:(UIWindow *)w {
    XLoad();
    [[NSUserDefaults standardUserDefaults] setObject:gXLog forKey:@"mp.insights"];
    MPSheet *sh = [MPSheet showIn:w height:MIN(560, w.bounds.size.height - 120)];
    UIView *c = sh.panel.contentView; CGFloat W = sh.panel.bounds.size.width;
    UILabel *t = XLabel(@"Music Insights", 24, UIFontWeightBold, nil); t.frame = CGRectMake(22, 22, W - 44, 30); [c addSubview:t];
    UIColor *pink = [UIColor colorWithRed:1 green:0.27 blue:0.42 alpha:1];
    // this week: a bar per day, Monday first
    NSDictionary *days = gXLog[@"days"];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
    NSDate *ws = nil; [cal rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&ws interval:NULL forDate:[NSDate date]];
    double vals[7], total = 0, mx = 1;
    for (int i = 0; i < 7; i++) { NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:i toDate:ws ?: [NSDate date] options:0]; vals[i] = [days[XDayKey(d)] doubleValue]; total += vals[i]; mx = MAX(mx, vals[i]); }
    UIView *wk = XCard(c, CGRectMake(16, 64, W - 32, 170), @"This Week", XDur(total), @"listening time", pink);
    NSArray *dn = @[@"M", @"T", @"W", @"T", @"F", @"S", @"S"];
    CGFloat bw = (W - 32 - 28) / 7;
    NSInteger today = ([cal component:NSCalendarUnitWeekday fromDate:[NSDate date]] + 5) % 7;
    for (int i = 0; i < 7; i++) {
        CGFloat bh = MAX(4, 58 * vals[i] / mx);
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(14 + i * bw + bw * 0.25, 150 - bh, bw * 0.5, bh)];
        bar.backgroundColor = i == today ? pink : [UIColor colorWithWhite:1 alpha:0.35];
        bar.layer.cornerRadius = MIN(bw * 0.25, 6);
        [wk addSubview:bar];
        bar.transform = CGAffineTransformMakeScale(1, 0.01); bar.layer.anchorPoint = CGPointMake(0.5, 1); bar.frame = CGRectMake(14 + i * bw + bw * 0.25, 150 - bh, bw * 0.5, bh);
        [UIView animateWithDuration:0.6 delay:0.15 + i * 0.04 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{ bar.transform = CGAffineTransformIdentity; } completion:nil];
        UILabel *l = XLabel(dn[i], 11, UIFontWeightMedium, [UIColor colorWithWhite:1 alpha:0.5]); l.textAlignment = NSTextAlignmentCenter;
        l.frame = CGRectMake(14 + i * bw, 152, bw, 14); [wk addSubview:l];
    }
    // this week's favorites (from what MusicPill has heard you play)
    double v1 = 0, v2 = 0;
    NSString *wa = XTop(gXLog[@"weekArtists"], &v1), *wsng = XTop(gXLog[@"weekSongs"], &v2);
    CGFloat hw = (W - 32 - 10) / 2;
    XCard(c, CGRectMake(16, 244, hw, 86), @"Top Artist", wa, wa ? [NSString stringWithFormat:@"%@ this week", XDur(v1)] : @"play some music", pink);
    NSArray *sp = [wsng componentsSeparatedByString:@"\n"];
    XCard(c, CGRectMake(16 + hw + 10, 244, hw, 86), @"Top Song", sp.firstObject, sp.count > 1 ? sp[1] : (wsng ? @"" : @"play some music"), pink);
    // all time, from your library's play counts
    NSString *libSong = nil, *libArtist = nil; unsigned long libPlays = 0; double libTime = 0;
    @try {
        MPMediaQuery *q = [MPMediaQuery songsQuery];
        NSMutableDictionary *ar = [NSMutableDictionary dictionary];
        for (MPMediaItem *it in q.items) {
            NSUInteger pc = it.playCount;
            libTime += pc * it.playbackDuration;
            if (pc > libPlays) { libPlays = pc; libSong = it.title; }
            if (it.artist.length) ar[it.artist] = @([ar[it.artist] unsignedLongValue] + pc);
        }
        double av = 0; libArtist = XTop(ar, &av);
    } @catch (__unused id e) {}
    XCard(c, CGRectMake(16, 340, hw, 86), @"Most Played", libSong, libSong ? [NSString stringWithFormat:@"%lu plays", libPlays] : @"", pink);
    XCard(c, CGRectMake(16 + hw + 10, 340, hw, 86), @"All-Time Artist", libArtist, libTime > 0 ? [NSString stringWithFormat:@"%@ total", XDur(libTime)] : @"", pink);
    UILabel *foot = XLabel(@"This week counts what you've played since installing. All-time comes from your library's play counts.", 12, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.45]);
    foot.numberOfLines = 2; foot.adjustsFontSizeToFitWidth = NO; foot.frame = CGRectMake(22, 436, W - 44, 34); [c addSubview:foot];
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

#pragma mark - hold the pill: glass menu

@interface MPHoldCtl : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@property (nonatomic, weak) UIView *from;
@property (nonatomic, weak) MPSheet *menu;
@end
@implementation MPHoldCtl
+ (instancetype)shared { static MPHoldCtl *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [MPHoldCtl new]; }); return s; }
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g { return gPillHold && gRound; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)o {
    return gPillHold && ![o isKindOfClass:[UISwipeGestureRecognizer class]] && ![o isKindOfClass:[UITapGestureRecognizer class]];   // Music's own long press waits for ours
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return NO; }
- (void)held:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    UIView *v = g.view; UIWindow *w = v.window;
    if (!w) return;
    self.from = v;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    XJelly(v);
    MPSheet *sh = [MPSheet showIn:w height:3 * 62 + 24];
    self.menu = sh;
    UIView *c = sh.panel.contentView; CGFloat W = sh.panel.bounds.size.width;
    NSString *sleep = SleepStatus();
    NSArray *rows = @[@[@"list.bullet", @"Up Next", @"Reorder, remove and add songs"],
                      @[@"moon.zzz.fill", @"Sleep Timer", sleep ? [NSString stringWithFormat:@"On · %@", sleep] : @"Stop music after a while"],
                      @[@"chart.bar.fill", @"Music Insights", @"Your top artist, songs and listening time"]];
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
        iv.tintColor = i == 1 ? [UIColor colorWithRed:0.66 green:0.58 blue:1 alpha:1] : [UIColor colorWithRed:1 green:0.3 blue:0.45 alpha:1];
        iv.contentMode = UIViewContentModeCenter; iv.frame = ic.bounds; [ic addSubview:iv];
        [b addSubview:ic];
        UILabel *t = XLabel(rows[i][1], 17, UIFontWeightSemibold, nil); t.frame = CGRectMake(62, 9, W - 100, 22); t.userInteractionEnabled = NO; [b addSubview:t];
        UILabel *s = XLabel(rows[i][2], 13, UIFontWeightRegular, [UIColor colorWithWhite:1 alpha:0.55]); s.frame = CGRectMake(62, 31, W - 100, 18); s.userInteractionEnabled = NO; [b addSubview:s];
        [c addSubview:b];
        b.alpha = 0; b.transform = CGAffineTransformMakeTranslation(0, 14);
        [UIView animateWithDuration:0.45 delay:0.08 + i * 0.05 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.alpha = 1; b.transform = CGAffineTransformIdentity; } completion:nil];
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
        if (b.tag == 0) OpenUpNext(gHiddenMini ?: from);
        else if (b.tag == 1) [[MPSleepCtl shared] showIn:w];
        else [MPInsightsCtl showIn:w];
    });
}
@end
static void AddHold(UIView *v) {
    static const void *kHold = &kHold;
    if (!v || objc_getAssociatedObject(v, kHold)) return;
    objc_setAssociatedObject(v, kHold, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[MPHoldCtl shared] action:@selector(held:)];
    lp.minimumPressDuration = 0.4; lp.delegate = [MPHoldCtl shared];
    [v addGestureRecognizer:lp];
}

#pragma mark - animated waveform on the pill

@interface MPWave : UIView
- (void)setPlaying:(BOOL)p;
@end
@implementation MPWave { BOOL _on; NSArray<CALayer *> *_bars; }
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.layer.cornerCurve = kCACornerCurveContinuous;
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < 4; i++) { CALayer *l = [CALayer layer]; l.backgroundColor = UIColor.whiteColor.CGColor; [self.layer addSublayer:l]; [a addObject:l]; }
    _bars = a;
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize S = self.bounds.size;
    self.layer.cornerRadius = MIN(S.width, S.height) * 0.3;
    CGFloat bw = 2.2, gap = 2, total = bw * 4 + gap * 3, x0 = (S.width - total) / 2, h = S.height * 0.56;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for (NSUInteger i = 0; i < _bars.count; i++) {
        CALayer *l = _bars[i];
        l.anchorPoint = CGPointMake(0.5, 1);
        l.bounds = CGRectMake(0, 0, bw, h); l.cornerRadius = bw / 2;
        l.position = CGPointMake(x0 + i * (bw + gap) + bw / 2, (S.height + h) / 2);
    }
    [CATransaction commit];
}
- (void)setPlaying:(BOOL)p {
    if (p == _on && (_on ? [_bars.firstObject animationForKey:@"w"] != nil : YES)) return;
    _on = p;
    NSArray *durs = @[@0.42, @0.55, @0.36, @0.5];
    for (NSUInteger i = 0; i < _bars.count; i++) {
        CALayer *l = _bars[i];
        [l removeAnimationForKey:@"w"];
        if (p) {
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
            a.fromValue = @0.25; a.toValue = @1; a.duration = [durs[i] doubleValue];
            a.autoreverses = YES; a.repeatCount = HUGE_VALF;
            a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            a.timeOffset = i * 0.13;
            [l addAnimation:a forKey:@"w"];
            l.transform = CATransform3DIdentity;
        } else {
            l.transform = CATransform3DMakeScale(1, 0.25, 1);
        }
    }
}
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
    // a small badge in the cover's bottom-right corner
    CGFloat d = MAX(14, art.bounds.size.width * 0.38);
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
    // waveform on Music's bar (styled as the pill) and on the minimized pill
    UITabBar *tb = gLastTabBar;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    BOOL show = gWave && gRound && gEverPlayed && gXTitle.length;
    if (mini) PlaceWave(mini, show ? XArtIn(mini) : nil, show && mini.window && mini.alpha > 0.05);
    MPMiniPill *pill = (MPMiniPill *)gPillObj;
    if ([pill isKindOfClass:[MPMiniPill class]]) PlaceWave(pill, show ? pill.art : nil, show && !pill.hidden && pill.art.image);
    if (mini) AddHold(mini);
    if ([pill isKindOfClass:[MPMiniPill class]]) AddHold(pill);
}
static void StartExtras(void) {
    if (gXTimer) return;
    gXTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(gXTimer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(1.0 * NSEC_PER_SEC), (uint64_t)(0.1 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(gXTimer, ^{ @try { ExtrasTick(); } @catch (__unused id e) {} });
    dispatch_resume(gXTimer);
}
