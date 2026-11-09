// ===================== Messages26: contact expand animation =====================
// Tap the contact photo / name at the top of a chat: the contact page grows out of the photo
// (a circle that opens from it over the chat, the photo lifting up), and going back folds it
// back into the photo. Same page, same info, just a nicer way in and out. Switch: "contactanim".
// Works whether Messages pushes the page or presents it. The animation plays in its own window
// on top, so nothing of Apple's flashes underneath.
// Included from Tweak.x before %ctor.


static CGRect M26AvatarRect(UINavigationBar *nb, UIView *to, UIView **outView) {
    UIView *best = nil; CGFloat bestD = CGFLOAT_MAX;
    if (nb.window) {
        CGFloat midX = nb.bounds.size.width / 2;
        NSMutableArray *st = [NSMutableArray arrayWithObject:nb]; int g = 0;
        while (st.count && g++ < 400) {
            UIView *v = st.lastObject; [st removeLastObject];
            if (v.hidden || v.alpha < 0.05) continue;
            NSString *n = NSStringFromClass(v.class);
            CGRect r = [v convertRect:v.bounds toView:nb];
            if ([n rangeOfString:@"Avatar"].location != NSNotFound && r.size.width >= 20 && r.size.width <= 110) {
                CGFloat d = fabs(CGRectGetMidX(r) - midX);
                if (d < bestD) { bestD = d; best = v; }
                continue;
            }
            [st addObjectsFromArray:v.subviews];
        }
    }
    if (outView) *outView = best;
    if (best) {
        CGRect r = [best convertRect:best.bounds toView:to];
        CGFloat s = MIN(r.size.width, r.size.height);
        return CGRectMake(CGRectGetMidX(r) - s / 2, CGRectGetMinY(r), s, s);
    }
    CGFloat W = to.bounds.size.width, top = to.window.safeAreaInsets.top;
    return CGRectMake(W / 2 - 22, top + 2, 44, 44);
}
static UIBezierPath *M26Circle(CGPoint c, CGFloat r) { return [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES]; }
static BOOL M26IsContactPage(UIViewController *vc) {
    if (!vc) return NO;
    if ([vc isKindOfClass:[UINavigationController class]]) vc = ((UINavigationController *)vc).viewControllers.firstObject;
    NSString *n = NSStringFromClass(vc.class);
    if ([n containsString:@"Search"] || [n hasPrefix:@"M26"]) return NO;
    return ([n hasPrefix:@"CK"] && [n containsString:@"Details"]) || [n hasPrefix:@"CNContact"] || [n containsString:@"ContactCard"];
}
static UINavigationBar *M26ChatBar(void) { return gChatBar; }

// one window over everything for the animation
static UIWindow *gAnimWin;
static UIView *M26AnimHost(UIWindow *w) {
    if (!w.windowScene) return nil;
    if (!gAnimWin || gAnimWin.windowScene != w.windowScene) {
        gAnimWin = [[UIWindow alloc] initWithWindowScene:w.windowScene];
        gAnimWin.windowLevel = UIWindowLevelAlert + 5;
        gAnimWin.backgroundColor = UIColor.clearColor;
        UIViewController *rv = [UIViewController new]; rv.view.backgroundColor = UIColor.clearColor;
        gAnimWin.rootViewController = rv;
    }
    gAnimWin.frame = w.bounds;
    gAnimWin.hidden = NO;
    UIView *box = [[UIView alloc] initWithFrame:gAnimWin.bounds];
    box.backgroundColor = UIColor.blackColor;
    [gAnimWin.rootViewController.view addSubview:box];
    return box;
}
static void M26AnimDone(UIView *box, BOOL fade) {
    void (^end)(void) = ^{ [box removeFromSuperview]; if (!gAnimWin.rootViewController.view.subviews.count) gAnimWin.hidden = YES; };
    if (fade) [UIView animateWithDuration:0.12 animations:^{ box.alpha = 0; } completion:^(__unused BOOL f) { end(); }];
    else end();
}

