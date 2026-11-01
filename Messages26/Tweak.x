// Messages26 0.1.0 - made by nano
// 0.1.0: liquid glass message field + glass "+" (camera / App Store buttons and the
//        app strip are gone), glass back / name / FaceTime in conversations, and a
//        liquid glass app menu that grows out of "+" (Photos, Camera, Apple Cash...).
//        Debug: hold three fingers on the screen.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

#define PLUS_TAG  0x4D323650
#define GLASS_TAG 0x4D323647
#define DEBUG_TAG 0x4D323644
#define MENU_TAG  0x4D32364D

static NSString *gDebug = @"-", *gNavDebug = @"-";
static BOOL gShowDebug = NO;
static __weak UIView *gEntry, *gStrip, *gPhotoBtn;
static __weak UICollectionView *gStripCV;

static BOOL IsDark(UIView *v) { return v.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight; }

// iOS 26 glass: blur + a light tint + a thin bright rim.
static UIVisualEffectView *GlassView(UIView *forTrait) {
    BOOL dark = IsDark(forTrait);
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:dark ? UIBlurEffectStyleSystemUltraThinMaterialDark : UIBlurEffectStyleSystemUltraThinMaterialLight]];
    g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.contentView.backgroundColor = dark ? [UIColor colorWithWhite:1 alpha:0.07] : [UIColor colorWithWhite:1 alpha:0.45];
    g.layer.borderWidth = 0.8;
    g.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.17] : [UIColor colorWithWhite:0 alpha:0.08]).CGColor;
    return g;
}
static UIColor *Ink(UIView *v) { return IsDark(v) ? UIColor.whiteColor : UIColor.blackColor; }

static UIView *Find(UIView *root, BOOL (^test)(UIView *v), int limit) {
    NSMutableArray *st = [NSMutableArray arrayWithObject:root];
    int g = 0;
    while (st.count && g++ < limit) {
        UIView *v = st.firstObject; [st removeObjectAtIndex:0];
        if (v != root && test(v)) return v;
        [st addObjectsFromArray:v.subviews];
    }
    return nil;
}

#pragma mark - the "+" menu

@interface M26Menu : NSObject
+ (instancetype)shared;
- (void)open:(UIButton *)plus;
@end

