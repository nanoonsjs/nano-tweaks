// Messages26 0.12.3 - made by nano
// 0.12.3: background stays put while scrolling; smoother peek (zoom + shade lift)
// 0.12.2: pull up past the last message to see the full background, pull down to come back
// 0.12.1: no black corners on bubbles over a background
// 0.12.0: Backgrounds tab (None / Photo / Color), each chat its own background
// 0.11.4: no gray boxes (header, media, cells); one glass card per Info group; Shared-with-You note gone
// 0.11.3: tabs switch the whole page; no Shared-with-You note, no iCloud footer; header see-through
// 0.11.2: tabs no longer crash; tabs clear of the cards; glass cards on a black page
// 0.11.1: tabs really split the page (Info / Photos / Links / Documents / Collaboration); Edit presses info
// 0.11.0: iOS 26 contact page: glass back + Edit, three glass icon buttons, Info / Backgrounds / Photos / Links tabs
// 0.10.13: name capsule drawn over the photo
// 0.10.12: name + glass measured without the scaling (no double move, no jitter)
// 0.10.11: name glass moves with the name; name centered
// 0.10.10: photo + name scaled without fighting Messages' layout; name hangs right under the photo
// 0.10.9: photo is the 51x60 avatar container
// 0.10.8: photo found anywhere on screen above the name
// 0.10.7: photo + name scaled one by one (bigger for real); drag the debug box anywhere
// 0.10.6: bigger contact photo + name at the top of a chat
// 0.10.5: To: typing spot stays after the label (Messages' resets are undone right away)
// 0.10.4: typing in To: starts after the label; + is white
// 0.10.3: To: row fits the capsule (no overlap), white + right under the X
// 0.10.2: rim sits on the bubble edge, none on big emoji; reply arrow no longer grows huge
// 0.10.1: bubble rim follows the bubble shape; swipe reply opens the reply view
// 0.10.0: glass rim on received bubbles, deeper blue iMessages, swipe right to reply
// 0.9.2: search pill mic starts dictation; no FaceTime tap animation
// 0.9.1: search moves above the keyboard with an X; all glass matches the search pill; top compose gone
// 0.9.0: iOS 26 search pill + compose circle at the bottom of the conversation list
// 0.8.4: pill always pulled back after reopening a chat; mic tap goes to the visible button
// 0.8.3: field row placed from where it's drawn now (corrects itself); mic / send found by position and kept in the pill
// 0.8.2: the bar never gets stuck "waiting" (pill, + and glass are back); no empty glass circles
// 0.8.1: text no longer jumps up and down; send works
// 0.8.0: send / mic always inside the pill (also with the keyboard up), no floating pill after the keyboard closes
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
#import <PhotosUI/PhotosUI.h>

#define PLUS_TAG  0x4D323650
#define GLASS_TAG 0x4D323647
#define DEBUG_TAG 0x4D323644
#define MENU_TAG  0x4D32364D
#define PILL_TAG  0x4D323649

