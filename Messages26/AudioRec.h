// ===================== Messages26: Voice Recorder =====================
// 1.6.1: our own recorder panel instead of Apple's Audio app (from the + menu or the mic): tap to record in high
// quality, live waveform and timer, then play / scrub it back, send, or X to throw it away and start over.
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

#pragma mark - the recorder panel (takes the place of Apple's Audio app)

@interface M26Rec : UIView <AVAudioPlayerDelegate>
@property (nonatomic, strong) UIVisualEffectView *glass;
@property (nonatomic, strong) UIView *dim, *ring;
@property (nonatomic, strong) UIButton *xBtn, *mainBtn, *sendBtn;
@property (nonatomic, strong) UILabel *time, *hint;
@property (nonatomic, strong) M26Wave *wave;
@property (nonatomic, strong) AVAudioRecorder *rec;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSURL *file;
@property (nonatomic, strong) NSTimer *tick;
@property (nonatomic) int state;   // 0 ready, 1 recording, 2 preview
@property (nonatomic) BOOL sending;
@end
static __weak M26Rec *gRec;

static NSString *RecTime(NSTimeInterval t) { int s = (int)floor(MAX(0, t)); return [NSString stringWithFormat:@"%d:%02d", s / 60, s % 60]; }
static UIButton *RecButton(NSString *sym, CGFloat pt, UIColor *tint, UIColor *bg) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:[[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    b.tintColor = tint; b.backgroundColor = bg; b.adjustsImageWhenHighlighted = NO;
    [b addAction:[UIAction actionWithHandler:^(UIAction *a) { [UIView animateWithDuration:0.12 animations:^{ ((UIView *)a.sender).transform = CGAffineTransformMakeScale(0.9, 0.9); }]; }] forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [b addAction:[UIAction actionWithHandler:^(UIAction *a) { [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.6 options:UIViewAnimationOptionAllowUserInteraction animations:^{ ((UIView *)a.sender).transform = CGAffineTransformIdentity; } completion:nil]; }] forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    return b;
}
static UIColor *RecSoft(UITraitCollection *tc) { return [UIColor colorWithWhite:tc.userInterfaceStyle == UIUserInterfaceStyleDark ? 1 : 0 alpha:0.1]; }

@implementation M26Rec
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    // tap above the panel to close it
    self.dim = [[UIView alloc] initWithFrame:self.bounds];
    self.dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0001];
    self.dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(outside)]];
    [self addSubview:self.dim];

    self.glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:dark ? UIBlurEffectStyleSystemThinMaterialDark : UIBlurEffectStyleSystemThinMaterialLight]];
    self.glass.layer.cornerRadius = 38; self.glass.layer.cornerCurve = kCACornerCurveContinuous; self.glass.clipsToBounds = YES;
    self.glass.layer.borderWidth = 0.75; self.glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:dark ? 0.14 : 0.55].CGColor;
    [self addSubview:self.glass];
    UIView *c = self.glass.contentView;

    self.time = [UILabel new];
    self.time.font = [UIFont monospacedDigitSystemFontOfSize:40 weight:UIFontWeightSemibold];
    self.time.textColor = UIColor.labelColor; self.time.textAlignment = NSTextAlignmentCenter; self.time.text = @"0:00";
    [c addSubview:self.time];

    self.hint = [UILabel new];
    self.hint.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.hint.textColor = UIColor.secondaryLabelColor; self.hint.textAlignment = NSTextAlignmentCenter;
    self.hint.text = @"Tap to record";
    [c addSubview:self.hint];

    self.wave = [M26Wave new];
    self.wave.played = UIColor.systemRedColor; self.wave.rest = [UIColor colorWithWhite:dark ? 1 : 0 alpha:0.22];
    [self.wave addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)]];
    [self.wave addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)]];
    [c addSubview:self.wave];

    // the big button sits in a soft red ring that breathes while recording
    self.ring = [UIView new];
    self.ring.backgroundColor = [UIColor.systemRedColor colorWithAlphaComponent:0.18];
    self.ring.userInteractionEnabled = NO;
    [c addSubview:self.ring];
    self.mainBtn = RecButton(@"mic.fill", 28, UIColor.whiteColor, UIColor.systemRedColor);
    [self.mainBtn addTarget:self action:@selector(mainTap) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:self.mainBtn];

    self.xBtn = RecButton(@"xmark", 18, UIColor.labelColor, RecSoft(self.traitCollection));
    [self.xBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:self.xBtn];

    self.sendBtn = RecButton(@"arrow.up", 20, UIColor.whiteColor, UIColor.systemBlueColor);
    [self.sendBtn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    self.sendBtn.alpha = 0; self.sendBtn.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [c addSubview:self.sendBtn];
    return self;
}
- (CGRect)panelRect {
    CGFloat W = self.bounds.size.width, H = 300 + self.safeAreaInsets.bottom;
    return CGRectMake(8, self.bounds.size.height - H - 4, W - 16, H);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.glass.frame = [self panelRect];
    CGFloat W = self.glass.bounds.size.width, sb = self.safeAreaInsets.bottom;
    CGFloat by = self.glass.bounds.size.height - sb - 64;           // centre line of the buttons
    self.time.frame = CGRectMake(0, 22, W, 48);
    self.hint.frame = CGRectMake(0, 70, W, 20);
    self.wave.frame = CGRectMake(28, 104, W - 56, 64);
    CGFloat m = 84;
    self.mainBtn.bounds = CGRectMake(0, 0, m, m); self.mainBtn.center = CGPointMake(W / 2, by); self.mainBtn.layer.cornerRadius = m / 2;
    self.ring.bounds = CGRectMake(0, 0, m + 26, m + 26); self.ring.center = self.mainBtn.center; self.ring.layer.cornerRadius = (m + 26) / 2;
    CGFloat s = 58;
    self.xBtn.bounds = CGRectMake(0, 0, s, s); self.xBtn.center = CGPointMake(W / 2 - 118, by); self.xBtn.layer.cornerRadius = s / 2;
    self.sendBtn.bounds = CGRectMake(0, 0, s, s); self.sendBtn.center = CGPointMake(W / 2 + 118, by); self.sendBtn.layer.cornerRadius = s / 2;
}
- (void)setMain:(NSString *)sym tint:(UIColor *)tint bg:(UIColor *)bg {
    [UIView transitionWithView:self.mainBtn duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.mainBtn setImage:[[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightBold]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.mainBtn.tintColor = tint; self.mainBtn.backgroundColor = bg;
    } completion:nil];
}

