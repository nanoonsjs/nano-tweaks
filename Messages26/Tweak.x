// Messages26 0.7.9 - made by nano
// 0.7.9: taps on the pill go straight to the text box (opens the keyboard); mic / send no longer cut off
// 0.7.8: taps reach the moved text box from inside the bar too; see-through layers no longer catch taps; the mic's own effect stays
// 0.7.7: the message field takes taps again and the mic is back; iOS 26 rim on the pill and +
// 0.7.6: every blur inside the message bar is removed (it covered the text box and blocked taps)
// 0.7.5: the field row's place is worked out inside the bar itself, so it's the same every time
// 0.7.4: back to moving just the field row (no blur), right on the keyboard / just above the home bar;
//        To: capsule matches the message pill, its + sits inside under the X
// 0.7.3: the whole bar moves down (pill touches the keyboard / sits just above the home bar),
//        iOS 26 dark field look, To: + centred in the capsule with a white plus
// 0.7.2: row sits right on the keyboard / just above the home bar, liquid glass pill again,
//        no blur behind it, To: glass stays when you tap the message field
// 0.7.1: the whole row (text + mic) sits right above the keyboard, text lined up for real,
//        Cancel button is an X, glassier To: pill with a white glass +
// 0.7.0: field sits at the bottom (no gap above the keyboard), solid crisp pill, text lined up by the caret;
//        compose: no glass on the title, Cancel is a glass X, glass To: field with a white glass +;
//        list: compose glass no longer cut off
// 0.6.2: "iMessage" lines up inside the pill (measured where the text is drawn)
// 0.6.1: text starts just inside the pill, the mic sits inside its right end
// 0.6.0: + menu and hold-for-Photos work again (the app row is switched on when it's off),
//        the menu remembers its apps; text starts at the pill's left; no leftover name glass;
//        soft blur behind the status bar
// 0.5.0: apps / Camera / hold-for-Photos work after reopening and with the keyboard up
//        (the keyboard goes down and the app row comes back first); the menu fits on
//        screen; glass Edit / compose on the conversation list, no bar background there
// 0.4.0: + grows into the menu (iOS 26 morph); hold and drag apps to reorder them;
//        icons never black out; hold + opens Photos every time; field background
//        lined up; name glass covers the whole name; FaceTime glass morphs open;
//        the back button shows the unread count
// 0.3.0: app icons in the + menu, faster liquid open, smaller glass on the top buttons,
//        names no longer cut off, the conversation list is left alone, hold + for Photos,
//        the field sits at the bottom (no gap where the app row was)
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
static __weak UIView *gEntry, *gStrip, *gPhotoBtn, *gAppsBtn;
static NSArray *gAppsCache;
static NSString *gTextDebug = @"-";
static __weak UIView *gField;
static NSString *gRowDebug = @"-";
static NSHashTable *gRowCtls;   // mic / send, moved down with the text box
static CGFloat gKbTop = 0;   // top of the keyboard on screen (0 = no keyboard)
static BOOL gRowOut = NO;    // our row sits below the bar's own edge   // the last app list seen (names + icons)
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
// Extra-glassy (iOS 26): clear blur, a light sheen on top and a bright rim.
static UIColor *Ink(UIView *v);
__attribute__((unused)) static UIVisualEffectView *ClearGlass(UIView *forTrait) {
    UIVisualEffectView *g = GlassView(forTrait);
    BOOL dark = IsDark(forTrait);
    g.contentView.backgroundColor = dark ? [UIColor colorWithWhite:1 alpha:0.06] : [UIColor colorWithWhite:1 alpha:0.3];
    g.layer.borderWidth = 1;
    g.layer.borderColor = [UIColor colorWithWhite:1 alpha:dark ? 0.28 : 0.6].CGColor;
    CAGradientLayer *sheen = [CAGradientLayer layer];
    sheen.name = @"m26.sheen";
    sheen.colors = @[(id)[UIColor colorWithWhite:1 alpha:dark ? 0.16 : 0.45].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    sheen.startPoint = CGPointMake(0.5, 0); sheen.endPoint = CGPointMake(0.5, 0.6);
    [g.contentView.layer addSublayer:sheen];
    return g;
}
static UIColor *Ink(UIView *v) { return IsDark(v) ? UIColor.whiteColor : UIColor.blackColor; }
static void SheenFit(UIView *g) {
    if (![g isKindOfClass:[UIVisualEffectView class]]) return;
    for (CALayer *l in ((UIVisualEffectView *)g).contentView.layer.sublayers) if ([l.name isEqualToString:@"m26.sheen"]) { [CATransaction begin]; [CATransaction setDisableActions:YES]; l.frame = g.bounds; [CATransaction commit]; }
}


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
static NSMutableDictionary *gIconCache;   // name -> a good icon (the strip doesn't always have one drawn)
static BOOL MostlyEmpty(UIImage *img) {
    CGImageRef cg = img.CGImage;
    if (!cg) return YES;
    const int N = 12; uint8_t px[N * N * 4]; memset(px, 0, sizeof(px));
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(px, N, N, 8, N * 4, cs, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cs);
    if (!ctx) return YES;
    CGContextDrawImage(ctx, CGRectMake(0, 0, N, N), cg);
    CGContextRelease(ctx);
    int lit = 0;
    for (int i = 0; i < N * N; i++) if (px[i * 4 + 3] > 40 && (px[i * 4] + px[i * 4 + 1] + px[i * 4 + 2]) > 60) lit++;
    return lit < N * N / 8;
}
static NSArray *StripApps(void) {
    UICollectionView *cv = gStripCV;
    if (!cv) return @[];
    if (!gIconCache) gIconCache = [NSMutableDictionary dictionary];
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
                CGFloat a = v.bounds.size.width * v.bounds.size.height;
                UIImage *im = [v isKindOfClass:[UIImageView class]] ? ((UIImageView *)v).image : nil;
                if (!im && v.layer.contents && CFGetTypeID((__bridge CFTypeRef)v.layer.contents) == CGImageGetTypeID()) im = [UIImage imageWithCGImage:(__bridge CGImageRef)v.layer.contents];
                if (!im) for (CALayer *l in v.layer.sublayers) if (l.contents && CFGetTypeID((__bridge CFTypeRef)l.contents) == CGImageGetTypeID()) { im = [UIImage imageWithCGImage:(__bridge CGImageRef)l.contents]; a = l.bounds.size.width * l.bounds.size.height; break; }
                if (im && a > area && a > 200) { icon = im; area = a; }
                if (!name.length && [v isKindOfClass:[UILabel class]]) name = ((UILabel *)v).text;
                if (!name.length && v.accessibilityLabel.length) name = v.accessibilityLabel;
                [st addObjectsFromArray:v.subviews];
            }
            if (!name.length) name = [NSString stringWithFormat:@"App %ld", (long)i + 1];
            if (!icon && cell.bounds.size.width > 10) {
                UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:cell.bounds.size];
                icon = [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [cell.layer renderInContext:c.CGContext]; }];
            }
            // a blacked-out picture (not drawn yet): use the last good one
            if (icon && !MostlyEmpty(icon)) gIconCache[name] = icon;
            else icon = gIconCache[name];
            [out addObject:@{@"name": name, @"icon": icon ?: [UIImage systemImageNamed:@"app.fill"], @"ip": ip}];
        }
    }
    return out;
}
static void OpenStripApp(NSIndexPath *ip) {
    UICollectionView *cv = gStripCV;
    if (!cv || !ip) return;
    for (NSIndexPath *p in cv.indexPathsForSelectedItems) {
        [cv deselectItemAtIndexPath:p animated:NO];
        if ([cv.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)]) [cv.delegate collectionView:cv didDeselectItemAtIndexPath:p];
    }
    [cv selectItemAtIndexPath:ip animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    if ([cv.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) [cv.delegate collectionView:cv didSelectItemAtIndexPath:ip];
}
static void StyleEntry(UIView *entry);
// The app row is only there with the keyboard down: put it away, wait for the
// row to come back, then do the thing.
static void WithStrip(void (^then)(void)) {
    UICollectionView *cv = gStripCV;
    UIView *pb = gPhotoBtn;
    if (cv.window && pb.window && cv.numberOfSections) { then(); return; }
    UIView *e = gEntry;
    [e.window endEditing:YES];
    __block int tries = 0;
    __block BOOL toggled = NO;
    [NSTimer scheduledTimerWithTimeInterval:0.08 repeats:YES block:^(NSTimer *t) {
        UIView *e2 = gEntry;
        if (e2) { @try { StyleEntry(e2); } @catch (__unused id ex) {} }
        UICollectionView *c2 = gStripCV;
        if (c2.window && [c2 numberOfSections]) { [t invalidate]; then(); return; }
        // still no app row after the keyboard went down: it's switched off; switch it on
        if (++tries == 5 && !toggled) { toggled = YES; [(UIButton *)gAppsBtn sendActionsForControlEvents:UIControlEventTouchUpInside]; }
        if (tries > 24) { [t invalidate]; then(); }
    }];
}
static void OpenStripAppNamed(NSString *name) {
    WithStrip(^{
        for (NSDictionary *a in StripApps()) if ([a[@"name"] isEqualToString:name]) { OpenStripApp(a[@"ip"]); return; }
    });
}
static void OpenCamera(void) {
    WithStrip(^{ [(UIButton *)gPhotoBtn sendActionsForControlEvents:UIControlEventTouchUpInside]; });
}
static NSDictionary *PhotosApp(void) {
    NSArray *apps = StripApps();
    for (NSDictionary *a in apps) if ([[a[@"name"] lowercaseString] isEqualToString:@"photos"]) return a;
    for (NSDictionary *a in apps) if ([[a[@"name"] lowercaseString] containsString:@"photos"] && ![[a[@"name"] lowercaseString] containsString:@"google"]) return a;
    return nil;
}
// The menu's order (names), changed by holding and dragging a row.
static NSArray *SavedOrder(void) { return [[NSUserDefaults standardUserDefaults] arrayForKey:@"m26.order"] ?: @[]; }
static NSArray *MenuItems(void) {
    NSMutableArray *items = [NSMutableArray array];
    NSArray *apps = StripApps();
    if (apps.count) gAppsCache = apps; else apps = gAppsCache ?: @[];
    NSDictionary *photos = nil;
    for (NSDictionary *a in apps) if ([[a[@"name"] lowercaseString] isEqualToString:@"photos"]) photos = a;
    if (photos) [items addObject:photos];
    [items addObject:@{@"name": @"Camera", @"icon": [UIImage systemImageNamed:@"camera.fill"], @"camera": @YES}];
    for (NSDictionary *a in apps) if (a != photos && ![a[@"name"] isEqual:photos[@"name"]] && ![[a[@"name"] lowercaseString] containsString:@"app store"] && ![[a[@"name"] lowercaseString] isEqualToString:@"store"]) [items addObject:a];
    NSArray *order = SavedOrder();
    [items sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSUInteger ia = [order indexOfObject:a[@"name"]], ib = [order indexOfObject:b[@"name"]];
        if (ia == ib) return NSOrderedSame;
        return ia < ib ? NSOrderedAscending : NSOrderedDescending;
    }];
    return items;
}

