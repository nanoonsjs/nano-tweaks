// ===================== Messages26: audio messages =====================
// Bigger audio bubbles (iOS 26: wide, a big play button, a long waveform, the time on the right, no
// speaker icon or "Raise to listen"), and audio messages play out loud on the bottom speaker instead
// of the earpiece (unless the phone is at your ear).
// Included from Tweak.x before %ctor.
#import <AVFoundation/AVFoundation.h>

#pragma mark - play on the speaker

static void MAForceSpeaker(void) {
    if (!gSpeakerOn || UIDevice.currentDevice.proximityState) return;
    AVAudioSession *s = [AVAudioSession sharedInstance];
    if (![s.category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) return;
    for (AVAudioSessionPortDescription *o in s.currentRoute.outputs)
        if ([o.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) { [s overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil]; break; }
}
static BOOL (*origSetCatOpt)(id, SEL, NSString *, AVAudioSessionCategoryOptions, NSError **);
static BOOL SetCatOpt(id self, SEL _cmd, NSString *cat, AVAudioSessionCategoryOptions o, NSError **e) {
    if (gSpeakerOn && [cat isEqualToString:AVAudioSessionCategoryPlayAndRecord] && !UIDevice.currentDevice.proximityState) o |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    return origSetCatOpt(self, _cmd, cat, o, e);
}
static BOOL (*origSetCatModeOpt)(id, SEL, NSString *, NSString *, AVAudioSessionCategoryOptions, NSError **);
static BOOL SetCatModeOpt(id self, SEL _cmd, NSString *cat, NSString *mode, AVAudioSessionCategoryOptions o, NSError **e) {
    if (gSpeakerOn && [cat isEqualToString:AVAudioSessionCategoryPlayAndRecord] && !UIDevice.currentDevice.proximityState) o |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    return origSetCatModeOpt(self, _cmd, cat, mode, o, e);
}
static void StartSpeaker(void) {
    Class S = [AVAudioSession class];
    SEL a = @selector(setCategory:withOptions:error:), b = @selector(setCategory:mode:options:error:);
    if (class_getInstanceMethod(S, a)) MSHookMessageEx(S, a, (IMP)SetCatOpt, (IMP *)&origSetCatOpt);
    if (class_getInstanceMethod(S, b)) MSHookMessageEx(S, b, (IMP)SetCatModeOpt, (IMP *)&origSetCatModeOpt);
    for (NSString *n in @[AVAudioSessionRouteChangeNotification, UIDeviceProximityStateDidChangeNotification])
        [[NSNotificationCenter defaultCenter] addObserverForName:n object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *x) {
            @try { MAForceSpeaker(); } @catch (__unused id e) {}
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { MAForceSpeaker(); } @catch (__unused id e) {} });
        }];
}

#pragma mark - bigger bubble

static CGSize MAGrow(CGSize r, CGSize fits) {
    if (!gAudioBig || r.height <= 0 || r.height > 90) return r;   // not a plain audio bubble (e.g. with a transcript)
    CGFloat avail = fits.width > 50 && fits.width < 2000 ? fits.width : UIScreen.mainScreen.bounds.size.width;
    CGFloat w = MIN(avail * 0.82, 296);
    return CGSizeMake(MAX(r.width, w), MAX(r.height, 60));
}
static void MAHookSize(Class C, NSString *name) {
    SEL s = NSSelectorFromString(name);
    Method m = class_getInstanceMethod(C, s);
    if (!m) return;
    const char *types = method_getTypeEncoding(m);
    if (!types || strncmp(types, "{CGSize", 7) != 0) return;
    IMP orig = method_getImplementation(m);
    unsigned int n = method_getNumberOfArguments(m);   // self, _cmd, then the arguments
    IMP rep = NULL;
    if (n == 3) rep = imp_implementationWithBlock(^CGSize(id me, CGSize a) { return MAGrow(((CGSize (*)(id, SEL, CGSize))orig)(me, s, a), a); });
    else if (n == 4) rep = imp_implementationWithBlock(^CGSize(id me, CGSize a, void *b) { return MAGrow(((CGSize (*)(id, SEL, CGSize, void *))orig)(me, s, a, b), a); });
    else if (n == 5) rep = imp_implementationWithBlock(^CGSize(id me, CGSize a, void *b, void *c) { return MAGrow(((CGSize (*)(id, SEL, CGSize, void *, void *))orig)(me, s, a, b, c), a); });
    if (!rep) return;
    // only this class (and its subclasses) changes: add an override if the method is inherited
    if (!class_addMethod(C, s, rep, types)) method_setImplementation(class_getInstanceMethod(C, s), rep);
}

#pragma mark - voice message speed (1.8.3)