#define DOM CFSTR("com.nano.messages26")
static BOOL gOn = YES, gBarOn = YES, gMenuOn = YES, gTopOn = YES, gSearchOn = YES, gBubblesOn = YES, gSwipeOn = YES, gPrefDebug = NO;
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
    gSearchOn = gOn && PrefBool(file, @"searchpill", YES);
    gBubblesOn = gOn && PrefBool(file, @"bubbles", YES);
    gSwipeOn = gOn && PrefBool(file, @"swipereply", YES);
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
    // same look as the search pill: solid dark glass, bright rim along the top
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:nil];
    g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.contentView.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:0.97] : [UIColor colorWithWhite:0.97 alpha:0.97];
    g.layer.borderWidth = 0;
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
__attribute__((unused)) static void SheenFit(UIView *g) {
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
    if (gMenuOn) {
        if (strip.alpha > 0) strip.alpha = 0;
        if (strip.userInteractionEnabled) strip.userInteractionEnabled = NO;
        CGRect sf = strip ? [strip convertRect:strip.bounds toView:entry] : CGRectZero;
        CGRect cf0 = CGRectApplyAffineTransform(container.frame, CGAffineTransformInvert(container.transform));
        (void)sf; (void)cf0;
        container = nil;
        // pieces we moved in older builds: back in place
        NSMutableArray *rs = [NSMutableArray arrayWithArray:entry.subviews]; int gr = 0;
        while (rs.count && gr++ < 300) { UIView *v = rs.lastObject; [rs removeLastObject];
            if (v.tag != PLUS_TAG && v.tag != PILL_TAG && v != field && ![v isKindOfClass:[UIControl class]] && ![gRowCtls containsObject:v] && !CGAffineTransformIsIdentity(v.transform) && ![field isDescendantOfView:v]) v.transform = CGAffineTransformIdentity;
            [rs addObjectsFromArray:v.subviews]; }
        if (!CGAffineTransformIsIdentity(entry.transform)) entry.transform = CGAffineTransformIdentity;
        // The field row moves down: onto the keyboard when it's up (where the hidden app
        // row was), else to just above the home bar. Worked out from where things are
        // drawn right now and corrected from there, so nothing else can throw it off.
        UIWindow *ew = entry.window;
        NSMutableArray *row = [NSMutableArray arrayWithObject:field];
        CGRect ffNow = [field convertRect:field.bounds toView:entry];
        // mic / send: small buttons to the right of the text box (wherever they are now)
        NSMutableArray *cs = [NSMutableArray arrayWithArray:entry.subviews]; int gc = 0;
        while (cs.count && gc++ < 300) { UIView *v = cs.lastObject; [cs removeLastObject];
            if (v == field || v.tag == PLUS_TAG || v.tag == PILL_TAG || v == strip || [v isDescendantOfView:field] || (strip && [v isDescendantOfView:strip])) continue;
            if ([v isKindOfClass:[UIControl class]] && !v.hidden && v.bounds.size.width < 60 && v.bounds.size.height < 60) {
                CGRect vf = [v convertRect:v.bounds toView:entry];
                if (CGRectGetMidX(vf) > CGRectGetMinX(ffNow) + ffNow.size.width * 0.6) { [row addObject:v]; continue; }
            }
            [cs addObjectsFromArray:v.subviews]; }
        CGRect ef = [entry convertRect:entry.bounds toView:nil];
        BOOL kbUp = CGRectGetMaxY(ef) < ew.bounds.size.height - 120;   // the bar rides on the keyboard
        CGFloat wantBottom = kbUp ? entry.bounds.size.height - (strip ? 10 : 4) : entry.bounds.size.height - 43;
        CGFloat t0 = field.transform.ty, t1 = t0 + (wantBottom - CGRectGetMaxY(ffNow));
        if (fabs(t1) > 2000) t1 = 0;   // Messages can leave the box far off after a chat reopens: always pull it back
        shift = t1;
        gKbTop = kbUp ? CGRectGetMaxY(ef) : 0;
        if (fabs(t1 - t0) > 0.5) field.transform = CGAffineTransformMakeTranslation(0, t1);
        CGFloat midY = CGRectGetMidY(ffNow) + (t1 - t0);
        for (UIView *v in row) if (v != field) {
            CGRect vf = [v convertRect:v.bounds toView:entry];
            CGFloat d = midY - CGRectGetMidY(vf);
            if (fabs(d) > 0.5 && fabs(v.transform.ty + d) < 2000) v.transform = CGAffineTransformMakeTranslation(0, v.transform.ty + d);
        }
        // their boxes must not cut them off (the mic was drawn outside its box, so it vanished)
        if (!gRowCtls) gRowCtls = [NSHashTable weakObjectsHashTable];
        [gRowCtls removeAllObjects];
        for (UIView *v in row) {
            if (v != field) [gRowCtls addObject:v];
            for (UIView *p = v.superview; p && p != entry; p = p.superview) if (p.clipsToBounds) p.clipsToBounds = NO;
        }
        NSMutableArray *rn = [NSMutableArray array];
        for (UIView *v in row) if (v != field) { CGFloat a = 1; BOOL hd = NO; for (UIView *q = v; q && q != entry; q = q.superview) { hd |= q.hidden; a *= q.alpha; } [rn addObject:[NSString stringWithFormat:@"%@ a=%.1f h=%d en=%d", NSStringFromClass([v class]), a, hd, [v isKindOfClass:[UIControl class]] ? ((UIControl *)v).enabled : 1]]; }
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
    pill.layer.borderWidth = 0; pill.layer.borderColor = UIColor.clearColor.CGColor;
    pill.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:0.97] : [UIColor colorWithWhite:0.97 alpha:0.97];
    pill.layer.shadowColor = UIColor.blackColor.CGColor; pill.layer.shadowOpacity = dark ? 0.35 : 0.12; pill.layer.shadowRadius = 14; pill.layer.shadowOffset = CGSizeMake(0, 6);
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
    g.backgroundColor = pill.backgroundColor; g.layer.borderWidth = 0;
    g.layer.shadowColor = UIColor.blackColor.CGColor; g.layer.shadowOpacity = pill.layer.shadowOpacity; g.layer.shadowRadius = 14; g.layer.shadowOffset = CGSizeMake(0, 6);
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
        // mic and send sit on the same spot: give the touch to the one that's actually showing
        UIView *best = nil; CGFloat bestA = 0.05;
        for (UIView *c in [gRowCtls allObjects]) {
            if (!c.window || !c.userInteractionEnabled || ![c isDescendantOfView:self]) continue;
            if ([c isKindOfClass:[UIControl class]] && !((UIControl *)c).enabled) continue;
            if (!CGRectContainsPoint(CGRectInset([c convertRect:c.bounds toView:self], -4, -4), p)) continue;
            CGFloat a = 1; BOOL hid = NO;
            for (UIView *q = c; q && q != self; q = q.superview) { if (q.hidden) { hid = YES; break; } a *= q.alpha; }
            if (hid) continue;
            if (a > bestA) { bestA = a; best = c; }
        }
        if (best) { CGPoint q = [self convertPoint:p toView:best]; q.x = MIN(MAX(q.x, 1), best.bounds.size.width - 1); q.y = MIN(MAX(q.y, 1), best.bounds.size.height - 1); return [best hitTest:q withEvent:e] ?: best; }
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
static BOOL gDrewNothing;
static CGRect DrawnRect(UIView *v) {
    CGRect u = CGRectNull;
    gDrewNothing = NO;
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
    gDrewNothing = CGRectIsNull(u);
    return CGRectIsNull(u) ? v.frame : u;
}
static __weak UIView *gNameNow;
static CGFloat gNameTy = 0, gNameTx = 0;
#define TITLE_SCALE 1.3
static CGRect NameDrawn(UIView *name, CGRect r, UIView *host);
static void GlassBehind(UIView *v, CGFloat padX, CGFloat padY, BOOL circle) {
    // the name's glass lives inside the name itself, so it grows and moves with it
    BOOL inside = (v == gNameNow);
    UIView *host = inside ? v : v.superview;
    if (!host || !v.superview) return;
    if (!gStyled) gStyled = [NSHashTable weakObjectsHashTable];
    [gStyled addObject:v];
    UIVisualEffectView *g = objc_getAssociatedObject(v, &kGlassKey);
    if (!g || g.superview != host) {
        [g removeFromSuperview];
        g = GlassView(v); g.tag = GLASS_TAG;
        if (inside) [host insertSubview:g atIndex:0]; else [host insertSubview:g belowSubview:v];
        objc_setAssociatedObject(v, &kGlassKey, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (inside && host.subviews.firstObject != g) [host sendSubviewToBack:g];
    // measure without our scaling (positions would count it twice)
    CATransform3D keep = v.layer.sublayerTransform;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (inside) v.layer.sublayerTransform = CATransform3DIdentity;
    CGRect f = DrawnRect(v);
    if (inside) { f = [v.superview convertRect:f toView:v]; v.layer.sublayerTransform = keep; }
    [CATransaction commit];
    CGRect want = CGRectInset(f, -padX, -padY);
    if (circle) { CGFloat d = MAX(want.size.width, want.size.height); want = CGRectMake(CGRectGetMidX(f) - d / 2, CGRectGetMidY(f) - d / 2, d, d); }
    want = CGRectIntegral(want);
    if (g.layer.animationKeys.count || g.alpha < 1) return;
    if (!CGRectEqualToRect(g.frame, want)) { g.frame = want; g.layer.cornerRadius = MIN(want.size.width, want.size.height) / 2; RimFit(g, IsDark(v)); }
    g.hidden = v.hidden || v.alpha < 0.05 || gDrewNothing;
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
static UIViewController *SearchList(void);
static NSHashTable *gNameGlass;
// A soft blur fading down from the top (behind the status bar and the buttons).
static __weak UINavigationBar *gChatBar;
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
    CGFloat bot = CGRectGetMaxY([nb convertRect:nb.bounds toView:host]) + 6;
    UIView *tb = gNameNow;
    if (tb.window && [tb isDescendantOfView:nb]) bot = MAX(bot, CGRectGetMaxY(NameDrawn(tb, [tb convertRect:tb.bounds toView:host], host)) + 14);
    CGRect f = CGRectMake(0, 0, host.bounds.size.width, bot);
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
static NSString *gToDebug = @"to: -";
static char kToExtra, kToBase;
static void (*origTVInset)(id, SEL, UIEdgeInsets);
static void TVInset(UITextView *self, SEL _cmd, UIEdgeInsets in) {
    NSNumber *ex = objc_getAssociatedObject(self, &kToExtra);
    if (ex && ex.doubleValue > 0) {
        objc_setAssociatedObject(self, &kToBase, [NSValue valueWithUIEdgeInsets:in], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        in.left += ex.doubleValue;
    }
    origTVInset(self, _cmd, in);
}
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
      g.backgroundColor = dk ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:0.97] : [UIColor colorWithWhite:0.97 alpha:0.97];
      g.layer.borderWidth = 0; }
    CGFloat h = MIN(row.bounds.size.height - 8, 52);
    // capsule: 16pt from both screen edges (worked out on screen, wherever the row sits)
    CGFloat W = w.bounds.size.width;
    CGFloat ox = [row convertPoint:CGPointZero toView:nil].x;
    CGRect gf = CGRectMake(16 - ox, CGRectGetMidY([to convertRect:to.bounds toView:row]) - h / 2, W - 32, h);
    // everything in the row (To:, the typed names) slides right together so "To:" sits inside
    { CGFloat lx = [to convertRect:to.bounds toView:nil].origin.x;
      UIView *top = to; while (top.superview && top.superview != row) top = top.superview;
      CGFloat cur = top.transform.tx, dx = MAX(0, cur + (34 - lx));
      if (dx > 40) dx = 0;
      for (UIView *c in row.subviews) {
          if (c == g || c.tag == GLASS_TAG + 11 || c.tag == GLASS_TAG + 9) continue;
          if (c.bounds.size.height <= 1.5) continue;
          if (fabs(c.transform.tx - dx) > 0.5) c.transform = CGAffineTransformMakeTranslation(dx, 0);
      } }
    if (!CGRectEqualToRect(g.frame, gf)) { g.frame = gf; g.layer.cornerRadius = h / 2; RimFit(g, IsDark(row)); }
    UIButton *add = nil; CGFloat ax = -1;
    { NSMutableArray *bs = [NSMutableArray arrayWithObject:row]; int gb = 0;
      while (bs.count && gb++ < 200) { UIView *v = bs.lastObject; [bs removeLastObject];
        if (v.tag == GLASS_TAG + 11) continue;   // ours
        if ([v isKindOfClass:[UIButton class]] && !v.hidden && v.alpha > 0.01 && v.bounds.size.width < 70) { CGFloat x = [v convertPoint:CGPointZero toView:row].x; if (x > ax) { ax = x; add = (UIButton *)v; } }
        [bs addObjectsFromArray:v.subviews]; } }
    if (add) {
        if (add.alpha > 0.02) add.alpha = 0.02;   // Apple's blue one: invisible (and white if it shows)
        add.tintColor = Ink(row);
        if ([add imageForState:UIControlStateNormal]) { UIImage *im = [add imageForState:UIControlStateNormal]; if (im.renderingMode != UIImageRenderingModeAlwaysTemplate) [add setImage:[im imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal]; }
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
        CGFloat cx = CGRectGetMaxX(g.frame) - 9 - d / 2;
        // right under the X (its glass circle), if it's there
        CGFloat best = -1;
        for (UIView *sv in [gStyled allObjects]) {
            if (sv.window != w) continue;
            UIView *gl = objc_getAssociatedObject(sv, &kGlassKey);
            if (!gl || gl.hidden) continue;
            CGRect gw = [gl convertRect:gl.bounds toView:nil];
            if (CGRectGetMidX(gw) > W * 0.7 && CGRectGetMidX(gw) > best) best = CGRectGetMidX(gw);
        }
        if (best > 0) cx = MIN(best - ox, CGRectGetMaxX(g.frame) - 6 - d / 2);
        CGRect mf = CGRectMake(cx - d / 2, CGRectGetMidY(g.frame) - d / 2, d, d);
        if (!CGRectEqualToRect(mine.frame, mf)) { mine.frame = mf; mine.layer.cornerRadius = d / 2; }
        if (row.subviews.lastObject != mine) [row bringSubviewToFront:mine];
        mine.hidden = NO; mine.alpha = 1;
        [mine setImage:[[UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]] imageWithTintColor:Ink(row) renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    // the typing spot starts after "To:" (it was drawn under it)
    UITextView *tv = (UITextView *)Find(row, ^BOOL(UIView *v) { return [v isKindOfClass:[UITextView class]] && !v.hidden; }, 200);
    if (tv) {
        CGRect lw = [to convertRect:to.bounds toView:nil];
        CGRect cr = [tv caretRectForPosition:tv.beginningOfDocument];
        CGFloat caretX = [tv convertPoint:cr.origin toView:nil].x;
        CGFloat need = CGRectGetMaxX(lw) + 6 - caretX;
        if ([tv isDescendantOfView:to]) need = 0;
        // Messages keeps resetting the spacing: remember our extra and add it back every time
        CGFloat extra = [objc_getAssociatedObject(tv, &kToExtra) doubleValue];
        if (fabs(need) > 0.5 && (need > 0 || extra > 0) && need < 80) {
            NSValue *bv = objc_getAssociatedObject(tv, &kToBase);
            UIEdgeInsets base = bv ? bv.UIEdgeInsetsValue : tv.textContainerInset;
            if (!bv) objc_setAssociatedObject(tv, &kToBase, [NSValue valueWithUIEdgeInsets:base], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            extra = MAX(0, extra + need);
            objc_setAssociatedObject(tv, &kToExtra, @(extra), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            tv.textContainerInset = base;   // (the hook adds the extra)
        }
        gToDebug = [NSString stringWithFormat:@"to: label=%.0f caret=%.0f extra=%.0f add=%@ a=%.2f", CGRectGetMaxX(lw), caretX, [objc_getAssociatedObject(tv, &kToExtra) doubleValue], add ? NSStringFromClass([add class]) : @"-", add.alpha];
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
            // (no FaceTime morph on tap anymore)
            if (right && gSearchOn && !chat) {
                UIViewController *lv = SearchList();
                if (lv && lv.navigationController.navigationBar == nb && lv.navigationController.topViewController == lv) {
                    if (v.alpha > 0) { v.alpha = 0; if (!gFaded) gFaded = [NSHashTable weakObjectsHashTable]; [gFaded addObject:v]; }
                    v.userInteractionEnabled = NO;
                    [objc_getAssociatedObject(v, &kGlassKey) removeFromSuperview]; objc_setAssociatedObject(v, &kGlassKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    continue;
                }
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

// Bigger contact photo + name in a chat (iOS 26 size), a little lower.
static __weak UIView *gAvatarV;
static NSString *gTitleDebug = @"title: -";
static NSString *gTitleNear = @"";
static void Crisp(UIView *root, CGFloat s) {
    CGFloat cs = UIScreen.mainScreen.scale * s;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root]; int g = 0;
    while (st.count && g++ < 60) { UIView *v = st.lastObject; [st removeLastObject];
        if ([v isKindOfClass:[UILabel class]] && fabs(v.layer.contentsScale - cs) > 0.01) { v.layer.contentsScale = cs; [v setNeedsDisplay]; }
        [st addObjectsFromArray:v.subviews]; }
}
static void ScaleTitle(BOOL chat, UINavigationBar *nb) {
    UIView *name = gNameNow, *oldA = gAvatarV;
    UIView *av = nil;
    if (chat && gTopOn && name.window && nb) {
        // the photo: a square right above the name, in the middle (searched in the whole window)
        UIWindow *win = name.window;
        CGRect nw = [name convertRect:name.bounds toView:nil];
        CGFloat Wd = win.bounds.size.width, bestW = 0;
        NSMutableArray *near = [NSMutableArray array];
        NSMutableArray *st = [NSMutableArray arrayWithObject:win]; int g = 0;
        while (st.count && g++ < 5000) { UIView *v = st.lastObject; [st removeLastObject];
            if (v.hidden || v.alpha < 0.05 || v.tag == GLASS_TAG || v == name || [v isDescendantOfView:name]) continue;
            CGRect r = [v convertRect:v.bounds toView:nil];
            if (CGRectGetMinY(r) > CGRectGetMaxY(nw) + 10) continue;   // nothing below the name matters
            CGSize sz = r.size;
            BOOL mid = fabs(CGRectGetMidX(r) - Wd / 2) < 30, above = CGRectGetMidY(r) < CGRectGetMinY(nw) + 4 && CGRectGetMaxY(r) > CGRectGetMinY(nw) - 40;
            if (mid && above && sz.width < 120 && near.count < 6) [near addObject:[NSString stringWithFormat:@"%@ %.0fx%.0f", NSStringFromClass([v class]), sz.width, sz.height]];
            if (mid && above && ![v isKindOfClass:[UILabel class]] && ![name isDescendantOfView:v] && sz.width >= 28 && sz.width <= 100 && (fabs(sz.width - sz.height) < 12 || [NSStringFromClass([v class]) containsString:@"Avatar"]) && sz.width > bestW) { bestW = sz.width; av = v; }
            [st addObjectsFromArray:v.subviews];
        }
        gTitleNear = [near componentsJoinedByString:@", "];
        // the outermost view of that size
        while (av.superview && ![av.superview isKindOfClass:[UINavigationBar class]] && fabs(av.superview.bounds.size.width - av.bounds.size.width) < 1 && fabs(av.superview.bounds.size.height - av.bounds.size.height) < 1) av = av.superview;
    }
    // Scale with the layers' sublayerTransform: Messages lays these views out by frame
    // (a view transform got baked into their size and the photo jumped up).
    if (oldA && oldA != av) oldA.layer.sublayerTransform = CATransform3DIdentity;
    if (!CGAffineTransformIsIdentity(oldA.transform)) oldA.transform = CGAffineTransformIdentity;
    gAvatarV = av;
    CGFloat s = TITLE_SCALE;
    if (!av) {
        if (name && !(chat && gTopOn)) { name.layer.sublayerTransform = CATransform3DIdentity; gNameTy = 0; }
        gTitleDebug = [NSString stringWithFormat:@"title: no photo; near: %@", gTitleNear];
        return;
    }
    if (!CGAffineTransformIsIdentity(av.transform)) av.transform = CGAffineTransformIdentity;
    if (!CGAffineTransformIsIdentity(name.transform)) name.transform = CGAffineTransformIdentity;
    CGRect ar = [av convertRect:av.bounds toView:nil], nr = [name convertRect:name.bounds toView:nil];
    CGFloat a = ar.size.height, n = nr.size.height;
    // the round photo inside the box (its bottom is where the name should hang)
    CGFloat circBot = ar.size.width;   // local
    CATransform3D keepA = av.layer.sublayerTransform, keepN = name.layer.sublayerTransform;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    av.layer.sublayerTransform = CATransform3DIdentity; name.layer.sublayerTransform = CATransform3DIdentity;
    UIView *circ = Find(av, ^BOOL(UIView *v) { return v != av && v.bounds.size.width >= 30 && fabs(v.bounds.size.width - v.bounds.size.height) < 2; }, 40);
    if (circ) circBot = CGRectGetMaxY([circ convertRect:circ.bounds toView:av]);
    CGRect dr0 = DrawnRect(name); dr0 = [name.superview convertRect:dr0 toView:nil];
    BOOL drewNone = gDrewNothing;
    av.layer.sublayerTransform = keepA; name.layer.sublayerTransform = keepN;
    [CATransaction commit];
    CGFloat tyA = 10 + (s - 1) * a / 2;
    CGFloat avC = CGRectGetMidY(ar);
    CGFloat circleBottom = avC + s * (circBot - a / 2) + tyA;
    CGFloat nC = CGRectGetMidY(nr);
    CGFloat tyN = circleBottom - 5 - nC + s * n / 2;
    CATransform3D ta = CATransform3DScale(CATransform3DMakeTranslation(0, tyA, 0), s, s, 1);
    // keep the name centered on screen
    CGFloat tx = 0;
    { if (!drewNone) { CGFloat hc = CGRectGetMidX(nr), cx0 = CGRectGetMidX(dr0), Wd = name.window.bounds.size.width;
        tx = Wd / 2 - hc - s * (cx0 - hc); if (fabs(tx) > 24) tx = 0; } }
    gNameTx = tx;
    CATransform3D tn = CATransform3DScale(CATransform3DMakeTranslation(tx, tyN, 0), s, s, 1);
    if (!CATransform3DEqualToTransform(av.layer.sublayerTransform, ta)) av.layer.sublayerTransform = ta;
    if (!CATransform3DEqualToTransform(name.layer.sublayerTransform, tn)) name.layer.sublayerTransform = tn;
    gNameTy = tyN;
    // the name capsule sits on top of the photo
    { UIView *common = av.superview;
      while (common && ![name isDescendantOfView:common]) common = common.superview;
      UIView *nb2 = name, *ab = av;
      while (nb2.superview && nb2.superview != common) nb2 = nb2.superview;
      while (ab.superview && ab.superview != common) ab = ab.superview;
      if (common && nb2 != ab && nb2.layer.zPosition <= ab.layer.zPosition) nb2.layer.zPosition = ab.layer.zPosition + 1;
      if (name.layer.zPosition < 10) name.layer.zPosition = 10; }
    Crisp(name, s);
    for (UIView *p = av; p && ![p isKindOfClass:[UIWindow class]]; p = p.superview) { if (p.clipsToBounds) p.clipsToBounds = NO; if ([p isKindOfClass:[UINavigationBar class]]) break; }
    for (UIView *p = name; p && ![p isKindOfClass:[UIWindow class]]; p = p.superview) { if (p.clipsToBounds) p.clipsToBounds = NO; if ([p isKindOfClass:[UINavigationBar class]]) break; }
    gTitleDebug = [NSString stringWithFormat:@"title: photo=%@ %.0fx%.0f circ=%.0f name=%@ %.0f tyN=%.0f tx=%.0f", NSStringFromClass([av class]), ar.size.width, a, circBot, NSStringFromClass([name class]), n, tyN, gNameTx];
}
// where the scaled name is actually drawn (in host's space)
static CGRect NameDrawn(UIView *name, CGRect r, UIView *host) {
    if (name != gNameNow || CATransform3DIsIdentity(name.layer.sublayerTransform)) return r;
    CGPoint c = [name convertPoint:CGPointMake(name.bounds.size.width / 2, name.bounds.size.height / 2) toView:host];
    CGFloat s = TITLE_SCALE;
    CGPoint rc = CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
    CGPoint nc = CGPointMake(c.x + (rc.x - c.x) * s + gNameTx, c.y + (rc.y - c.y) * s + gNameTy);
    return CGRectMake(nc.x - r.size.width * s / 2, nc.y - r.size.height * s / 2, r.size.width * s, r.size.height * s);
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
            if (CGRectGetMaxX(f) >= w.bounds.size.width - 2) { bars++; StyleOneNav((UINavigationBar *)v, found, chat); gChatBar = (UINavigationBar *)v; }
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
    @try { ScaleTitle(chat, gChatBar); } @catch (__unused id e) {}
    gNavDebug = [NSString stringWithFormat:@"nav chat=%d bars=%d items: %@", chat, bars, [found componentsJoinedByString:@" "]];
}

#pragma mark - search pill (conversation list)

#define SEARCH_TAG  0x4D323653
#define SCOMPOSE_TAG 0x4D323643
static NSString *gSearchDebug = @"";
static NSString *gDictDebug = @"-";
static UIViewController *ListVC(UIViewController *vc, int depth) {
    if (!vc || depth > 12) return nil;
    if ([NSStringFromClass([vc class]) containsString:@"ConversationList"] && vc.viewIfLoaded.window) return vc;
    for (UIViewController *c in vc.childViewControllers) { UIViewController *r = ListVC(c, depth + 1); if (r) return r; }
    return nil;
}
static BOOL IsComposeItem(UIBarButtonItem *it) {
    NSInteger sys = -1; @try { sys = [[it valueForKey:@"systemItem"] integerValue]; } @catch (__unused id e) {}
    NSString *a = it.action ? NSStringFromSelector(it.action).lowercaseString : @"";
    return sys == UIBarButtonSystemItemCompose || [a containsString:@"compose"] || [a containsString:@"newmessage"];
}
@interface M26Search : NSObject <UITextFieldDelegate>
+ (instancetype)shared;
@property (nonatomic, weak) UIViewController *list;
@property (nonatomic, strong) UIBarButtonItem *compose;   // the top compose button we moved down
@property (nonatomic) CGFloat kbTop;                       // keyboard top on screen (0 = down)
@property (nonatomic) BOOL searching;
@end
static void StyleSearchPill(UIWindow *w);
static UIWindow *KeyWin(void) {
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) if ([sc isKindOfClass:[UIWindowScene class]]) for (UIWindow *x in ((UIWindowScene *)sc).windows) if (x.isKeyWindow) return x;
    return nil;
}
@implementation M26Search
+ (instancetype)shared { static M26Search *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Search new]; [[NSNotificationCenter defaultCenter] addObserver:t selector:@selector(kb:) name:UIKeyboardWillChangeFrameNotification object:nil]; }); return t; }
- (void)kb:(NSNotification *)n {
    CGRect e = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat H = UIScreen.mainScreen.bounds.size.height;
    self.kbTop = (e.origin.y >= H - 1 || e.size.height < 10) ? 0 : e.origin.y;
    double d = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIWindow *w = KeyWin();
    if (!w || ![w viewWithTag:SEARCH_TAG]) return;
    [UIView animateWithDuration:MAX(d, 0.25) delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ StyleSearchPill(w); [w layoutIfNeeded]; } completion:nil];
}
- (UISearchController *)sc { return self.list.navigationItem.searchController; }
- (UITextField *)field { return (UITextField *)[KeyWin() viewWithTag:SEARCH_TAG + 4]; }
- (void)down:(UIView *)b { [UIView animateWithDuration:0.18 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformMakeScale(1.06, 1.06); } completion:nil]; }
- (void)up:(UIView *)b { [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil]; }
- (void)search:(UIView *)b {
    [self up:b];
    UISearchController *sc = [self sc];
    if (!sc) { gSearchDebug = @"search: no search controller"; return; }
    if (!self.searching) [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    self.searching = YES;
    if (!sc.active) sc.active = YES;
    UIWindow *w = KeyWin();
    [UIView animateWithDuration:0.3 animations:^{ StyleSearchPill(w); }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [[self field] becomeFirstResponder]; });
}
- (void)mic:(UIView *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (!self.searching) [self search:[KeyWin() viewWithTag:SEARCH_TAG]];
    else [[self field] becomeFirstResponder];
    // start dictation once the keyboard is up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class DC = NSClassFromString(@"UIDictationController");
        SEL si = NSSelectorFromString(@"sharedInstance");
        id dc = [DC respondsToSelector:si] ? ((id (*)(id, SEL))objc_msgSend)(DC, si) : nil;
        NSString *how = @"none";
        @try {
            if ([dc respondsToSelector:NSSelectorFromString(@"switchToDictationInputModeWithTouch:mediaPlayingNotificationLauncherIsVisible:")]) { how = @"switch2"; ((void (*)(id, SEL, id, BOOL))objc_msgSend)(dc, NSSelectorFromString(@"switchToDictationInputModeWithTouch:mediaPlayingNotificationLauncherIsVisible:"), nil, NO); }
            else if ([dc respondsToSelector:NSSelectorFromString(@"switchToDictationInputModeWithTouch:")]) { how = @"switch"; ((void (*)(id, SEL, id))objc_msgSend)(dc, NSSelectorFromString(@"switchToDictationInputModeWithTouch:"), nil); }
            else if ([dc respondsToSelector:NSSelectorFromString(@"startDictation")]) { how = @"start"; ((void (*)(id, SEL))objc_msgSend)(dc, NSSelectorFromString(@"startDictation")); }
        } @catch (__unused id e) { how = @"error"; }
        gDictDebug = how;
    });
}
- (void)push:(UITextField *)tf {
    UISearchController *sc = [self sc];
    UISearchBar *bar = sc.searchBar;
    if (!bar) return;
    bar.text = tf.text ?: @"";
    id d = bar.delegate;
    if ([d respondsToSelector:@selector(searchBar:textDidChange:)]) [d searchBar:bar textDidChange:bar.text];
    if (sc.searchResultsUpdater && sc.searchResultsUpdater != d) [sc.searchResultsUpdater updateSearchResultsForSearchController:sc];
    else if (sc.searchResultsUpdater && ![d respondsToSelector:@selector(searchBar:textDidChange:)]) [sc.searchResultsUpdater updateSearchResultsForSearchController:sc];
}
- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    UISearchBar *bar = [self sc].searchBar;
    id d = bar.delegate;
    if ([d respondsToSelector:@selector(searchBarSearchButtonClicked:)]) [d searchBarSearchButtonClicked:bar];
    [tf resignFirstResponder];
    return YES;
}
- (void)endSearch {
    UITextField *tf = [self field];
    tf.text = @""; [tf resignFirstResponder];
    UISearchController *sc = [self sc];
    sc.searchBar.text = @"";
    id d = sc.searchBar.delegate;
    if ([d respondsToSelector:@selector(searchBarCancelButtonClicked:)]) [d searchBarCancelButtonClicked:sc.searchBar];
    sc.active = NO;
    self.searching = NO;
    UIWindow *w = KeyWin();
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{ StyleSearchPill(w); } completion:nil];
}
- (void)composeTap:(UIView *)b {
    [self up:b];
    if (self.searching) { [self endSearch]; return; }
    UIBarButtonItem *it = self.compose;
    if (it.target && it.action) ((void (*)(id, SEL, id))objc_msgSend)(it.target, it.action, it);
    else if (it.action) [UIApplication.sharedApplication sendAction:it.action to:nil from:it forEvent:nil];
}
@end
static UIViewController *SearchList(void) { return [M26Search shared].list; }
static UIButton *GlassCapsule(NSInteger tag, SEL action, SEL down) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.tag = tag; b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.shadowColor = UIColor.blackColor.CGColor; b.layer.shadowOpacity = 0.35; b.layer.shadowRadius = 14; b.layer.shadowOffset = CGSizeMake(0, 6);
    [b addTarget:[M26Search shared] action:action forControlEvents:UIControlEventTouchUpInside];
    [b addTarget:[M26Search shared] action:down forControlEvents:UIControlEventTouchDown];
    [b addTarget:[M26Search shared] action:@selector(up:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    return b;
}
static void PaintCapsule(UIButton *b, BOOL dark) {
    b.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:0.97] : [UIColor colorWithWhite:0.97 alpha:0.97];
    b.layer.shadowOpacity = dark ? 0.35 : 0.12;
    b.layer.cornerRadius = b.bounds.size.height / 2;
    RimFit(b, dark);
}
static void StyleSearchPill(UIWindow *w) {
    if (!w) return;
    UIButton *pill = (UIButton *)[w viewWithTag:SEARCH_TAG], *comp = (UIButton *)[w viewWithTag:SCOMPOSE_TAG];
    M26Search *S = [M26Search shared];
    UIViewController *vc = gSearchOn ? ListVC(w.rootViewController, 0) : nil;
    UINavigationController *nc = vc.navigationController;
    UISearchController *sc = vc.navigationItem.searchController;
    UIViewController *pres = vc.presentedViewController;
    BOOL show = vc && (!nc || nc.topViewController == vc) && (!pres || pres == sc) && !vc.isEditing && !gEntry.window;
    if (S.searching && vc && !sc.active) { S.searching = NO; ((UITextField *)[w viewWithTag:SEARCH_TAG + 4]).text = @""; }
    if (sc.active && !S.searching) show = NO;   // Messages' own search (not ours)
    BOOL searching = show && S.searching;
    if (searching && sc.searchBar.alpha > 0) sc.searchBar.alpha = 0;   // ours is at the bottom
    if (!sc.active && sc.searchBar.alpha < 1) sc.searchBar.alpha = 1;
    // the top compose button moves down next to the pill (and comes back when off)
    UINavigationItem *ni = vc.navigationItem ?: S.list.navigationItem;
    if (ni) {
        NSMutableArray *keep = [NSMutableArray array]; BOOL removed = NO;
        for (UIBarButtonItem *it in ni.rightBarButtonItems) { if (gSearchOn && IsComposeItem(it)) { S.compose = it; removed = YES; } else [keep addObject:it]; }
        if (removed) ni.rightBarButtonItems = keep;
        if (!gSearchOn && S.compose && ![ni.rightBarButtonItems containsObject:S.compose]) { ni.rightBarButtonItems = [@[S.compose] arrayByAddingObjectsFromArray:ni.rightBarButtonItems ?: @[]]; S.compose = nil; }
    }
    // glass left behind by a button that's gone or hidden
    for (UIView *v in [gStyled allObjects]) if (!v.window || v.hidden || v.alpha < 0.05) { [objc_getAssociatedObject(v, &kGlassKey) removeFromSuperview]; objc_setAssociatedObject(v, &kGlassKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); [gStyled removeObject:v]; }
    if (vc) S.list = vc;
    gSearchDebug = [NSString stringWithFormat:@"search: list=%@ show=%d sc=%d act=%d ours=%d compose=%d kb=%.0f dict=%@", vc ? NSStringFromClass([vc class]) : @"-", show, sc != nil, sc.active, S.searching, S.compose != nil, S.kbTop, gDictDebug];
    if (!gSearchOn) { [pill removeFromSuperview]; [comp removeFromSuperview]; return; }
    BOOL dark = IsDark(w);
    if (!pill) {
        pill = GlassCapsule(SEARCH_TAG, @selector(search:), @selector(down:));
        UIImageView *mag = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightMedium]]];
        mag.tag = 1; mag.contentMode = UIViewContentModeCenter; mag.userInteractionEnabled = NO; [pill addSubview:mag];
        UILabel *t = [UILabel new]; t.tag = 2; t.text = @"Search"; t.font = [UIFont systemFontOfSize:19]; t.userInteractionEnabled = NO; [pill addSubview:t];
        UIButton *mic = [UIButton buttonWithType:UIButtonTypeSystem];
        [mic setImage:[UIImage systemImageNamed:@"mic" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightRegular]] forState:UIControlStateNormal];
        mic.tag = 3; [mic addTarget:S action:@selector(mic:) forControlEvents:UIControlEventTouchUpInside]; [pill addSubview:mic];
        UITextField *tf = [UITextField new]; tf.tag = SEARCH_TAG + 4; tf.font = [UIFont systemFontOfSize:19];
        tf.returnKeyType = UIReturnKeySearch; tf.autocorrectionType = UITextAutocorrectionTypeNo; tf.delegate = S; tf.alpha = 0;
        [tf addTarget:S action:@selector(push:) forControlEvents:UIControlEventEditingChanged];
        [pill addSubview:tf];
        pill.alpha = 0; [w addSubview:pill];
    }
    if (!comp) {
        comp = GlassCapsule(SCOMPOSE_TAG, @selector(composeTap:), @selector(down:));
        comp.alpha = 0; [w addSubview:comp];
    }
    UITextField *tf = (UITextField *)[pill viewWithTag:SEARCH_TAG + 4];
    CGFloat W = w.bounds.size.width, H = w.bounds.size.height, h = searching ? 51 : 53, m = searching ? 10 : 30, gap = searching ? 12 : 14;
    CGFloat y = H - MAX(w.safeAreaInsets.bottom, 0) + 3 - h;
    if (w.safeAreaInsets.bottom < 10) y = H - 16 - h;
    if (searching && S.kbTop > 0) y = S.kbTop - 12 - h;
    BOOL hasComp = searching || S.compose != nil;
    CGRect cf = CGRectMake(W - m - h, y, h, h), pf = CGRectMake(m, y, hasComp ? CGRectGetMinX(cf) - gap - m : W - 2 * m, h);
    if (!CGRectEqualToRect(pill.frame, pf) && CGAffineTransformIsIdentity(pill.transform)) {
        pill.frame = pf;
        [pill viewWithTag:1].frame = CGRectMake(14, 0, 28, h);
        [pill viewWithTag:2].frame = CGRectMake(50, 0, pf.size.width - 100, h);
        tf.frame = CGRectMake(48, 0, pf.size.width - 104, h);
        [pill viewWithTag:3].frame = CGRectMake(pf.size.width - 54, 0, 44, h);
    }
    if (!CGRectEqualToRect(comp.frame, cf) && CGAffineTransformIsIdentity(comp.transform)) comp.frame = cf;
    NSString *ci = searching ? @"xmark" : @"square.and.pencil";
    if (![objc_getAssociatedObject(comp, "m26img") isEqual:ci]) {
        objc_setAssociatedObject(comp, "m26img", ci, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [comp setImage:[UIImage systemImageNamed:ci withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:searching ? 20 : 21 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    }
    UIColor *ink = Ink(w), *dim = [UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.55 : 0.45];
    ((UIImageView *)[pill viewWithTag:1]).tintColor = ink;
    ((UILabel *)[pill viewWithTag:2]).textColor = dim;
    [pill viewWithTag:3].tintColor = ink;
    tf.textColor = ink; tf.keyboardAppearance = dark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    if (!tf.attributedPlaceholder.length) tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: dim}];
    comp.tintColor = ink;
    tf.alpha = searching ? 1 : 0; tf.userInteractionEnabled = searching;
    [pill viewWithTag:2].alpha = searching ? 0 : 1;
    if (objc_getAssociatedObject(pill, "m26dk") == nil || [objc_getAssociatedObject(pill, "m26dk") boolValue] != dark || !CGSizeEqualToSize([objc_getAssociatedObject(pill, "m26sz") CGSizeValue], pill.bounds.size)) {
        objc_setAssociatedObject(pill, "m26dk", @(dark), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(pill, "m26sz", [NSValue valueWithCGSize:pill.bounds.size], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        PaintCapsule(pill, dark); PaintCapsule(comp, dark);
    }
    BOOL showComp = show && hasComp;
    for (UIView *v in @[pill, comp]) {
        BOOL on = v == pill ? show : showComp;
        CGFloat a = on ? 1 : 0;
        v.userInteractionEnabled = on;
        if (fabs(v.alpha - a) > 0.01 && ![v.layer animationForKey:@"opacity"]) [UIView animateWithDuration:0.25 animations:^{ v.alpha = a; }];
        if (on && w.subviews.lastObject != v && v.superview == w) [w bringSubviewToFront:v];
    }
    if (!show && tf.isFirstResponder) [tf resignFirstResponder];
    // rows can scroll out from under the pill
    if (vc && show) {
        UIScrollView *list = (UIScrollView *)Find(vc.view, ^BOOL(UIView *v) { return [v isKindOfClass:[UIScrollView class]] && v.bounds.size.height > H * 0.5; }, 300);
        CGFloat want = h + 16;
        if (list && objc_getAssociatedObject(list, "m26ins") == nil) {
            objc_setAssociatedObject(list, "m26ins", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIEdgeInsets in = list.contentInset; in.bottom += want; list.contentInset = in;
        }
    }
}

#pragma mark - glass bubbles + swipe to reply

static NSString *gBubbleDebug = @"bubbles: -";
static NSString *gReplyDebug = @"reply=-";
static UIColor *DeepBlue(void) { return [UIColor colorWithRed:0.04 green:0.10 blue:0.70 alpha:1]; }
// darker blue for my iMessages: the theme's blue (and reply blue) colors
static NSMapTable *gThemeOrig;   // "Class.sel" -> IMP
static id ThemeBlue(id self, SEL _cmd) {
    if (gBubblesOn) return @[DeepBlue(), DeepBlue()];
    for (Class c = object_getClass(self); c; c = class_getSuperclass(c)) {
        NSValue *v = [gThemeOrig objectForKey:[NSString stringWithFormat:@"%s.%s", class_getName(c), sel_getName(_cmd)]];
        if (v) return ((id (*)(id, SEL))[v pointerValue])(self, _cmd);
    }
    return nil;
}
static void HookThemes(void) {
    gThemeOrig = [NSMapTable strongToStrongObjectsMapTable];
    int n = objc_getClassList(NULL, 0);
    Class *all = (Class *)malloc(sizeof(Class) * n); n = objc_getClassList(all, n);
    int hooked = 0;
    for (int i = 0; i < n; i++) {
        const char *nm = class_getName(all[i]);
        if (strncmp(nm, "CKUITheme", 9) != 0) continue;
        for (NSString *sn in @[@"blue_balloonColors", @"reply_blue_balloonColors"]) {
            SEL sel = NSSelectorFromString(sn);
            unsigned int mc = 0; Method *ms = class_copyMethodList(all[i], &mc); BOOL own = NO;
            for (unsigned int k = 0; k < mc; k++) if (method_getName(ms[k]) == sel) own = YES;
            free(ms);
            if (!own) continue;
            IMP o = NULL;
            MSHookMessageEx(all[i], sel, (IMP)ThemeBlue, &o);
            if (o) { [gThemeOrig setObject:[NSValue valueWithPointer:(const void *)o] forKey:[NSString stringWithFormat:@"%s.%@", nm, sn]]; hooked++; }
        }
    }
    free(all);
    gBubbleDebug = [NSString stringWithFormat:@"bubbles: theme hooks=%d", hooked];
}
// received bubbles: a thin glass rim, bright along the top (exact bubble + tail shape)
static char kRimKey;
static void BubbleRim(UIView *b) {
    UIView *rim = objc_getAssociatedObject(b, &kRimKey);
    BOOL gray = NO;
    @try { id c = [b valueForKey:@"color"]; gray = c ? [c intValue] == -1 : NO; } @catch (__unused id e) {}
    if (!gray) { @try { gray = [[b valueForKey:@"orientation"] intValue] == 0; } @catch (__unused id e) {} }
    // big emoji (no bubble behind them): no rim
    @try { if (![[b valueForKey:@"hasBackground"] boolValue]) gray = NO; } @catch (__unused id e) {}
    if ([NSStringFromClass([b class]) containsString:@"Emoji"]) gray = NO;
    UIView *host = b.superview;
    if (!gBubblesOn || !gray || !host || b.bounds.size.width < 10) { [rim removeFromSuperview]; return; }
    BOOL dark = IsDark(b);
    if (!rim) {
        rim = [UIView new]; rim.userInteractionEnabled = NO;
        CAGradientLayer *gl = [CAGradientLayer layer]; gl.name = @"g";
        gl.startPoint = CGPointMake(0.5, 0); gl.endPoint = CGPointMake(0.5, 1);
        CAShapeLayer *m = [CAShapeLayer layer]; m.fillColor = UIColor.clearColor.CGColor; m.strokeColor = UIColor.blackColor.CGColor; m.lineWidth = 1.3;
        gl.mask = m;
        [rim.layer addSublayer:gl];
        objc_setAssociatedObject(b, &kRimKey, rim, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // on top of the bubble (only the outline is drawn, so the text stays clear)
    if (rim.superview != host || [host.subviews indexOfObject:rim] < [host.subviews indexOfObject:b]) [host insertSubview:rim aboveSubview:b];
    BOOL tail = NO; @try { tail = [[b valueForKey:@"hasTail"] boolValue]; } @catch (__unused id e) {}
    // the bubble fills the view, except the room kept for the tail on the left
    CGRect body = b.bounds;
    body.origin.x += 5.5; body.size.width -= 5.5;
    body = CGRectInset(body, 0.65, 0.65);
    CGFloat x0 = CGRectGetMinX(body), x1 = CGRectGetMaxX(body), y0 = CGRectGetMinY(body), y1 = CGRectGetMaxY(body);
    CGFloat r = MIN(17.5, body.size.height / 2);
    UIBezierPath *pth = [UIBezierPath bezierPath];
    [pth moveToPoint:CGPointMake(x0 + r, y0)];
    [pth addLineToPoint:CGPointMake(x1 - r, y0)];
    [pth addArcWithCenter:CGPointMake(x1 - r, y0 + r) radius:r startAngle:-M_PI_2 endAngle:0 clockwise:YES];
    [pth addLineToPoint:CGPointMake(x1, y1 - r)];
    [pth addArcWithCenter:CGPointMake(x1 - r, y1 - r) radius:r startAngle:0 endAngle:M_PI_2 clockwise:YES];
    if (tail) {
        // iMessage tail curling out of the bottom-left corner
        [pth addLineToPoint:CGPointMake(x0 + 11, y1)];
        [pth addQuadCurveToPoint:CGPointMake(x0 - 5.5, y1 + 0.5) controlPoint:CGPointMake(x0 + 3, y1 + 1.5)];
        [pth addQuadCurveToPoint:CGPointMake(x0, y1 - 9) controlPoint:CGPointMake(x0 + 0.5, y1 - 2.5)];
    } else {
        [pth addLineToPoint:CGPointMake(x0 + r, y1)];
        [pth addArcWithCenter:CGPointMake(x0 + r, y1 - r) radius:r startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    }
    [pth addLineToPoint:CGPointMake(x0, y0 + r)];
    [pth addArcWithCenter:CGPointMake(x0 + r, y0 + r) radius:r startAngle:M_PI endAngle:M_PI * 1.5 clockwise:YES];
    [pth closePath];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (!CGRectEqualToRect(rim.frame, b.frame)) rim.frame = b.frame;
    CAGradientLayer *gl = (CAGradientLayer *)rim.layer.sublayers.firstObject;
    gl.frame = CGRectInset(rim.bounds, -8, -8);
    CAShapeLayer *m = (CAShapeLayer *)gl.mask;
    m.frame = gl.bounds;
    [pth applyTransform:CGAffineTransformMakeTranslation(8, 8)];
    m.path = pth.CGPath;
    gl.colors = @[(id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.42 : 0.16].CGColor, (id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.16 : 0.08].CGColor, (id)[UIColor colorWithWhite:dark ? 1 : 0 alpha:dark ? 0.26 : 0.10].CGColor];
    gl.locations = @[@0, @0.5, @1];
    [CATransaction commit];
    rim.hidden = b.hidden; rim.alpha = b.alpha; rim.transform = b.transform;
}
// bubbles draw their corners see-through (the "opaque mask" painted them black over a background)
static void (*origOpaqueA)(id, SEL, BOOL);
static void OpaqueA(id self, SEL _cmd, BOOL v) { origOpaqueA(self, _cmd, NO); }
static void (*origOpaqueB)(id, SEL, BOOL);
static void OpaqueB(id self, SEL _cmd, BOOL v) { origOpaqueB(self, _cmd, NO); }
static BOOL NoOpaque(id self, SEL _cmd) { return NO; }
static void (*origBalloonLayout)(id, SEL);
static void BalloonLayout(UIView *self, SEL _cmd) { origBalloonLayout(self, _cmd); @try { BubbleRim(self); } @catch (__unused id e) {} }
static void (*origBalloonFrame)(id, SEL, CGRect);
static void BalloonFrame(UIView *self, SEL _cmd, CGRect f) { origBalloonFrame(self, _cmd, f); if (objc_getAssociatedObject(self, &kRimKey)) @try { BubbleRim(self); } @catch (__unused id e) {} }
static void (*origBalloonCenter)(id, SEL, CGPoint);
static void BalloonCenter(UIView *self, SEL _cmd, CGPoint c) { origBalloonCenter(self, _cmd, c); if (objc_getAssociatedObject(self, &kRimKey)) @try { BubbleRim(self); } @catch (__unused id e) {} }
static void (*origBalloonAlpha)(id, SEL, CGFloat);
static void BalloonAlpha(UIView *self, SEL _cmd, CGFloat a) { origBalloonAlpha(self, _cmd, a); UIView *r = objc_getAssociatedObject(self, &kRimKey); if (r) r.alpha = a; }
static void (*origBalloonHidden)(id, SEL, BOOL);
static void BalloonHidden(UIView *self, SEL _cmd, BOOL h) { origBalloonHidden(self, _cmd, h); UIView *r = objc_getAssociatedObject(self, &kRimKey); if (r) r.hidden = h; }
static void (*origBalloonMove)(id, SEL);
static void BalloonMove(UIView *self, SEL _cmd) { origBalloonMove(self, _cmd); if (!self.superview) [objc_getAssociatedObject(self, &kRimKey) removeFromSuperview]; }

// Swipe right on any message to reply: the message slides with your finger, a reply
// arrow grows in behind it, and past the line it pops (haptic) and opens the reply.
@interface M26Swipe : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@property (nonatomic, weak) UICollectionViewCell *cell;
@property (nonatomic, weak) UIView *balloon;
@property (nonatomic, strong) UIImageView *arrow;
@property (nonatomic) BOOL armed;
@end
static UIView *BalloonIn(UIView *root) {
    Class B = NSClassFromString(@"CKBalloonView");
    return Find(root, ^BOOL(UIView *v) { return B && [v isKindOfClass:B] && !v.hidden && v.bounds.size.width > 20; }, 200);
}
@implementation M26Swipe
+ (instancetype)shared { static M26Swipe *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Swipe new]; }); return t; }
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    if (!gSwipeOn) return NO;
    CGPoint v = [g velocityInView:g.view];
    if (v.x <= 0 || fabs(v.x) < fabs(v.y) * 1.6) return NO;
    UICollectionView *cv = (UICollectionView *)g.view;
    NSIndexPath *ip = [cv indexPathForItemAtPoint:[g locationInView:cv]];
    UICollectionViewCell *c = ip ? [cv cellForItemAtIndexPath:ip] : nil;
    UIView *b = c ? BalloonIn(c) : nil;
    if (!b) return NO;
    self.cell = c; self.balloon = b;
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return NO; }
- (void)pan:(UIPanGestureRecognizer *)g {
    UICollectionViewCell *c = self.cell; UIView *b = self.balloon;
    if (!c || !b) return;
    CGFloat t = MAX(0, [g translationInView:g.view].x);
    CGFloat x = t < 70 ? t : 70 + (t - 70) * 0.35;   // rubber band past the line
    x = MIN(x, 120);
    if (g.state == UIGestureRecognizerStateBegan) {
        self.armed = NO;
        if (!self.arrow) {
            self.arrow = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrowshape.turn.up.left.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]]];
            self.arrow.contentMode = UIViewContentModeCenter; self.arrow.layer.cornerRadius = 17; self.arrow.layer.cornerCurve = kCACornerCurveContinuous;
        }
        BOOL dark = IsDark(c);
        self.arrow.tintColor = Ink(c);
        self.arrow.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:0.97] : [UIColor colorWithWhite:0.93 alpha:0.97];
        self.arrow.transform = CGAffineTransformIdentity; [self.arrow.layer removeAllAnimations];
        self.arrow.bounds = CGRectMake(0, 0, 34, 34); self.arrow.alpha = 0;
        [c.superview insertSubview:self.arrow belowSubview:c];
    }
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        c.transform = CGAffineTransformMakeTranslation(x, 0);
        CGRect bf = [b convertRect:b.bounds toView:c.superview];
        CGFloat p = MIN(1, x / 70);
        self.arrow.center = CGPointMake(CGRectGetMinX(bf) - x + MAX(22, x / 2), CGRectGetMidY(bf));
        self.arrow.alpha = p;
        CGFloat sc = 0.3 + 0.7 * p;
        if (!self.armed) self.arrow.transform = CGAffineTransformMakeScale(sc, sc);
        BOOL armed = t >= 70;
        if (armed != self.armed) {
            self.armed = armed;
            if (armed) [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self.arrow.transform = armed ? CGAffineTransformMakeScale(1.18, 1.18) : CGAffineTransformMakeScale(sc, sc); } completion:nil];
        }
        return;
    }
    BOOL go = g.state == UIGestureRecognizerStateEnded && self.armed;
    UIImageView *ar = self.arrow;
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        c.transform = CGAffineTransformIdentity;
        ar.alpha = 0; ar.transform = go ? CGAffineTransformMakeScale(1.5, 1.5) : CGAffineTransformMakeScale(0.3, 0.3);
    } completion:^(__unused BOOL d) { [ar removeFromSuperview]; }];
    if (go) {
        UICollectionView *cv = (UICollectionView *)g.view;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.22 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self replyTo:b inCollection:cv cell:c]; });
    }
}
- (void)replyTo:(UIView *)b inCollection:(UICollectionView *)cv cell:(UICollectionViewCell *)c {
    NSMutableArray *cands = [NSMutableArray array];
    id tvc = cv.delegate;
    if (tvc) { [cands addObject:tvc]; @try { id d = [tvc valueForKey:@"delegate"]; if (d) [cands addObject:d]; } @catch (__unused id e) {} }
    for (UIResponder *r = cv; r; r = r.nextResponder) [cands addObject:r];
    // the message's chat item, then the chat's own "Reply" (same as hold -> Reply)
    id item = nil;
    SEL ci = NSSelectorFromString(@"chatItemForCell:");
    for (id o in cands) if ([o respondsToSelector:ci]) { item = ((id (*)(id, SEL, id))objc_msgSend)(o, ci, c); if (item) break; }
    if (!item) {
        NSIndexPath *ip = [cv indexPathForCell:c];
        for (id d in cands) { @try { NSArray *items = [d valueForKey:@"chatItems"]; if ([items isKindOfClass:[NSArray class]] && ip && ip.item < (NSInteger)items.count) { item = items[ip.item]; break; } } @catch (__unused id e) {} }
    }
    SEL s2 = NSSelectorFromString(@"showInlineReplyControllerForChatItem:presentKeyboard:");
    NSString *how = @"none";
    if (item) for (id o in cands) if ([o respondsToSelector:s2]) {
        @try { ((void (*)(id, SEL, id, BOOL))objc_msgSend)(o, s2, item, YES); how = [NSString stringWithFormat:@"item(%@)", NSStringFromClass([item class])]; } @catch (__unused id e) { how = @"item-error"; }
        break;
    }
    if ([how isEqualToString:@"none"]) {
        SEL s1 = NSSelectorFromString(@"balloonViewShowInlineReply:");
        for (id o in cands) if ([o respondsToSelector:s1]) { ((void (*)(id, SEL, id))objc_msgSend)(o, s1, b); how = @"balloon"; break; }
    }
    gReplyDebug = [NSString stringWithFormat:@"reply=%@ item=%d", how, item != nil];
}
@end
static void InstallSwipe(UIWindow *w) {
    if (!gSwipeOn) return;
    UIView *e = gEntry;
    if (!e.window) return;
    UICollectionView *cv = (UICollectionView *)Find(w, ^BOOL(UIView *v) { return [v isKindOfClass:[UICollectionView class]] && [NSStringFromClass([v class]) containsString:@"Transcript"]; }, 3000);
    if (!cv || objc_getAssociatedObject(cv, "m26swipe")) return;
    objc_setAssociatedObject(cv, "m26swipe", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:[M26Swipe shared] action:@selector(pan:)];
    p.delegate = [M26Swipe shared];
    [cv addGestureRecognizer:p];
    [cv.panGestureRecognizer requireGestureRecognizerToFail:p];
}