#define ROW_H 62.0
@implementation M26Menu {
    UIView *_dim, *_panel; UIVisualEffectView *_glass;
    UIScrollView *_sv;
    __weak UIButton *_plus;
    NSMutableArray *_items, *_rows;
    UIView *_lifted; NSInteger _liftFrom; CGFloat _liftDY;
}
+ (instancetype)shared { static M26Menu *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Menu new]; }); return t; }
- (UIButton *)rowFor:(NSDictionary *)it width:(CGFloat)W ink:(UIColor *)ink {
    UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
    row.bounds = CGRectMake(0, 0, W, ROW_H);
    row.layer.cornerRadius = 20; row.layer.cornerCurve = kCACornerCurveContinuous;
    [row addTarget:self action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
    [row addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [row addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchDragExit | UIControlEventTouchCancel];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    lp.minimumPressDuration = 0.35;
    [row addGestureRecognizer:lp];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(22, 9, 44, 44)];
    iv.image = [it[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]; iv.contentMode = UIViewContentModeScaleAspectFill;
    iv.layer.cornerRadius = 22; iv.clipsToBounds = YES;
    if (it[@"camera"]) { iv.contentMode = UIViewContentModeCenter; iv.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
        iv.image = [[UIImage systemImageNamed:@"camera.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold]] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal]; }
    iv.userInteractionEnabled = NO;
    [row addSubview:iv];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(84, 0, W - 100, ROW_H)];
    l.text = it[@"name"]; l.font = [UIFont systemFontOfSize:21 weight:UIFontWeightRegular]; l.textColor = ink;
    l.userInteractionEnabled = NO;
    [row addSubview:l];
    return row;
}
- (void)layoutRows:(BOOL)animated except:(UIView *)skip {
    void (^go)(void) = ^{
        for (NSUInteger i = 0; i < self->_rows.count; i++) {
            UIView *r = self->_rows[i];
            if (r == skip) continue;
            r.center = CGPointMake(r.bounds.size.width / 2, 12 + i * ROW_H + ROW_H / 2);
        }
    };
    if (animated) [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.2 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:go completion:nil];
    else go();
}
- (void)open:(UIButton *)plus {
    UIWindow *w = plus.window;
    if (!w || _panel.superview) return;
    if (!gMenuOn) { OpenCamera(); return; }   // menu off: + is the camera
    // keyboard up: put it away first, then grow the menu from where + lands
    static BOOL waiting;
    if (!gStripCV.window && !waiting) {
        waiting = YES;
        __weak UIButton *wp = plus;
        WithStrip(^{ waiting = NO; UIButton *p2 = wp; if (p2.window) [self open:p2]; });
        return;
    }
    _plus = plus;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    [w endEditing:YES];
    _items = [MenuItems() mutableCopy];

    _dim = [[UIView alloc] initWithFrame:w.bounds];
    _dim.backgroundColor = UIColor.clearColor;
    [_dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    [w addSubview:_dim];

    CGRect pf = [plus convertRect:plus.bounds toView:w];
    CGFloat W = MIN(w.bounds.size.width - 40, 330);
    CGFloat H = MIN(MIN(_items.count * ROW_H + 24, w.bounds.size.height * 0.62), CGRectGetMinY(pf) - 12 - w.safeAreaInsets.top - 8);
    CGRect full = CGRectMake(CGRectGetMinX(pf), CGRectGetMinY(pf) - 12 - H, W, H);
    // The panel IS the "+" glass growing: it starts as the circle and stretches
    // up and right into the menu (iOS 26), its corners easing from round to soft.
    _panel = [[UIView alloc] initWithFrame:pf];
    _panel.tag = MENU_TAG;
    _panel.layer.shadowColor = UIColor.blackColor.CGColor; _panel.layer.shadowOpacity = 0.35; _panel.layer.shadowRadius = 30; _panel.layer.shadowOffset = CGSizeMake(0, 12);
    _glass = GlassView(plus);
    _glass.frame = _panel.bounds; _glass.layer.cornerRadius = pf.size.width / 2; _glass.userInteractionEnabled = YES;
    _glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_panel addSubview:_glass];
    _sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, W, H)];
    _sv.contentSize = CGSizeMake(W, _items.count * ROW_H + 24);
    _sv.showsVerticalScrollIndicator = NO;
    _sv.alpha = 0;
    [_glass.contentView addSubview:_sv];
    _rows = [NSMutableArray array];
    UIColor *ink = Ink(plus);
    for (NSDictionary *it in _items) { UIButton *r = [self rowFor:it width:W ink:ink]; [_sv addSubview:r]; [_rows addObject:r]; }
    [self layoutRows:NO except:nil];
    [w addSubview:_panel];
    plus.alpha = 0;   // the glass leaves the button
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.6 options:0 animations:^{
        self->_panel.frame = full;
        self->_dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
    } completion:nil];
    CABasicAnimation *cr = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cr.fromValue = @(pf.size.width / 2); cr.toValue = @34; cr.duration = 0.3;
    cr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    _glass.layer.cornerRadius = 34;
    [_glass.layer addAnimation:cr forKey:@"cr"];
    [UIView animateWithDuration:0.2 delay:0.1 options:0 animations:^{ self->_sv.alpha = 1; } completion:nil];
}
- (void)down:(UIButton *)b { [UIView animateWithDuration:0.15 animations:^{ b.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.18]; b.transform = CGAffineTransformMakeScale(0.97, 0.97); }]; }
- (void)up:(UIButton *)b { [UIView animateWithDuration:0.25 animations:^{ b.backgroundColor = UIColor.clearColor; b.transform = CGAffineTransformIdentity; }]; }
// Hold a row, move it up or down, let go: the new order is kept.
- (void)drag:(UILongPressGestureRecognizer *)g {
    UIView *row = g.view;
    CGFloat y = [g locationInView:_sv].y;
    if (g.state == UIGestureRecognizerStateBegan) {
        _lifted = row; _liftFrom = [_rows indexOfObject:row]; _liftDY = row.center.y - y;
        _sv.scrollEnabled = NO;
        [_sv bringSubviewToFront:row];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            row.transform = CGAffineTransformMakeScale(1.04, 1.04);
            row.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.22];
        } completion:nil];
        return;
    }
    if (row != _lifted) return;
    if (g.state == UIGestureRecognizerStateChanged) {
        CGFloat cy = MIN(MAX(y + _liftDY, 12 + ROW_H / 2), 12 + (_rows.count - 0.5) * ROW_H);
        row.center = CGPointMake(row.center.x, cy);
        NSInteger to = MAX(0, MIN((NSInteger)_rows.count - 1, (NSInteger)floor((cy - 12) / ROW_H)));
        NSInteger from = [_rows indexOfObject:row];
        if (to != from) {
            [_rows removeObjectAtIndex:from]; [_rows insertObject:row atIndex:to];
            id it = _items[from]; [_items removeObjectAtIndex:from]; [_items insertObject:it atIndex:to];
            [[UISelectionFeedbackGenerator new] selectionChanged];
            [self layoutRows:YES except:row];
        }
        return;
    }
    _lifted = nil; _sv.scrollEnabled = YES;
    [self layoutRows:YES except:nil];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        row.transform = CGAffineTransformIdentity; row.backgroundColor = UIColor.clearColor;
    } completion:nil];
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *it in _items) [names addObject:it[@"name"]];
    [[NSUserDefaults standardUserDefaults] setObject:names forKey:@"m26.order"];
}
- (void)closeThen:(void (^)(void))then {
    UIView *panel = _panel, *dim = _dim; UIButton *plus = _plus; UIView *glass = _glass; UIView *sv = _sv;
    _panel = nil; _dim = nil;
    if (!panel) { plus.alpha = 1; if (then) then(); return; }
    CGRect pf = [plus convertRect:plus.bounds toView:panel.superview];
    [UIView animateWithDuration:0.12 animations:^{ sv.alpha = 0; }];
    CABasicAnimation *cr = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cr.fromValue = @34; cr.toValue = @(pf.size.width / 2); cr.duration = 0.28;
    glass.layer.cornerRadius = pf.size.width / 2;
    [glass.layer addAnimation:cr forKey:@"cr"];
    [UIView animateWithDuration:0.34 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.3 options:0 animations:^{
        panel.frame = pf;
        dim.backgroundColor = UIColor.clearColor;
    } completion:^(__unused BOOL d) {
        plus.alpha = 1;
        [panel removeFromSuperview]; [dim removeFromSuperview];
        CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        k.values = @[@1, @1.12, @0.96, @1]; k.duration = 0.35;
        [plus.layer addAnimation:k forKey:@"m26.swallow"];
    }];
    if (then) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), then);
}
- (void)close { [self closeThen:nil]; }
- (void)pick:(UIButton *)b {
    NSUInteger i = [_rows indexOfObject:b];
    NSDictionary *it = i < _items.count ? _items[i] : nil;
    [[UISelectionFeedbackGenerator new] selectionChanged];
    [self closeThen:^{
        if (it[@"camera"]) OpenCamera();
        else if (it[@"name"]) OpenStripAppNamed(it[@"name"]);
    }];
}
- (void)hold:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan || !gMenuOn) return;
    UIView *plus = g.view;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@1, @1.2, @0.92, @1]; k.duration = 0.35;
    [plus.layer addAnimation:k forKey:@"m26.hold"];
    WithStrip(^{ NSDictionary *p = PhotosApp(); if (p) OpenStripApp(p[@"ip"]); });
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
// iOS 26 field edge: a thin rim that's bright along the top and fades toward the
// bottom, plus a faint sheen inside the top half.
static void RimFit(UIView *v, BOOL dark) {
    CGFloat r = v.layer.cornerRadius;
    CAGradientLayer *rim = nil;
    for (CALayer *l in v.layer.sublayers) if ([l.name isEqualToString:@"m26.rim"]) rim = (CAGradientLayer *)l;
    if (!rim) {
        rim = [CAGradientLayer layer]; rim.name = @"m26.rim";
        rim.startPoint = CGPointMake(0.5, 0); rim.endPoint = CGPointMake(0.5, 1);
        CAShapeLayer *m = [CAShapeLayer layer]; m.fillColor = UIColor.clearColor.CGColor; m.strokeColor = UIColor.blackColor.CGColor; m.lineWidth = 1.2;
        rim.mask = m;
        [v.layer addSublayer:rim];
    }
    rim.colors = @[(id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.32 : 0.14].CGColor, (id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.10 : 0.06].CGColor, (id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.18 : 0.10].CGColor];
    rim.locations = @[@0, @0.55, @1];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    rim.frame = v.bounds;
    ((CAShapeLayer *)rim.mask).path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(v.bounds, 0.6, 0.6) cornerRadius:MAX(0, r - 0.6)].CGPath;
    [CATransaction commit];
}
static void StyleEntry(UIView *entry) {
    UIView *field = FieldOf(entry);
    if (!field) { gDebug = [NSString stringWithFormat:@"entry=%@ no field", NSStringFromClass([entry class])]; return; }
    gEntry = entry; gField = field;
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
        (void)sf; (void)cf0;
        container = nil;
        // pieces we moved in older builds: back in place
        NSMutableArray *rs = [NSMutableArray arrayWithArray:entry.subviews]; int gr = 0;
        while (rs.count && gr++ < 300) { UIView *v = rs.lastObject; [rs removeLastObject];
            if (v.tag != PLUS_TAG && v.tag != PILL_TAG && v != field && ![v isKindOfClass:[UIControl class]] && !CGAffineTransformIsIdentity(v.transform)) v.transform = CGAffineTransformIdentity;
            [rs addObjectsFromArray:v.subviews]; }
        if (!CGAffineTransformIsIdentity(entry.transform)) entry.transform = CGAffineTransformIdentity;
        // The field row (text box + mic / send) moves down: onto the keyboard when it's
        // up (where the hidden app row was), else to just above the home bar.
        UIWindow *ew = entry.window;
        NSMutableArray *row = [NSMutableArray arrayWithObject:field];
        for (UIView *v in @[field]) v.transform = CGAffineTransformIdentity;
        CGRect fu = [field convertRect:field.bounds toView:entry];
        NSMutableArray *cs = [NSMutableArray arrayWithArray:entry.subviews]; int gc = 0;
        while (cs.count && gc++ < 300) { UIView *v = cs.lastObject; [cs removeLastObject];
            if (v == field || v.tag == PLUS_TAG || v.tag == PILL_TAG || v == strip || [v isDescendantOfView:field]) continue;
            if ([v isKindOfClass:[UIControl class]] && v.alpha > 0.05 && !v.hidden && v.bounds.size.width < 60) {
                CGRect vf = [v.superview convertRect:CGRectMake(v.center.x - v.bounds.size.width / 2, v.center.y - v.bounds.size.height / 2, v.bounds.size.width, v.bounds.size.height) toView:entry];
                if (CGRectGetMidX(vf) > CGRectGetMidX(fu) && fabs(CGRectGetMidY(vf) - CGRectGetMidY(fu)) < 26) { [row addObject:v]; continue; }
            }
            [cs addObjectsFromArray:v.subviews]; }
        CGRect ef = [entry convertRect:entry.bounds toView:nil];
        BOOL kbUp = CGRectGetMaxY(ef) < ew.bounds.size.height - 120;   // the bar rides on the keyboard
        // All in the bar's own space (screen math gave wrong numbers while the bar
        // moves between windows): the text box's bottom goes to a fixed place.
        CGFloat wantBottom = kbUp ? entry.bounds.size.height - 10 : entry.bounds.size.height - 43;
        shift = wantBottom - CGRectGetMaxY(fu);
        if (fabs(shift) > 200) shift = 0;
        gKbTop = kbUp ? CGRectGetMaxY(ef) : 0;
        CGAffineTransform rt = CGAffineTransformMakeTranslation(0, shift);
        for (UIView *v in row) if (!CGAffineTransformEqualToTransform(v.transform, rt)) v.transform = rt;
        // their boxes must not cut them off (the mic was drawn outside its box, so it vanished)
        if (!gRowCtls) gRowCtls = [NSHashTable weakObjectsHashTable];
        [gRowCtls removeAllObjects];
        for (UIView *v in row) {
            if (v != field) [gRowCtls addObject:v];
            for (UIView *p = v.superview; p && p != entry; p = p.superview) if (p.clipsToBounds) p.clipsToBounds = NO;
        }
        NSMutableArray *rn = [NSMutableArray array];
        for (UIView *v in row) if (v != field) [rn addObject:[NSString stringWithFormat:@"%@ a=%.1f h=%d", NSStringFromClass([v class]), v.alpha, v.hidden]];
        gRowDebug = rn.count ? [rn componentsJoinedByString:@", "] : @"(no mic found)";
        gRowOut = NO;
    } else if (strip) { strip.alpha = 1; strip.userInteractionEnabled = YES; }
    if (container) { CGAffineTransform t = CGAffineTransformMakeTranslation(0, shift); if (!CGAffineTransformEqualToTransform(container.transform, t)) container.transform = t; }
    // Instagram-style... no: iOS 26 field look is drawn by our pill behind it
    {
        UIView *topc = field; while (topc.superview && topc.superview != entry) topc = topc.superview;
        NSMutableArray *cs = [NSMutableArray arrayWithObject:topc];
        int gc = 0;
        while (cs.count && gc++ < 120) {
            UIView *v = cs.lastObject; [cs removeLastObject];
            if (v == strip || v.tag == PLUS_TAG) continue;
            if (v.bounds.size.width > 140 && ![v isKindOfClass:[UITextView class]]) {
                if (v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0) v.backgroundColor = UIColor.clearColor;
                if (v.layer.borderWidth > 0) v.layer.borderWidth = 0;
                for (CALayer *l in v.layer.sublayers) if ([l isKindOfClass:[CAShapeLayer class]] && l.bounds.size.width > 140) { ((CAShapeLayer *)l).strokeColor = UIColor.clearColor.CGColor; ((CAShapeLayer *)l).fillColor = UIColor.clearColor.CGColor; }
            }
            [cs addObjectsFromArray:v.subviews];
        }
    }
    NSArray *left = LeftButtons(entry, field);
    for (UIView *b in left) { if (b.alpha > 0) b.alpha = 0; if (b.userInteractionEnabled) b.userInteractionEnabled = NO; }
    // left to right: camera, then App Store (switches the app row on / off)
    if (left.count >= 2) {
        NSArray *byX = [left sortedArrayUsingComparator:^NSComparisonResult(UIView *a, UIView *b) { return [a convertPoint:CGPointZero toView:nil].x < [b convertPoint:CGPointZero toView:nil].x ? NSOrderedAscending : NSOrderedDescending; }];
        gPhotoBtn = byX[0]; gAppsBtn = byX[1];
    }
    UIView *textV = Find(field, ^BOOL(UIView *v) { return [v isKindOfClass:[UITextView class]]; }, 100) ?: field;
    {
        // where the text is actually drawn: the caret's start; adjust and re-measure
        CGFloat want = 12 + 46 + 10 + 16, textX = 0;
        for (int it = 0; it < 4; it++) {
            textX = CGRectGetMinX([textV convertRect:textV.bounds toView:entry]);
            if ([textV isKindOfClass:[UITextView class]]) {
                UITextView *tv = (UITextView *)textV;
                CGRect caret = [tv caretRectForPosition:tv.beginningOfDocument];
                if (!CGRectIsNull(caret) && !CGRectIsInfinite(caret)) textX = CGRectGetMinX([tv convertRect:caret toView:entry]);
            }
            CGFloat dx = want - textX;
            if (fabs(dx) <= 1 || fabs(dx) > 160 || !field.superview) break;
            CGRect bnd = field.bounds; bnd.size.width -= dx; field.bounds = bnd;   // right edge stays
            CGPoint c = field.center; c.x += dx / 2; field.center = c;
            [field setNeedsLayout]; [field layoutIfNeeded];
        }
        gTextDebug = [NSString stringWithFormat:@"textX=%.0f want=%.0f\n row: %@", textX, want, gRowDebug];
    }
    CGRect ff = [field convertRect:field.bounds toView:entry];   // includes the move down
    CGFloat padY = 6, D = MAX(46, MIN(ff.size.height + padY * 2, 52));
    CGFloat px = 12;
    CGRect plusF = CGRectMake(px, round(CGRectGetMaxY(ff) + padY - D), D, D);
    // the pill ends just past the mic / send button (whatever is right of the text)
    CGFloat right = CGRectGetMaxX(ff);
    {
        CGRect tr = [textV convertRect:textV.bounds toView:entry];
        NSMutableArray *cs = [NSMutableArray arrayWithArray:entry.subviews];
        int gc = 0;
        while (cs.count && gc++ < 200) {
            UIView *v = cs.lastObject; [cs removeLastObject];
            if (v.tag == PLUS_TAG || v.tag == PILL_TAG || v.hidden || v.alpha < 0.05 || v == strip || [v isDescendantOfView:strip ?: v]) { if (v != strip && !strip) {} if (v == strip) continue; }
            CGRect f = [v convertRect:v.bounds toView:entry];
            if ([v isKindOfClass:[UIControl class]] && CGRectGetMinX(f) >= CGRectGetMaxX(tr) - 6 && f.size.width < 60 && fabs(CGRectGetMidY(f) - CGRectGetMidY(tr)) < 30) right = MAX(right, CGRectGetMaxX(f));
            [cs addObjectsFromArray:v.subviews];
        }
    }
    right = MIN(right + 8, entry.bounds.size.width - 8);
    CGRect pillF = CGRectMake(px + D + 10, CGRectGetMinY(ff) - padY, right - (px + D + 10), ff.size.height + padY * 2);
    UIView *pill = [entry viewWithTag:PILL_TAG];
    UIView *pHost = field.superview ?: entry;
    if (!pill || pill.superview != pHost) {
        [pill removeFromSuperview];
        pill = [UIView new]; pill.tag = PILL_TAG; pill.userInteractionEnabled = NO;
        pill.layer.cornerCurve = kCACornerCurveContinuous; pill.layer.borderWidth = 1;
        CAGradientLayer *hl = [CAGradientLayer layer]; hl.name = @"m26.sheen";
        hl.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.07].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        hl.startPoint = CGPointMake(0.5, 0); hl.endPoint = CGPointMake(0.5, 0.5);
        [pill.layer addSublayer:hl];
        [pHost insertSubview:pill belowSubview:field];
    }
    if ([pHost.subviews indexOfObject:pill] > [pHost.subviews indexOfObject:field]) [pHost insertSubview:pill belowSubview:field];
    pill.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:1] : [UIColor colorWithWhite:0.96 alpha:1];
    pill.layer.borderColor = UIColor.clearColor.CGColor;
    CGRect pillIn = [entry convertRect:pillF toView:pHost];
    // in the field's space the move down is already in field's transform: follow it
    pillIn = CGRectOffset(pillIn, 0, 0);
    if (!CGRectEqualToRect(pill.frame, pillIn)) {
        pill.frame = pillIn; pill.layer.cornerRadius = MIN(pillIn.size.height / 2, 26);
        RimFit(pill, dark);
        for (CALayer *l in pill.layer.sublayers) if ([l.name isEqualToString:@"m26.sheen"]) { [CATransaction begin]; [CATransaction setDisableActions:YES]; l.frame = pill.bounds; l.cornerRadius = pill.layer.cornerRadius; [CATransaction commit]; }
    }
    // no blur anywhere in the bar (it covered the text box and took its taps)
    {
        NSMutableArray *bs = [NSMutableArray arrayWithObject:entry]; int gb = 0;
        while (bs.count && gb++ < 600) {
            UIView *v = bs.lastObject; [bs removeLastObject];
            if (v.tag == PLUS_TAG || v.tag == PILL_TAG || v.tag == MENU_TAG || v == strip) continue;
            NSString *n = NSStringFromClass([v class]);
            if (v != entry && [v isKindOfClass:[UIVisualEffectView class]]) {
                UIVisualEffectView *ev = (UIVisualEffectView *)v;
                if (ev.hidden) ev.hidden = NO;   // (0.7.6 hid these, with the mic inside)
                if ([ev.effect isKindOfClass:[UIBlurEffect class]]) ev.effect = nil;   // vibrancy (the mic's look) stays
                ev.backgroundColor = UIColor.clearColor;
                // a see-through layer on top of the text box must not take its taps
                BOOL hasCtl = Find(ev, ^BOOL(UIView *x) { return [x isKindOfClass:[UIControl class]]; }, 60) != nil;
                if (!hasCtl && ev.userInteractionEnabled) ev.userInteractionEnabled = NO;
                [bs addObject:ev.contentView];
                continue;
            }
            if (v != entry && ([n containsString:@"Backdrop"] || [n containsString:@"BlurView"]) && !v.subviews.count) {
                if (!v.hidden) v.hidden = YES;
                continue;
            }
            [bs addObjectsFromArray:v.subviews];
        }
    }
    // no blurred bar behind the field row
    for (UIView *v in entry.subviews) {
        if (v == strip || v.tag == PLUS_TAG || v.tag == PILL_TAG || [field isDescendantOfView:v] || [strip isDescendantOfView:v]) continue;
        NSString *n = NSStringFromClass([v class]);
        if (v.bounds.size.width >= entry.bounds.size.width * 0.95 && ([v isKindOfClass:[UIVisualEffectView class]] || [n containsString:@"Background"] || [n containsString:@"Backdrop"] || [n containsString:@"Blur"]) && v.alpha > 0) v.alpha = 0;
    }
    if (entry.backgroundColor && CGColorGetAlpha(entry.backgroundColor.CGColor) > 0) entry.backgroundColor = UIColor.clearColor;
    for (UIView *p = entry.superview; p && ![p isKindOfClass:[UIWindow class]]; p = p.superview) {
        if (p.clipsToBounds && gRowOut) p.clipsToBounds = NO;
        if (p.bounds.size.width >= entry.bounds.size.width * 0.95 && p.bounds.size.height < 220) {
            for (UIView *v in p.subviews) if (!([entry isDescendantOfView:v]) && ([v isKindOfClass:[UIVisualEffectView class]] || [NSStringFromClass([v class]) containsString:@"Backdrop"]) && v.bounds.size.width >= entry.bounds.size.width * 0.95 && v.alpha > 0) v.alpha = 0;
        }
    }
    pill.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.17] : [UIColor colorWithWhite:0 alpha:0.08]).CGColor;
    UIButton *plus = (UIButton *)[entry viewWithTag:PLUS_TAG];
    if (!plus) {
        plus = [UIButton buttonWithType:UIButtonTypeCustom];
        plus.tag = PLUS_TAG;
        UIView *g = [UIView new]; g.userInteractionEnabled = NO;
        g.tag = GLASS_TAG; g.layer.borderWidth = 1;
        [plus addSubview:g];
        [plus setImage:[UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
        [plus addTarget:[M26Menu shared] action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[M26Menu shared] action:@selector(hold:)];
        lp.minimumPressDuration = 0.4;
        [plus addGestureRecognizer:lp];
        [entry addSubview:plus];
    }
    plus.tintColor = Ink(entry);
    plus.hidden = !gMenuOn && !gPhotoBtn;
    if (!CGRectEqualToRect(plus.frame, plusF) && CGAffineTransformIsIdentity(plus.transform)) plus.frame = plusF;
    UIView *g = [plus viewWithTag:GLASS_TAG];
    g.frame = plus.bounds; g.layer.cornerRadius = D / 2;
    g.backgroundColor = pill.backgroundColor; g.layer.borderColor = pill.layer.borderColor;
    if (!CGSizeEqualToSize([objc_getAssociatedObject(g, "m26rim") CGSizeValue], g.bounds.size)) { objc_setAssociatedObject(g, "m26rim", [NSValue valueWithCGSize:g.bounds.size], OBJC_ASSOCIATION_RETAIN_NONATOMIC); RimFit(g, dark); }
    [plus bringSubviewToFront:plus.imageView];
    if (entry.subviews.lastObject != plus) [entry bringSubviewToFront:plus];
    if (entry.clipsToBounds) entry.clipsToBounds = NO;
    gDebug = [NSString stringWithFormat:@"%@ kb=%.0f out=%d\n entry=%@ %.0f field=%@ %.0fx%.0f@%.0f shift=%.0f\n box=%@ left=%lu photo=%@\n strip=%@ %.0f cv=%d apps=%lu",
              gTextDebug, gKbTop, gRowOut, NSStringFromClass([entry class]), entry.bounds.size.height, NSStringFromClass([field class]), ff.size.width, ff.size.height, ff.origin.y, shift,
              NSStringFromClass([container class]), (unsigned long)left.count, NSStringFromClass([gPhotoBtn class]),
              strip ? NSStringFromClass([strip class]) : @"none", strip.bounds.size.height, gStripCV != nil, (unsigned long)(gStripCV.numberOfSections ? [gStripCV numberOfItemsInSection:0] : 0)];
}

static UIView *(*origEntryHit)(id, SEL, CGPoint, UIEvent *);
static UIView *EntryHit(UIView *self, SEL _cmd, CGPoint p, UIEvent *e) {
    if (gBarOn && !self.hidden && self.alpha > 0.05) {
        UIView *plus = [self viewWithTag:PLUS_TAG];
        if (plus && !plus.hidden && CGRectContainsPoint(CGRectInset([plus convertRect:plus.bounds toView:self], -4, -4), p)) return plus;
        for (UIView *c in [gRowCtls allObjects])
            if (c.window && !c.hidden && c.alpha > 0.05 && c.userInteractionEnabled && [c isDescendantOfView:self] && CGRectContainsPoint(CGRectInset([c convertRect:c.bounds toView:self], -4, -4), p)) return c;
        UIView *f = gField;
        if (f.window && [f isDescendantOfView:self]) {
            UIView *pill = [f.superview viewWithTag:PILL_TAG];
            CGRect area = pill ? [pill convertRect:pill.bounds toView:self] : [f convertRect:f.bounds toView:self];
            if (CGRectContainsPoint(area, p)) {
                CGPoint q = [self convertPoint:p toView:f];
                q.x = MIN(MAX(q.x, 1), f.bounds.size.width - 1); q.y = MIN(MAX(q.y, 1), f.bounds.size.height - 1);
                UIView *h = [f hitTest:q withEvent:e];
                return h ?: f;
            }
        }
    }
    return origEntryHit(self, _cmd, p, e);
}
static void (*origEntryLayout)(id, SEL);
static void EntryLayout(UIView *self, SEL _cmd) {
    origEntryLayout(self, _cmd);
    if (!gOn && ![self viewWithTag:PLUS_TAG]) return;
    @try { StyleEntry(self); } @catch (__unused id e) {}
}

#pragma mark - conversation top bar

static NSHashTable *gStyled;   // nav things we put glass behind / changed
static char kGlassKey;
// What a view actually draws (its icons / text), not its whole tap area.
static CGRect DrawnRect(UIView *v) {
    CGRect u = CGRectNull;
    NSMutableArray *st = [NSMutableArray arrayWithObject:v];
    int g = 0;
    while (st.count && g++ < 40) {
        UIView *x = st.lastObject; [st removeLastObject];
        if (x.hidden || x.alpha < 0.05 || x.tag == GLASS_TAG) continue;
        if (([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image) || [x isKindOfClass:[UILabel class]]) {
            CGRect f = [x convertRect:x.bounds toView:v.superview];
            if ([x isKindOfClass:[UILabel class]]) {
                CGSize ts = [(UILabel *)x sizeThatFits:CGSizeMake(1000, 100)];
                f = CGRectMake(CGRectGetMidX(f) - MIN(ts.width, f.size.width) / 2, CGRectGetMidY(f) - ts.height / 2, MIN(ts.width, f.size.width), ts.height);
            }
            u = CGRectUnion(u, f);
            continue;
        }
        [st addObjectsFromArray:x.subviews];
    }
    return CGRectIsNull(u) ? v.frame : u;
}
static void GlassBehind(UIView *v, CGFloat padX, CGFloat padY, BOOL circle) {
    UIView *host = v.superview;
    if (!host) return;
    if (!gStyled) gStyled = [NSHashTable weakObjectsHashTable];
    [gStyled addObject:v];
    UIVisualEffectView *g = objc_getAssociatedObject(v, &kGlassKey);
    if (!g || g.superview != host) {
        [g removeFromSuperview];
        g = GlassView(v); g.tag = GLASS_TAG;
        [host insertSubview:g belowSubview:v];
        objc_setAssociatedObject(v, &kGlassKey, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGRect f = DrawnRect(v);
    CGRect want = CGRectInset(f, -padX, -padY);
    if (circle) { CGFloat d = MAX(want.size.width, want.size.height); want = CGRectMake(CGRectGetMidX(f) - d / 2, CGRectGetMidY(f) - d / 2, d, d); }
    want = CGRectIntegral(want);
    if (g.layer.animationKeys.count || g.alpha < 1) return;
    if (!CGRectEqualToRect(g.frame, want)) { g.frame = want; g.layer.cornerRadius = MIN(want.size.width, want.size.height) / 2; }
    g.hidden = v.hidden || v.alpha < 0.05;
    for (UIView *p = host; p && ![p isKindOfClass:[UIWindow class]]; p = p.superview) { if (p.clipsToBounds) p.clipsToBounds = NO; if ([p isKindOfClass:[UINavigationBar class]]) break; }
}
static NSHashTable *gFaded;   // bar backgrounds we hid
static void UndoNav(void) {
    for (UIView *v in [gStyled allObjects]) { [objc_getAssociatedObject(v, &kGlassKey) removeFromSuperview]; objc_setAssociatedObject(v, &kGlassKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    [gStyled removeAllObjects];
    for (UIView *v in [gFaded allObjects]) { v.alpha = 1; v.hidden = NO; }
    [gFaded removeAllObjects];
}
// FaceTime: its glass circle swells out toward where the menu opens, then fades
// into it (iOS 26 morph), and comes back when the menu closes.
@interface M26FaceTime : NSObject
+ (instancetype)shared;
- (void)tap:(UIControl *)c;
@end
@implementation M26FaceTime
+ (instancetype)shared { static M26FaceTime *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26FaceTime new]; }); return t; }
- (void)tap:(UIControl *)c {
    UIView *g = objc_getAssociatedObject(c, &kGlassKey);
    if (!g) return;
    CGRect from = g.frame;
    CGFloat w = 230, h = 170;
    CGRect to = CGRectMake(CGRectGetMaxX(from) - w, CGRectGetMinY(from), w, h);
    CABasicAnimation *cr = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cr.fromValue = @(from.size.width / 2); cr.toValue = @26; cr.duration = 0.25;
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        g.frame = to;
    } completion:^(__unused BOOL d) {
        [UIView animateWithDuration:0.15 animations:^{ g.alpha = 0; } completion:^(__unused BOOL d2) {
            g.frame = from; g.layer.cornerRadius = from.size.width / 2;
            [UIView animateWithDuration:0.25 delay:0.6 options:0 animations:^{ g.alpha = 1; } completion:nil];
        }];
    }];
    g.layer.cornerRadius = 26;
    [g.layer addAnimation:cr forKey:@"cr"];
}
@end
static NSHashTable *gNameGlass;
static __weak UIView *gNameNow;
// A soft blur fading down from the top (behind the status bar and the buttons).
static void TopBlur(UINavigationBar *nb) {
    UIView *host = nb.superview;
    if (!host) return;
    UIVisualEffectView *b = (UIVisualEffectView *)[host viewWithTag:GLASS_TAG + 7];
    if (!b) {
        b = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
        b.tag = GLASS_TAG + 7; b.userInteractionEnabled = NO;
        CAGradientLayer *m = [CAGradientLayer layer];
        m.colors = @[(id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
        m.locations = @[@0, @0.45, @1];
        b.layer.mask = m;
    }
    if (b.superview != host || [host.subviews indexOfObject:b] > [host.subviews indexOfObject:nb]) [host insertSubview:b belowSubview:nb];
    CGRect f = CGRectMake(0, 0, host.bounds.size.width, CGRectGetMaxY([nb convertRect:nb.bounds toView:host]) + 6);
    if (!CGRectEqualToRect(b.frame, f)) { b.frame = f; [CATransaction begin]; [CATransaction setDisableActions:YES]; b.layer.mask.frame = b.bounds; [CATransaction commit]; }
}
@interface M26Cancel : NSObject
+ (instancetype)shared;
@end
@implementation M26Cancel
+ (instancetype)shared { static M26Cancel *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Cancel new]; }); return t; }
- (void)tap:(UIBarButtonItem *)it {
    UIBarButtonItem *orig = objc_getAssociatedObject(it, "m26orig");
    if (orig.target && orig.action) ((void (*)(id, SEL, id))objc_msgSend)(orig.target, orig.action, orig);
}
@end
static void CancelToX(UINavigationItem *ni) {
    NSArray *items = ni.rightBarButtonItems;
    if (!items.count) return;
    NSMutableArray *out = [NSMutableArray array]; BOOL changed = NO;
    for (UIBarButtonItem *it in items) {
        if (objc_getAssociatedObject(it, "m26orig")) { [out addObject:it]; continue; }
        NSString *t = it.title.lowercaseString;
        NSInteger sys = -1; @try { sys = [[it valueForKey:@"systemItem"] integerValue]; } @catch (__unused id e) {}
        BOOL isCancel = [t isEqualToString:@"cancel"] || ([it respondsToSelector:@selector(isSystemItem)] && sys == UIBarButtonSystemItemCancel);
        if (!isCancel) { [out addObject:it]; continue; }
        UIBarButtonItem *x = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]] style:UIBarButtonItemStylePlain target:[M26Cancel shared] action:@selector(tap:)];
        objc_setAssociatedObject(x, "m26orig", it, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [out addObject:x]; changed = YES;
    }
    if (changed) ni.rightBarButtonItems = out;
}
@interface M26ToPlus : NSObject
+ (instancetype)shared;
@end
@implementation M26ToPlus
+ (instancetype)shared { static M26ToPlus *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26ToPlus new]; }); return t; }
- (void)tap:(UIButton *)b { UIButton *add = objc_getAssociatedObject(b, "m26add"); [add sendActionsForControlEvents:UIControlEventTouchUpInside]; }
@end
// New message "To:" row: a glass capsule, with a white glass + inside.
static void StyleToField(UIWindow *w) {
    UILabel *to = (UILabel *)Find(w, ^BOOL(UIView *v) { return [v isKindOfClass:[UILabel class]] && [[((UILabel *)v).text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] hasPrefix:@"To:"] && v.window && !v.hidden && v.alpha > 0.05; }, 6000);
    if (!to) return;
    UIView *row = to;
    while (row.superview && row.bounds.size.width < w.bounds.size.width * 0.9) row = row.superview;
    if (!row.superview || row.bounds.size.height > 200) return;
    for (UIView *o in [[w viewWithTag:GLASS_TAG + 9].superview subviews]) if (o.tag == GLASS_TAG + 9 && o.superview != row) [o removeFromSuperview];
    for (UIView *s in row.superview.subviews) if (s != row && s.bounds.size.height <= 1.5 && s.bounds.size.width >= w.bounds.size.width * 0.8) s.hidden = YES;
    for (UIView *s in row.subviews) if (s.bounds.size.height <= 1.5 && s.bounds.size.width >= w.bounds.size.width * 0.8) s.hidden = YES;
    UIView *g = [row viewWithTag:GLASS_TAG + 9];
    if (!g) { g = [UIView new]; g.userInteractionEnabled = NO; g.tag = GLASS_TAG + 9; g.layer.borderWidth = 1; g.layer.cornerCurve = kCACornerCurveContinuous; [row insertSubview:g atIndex:0]; }
    { BOOL dk = IsDark(row);
      g.backgroundColor = dk ? [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:0.96] : [UIColor colorWithWhite:0.97 alpha:0.96];
      g.layer.borderColor = (dk ? [UIColor colorWithWhite:1 alpha:0.16] : [UIColor colorWithWhite:0 alpha:0.10]).CGColor; }
    CGFloat h = MIN(row.bounds.size.height - 8, 52);
    CGRect gf = CGRectMake(16, CGRectGetMidY([to convertRect:to.bounds toView:row]) - h / 2, row.bounds.size.width - 32, h);
    if (!CGRectEqualToRect(g.frame, gf)) { g.frame = gf; g.layer.cornerRadius = h / 2; SheenFit(g); }
    if (CGRectGetMinX(to.frame) < 30 && to.superview == row) { CGRect f = to.frame; f.origin.x = 32; to.frame = f; }
    UIButton *add = nil; CGFloat ax = -1;
    { NSMutableArray *bs = [NSMutableArray arrayWithObject:row]; int gb = 0;
      while (bs.count && gb++ < 200) { UIView *v = bs.lastObject; [bs removeLastObject];
        if ([v isKindOfClass:[UIButton class]] && !v.hidden && v.alpha > 0.05 && v.bounds.size.width < 70) { CGFloat x = [v convertPoint:CGPointZero toView:row].x; if (x > ax) { ax = x; add = (UIButton *)v; } }
        [bs addObjectsFromArray:v.subviews]; } }
    if (add) {
        if (add.alpha > 0) add.alpha = 0.02;   // Apple's blue one: invisible
        if (!CGAffineTransformIsIdentity(add.transform)) add.transform = CGAffineTransformIdentity;
        UIButton *mine = (UIButton *)[row viewWithTag:GLASS_TAG + 11];
        if (!mine) {
            mine = [UIButton buttonWithType:UIButtonTypeCustom]; mine.tag = GLASS_TAG + 11;
            mine.layer.borderWidth = 1;
            [mine setImage:[UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
            [mine addTarget:[M26ToPlus shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            [row addSubview:mine];
        }
        objc_setAssociatedObject(mine, "m26add", add, OBJC_ASSOCIATION_ASSIGN);
        [[row viewWithTag:GLASS_TAG + 10] removeFromSuperview];
        BOOL dk = IsDark(row);
        mine.tintColor = Ink(row);
        mine.backgroundColor = dk ? [UIColor colorWithWhite:1 alpha:0.12] : [UIColor colorWithWhite:0 alpha:0.06];
        mine.layer.borderColor = [UIColor colorWithWhite:dk ? 1 : 0 alpha:dk ? 0.18 : 0.1].CGColor;
        CGFloat d = 32;
        CGRect mf = CGRectMake(CGRectGetMaxX(g.frame) - 9 - d, CGRectGetMidY(g.frame) - d / 2, d, d);
        if (!CGRectEqualToRect(mine.frame, mf)) { mine.frame = mf; mine.layer.cornerRadius = d / 2; }
        if (row.subviews.lastObject != mine) [row bringSubviewToFront:mine];
    }
}

static void StyleOneNav(UINavigationBar *nb, NSMutableArray *found, BOOL chat) {
    TopBlur(nb);
    @try { CancelToX(nb.topItem); } @catch (__unused id e) {}
    nb.tintColor = Ink(nb);
    // see-through bar for good (scrolling brought the gray back)
    if (!objc_getAssociatedObject(nb, "m26app")) {
        objc_setAssociatedObject(nb, "m26app", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UINavigationBarAppearance *a = [nb.standardAppearance copy] ?: [UINavigationBarAppearance new];
        [a configureWithTransparentBackground];
        a.titleTextAttributes = nb.standardAppearance.titleTextAttributes ?: @{};
        a.largeTitleTextAttributes = nb.standardAppearance.largeTitleTextAttributes ?: @{};
        nb.standardAppearance = a; nb.scrollEdgeAppearance = a; nb.compactAppearance = a;
        if (@available(iOS 15.0, *)) nb.compactScrollEdgeAppearance = a;
    }
    // no bar background: the buttons float on the chat
    NSMutableArray *bs = [NSMutableArray arrayWithArray:nb.subviews];
    int gb = 0;
    while (bs.count && gb++ < 40) {
        UIView *s = bs.firstObject; [bs removeObjectAtIndex:0];
        NSString *n = NSStringFromClass([s class]);
        if (!gFaded) gFaded = [NSHashTable weakObjectsHashTable];
        if (([n containsString:@"BarBackground"] || [n containsString:@"Backdrop"]) && s.alpha > 0) { s.alpha = 0; [gFaded addObject:s]; }
        else if (s.bounds.size.width >= nb.bounds.size.width * 0.95 && s.bounds.size.height <= 1.5 && !s.hidden) { s.hidden = YES; [gFaded addObject:s]; }   // hairline
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
            // "Cancel" text button -> X
            if (right && [v isKindOfClass:[UIButton class]]) {
                UIButton *b = (UIButton *)v;
                NSString *bt = [b titleForState:UIControlStateNormal] ?: b.titleLabel.text;
                if ([bt.lowercaseString isEqualToString:@"cancel"]) {
                    [b setTitle:@"" forState:UIControlStateNormal];
                    [b setImage:[[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]] imageWithTintColor:Ink(nb) renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
                    if (b.configuration) { UIButtonConfiguration *c = b.configuration; c.title = nil; c.attributedTitle = nil; c.image = [b imageForState:UIControlStateNormal]; b.configuration = c; }
                }
                // labels inside a custom bar view ("Cancel" drawn as a label)
                NSMutableArray *ls2 = [NSMutableArray arrayWithObject:v]; int g2 = 0;
                while (ls2.count && g2++ < 20) { UIView *x = ls2.lastObject; [ls2 removeLastObject];
                    if ([x isKindOfClass:[UILabel class]] && [((UILabel *)x).text.lowercaseString isEqualToString:@"cancel"]) x.hidden = YES;
                    [ls2 addObjectsFromArray:x.subviews]; }
            }
            if (left) {
                // unread count on the back button: dark number on the white badge
                NSMutableArray *ls = [NSMutableArray arrayWithObject:v]; int gl = 0;
                while (ls.count && gl++ < 30) { UIView *x = ls.lastObject; [ls removeLastObject];
                    if ([x isKindOfClass:[UILabel class]]) { UIColor *c = IsDark(nb) ? UIColor.blackColor : UIColor.whiteColor; if (![((UILabel *)x).textColor isEqual:c]) ((UILabel *)x).textColor = c; }
                    [ls addObjectsFromArray:x.subviews]; }
            }
            if (right && [v isKindOfClass:[UIControl class]] && !objc_getAssociatedObject(v, "m26ft")) {
                objc_setAssociatedObject(v, "m26ft", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [(UIControl *)v addTarget:[M26FaceTime shared] action:@selector(tap:) forControlEvents:UIControlEventTouchDown];
            }
            if (left || right) { GlassBehind(v, left ? 10 : 7, right ? 7 : 7, right); [found addObject:[NSString stringWithFormat:@"%@%@", left ? @"L:" : @"R:", cn]]; continue; }
        }
        if (chat && [v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length && ((UILabel *)v).font.pointSize < 16 && fabs(CGRectGetMidX(f) - W / 2) < W * 0.25 && f.size.height < 30) {
            UILabel *l = (UILabel *)v;
            UIView *holder = l;
            // the label and its ">" share a small parent: cover both
            if (l.superview && l.superview.bounds.size.width < W * 0.7 && l.superview.bounds.size.height < 44 && l.superview != nb) holder = l.superview;
            GlassBehind(holder, 12, 6, NO);
            if (!gNameGlass) gNameGlass = [NSHashTable weakObjectsHashTable];
            [gNameGlass addObject:holder];
            gNameNow = holder;
            [found addObject:[NSString stringWithFormat:@"name:%@", l.text]];
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
}
static void StyleNav(UIWindow *w) {
    UIView *e = gEntry;
    BOOL chat = e.window != nil;
    if (!gTopOn) { UndoNav(); gNavDebug = @"top bar off"; return; }
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *st = [NSMutableArray arrayWithObject:w];
    int g = 0, bars = 0;
    while (st.count && g++ < 4000) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.hidden || v.alpha < 0.05) continue;
        if ([v isKindOfClass:[UINavigationBar class]]) {
            CGRect f = [v convertRect:v.bounds toView:nil];
            // the chat's bar (on the right side on iPad-style splits)
            if (CGRectGetMaxX(f) >= w.bounds.size.width - 2) { bars++; StyleOneNav((UINavigationBar *)v, found, chat); }
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
    // name glass left from another conversation / the list title: gone
    for (UIView *h in [gNameGlass allObjects]) if (!chat || h != gNameNow) {
        [objc_getAssociatedObject(h, &kGlassKey) removeFromSuperview];
        objc_setAssociatedObject(h, &kGlassKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [gNameGlass removeObject:h];
    }
    if (!chat) gNameNow = nil;
    gNavDebug = [NSString stringWithFormat:@"nav chat=%d bars=%d items: %@", chat, bars, [found componentsJoinedByString:@" "]];
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
    if (gTopOn) { @try { for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) if ([sc isKindOfClass:[UIWindowScene class]]) for (UIWindow *x in ((UIWindowScene *)sc).windows) StyleToField(x); } @catch (__unused id e) {} }
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
    l.text = [NSString stringWithFormat:@" Messages26 0.7.9 debug\n %@\n %@", gDebug, gNavDebug];
    CGSize s = [l sizeThatFits:CGSizeMake(w.bounds.size.width - 24, 800)];
    l.frame = CGRectMake(12, w.safeAreaInsets.top + 140, w.bounds.size.width - 24, s.height + 12);
    [w bringSubviewToFront:l];
}

%hook UIView
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)e {
    BOOL r = %orig;
    if (r) return r;
    UIView *en = gEntry, *fld = gField;
    if (!en || (self != en && ![en isDescendantOfView:self] && !(fld && [fld isDescendantOfView:self]))) return r;
    for (NSNumber *t in @[@(PILL_TAG), @(PLUS_TAG)]) {
        UIView *v = [en viewWithTag:t.integerValue];
        if (!v) { UIView *f = gField; v = [f.superview viewWithTag:t.integerValue]; }
        if (v && !v.hidden && CGRectContainsPoint(CGRectInset([v convertRect:v.bounds toView:self], -4, -4), p)) return YES;
    }
    UIView *f = gField;
    if (f.window && CGRectContainsPoint([f convertRect:f.bounds toView:self], p)) return YES;
    return r;
}
%end
%ctor {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.MobileSMS"]) return;
    LoadPrefs();
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
        CGRect f = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat H = UIScreen.mainScreen.bounds.size.height;
        gKbTop = (CGRectGetMinY(f) < H - 60 && f.size.height > 100) ? CGRectGetMinY(f) : 0;
        UIView *e = gEntry; [e setNeedsLayout];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *n) { gKbTop = 0; UIView *e = gEntry; [e setNeedsLayout]; }];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, CFSTR("com.nano.messages26/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    dispatch_async(dispatch_get_main_queue(), ^{
        Class E = NSClassFromString(@"CKMessageEntryView");
        if (E) {
            MSHookMessageEx(E, @selector(layoutSubviews), (IMP)EntryLayout, (IMP *)&origEntryLayout);
            MSHookMessageEx(E, @selector(hitTest:withEvent:), (IMP)EntryHit, (IMP *)&origEntryHit);
        }
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(__unused NSTimer *t) { @try { Tick(); } @catch (__unused id ex) {} }];
    });
}