static float MASpeed(void) {
    if (!Opt(@"vspeed")) return 1;
    float s = [[NSUserDefaults standardUserDefaults] floatForKey:@"m26.vspeed"];
    return s >= 0.5 && s <= 3 ? s : 1;
}
static NSHashTable *gMAPlayers;
// the AVAudioPlayer / AVPlayer inside Messages' audio player
static void MAEachInner(id ip, void (^b)(id inner)) {
    for (Class c = [ip class]; c && c != [NSObject class]; c = class_getSuperclass(c)) {
        unsigned n = 0; Ivar *iv = class_copyIvarList(c, &n);
        for (unsigned i = 0; i < n; i++) {
            const char *t = ivar_getTypeEncoding(iv[i]);
            if (!t || t[0] != '@') continue;
            id v = nil; @try { v = object_getIvar(ip, iv[i]); } @catch (__unused id e) {}
            if ([v isKindOfClass:[AVAudioPlayer class]] || [v isKindOfClass:[AVPlayer class]]) b(v);
        }
        free(iv);
    }
}
static void MAApplyRate(id ip, BOOL prepare) {
    float s = MASpeed();
    MAEachInner(ip, ^(id inner) {
        if ([inner isKindOfClass:[AVAudioPlayer class]]) {
            AVAudioPlayer *p = inner;
            if (prepare || !p.enableRate) p.enableRate = YES;   // has to be on before it starts
            p.rate = s;
        } else {
            AVPlayer *p = inner;
            if (p.currentItem) p.currentItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;   // voices keep their pitch
            if (p.rate > 0) p.rate = s;
        }
    });
}
static void (*origIPPrepare)(id, SEL);
static void IPPrepare(id self, SEL _cmd) {
    if (!gMAPlayers) gMAPlayers = [NSHashTable weakObjectsHashTable];
    [gMAPlayers addObject:self];
    @try { MAApplyRate(self, YES); } @catch (__unused id e) {}
    origIPPrepare(self, _cmd);
}
static BOOL (*origIPPlayAt)(id, SEL, double);
static BOOL IPPlayAt(id self, SEL _cmd, double t) {
    if (!gMAPlayers) gMAPlayers = [NSHashTable weakObjectsHashTable];
    [gMAPlayers addObject:self];
    @try { MAEachInner(self, ^(id inner) { if ([inner isKindOfClass:[AVAudioPlayer class]] && !((AVAudioPlayer *)inner).enableRate) ((AVAudioPlayer *)inner).enableRate = YES; }); } @catch (__unused id e) {}
    BOOL r = origIPPlayAt(self, _cmd, t);
    @try { MAApplyRate(self, NO); } @catch (__unused id e) {}
    return r;
}
static NSString *MASpeedText(float s) { return s >= 1.99 ? @"2×" : s >= 1.49 ? @"1.5×" : @"1×"; }
@interface M26SpeedChip : UIButton
@end
@implementation M26SpeedChip
- (void)tap {
    float s = MASpeed();
    float n = s < 1.49 ? 1.5 : s < 1.99 ? 2 : 1;
    [[NSUserDefaults standardUserDefaults] setFloat:n forKey:@"m26.vspeed"];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    for (id p in [gMAPlayers allObjects]) @try { MAApplyRate(p, NO); } @catch (__unused id e) {}
    // every voice message on screen shows the new speed
    Class A = NSClassFromString(@"CKAudioBalloonView");
    NSMutableArray *st = [NSMutableArray arrayWithObject:self.window ?: (id)NSNull.null]; int g = 0;
    while (st.count && g++ < 4000) { UIView *v = st.lastObject; [st removeLastObject]; if (![v isKindOfClass:[UIView class]]) continue;
        if ([v isKindOfClass:[M26SpeedChip class]]) [(UIButton *)v setTitle:MASpeedText(n) forState:UIControlStateNormal];
        if (A && [v isKindOfClass:A]) continue;
        [st addObjectsFromArray:v.subviews]; }
    [UIView animateWithDuration:0.12 animations:^{ self.transform = CGAffineTransformMakeScale(1.15, 1.15); } completion:^(BOOL f) { [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:0 animations:^{ self.transform = CGAffineTransformIdentity; } completion:nil]; }];
}
@end
#define SPEED_TAG 0x4D325350