#pragma mark - contact details page (iOS 26 look)

#define DGLASS_TAG 0x4D323654
#define DTABS_TAG  0x4D323655
static NSString *gDetDebug = @"details: -";
static __weak UIView *gInfoTile;
static __weak UIScrollView *gDetTable;
static __weak UICollectionView *gDetChild;
static NSInteger gChildRowSection = -1, gHeadRowSection = -1;
static NSString *gDetTab = @"Info";
static NSInteger gHeaderSection = -1;
static UIViewController *DetailsVC(UIViewController *vc, int depth) {
    if (!vc || depth > 14) return nil;
    if ([NSStringFromClass([vc class]) containsString:@"DetailsController"] && vc.viewIfLoaded.window) return vc;
    UIViewController *r = DetailsVC(vc.presentedViewController, depth + 1); if (r) return r;
    for (UIViewController *c in vc.childViewControllers) { r = DetailsVC(c, depth + 1); if (r) return r; }
    return nil;
}
// press a view that isn't a button: its control, or its tap gesture's target
static NSString *gEditDebug = @"";
static BOOL ForwardTap(UIView *v) {
    NSMutableString *log = [NSMutableString string];
    // a control inside it, or one it sits in
    UIControl *c = (UIControl *)Find(v, ^BOOL(UIView *x) { return [x isKindOfClass:[UIControl class]]; }, 40);
    int up = 0;
    for (UIView *p = v; p && !c && up < 4; p = p.superview, up++) if ([p isKindOfClass:[UIControl class]]) c = (UIControl *)p;
    if (c) { [log appendFormat:@"ctl=%@ ", NSStringFromClass([c class])]; [c sendActionsForControlEvents:UIControlEventTouchUpInside]; [c sendActionsForControlEvents:UIControlEventPrimaryActionTriggered]; gEditDebug = log; return YES; }
    NSMutableArray *views = [NSMutableArray array];
    for (UIView *p = v; p && views.count < 5; p = p.superview) [views addObject:p];
    NSMutableArray *sub = [NSMutableArray arrayWithArray:v.subviews]; int gs = 0;
    while (sub.count && gs++ < 40) { UIView *x = sub.lastObject; [sub removeLastObject]; [views addObject:x]; [sub addObjectsFromArray:x.subviews]; }
    for (UIView *p in views) for (UIGestureRecognizer *g in p.gestureRecognizers) {
        [log appendFormat:@"%@@%@ ", NSStringFromClass([g class]), NSStringFromClass([p class])];
        if (![g isKindOfClass:[UITapGestureRecognizer class]] || !g.enabled) continue;
        NSArray *ts = nil; @try { ts = [g valueForKey:@"_targets"]; } @catch (__unused id e) {}
        for (id t in ts) {
            Ivar ti = class_getInstanceVariable([t class], "_target"), ai = class_getInstanceVariable([t class], "_action");
            if (!ti || !ai) continue;
            id target = object_getIvar(t, ti);
            SEL act = *(SEL *)((uint8_t *)(__bridge void *)t + ivar_getOffset(ai));
            if (target && act && [target respondsToSelector:act]) {
                [log appendFormat:@"-> %@ %@", NSStringFromClass([target class]), NSStringFromSelector(act)];
                gEditDebug = log;
                ((void (*)(id, SEL, id))objc_msgSend)(target, act, g); return YES;
            }
        }
    }
    gEditDebug = log.length ? log : @"nothing to press";
    return NO;
}