// opening: `fromSnap` is the chat, `after` shows the page (no animation), then the page grows out of the photo
static void M26Open(UIWindow *w, void (^show)(void (^shown)(void))) {
    UIView *avView = nil;
    CGRect av = M26AvatarRect(M26ChatBar(), w, &avView);
    UIView *fromSnap = [w snapshotViewAfterScreenUpdates:NO];
    UIView *avSnap = [avView snapshotViewAfterScreenUpdates:NO];
    UIView *box = M26AnimHost(w);
    if (!box || !fromSnap) { show(nil); return; }
    [box addSubview:fromSnap];
    UIView *dim = [[UIView alloc] initWithFrame:box.bounds]; dim.backgroundColor = UIColor.blackColor; dim.alpha = 0; [box addSubview:dim];
    show(^{
        UIView *toSnap = [w snapshotViewAfterScreenUpdates:YES];
        if (!toSnap) { M26AnimDone(box, YES); return; }
        [box addSubview:toSnap];
        CGPoint c = CGPointMake(CGRectGetMidX(av), CGRectGetMidY(av));
        CGFloat R = hypot(MAX(c.x, w.bounds.size.width - c.x), MAX(c.y, w.bounds.size.height - c.y)) + 20;
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = M26Circle(c, R).CGPath;
        toSnap.layer.mask = mask;
        CASpringAnimation *grow = [CASpringAnimation animationWithKeyPath:@"path"];
        grow.fromValue = (__bridge id)M26Circle(c, av.size.width / 2).CGPath; grow.toValue = (__bridge id)mask.path;
        grow.mass = 1; grow.stiffness = 150; grow.damping = 22; grow.duration = MIN(0.7, grow.settlingDuration);
        [mask addAnimation:grow forKey:@"grow"];
        if (avSnap) { avSnap.frame = av; avSnap.layer.cornerRadius = av.size.width / 2; avSnap.clipsToBounds = YES; [box addSubview:avSnap]; }
        toSnap.transform = CGAffineTransformMakeScale(0.97, 0.97);
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{
            fromSnap.transform = CGAffineTransformMakeScale(0.92, 0.92);
            dim.alpha = 0.35;
            toSnap.transform = CGAffineTransformIdentity;
            avSnap.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, 70), 2.1, 2.1);
        } completion:nil];
        [UIView animateWithDuration:0.25 delay:0.22 options:0 animations:^{ avSnap.alpha = 0; } completion:nil];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ M26AnimDone(box, YES); });
    });
}
// closing: the page folds back into the photo
static void M26Close(UIWindow *w, void (^hide)(void (^hidden)(void))) {
    UIView *fromSnap = [w snapshotViewAfterScreenUpdates:NO];
    UIView *box = M26AnimHost(w);
    if (!box || !fromSnap) { hide(nil); return; }
    [box addSubview:fromSnap];
    hide(^{
        UIView *toSnap = [w snapshotViewAfterScreenUpdates:YES];
        UIView *avView = nil;
        CGRect av = M26AvatarRect(M26ChatBar(), w, &avView);
        if (!toSnap) { M26AnimDone(box, YES); return; }
        [box insertSubview:toSnap atIndex:0];
        UIView *dim = [[UIView alloc] initWithFrame:box.bounds]; dim.backgroundColor = UIColor.blackColor; dim.alpha = 0.35;
        [box insertSubview:dim aboveSubview:toSnap];
        CGPoint c = CGPointMake(CGRectGetMidX(av), CGRectGetMidY(av));
        CGFloat R = hypot(MAX(c.x, w.bounds.size.width - c.x), MAX(c.y, w.bounds.size.height - c.y)) + 20;
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = M26Circle(c, av.size.width / 2).CGPath;
        fromSnap.layer.mask = mask;
        CABasicAnimation *shrink = [CABasicAnimation animationWithKeyPath:@"path"];
        shrink.fromValue = (__bridge id)M26Circle(c, R).CGPath; shrink.toValue = (__bridge id)mask.path;
        shrink.duration = 0.42; shrink.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4 :0 :0.2 :1];
        [mask addAnimation:shrink forKey:@"shrink"];
        toSnap.transform = CGAffineTransformMakeScale(0.92, 0.92);
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{
            toSnap.transform = CGAffineTransformIdentity; dim.alpha = 0;
            fromSnap.transform = CGAffineTransformMakeScale(0.97, 0.97);
        } completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.42 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            M26AnimDone(box, NO);
            if (avView) {   // the photo takes it back in with a little bounce
                CASpringAnimation *b = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
                b.additive = YES; b.fromValue = @0.18; b.toValue = @0; b.stiffness = 320; b.damping = 11; b.duration = b.settlingDuration;
                [avView.layer addAnimation:b forKey:@"m26.back"];
            }
        });
    });
}

#pragma mark - push / pop

