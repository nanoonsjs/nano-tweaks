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
static NSHashTable *gMVMasked, *gMVNoTouch, *gMVHidden, *gMVOffPans;
static void MVMask(UIView *v) {
    if (!v || objc_getAssociatedObject(v, kMVMask)) return;
    v.layer.mask = [CALayer layer];   // draws nothing, still takes touches
    objc_setAssociatedObject(v, kMVMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!gMVMasked) gMVMasked = [NSHashTable weakObjectsHashTable];
    [gMVMasked addObject:v];
}
static void MVNoTouch(UIView *v) {
    if (!v || !v.userInteractionEnabled) return;
    v.userInteractionEnabled = NO;
    if (!gMVNoTouch) gMVNoTouch = [NSHashTable weakObjectsHashTable];
    [gMVNoTouch addObject:v];
}
// a file that isn't a photo or video (music, PDF...): Apple's viewer exactly as it was
static void MVRestoreApple(void) {
    for (UIView *v in [gMVMasked allObjects]) { if (objc_getAssociatedObject(v, kMVMask)) { v.layer.mask = nil; objc_setAssociatedObject(v, kMVMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); } }
    for (UIView *v in [gMVNoTouch allObjects]) v.userInteractionEnabled = YES;
    for (UIView *v in [gMVHidden allObjects]) v.hidden = NO;
    for (UIGestureRecognizer *g in [gMVOffPans allObjects]) g.enabled = YES;
    [gMVMasked removeAllObjects]; [gMVNoTouch removeAllObjects]; [gMVHidden removeAllObjects]; [gMVOffPans removeAllObjects];
}

