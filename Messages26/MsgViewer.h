// ===================== Messages26: iOS 26 photo / video viewer =====================
// Tap a photo or video in a chat: Messages opens Quick Look (QLPreviewController). We keep
// Apple's viewer and its buttons (they still do the work, just invisible), and draw the iOS 26
// look on top:
//   top:     glass X (Done), "Photo" / "Video" title
//   video:   big play with -10 / +10 circles in the middle, a glass time bar, a ... menu (speed, loop)
//   bottom:  glass capsule [tapback | reply] on the left, [save | share] on the right
// Included from Tweak.x before %ctor.
#import <AVFoundation/AVFoundation.h>


static Class MVQLClass(void) { static Class c; if (!c) c = NSClassFromString(@"QLPreviewController"); return c; }
static UIViewController *MVQLOf(UIView *v) {
    Class q = MVQLClass(); if (!q) return nil;
    int guard = 0;
    for (UIResponder *r = v; r && guard++ < 120; r = r.nextResponder) {
        if (![r isKindOfClass:[UIViewController class]]) continue;
        UIViewController *vc = (UIViewController *)r;
        if ([vc isKindOfClass:q]) return vc;
        for (UIViewController *ch in vc.childViewControllers) if ([ch isKindOfClass:q]) return ch;
    }
    return nil;
}