// Apps in the (hidden) app strip: name, icon, and how to open them.
static NSArray *StripApps(void) {
    UICollectionView *cv = gStripCV;
    if (!cv) return @[];
    NSMutableArray *out = [NSMutableArray array];
    NSInteger secs = [cv numberOfSections];
    for (NSInteger s = 0; s < secs; s++) {
        NSInteger n = [cv numberOfItemsInSection:s];
        for (NSInteger i = 0; i < n && out.count < 30; i++) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:i inSection:s];
            UICollectionViewCell *cell = [cv cellForItemAtIndexPath:ip];
            if (!cell && [cv.dataSource respondsToSelector:@selector(collectionView:cellForItemAtIndexPath:)]) {
                @try { cell = [cv.dataSource collectionView:cv cellForItemAtIndexPath:ip]; } @catch (__unused id e) {}
            }
            NSString *name = cell.accessibilityLabel;
            UIImage *icon = nil; CGFloat area = 0;
            NSMutableArray *st = cell ? [NSMutableArray arrayWithObject:cell] : [NSMutableArray array];
            int g = 0;
            while (st.count && g++ < 60) {
                UIView *v = st.lastObject; [st removeLastObject];
                if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image && v.bounds.size.width * v.bounds.size.height > area) { icon = ((UIImageView *)v).image; area = v.bounds.size.width * v.bounds.size.height; }
                if (!name.length && [v isKindOfClass:[UILabel class]]) name = ((UILabel *)v).text;
                if (!name.length && v.accessibilityLabel.length) name = v.accessibilityLabel;
                [st addObjectsFromArray:v.subviews];
            }
            if (!name.length) name = [NSString stringWithFormat:@"App %ld", (long)i + 1];
            [out addObject:@{@"name": name, @"icon": icon ?: [UIImage systemImageNamed:@"app.fill"], @"ip": ip}];
        }
    }
    return out;
}
static void OpenStripApp(NSIndexPath *ip) {
    UICollectionView *cv = gStripCV;
    if (!cv || !ip) return;
    [cv selectItemAtIndexPath:ip animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    if ([cv.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) [cv.delegate collectionView:cv didSelectItemAtIndexPath:ip];
}

@implementation M26Menu {
    UIView *_dim, *_panel;
    __weak UIButton *_plus;
    NSArray *_items;
}
+ (instancetype)shared { static M26Menu *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Menu new]; }); return t; }
- (void)open:(UIButton *)plus {
    UIWindow *w = plus.window;
    if (!w || _panel.superview) return;
    _plus = plus;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    [w endEditing:YES];
    // Photos first, then Camera, then the rest of the apps.
    NSMutableArray *items = [NSMutableArray array];
    NSArray *apps = StripApps();
    NSDictionary *photos = nil;
    for (NSDictionary *a in apps) if ([[a[@"name"] lowercaseString] containsString:@"photo"]) photos = a;
    if (photos) [items addObject:photos];
    [items addObject:@{@"name": @"Camera", @"icon": [UIImage systemImageNamed:@"camera.fill"], @"camera": @YES}];
    for (NSDictionary *a in apps) if (a != photos && ![[a[@"name"] lowercaseString] containsString:@"app store"]) [items addObject:a];
    _items = items;

    _dim = [[UIView alloc] initWithFrame:w.bounds];
    _dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [_dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    [w addSubview:_dim];

    CGRect pf = [plus convertRect:plus.bounds toView:w];
    CGFloat W = MIN(w.bounds.size.width - 40, 330), rowH = 62;
    CGFloat H = MIN(items.count * rowH + 24, w.bounds.size.height * 0.62);
    CGFloat bottom = CGRectGetMinY(pf) - 12;
    _panel = [[UIView alloc] initWithFrame:CGRectMake(16, bottom - H, W, H)];
    _panel.tag = MENU_TAG;
    _panel.layer.shadowColor = UIColor.blackColor.CGColor; _panel.layer.shadowOpacity = 0.35; _panel.layer.shadowRadius = 30; _panel.layer.shadowOffset = CGSizeMake(0, 12);
    UIVisualEffectView *g = GlassView(plus);
    g.frame = _panel.bounds; g.layer.cornerRadius = 34; g.userInteractionEnabled = YES;
    [_panel addSubview:g];
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:g.bounds];
    sv.contentSize = CGSizeMake(W, items.count * rowH + 24);
    sv.showsVerticalScrollIndicator = NO;
    [g.contentView addSubview:sv];
    for (NSUInteger i = 0; i < items.count; i++) {
        NSDictionary *it = items[i];
        UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
        row.frame = CGRectMake(0, 12 + i * rowH, W, rowH);
        row.tag = i;
        [row addTarget:self action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
        [row addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [row addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchDragExit | UIControlEventTouchCancel];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(22, 9, 44, 44)];
        iv.image = it[@"icon"]; iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.layer.cornerRadius = 22; iv.clipsToBounds = YES;
        if (it[@"camera"]) { iv.contentMode = UIViewContentModeCenter; iv.tintColor = UIColor.whiteColor; iv.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
            iv.image = [UIImage systemImageNamed:@"camera.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold]]; }
        iv.userInteractionEnabled = NO;
        [row addSubview:iv];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(84, 0, W - 100, rowH)];
        l.text = it[@"name"]; l.font = [UIFont systemFontOfSize:21 weight:UIFontWeightRegular]; l.textColor = Ink(plus);
        l.userInteractionEnabled = NO;
        [row addSubview:l];
        [sv addSubview:row];
        // rows float in one after another
        row.alpha = 0; row.transform = CGAffineTransformMakeTranslation(0, 14);
        [UIView animateWithDuration:0.4 delay:0.08 + 0.025 * i usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:0 animations:^{ row.alpha = 1; row.transform = CGAffineTransformIdentity; } completion:nil];
    }
    [w addSubview:_panel];
    // Liquid open: a drop leaves the "+", stretches up and swells into the menu.
    CGPoint from = CGPointMake(CGRectGetMidX(pf) - _panel.center.x, CGRectGetMidY(pf) - _panel.center.y);
    _panel.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(from.x, from.y), 44 / W, 44 / H);
    g.layer.cornerRadius = 34;
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.35 animations:^{
            self->_panel.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(from.x * 0.45, from.y * 0.45), 0.35, 0.62);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.35 relativeDuration:0.45 animations:^{ self->_panel.transform = CGAffineTransformMakeScale(1.03, 0.98); }];
        [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{ self->_panel.transform = CGAffineTransformIdentity; }];
    } completion:nil];
    [UIView animateWithDuration:0.3 animations:^{ self->_dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25]; plus.transform = CGAffineTransformMakeRotation(M_PI_4); }];
}
- (void)down:(UIButton *)b { [UIView animateWithDuration:0.15 animations:^{ b.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.18]; b.transform = CGAffineTransformMakeScale(0.97, 0.97); }]; }
- (void)up:(UIButton *)b { [UIView animateWithDuration:0.25 animations:^{ b.backgroundColor = UIColor.clearColor; b.transform = CGAffineTransformIdentity; }]; }
- (void)closeThen:(void (^)(void))then {
    UIView *panel = _panel, *dim = _dim; UIButton *plus = _plus;
    _panel = nil; _dim = nil;
    if (!panel) { if (then) then(); return; }
    CGRect pf = [plus convertRect:plus.bounds toView:panel.superview];
    CGPoint to = CGPointMake(CGRectGetMidX(pf) - panel.center.x, CGRectGetMidY(pf) - panel.center.y);
    CGFloat W = panel.bounds.size.width, H = panel.bounds.size.height;
    [UIView animateKeyframesWithDuration:0.38 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.4 animations:^{ panel.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(to.x * 0.4, to.y * 0.4), 0.4, 0.6); }];
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.6 animations:^{ panel.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(to.x, to.y), 40 / W, 40 / H); panel.alpha = 0; }];
    } completion:^(__unused BOOL d) { [panel removeFromSuperview]; }];
    [UIView animateWithDuration:0.3 animations:^{ dim.backgroundColor = UIColor.clearColor; plus.transform = CGAffineTransformIdentity; } completion:^(__unused BOOL d) { [dim removeFromSuperview]; }];
    // "+" swallows the drop
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@1, @1, @1.15, @0.95, @1]; k.duration = 0.6;
    [plus.layer addAnimation:k forKey:@"m26.swallow"];
    if (then) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), then);
}
- (void)close { [self closeThen:nil]; }
- (void)pick:(UIButton *)b {
    NSDictionary *it = b.tag < (NSInteger)_items.count ? _items[b.tag] : nil;
    [[UISelectionFeedbackGenerator new] selectionChanged];
    [self closeThen:^{
        if (it[@"camera"]) { UIButton *pb = (UIButton *)gPhotoBtn; [pb sendActionsForControlEvents:UIControlEventTouchUpInside]; }
        else if (it[@"ip"]) OpenStripApp(it[@"ip"]);
    }];
}
@end

