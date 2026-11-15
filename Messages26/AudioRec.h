// ===================== Messages26: Voice Recorder =====================
// 1.6: tap the mic instead of holding it. A glass bar takes the field's place: live waveform and timer while
// recording (high quality), then a preview you can play and scrub before sending, X to throw it away.
// Apple's hold-to-record stays out of the way while it's on. Included from Tweak.x after VidVoice.h.
#import <AVFoundation/AVFoundation.h>

#define REC_TAG 0x4D32524D

#pragma mark - waveform

@interface M26Wave : UIView
@property (nonatomic, strong) NSMutableArray<NSNumber *> *levels;   // 0..1
@property (nonatomic) CGFloat progress;    // played part (0..1), or -1 while recording (newest at the right)
@property (nonatomic, strong) UIColor *played, *rest;
@end
@implementation M26Wave
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) { self.levels = [NSMutableArray array]; self.progress = -1; self.backgroundColor = UIColor.clearColor; self.opaque = NO; self.contentMode = UIViewContentModeRedraw; }
    return self;
}
- (void)drawRect:(CGRect)r {
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height, bw = 2.6, gap = 2.2;
    NSInteger n = MAX(1, (NSInteger)floor((W + gap) / (bw + gap)));
    NSArray *src = self.levels;
    NSMutableArray *bars = [NSMutableArray arrayWithCapacity:n];
    if (self.progress < 0) {   // recording: the last n levels, sliding left
        NSInteger s = MAX(0, (NSInteger)src.count - n);
        for (NSInteger i = s; i < (NSInteger)src.count; i++) [bars addObject:src[i]];
        while ((NSInteger)bars.count < n) [bars insertObject:@0 atIndex:0];
    } else {               // preview: the whole recording squeezed into n bars
        for (NSInteger i = 0; i < n; i++) {
            if (!src.count) { [bars addObject:@0]; continue; }
            NSInteger a = i * src.count / n, b = MAX(a + 1, (i + 1) * src.count / n);
            CGFloat m = 0; for (NSInteger k = a; k < b && k < (NSInteger)src.count; k++) m = MAX(m, [src[k] doubleValue]);
            [bars addObject:@(m)];
        }
    }
    for (NSInteger i = 0; i < n; i++) {
        CGFloat v = MAX(0.08, MIN(1, [bars[i] doubleValue])), h = MAX(3, v * H);
        CGRect b = CGRectMake(i * (bw + gap), (H - h) / 2, bw, h);
        BOOL on = self.progress < 0 || (i + 0.5) / n <= self.progress;
        [(on ? self.played : self.rest) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:b cornerRadius:bw / 2] fill];
    }
}
@end

#pragma mark - the bar

@interface M26Rec : UIView <AVAudioPlayerDelegate>
@property (nonatomic, strong) UIVisualEffectView *glass;
@property (nonatomic, strong) UIButton *xBtn, *mainBtn, *sendBtn;
@property (nonatomic, strong) UIView *dot;
@property (nonatomic, strong) UILabel *time;
@property (nonatomic, strong) M26Wave *wave;
@property (nonatomic, strong) AVAudioRecorder *rec;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSURL *file;
@property (nonatomic, strong) NSTimer *tick;
@property (nonatomic) BOOL previewing, sending;
@property (nonatomic, weak) UIView *anchor;   // the mic we grew out of
@end
static __weak M26Rec *gRec;

static NSString *RecTime(NSTimeInterval t) { int s = (int)floor(MAX(0, t)); return [NSString stringWithFormat:@"%d:%02d", s / 60, s % 60]; }
static UIButton *RecButton(NSString *sym, CGFloat pt, UIColor *tint, UIColor *bg) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    b.tintColor = tint; b.backgroundColor = bg;
    return b;
}