// Tabs: each section of the page belongs to one tab (by its controller's title/class)
static NSString *SectionKind(id ctl) {
    NSString *t = nil; @try { if ([[ctl class] respondsToSelector:@selector(sectionTitle)]) t = [[ctl class] performSelector:@selector(sectionTitle)]; } @catch (__unused id e) {}
    NSString *k = [[NSString stringWithFormat:@"%@ %@", NSStringFromClass([ctl class]), [t isKindOfClass:[NSString class]] ? t : @""] lowercaseString];
    if ([k containsString:@"collab"]) return @"Collaboration";
    if ([k containsString:@"link"]) return @"Links";
    if ([k containsString:@"document"] || [k containsString:@"pass"]) return @"Documents";
    if ([k containsString:@"photo"] || [k containsString:@"attachment"] || [k containsString:@"image"]) return @"Photos";
    if ([k containsString:@"location"]) return @"Info";
    return @"Info";
}
static NSString *gSnapDebug = @"";
static id (*origSnapA)(id, SEL);
static id (*origSnapB)(id, SEL);
static id FilterSnap(id self, id snap) {
    if (!gTopOn || ![NSStringFromClass([self class]) containsString:@"Details"] || ![snap respondsToSelector:@selector(sectionIdentifiers)]) return snap;
    NSArray *ctls = nil; @try { ctls = [self valueForKey:@"searchControllers"]; } @catch (__unused id e) {}
    NSArray *ids = [snap sectionIdentifiers];
    NSMutableArray *drop = [NSMutableArray array], *log = [NSMutableArray array];
    for (NSUInteger i = 0; i < ids.count; i++) {
        id sid = ids[i];
        id ctl = nil;
        for (id c in ctls) {
            id cs = nil; @try { if ([[c class] respondsToSelector:@selector(sectionIdentifier)]) cs = [[c class] performSelector:@selector(sectionIdentifier)]; } @catch (__unused id e) {}
            if (cs && [cs isEqual:sid]) { ctl = c; break; }
        }
        if (!ctl) for (id c in ctls) { @try { if ([[c valueForKey:@"sectionIndex"] unsignedIntegerValue] == i) { ctl = c; break; } } @catch (__unused id e) {} }
        NSString *kind = ctl ? SectionKind(ctl) : @"Info";
        NSUInteger si = i; @try { if (ctl) si = [[ctl valueForKey:@"sectionIndex"] unsignedIntegerValue]; } @catch (__unused id e) {}
        BOOL keep = [kind isEqualToString:gDetTab] || (NSInteger)si == gHeaderSection;
        [log addObject:[NSString stringWithFormat:@"%@:%@%@", ctl ? [NSStringFromClass([ctl class]) stringByReplacingOccurrencesOfString:@"SearchController" withString:@""] : [sid description], kind, keep ? @"" : @"-"]];
        if (!keep) [drop addObject:sid];
    }
    gSnapDebug = [log componentsJoinedByString:@" "];
    // empty those sections (removing them shifts Messages' section numbers -> crash)
    for (id sid in drop) { NSArray *items = [snap itemIdentifiersInSectionWithIdentifier:sid]; if (items.count) [snap deleteItemsWithIdentifiers:items]; }
    return snap;
}
// hidden sections get a blank layout (no header, no card)
static id (*origLayA)(id, SEL, id, id);
static id (*origLayB)(id, SEL, id, id);
static BOOL HideCtl(id self, id ctl) {
    if (!gTopOn || ![NSStringFromClass([self class]) containsString:@"Details"] || !ctl) return NO;
    NSInteger si = -1; @try { si = [[ctl valueForKey:@"sectionIndex"] integerValue]; } @catch (__unused id e) {}
    if (si == gHeaderSection) return NO;
    return ![SectionKind(ctl) isEqualToString:gDetTab];
}
static id BlankSection(void) {
    NSCollectionLayoutSize *sz = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension absoluteDimension:1]];
    NSCollectionLayoutItem *it = [NSCollectionLayoutItem itemWithLayoutSize:sz];
    NSCollectionLayoutGroup *g = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:sz subitems:@[it]];
    return [NSCollectionLayoutSection sectionWithGroup:g];
}
static id LayA(id self, SEL _cmd, id ctl, id env) { if (HideCtl(self, ctl)) return BlankSection(); return origLayA(self, _cmd, ctl, env); }
static id LayB(id self, SEL _cmd, id ctl, id env) { if (HideCtl(self, ctl)) return BlankSection(); return origLayB(self, _cmd, ctl, env); }
static id SnapA(id self, SEL _cmd) { return FilterSnap(self, origSnapA(self, _cmd)); }
static id SnapB(id self, SEL _cmd) { return FilterSnap(self, origSnapB(self, _cmd)); }
static void ReloadDetailSections(void) {
    UITableView *tb = (UITableView *)gDetTable;
    if ([tb isKindOfClass:[UITableView class]]) [tb reloadData];
    UIScrollView *cv = gDetChild;
    for (UIResponder *r = cv; r; r = r.nextResponder) if ([r respondsToSelector:@selector(reloadData)] && [r isKindOfClass:[UIViewController class]]) { [(id)r performSelector:@selector(reloadData)]; return; }
    id d = [(id)cv delegate];
    if ([d isKindOfClass:[UIViewController class]] && [d respondsToSelector:@selector(reloadData)]) [d performSelector:@selector(reloadData)];
}