static void (*origM26Push)(UINavigationController *, SEL, UIViewController *, BOOL);
static void M26Push(UINavigationController *self, SEL _cmd, UIViewController *vc, BOOL anim) {
    if (M26IsContactPage(vc)) gContactDebug = [NSString stringWithFormat:@"contact: push %@ anim=%d", NSStringFromClass(vc.class), anim];
    UIWindow *w = self.view.window;
    if (!gContactAnim || !anim || !w || !M26IsContactPage(vc) || self.presentedViewController) { origM26Push(self, _cmd, vc, anim); return; }
    __block BOOL done = NO;
    @try {
        M26Open(w, ^(void (^shown)(void)) {
            origM26Push(self, _cmd, vc, NO); done = YES;
            [self.view setNeedsLayout]; [self.view layoutIfNeeded];
            if (shown) shown();
        });
    } @catch (__unused id e) { if (!done) origM26Push(self, _cmd, vc, anim); }
}
static UIViewController *(*origM26Pop)(UINavigationController *, SEL, BOOL);
static UIViewController *M26Pop(UINavigationController *self, SEL _cmd, BOOL anim) {
    UIViewController *top = self.topViewController;
    UIWindow *w = self.view.window;
    UIGestureRecognizerState gs = self.interactivePopGestureRecognizer.state;
    BOOL interactive = gs == UIGestureRecognizerStateBegan || gs == UIGestureRecognizerStateChanged;
    if (!gContactAnim || !anim || interactive || !w || !M26IsContactPage(top) || self.viewControllers.count < 2 || self.presentedViewController) return origM26Pop(self, _cmd, anim);
    __block UIViewController *r = nil; __block BOOL done = NO;
    @try {
        M26Close(w, ^(void (^hidden)(void)) {
            r = origM26Pop(self, _cmd, NO); done = YES;
            [self.view setNeedsLayout]; [self.view layoutIfNeeded];
            if (hidden) hidden();
        });
    } @catch (__unused id e) { if (!done) r = origM26Pop(self, _cmd, anim); }
    return r;
}

#pragma mark - present / dismiss (when Messages shows the page as a sheet or full screen)

static void (*origM26Present)(UIViewController *, SEL, UIViewController *, BOOL, id);
static void M26Present(UIViewController *self, SEL _cmd, UIViewController *vc, BOOL anim, void (^completion)(void)) {
    if (M26IsContactPage(vc)) gContactDebug = [NSString stringWithFormat:@"contact: present %@ anim=%d style=%ld", NSStringFromClass(vc.class), anim, (long)vc.modalPresentationStyle];
    UIWindow *w = self.view.window;
    BOOL fromChat = M26ChatBar().window == w && CACurrentMediaTime() - gTopTapAt < 1.5;
    if (!gContactAnim || !anim || !w || !fromChat || !M26IsContactPage(vc)) { origM26Present(self, _cmd, vc, anim, completion); return; }
    __block BOOL done = NO;
    @try {
        if (vc.modalPresentationStyle == UIModalPresentationAutomatic || vc.modalPresentationStyle == UIModalPresentationPageSheet) vc.modalPresentationStyle = UIModalPresentationFullScreen;
        M26Open(w, ^(void (^shown)(void)) {
            origM26Present(self, _cmd, vc, NO, ^{
                if (shown) shown();
                if (completion) completion();
            });
            done = YES;
        });
    } @catch (__unused id e) { if (!done) origM26Present(self, _cmd, vc, anim, completion); }
}
static void (*origM26Dismiss)(UIViewController *, SEL, BOOL, id);
static void M26Dismiss(UIViewController *self, SEL _cmd, BOOL anim, void (^completion)(void)) {
    UIViewController *shown = self.presentedViewController ?: self;
    UIWindow *w = self.view.window ?: shown.view.window;
    BOOL ours = gContactAnim && anim && w && M26IsContactPage(shown) && shown.presentingViewController && M26ChatBar();
    if (!ours) { origM26Dismiss(self, _cmd, anim, completion); return; }
    __block BOOL done = NO;
    @try {
        M26Close(w, ^(void (^hidden)(void)) {
            origM26Dismiss(self, _cmd, NO, ^{
                if (hidden) hidden();
                if (completion) completion();
            });
            done = YES;
        });
    } @catch (__unused id e) { if (!done) origM26Dismiss(self, _cmd, anim, completion); }
}

static void M26NoteTouch(UIEvent *e) {
    if (e.type != UIEventTypeTouches) return;
    UITouch *t = e.allTouches.anyObject;
    if (t.phase != UITouchPhaseBegan) return;
    UINavigationBar *nb = M26ChatBar();
    if (!nb.window || t.window != nb.window) return;
    CGPoint p = [t locationInView:nb];
    if (p.y < nb.bounds.size.height + 40 && fabs(p.x - nb.bounds.size.width / 2) < nb.bounds.size.width * 0.3) gTopTapAt = CACurrentMediaTime();
}
static void StartContactAnim(void) {
    MSHookMessageEx([UINavigationController class], @selector(pushViewController:animated:), (IMP)M26Push, (IMP *)&origM26Push);
    MSHookMessageEx([UINavigationController class], @selector(popViewControllerAnimated:), (IMP)M26Pop, (IMP *)&origM26Pop);
    MSHookMessageEx([UIViewController class], @selector(presentViewController:animated:completion:), (IMP)M26Present, (IMP *)&origM26Present);
    MSHookMessageEx([UIViewController class], @selector(dismissViewControllerAnimated:completion:), (IMP)M26Dismiss, (IMP *)&origM26Dismiss);
}
