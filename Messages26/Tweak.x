// Messages26 0.2.0 - made by nano
// 0.2.0: + and the field work again (they were outside the bar), bigger glass field and +,
//        lower; glass back / FaceTime / name on the real top bar; settings page
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
#define PILL_TAG  0x4D323649

#define DOM CFSTR("com.nano.messages26")
static BOOL gOn = YES, gBarOn = YES, gMenuOn = YES, gTopOn = YES, gPrefDebug = NO;
static BOOL PrefBool(NSDictionary *file, NSString *key, BOOL def) {
    id v = file[key];
    if (!v) { CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)key, DOM); if (cf) v = (__bridge_transfer id)cf; }
    return v ? [v boolValue] : def;
}
static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSDictionary *file = nil; NSDate *best = nil;
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSString *p = [dir stringByAppendingString:@"com.nano.messages26.plist"];
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p];
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        NSDate *m = [[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil][NSFileModificationDate];
        if (!file || (m && best && [m compare:best] == NSOrderedDescending)) { file = d; best = m; }
    }
    gOn = PrefBool(file, @"enabled", YES);
    gBarOn = gOn && PrefBool(file, @"bar", YES);
    gMenuOn = gOn && PrefBool(file, @"menu", YES);
    gTopOn = gOn && PrefBool(file, @"topbar", YES);
    gPrefDebug = PrefBool(file, @"debug", NO);
}
static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{ LoadPrefs(); });
}

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
    if (!gMenuOn) { [(UIButton *)gPhotoBtn sendActionsForControlEvents:UIControlEventTouchUpInside]; return; }   // menu off: + is the camera
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
static void UnstyleEntry(UIView *entry, UIView *field, UIView *container) {
    [[entry viewWithTag:PLUS_TAG] removeFromSuperview];
    [[entry viewWithTag:PILL_TAG] removeFromSuperview];
    if (!CGAffineTransformIsIdentity(container.transform)) container.transform = CGAffineTransformIdentity;
    for (UIView *b in LeftButtons(entry, field)) { b.alpha = 1; b.userInteractionEnabled = YES; }
    UIView *strip = StripOf(entry);
    if (strip) { strip.alpha = 1; strip.userInteractionEnabled = YES; }
}
static void StyleEntry(UIView *entry) {
    UIView *field = FieldOf(entry);
    if (!field) { gDebug = [NSString stringWithFormat:@"entry=%@ no field", NSStringFromClass([entry class])]; return; }
    gEntry = entry;
    // the part of the bar holding the field (moved as one)
    UIView *container = field;
    while (container.superview && container.superview != entry) container = container.superview;
    UIView *strip = StripOf(entry);
    if (strip) {
        gStrip = strip;
        UICollectionView *cv = (UICollectionView *)Find(strip, ^BOOL(UIView *v) { return [v isKindOfClass:[UICollectionView class]]; }, 100);
        if (cv) gStripCV = cv;
    }
    if (!gBarOn) { UnstyleEntry(entry, field, container); return; }
    BOOL dark = IsDark(entry);
    // app strip hidden (its apps live in the + menu); the field row moves down into its place
    CGFloat shift = 0;
    if (strip && gMenuOn) {
        if (strip.alpha > 0) strip.alpha = 0;
        if (strip.userInteractionEnabled) strip.userInteractionEnabled = NO;
        CGRect sf = [strip convertRect:strip.bounds toView:entry];
        CGRect cf0 = CGRectApplyAffineTransform(container.frame, CGAffineTransformInvert(container.transform));
        if (CGRectGetMinY(sf) >= CGRectGetMaxY(cf0) - 4 && container != strip && ![strip isDescendantOfView:container]) shift = MAX(0, sf.size.height - 10);
    } else if (strip) { strip.alpha = 1; strip.userInteractionEnabled = YES; }
    CGAffineTransform t = CGAffineTransformMakeTranslation(0, shift);
    if (!CGAffineTransformEqualToTransform(container.transform, t)) container.transform = t;
    // Instagram-style... no: iOS 26 field look is drawn by our pill behind it
    if (field.backgroundColor && CGColorGetAlpha(field.backgroundColor.CGColor) > 0) field.backgroundColor = UIColor.clearColor;
    if (field.layer.borderWidth > 0) field.layer.borderWidth = 0;
    NSArray *left = LeftButtons(entry, field);
    for (UIView *b in left) { if (b.alpha > 0) b.alpha = 0; if (b.userInteractionEnabled) b.userInteractionEnabled = NO; }
    for (UIView *b in left) {
        NSString *d = [[(UIButton *)b imageForState:UIControlStateNormal] description] ?: @"";
        if ([d containsString:@"camera"] || [NSStringFromClass([b class]) containsString:@"Photo"]) gPhotoBtn = b;
    }
    if (!gPhotoBtn && left.count) gPhotoBtn = left.firstObject;
    CGRect ff = [field convertRect:field.bounds toView:entry];   // includes the move down
    CGFloat padY = 6, D = MAX(46, MIN(ff.size.height + padY * 2, 52));
    CGFloat px = 12;
    CGRect plusF = CGRectMake(px, round(CGRectGetMaxY(ff) + padY - D), D, D);
    CGRect pillF = CGRectMake(px + D + 10, CGRectGetMinY(ff) - padY, CGRectGetMaxX(ff) - (px + D + 10), ff.size.height + padY * 2);
    UIView *pill = [entry viewWithTag:PILL_TAG];
    if (!pill) {
        pill = GlassView(entry); pill.tag = PILL_TAG;
        [entry insertSubview:pill belowSubview:container];
    }
    if ([entry.subviews indexOfObject:pill] > [entry.subviews indexOfObject:container]) [entry insertSubview:pill belowSubview:container];
    if (!CGRectEqualToRect(pill.frame, pillF)) { pill.frame = pillF; pill.layer.cornerRadius = MIN(pillF.size.height / 2, 26); }
    pill.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.17] : [UIColor colorWithWhite:0 alpha:0.08]).CGColor;
    UIButton *plus = (UIButton *)[entry viewWithTag:PLUS_TAG];
    if (!plus) {
        plus = [UIButton buttonWithType:UIButtonTypeCustom];
        plus.tag = PLUS_TAG;
        UIVisualEffectView *g = GlassView(entry);
        g.tag = GLASS_TAG;
        [plus addSubview:g];
        [plus setImage:[UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
        [plus addTarget:[M26Menu shared] action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
        [entry addSubview:plus];
    }
    plus.tintColor = Ink(entry);
    plus.hidden = !gMenuOn && !gPhotoBtn;
    if (!CGRectEqualToRect(plus.frame, plusF) && CGAffineTransformIsIdentity(plus.transform)) plus.frame = plusF;
    UIView *g = [plus viewWithTag:GLASS_TAG];
    g.frame = plus.bounds; g.layer.cornerRadius = D / 2;
    [plus bringSubviewToFront:plus.imageView];
    if (entry.subviews.lastObject != plus) [entry bringSubviewToFront:plus];
    if (entry.clipsToBounds) entry.clipsToBounds = NO;
    gDebug = [NSString stringWithFormat:@"entry=%@ %.0f field=%@ %.0fx%.0f@%.0f shift=%.0f\n box=%@ left=%lu photo=%@\n strip=%@ %.0f cv=%d apps=%lu",
              NSStringFromClass([entry class]), entry.bounds.size.height, NSStringFromClass([field class]), ff.size.width, ff.size.height, ff.origin.y, shift,
              NSStringFromClass([container class]), (unsigned long)left.count, NSStringFromClass([gPhotoBtn class]),
              strip ? NSStringFromClass([strip class]) : @"none", strip.bounds.size.height, gStripCV != nil, (unsigned long)(gStripCV.numberOfSections ? [gStripCV numberOfItemsInSection:0] : 0)];
}

static void (*origEntryLayout)(id, SEL);
static void EntryLayout(UIView *self, SEL _cmd) {
    origEntryLayout(self, _cmd);
    if (!gOn && ![self viewWithTag:PLUS_TAG]) return;
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
static void StyleOneNav(UINavigationBar *nb, NSMutableArray *found) {
    nb.tintColor = Ink(nb);
    // no bar background: the buttons float on the chat
    NSMutableArray *bs = [NSMutableArray arrayWithArray:nb.subviews];
    int gb = 0;
    while (bs.count && gb++ < 40) {
        UIView *s = bs.firstObject; [bs removeObjectAtIndex:0];
        NSString *n = NSStringFromClass([s class]);
        if (([n containsString:@"BarBackground"] || [n containsString:@"Backdrop"]) && s.alpha > 0) s.alpha = 0;
        else if (s.bounds.size.width >= nb.bounds.size.width * 0.95 && s.bounds.size.height <= 1.5) s.hidden = YES;   // hairline
    }
    CGFloat W = nb.bounds.size.width;
    NSMutableArray *st = [NSMutableArray arrayWithArray:nb.subviews];
    int g = 0;
    while (st.count && g++ < 500) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == GLASS_TAG || v.hidden || v.alpha < 0.05) continue;
        CGRect f = [v convertRect:v.bounds toView:nb];
        NSString *cn = NSStringFromClass([v class]);
        if ([v isKindOfClass:[UIControl class]] && f.size.width >= 24 && f.size.width < 170 && f.size.height >= 24 && f.size.height < 80) {
            BOOL left = CGRectGetMidX(f) < W * 0.33, right = CGRectGetMidX(f) > W * 0.67;
            if (left || right) { GlassBehind(v, left ? 12 : 10, 8, right); [found addObject:[NSString stringWithFormat:@"%@%@", left ? @"L:" : @"R:", cn]]; continue; }
        }
        if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length && fabs(CGRectGetMidX(f) - W / 2) < W * 0.25 && f.size.height < 30) {
            UILabel *l = (UILabel *)v;
            UIFont *bold = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
            if (![l.font isEqual:bold]) l.font = bold;
            l.textColor = Ink(nb);
            UIView *holder = l.superview && l.superview.bounds.size.width < W * 0.7 && l.superview.bounds.size.height < 40 ? l.superview : l;
            GlassBehind(holder, 14, 7, NO);
            [found addObject:[NSString stringWithFormat:@"name:%@", l.text]];
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
}
static void StyleNav(UIWindow *w) {
    UIView *e = gEntry;
    BOOL chat = e.window != nil;
    if (!gTopOn || !chat) { gNavDebug = chat ? @"top bar off" : @"nav: no chat open"; return; }
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *st = [NSMutableArray arrayWithObject:w];
    int g = 0, bars = 0;
    while (st.count && g++ < 4000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.hidden || v.alpha < 0.05) continue;
        if ([v isKindOfClass:[UINavigationBar class]]) {
            CGRect f = [v convertRect:v.bounds toView:nil];
            // the chat's bar (on the right side on iPad-style splits)
            if (CGRectGetMaxX(f) >= w.bounds.size.width - 2) { bars++; StyleOneNav((UINavigationBar *)v, found); }
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
    gNavDebug = [NSString stringWithFormat:@"nav bars=%d items: %@", bars, [found componentsJoinedByString:@" "]];
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
    if (!gShowDebug && !gPrefDebug) { [l removeFromSuperview]; return; }
    if (!l) {
        l = [UILabel new]; l.tag = DEBUG_TAG; l.numberOfLines = 0; l.userInteractionEnabled = NO;
        l.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor; l.backgroundColor = [UIColor colorWithRed:0.3 green:0 blue:0.35 alpha:0.85];
        l.layer.cornerRadius = 10; l.clipsToBounds = YES;
        [w addSubview:l];
    }
    l.text = [NSString stringWithFormat:@" Messages26 0.2.0 debug\n %@\n %@", gDebug, gNavDebug];
    CGSize s = [l sizeThatFits:CGSizeMake(w.bounds.size.width - 24, 800)];
    l.frame = CGRectMake(12, w.safeAreaInsets.top + 140, w.bounds.size.width - 24, s.height + 12);
    [w bringSubviewToFront:l];
}

%ctor {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.MobileSMS"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.messages26/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    dispatch_async(dispatch_get_main_queue(), ^{
        Class E = NSClassFromString(@"CKMessageEntryView");
        if (E) {
            MSHookMessageEx(E, @selector(layoutSubviews), (IMP)EntryLayout, (IMP *)&origEntryLayout);
        }
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(__unused NSTimer *t) { @try { Tick(); } @catch (__unused id ex) {} }];
    });
}