static const void *kMVMask = &kMVMask;
static void MVMask(UIView *v) {
    if (!v || objc_getAssociatedObject(v, kMVMask)) return;
    v.layer.mask = [CALayer layer];   // draws nothing, still takes touches
    objc_setAssociatedObject(v, kMVMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// what a bar button is: from its symbol, label and system type
static NSString *MVKind(UIBarButtonItem *it) {
    NSMutableString *s = [NSMutableString string];
    if (it.accessibilityLabel) [s appendString:it.accessibilityLabel];
    if (it.title) [s appendString:it.title];
    if (it.image) [s appendString:it.image.description];
    @try {
        NSNumber *sys = [it valueForKey:@"systemItem"];
        if ([sys isKindOfClass:[NSNumber class]]) switch (sys.integerValue) {
            case UIBarButtonSystemItemAction: [s appendString:@" share"]; break;
            case UIBarButtonSystemItemPlay: [s appendString:@" play"]; break;
            case UIBarButtonSystemItemPause: [s appendString:@" pause"]; break;
            case UIBarButtonSystemItemDone: [s appendString:@" done"]; break;
            case UIBarButtonSystemItemReply: [s appendString:@" reply"]; break;
            case UIBarButtonSystemItemFlexibleSpace: case UIBarButtonSystemItemFixedSpace: return @"space";
            default: break;
        }
    } @catch (__unused id e) {}
    UIView *v = nil; @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {}
    if ([v isKindOfClass:[UIView class]]) {
        NSMutableArray *st = [NSMutableArray arrayWithObject:v]; int g = 0;
        while (st.count && g++ < 40) {
            UIView *x = st.lastObject; [st removeLastObject];
            if ([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image) [s appendString:((UIImageView *)x).image.description];
            if ([x isKindOfClass:[UIButton class]] && [(UIButton *)x currentImage]) [s appendString:[(UIButton *)x currentImage].description];
            if ([x isKindOfClass:[UILabel class]] && ((UILabel *)x).text) [s appendString:((UILabel *)x).text];
            if (x.accessibilityLabel) [s appendString:x.accessibilityLabel];
            [st addObjectsFromArray:x.subviews];
        }
    }
    NSString *l = s.lowercaseString;
    if (!l.length) return @"?";
    if ([l containsString:@"square.and.arrow.up"] || [l containsString:@"share"]) return @"share";
    if ([l containsString:@"pause"] || [l containsString:@"play"]) return @"play";
    if ([l containsString:@"arrowshape"] || [l containsString:@"reply"]) return @"reply";
    if ([l containsString:@"done"] || [l containsString:@"close"]) return @"done";
    return @"tapback";
}
static void MVForward(UIBarButtonItem *it) {
    if (!it) return;
    if (it.action) { [[UIApplication sharedApplication] sendAction:it.action to:it.target from:it forEvent:nil]; return; }
    UIView *v = it.customView; if (!v) { @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {} }
    NSMutableArray *st = [NSMutableArray arrayWithObject:v ?: [UIView new]];
    while (st.count) {
        UIView *x = st.firstObject; [st removeObjectAtIndex:0];
        if ([x isKindOfClass:[UIControl class]]) { [(UIControl *)x sendActionsForControlEvents:UIControlEventTouchUpInside]; [(UIControl *)x sendActionsForControlEvents:UIControlEventPrimaryActionTriggered]; return; }
        [st addObjectsFromArray:x.subviews];
    }
    if (@available(iOS 14.0, *)) {
        id pa = it.primaryAction; SEL ps = NSSelectorFromString(@"performWithSender:target:");
        if (pa && [pa respondsToSelector:ps]) ((void (*)(id, SEL, id, id))objc_msgSend)(pa, ps, it, nil);
    }
}

static double MVDur(AVPlayer *p) {
    CMTime d = p.currentItem.duration;
    if (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) return CMTimeGetSeconds(d);
    d = p.currentItem.asset.duration;
    return (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) ? CMTimeGetSeconds(d) : 0;
}
static AVPlayer *MVPlayerIn(UIView *root) {
    if (!root) return nil;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root.layer]; int guard = 0;
    AVPlayer *best = nil;
    while (st.count && guard++ < 6000) {
        CALayer *l = st.lastObject; [st removeLastObject];
        if ([l isKindOfClass:[AVPlayerLayer class]] && ((AVPlayerLayer *)l).player) {
            AVPlayer *p = ((AVPlayerLayer *)l).player;
            if (!best || (p.rate > 0 && best.rate == 0)) best = p;
        }
        if (l.sublayers.count) [st addObjectsFromArray:l.sublayers];
    }
    return best;
}
static NSString *MVClock(double s) { int t = (int)MAX(0, floor(s)); return [NSString stringWithFormat:@"%d:%02d", t / 60, t % 60]; }

static UIVisualEffectView *MVGlass(CGFloat radius) {
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerRadius = radius; g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.8; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    g.contentView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.35];
    return g;
}

@interface MVOverlay : UIView
@property (nonatomic, weak) UIViewController *ql;
@property (nonatomic, weak) UINavigationBar *nb;
@property (nonatomic, weak) UIToolbar *tb;
- (void)refresh;
@end

@implementation MVOverlay {
    UIVisualEffectView *_closeG, *_leftG, *_rightG, *_scrubG, *_moreG, *_playG, *_backG, *_fwdG;
    UIButton *_close, *_tap, *_reply, *_save, *_share, *_more, *_play, *_back, *_fwd;
    UILabel *_title, *_el, *_rem;
    UIImageView *_chev;
    UIView *_track, *_fill, *_scrubHit;
    __weak AVPlayer *_player;
    UIBarButtonItem *_iShare, *_iPlay, *_iReply, *_iTap, *_iDone;
    __weak UIImageView *_photo;
    CADisplayLink *_link;
    BOOL _video, _scrubbing, _loop;
    double _scrubStart; CGFloat _scrubX0;
    float _speed;
    CFTimeInterval _lastScan;
}
static UIButton *MVButton(NSString *sym, CGFloat pt, id target, SEL a) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    b.tintColor = UIColor.whiteColor; b.adjustsImageWhenHighlighted = NO;
    [b addTarget:target action:a forControlEvents:UIControlEventTouchUpInside];
    [b addTarget:target action:@selector(press:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [b addTarget:target action:@selector(unpress:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    return b;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _speed = 1;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _closeG = MVGlass(20); _leftG = MVGlass(20); _rightG = MVGlass(20); _scrubG = MVGlass(20);
    _moreG = MVGlass(20); _playG = MVGlass(20); _backG = MVGlass(20); _fwdG = MVGlass(20);
    for (UIView *g in @[_closeG, _leftG, _rightG, _scrubG, _moreG, _playG, _backG, _fwdG]) [self addSubview:g];
    _close = MVButton(@"xmark", 19, self, @selector(doClose)); [self addSubview:_close];
    _title = [UILabel new]; _title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]; _title.textColor = UIColor.whiteColor; _title.textAlignment = NSTextAlignmentCenter; [self addSubview:_title];
    _chev = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]]];
    _chev.tintColor = [UIColor colorWithWhite:1 alpha:0.35]; [self addSubview:_chev];
    _title.userInteractionEnabled = NO; _chev.userInteractionEnabled = NO;   // Apple's own title (under us) still opens its menu
    _tap = MVButton(@"plus.bubble", 20, self, @selector(doTap)); [self addSubview:_tap];
    _reply = MVButton(@"arrowshape.turn.up.left", 19, self, @selector(doReply)); [self addSubview:_reply];
    _save = MVButton(@"square.and.arrow.down", 19, self, @selector(doSave)); [self addSubview:_save];
    _share = MVButton(@"square.and.arrow.up", 19, self, @selector(doShare)); [self addSubview:_share];
    _play = MVButton(@"play.fill", 36, self, @selector(doPlay)); [self addSubview:_play];
    _back = MVButton(@"gobackward.10", 26, self, @selector(doBack)); [self addSubview:_back];
    _fwd = MVButton(@"goforward.10", 26, self, @selector(doFwd)); [self addSubview:_fwd];
    _more = [UIButton buttonWithType:UIButtonTypeCustom];
    [_more setImage:[UIImage systemImageNamed:@"ellipsis" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    _more.tintColor = UIColor.whiteColor; _more.showsMenuAsPrimaryAction = YES; [self addSubview:_more];
    [self buildMenu];
    _el = [UILabel new]; _rem = [UILabel new];
    for (UILabel *l in @[_el, _rem]) { l.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium]; l.textColor = [UIColor colorWithWhite:1 alpha:0.6]; [self addSubview:l]; }
    _rem.textAlignment = NSTextAlignmentRight;
    _track = [UIView new]; _track.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25]; _track.userInteractionEnabled = NO; [self addSubview:_track];
    _fill = [UIView new]; _fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9]; [_track addSubview:_fill];
    _track.clipsToBounds = YES;
    _scrubHit = [UIView new]; [self addSubview:_scrubHit];
    [_scrubHit addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)]];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(scrub:)]; lp.minimumPressDuration = 0;
    [_scrubHit addGestureRecognizer:lp];
    return self;
}
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    if (self.alpha < 0.05) return nil;
    UIView *h = [super hitTest:p withEvent:e];
    if (h == self || [h isKindOfClass:[UIVisualEffectView class]] || h == _title || h == _chev) return nil;   // empty spots go to Apple's viewer
    return (h.hidden || h.alpha < 0.05) ? nil : h;
}
- (void)press:(UIButton *)b { [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformMakeScale(0.86, 0.86); } completion:nil]; }
- (void)unpress:(UIButton *)b { [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil]; }
- (void)buildMenu {
    __weak MVOverlay *ws = self;
    NSMutableArray *speeds = [NSMutableArray array];
    for (NSNumber *n in @[@0.5, @1, @1.25, @1.5, @2]) {
        float r = n.floatValue;
        UIAction *a = [UIAction actionWithTitle:[NSString stringWithFormat:@"%@×", n] image:nil identifier:nil handler:^(__unused UIAction *x) {
            MVOverlay *s = ws; if (!s) return;
            s->_speed = r;
            AVPlayer *p = s->_player;
            if (@available(iOS 16.0, *)) p.defaultRate = r;
            if (p.rate > 0) p.rate = r;
            [s buildMenu];
        }];
        a.state = fabsf(_speed - r) < 0.01 ? UIMenuElementStateOn : UIMenuElementStateOff;
        [speeds addObject:a];
    }
    UIMenu *sp = [UIMenu menuWithTitle:@"Playback Speed" image:[UIImage systemImageNamed:@"gauge.with.dots.needle.67percent"] identifier:nil options:0 children:speeds];
    UIAction *loop = [UIAction actionWithTitle:@"Loop" image:[UIImage systemImageNamed:@"repeat"] identifier:nil handler:^(__unused UIAction *x) { MVOverlay *s = ws; if (!s) return; s->_loop = !s->_loop; [s buildMenu]; }];
    loop.state = _loop ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *share = [UIAction actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__unused UIAction *x) { [ws doShare]; }];
    _more.menu = [UIMenu menuWithTitle:@"" children:@[sp, loop, share]];
}
- (void)haptic { [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred]; }
- (void)doClose {
    [self haptic];
    if (_iDone) { MVForward(_iDone); return; }
    UIViewController *q = self.ql;
    UIViewController *pres = q.navigationController ?: q;
    [pres dismissViewControllerAnimated:YES completion:nil];
}
- (void)doTap { [self haptic]; MVForward(_iTap); }
- (void)doReply { [self haptic]; MVForward(_iReply); }
- (void)doShare { [self haptic]; MVForward(_iShare); }
- (void)doSave {
    UIImage *img = _photo.image;
    if (!img) return;
    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    [_save setImage:[UIImage systemImageNamed:@"checkmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_save setImage:[UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    });
}
- (void)doPlay {
    [self haptic];
    AVPlayer *p = _player;
    if (p) {
        if (p.rate > 0) [p pause];
        else {
            if (MVDur(p) > 0 && CMTimeGetSeconds(p.currentTime) >= MVDur(p) - 0.15) [p seekToTime:kCMTimeZero];
            [p play]; if (_speed != 1) p.rate = _speed;
        }
    } else MVForward(_iPlay);
    [self refresh];
}
- (void)skip:(double)d {
    [self haptic];
    AVPlayer *p = _player; if (!p) return;
    double t = MAX(0, MIN(MVDur(p), CMTimeGetSeconds(p.currentTime) + d));
    [p seekToTime:CMTimeMakeWithSeconds(t, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    UIButton *b = d < 0 ? _back : _fwd;
    CABasicAnimation *r = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    r.fromValue = @0; r.toValue = @(d < 0 ? -M_PI * 2 : M_PI * 2); r.duration = 0.45;
    r.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [b.imageView.layer addAnimation:r forKey:@"spin"];
}
- (void)doBack { [self skip:-10]; }
- (void)doFwd { [self skip:10]; }
- (void)scrub:(UIGestureRecognizer *)g {
    AVPlayer *p = _player; double D = MVDur(p);
    if (!p || D <= 0) return;
    CGFloat x = [g locationInView:self].x;
    if (g.state == UIGestureRecognizerStateBegan) {
        _scrubbing = YES; _scrubX0 = x; _scrubStart = CMTimeGetSeconds(p.currentTime) / D;
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self->_track.transform = CGAffineTransformMakeScale(1.03, 1.8); } completion:nil];
    }
    if (!_scrubbing) return;
    double v = MAX(0, MIN(1, _scrubStart + (x - _scrubX0) / MAX(1, _track.bounds.size.width)));
    if (g.state == UIGestureRecognizerStateChanged || g.state == UIGestureRecognizerStateBegan) {
        [p seekToTime:CMTimeMakeWithSeconds(v * D, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self showProgress:v dur:D];
    } else {
        _scrubbing = NO;
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self->_track.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)showProgress:(double)v dur:(double)D {
    _fill.frame = CGRectMake(0, 0, _track.bounds.size.width * v, _track.bounds.size.height);
    _el.text = MVClock(v * D); _rem.text = [@"-" stringByAppendingString:MVClock(D - v * D)];
}
// Apple's pieces: find the buttons, hide Apple's look (they keep working), hide its film strip and middle play button
- (void)scan {
    UINavigationBar *nb = self.nb; UIToolbar *tb = self.tb;
    _iShare = _iPlay = _iReply = _iTap = _iDone = nil;
    for (UIBarButtonItem *it in tb.items) {
        NSString *k = MVKind(it);
        if ([k isEqualToString:@"share"]) _iShare = it;
        else if ([k isEqualToString:@"play"]) _iPlay = it;
        else if ([k isEqualToString:@"reply"]) _iReply = it;
        else if ([k isEqualToString:@"tapback"] && !_iTap) _iTap = it;
    }
    UINavigationItem *top = nb.topItem;
    for (UIBarButtonItem *it in [(top.rightBarButtonItems ?: @[]) arrayByAddingObjectsFromArray:top.leftBarButtonItems ?: @[]]) {
        NSString *k = MVKind(it);
        if ([k isEqualToString:@"done"] || [it.title isEqualToString:@"Done"]) _iDone = it;
        else if ([k isEqualToString:@"share"] && !_iShare) _iShare = it;
    }
    if (!_iDone) _iDone = top.rightBarButtonItem;
    for (UIView *s in nb.subviews) if (![NSStringFromClass(s.class) containsString:@"Background"]) MVMask(s);
    // the toolbar's own buttons stay pressable only through ours (no invisible buttons under empty spots)
    for (UIView *s in tb.subviews) if (![NSStringFromClass(s.class) containsString:@"Background"]) { MVMask(s); if (s.userInteractionEnabled) s.userInteractionEnabled = NO; }
    UIView *root = self.superview;
    CGFloat W = root.bounds.size.width;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root ?: [UIView new]]; int guard = 0;
    UIImageView *photo = nil; CGFloat best = 0;
    while (st.count && guard++ < 3000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v == self || v == nb || v == tb) continue;
        NSString *n = NSStringFromClass(v.class);
        CGRect r = [v convertRect:v.bounds toView:root];
        if (([n containsString:@"Scrubber"] || [n containsString:@"Filmstrip"] || [n containsString:@"TimeSlider"]) && r.size.width > W * 0.5) { MVMask(v); v.userInteractionEnabled = NO; continue; }
        BOOL playish = [n containsString:@"PlayButton"] || [n containsString:@"PlayPause"];
        if (!playish && ([v isKindOfClass:[UIButton class]] || [v isKindOfClass:[UIImageView class]])) {
            UIImage *im = [v isKindOfClass:[UIButton class]] ? [(UIButton *)v currentImage] : ((UIImageView *)v).image;
            NSString *d = im.description.lowercaseString;
            if ([d containsString:@"play"] && r.size.width >= 40 && r.size.width <= 160 && fabs(CGRectGetMidX(r) - W / 2) < 40) playish = YES;
        }
        if (playish && r.size.width >= 30 && r.size.width <= 180) { MVMask(v); v.userInteractionEnabled = NO; continue; }
        if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image && r.size.width * r.size.height > best && r.size.width > W * 0.5) { best = r.size.width * r.size.height; photo = (UIImageView *)v; }
        [st addObjectsFromArray:v.subviews];
    }
    _photo = photo;
    _player = MVPlayerIn(root);
    _video = _iPlay != nil || _player != nil;
}
- (void)place:(UIView *)v glass:(UIVisualEffectView *)g frame:(CGRect)r {
    if (!CGRectEqualToRect(g.frame, r)) { g.frame = r; g.layer.cornerRadius = MIN(r.size.width, r.size.height) / 2; }
    if (v && v.transform.a == 1 && !CGRectEqualToRect(v.frame, r)) v.frame = r;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *root = self.superview; if (!root) return;
    CGRect B = self.bounds; CGFloat W = B.size.width, H = B.size.height;
    UIEdgeInsets sa = self.window.safeAreaInsets;
    UINavigationBar *nb = self.nb;
    CGFloat topY = nb.window ? CGRectGetMidY([nb convertRect:nb.bounds toView:self]) : sa.top + 22;
    CGFloat D = 50;
    [self place:_close glass:_closeG frame:CGRectMake(16, topY - D / 2, D, D)];
    CGSize ts = [_title sizeThatFits:CGSizeMake(W - 160, 30)];
    _title.frame = CGRectMake(W / 2 - (ts.width + 26) / 2, topY - 12, ts.width, 24);
    _chev.frame = CGRectMake(CGRectGetMaxX(_title.frame) + 6, topY - 10, 20, 20);
    // bottom row
    CGFloat by = H - MAX(14, sa.bottom + 4) - 26;
    CGFloat BH = 54;
    [self place:nil glass:_leftG frame:CGRectMake(22, by - BH / 2, 124, BH)];
    _tap.frame = CGRectMake(28, by - BH / 2, 56, BH);
    _reply.frame = CGRectMake(84, by - BH / 2, 56, BH);
    BOOL canSave = !_video && _photo.image;
    _save.hidden = !canSave;
    if (canSave) {
        [self place:nil glass:_rightG frame:CGRectMake(W - 22 - 124, by - BH / 2, 124, BH)];
        _save.frame = CGRectMake(W - 22 - 118, by - BH / 2, 56, BH);
        _share.frame = CGRectMake(W - 22 - 62, by - BH / 2, 56, BH);
    } else {
        [self place:nil glass:_rightG frame:CGRectMake(W - 22 - BH, by - BH / 2, BH, BH)];
        _share.frame = _rightG.frame;
    }
    // video: the time bar and ... above, the big buttons in the middle
    for (UIView *v in @[_scrubG, _moreG, _more, _el, _rem, _track, _scrubHit, _playG, _play, _backG, _back, _fwdG, _fwd]) v.hidden = !_video;
    BOOL seek = _player != nil;
    for (UIView *v in @[_scrubG, _el, _rem, _track, _scrubHit, _backG, _back, _fwdG, _fwd]) if (!seek) v.hidden = YES;
    if (_video) {
        CGFloat sy = by - BH / 2 - 18 - 25;
        [self place:nil glass:_scrubG frame:CGRectMake(18, sy - 25, W - 36, 50)];
        _el.frame = CGRectMake(36, sy - 10, 56, 20);
        _rem.frame = CGRectMake(W - 36 - 60, sy - 10, 60, 20);
        CGRect tr = CGRectMake(96, sy - 4, W - 96 - 102, 8);
        if (!_scrubbing) { _track.transform = CGAffineTransformIdentity; _track.frame = tr; _track.layer.cornerRadius = 4; }
        _scrubHit.frame = CGRectMake(80, sy - 25, W - 160, 50);
        [self place:_more glass:_moreG frame:CGRectMake(W - 22 - 50, sy - 25 - 14 - 50, 50, 50)];
        CGFloat cy = H / 2, PD = MIN(104, W * 0.24), SD = MIN(72, W * 0.165), off = MIN(118, W * 0.27);
        [self place:_play glass:_playG frame:CGRectMake(W / 2 - PD / 2, cy - PD / 2, PD, PD)];
        [self place:_back glass:_backG frame:CGRectMake(W / 2 - off - SD / 2, cy - SD / 2, SD, SD)];
        [self place:_fwd glass:_fwdG frame:CGRectMake(W / 2 + off - SD / 2, cy - SD / 2, SD, SD)];
    }
}
- (void)refresh {
    UIViewController *q = self.ql;
    UIToolbar *tb = self.tb; UINavigationBar *nb = self.nb;
    if (!q.view.window || !self.superview) { [_link invalidate]; _link = nil; return; }
    CFTimeInterval now = CACurrentMediaTime();
    if (now - _lastScan > 0.4) { _lastScan = now; [self scan]; [self setNeedsLayout]; }
    // follow Apple's bars: tap the photo and everything hides with them
    BOOL chrome = (tb.window && !tb.hidden && tb.alpha > 0.05) || (nb.window && !nb.hidden && nb.alpha > 0.05);
    CGFloat a = chrome ? 1 : 0;
    if (fabs(self.alpha - a) > 0.01 && ![self.layer animationForKey:@"opacity"]) [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ self.alpha = a; } completion:nil];
    NSString *t = _video ? @"Video" : @"Photo";
    if (![_title.text isEqualToString:t]) { _title.text = t; [self setNeedsLayout]; }
    AVPlayer *p = _player;
    BOOL playing = p ? p.rate > 0 : [MVKind(_iPlay) isEqualToString:@"play"] && [[_iPlay.image.description lowercaseString] containsString:@"pause"];
    NSString *sym = playing ? @"pause.fill" : @"play.fill";
    if (![_play.accessibilityValue isEqualToString:sym]) {
        _play.accessibilityValue = sym;
        [_play setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    }
    double D = MVDur(p);
    if (p && D > 0 && !_scrubbing) {
        double cur = CMTimeGetSeconds(p.currentTime);
        if (_loop && cur >= D - 0.08 && p.rate == 0) { [p seekToTime:kCMTimeZero]; [p play]; if (_speed != 1) p.rate = _speed; }
        [self showProgress:MAX(0, MIN(1, cur / D)) dur:D];
    }
}
- (void)tick:(CADisplayLink *)l { @try { [self refresh]; } @catch (__unused id e) {} }
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && !_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        if (@available(iOS 15.0, *)) _link.preferredFrameRateRange = CAFrameRateRangeMake(20, 30, 30);
        [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    } else if (!self.window) { [_link invalidate]; _link = nil; }
}
@end