// Outer page (table): Info rows only on the Info tab; the media part only on the others.
static BOOL HideRowSection(NSInteger sct) {
    if (!gTopOn || sct == gHeadRowSection) return NO;
    BOOL info = [gDetTab isEqualToString:@"Info"];
    if (sct == gChildRowSection) return info || [gDetTab isEqualToString:@"Backgrounds"];
    return !info && gChildRowSection >= 0;
}
static BOOL IsSharedFooter(UIView *v) { return v && Find(v, ^BOOL(UIView *y) { return [y isKindOfClass:[UILabel class]] && [((UILabel *)y).text hasPrefix:@"Content shared"]; }, 30) != nil; }
static NSInteger (*origRows)(id, SEL, id, NSInteger);
static NSInteger DetRows(id self, SEL _cmd, UITableView *tv, NSInteger sct) { NSInteger n = origRows(self, _cmd, tv, sct); return HideRowSection(sct) ? 0 : n; }
static id (*origFootV)(id, SEL, id, NSInteger);
static id DetFootV(id self, SEL _cmd, UITableView *tv, NSInteger sct) { if (HideRowSection(sct)) return nil; id v = origFootV(self, _cmd, tv, sct); return IsSharedFooter(v) ? nil : v; }
static CGFloat (*origFootH)(id, SEL, id, NSInteger);
static CGFloat DetFootH(id self, SEL _cmd, UITableView *tv, NSInteger sct) {
    if (HideRowSection(sct)) return 0.01;
    if (origFootV && IsSharedFooter(origFootV(self, @selector(tableView:viewForFooterInSection:), tv, sct))) return 0.01;
    return origFootH(self, _cmd, tv, sct);
}
static id (*origHeadV)(id, SEL, id, NSInteger);
static id DetHeadV(id self, SEL _cmd, UITableView *tv, NSInteger sct) { return HideRowSection(sct) ? nil : origHeadV(self, _cmd, tv, sct); }
static CGFloat (*origHeadH)(id, SEL, id, NSInteger);
static CGFloat DetHeadH(id self, SEL _cmd, UITableView *tv, NSInteger sct) { return HideRowSection(sct) ? 0.01 : origHeadH(self, _cmd, tv, sct); }
static NSString *(*origFootT)(id, SEL, id, NSInteger);
static NSString *DetFootT(id self, SEL _cmd, UITableView *tv, NSInteger sct) { if (HideRowSection(sct)) return nil; NSString *t = origFootT(self, _cmd, tv, sct); return [t hasPrefix:@"Content shared"] ? nil : t; }
static void HookDetailsTable(void) {
    Class D = NSClassFromString(@"CKDetailsController");
    if (!D) return;
    #define DH(sel, fn, orig) if (class_getInstanceMethod(D, sel)) MSHookMessageEx(D, sel, (IMP)fn, (IMP *)&orig)
    DH(@selector(tableView:numberOfRowsInSection:), DetRows, origRows);
    DH(@selector(tableView:viewForFooterInSection:), DetFootV, origFootV);
    DH(@selector(tableView:heightForFooterInSection:), DetFootH, origFootH);
    DH(@selector(tableView:viewForHeaderInSection:), DetHeadV, origHeadV);
    DH(@selector(tableView:heightForHeaderInSection:), DetHeadH, origHeadH);
    DH(@selector(tableView:titleForFooterInSection:), DetFootT, origFootT);
}
@interface M26Details : NSObject
+ (instancetype)shared;
@end
@implementation M26Details
+ (instancetype)shared { static M26Details *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Details new]; }); return t; }
- (void)edit:(id)sender { UIView *t = gInfoTile; if (!t) gEditDebug = @"no info tile"; else ForwardTap(t); }
- (void)tab:(UIButton *)b {
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    gDetTab = [b titleForState:UIControlStateNormal];
    @try { ReloadDetailSections(); } @catch (__unused id e) {}
    UICollectionView *cv = gDetChild;
    [cv.collectionViewLayout invalidateLayout];
    UIScrollView *sv = gDetTable;
    [sv setContentOffset:CGPointMake(0, -sv.adjustedContentInset.top) animated:YES];
}
@end