#pragma mark recording
- (void)startRecording {
    AVAudioSession *as = [AVAudioSession sharedInstance];
    NSError *e = nil;
    [as setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetoothA2DP error:&e];
    [as setActive:YES error:&e];
    // as clean as the mic gets: 48 kHz, 24-bit; squeezed only when it's sent
    self.file = VVTempURL(@"caf");
    NSDictionary *set = @{AVFormatIDKey: @(kAudioFormatLinearPCM), AVSampleRateKey: @48000, AVNumberOfChannelsKey: @1,
                          AVLinearPCMBitDepthKey: @24, AVLinearPCMIsFloatKey: @NO, AVLinearPCMIsBigEndianKey: @NO};
    self.rec = [[AVAudioRecorder alloc] initWithURL:self.file settings:set error:&e];
    self.rec.meteringEnabled = YES;
    if (!self.rec || ![self.rec record]) { Toast(@"Couldn't use the microphone", @"mic.slash.fill"); return; }
    self.state = 1;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    [self setMain:@"stop.fill" tint:UIColor.whiteColor bg:UIColor.systemRedColor];
    self.hint.text = @"Recording · tap to stop";
    __weak typeof(self) me = self;
    self.tick = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(__unused NSTimer *t) { [me step]; }];
}
- (void)step {
    if (self.rec.isRecording) {
        [self.rec updateMeters];
        float db = [self.rec averagePowerForChannel:0];
        CGFloat v = MIN(1, pow(10, MAX(-50, db) / 40.0) * 1.15);
        [self.wave.levels addObject:@(v)];
        self.time.text = RecTime(self.rec.currentTime);
        [self.wave setNeedsDisplay];
        // the ring breathes with your voice
        CGFloat k = 1 + v * 0.35;
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ self.ring.transform = CGAffineTransformMakeScale(k, k); } completion:nil];
        if (self.rec.currentTime > 600) [self mainTap];
    } else if (self.player) {
        self.wave.progress = self.player.duration > 0 ? self.player.currentTime / self.player.duration : 0;
        self.time.text = RecTime(self.player.isPlaying ? self.player.currentTime : self.player.duration);
        [self.wave setNeedsDisplay];
    }
}
- (void)mainTap {
    if (self.state == 0) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL ok) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (ok) [self startRecording];
                else Toast(@"Messages needs the microphone (Settings → Messages)", @"mic.slash.fill");
            });
        }];
        return;
    }
    if (self.state == 1) { [self stopAndPreview]; return; }
    if (self.player.isPlaying) { [self.player pause]; [self setMain:@"play.fill" tint:UIColor.labelColor bg:RecSoft(self.traitCollection)]; }
    else {
        AVAudioSession *as = [AVAudioSession sharedInstance];
        [as setCategory:AVAudioSessionCategoryPlayback error:nil]; [as setActive:YES error:nil];
        [self.player play]; [self setMain:@"pause.fill" tint:UIColor.labelColor bg:RecSoft(self.traitCollection)];
    }
}
- (void)stopAndPreview {
    NSTimeInterval len = self.rec.currentTime;
    [self.rec stop]; self.rec = nil;
    if (len < 0.4) { [self resetToReady]; return; }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.file error:nil];
    self.player.delegate = self; [self.player prepareToPlay];
    self.state = 2; self.wave.progress = 0; self.wave.played = UIColor.systemBlueColor;
    self.time.text = RecTime(self.player.duration);
    self.hint.text = @"Listen back, then send";
    [self setMain:@"play.fill" tint:UIColor.labelColor bg:RecSoft(self.traitCollection)];
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.4 options:0 animations:^{
        self.ring.transform = CGAffineTransformMakeScale(0.6, 0.6); self.ring.alpha = 0;
        self.sendBtn.alpha = 1; self.sendBtn.transform = CGAffineTransformIdentity;
    } completion:nil];
    [self.wave setNeedsDisplay];
}
- (void)resetToReady {
    [self.player stop]; self.player = nil;
    if (self.file) [[NSFileManager defaultManager] removeItemAtURL:self.file error:nil];
    self.file = nil; self.state = 0;
    [self.wave.levels removeAllObjects]; self.wave.progress = -1; self.wave.played = UIColor.systemRedColor; [self.wave setNeedsDisplay];
    self.time.text = @"0:00"; self.hint.text = @"Tap to record";
    [self setMain:@"mic.fill" tint:UIColor.whiteColor bg:UIColor.systemRedColor];
    [UIView animateWithDuration:0.3 animations:^{ self.ring.alpha = 1; self.ring.transform = CGAffineTransformIdentity; self.sendBtn.alpha = 0; self.sendBtn.transform = CGAffineTransformMakeScale(0.4, 0.4); }];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)p successfully:(BOOL)ok {
    [self setMain:@"play.fill" tint:UIColor.labelColor bg:RecSoft(self.traitCollection)];
    self.player.currentTime = 0; self.wave.progress = 0; self.time.text = RecTime(self.player.duration); [self.wave setNeedsDisplay];
}
- (void)scrub:(UIGestureRecognizer *)g {
    if (self.state != 2 || !self.player) return;
    CGFloat x = MAX(0, MIN(1, [g locationInView:self.wave].x / MAX(1, self.wave.bounds.size.width)));
    self.player.currentTime = x * self.player.duration;
    self.wave.progress = x; [self.wave setNeedsDisplay];
    if ([g isKindOfClass:[UITapGestureRecognizer class]] && !self.player.isPlaying) [self mainTap];
}