#pragma mark - message field

// The two buttons left of the field (camera, App Store), by place.
static NSArray *LeftButtons(UIView *entry, UIView *field) {
    NSMutableArray *out = [NSMutableArray array];
    CGFloat fx = [field convertPoint:CGPointZero toView:entry].x;
    NSMutableArray *st = [NSMutableArray arrayWithArray:entry.subviews];
    int g = 0;
    while (st.count && g++ < 200) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == PLUS_TAG || v == field || [field isDescendantOfView:v]) { if (v != field && [field isDescendantOfView:v]) [st addObjectsFromArray:v.subviews]; continue; }
        CGRect f = [v convertRect:v.bounds toView:entry];
        if ([v isKindOfClass:[UIControl class]] && CGRectGetMaxX(f) <= fx + 2 && f.size.width < 90) { [out addObject:v]; continue; }
        [st addObjectsFromArray:v.subviews];
    }
    return out;
}
static UIView *FieldOf(UIView *entry) {
    UIView *tv = Find(entry, ^BOOL(UIView *v) { return [v isKindOfClass:[UITextView class]] && v.bounds.size.width > 100; }, 300);
    if (!tv) return nil;
    // the rounded box around the text
    UIView *box = tv;
    for (UIView *p = tv.superview; p && p != entry; p = p.superview) {
        if (p.layer.borderWidth > 0 || p.layer.cornerRadius > 8) { box = p; break; }
        if (p.bounds.size.width > entry.bounds.size.width * 0.9) break;
        box = p;
    }
    return box;
}
static UIView *StripOf(UIView *entry) {
    return Find(entry, ^BOOL(UIView *v) {
        NSString *n = NSStringFromClass([v class]);
        return [n containsString:@"AppStrip"] || [n containsString:@"BrowserSwitcher"] || [n containsString:@"AppDrawer"];
    }, 400);
}
static void StyleEntry(UIView *entry) {
    UIView *field = FieldOf(entry);
    if (!field) { gDebug = [NSString stringWithFormat:@"entry=%@ no field", NSStringFromClass([entry class])]; return; }
    gEntry = entry;
    // field: dark glass pill
    BOOL dark = IsDark(entry);
    CGFloat h = field.bounds.size.height, r = MIN(h / 2, 24);
    if (field.layer.cornerRadius != r) { field.layer.cornerRadius = r; field.layer.cornerCurve = kCACornerCurveContinuous; }
    UIColor *fill = dark ? [UIColor colorWithWhite:1 alpha:0.10] : [UIColor colorWithWhite:0 alpha:0.05];
    if (![field.backgroundColor isEqual:fill]) field.backgroundColor = fill;
    field.layer.borderWidth = 0.8;
    field.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.16] : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    // camera + App Store buttons: hidden; the glass "+" takes their place
    NSArray *left = LeftButtons(entry, field);
    for (UIView *b in left) { if (b.alpha > 0) b.alpha = 0; if (b.userInteractionEnabled) b.userInteractionEnabled = NO; }
    for (UIView *b in left) {
        NSString *d = [[(UIButton *)b imageForState:UIControlStateNormal] description] ?: @"";
        if ([d containsString:@"camera"] || [NSStringFromClass([b class]) containsString:@"Photo"]) gPhotoBtn = b;
    }
    if (!gPhotoBtn && left.count) gPhotoBtn = left.firstObject;
    CGRect ff = [field convertRect:field.bounds toView:entry];
    UIButton *plus = (UIButton *)[entry viewWithTag:PLUS_TAG];
    CGFloat D = MAX(40, MIN(h, 50));
    if (!plus) {
        plus = [UIButton buttonWithType:UIButtonTypeCustom];
        plus.tag = PLUS_TAG;
        UIVisualEffectView *g = GlassView(entry);
        g.tag = GLASS_TAG;
        [plus addSubview:g];
        [plus setImage:[UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
        [plus addTarget:[M26Menu shared] action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
        [entry addSubview:plus];
    }
    plus.tintColor = Ink(entry);
    CGRect pf = CGRectMake(round(MAX(8, CGRectGetMinX(ff) - D - 12)), round(CGRectGetMaxY(ff) - h / 2 - D / 2), D, D);
    if (h > 60) pf.origin.y = round(CGRectGetMaxY(ff) - D - 2);   // multi-line: stays at the bottom
    if (!CGRectEqualToRect(plus.frame, pf) && CGAffineTransformIsIdentity(plus.transform)) plus.frame = pf;
    UIView *g = [plus viewWithTag:GLASS_TAG];
    g.frame = plus.bounds; g.layer.cornerRadius = D / 2;
    [plus bringSubviewToFront:plus.imageView];
    [entry bringSubviewToFront:plus];
    // app strip: kept (its apps fill the "+" menu) but hidden
    UIView *strip = StripOf(entry);
    if (strip) {
        gStrip = strip;
        if (strip.alpha > 0) strip.alpha = 0;
        if (strip.userInteractionEnabled) strip.userInteractionEnabled = NO;
        UICollectionView *cv = (UICollectionView *)Find(strip, ^BOOL(UIView *v) { return [v isKindOfClass:[UICollectionView class]]; }, 100);
        if (cv) gStripCV = cv;
    }
    gDebug = [NSString stringWithFormat:@"entry=%@ field=%@ %.0fx%.0f\n left=%lu photo=%@\n strip=%@ %.0f cv=%d apps=%lu",
              NSStringFromClass([entry class]), NSStringFromClass([field class]), ff.size.width, ff.size.height,
              (unsigned long)left.count, NSStringFromClass([gPhotoBtn class]),
              strip ? NSStringFromClass([strip class]) : @"none", strip.bounds.size.height, gStripCV != nil, (unsigned long)(gStripCV.numberOfSections ? [gStripCV numberOfItemsInSection:0] : 0)];
}

// The entry view's height without the (hidden) app strip.
static CGSize (*origEntrySize)(id, SEL, CGSize);
static CGSize EntrySize(UIView *self, SEL _cmd, CGSize s) {
    CGSize r = origEntrySize(self, _cmd, s);
    UIView *strip = gStrip;
    if (strip && [strip isDescendantOfView:self] && strip.bounds.size.height > 10 && strip.bounds.size.height < r.height) r.height -= strip.bounds.size.height;
    return r;
}
static void (*origEntryLayout)(id, SEL);
static void EntryLayout(UIView *self, SEL _cmd) {
    origEntryLayout(self, _cmd);
    @try { StyleEntry(self); } @catch (__unused id e) {}
}

#pragma mark - conversation top bar

static void GlassBehind(UIView *v, CGFloat padX, CGFloat padY, BOOL circle) {
    UIView *host = v.superview;
    if (!host) return;
    static const char kG = 0;
    UIVisualEffectView *g = objc_getAssociatedObject(v, &kG);
    if (!g || g.superview != host) {
        [g removeFromSuperview];
        g = GlassView(v); g.tag = GLASS_TAG;
        [host insertSubview:g belowSubview:v];
        objc_setAssociatedObject(v, &kG, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGRect f = v.frame;
    CGRect want = CGRectInset(f, -padX, -padY);
    if (circle) { CGFloat d = MAX(want.size.width, want.size.height); want = CGRectMake(CGRectGetMidX(f) - d / 2, CGRectGetMidY(f) - d / 2, d, d); }
    if (!CGRectEqualToRect(g.frame, want)) { g.frame = want; g.layer.cornerRadius = MIN(want.size.width, want.size.height) / 2; }
    g.hidden = v.hidden || v.alpha < 0.05;
}
static void StyleNav(UIWindow *w) {
    UINavigationBar *nb = (UINavigationBar *)Find(w, ^BOOL(UIView *v) { return [v isKindOfClass:[UINavigationBar class]] && !v.hidden && v.window; }, 3000);
    UINavigationController *nc = [nb.delegate isKindOfClass:[UINavigationController class]] ? (UINavigationController *)nb.delegate : nil;
    NSString *top = NSStringFromClass([nc.topViewController class]);
    BOOL chat = ([top containsString:@"Chat"] || [top containsString:@"Transcript"] || [top containsString:@"Conversation"]) && ![top containsString:@"List"];
    if (!nb || !chat) { gNavDebug = [NSString stringWithFormat:@"nav top=%@ (not a chat)", top]; return; }
    nb.tintColor = Ink(nb);
    // no bar background: the buttons float on the chat
    for (UIView *s in nb.subviews) if ([NSStringFromClass([s class]) containsString:@"BarBackground"] && s.alpha > 0) s.alpha = 0;
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *st = [NSMutableArray arrayWithArray:nb.subviews];
    int g = 0;
    CGFloat W = nb.bounds.size.width;
    while (st.count && g++ < 400) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG || v.hidden || v.alpha < 0.05) continue;
        CGRect f = [v convertRect:v.bounds toView:nb];
        NSString *cn = NSStringFromClass([v class]);
        // back button (left) / FaceTime (right)
        if ([v isKindOfClass:[UIControl class]] && f.size.width >= 24 && f.size.width < 160 && f.size.height >= 24 && f.size.height < 70) {
            BOOL left = CGRectGetMidX(f) < W * 0.3, right = CGRectGetMidX(f) > W * 0.7;
            if (left || right) { GlassBehind(v, left ? 10 : 8, 6, right); [found addObject:[NSString stringWithFormat:@"%@%@", left ? @"L:" : @"R:", cn]]; continue; }
        }
        // the name under the picture
        if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length && fabs(CGRectGetMidX(f) - W / 2) < W * 0.2 && f.size.height < 30) {
            UILabel *l = (UILabel *)v;
            l.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
            l.textColor = Ink(nb);
            UIView *holder = l.superview && l.superview.bounds.size.width < W * 0.7 && l.superview.bounds.size.height < 40 ? l.superview : l;
            GlassBehind(holder, 14, 6, NO);
            [found addObject:[NSString stringWithFormat:@"name:%@", l.text]];
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
    gNavDebug = [NSString stringWithFormat:@"nav top=%@ items: %@", top, [found componentsJoinedByString:@" "]];
}

#pragma mark - debug + tick

@interface M26Debug : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation M26Debug
+ (instancetype)shared { static M26Debug *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Debug new]; }); return t; }
- (void)hold:(UILongPressGestureRecognizer *)g { if (g.state == UIGestureRecognizerStateBegan) gShowDebug = !gShowDebug; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
@end

static void Tick(void) {
    UIWindow *w = nil;
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *x in ((UIWindowScene *)sc).windows) if (x.isKeyWindow) w = x;
    }
    if (!w) return;
    static const char kInst = 0;
    if (!objc_getAssociatedObject(w, &kInst)) {
        objc_setAssociatedObject(w, &kInst, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[M26Debug shared] action:@selector(hold:)];
        lp.numberOfTouchesRequired = 3; lp.minimumPressDuration = 0.8; lp.cancelsTouchesInView = NO; lp.delegate = [M26Debug shared];
        [w addGestureRecognizer:lp];
    }
    @try { StyleNav(w); } @catch (__unused id e) {}
    // the entry view lives in the keyboard's window too: style it wherever it is
    UIView *e = gEntry;
    if (!e.window) {
        for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *x in ((UIWindowScene *)sc).windows) {
                UIView *f = Find(x, ^BOOL(UIView *v) { return [NSStringFromClass([v class]) isEqualToString:@"CKMessageEntryView"]; }, 4000);
                if (f) { @try { StyleEntry(f); } @catch (__unused id ex) {} }
            }
        }
    }
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gShowDebug) { [l removeFromSuperview]; return; }
    if (!l) {
        l = [UILabel new]; l.tag = DEBUG_TAG; l.numberOfLines = 0; l.userInteractionEnabled = NO;
        l.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor; l.backgroundColor = [UIColor colorWithRed:0.3 green:0 blue:0.35 alpha:0.85];
        l.layer.cornerRadius = 10; l.clipsToBounds = YES;
        [w addSubview:l];
    }
    l.text = [NSString stringWithFormat:@" Messages26 0.1.0 debug\n %@\n %@", gDebug, gNavDebug];
    CGSize s = [l sizeThatFits:CGSizeMake(w.bounds.size.width - 24, 800)];
    l.frame = CGRectMake(12, w.safeAreaInsets.top + 110, w.bounds.size.width - 24, s.height + 12);
    [w bringSubviewToFront:l];
}

%ctor {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.MobileSMS"]) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        Class E = NSClassFromString(@"CKMessageEntryView");
        if (E) {
            MSHookMessageEx(E, @selector(sizeThatFits:), (IMP)EntrySize, (IMP *)&origEntrySize);
            MSHookMessageEx(E, @selector(layoutSubviews), (IMP)EntryLayout, (IMP *)&origEntryLayout);
        }
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(__unused NSTimer *t) { @try { Tick(); } @catch (__unused id ex) {} }];
    });
}