@implementation M26Rec
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    self.glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    self.glass.frame = self.bounds; self.glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.glass.layer.cornerRadius = f.size.height / 2; self.glass.layer.cornerCurve = kCACornerCurveContinuous; self.glass.clipsToBounds = YES;
    self.glass.layer.borderWidth = 0.75; self.glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:dark ? 0.16 : 0.5].CGColor;
    [self addSubview:self.glass];
    self.layer.shadowColor = UIColor.blackColor.CGColor; self.layer.shadowOpacity = 0.18; self.layer.shadowRadius = 14; self.layer.shadowOffset = CGSizeMake(0, 4);

    CGFloat H = f.size.height, s = H - 10;
    self.xBtn = RecButton(@"xmark", 15, UIColor.labelColor, [UIColor colorWithWhite:dark ? 1 : 0 alpha:0.1]);
    self.xBtn.frame = CGRectMake(5, 5, s, s); self.xBtn.layer.cornerRadius = s / 2;
    [self.xBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.xBtn];

    self.dot = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.xBtn.frame) + 10, (H - 9) / 2, 9, 9)];
    self.dot.backgroundColor = UIColor.systemRedColor; self.dot.layer.cornerRadius = 4.5;
    [self addSubview:self.dot];

    self.mainBtn = RecButton(@"stop.fill", 14, UIColor.whiteColor, UIColor.systemRedColor);
    [self.mainBtn addTarget:self action:@selector(mainTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.mainBtn];

    self.sendBtn = RecButton(@"arrow.up", 16, UIColor.whiteColor, UIColor.systemBlueColor);
    [self.sendBtn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    self.sendBtn.alpha = 0; self.sendBtn.transform = CGAffineTransformMakeScale(0.3, 0.3);
    [self addSubview:self.sendBtn];

    self.time = [UILabel new];
    self.time.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
    self.time.textColor = UIColor.labelColor; self.time.text = @"0:00"; self.time.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.time];

    self.wave = [M26Wave new];
    self.wave.played = UIColor.systemRedColor; self.wave.rest = [UIColor colorWithWhite:dark ? 1 : 0 alpha:0.25];
    UITapGestureRecognizer *tp = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)];
    UIPanGestureRecognizer *pn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)];
    [self.wave addGestureRecognizer:tp]; [self.wave addGestureRecognizer:pn];
    [self addSubview:self.wave];
    [self layoutBits];
    return self;
}
- (void)layoutBits {
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height, s = H - 10;
    self.xBtn.frame = CGRectMake(5, 5, s, s);
    self.sendBtn.bounds = CGRectMake(0, 0, s, s); self.sendBtn.center = CGPointMake(W - 5 - s / 2, H / 2); self.sendBtn.layer.cornerRadius = s / 2;
    // recording: stop sits at the right end; preview: play / pause sits just after the X, send at the right end
    CGFloat mainX = self.previewing ? CGRectGetMaxX(self.xBtn.frame) + 6 + s / 2 : W - 5 - s / 2;
    self.mainBtn.bounds = CGRectMake(0, 0, s, s); self.mainBtn.center = CGPointMake(mainX, H / 2); self.mainBtn.layer.cornerRadius = s / 2;
    CGFloat tw = 44;
    if (self.previewing) {
        CGFloat x0 = CGRectGetMaxX(self.mainBtn.frame) + 10, x1 = CGRectGetMinX(self.sendBtn.frame) - 8;
        self.time.frame = CGRectMake(x1 - tw, 0, tw, H);
        self.wave.frame = CGRectMake(x0, 9, MAX(10, CGRectGetMinX(self.time.frame) - 6 - x0), H - 18);
    } else {
        CGFloat x0 = CGRectGetMaxX(self.dot.frame) + 8, x1 = CGRectGetMinX(self.mainBtn.frame) - 8;
        self.time.frame = CGRectMake(x1 - tw, 0, tw, H);
        self.wave.frame = CGRectMake(x0, 9, MAX(10, CGRectGetMinX(self.time.frame) - 6 - x0), H - 18);
    }
}
- (void)layoutSubviews { [super layoutSubviews]; self.glass.layer.cornerRadius = self.bounds.size.height / 2; [self layoutBits]; }