#define DPLATE_TAG 0x4D323656
static char kCardKey;
static BOOL CardColor(UIColor *c) {
    if (!c) return NO;
    CGFloat r, g, b, a;
    if (![c getRed:&r green:&g blue:&b alpha:&a]) return NO;
    if (a < 0.5 || fabs(r - g) > 0.04 || fabs(g - b) > 0.06) return NO;
    return (r > 0.08 && r < 0.32) || r > 0.94;
}
// Every card (grouped rows, photo / link boxes) becomes one dark glass plate with a
// bright rim, on a black page with a soft blue glow.
static void CardGlass(UIView *root) {
    UIScrollView *sc = gDetTable;
    if (!sc || ![sc isDescendantOfView:root]) return;
    CGFloat W = root.bounds.size.width;
    BOOL dark = IsDark(root);
    // page
    UIColor *page = dark ? UIColor.blackColor : [UIColor colorWithWhite:0.95 alpha:1];
    if (![root.backgroundColor isEqual:page]) root.backgroundColor = page;
    for (UIView *p = sc; p && p != root.superview; p = p.superview) if (p != root && p.backgroundColor && CGColorGetAlpha(p.backgroundColor.CGColor) > 0) p.backgroundColor = UIColor.clearColor;
    UIView *glow = [root viewWithTag:DPLATE_TAG + 50];
    if (!glow && dark) {
        glow = [UIView new]; glow.tag = DPLATE_TAG + 50; glow.userInteractionEnabled = NO;
        for (int i = 0; i < 2; i++) {
            CAGradientLayer *gl = [CAGradientLayer layer]; gl.type = kCAGradientLayerRadial;
            gl.colors = @[(id)[UIColor colorWithRed:0.12 green:0.2 blue:0.75 alpha:i ? 0.22 : 0.3].CGColor, (id)[UIColor colorWithRed:0.1 green:0.15 blue:0.6 alpha:0].CGColor];
            gl.startPoint = CGPointMake(0.5, 0.5); gl.endPoint = CGPointMake(1, 1);
            gl.name = i ? @"b" : @"a";
            [glow.layer addSublayer:gl];
        }
        [root insertSubview:glow atIndex:0];
    }
    if (glow) {
        glow.hidden = !dark;
        if (!CGRectEqualToRect(glow.frame, root.bounds)) {
            glow.frame = root.bounds;
            for (CAGradientLayer *gl in glow.layer.sublayers) gl.frame = [gl.name isEqualToString:@"a"] ? CGRectMake(W * 0.35, root.bounds.size.height * 0.28, W * 0.9, W * 0.9) : CGRectMake(-W * 0.3, root.bounds.size.height * 0.62, W * 0.9, W * 0.9);
        }
        if (root.subviews.firstObject != glow) [root sendSubviewToBack:glow];
    }
    // no gray anywhere (cell backgrounds, card layers, the header box, media boxes)
    NSMutableArray *st = [NSMutableArray arrayWithArray:sc.subviews]; int g = 0;
    while (st.count && g++ < 5000) { UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == DPLATE_TAG || [v isKindOfClass:[UIImageView class]] || [v isKindOfClass:[UILabel class]] || [v isKindOfClass:[UIControl class]]) continue;
        if (@available(iOS 14.0, *)) if ([v isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *c = (UITableViewCell *)v;
            if (!objc_getAssociatedObject(c, &kCardKey)) { objc_setAssociatedObject(c, &kCardKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); c.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration]; }
            if (c.backgroundColor && CGColorGetAlpha(c.backgroundColor.CGColor) > 0) c.backgroundColor = UIColor.clearColor;
        }
        CGSize z = v.bounds.size;
        if (z.width >= W - 100 && z.height >= 20) {
            if (CardColor(v.backgroundColor)) v.backgroundColor = UIColor.clearColor;
            if (v.layer.backgroundColor && CardColor([UIColor colorWithCGColor:v.layer.backgroundColor])) v.layer.backgroundColor = nil;
        }
        if ([v isKindOfClass:[UICollectionReusableView class]] && ![v isKindOfClass:[UICollectionViewCell class]] && v.layer.backgroundColor) v.layer.backgroundColor = nil;
        [st addObjectsFromArray:v.subviews];
    }
    // "Content shared in this conversation…" note: hidden
    { UILabel *n = (UILabel *)Find(sc, ^BOOL(UIView *y) { return [y isKindOfClass:[UILabel class]] && [((UILabel *)y).text hasPrefix:@"Content shared"]; }, 3000);
      if (n) { UIView *box = n; while (box.superview && box.superview != sc && ![box isKindOfClass:[UITableViewHeaderFooterView class]] && ![box isKindOfClass:[UITableViewCell class]]) box = box.superview; if (!box.hidden) box.hidden = YES; } }
    // glass plates: one per Info card (a table section's rows), none on the header or the media
    NSMutableDictionary *bySect = [NSMutableDictionary dictionary];
    UITableView *tb = [sc isKindOfClass:[UITableView class]] ? (UITableView *)sc : nil;
    for (UITableViewCell *c in tb.visibleCells) {
        NSIndexPath *ip = [tb indexPathForCell:c];
        if (!ip || ip.section == gHeadRowSection || ip.section == gChildRowSection || c.hidden) continue;
        if (Find(c, ^BOOL(UIView *y) { return [y isKindOfClass:[UILabel class]] && [((UILabel *)y).text hasPrefix:@"Content shared"]; }, 60)) continue;
        NSValue *old = bySect[@(ip.section)];
        CGRect r = c.frame;
        bySect[@(ip.section)] = [NSValue valueWithCGRect:old ? CGRectUnion(old.CGRectValue, r) : r];
    }
    NSMutableArray *merged = [NSMutableArray array];
    for (NSNumber *k in [bySect.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        CGRect r = [bySect[k] CGRectValue];
        // the rows span the table; the card is inset like iOS
        CGFloat inset = tb.layoutMargins.left > 8 ? tb.layoutMargins.left : 20;
        r = CGRectMake(MAX(r.origin.x, inset), r.origin.y, MIN(r.size.width, tb.bounds.size.width - 2 * inset), r.size.height);
        [merged addObject:[NSValue valueWithCGRect:r]];
    }
    NSMutableArray *plates = [NSMutableArray array];
    for (UIView *x in sc.subviews) if (x.tag == DPLATE_TAG) [plates addObject:x];
    for (NSUInteger i = 0; i < merged.count; i++) {
        UIView *pl = i < plates.count ? plates[i] : nil;
        if (!pl) { pl = [UIView new]; pl.tag = DPLATE_TAG; pl.userInteractionEnabled = NO; pl.layer.cornerCurve = kCACornerCurveContinuous; [sc insertSubview:pl atIndex:0]; }
        CGRect r = [merged[i] CGRectValue];
        pl.hidden = NO;
        pl.backgroundColor = dark ? [UIColor colorWithRed:0.115 green:0.115 blue:0.125 alpha:0.94] : [UIColor colorWithWhite:1 alpha:0.94];
        if (!CGRectEqualToRect(pl.frame, r)) { pl.frame = r; pl.layer.cornerRadius = MIN(26, r.size.height / 2); RimFit(pl, dark); }
        if (sc.subviews.firstObject != pl && [sc.subviews indexOfObject:pl] > i) [sc insertSubview:pl atIndex:i];
    }
    for (NSUInteger i = merged.count; i < plates.count; i++) ((UIView *)plates[i]).hidden = YES;
}
static UIBarButtonItem *GlassTextItem(NSString *t, id target, SEL a) { return [[UIBarButtonItem alloc] initWithTitle:t style:UIBarButtonItemStylePlain target:target action:a]; }
static void StyleBgTab(UIViewController *vc);
static void StyleDetails(UIWindow *w) {
    UIViewController *vc = gTopOn ? DetailsVC(w.rootViewController, 0) : nil;
    if (!vc) { gDetDebug = @"details: -"; gDetTab = @"Info"; gHeadRowSection = gChildRowSection = -1; return; }
    UIView *root = vc.view;
    CGFloat W = root.bounds.size.width;
    // the action tiles: call / video / mail / info (found by their labels)
    NSMutableDictionary *tiles = [NSMutableDictionary dictionary];
    NSArray *names = @[@"call", @"video", @"mail", @"info", @"message"];
    BOOL foundTable = NO;
    NSMutableArray *st = [NSMutableArray arrayWithObject:root]; int g = 0;
    while (st.count && g++ < 3000) { UIView *v = st.lastObject; [st removeLastObject];
        if ([v isKindOfClass:[UILabel class]]) {
            NSString *t = ((UILabel *)v).text.lowercaseString;
            if (t && [names containsObject:t] && !tiles[t]) {
                UIView *tile = nil;
                for (UIView *p = v.superview; p && p != root; p = p.superview) {
                    CGSize z = p.bounds.size;
                    if (z.width >= 55 && z.width <= 140 && z.height >= 44 && z.height <= 100) tile = p;
                    if (z.width > 140) break;
                }
                if (tile) tiles[t] = @{@"tile": tile, @"label": v};
            }
        }
        if ([v isKindOfClass:[UITableView class]] && !foundTable) { gDetTable = (UIScrollView *)v; foundTable = YES; }
        if ([v isKindOfClass:[UICollectionView class]] && [NSStringFromClass([v class]) containsString:@"Search"]) gDetChild = (UICollectionView *)v;
        [st addObjectsFromArray:v.subviews];
    }
    // top bar: Done -> glass back chevron (left), info -> Edit (right)
    UINavigationItem *ni = vc.navigationItem;
    if (!objc_getAssociatedObject(ni, "m26det")) {
        UIBarButtonItem *done = ni.rightBarButtonItem;
        if (done) {
            objc_setAssociatedObject(ni, "m26det", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold]] style:UIBarButtonItemStylePlain target:[M26Cancel shared] action:@selector(tap:)];
            objc_setAssociatedObject(back, "m26orig", done, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            ni.leftBarButtonItem = back;
            ni.rightBarButtonItem = tiles[@"info"] ? GlassTextItem(@"Edit", [M26Details shared], @selector(edit:)) : nil;
        }
    } else if (tiles[@"info"] && ![ni.rightBarButtonItem.title isEqualToString:@"Edit"]) ni.rightBarButtonItem = GlassTextItem(@"Edit", [M26Details shared], @selector(edit:));
    gInfoTile = tiles[@"info"][@"tile"];
    { UIView *any = ((NSDictionary *)tiles.allValues.firstObject)[@"tile"];
      UIView *cell = any; while (cell && ![cell isKindOfClass:[UICollectionViewCell class]] && ![cell isKindOfClass:[UICollectionReusableView class]]) cell = cell.superview;
      (void)cell; }
    // which table sections hold the header (buttons) and the media part
    { UITableView *tb = (UITableView *)gDetTable;
      if ([tb isKindOfClass:[UITableView class]]) {
          UIView *any = ((NSDictionary *)tiles.allValues.firstObject)[@"tile"];
          UIView *c = any; while (c && ![c isKindOfClass:[UITableViewCell class]]) c = c.superview;
          NSIndexPath *ip = c ? [tb indexPathForCell:(UITableViewCell *)c] : nil; if (ip) gHeadRowSection = ip.section;
          c = gDetChild; while (c && ![c isKindOfClass:[UITableViewCell class]]) c = c.superview;
          ip = c ? [tb indexPathForCell:(UITableViewCell *)c] : nil; if (ip) gChildRowSection = ip.section;
      } }
    // "707 images in iCloud / Download": gone
    { UICollectionView *cv = gDetChild;
      if (cv) for (UIView *x in cv.subviews) {
          BOOL icl = Find(x, ^BOOL(UIView *y) { return [y isKindOfClass:[UILabel class]] && [((UILabel *)y).text containsString:@"in iCloud"]; }, 30) != nil;
          if (icl && !x.hidden) x.hidden = YES;
      } }
    @try { CardGlass(root); } @catch (__unused id e) {}
    NSArray *order = @[@"call", @"video", @"mail"];
    NSMutableArray *have = [NSMutableArray array];
    for (NSString *k in order) if (tiles[k]) [have addObject:k];
    if (!have.count) { gDetDebug = [NSString stringWithFormat:@"details: %@ no tiles", NSStringFromClass([vc class])]; return; }
    UIView *row = ((NSDictionary *)tiles[have[0]])[@"tile"];
    row = row.superview;
    // tile row band (untransformed): top T, bottom B, in row coords
    CGFloat T = CGFLOAT_MAX, B = 0;
    for (NSString *k in tiles) { UIView *t = tiles[k][@"tile"]; if (t.superview != row) continue; T = MIN(T, t.center.y - t.bounds.size.height / 2); B = MAX(B, t.center.y + t.bounds.size.height / 2); }
    CGFloat d = 48, gap = 74;
    CGPoint rc = [root convertPoint:CGPointMake(W / 2, 0) toView:row];
    CGFloat cx0 = rc.x - gap * (have.count - 1) / 2.0, cy = T - 1;
    BOOL dark = IsDark(root);
    for (NSString *k in tiles) {
        UIView *t = tiles[k][@"tile"]; UILabel *lb = tiles[k][@"label"];
        if (t.superview != row) continue;
        // no gray tile, no label
        t.backgroundColor = UIColor.clearColor; t.layer.borderWidth = 0;
        if (lb.alpha > 0) lb.alpha = 0;
        NSMutableArray *ss = [NSMutableArray arrayWithArray:t.subviews]; int gg = 0;
        while (ss.count && gg++ < 60) { UIView *x = ss.lastObject; [ss removeLastObject];
            if (x.tag == DGLASS_TAG) continue;
            if (![x isKindOfClass:[UILabel class]] && ![x isKindOfClass:[UIImageView class]] && x.bounds.size.width >= t.bounds.size.width * 0.8 && x.bounds.size.height >= t.bounds.size.height * 0.7) {
                if ([x isKindOfClass:[UIVisualEffectView class]]) { if (x.alpha > 0) x.alpha = 0; }
                else x.backgroundColor = UIColor.clearColor;
            }
            [ss addObjectsFromArray:x.subviews]; }
        if ([k isEqualToString:@"info"] || [k isEqualToString:@"message"]) {
            if (t.alpha > 0) t.alpha = 0;
            t.userInteractionEnabled = [k isEqualToString:@"info"];
            if (!CGAffineTransformIsIdentity(t.transform)) t.transform = CGAffineTransformIdentity;
            continue;
        }
        UIImageView *icon = (UIImageView *)Find(t, ^BOOL(UIView *x) { return [x isKindOfClass:[UIImageView class]] && x.tag != DGLASS_TAG && ((UIImageView *)x).image && x.bounds.size.width < 50; }, 40);
        CGPoint ic = icon ? [icon convertPoint:CGPointMake(icon.bounds.size.width / 2, icon.bounds.size.height / 2) toView:t] : CGPointMake(t.bounds.size.width / 2, t.bounds.size.height / 2 - 8);
        // a glass circle behind the icon
        UIVisualEffectView *gl = (UIVisualEffectView *)[t viewWithTag:DGLASS_TAG];
        if (!gl) { gl = GlassView(t); gl.tag = DGLASS_TAG; [t insertSubview:gl atIndex:0]; }
        CGRect gf = CGRectMake(ic.x - d / 2, ic.y - d / 2, d, d);
        if (!CGRectEqualToRect(gl.frame, gf)) { gl.frame = gf; gl.layer.cornerRadius = d / 2; RimFit(gl, dark); }
        BOOL off = [lb.textColor isEqual:UIColor.secondaryLabelColor] || lb.textColor == nil || ({ CGFloat r0, g0, b0, a0; [lb.textColor getRed:&r0 green:&g0 blue:&b0 alpha:&a0]; fabs(r0 - g0) < 0.05 && fabs(g0 - b0) < 0.05; });
        icon.tintColor = [UIColor colorWithWhite:dark ? 1 : 0 alpha:off ? 0.35 : 1];
        if (icon.image.renderingMode != UIImageRenderingModeAlwaysTemplate) icon.image = [icon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        // centered, three in a row, a bit higher
        NSInteger i = [have indexOfObject:k];
        CGFloat ox = t.center.x - t.bounds.size.width / 2 + ic.x, oy = t.center.y - t.bounds.size.height / 2 + ic.y;
        CGAffineTransform want = CGAffineTransformMakeTranslation(cx0 + gap * i - ox, cy - oy);
        if (!CGAffineTransformEqualToTransform(t.transform, want)) t.transform = want;
    }
    // other gray backgrounds behind the tiles in that row
    for (UIView *x in row.subviews) {
        BOOL isTile = NO; for (NSString *k in tiles) if (tiles[k][@"tile"] == x) isTile = YES;
        if (isTile || x.tag == DTABS_TAG) continue;
        CGFloat top = x.center.y - x.bounds.size.height / 2;
        if (fabs(top - T) < 4 && x.bounds.size.height <= B - T + 4 && x.bounds.size.width < 160) { if (x.alpha > 0) x.alpha = 0; }
    }
    // tabs: Info / Backgrounds / Photos / Links
    UIView *tabs = [row viewWithTag:DTABS_TAG];
    NSArray *tn = @[@"Info", @"Backgrounds", @"Photos", @"Links", @"Documents", @"Collaboration"];
    if (!tabs) {
        tabs = [UIScrollView new]; tabs.tag = DTABS_TAG; ((UIScrollView *)tabs).showsHorizontalScrollIndicator = NO; tabs.clipsToBounds = NO;
        UIVisualEffectView *sel = GlassView(row); sel.tag = 99; [tabs addSubview:sel];
        for (NSString *n in tn) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            [b setTitle:n forState:UIControlStateNormal];
            b.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            [b addTarget:[M26Details shared] action:@selector(tab:) forControlEvents:UIControlEventTouchUpInside];
            [tabs addSubview:b];
        }
        [row addSubview:tabs];
    }
    CGFloat th = 32, x = 0;
    NSMutableArray *bws = [NSMutableArray array];
    for (UIView *b in tabs.subviews) if ([b isKindOfClass:[UIButton class]]) { CGFloat bw = [((UIButton *)b).titleLabel sizeThatFits:CGSizeMake(300, 40)].width + 28; [bws addObject:@(bw)]; }
    CGFloat total = 0; for (NSNumber *n in bws) total += n.doubleValue;
    total += 4 * (bws.count - 1);
    CGFloat left = [root convertPoint:CGPointMake(16, 0) toView:row].x;
    CGRect tf = CGRectMake(left, T + 31, W - 32, th);
    if (!CGRectEqualToRect(tabs.frame, tf)) tabs.frame = tf;
    ((UIScrollView *)tabs).contentSize = CGSizeMake(total, th);
    int bi = 0;
    for (UIView *b in tabs.subviews) if ([b isKindOfClass:[UIButton class]]) {
        CGFloat bw = [bws[bi++] doubleValue];
        CGRect bf = CGRectMake(x, 0, bw, th); x += bw + 4;
        if (!CGRectEqualToRect(b.frame, bf)) b.frame = bf;
        BOOL on = [[(UIButton *)b titleForState:UIControlStateNormal] isEqualToString:gDetTab];
        [(UIButton *)b setTitleColor:on ? Ink(row) : [UIColor colorWithWhite:dark ? 1 : 0 alpha:0.55] forState:UIControlStateNormal];
        if (on) {
            UIView *sel = [tabs viewWithTag:99];
            if (!CGRectEqualToRect(sel.frame, bf)) { [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:0 animations:^{ sel.frame = bf; } completion:nil]; sel.layer.cornerRadius = th / 2; RimFit(sel, dark); }
        }
    }
    if (row.subviews.lastObject != tabs) [row bringSubviewToFront:tabs];
    for (UIView *p = row; p && p != root; p = p.superview) if (p.clipsToBounds && p.bounds.size.height < 300) p.clipsToBounds = NO;
    @try { StyleBgTab(vc); } @catch (__unused id e) {}
    gDetDebug = [NSString stringWithFormat:@"details: %@ tiles=%@ T=%.0f B=%.0f table=%@", NSStringFromClass([vc class]), [tiles.allKeys componentsJoinedByString:@","], T, B, gDetTable ? NSStringFromClass([gDetTable class]) : @"-"];
}