// what a bar button is: from its symbol, label and system type
static NSString *MVKind(UIBarButtonItem *it) {
    NSString *act = it.action ? NSStringFromSelector(it.action).lowercaseString : @"";
    if ([act containsString:@"reply"]) return @"reply";
    if ([act containsString:@"tapback"] || [act containsString:@"acknowledg"] || [act containsString:@"react"]) return @"tapback";
    if ([act containsString:@"actionbutton"] || [act containsString:@"share"]) return @"share";
    if ([act containsString:@"done"] || [act containsString:@"dismiss"] || [act containsString:@"close"]) return @"done";
    if ([act containsString:@"play"] || [act containsString:@"pause"]) return @"play";
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
static void MVForward(UIBarButtonItem *it, UIView *from) {
    if (!it) return;
    if (it.action) {
        id target = it.target;
        if (!target) for (UIResponder *r = from; r; r = r.nextResponder) if ([r respondsToSelector:it.action]) { target = r; break; }
        if (target) { [[UIApplication sharedApplication] sendAction:it.action to:target from:it forEvent:nil]; return; }
    }
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

static UIImage *MVItemImage(UIBarButtonItem *it) {
    if (it.image) return it.image;
    UIView *v = it.customView; if (!v) { @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {} }
    NSMutableArray *st = [NSMutableArray arrayWithObject:v ?: [UIView new]]; int g = 0;
    while (st.count && g++ < 40) {
        UIView *x = st.firstObject; [st removeObjectAtIndex:0];
        if ([x isKindOfClass:[UIButton class]] && [(UIButton *)x currentImage]) return [(UIButton *)x currentImage];
        if ([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image) return ((UIImageView *)x).image;
        [st addObjectsFromArray:x.subviews];
    }
    return nil;
}
static double MVDur(AVPlayer *p) {
    CMTime d = p.currentItem.duration;
    if (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) return CMTimeGetSeconds(d);
    d = p.currentItem.asset.duration;
    return (CMTIME_IS_NUMERIC(d) && CMTimeGetSeconds(d) > 0) ? CMTimeGetSeconds(d) : 0;
}
static BOOL gMVAnyPlayerLayer;
   // Quick Look plays videos right here (so no player in the middle = not a video)
static AVPlayer *MVPlayerIn(UIView *root) {
    if (!root) return nil;
    gMVAnyPlayerLayer = NO;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root.layer]; int guard = 0;
    AVPlayer *best = nil;
    while (st.count && guard++ < 6000) {
        CALayer *l = st.lastObject; [st removeLastObject];
        if ([l isKindOfClass:[AVPlayerLayer class]]) gMVAnyPlayerLayer = YES;
        if ([l isKindOfClass:[AVPlayerLayer class]] && ((AVPlayerLayer *)l).player && !l.hidden && l.opacity > 0.01) {
            AVPlayer *p = ((AVPlayerLayer *)l).player;
            BOOL seen = YES;
            for (CALayer *u = l.superlayer; u && u != root.layer; u = u.superlayer) if (u.hidden || u.opacity < 0.01) { seen = NO; break; }
            for (CALayer *u = l; u && seen; u = u.superlayer) { id d = u.delegate; if ([d isKindOfClass:[UIView class]] && [NSStringFromClass([d class]) rangeOfString:@"LivePhoto"].location != NSNotFound) seen = NO; }
            if (!seen || !p.currentItem) continue;
            CGRect f = [l convertRect:l.bounds toLayer:root.layer];
            CGPoint mid = CGPointMake(CGRectGetMidX(root.bounds), CGRectGetMidY(root.bounds));
            if (!CGRectContainsPoint(f, mid) || f.size.width < root.bounds.size.width * 0.5) { if (l.sublayers.count) [st addObjectsFromArray:l.sublayers]; continue; }
            if (!best || (p.rate > 0 && best.rate == 0)) best = p;
        }
        if (l.sublayers.count) [st addObjectsFromArray:l.sublayers];
    }
    if (!best) {
        // Quick Look shows videos with AVPlayerViewController: ask it for its player
        NSMutableArray *vs = [NSMutableArray arrayWithObject:root]; int g2 = 0;
        CGPoint mid = CGPointMake(CGRectGetMidX(root.bounds), CGRectGetMidY(root.bounds));
        while (vs.count && g2++ < 4000 && !best) {
            UIView *v = vs.lastObject; [vs removeLastObject];
            if (v.hidden || v.alpha < 0.01) continue;
            UIResponder *nr = v.nextResponder;
            if ([nr isKindOfClass:[UIViewController class]] && [NSStringFromClass(nr.class) hasPrefix:@"AVPlayerViewController"] && ((UIViewController *)nr).view == v) {
                CGRect f = [v convertRect:v.bounds toView:root];
                BOOL seen = v.window != nil;
                for (UIView *u = v.superview; u && u != root && seen; u = u.superview) if (u.hidden || u.alpha < 0.01) seen = NO;
                AVPlayer *p = nil; @try { p = [nr valueForKey:@"player"]; } @catch (__unused id e) {}
                if (seen && p.currentItem && CGRectContainsPoint(f, mid)) { best = p; gMVAnyPlayerLayer = YES; break; }
            }
            [vs addObjectsFromArray:v.subviews];
        }
    }
    return best;
}
// a fingerprint of a picture (its size and a tiny 8x8 copy), to remember what was already saved
static NSString *MVImageKey(UIImage *img) {
    CGImageRef cg = img.CGImage; if (!cg) return nil;
    unsigned char px[8 * 8 * 4] = {0};
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(px, 8, 8, 8, 32, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, 8, 8), cg);
    CGContextRelease(ctx); CGColorSpaceRelease(cs);
    unsigned long h = 5381; for (int i = 0; i < 256; i++) h = h * 33 + (px[i] >> 3);
    return [NSString stringWithFormat:@"%zux%zu-%lx", CGImageGetWidth(cg), CGImageGetHeight(cg), h];
}
static BOOL MVWasSaved(UIImage *img) {
    NSString *k = MVImageKey(img);
    return k && [[[NSUserDefaults standardUserDefaults] arrayForKey:@"m26.savedMedia"] containsObject:k];
}
static void MVMarkSaved(UIImage *img) {
    NSString *k = MVImageKey(img); if (!k) return;
    NSMutableArray *a = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"m26.savedMedia"] mutableCopy] ?: [NSMutableArray array];
    if (![a containsObject:k]) [a addObject:k];
    while (a.count > 1000) [a removeObjectAtIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"m26.savedMedia"];
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
    UIView *_panel, *_catcher; UIVisualEffectView *_panelG;
    int _kind;
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
    _tap = MVButton(@"face.smiling", 21, self, @selector(doTap)); [self addSubview:_tap];
    _reply = MVButton(@"arrowshape.turn.up.left", 19, self, @selector(doReply)); [self addSubview:_reply];
    _save = MVButton(@"square.and.arrow.down", 19, self, @selector(doSave)); [self addSubview:_save];
    _share = MVButton(@"square.and.arrow.up", 19, self, @selector(doShare)); [self addSubview:_share];
    _play = MVButton(@"play.fill", 36, self, @selector(doPlay)); [self addSubview:_play];
    _back = MVButton(@"gobackward.10", 26, self, @selector(doBack)); [self addSubview:_back];
    _fwd = MVButton(@"goforward.10", 26, self, @selector(doFwd)); [self addSubview:_fwd];
    _more = MVButton(@"ellipsis", 19, self, @selector(toggleMore)); [self addSubview:_more];
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
    if (self.alpha < 0.05 || _kind == 0) return nil;
    UIView *h = [super hitTest:p withEvent:e];
    if (h == self || [h isKindOfClass:[UIVisualEffectView class]] || h == _title || h == _chev) return nil;   // empty spots go to Apple's viewer
    return (h.hidden || h.alpha < 0.05 || !h.userInteractionEnabled) ? nil : h;
}
- (void)press:(UIButton *)b { [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ b.transform = CGAffineTransformMakeScale(0.86, 0.86); } completion:nil]; }
- (void)unpress:(UIButton *)b { [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil]; }
- (void)toggleMore { if (_panel) [self closeMore]; else [self openMore]; }
- (void)openMore {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    CGRect from = _moreG.frame;
    CGFloat PW = 244, PH = 132;
    CGRect to = CGRectMake(CGRectGetMaxX(from) - PW, CGRectGetMaxY(from) - PH, PW, PH);
    _catcher = [[UIView alloc] initWithFrame:self.bounds];
    [_catcher addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMore)]];
    [self addSubview:_catcher];
    _panelG = MVGlass(from.size.height / 2); _panelG.frame = from;
    [self addSubview:_panelG];
    _panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PW, PH)];   // plain view: taps on it stay on it
    _panel.clipsToBounds = YES;
    [self addSubview:_panel];
    UILabel *h = [UILabel new]; h.text = @"Playback Speed"; h.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]; h.textColor = [UIColor colorWithWhite:1 alpha:0.55];
    h.frame = CGRectMake(18, 14, PW - 36, 16); [_panel addSubview:h];
    NSArray *speeds = @[@0.5, @1, @1.25, @1.5, @2];
    CGFloat cw = (PW - 28 - 4 * 5) / 5;
    for (NSUInteger i = 0; i < speeds.count; i++) {
        float r = [speeds[i] floatValue];
        UIButton *c = [UIButton buttonWithType:UIButtonTypeCustom];
        c.frame = CGRectMake(14 + i * (cw + 5), 38, cw, 34); c.layer.cornerRadius = 17; c.layer.cornerCurve = kCACornerCurveContinuous;
        c.tag = (NSInteger)(r * 100);
        [c setTitle:[NSString stringWithFormat:@"%g×", r] forState:UIControlStateNormal];
        c.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [c addTarget:self action:@selector(pickSpeed:) forControlEvents:UIControlEventTouchUpInside];
        [c addTarget:self action:@selector(press:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [c addTarget:self action:@selector(unpress:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        [_panel addSubview:c];
    }
    UIButton *lp = [UIButton buttonWithType:UIButtonTypeCustom]; lp.tag = 9;
    lp.frame = CGRectMake(14, 82, PW - 28, 38); lp.layer.cornerRadius = 19; lp.layer.cornerCurve = kCACornerCurveContinuous;
    lp.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [lp setImage:[UIImage systemImageNamed:@"repeat" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    lp.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 6);
    [lp addTarget:self action:@selector(toggleLoop) forControlEvents:UIControlEventTouchUpInside];
    [lp addTarget:self action:@selector(press:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [lp addTarget:self action:@selector(unpress:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [_panel addSubview:lp];
    [self paintMore];
    // the circle stretches into the panel, the contents come in as it opens
    _panel.frame = from; _panel.alpha = 0;
    for (UIView *v in _panel.subviews) v.center = CGPointMake(v.center.x - (PW - from.size.width), v.center.y - (PH - from.size.height));
    [UIView animateWithDuration:0.15 animations:^{ self->_more.alpha = 0; }];
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->_panelG.frame = to; self->_panelG.layer.cornerRadius = 26;
        self->_panel.frame = to;
        for (UIView *v in self->_panel.subviews) v.center = CGPointMake(v.center.x + (PW - from.size.width), v.center.y + (PH - from.size.height));
    } completion:nil];
    [UIView animateWithDuration:0.25 delay:0.1 options:0 animations:^{ self->_panel.alpha = 1; } completion:nil];
}
- (void)closeMore {
    UIView *p = _panel, *g = _panelG, *c = _catcher;
    _panel = nil; _panelG = nil; _catcher = nil;
    if (!p) return;
    CGRect to = _moreG.frame;
    [c removeFromSuperview];
    [UIView animateWithDuration:0.12 animations:^{ p.alpha = 0; }];
    [UIView animateWithDuration:0.42 delay:0.02 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        g.frame = to; g.layer.cornerRadius = to.size.height / 2; p.frame = to;
    } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.12 animations:^{ g.alpha = 0; self->_more.alpha = 1; } completion:^(__unused BOOL d) { [g removeFromSuperview]; [p removeFromSuperview]; }];
    }];
}
- (void)paintMore {
    for (UIView *v in _panel.subviews) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        UIButton *b = (UIButton *)v;
        BOOL on = b.tag == 9 ? _loop : abs((int)b.tag - (int)lroundf(_speed * 100)) < 1;
        b.backgroundColor = on ? UIColor.whiteColor : [UIColor colorWithWhite:1 alpha:0.12];
        UIColor *fg = on ? UIColor.blackColor : UIColor.whiteColor;
        [b setTitleColor:fg forState:UIControlStateNormal]; b.tintColor = fg;
        if (b.tag == 9) [b setTitle:_loop ? @"Loop On" : @"Loop" forState:UIControlStateNormal];
    }
}
- (void)pickSpeed:(UIButton *)b {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    _speed = b.tag / 100.0f;
    AVPlayer *p = _player;
    if (@available(iOS 16.0, *)) p.defaultRate = _speed;
    if (p.rate > 0) p.rate = _speed;
    [UIView transitionWithView:_panel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ [self paintMore]; } completion:nil];
}
- (void)toggleLoop {
    [[UISelectionFeedbackGenerator new] selectionChanged];
    _loop = !_loop;
    [UIView transitionWithView:_panel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ [self paintMore]; } completion:nil];
}
- (void)haptic { [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred]; }
- (void)doClose {
    [self haptic];
    if (_iDone) { MVForward(_iDone, self.tb ?: (UIView *)self.nb); return; }
    UIViewController *q = self.ql;
    UIViewController *pres = q.navigationController ?: q;
    [pres dismissViewControllerAnimated:YES completion:nil];
}
- (void)doTap {
    [self reactBurst];
    UIBarButtonItem *it = _iTap; if (!it) return;
    UIView *v = it.customView; if (!v) { @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {} }
    UIControl *ctl = nil;
    NSMutableArray *st = [NSMutableArray arrayWithObject:v ?: [UIView new]];
    while (st.count && !ctl) { UIView *x = st.firstObject; [st removeObjectAtIndex:0]; if ([x isKindOfClass:[UIControl class]]) ctl = (UIControl *)x; [st addObjectsFromArray:x.subviews]; }
    // 1. a menu (the reaction picker): open it right where our button is
    if (@available(iOS 14.0, *)) {
        UIContextMenuInteraction *mi = ctl.contextMenuInteraction;
        if (!mi) for (id<UIInteraction> x in (ctl ?: v).interactions) if ([x isKindOfClass:[UIContextMenuInteraction class]]) mi = (UIContextMenuInteraction *)x;
        SEL pm = NSSelectorFromString(@"_presentMenuAtLocation:");
        if ((it.menu || mi) && mi && [mi respondsToSelector:pm]) {
            CGPoint p = [self convertPoint:_tap.center toView:mi.view];
            ((void (*)(id, SEL, CGPoint))objc_msgSend)(mi, pm, p);
            return;
        }
        id pa = it.primaryAction; SEL ps = NSSelectorFromString(@"performWithSender:target:");
        if (pa && [pa respondsToSelector:ps]) { ((void (*)(id, SEL, id, id))objc_msgSend)(pa, ps, ctl ?: it, nil); return; }
    }
    // 2. its action, sent from its own button (some actions look at where the sender is)
    if (it.action) {
        id target = it.target;
        if (!target) for (UIResponder *r = self.tb; r; r = r.nextResponder) if ([r respondsToSelector:it.action]) { target = r; break; }
        if (target) { [[UIApplication sharedApplication] sendAction:it.action to:target from:(ctl ?: (id)it) forEvent:nil]; return; }
    }
    [ctl sendActionsForControlEvents:UIControlEventTouchUpInside];
}
- (void)doReply { [self haptic]; MVForward(_iReply, self.tb ?: (UIView *)self.nb); }
- (void)doShare { [self haptic]; MVForward(_iShare, self.tb ?: (UIView *)self.nb); }
- (void)doSave {
    UIImage *img = _photo.image;
    if (!img) return;
    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    MVMarkSaved(img);
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    [_save setImage:[UIImage systemImageNamed:@"checkmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_save setImage:[UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ [self setNeedsLayout]; [self layoutIfNeeded]; } completion:nil];
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
    } else MVForward(_iPlay, self.tb ?: (UIView *)self.nb);
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
// 0 = not a photo or video (leave it to Apple), 1 = photo, 2 = video, -1 = can't tell
- (int)fileKind {
    id item = nil; @try { item = [self.ql valueForKey:@"currentPreviewItem"]; } @catch (__unused id e) {}
    NSURL *u = nil; @try { if ([item respondsToSelector:@selector(previewItemURL)]) u = [item previewItemURL]; } @catch (__unused id e) {}
    NSString *ext = u.pathExtension.lowercaseString;
    if (!ext.length) {
        NSString *t = self.nb.topItem.title.lowercaseString;
        if ([t rangeOfString:@"."].location != NSNotFound) ext = t.pathExtension;
    }
    if (!ext.length) return -1;
    if ([@[@"jpg", @"jpeg", @"png", @"heic", @"heif", @"gif", @"webp", @"tif", @"tiff", @"bmp", @"dng", @"raw"] containsObject:ext]) return 1;
    if ([@[@"mov", @"mp4", @"m4v", @"3gp", @"avi", @"mkv", @"webm", @"hevc"] containsObject:ext]) return 2;
    return 0;
}
- (void)scan {
    UINavigationBar *nb = self.nb; UIToolbar *tb = self.tb;
    _kind = [self fileKind];
    if (_kind == 0) {
        // music, documents...: Apple's viewer untouched, ours out of the way
        MVRestoreApple();
        _video = NO; _player = nil;
        gMVDebug = @"viewer: not a photo / video (left to Apple)";
        return;
    }
    _iShare = _iPlay = _iReply = _iTap = _iDone = nil;
    NSMutableArray *dbg = [NSMutableArray array];
    for (UIBarButtonItem *it in tb.items) {
        NSString *k = MVKind(it);
        if (![k isEqualToString:@"space"]) {
            UIView *iv = nil; @try { iv = [it valueForKey:@"view"]; } @catch (__unused id e) {}
            [dbg addObject:[NSString stringWithFormat:@"%@(%@%@%@%@)", k, it.action ? NSStringFromSelector(it.action) : @"-", it.target ? @"+t" : @"", it.menu ? @" menu" : @"", it.primaryAction ? @" pa" : @""]];
            (void)iv;
        }
        if ([k isEqualToString:@"share"]) _iShare = it;
        else if ([k isEqualToString:@"play"]) _iPlay = it;
        else if ([k isEqualToString:@"reply"]) _iReply = it;
        else if ([k isEqualToString:@"tapback"] && !_iTap) _iTap = it;
    }
    gMVItems = [dbg componentsJoinedByString:@" "];
    UINavigationItem *top = nb.topItem;
    for (UIBarButtonItem *it in [(top.rightBarButtonItems ?: @[]) arrayByAddingObjectsFromArray:top.leftBarButtonItems ?: @[]]) {
        NSString *k = MVKind(it);
        if ([k isEqualToString:@"done"] || [it.title isEqualToString:@"Done"]) _iDone = it;
        else if ([k isEqualToString:@"share"] && !_iShare) _iShare = it;
    }
    if (!_iDone) _iDone = top.rightBarButtonItem;
    for (UIView *s in nb.subviews) MVMask(s);
    for (UIView *s in tb.subviews) { MVMask(s); if ([NSStringFromClass(s.class) containsString:@"Background"] && !s.hidden) { s.hidden = YES; if (!gMVHidden) gMVHidden = [NSHashTable weakObjectsHashTable]; [gMVHidden addObject:s]; } }
    tb.backgroundColor = UIColor.clearColor; nb.backgroundColor = UIColor.clearColor;
    // Apple's buttons that aren't ours (play, spaces) take no touches; reply / tapback / share are moved under ours
    for (UIBarButtonItem *it in tb.items) {
        UIView *v = nil; @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {}
        if ([v isKindOfClass:[UIView class]]) MVNoTouch(v);
    }
    UIView *root = self.superview;
    CGFloat W = root.bounds.size.width;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root ?: [UIView new]]; int guard = 0;
    UIImageView *photo = nil; CGFloat best = 0;
    while (st.count && guard++ < 3000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v == self || v == nb || v == tb) continue;
        NSString *n = NSStringFromClass(v.class);
        CGRect r = [v convertRect:v.bounds toView:root];
        if (([n containsString:@"Scrubber"] || [n containsString:@"Filmstrip"] || [n containsString:@"TimeSlider"]) && r.size.width > W * 0.5) { MVMask(v); MVNoTouch(v); continue; }
        BOOL playish = [n containsString:@"PlayButton"] || [n containsString:@"PlayPause"];
        if (!playish && ([v isKindOfClass:[UIButton class]] || [v isKindOfClass:[UIImageView class]])) {
            UIImage *im = [v isKindOfClass:[UIButton class]] ? [(UIButton *)v currentImage] : ((UIImageView *)v).image;
            NSString *d = im.description.lowercaseString;
            if ([d containsString:@"play"] && r.size.width >= 40 && r.size.width <= 160 && fabs(CGRectGetMidX(r) - W / 2) < 40) playish = YES;
        }
        if (playish && r.size.width >= 30 && r.size.width <= 180) { MVMask(v); MVNoTouch(v); continue; }
        if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image && r.size.width * r.size.height > best && r.size.width > W * 0.5) { best = r.size.width * r.size.height; photo = (UIImageView *)v; }
        [st addObjectsFromArray:v.subviews];
    }
    _photo = photo;
    [self hideStrips:root];
    [self killScrubPans:root];
    _player = MVPlayerIn(root);
    // a video only when Apple shows its play button for this item (photos have none), or a player is in the middle
    UIView *pv = nil; @try { pv = [_iPlay valueForKey:@"view"]; } @catch (__unused id e) {}
    BOOL playShown = _iPlay && _iPlay.enabled && (!pv || (pv.window && !pv.hidden && pv.alpha > 0.01 && pv.bounds.size.width > 2));
    // Quick Look's bottom bar has a play button only for videos (photos, and Live Photos, don't)
    (void)playShown;
    _video = _kind == 2 ? YES : (_kind == 1 ? NO : _iPlay != nil);
    gMVDebug = [NSString stringWithFormat:@"viewer: video=%d player=%d layers=%d items=%@", _video, _player != nil, gMVAnyPlayerLayer, gMVItems];
    if (!_video) _player = nil;
    // Apple's own icons for tapback and reply
    for (NSArray *pair in @[@[_reply, _iReply ?: (id)NSNull.null]]) {
        UIButton *b = pair[0]; UIBarButtonItem *it = pair[1] == NSNull.null ? nil : pair[1];
        UIImage *im = MVItemImage(it);
        if (im && ![b.accessibilityValue isEqualToString:im.description]) {
            b.accessibilityValue = im.description;
            UIImage *t = [im imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if (t.isSymbolImage) t = [t imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]];
            [b setImage:t forState:UIControlStateNormal];
        }
    }
}
- (void)hideStrips:(UIView *)root {
    CGFloat W = root.bounds.size.width, H = root.bounds.size.height;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root ?: [UIView new]]; int guard = 0;
    while (st.count && guard++ < 3000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v == self || v.hidden) continue;
        CGRect r = [v convertRect:v.bounds toView:root];
        BOOL strip = r.size.width >= W - 2 && r.size.height >= 40 && r.size.height <= 160 && (CGRectGetMaxY(r) >= H - 2 || CGRectGetMinY(r) <= 2);
        BOOL looks = [v isKindOfClass:[UIVisualEffectView class]] || [NSStringFromClass(v.class) rangeOfString:@"Background"].location != NSNotFound ||
                     [NSStringFromClass(v.class) rangeOfString:@"Backdrop"].location != NSNotFound || [NSStringFromClass(v.class) rangeOfString:@"Shadow"].location != NSNotFound ||
                     (v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0.05 && v.subviews.count == 0);
        if (strip && looks) { MVMask(v); continue; }
        if (strip && v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0.05) v.backgroundColor = UIColor.clearColor;
        [st addObjectsFromArray:v.subviews];
    }
}
// Quick Look's drag-on-the-video to rewind / fast-forward: off (swiping between items stays)
- (void)killScrubPans:(UIView *)root {
    NSMutableArray *st = [NSMutableArray arrayWithObject:root ?: [UIView new]]; int guard = 0;
    while (st.count && guard++ < 3000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v == self) continue;
        for (UIGestureRecognizer *g in v.gestureRecognizers) {
            if (!g.enabled || ![g isKindOfClass:[UIPanGestureRecognizer class]]) continue;
            if ([v isKindOfClass:[UIScrollView class]] && g == ((UIScrollView *)v).panGestureRecognizer) continue;
            NSString *d = @"";
            @try { d = [[g valueForKey:@"_targets"] description] ?: @""; } @catch (__unused id e) {}
            d = [d stringByAppendingString:NSStringFromClass(g.class)];
            NSString *l = d.lowercaseString;
            NSString *vn = NSStringFromClass(v.class).lowercaseString;
            BOOL media = [vn containsString:@"video"] || [vn containsString:@"media"] || [vn containsString:@"player"] || [vn containsString:@"movie"] || [vn containsString:@"avplayer"];
            if ([l containsString:@"scrub"] || [l containsString:@"seek"] || [l containsString:@"skim"] || [l containsString:@"timepan"] || (media && ![l containsString:@"dismiss"] && ![l containsString:@"transition"])) {
                g.enabled = NO;
                if (!gMVOffPans) gMVOffPans = [NSHashTable weakObjectsHashTable];
                [gMVOffPans addObject:g];
                gMVPans = [gMVPans stringByAppendingFormat:@" off:%@", NSStringFromClass(v.class)];
            }
        }
        [st addObjectsFromArray:v.subviews];
    }
}
// Apple's own reply / tapback / share buttons (invisible) sit right under ours, so a tap is a real tap on them
static const void *kMVOurs = &kMVOurs;
- (void)alignApple {
    for (NSArray *pair in @[]) {
        UIBarButtonItem *it = pair[0] == NSNull.null ? nil : pair[0]; UIButton *ours = pair[1];
        UIView *v = nil; @try { v = [it valueForKey:@"view"]; } @catch (__unused id e) {}
        if (![v isKindOfClass:[UIView class]] || !v.superview || ours.hidden || !self.tb.window) { ours.userInteractionEnabled = YES; continue; }
        CGPoint c = [self convertPoint:ours.center toView:v.superview];
        CGAffineTransform t = CGAffineTransformMakeTranslation(c.x - v.center.x, c.y - v.center.y);
        if (!CGAffineTransformEqualToTransform(v.transform, t)) v.transform = t;
        v.userInteractionEnabled = YES;
        for (UIView *p = v.superview; p && p != self.tb; p = p.superview) { p.userInteractionEnabled = YES; if (p.clipsToBounds) p.clipsToBounds = NO; }
        ours.userInteractionEnabled = NO;   // the touch goes through to Apple's button under it
        if (!objc_getAssociatedObject(v, kMVOurs)) {
            NSMutableArray *ctl = [NSMutableArray arrayWithObject:v]; UIControl *found = nil;
            while (ctl.count && !found) { UIView *x = ctl.firstObject; [ctl removeObjectAtIndex:0]; if ([x isKindOfClass:[UIControl class]]) found = (UIControl *)x; [ctl addObjectsFromArray:x.subviews]; }
            if (found) {
                [found addTarget:self action:@selector(appleDown:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
                [found addTarget:self action:@selector(appleUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
                objc_setAssociatedObject(found, kMVOurs, ours, OBJC_ASSOCIATION_ASSIGN);
            }
            objc_setAssociatedObject(v, kMVOurs, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}
- (void)appleDown:(UIControl *)c { UIButton *b = objc_getAssociatedObject(c, kMVOurs); if (b) [self press:b]; }
- (void)appleUp:(UIControl *)c {
    UIButton *b = objc_getAssociatedObject(c, kMVOurs); if (!b) return;
    [self unpress:b];
    if (b == _tap && c.touchInside) [self reactBurst];
    else if (c.touchInside) [self haptic];
}
// the reaction button: a wiggle and a few reactions float up out of it
- (void)reactBurst {
    static CFTimeInterval last; if (CACurrentMediaTime() - last < 0.4) return; last = CACurrentMediaTime();
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    CAKeyframeAnimation *sc = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    sc.values = @[@1, @1.35, @0.88, @1.08, @1]; sc.keyTimes = @[@0, @0.25, @0.5, @0.75, @1]; sc.duration = 0.55;
    CAKeyframeAnimation *rot = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rot.values = @[@0, @(-0.3), @0.25, @(-0.12), @0]; rot.keyTimes = sc.keyTimes; rot.duration = 0.55;
    [_tap.imageView.layer addAnimation:sc forKey:@"pop"]; [_tap.imageView.layer addAnimation:rot forKey:@"wig"];
    NSArray *em = @[@"❤️", @"👍", @"😂", @"‼️", @"👎", @"❓"];
    CGPoint c = _tap.center;
    for (NSUInteger i = 0; i < em.count; i++) {
        UILabel *l = [UILabel new]; l.text = em[i]; l.font = [UIFont systemFontOfSize:20]; [l sizeToFit];
        l.center = c; l.alpha = 0; l.transform = CGAffineTransformMakeScale(0.3, 0.3); l.userInteractionEnabled = NO;
        [self addSubview:l];
        CGFloat a = -M_PI_2 + ((CGFloat)i - 2.5) * 0.32, r = 60 + (i % 2) * 18;
        [UIView animateWithDuration:0.55 delay:i * 0.03 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
            l.alpha = 1; l.transform = CGAffineTransformIdentity; l.center = CGPointMake(c.x + cos(a) * r * 0.7, c.y + sin(a) * r);
        } completion:nil];
        [UIView animateWithDuration:0.35 delay:0.6 + i * 0.03 options:0 animations:^{ l.alpha = 0; l.center = CGPointMake(l.center.x, l.center.y - 18); l.transform = CGAffineTransformMakeScale(0.6, 0.6); } completion:^(__unused BOOL f) { [l removeFromSuperview]; }];
    }
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
    _leftG.hidden = _tap.hidden = _reply.hidden = YES;   // reply / reactions: off (Apple's need the chat behind)
    // already saved to Photos: no download button
    BOOL canSave = !_video && _photo.image && !MVWasSaved(_photo.image);
    _save.hidden = !canSave;
    if (canSave) {
        [self place:nil glass:_rightG frame:CGRectMake(W - 22 - 124, by - BH / 2, 124, BH)];
        _save.frame = CGRectMake(W - 22 - 118, by - BH / 2, 56, BH);
        _share.frame = CGRectMake(W - 22 - 62, by - BH / 2, 56, BH);
    } else {
        [self place:nil glass:_rightG frame:CGRectMake(W - 22 - BH, by - BH / 2, BH, BH)];
        _share.frame = _rightG.frame;
    }
    @try { [self alignApple]; } @catch (__unused id e) {}
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
    CGFloat a = (chrome && _kind != 0) ? 1 : 0;
    if (fabs(self.alpha - a) > 0.01 && ![self.layer animationForKey:@"opacity"]) [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{ self.alpha = a; } completion:nil];
    if (_panel && (!_video || a == 0)) [self closeMore];
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


#pragma mark - FaceTime: one glass panel that grows out of the button (Audio / Video in the same place)

@interface M26FTPanel : NSObject
+ (instancetype)shared;
- (void)open:(UIButton *)b;
@end
@implementation M26FTPanel {
    UIView *_catcher, *_panel; UIVisualEffectView *_glass;
    __weak UIButton *_btn; NSArray<UIAction *> *_acts;
    CGRect _from;
}
static const void *kM26FTMenu = &kM26FTMenu;
+ (instancetype)shared { static M26FTPanel *s; static dispatch_once_t o; dispatch_once(&o, ^{ s = [M26FTPanel new]; }); return s; }
static void M26FTFlatten(UIMenu *m, NSMutableArray *out) {
    for (UIMenuElement *e in m.children) {
        if ([e isKindOfClass:[UIMenu class]]) M26FTFlatten((UIMenu *)e, out);
        else if ([e isKindOfClass:[UIAction class]]) [out addObject:e];
    }
}
- (void)open:(UIButton *)b {
    if (_panel) { [self close]; return; }
    UIMenu *m = objc_getAssociatedObject(b, kM26FTMenu);
    NSMutableArray *acts = [NSMutableArray array]; M26FTFlatten(m, acts);
    if (!acts.count || !b.window) return;
    _btn = b; _acts = acts;
    UIWindow *w = b.window;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIView *g0 = objc_getAssociatedObject(b, &kGlassKey);
    _from = g0.window ? [g0 convertRect:g0.bounds toView:w] : [b convertRect:b.bounds toView:w];
    CGFloat RH = 52, PW = 236, PH = acts.count * RH + 12;
    CGRect to = CGRectMake(CGRectGetMaxX(_from) - PW, CGRectGetMinY(_from), PW, PH);
    _catcher = [[UIView alloc] initWithFrame:w.bounds];
    [_catcher addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    [w addSubview:_catcher];
    _glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    _glass.frame = _from; _glass.clipsToBounds = YES; _glass.layer.cornerCurve = kCACornerCurveContinuous; _glass.layer.cornerRadius = _from.size.height / 2;
    _glass.layer.borderWidth = 0.8; _glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    [w addSubview:_glass];
    _panel = [[UIView alloc] initWithFrame:_from]; _panel.clipsToBounds = YES; _panel.alpha = 0;
    [w addSubview:_panel];
    UIView *rows = [[UIView alloc] initWithFrame:CGRectMake(PW - _from.size.width - (PW - _from.size.width), 0, PW, PH)];
    rows.frame = CGRectMake(-(PW - _from.size.width), 0, PW, PH);
    rows.tag = 7;
    for (NSUInteger i = 0; i < acts.count; i++) {
        UIAction *a = acts[i];
        UIButton *r = [UIButton buttonWithType:UIButtonTypeCustom];
        r.frame = CGRectMake(6, 6 + i * RH, PW - 12, RH); r.tag = 100 + i;
        r.layer.cornerRadius = 20; r.layer.cornerCurve = kCACornerCurveContinuous;
        [r addTarget:self action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
        [r addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [r addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        UIImageView *ic = [[UIImageView alloc] initWithImage:[a.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        ic.tintColor = UIColor.labelColor; ic.contentMode = UIViewContentModeCenter; ic.frame = CGRectMake(12, 0, 30, RH); ic.userInteractionEnabled = NO;
        [r addSubview:ic];
        UILabel *t = [UILabel new]; t.text = a.title; t.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium]; t.textColor = UIColor.labelColor;
        t.frame = CGRectMake(50, 0, PW - 74, RH); t.userInteractionEnabled = NO; [r addSubview:t];
        [rows addSubview:r];
        r.alpha = 0; r.transform = CGAffineTransformMakeTranslation(0, -8);
        [UIView animateWithDuration:0.32 delay:0.05 + i * 0.03 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ r.alpha = 1; r.transform = CGAffineTransformIdentity; } completion:nil];
    }
    [_panel addSubview:rows];
    [UIView animateWithDuration:0.36 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->_glass.frame = to; self->_glass.layer.cornerRadius = 26;
        self->_panel.frame = to;
        rows.frame = CGRectMake(0, 0, PW, PH);
    } completion:nil];
    [UIView animateWithDuration:0.14 delay:0.04 options:0 animations:^{ self->_panel.alpha = 1; } completion:nil];
}
- (void)down:(UIButton *)r { [UIView animateWithDuration:0.12 animations:^{ r.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.18]; r.transform = CGAffineTransformMakeScale(0.97, 0.97); }]; }
- (void)up:(UIButton *)r { [UIView animateWithDuration:0.3 animations:^{ r.backgroundColor = UIColor.clearColor; r.transform = CGAffineTransformIdentity; }]; }
- (void)pick:(UIButton *)r {
    [self up:r];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    NSUInteger i = r.tag - 100;
    UIAction *a = i < _acts.count ? _acts[i] : nil;
    UIButton *b = _btn;
    [self close];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SEL ps = NSSelectorFromString(@"performWithSender:target:");
        if (a && [a respondsToSelector:ps]) ((void (*)(id, SEL, id, id))objc_msgSend)(a, ps, b, nil);
    });
}
- (void)close {
    UIView *p = _panel, *c = _catcher; UIVisualEffectView *g = _glass; UIButton *b = _btn;
    _panel = nil; _catcher = nil; _glass = nil;
    if (!p) return;
    [c removeFromSuperview];
    CGRect to = _from;
    UIView *rows = [p viewWithTag:7];
    [UIView animateWithDuration:0.1 animations:^{ p.alpha = 0; }];
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        g.frame = to; g.layer.cornerRadius = to.size.height / 2; p.frame = to;
        rows.frame = CGRectMake(-(rows.bounds.size.width - to.size.width), 0, rows.bounds.size.width, rows.bounds.size.height);
    } completion:^(__unused BOOL f) {
        (void)b;
        [UIView animateWithDuration:0.1 animations:^{ g.alpha = 0; } completion:^(__unused BOOL d) { [g removeFromSuperview]; [p removeFromSuperview]; }];
    }];
}
@end
static void M26FTInstall(UIButton *b) {
    if (!b || objc_getAssociatedObject(b, kM26FTMenu)) return;
    UIMenu *m = b.menu;
    if (!m) return;
    objc_setAssociatedObject(b, kM26FTMenu, m, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    b.showsMenuAsPrimaryAction = NO;
    b.menu = nil;
    [b addTarget:[M26FTPanel shared] action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
}
