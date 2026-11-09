// ===================== Messages26: contact expand animation =====================
// Tap the contact photo / name at the top of a chat: the details page grows out of the photo
// (a circle that opens from it over the chat, the photo lifting up), and going back folds it
// back into the photo. Same page, same info, just a nicer way in and out. Switch: "contactanim".
// Included from Tweak.x before %ctor.

static CGRect M26AvatarRect(UINavigationBar *nb, UIView *to, UIView **outView) {
    UIView *best = nil; CGFloat bestD = CGFLOAT_MAX;
    if (nb) {
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
static BOOL M26IsDetails(UIViewController *vc) {
    Class D = NSClassFromString(@"CKDetailsController");
    if (D && [vc isKindOfClass:D]) return YES;
    NSString *n = NSStringFromClass(vc.class);
    return [n hasPrefix:@"CK"] && [n containsString:@"Details"] && ![n containsString:@"Search"];
}

static void (*origM26Push)(UINavigationController *, SEL, UIViewController *, BOOL);
static void M26Push(UINavigationController *self, SEL _cmd, UIViewController *vc, BOOL anim) {
    UIWindow *w = self.view.window;
    if (!gContactAnim || !anim || !w || !M26IsDetails(vc) || self.presentedViewController) { origM26Push(self, _cmd, vc, anim); return; }
    BOOL pushed = NO;
    @try {
        UIView *avView = nil;
        CGRect av = M26AvatarRect(self.navigationBar, w, &avView);
        UIView *fromSnap = [w snapshotViewAfterScreenUpdates:NO];
        UIView *avSnap = [avView snapshotViewAfterScreenUpdates:NO];
        origM26Push(self, _cmd, vc, NO); pushed = YES;
        [self.view setNeedsLayout]; [self.view layoutIfNeeded];
        UIView *toSnap = [w snapshotViewAfterScreenUpdates:YES];
        if (!fromSnap || !toSnap) return;
        UIView *box = [[UIView alloc] initWithFrame:w.bounds];
        box.backgroundColor = UIColor.blackColor;
        [box addSubview:fromSnap];
        UIView *dim = [[UIView alloc] initWithFrame:w.bounds]; dim.backgroundColor = UIColor.blackColor; dim.alpha = 0; [box addSubview:dim];
        [box addSubview:toSnap];
        CGPoint c = CGPointMake(CGRectGetMidX(av), CGRectGetMidY(av));
        CGFloat R = hypot(MAX(c.x, w.bounds.size.width - c.x), MAX(c.y, w.bounds.size.height - c.y)) + 20;
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = M26Circle(c, R).CGPath;
        toSnap.layer.mask = mask;
        CASpringAnimation *grow = [CASpringAnimation animationWithKeyPath:@"path"];
        grow.fromValue = (__bridge id)M26Circle(c, av.size.width / 2).CGPath; grow.toValue = (__bridge id)mask.path;
        grow.mass = 1; grow.stiffness = 140; grow.damping = 22; grow.duration = MIN(0.75, grow.settlingDuration);
        [mask addAnimation:grow forKey:@"grow"];
        if (avSnap) {
            avSnap.frame = av; [box addSubview:avSnap];
            avSnap.layer.cornerRadius = av.size.width / 2; avSnap.clipsToBounds = YES;
        }
        [w addSubview:box];
        toSnap.transform = CGAffineTransformMakeScale(0.97, 0.97);
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{
            fromSnap.transform = CGAffineTransformMakeScale(0.92, 0.92);
            dim.alpha = 0.35;
            toSnap.transform = CGAffineTransformIdentity;
            avSnap.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, 70), 2.1, 2.1);
        } completion:nil];
        [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{ avSnap.alpha = 0; } completion:nil];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.62 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.12 animations:^{ box.alpha = 0; } completion:^(__unused BOOL f) { [box removeFromSuperview]; }];
        });
    } @catch (__unused id e) { if (!pushed) origM26Push(self, _cmd, vc, anim); }
}

static UIViewController *(*origM26Pop)(UINavigationController *, SEL, BOOL);
static UIViewController *M26Pop(UINavigationController *self, SEL _cmd, BOOL anim) {
    UIViewController *top = self.topViewController;
    UIWindow *w = self.view.window;
    UIGestureRecognizerState gs = self.interactivePopGestureRecognizer.state;
    BOOL interactive = gs == UIGestureRecognizerStateBegan || gs == UIGestureRecognizerStateChanged;
    if (!gContactAnim || !anim || interactive || !w || !M26IsDetails(top) || self.viewControllers.count < 2 || self.presentedViewController) return origM26Pop(self, _cmd, anim);
    UIViewController *r = nil;
    @try {
        UIView *fromSnap = [w snapshotViewAfterScreenUpdates:NO];
        r = origM26Pop(self, _cmd, NO);
        [self.view setNeedsLayout]; [self.view layoutIfNeeded];
        UIView *toSnap = [w snapshotViewAfterScreenUpdates:YES];
        if (!fromSnap || !toSnap) return r;
        UIView *avView = nil;
        CGRect av = M26AvatarRect(self.navigationBar, w, &avView);
        UIView *box = [[UIView alloc] initWithFrame:w.bounds];
        box.backgroundColor = UIColor.blackColor;
        [box addSubview:toSnap];
        UIView *dim = [[UIView alloc] initWithFrame:w.bounds]; dim.backgroundColor = UIColor.blackColor; dim.alpha = 0.35; [box addSubview:dim];
        [box addSubview:fromSnap];
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
        [w addSubview:box];
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:0 animations:^{
            toSnap.transform = CGAffineTransformIdentity; dim.alpha = 0;
            fromSnap.transform = CGAffineTransformMakeScale(0.97, 0.97);
        } completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.42 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [box removeFromSuperview];
            if (avView) {   // the photo takes it back in with a little bounce
                CASpringAnimation *b = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
                b.additive = YES; b.fromValue = @0.18; b.toValue = @0; b.stiffness = 320; b.damping = 11; b.duration = b.settlingDuration;
                [avView.layer addAnimation:b forKey:@"m26.back"];
            }
        });
    } @catch (__unused id e) { if (!r) r = origM26Pop(self, _cmd, anim); }
    return r;
}
static void StartContactAnim(void) {
    MSHookMessageEx([UINavigationController class], @selector(pushViewController:animated:), (IMP)M26Push, (IMP *)&origM26Push);
    MSHookMessageEx([UINavigationController class], @selector(popViewControllerAnimated:), (IMP)M26Pop, (IMP *)&origM26Pop);
}