#pragma mark send / cancel
- (void)send {
    if (self.sending || self.state != 2) return; self.sending = YES;
    [self.player stop];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    NSURL *raw = self.file; self.file = nil;
    // to the voice message format, still high quality (Opus, 48 kHz)
    VVExtract(raw, ^(NSURL *out, NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSFileManager defaultManager] removeItemAtURL:raw error:nil];
            if (out) VVSend(out); else Toast(msg, @"exclamationmark.circle.fill");
        });
    });
    [self close];
}
- (void)cancel {
    if (self.state == 0) { [self close]; return; }
    [self.rec stop]; [self.rec deleteRecording]; self.rec = nil;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self resetToReady];
}
- (void)outside { if (self.state == 0) [self close]; }   // never loses a recording by accident
- (void)close {
    [self.tick invalidate]; self.tick = nil;
    [self.rec stop]; self.rec = nil; [self.player stop];
    if (self.file) [[NSFileManager defaultManager] removeItemAtURL:self.file error:nil];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    CGFloat dy = self.glass.bounds.size.height + 20;
    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.glass.transform = CGAffineTransformMakeTranslation(0, dy);
    } completion:^(BOOL f) { [self removeFromSuperview]; }];
}
@end

static void RecOpen(__unused UIView *from) {
    if (gRec.superview) return;
    UIWindow *w = gEntry.window ?: [UIApplication sharedApplication].keyWindow; if (!w) return;
    CloseOpenApp();
    // 1.6.2: the keyboard lives in its own window above ours, so it's put away for real (not just this window)
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    for (UIWindow *x in [UIApplication sharedApplication].windows) [x endEditing:YES];
    @try {
        UIViewController *chat = VVChat();
        SEL d = NSSelectorFromString(@"dismissKeyboard");
        if ([chat respondsToSelector:d]) ((void (*)(id, SEL))objc_msgSend)(chat, d);
        id ic = [chat valueForKey:@"inputController"];
        SEL d2 = NSSelectorFromString(@"dismissKeyboard");
        if ([ic respondsToSelector:d2]) ((void (*)(id, SEL))objc_msgSend)(ic, d2);
    } @catch (__unused id e) {}
    M26Rec *r = [[M26Rec alloc] initWithFrame:w.bounds];
    r.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [w addSubview:r];
    gRec = r;
    [r layoutIfNeeded];
    // slides up like a sheet, with a little bounce
    r.glass.transform = CGAffineTransformMakeTranslation(0, r.glass.bounds.size.height + 20);
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.3 options:0 animations:^{ r.glass.transform = CGAffineTransformIdentity; } completion:nil];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
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