#pragma mark - finding the viewer

#define MV_TAG 0x4D563236
static UIView *MVCommon(UIView *a, UIView *b) {
    for (UIView *p = a.superview; p; p = p.superview) if ([b isDescendantOfView:p]) return p;
    return nil;
}
static void MVClear(UINavigationBar *nb, UIToolbar *tb) {
    static const void *kClr = &kClr;
    for (UIView *bar in @[nb ?: (id)NSNull.null, tb ?: (id)NSNull.null]) {
        if (![bar isKindOfClass:[UIView class]] || objc_getAssociatedObject(bar, kClr)) continue;
        objc_setAssociatedObject(bar, kClr, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if ([bar isKindOfClass:[UINavigationBar class]]) {
            UINavigationBarAppearance *a = [UINavigationBarAppearance new]; [a configureWithTransparentBackground];
            UINavigationBar *n = (UINavigationBar *)bar; n.standardAppearance = a; n.compactAppearance = a; n.scrollEdgeAppearance = a;
        } else {
            UIToolbarAppearance *a = [UIToolbarAppearance new]; [a configureWithTransparentBackground];
            UIToolbar *t = (UIToolbar *)bar; t.standardAppearance = a; t.compactAppearance = a; t.scrollEdgeAppearance = a;
        }
    }
}
static void MVStyle(UIViewController *ql) {
    if (!gViewerOn || !ql.view.window) return;
    UIWindow *w = ql.view.window;
    static const void *kBars = &kBars;
    NSPointerArray *cached = objc_getAssociatedObject(ql, kBars);
    UINavigationBar *nb = cached.count > 1 ? (__bridge UINavigationBar *)[cached pointerAtIndex:0] : nil;
    UIToolbar *tb = cached.count > 1 ? (__bridge UIToolbar *)[cached pointerAtIndex:1] : nil;
    if ((nb && nb.window != w) || (tb && tb.window != w)) { nb = nil; tb = nil; }
    BOOL search = !(nb && tb);
    NSMutableArray *st = [NSMutableArray arrayWithObject:w]; int guard = 0;
    if (!search) [st removeAllObjects];
    while (st.count && guard++ < 5000 && !(nb && tb)) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (!nb && [v isKindOfClass:[UINavigationBar class]] && MVQLOf(v) == ql) nb = (UINavigationBar *)v;
        else if (!tb && [v isKindOfClass:[UIToolbar class]] && MVQLOf(v) == ql) tb = (UIToolbar *)v;
        [st addObjectsFromArray:v.subviews];
    }
    if (!nb && !tb) return;
    if (search) {
        NSPointerArray *pa = [NSPointerArray weakObjectsPointerArray];
        [pa addPointer:(__bridge void *)nb]; [pa addPointer:(__bridge void *)tb];
        objc_setAssociatedObject(ql, kBars, pa, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *host = (nb && tb) ? MVCommon(nb, tb) : (nb ?: tb).superview;
    if (!host) return;
    MVOverlay *o = (MVOverlay *)[host viewWithTag:MV_TAG];
    if (![o isKindOfClass:[MVOverlay class]] || o.superview != host) {
        o = [[MVOverlay alloc] initWithFrame:host.bounds];
        o.tag = MV_TAG;
        [host addSubview:o];
    }
    o.ql = ql; o.nb = nb; o.tb = tb;
    MVClear(nb, tb);
    if (host.subviews.lastObject != o) [host bringSubviewToFront:o];
    o.frame = host.bounds;
    [o refresh];
}

static void (*origQLLayout)(id, SEL);
static void QLLayout(UIViewController *self, SEL _cmd) {
    origQLLayout(self, _cmd);
    @try { MVStyle(self); } @catch (__unused id e) {}
}
static void (*origQLAppear)(id, SEL, BOOL);
static void QLAppear(UIViewController *self, SEL _cmd, BOOL a) {
    origQLAppear(self, _cmd, a);
    @try { MVStyle(self); } @catch (__unused id e) {}
    __weak UIViewController *ws = self;
    for (NSNumber *d in @[@0.05, @0.3, @0.8]) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { MVStyle(ws); } @catch (__unused id e) {} });
}
static void HookViewer(void) {
    static BOOL done; if (done) return;
    Class q = MVQLClass(); if (!q) return;
    done = YES;
    MSHookMessageEx(q, @selector(viewDidLayoutSubviews), (IMP)QLLayout, (IMP *)&origQLLayout);
    MSHookMessageEx(q, @selector(viewDidAppear:), (IMP)QLAppear, (IMP *)&origQLAppear);
}