#pragma mark recording
- (void)startRecording {
    AVAudioSession *as = [AVAudioSession sharedInstance];
    NSError *e = nil;
    [as setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetoothA2DP error:&e];
    [as setActive:YES error:&e];
    // as clean as the mic gets: 48 kHz, 24-bit, no squashing until it's sent
    self.file = VVTempURL(@"caf");
    NSDictionary *set = @{AVFormatIDKey: @(kAudioFormatLinearPCM), AVSampleRateKey: @48000, AVNumberOfChannelsKey: @1,
                          AVLinearPCMBitDepthKey: @24, AVLinearPCMIsFloatKey: @NO, AVLinearPCMIsBigEndianKey: @NO};
    self.rec = [[AVAudioRecorder alloc] initWithURL:self.file settings:set error:&e];
    self.rec.meteringEnabled = YES;
    if (!self.rec || ![self.rec record]) { Toast(@"Couldn't use the microphone", @"mic.slash.fill"); [self closeAnimated:YES]; return; }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    __weak typeof(self) me = self;
    self.tick = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(__unused NSTimer *t) { [me step]; }];
    [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction animations:^{ me.dot.alpha = 0.25; } completion:nil];
}
- (void)step {
    if (self.rec.isRecording) {
        [self.rec updateMeters];
        float db = [self.rec averagePowerForChannel:0];   // -160..0
        CGFloat v = pow(10, MAX(-50, db) / 40.0);         // gentle curve so quiet talk still shows
        [self.wave.levels addObject:@(MIN(1, v * 1.15))];
        self.time.text = RecTime(self.rec.currentTime);
        [self.wave setNeedsDisplay];
        if (self.rec.currentTime > 600) [self mainTap];   // 10 minutes is plenty
    } else if (self.player) {
        self.wave.progress = self.player.duration > 0 ? self.player.currentTime / self.player.duration : 0;
        self.time.text = RecTime(self.player.isPlaying ? self.player.currentTime : self.player.duration);
        [self.wave setNeedsDisplay];
    }
    [self follow];
}
// stays on top of the field row (it moves with the keyboard)
- (void)follow {
    CGRect want = [self.class frameFor:self.anchor in:self.superview];
    if (!CGRectIsNull(want) && (fabs(want.origin.y - self.frame.origin.y) > 0.5 || fabs(want.size.width - self.frame.size.width) > 0.5)) self.frame = want;
}
+ (CGRect)frameFor:(UIView *)mic in:(UIView *)host {
    UIView *f = gField; UIView *pill = [f.superview viewWithTag:PILL_TAG] ?: f;
    if (!pill.window || !host) return CGRectNull;
    CGRect pr = [pill convertRect:pill.bounds toView:host];
    UIView *plus = [gEntry viewWithTag:PLUS_TAG];
    CGRect r = pr;
    if (plus.window && !plus.hidden) r = CGRectUnion(r, [plus convertRect:plus.bounds toView:host]);
    CGFloat h = MAX(46, pr.size.height);
    return CGRectMake(CGRectGetMinX(r), CGRectGetMidY(pr) - h / 2, r.size.width, h);
}
- (void)mainTap {
    if (!self.previewing) { [self stopAndPreview]; return; }
    if (self.player.isPlaying) { [self.player pause]; [self setMain:@"play.fill"]; }
    else {
        AVAudioSession *as = [AVAudioSession sharedInstance];
        [as setCategory:AVAudioSessionCategoryPlayback error:nil]; [as setActive:YES error:nil];
        [self.player play]; [self setMain:@"pause.fill"];
    }
}
- (void)setMain:(NSString *)sym {
    [self.mainBtn setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
}
- (void)stopAndPreview {
    NSTimeInterval len = self.rec.currentTime;
    [self.rec stop]; self.rec = nil;
    [self.dot.layer removeAllAnimations];
    if (len < 0.4) { [self cancel]; return; }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.file error:nil];
    self.player.delegate = self; [self.player prepareToPlay];
    self.previewing = YES; self.wave.progress = 0;
    self.wave.played = UIColor.systemBlueColor;
    [self setMain:@"play.fill"];
    self.mainBtn.backgroundColor = [UIColor colorWithWhite:self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? 1 : 0 alpha:0.12];
    self.mainBtn.tintColor = UIColor.labelColor;
    self.time.text = RecTime(self.player.duration);
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:0 animations:^{
        self.dot.alpha = 0; self.dot.transform = CGAffineTransformMakeScale(0.2, 0.2);
        self.sendBtn.alpha = 1; self.sendBtn.transform = CGAffineTransformIdentity;
        [self layoutBits];
    } completion:nil];
    [self.wave setNeedsDisplay];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)p successfully:(BOOL)ok { [self setMain:@"play.fill"]; self.wave.progress = 0; self.player.currentTime = 0; [self.wave setNeedsDisplay]; }