static void (*origAudioLayout)(UIView *, SEL);
static void AudioLayout(UIView *self, SEL _cmd) {
    origAudioLayout(self, _cmd);
    if (!gAudioBig) return;
    @try {
        CGRect B = self.bounds; CGFloat W = B.size.width, H = B.size.height;
        if (W < 120 || H > 90) return;
        BOOL right = NO;   // which side the tail is on
        @try { right = [[self valueForKey:@"orientation"] integerValue] == 1; } @catch (__unused id e) {}
        CGFloat L = right ? 6 : 12, R = right ? 12 : 6;
        UIView *play = nil, *wave = nil; UILabel *time = nil;
        for (UIView *v in self.subviews) {
            if (v.hidden || v.alpha < 0.01 || v.tag == GLASS_TAG) continue;
            NSString *n = NSStringFromClass(v.class);
            if ([v isKindOfClass:[UILabel class]]) { time = (UILabel *)v; continue; }
            if (!play && ([v isKindOfClass:[UIButton class]] || [n containsString:@"Play"])) { play = v; continue; }
            if (v.bounds.size.width > wave.bounds.size.width && v.bounds.size.height < H && v.bounds.size.width < W) wave = v;
        }
        CGFloat cy = H / 2;
        if (play) { CGFloat d = 38; play.transform = CGAffineTransformMakeScale(d / MAX(1, play.bounds.size.width), d / MAX(1, play.bounds.size.height)); play.center = CGPointMake(L + 8 + d / 2, cy); }
        if (time) { [time sizeToFit]; time.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium]; [time sizeToFit]; time.center = CGPointMake(W - R - 10 - time.bounds.size.width / 2, cy); }
        // 1.8.3: a little speed chip (1× / 1.5× / 2×) before the time
        M26SpeedChip *chip = (M26SpeedChip *)[self viewWithTag:SPEED_TAG];
        if (Opt(@"vspeed") && time) {
            if (!chip) {
                chip = [M26SpeedChip buttonWithType:UIButtonTypeCustom]; chip.tag = SPEED_TAG;
                chip.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
                [chip addTarget:chip action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:chip];
            }
            [chip setTitle:MASpeedText(MASpeed()) forState:UIControlStateNormal];
            UIColor *tc = time.textColor ?: UIColor.labelColor;
            [chip setTitleColor:tc forState:UIControlStateNormal];
            chip.backgroundColor = [tc colorWithAlphaComponent:0.18];
            chip.bounds = CGRectMake(0, 0, 38, 22); chip.layer.cornerRadius = 11;
            chip.center = CGPointMake(CGRectGetMinX(time.frame) - 8 - 19, cy);
        } else [chip removeFromSuperview];
        if (wave && play && time) {
            CGFloat x0 = CGRectGetMaxX(play.frame) + 14, x1 = (chip.superview ? CGRectGetMinX(chip.frame) : CGRectGetMinX(time.frame)) - 14;
            if (x1 - x0 > 40) { wave.frame = CGRectMake(x0, cy - wave.bounds.size.height / 2, x1 - x0, wave.bounds.size.height); [wave setNeedsLayout]; [wave setNeedsDisplay]; }
        }
        // the speaker icon beside the bubble and "Raise to listen" under it go away
        for (UIView *host in @[self.superview ?: (id)NSNull.null, self.superview.superview ?: (id)NSNull.null]) {
            if (![host isKindOfClass:[UIView class]]) continue;
            NSMutableArray *st = [NSMutableArray arrayWithArray:((UIView *)host).subviews]; int g = 0;
            while (st.count && g++ < 200) {
                UIView *v = st.lastObject; [st removeLastObject];
                if (v == self || [v isDescendantOfView:self]) continue;
                if ([v isKindOfClass:[UILabel class]] && [((UILabel *)v).text rangeOfString:@"Raise" options:NSCaseInsensitiveSearch].location != NSNotFound) { v.hidden = YES; continue; }
                if ([v isKindOfClass:[UIButton class]]) {
                    NSString *d = [(UIButton *)v currentImage].description.lowercaseString;
                    if ([d containsString:@"speaker"]) { v.hidden = YES; continue; }
                }
                [st addObjectsFromArray:v.subviews];
            }
        }
    } @catch (__unused id e) {}
}
static void StartAudioBubbles(void) {
    Class A = NSClassFromString(@"CKAudioBalloonView");
    if (A) {
        for (NSString *n in @[@"sizeThatFits:", @"sizeThatFits:textAlignmentInsets:", @"sizeThatFits:textAlignmentInsets:tailInsets:"]) MAHookSize(A, n);
        MSHookMessageEx(A, @selector(layoutSubviews), (IMP)AudioLayout, (IMP *)&origAudioLayout);
    }
    Class IP = NSClassFromString(@"CKInternalAudioPlayer");
    if (IP && class_getInstanceMethod(IP, @selector(prepareToPlay))) MSHookMessageEx(IP, @selector(prepareToPlay), (IMP)IPPrepare, (IMP *)&origIPPrepare);
    if (IP && class_getInstanceMethod(IP, @selector(playAtTime:))) MSHookMessageEx(IP, @selector(playAtTime:), (IMP)IPPlayAt, (IMP *)&origIPPlayAt);
    Class AIC = NSClassFromString(@"CKAudioMessageChatItem");
    if (AIC) for (NSString *n in @[@"loadSizeThatFits:textAlignmentInsets:", @"loadSizeThatFits:textAlignmentInsets:fittingSize:", @"sizeThatFits:"]) MAHookSize(AIC, n);
}