#pragma mark - per-conversation backgrounds (None / Photo / Color)

#define BGTAB_TAG 0x4D323657
#define CHATBG_TAG 0x4D323658
static NSString *ConvKey(id owner) {
    id conv = nil; @try { conv = [owner valueForKey:@"conversation"]; } @catch (__unused id e) {}
    if (!conv) return nil;
    for (NSString *kp in @[@"chat.guid", @"chat.chatIdentifier", @"groupID", @"name"]) {
        id v = nil; @try { v = [conv valueForKeyPath:kp]; } @catch (__unused id e) {}
        if ([v isKindOfClass:[NSString class]] && [v length]) return v;
    }
    return nil;
}
static NSString *BgDir(void) {
    NSString *d = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Messages26"];
    [[NSFileManager defaultManager] createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
    return d;
}
static NSString *BgFile(NSString *key) {
    NSMutableString *safe = [NSMutableString string];
    for (NSUInteger i = 0; i < key.length; i++) { unichar c = [key characterAtIndex:i]; [safe appendFormat:(isalnum(c) ? @"%C" : @"_"), c]; }
    return [BgDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"bg_%@.jpg", safe]];
}
static NSDictionary *BgFor(NSString *key) { return key ? [[NSUserDefaults standardUserDefaults] dictionaryForKey:[@"m26.bg." stringByAppendingString:key]] : nil; }
static void SetBg(NSString *key, NSDictionary *d) {
    if (!key) return;
    if (d) [[NSUserDefaults standardUserDefaults] setObject:d forKey:[@"m26.bg." stringByAppendingString:key]];
    else [[NSUserDefaults standardUserDefaults] removeObjectForKey:[@"m26.bg." stringByAppendingString:key]];
}
static UIColor *HexColor(NSString *h) {
    unsigned int v = 0; [[NSScanner scannerWithString:h ?: @"000000"] scanHexInt:&v];
    return [UIColor colorWithRed:((v >> 16) & 255) / 255.0 green:((v >> 8) & 255) / 255.0 blue:(v & 255) / 255.0 alpha:1];
}
static NSString *ColorHex(UIColor *c) {
    CGFloat r = 0, g = 0, b = 0, a = 0; [c getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"%02X%02X%02X", (int)lround(MAX(0, MIN(1, r)) * 255), (int)lround(MAX(0, MIN(1, g)) * 255), (int)lround(MAX(0, MIN(1, b)) * 255)];
}
static NSMutableDictionary *gBgImages;   // key -> UIImage (loaded once)
static UIImage *BgImage(NSString *key) {
    if (!gBgImages) gBgImages = [NSMutableDictionary dictionary];
    NSDictionary *d = BgFor(key);
    NSString *stamp = [NSString stringWithFormat:@"%@|%@", key, d[@"t"]];
    UIImage *im = gBgImages[stamp];
    if (!im) { im = [UIImage imageWithContentsOfFile:BgFile(key)]; if (im) gBgImages[stamp] = im; }
    return im;
}

@interface M26Bg : NSObject <PHPickerViewControllerDelegate, UIColorPickerViewControllerDelegate>
+ (instancetype)shared;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, weak) UIViewController *host;
@end
@implementation M26Bg
+ (instancetype)shared { static M26Bg *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Bg new]; }); return t; }
- (void)pick:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (!self.key) return;
    if (b.tag == 0) { SetBg(self.key, nil); return; }
    if (b.tag == 1) {
        PHPickerConfiguration *cfg = [PHPickerConfiguration new];
        cfg.filter = [PHPickerFilter imagesFilter]; cfg.selectionLimit = 1;
        PHPickerViewController *pk = [[PHPickerViewController alloc] initWithConfiguration:cfg];
        pk.delegate = self;
        [self.host presentViewController:pk animated:YES completion:nil];
        return;
    }
    UIColorPickerViewController *cp = [UIColorPickerViewController new];
    cp.delegate = self; cp.supportsAlpha = NO;
    NSDictionary *d = BgFor(self.key);
    if ([d[@"type"] isEqualToString:@"color"]) cp.selectedColor = HexColor(d[@"hex"]);
    [self.host presentViewController:cp animated:YES completion:nil];
}
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSItemProvider *ip = results.firstObject.itemProvider;
    NSString *key = self.key;
    if (!ip || !key || ![ip canLoadObjectOfClass:[UIImage class]]) return;
    [ip loadObjectOfClass:[UIImage class] completionHandler:^(id obj, NSError *err) {
        UIImage *im = [obj isKindOfClass:[UIImage class]] ? obj : nil;
        if (!im) return;
        // keep it screen-sized
        CGFloat maxSide = 1600, sc = MIN(1, maxSide / MAX(im.size.width, im.size.height));
        CGSize sz = CGSizeMake(round(im.size.width * sc), round(im.size.height * sc));
        UIGraphicsImageRendererFormat *f = [UIGraphicsImageRendererFormat defaultFormat]; f.scale = 1;
        UIImage *small = [[[UIGraphicsImageRenderer alloc] initWithSize:sz format:f] imageWithActions:^(__unused UIGraphicsImageRendererContext *c) { [im drawInRect:CGRectMake(0, 0, sz.width, sz.height)]; }];
        [UIImageJPEGRepresentation(small, 0.85) writeToFile:BgFile(key) atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{ SetBg(key, @{@"type": @"photo", @"t": @([NSDate date].timeIntervalSince1970)}); });
    }];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)vc { if (self.key) SetBg(self.key, @{@"type": @"color", @"hex": ColorHex(vc.selectedColor), @"t": @([NSDate date].timeIntervalSince1970)}); }
- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)vc { [self colorPickerViewControllerDidSelectColor:vc]; }
@end