- (void)scrub:(UIGestureRecognizer *)g {
    if (!self.previewing || !self.player) return;
    CGFloat x = [g locationInView:self.wave].x / MAX(1, self.wave.bounds.size.width);
    self.player.currentTime = MAX(0, MIN(1, x)) * self.player.duration;
    self.wave.progress = MAX(0, MIN(1, x)); [self.wave setNeedsDisplay];
    if ([g isKindOfClass:[UITapGestureRecognizer class]] && !self.player.isPlaying) [self mainTap];
}

#pragma mark send / cancel
- (void)send {
    if (self.sending) return; self.sending = YES;
    [self.player stop];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    NSURL *raw = self.file;
    // squeezed to the voice message format, still high quality (VidVoice's Opus, 48 kHz)
    VVExtract(raw, ^(NSURL *out, NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSFileManager defaultManager] removeItemAtURL:raw error:nil];
            if (out) VVSend(out); else Toast(msg, @"exclamationmark.circle.fill");
        });
    });
    self.file = nil;
    [self closeAnimated:YES];
}
- (void)cancel {
    [self.rec stop]; [self.rec deleteRecording]; self.rec = nil;
    [self.player stop];
    if (self.file) [[NSFileManager defaultManager] removeItemAtURL:self.file error:nil];
    self.file = nil;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self closeAnimated:YES];
}
- (void)closeAnimated:(BOOL)anim {
    [self.tick invalidate]; self.tick = nil;
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    UIView *field = gField.superview;
    [UIView animateWithDuration:anim ? 0.28 : 0 animations:^{
        self.alpha = 0; self.transform = CGAffineTransformMakeScale(0.94, 0.94);
        field.alpha = 1; [gEntry viewWithTag:PLUS_TAG].alpha = 1;
    } completion:^(BOOL f) { [self removeFromSuperview]; }];
}
@end

static void RecOpen(UIView *mic) {
    if (gRec.superview) return;
    UIWindow *w = gEntry.window; if (!w) return;
    CGRect fr = [M26Rec frameFor:mic in:w];
    if (CGRectIsNull(fr)) return;
    M26Rec *r = [[M26Rec alloc] initWithFrame:fr];
    r.anchor = mic; r.tag = REC_TAG;
    [w addSubview:r];
    gRec = r;
    // grows out of the mic
    CGPoint mc = [mic convertPoint:CGPointMake(CGRectGetMidX(mic.bounds), CGRectGetMidY(mic.bounds)) toView:w];
    CGFloat sx = MAX(0.12, fr.size.height / fr.size.width);
    r.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(sx, 1), CGAffineTransformMakeTranslation(mc.x - CGRectGetMidX(fr), 0));
    r.alpha = 0;
    UIView *field = gField.superview; UIView *plus = [gEntry viewWithTag:PLUS_TAG];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.3 options:0 animations:^{
        r.transform = CGAffineTransformIdentity; r.alpha = 1;
        field.alpha = 0; plus.alpha = 0;
    } completion:nil];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL ok) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) [r startRecording];
            else { Toast(@"Messages needs the microphone (Settings → Messages)", @"mic.slash.fill"); [r closeAnimated:YES]; }
        });
    }];
}

#pragma mark - the mic opens ours instead of Apple's hold-to-record

