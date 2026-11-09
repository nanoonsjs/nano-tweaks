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
        if (wave && play && time) {
            CGFloat x0 = CGRectGetMaxX(play.frame) + 14, x1 = CGRectGetMinX(time.frame) - 14;
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
    Class I = NSClassFromString(@"CKAudioMessageChatItem");
    if (I) for (NSString *n in @[@"loadSizeThatFits:textAlignmentInsets:", @"loadSizeThatFits:textAlignmentInsets:fittingSize:", @"sizeThatFits:"]) MAHookSize(I, n);
}