// The Backgrounds tab: None / Photo / Color circles under the tabs.
static void StyleBgTab(UIViewController *vc) {
    UITableView *tb = (UITableView *)gDetTable;
    if (![tb isKindOfClass:[UITableView class]]) return;
    UIView *box = [tb viewWithTag:BGTAB_TAG];
    BOOL on = [gDetTab isEqualToString:@"Backgrounds"];
    NSString *key = ConvKey(vc);
    M26Bg *B = [M26Bg shared]; B.key = key; B.host = vc;
    if (!on || !key || gHeadRowSection < 0) { box.hidden = YES; return; }
    BOOL dark = IsDark(tb);
    CGFloat W = tb.bounds.size.width, d = 84, lab = 26, gap = (W - 3 * d) / 4;
    if (!box) {
        box = [UIView new]; box.tag = BGTAB_TAG;
        NSArray *names = @[@"None", @"Photo", @"Color"];
        for (int i = 0; i < 3; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom]; b.tag = i;
            b.layer.cornerRadius = d / 2; b.clipsToBounds = YES; b.imageView.contentMode = UIViewContentModeScaleAspectFill;
            [b addTarget:B action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
            b.frame = CGRectMake(gap + i * (d + gap), 8, d, d);
            [box addSubview:b];
            UIView *ring = [[UIView alloc] initWithFrame:CGRectInset(b.frame, -5, -5)]; ring.tag = 10 + i; ring.userInteractionEnabled = NO;
            ring.layer.cornerRadius = ring.bounds.size.width / 2; ring.layer.borderWidth = 3;
            [box addSubview:ring];
            UIImageView *chk = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightBold]]];
            chk.tag = 20 + i; chk.frame = CGRectMake(CGRectGetMaxX(b.frame) - 26, CGRectGetMaxY(b.frame) - 26, 30, 30); chk.contentMode = UIViewContentModeCenter;
            chk.layer.cornerRadius = 15; chk.clipsToBounds = YES;
            [box addSubview:chk];
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(b.frame) - 60, CGRectGetMaxY(b.frame) + 10, 120, lab)];
            l.text = names[i]; l.textAlignment = NSTextAlignmentCenter; l.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium]; l.tag = 30 + i;
            [box addSubview:l];
        }
        [tb addSubview:box];
    }
    box.hidden = NO;
    CGRect hr = [tb rectForSection:gHeadRowSection];
    CGRect bf = CGRectMake(0, CGRectGetMaxY(hr) + 6, W, d + lab + 30);
    if (!CGRectEqualToRect(box.frame, bf)) box.frame = bf;
    if (tb.subviews.lastObject != box) [tb bringSubviewToFront:box];
    NSDictionary *cur = BgFor(key);
    NSInteger sel = [cur[@"type"] isEqualToString:@"photo"] ? 1 : [cur[@"type"] isEqualToString:@"color"] ? 2 : 0;
    for (int i = 0; i < 3; i++) {
        UIButton *b = (UIButton *)[box viewWithTag:i];
        if (![b isKindOfClass:[UIButton class]]) { for (UIView *x in box.subviews) if ([x isKindOfClass:[UIButton class]] && x.tag == i) b = (UIButton *)x; }
        UIView *ring = [box viewWithTag:10 + i]; UIImageView *chk = (UIImageView *)[box viewWithTag:20 + i]; UILabel *l = (UILabel *)[box viewWithTag:30 + i];
        l.textColor = Ink(tb);
        ring.layer.borderColor = (sel == i ? Ink(tb) : UIColor.clearColor).CGColor;
        chk.hidden = sel != i; chk.tintColor = dark ? UIColor.whiteColor : UIColor.blackColor; chk.backgroundColor = dark ? UIColor.blackColor : UIColor.whiteColor;
        if (i == 0) b.backgroundColor = dark ? [UIColor colorWithWhite:0.17 alpha:1] : [UIColor colorWithWhite:0.88 alpha:1];
        if (i == 1) {
            UIImage *im = sel == 1 ? BgImage(key) : nil;
            if (im) { [b setImage:im forState:UIControlStateNormal]; b.backgroundColor = UIColor.blackColor; }
            else { [b setImage:[UIImage systemImageNamed:@"photo" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal]; b.imageView.contentMode = UIViewContentModeCenter; b.tintColor = Ink(tb); b.backgroundColor = dark ? [UIColor colorWithWhite:0.09 alpha:1] : [UIColor colorWithWhite:0.8 alpha:1]; }
            if (im) b.imageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        if (i == 2) {
            CAGradientLayer *gl = nil; for (CALayer *x in b.layer.sublayers) if ([x.name isEqualToString:@"g"]) gl = (CAGradientLayer *)x;
            if (!gl) { gl = [CAGradientLayer layer]; gl.name = @"g"; gl.frame = b.bounds; gl.startPoint = CGPointMake(0, 0); gl.endPoint = CGPointMake(1, 1); [b.layer insertSublayer:gl atIndex:0]; }
            if (sel == 2) gl.colors = @[(id)HexColor(cur[@"hex"]).CGColor, (id)HexColor(cur[@"hex"]).CGColor];
            else gl.colors = @[(id)[UIColor colorWithRed:1 green:0.55 blue:0.75 alpha:1].CGColor, (id)[UIColor colorWithRed:1 green:0.72 blue:0.25 alpha:1].CGColor, (id)[UIColor colorWithRed:0.98 green:0.55 blue:0.6 alpha:1].CGColor];
        }
    }
}


// Pull the chat up past the last message to see the whole background; pull down to bring it back.
@interface M26Peek : NSObject
+ (instancetype)shared;
@end
@implementation M26Peek
+ (instancetype)shared { static M26Peek *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Peek new]; }); return t; }
- (void)pan:(UIPanGestureRecognizer *)g {
    UICollectionView *cv = (UICollectionView *)g.view;
    if (![cv isKindOfClass:[UICollectionView class]] || !BgFor(objc_getAssociatedObject(cv, "m26key"))) return;
    if (g.state != UIGestureRecognizerStateEnded) return;
    CGFloat extra = [objc_getAssociatedObject(cv, "m26peek") doubleValue];
    UIEdgeInsets in = cv.adjustedContentInset;
    CGFloat maxY = cv.contentSize.height + in.bottom - cv.bounds.size.height;
    CGFloat vy = [g velocityInView:cv].y;
    if (extra <= 0) {
        if (cv.contentOffset.y - maxY > 70) {
            CGFloat E = MAX(0, cv.bounds.size.height - in.top - 160);
            objc_setAssociatedObject(cv, "m26peek", @(E), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft] impactOccurred];
            UIEdgeInsets ci = cv.contentInset; ci.bottom += E;
            CGFloat target = maxY + E;
            UIView *host = objc_getAssociatedObject(cv, "m26bghost");
            UIView *iv = [host viewWithTag:1], *dim = [host viewWithTag:2];
            CGFloat v0 = MAX(0, -vy) / MAX(1, target - cv.contentOffset.y);
            dispatch_async(dispatch_get_main_queue(), ^{
                cv.contentInset = ci;
                // messages glide away on a soft spring; the photo settles back from a slight zoom and its shade lifts
                [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:MIN(v0, 3) options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ cv.contentOffset = CGPointMake(0, target); } completion:nil];
                [UIView animateWithDuration:0.9 delay:0.05 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ iv.transform = CGAffineTransformIdentity; dim.alpha = 0; } completion:nil];
                for (UICollectionViewCell *c in cv.visibleCells) {
                    c.alpha = 0.55;
                    [UIView animateWithDuration:0.6 delay:0.15 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{ c.alpha = 1; } completion:nil];
                }
            });
        }
    } else if (vy > 120 || cv.contentOffset.y < maxY - 60) {
        objc_setAssociatedObject(cv, "m26peek", @0, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIEdgeInsets ci = cv.contentInset; ci.bottom = MAX(0, ci.bottom - extra);
        CGFloat target = maxY - extra;
        UIView *host = objc_getAssociatedObject(cv, "m26bghost");
        UIView *iv = [host viewWithTag:1], *dim = [host viewWithTag:2];
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.84 initialSpringVelocity:MIN(MAX(vy, 0) / 800.0, 3) options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                cv.contentInset = ci; cv.contentOffset = CGPointMake(0, MAX(-cv.adjustedContentInset.top, target));
            } completion:nil];
            [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{ iv.transform = CGAffineTransformMakeScale(1.04, 1.04); dim.alpha = 1; } completion:nil];
        });
    }
}
@end
// In the chat: that conversation's background behind the messages.
static void ApplyChatBg(UIWindow *w) {
    UIView *e = gEntry;
    if (!e.window) return;
    UICollectionView *cv = (UICollectionView *)Find(w, ^BOOL(UIView *v) { return [v isKindOfClass:[UICollectionView class]] && [NSStringFromClass([v class]) containsString:@"Transcript"]; }, 3000);
    if (!cv) return;
    NSString *key = nil;
    for (UIResponder *r = cv; r && !key; r = r.nextResponder) if ([r respondsToSelector:NSSelectorFromString(@"conversation")]) key = ConvKey(r);
    if (!key) { id d = cv.delegate; for (int i = 0; i < 3 && d && !key; i++) { key = ConvKey(d); @try { d = [d valueForKey:@"delegate"]; } @catch (__unused id ex) { d = nil; } } }
    if (key) objc_setAssociatedObject(cv, "m26key", key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!objc_getAssociatedObject(cv, "m26peekon")) { objc_setAssociatedObject(cv, "m26peekon", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); [cv.panGestureRecognizer addTarget:[M26Peek shared] action:@selector(pan:)]; }
    NSDictionary *bg = gOn ? BgFor(key) : nil;
    // the background lives behind the chat (not inside it), so scrolling never moves it
    UIView *sup = cv.superview;
    UIView *host = objc_getAssociatedObject(cv, "m26bghost");
    if (cv.backgroundView.tag == CHATBG_TAG) cv.backgroundView = nil;
    if (!bg) { [host removeFromSuperview]; objc_setAssociatedObject(cv, "m26bghost", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); objc_setAssociatedObject(cv, "m26bg", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); return; }
    if (!host) {
        host = [UIView new]; host.tag = CHATBG_TAG; host.clipsToBounds = YES; host.userInteractionEnabled = NO;
        UIImageView *iv = [UIImageView new]; iv.tag = 1; iv.contentMode = UIViewContentModeScaleAspectFill; [host addSubview:iv];
        UIView *dim = [UIView new]; dim.tag = 2; dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.28]; [host addSubview:dim];
        objc_setAssociatedObject(cv, "m26bghost", host, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (host.superview != sup) [sup insertSubview:host belowSubview:cv];
    else if ([sup.subviews indexOfObject:host] > [sup.subviews indexOfObject:cv]) [sup insertSubview:host belowSubview:cv];
    CGRect hf = cv.frame;
    if (!CGRectEqualToRect(host.frame, hf)) {
        host.frame = hf;
        UIView *iv = [host viewWithTag:1], *dim = [host viewWithTag:2];
        CGAffineTransform keep = iv.transform; iv.transform = CGAffineTransformIdentity; iv.frame = host.bounds; iv.transform = keep;
        dim.frame = host.bounds;
    }
    if (cv.backgroundColor && CGColorGetAlpha(cv.backgroundColor.CGColor) > 0) cv.backgroundColor = UIColor.clearColor;
    NSString *stamp = [NSString stringWithFormat:@"%@|%@|%@", key, bg[@"t"], bg[@"hex"]];
    if ([objc_getAssociatedObject(cv, "m26bg") isEqual:stamp]) return;
    objc_setAssociatedObject(cv, "m26bg", stamp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImageView *iv = (UIImageView *)[host viewWithTag:1]; UIView *dim = [host viewWithTag:2];
    BOOL photo = [bg[@"type"] isEqualToString:@"photo"];
    iv.image = photo ? BgImage(key) : nil;
    iv.hidden = !photo; dim.hidden = !photo;
    host.backgroundColor = photo ? UIColor.blackColor : HexColor(bg[@"hex"]);
    BOOL peek = [objc_getAssociatedObject(cv, "m26peek") doubleValue] > 0;
    iv.transform = peek ? CGAffineTransformIdentity : CGAffineTransformMakeScale(1.04, 1.04);
    dim.alpha = peek ? 0 : 1;
}

#pragma mark - debug + tick

@interface M26Debug : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation M26Debug
+ (instancetype)shared { static M26Debug *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [M26Debug new]; }); return t; }
- (void)hold:(UILongPressGestureRecognizer *)g { if (g.state == UIGestureRecognizerStateBegan) gShowDebug = !gShowDebug; }
// drag the debug box anywhere (remembered)
- (void)drag:(UIPanGestureRecognizer *)g {
    UIView *l = g.view;
    CGPoint t = [g translationInView:l.superview];
    l.center = CGPointMake(l.center.x + t.x, l.center.y + t.y);
    [g setTranslation:CGPointZero inView:l.superview];
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        [[NSUserDefaults standardUserDefaults] setDouble:l.frame.origin.y forKey:@"m26.debugY"];
        [[NSUserDefaults standardUserDefaults] setDouble:l.frame.origin.x forKey:@"m26.debugX"];
    }
}
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
    @try { StyleSearchPill(w); } @catch (__unused id e) {}
    @try { InstallSwipe(w); } @catch (__unused id e) {}
    @try { StyleDetails(w); } @catch (__unused id e) {}
    @try { ApplyChatBg(w); } @catch (__unused id e) {}
    if (gTopOn) { @try { for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) if ([sc isKindOfClass:[UIWindowScene class]]) for (UIWindow *x in ((UIWindowScene *)sc).windows) StyleToField(x); } @catch (__unused id e) {} }
    // the entry view lives in the keyboard's window too: style it wherever it is
    UIView *e = gEntry;
    if (e.window) {
        UIView *f = gField, *pill = [f.superview viewWithTag:PILL_TAG];
        CGRect fr = [f convertRect:f.bounds toView:e], pr = pill ? [pill convertRect:pill.bounds toView:e] : CGRectNull;
        if (f && (!pill || fabs(CGRectGetMidY(fr) - CGRectGetMidY(pr)) > 3)) { @try { StyleEntry(e); } @catch (__unused id ex) {} }
    }
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
        l = [UILabel new]; l.tag = DEBUG_TAG; l.numberOfLines = 0; l.userInteractionEnabled = YES;
        [l addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:[M26Debug shared] action:@selector(drag:)]];
        l.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor; l.backgroundColor = [UIColor colorWithRed:0.3 green:0 blue:0.35 alpha:0.85];
        l.layer.cornerRadius = 10; l.clipsToBounds = YES;
        [w addSubview:l];
    }
    l.text = [NSString stringWithFormat:@" Messages26 0.12.3 debug\n %@\n %@\n %@", gDebug, gNavDebug, gSearchDebug];
    l.text = [l.text stringByAppendingFormat:@"\n %@ %@\n %@\n %@", gBubbleDebug, gReplyDebug, gToDebug, gTitleDebug];
    l.text = [l.text stringByAppendingFormat:@"\n %@ tab=%@ head=%ld child=%ld\n sections: %@\n edit: %@", gDetDebug, gDetTab, (long)gHeadRowSection, (long)gChildRowSection, gSnapDebug, gEditDebug];
    CGSize s = [l sizeThatFits:CGSizeMake(w.bounds.size.width - 24, 800)];
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        BOOL dragging = NO;
        for (UIGestureRecognizer *gr in l.gestureRecognizers) if (gr.state == UIGestureRecognizerStateBegan || gr.state == UIGestureRecognizerStateChanged) dragging = YES;
        if (!dragging) {
            CGFloat x = [ud objectForKey:@"m26.debugX"] ? [ud doubleForKey:@"m26.debugX"] : 12;
            CGFloat y = [ud objectForKey:@"m26.debugY"] ? [ud doubleForKey:@"m26.debugY"] : w.safeAreaInsets.top + 140;
            CGFloat bw = w.bounds.size.width - 24, bh = s.height + 12;
            x = MIN(MAX(x, -bw + 60), w.bounds.size.width - 60);
            y = MIN(MAX(y, 0), w.bounds.size.height - 40);
            l.frame = CGRectMake(x, y, bw, bh);
        }
    }
    [w bringSubviewToFront:l];
}

%hook UIView
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)e {
    BOOL r = %orig;
    if (r) return r;
    UIView *tb = gNameNow;
    if (tb && tb.window && !CATransform3DIsIdentity(tb.layer.sublayerTransform) && (self == tb || [tb isDescendantOfView:self]) && CGRectContainsPoint(NameDrawn(tb, [tb convertRect:tb.bounds toView:self], self), p)) return YES;
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
        MSHookMessageEx([UITextView class], @selector(setTextContainerInset:), (IMP)TVInset, (IMP *)&origTVInset);
        @try { HookThemes(); } @catch (__unused id ex) {}
        @try { HookDetailsTable(); } @catch (__unused id ex) {}
        { Class SA = NSClassFromString(@"CKSearchViewController"), SB = NSClassFromString(@"CKDetailsSearchViewController");
          SEL ss = NSSelectorFromString(@"_newSnapshotForCurrentControllerState");
          if (SA && class_getInstanceMethod(SA, ss)) MSHookMessageEx(SA, ss, (IMP)SnapA, (IMP *)&origSnapA);
          if (SB) { unsigned int mc = 0; Method *ms = class_copyMethodList(SB, &mc); BOOL own = NO; for (unsigned int k = 0; k < mc; k++) if (method_getName(ms[k]) == ss) own = YES; free(ms);
                    if (own) MSHookMessageEx(SB, ss, (IMP)SnapB, (IMP *)&origSnapB); }
          SEL ls = NSSelectorFromString(@"layoutSectionForController:withEnvironment:");
          if (SA && class_getInstanceMethod(SA, ls)) MSHookMessageEx(SA, ls, (IMP)LayA, (IMP *)&origLayA);
          if (SB) { unsigned int mc = 0; Method *ms = class_copyMethodList(SB, &mc); BOOL own = NO; for (unsigned int k = 0; k < mc; k++) if (method_getName(ms[k]) == ls) own = YES; free(ms);
                    if (own) MSHookMessageEx(SB, ls, (IMP)LayB, (IMP *)&origLayB); } }
        { Class B1 = NSClassFromString(@"CKBalloonView"), B2 = NSClassFromString(@"CKColoredBalloonView");
          SEL so = NSSelectorFromString(@"setCanUseOpaqueMask:"), go = NSSelectorFromString(@"canUseOpaqueMask");
          if (B1 && class_getInstanceMethod(B1, so)) MSHookMessageEx(B1, so, (IMP)OpaqueA, (IMP *)&origOpaqueA);
          if (B2 && class_getInstanceMethod(B2, so)) MSHookMessageEx(B2, so, (IMP)OpaqueB, (IMP *)&origOpaqueB);
          IMP dummy = NULL;
          if (B1 && class_getInstanceMethod(B1, go)) MSHookMessageEx(B1, go, (IMP)NoOpaque, &dummy); }
        Class CB = NSClassFromString(@"CKColoredBalloonView");
        if (CB) {
            MSHookMessageEx(CB, @selector(layoutSubviews), (IMP)BalloonLayout, (IMP *)&origBalloonLayout);
            MSHookMessageEx(CB, @selector(setFrame:), (IMP)BalloonFrame, (IMP *)&origBalloonFrame);
            MSHookMessageEx(CB, @selector(setCenter:), (IMP)BalloonCenter, (IMP *)&origBalloonCenter);
            MSHookMessageEx(CB, @selector(setAlpha:), (IMP)BalloonAlpha, (IMP *)&origBalloonAlpha);
            MSHookMessageEx(CB, @selector(setHidden:), (IMP)BalloonHidden, (IMP *)&origBalloonHidden);
            MSHookMessageEx(CB, @selector(didMoveToSuperview), (IMP)BalloonMove, (IMP *)&origBalloonMove);
        }
        [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(__unused NSTimer *t) { @try { Tick(); } @catch (__unused id ex) {} }];
    });
}