static const void *kRecOff = &kRecOff;
@interface M26MicCover : UIControl
@end
@implementation M26MicCover
@end
static void RecMicTap(UIControl *c) { RecOpen(c.superview); }
static void RecAttach(UIView *entry) {
    UIView *ab = nil;
    @try { ab = [entry valueForKey:@"audioButton"]; } @catch (__unused id e) {}
    if (![ab isKindOfClass:[UIView class]]) return;
    M26MicCover *cov = (M26MicCover *)[ab viewWithTag:REC_TAG];
    BOOL on = Opt(@"newaudio");
    if (!on) {
        if (cov) {
            [cov removeFromSuperview];
            for (UIGestureRecognizer *g in ab.gestureRecognizers) if ([objc_getAssociatedObject(g, kRecOff) boolValue]) { g.enabled = YES; objc_setAssociatedObject(g, kRecOff, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        }
        return;
    }
    if (!cov) {
        cov = [M26MicCover new]; cov.tag = REC_TAG;
        cov.backgroundColor = UIColor.clearColor;
        cov.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cov addAction:[UIAction actionWithHandler:^(UIAction *a) { RecMicTap((UIControl *)a.sender); }] forControlEvents:UIControlEventTouchUpInside];
        [ab addSubview:cov];
    }
    if (!CGRectEqualToRect(cov.frame, CGRectInset(ab.bounds, -6, -6))) cov.frame = CGRectInset(ab.bounds, -6, -6);
    if (ab.subviews.lastObject != cov) [ab bringSubviewToFront:cov];
    if (ab.clipsToBounds) ab.clipsToBounds = NO;
    // Apple's hold-to-record stays quiet while ours is on
    for (UIGestureRecognizer *g in ab.gestureRecognizers) if (g.enabled) { g.enabled = NO; objc_setAssociatedObject(g, kRecOff, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
}

// Apple's hold-to-record does nothing while ours is on (its touches and its press gesture)
static BOOL RecOwns(id gbtn) {
    if (!Opt(@"newaudio")) return NO;
    UIView *b = nil; @try { b = [gbtn valueForKey:@"button"]; } @catch (__unused id e) {}
    return !b || [b viewWithTag:REC_TAG] != nil || [b isDescendantOfView:gEntry];
}
static void (*origGRRecognized)(id, SEL, id);
static void GRRecognized(id self, SEL _cmd, id g) { if (RecOwns(self)) return; origGRRecognized(self, _cmd, g); }
static void (*origGRDown)(id, SEL, id);
static void GRDown(id self, SEL _cmd, id b) { if (RecOwns(self)) return; origGRDown(self, _cmd, b); }
static void (*origGRUpIn)(id, SEL, id);
static void GRUpIn(id self, SEL _cmd, id b) { if (RecOwns(self)) return; origGRUpIn(self, _cmd, b); }
static void (*origGRUpOut)(id, SEL, id);
static void GRUpOut(id self, SEL _cmd, id b) { if (RecOwns(self)) return; origGRUpOut(self, _cmd, b); }
static void (*origAudioTapped)(id, SEL, id);
static void AudioTapped(UIView *self, SEL _cmd, id b) {
    if (Opt(@"newaudio")) { RecOpen([b isKindOfClass:[UIView class]] ? b : self); return; }
    origAudioTapped(self, _cmd, b);
}
static void StartAudioRec(void) {
    Class G = NSClassFromString(@"CKActionMenuGestureRecognizerButton");
    struct { const char *s; IMP n; IMP *o; } hs[] = {
        {"gestureRecognized:", (IMP)GRRecognized, (IMP *)&origGRRecognized},
        {"touchDownButton:", (IMP)GRDown, (IMP *)&origGRDown},
        {"touchUpInsideButton:", (IMP)GRUpIn, (IMP *)&origGRUpIn},
        {"touchUpOutsideButton:", (IMP)GRUpOut, (IMP *)&origGRUpOut},
    };
    for (int i = 0; i < 4; i++) { SEL s = sel_registerName(hs[i].s); if (G && class_getInstanceMethod(G, s)) MSHookMessageEx(G, s, hs[i].n, hs[i].o); }
    Class E = NSClassFromString(@"CKMessageEntryView");
    SEL t = NSSelectorFromString(@"audioButtonTapped:");
    if (E && class_getInstanceMethod(E, t)) MSHookMessageEx(E, t, (IMP)AudioTapped, (IMP *)&origAudioTapped);
}
