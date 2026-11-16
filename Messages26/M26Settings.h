// ===================== Messages26 settings: live preview (runs in the Settings app) =====================
// A little phone with a chat that plays Messages26's features on a loop: bubbles pop in, swipe to
// reply, the + button grows into the glass menu, a video opens in the iOS 26 viewer, a wide audio
// bubble. It follows your switches live: flip one and the phone changes, and its Dynamic Island
// grows to say what changed ("Glass Bubbles · On") and shrinks back, like iOS does.

@interface NSObject (M26PS)
- (id)propertyForKey:(NSString *)k;
- (NSString *)identifier;
@end

static NSString *const kM26Flip = @"M26PrefFlip";

static NSMutableDictionary *M26ReadPrefs(void) {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for (NSString *dir in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *f = [NSDictionary dictionaryWithContentsOfFile:[dir stringByAppendingString:@"com.nano.messages26.plist"]];
        if ([f isKindOfClass:[NSDictionary class]]) { [d addEntriesFromDictionary:f]; break; }
    }
    for (NSString *k in @[@"enabled", @"bar", @"menu", @"topbar", @"bigphoto", @"bubbles", @"swipereply", @"viewer", @"audiobig", @"speaker", @"searchpill"]) {
        if (!d[k]) { CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)k, CFSTR("com.nano.messages26")); d[k] = cf ? (__bridge_transfer id)cf : @YES; }
    }
    return d;
}

@interface M26Phone : UIView
@end
@implementation M26Phone {
    UIView *_screen, *_chat, *_island, *_islandContent, *_dot, *_menu, *_viewer;
    UIImageView *_islandIcon; UILabel *_islandText;
    NSMutableDictionary *_p;
    NSMutableArray<UIView *> *_bubbles;
    UIView *_r1, *_photo, *_plus, *_replyArrow;
    NSUInteger _gen;
    BOOL _islandBusy;
}
- (BOOL)on:(NSString *)k { return [_p[@"enabled"] boolValue] && [_p[k] boolValue]; }
static UIView *M26Box(UIView *in, CGRect r, CGFloat rad, UIColor *c) {
    UIView *v = [[UIView alloc] initWithFrame:r];
    v.backgroundColor = c; v.layer.cornerRadius = rad; v.layer.cornerCurve = kCACornerCurveContinuous;
    [in addSubview:v];
    return v;
}
static UIView *M26Glass(UIView *in, CGRect r, CGFloat rad) {
    UIView *g = M26Box(in, r, rad, [UIColor colorWithWhite:1 alpha:0.14]);
    g.layer.borderWidth = 0.6; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
    return g;
}
static UIImageView *M26Sym(UIView *in, NSString *name, CGFloat pt, CGPoint c, UIColor *tint) {
    UIImageView *v = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold]]];
    v.tintColor = tint ?: UIColor.whiteColor; v.contentMode = UIViewContentModeCenter;
    [v sizeToFit]; v.center = c; [in addSubview:v];
    return v;
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.layer.cornerRadius = 17; self.layer.cornerCurve = kCACornerCurveContinuous; self.layer.borderWidth = 3;
    _screen = [UIView new]; _screen.backgroundColor = UIColor.blackColor;
    _screen.layer.cornerRadius = 13; _screen.layer.cornerCurve = kCACornerCurveContinuous; _screen.clipsToBounds = YES;
    [self addSubview:_screen];
    _p = M26ReadPrefs();
    _bubbles = [NSMutableArray array];
    __weak M26Phone *ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kM26Flip object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
        M26Phone *s = ws; if (!s) return;
        [s flip:n.userInfo[@"key"] on:[n.userInfo[@"value"] boolValue]];
    }];
    [self updateColors];
    return self;
}
- (void)updateColors {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    self.layer.borderColor = (dark ? [UIColor colorWithWhite:0.42 alpha:1] : [UIColor colorWithWhite:0.80 alpha:1]).CGColor;
}
- (void)traitCollectionDidChange:(UITraitCollection *)p { [super traitCollectionDidChange:p]; [self updateColors]; }
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect sr = CGRectInset(self.bounds, 5, 5);
    if (!CGRectEqualToRect(_screen.frame, sr)) { _screen.frame = sr; [self renderChat]; [self buildIsland]; [self restart]; }
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self restart]; }

#pragma mark the chat, drawn from the switches
- (void)renderChat {
    [_chat removeFromSuperview];
    [_bubbles removeAllObjects];
    CGSize S = _screen.bounds.size;
    _chat = [[UIView alloc] initWithFrame:_screen.bounds];
    [_screen insertSubview:_chat atIndex:0];
    BOOL glassB = [self on:@"bubbles"];
    UIColor *recv = glassB ? [UIColor colorWithWhite:1 alpha:0.17] : [UIColor colorWithWhite:0.24 alpha:1];
    UIColor *sent = glassB ? [UIColor colorWithRed:0.05 green:0.32 blue:0.95 alpha:1] : UIColor.systemBlueColor;
    UIView *(^bubble)(CGRect, BOOL) = ^UIView *(CGRect r, BOOL mine) {
        UIView *b = M26Box(self->_chat, r, r.size.height / 2, mine ? sent : recv);
        if (glassB && !mine) { b.layer.borderWidth = 0.6; b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor; }
        M26Box(b, CGRectMake(5, r.size.height / 2 - 1.25, r.size.width - 12, 2.5), 1.25, [UIColor colorWithWhite:1 alpha:0.85]);
        [self->_bubbles addObject:b];
        return b;
    };
    // top: back, contact photo + name, FaceTime
    if ([self on:@"topbar"]) {
        UIView *bk = M26Glass(_chat, CGRectMake(4, 15, 13, 13), 6.5); M26Sym(bk, @"chevron.left", 5, CGPointMake(6.5, 6.5), nil);
        UIView *ft = M26Glass(_chat, CGRectMake(S.width - 17, 15, 13, 13), 6.5); M26Sym(ft, @"video.fill", 5, CGPointMake(6.5, 6.5), nil);
    } else {
        M26Sym(_chat, @"chevron.left", 7, CGPointMake(8, 21), UIColor.systemBlueColor);
        M26Sym(_chat, @"video", 7, CGPointMake(S.width - 9, 21), UIColor.systemBlueColor);
        M26Box(_chat, CGRectMake(0, 36, S.width, 0.5), 0, [UIColor colorWithWhite:1 alpha:0.15]);
    }
    BOOL big = [self on:@"topbar"] && [self on:@"bigphoto"];
    CGFloat pd = big ? 16 : 11;
    UIView *pf = M26Box(_chat, CGRectMake(S.width / 2 - pd / 2, big ? 11 : 13, pd, pd), pd / 2, [UIColor colorWithRed:0.55 green:0.6 blue:0.75 alpha:1]);
    (void)pf;
    if (big) M26Glass(_chat, CGRectMake(S.width / 2 - 15, 29, 30, 7), 3.5);
    else M26Box(_chat, CGRectMake(S.width / 2 - 9, 26, 18, 2.5), 1.25, [UIColor colorWithWhite:1 alpha:0.7]);
    // messages
    _r1 = bubble(CGRectMake(4, 44, 46, 12), NO);
    bubble(CGRectMake(S.width - 4 - 36, 60, 36, 12), YES);
    _photo = M26Box(_chat, CGRectMake(4, 76, 36, 30), 6, UIColor.clearColor);
    CAGradientLayer *gl = [CAGradientLayer layer]; gl.frame = _photo.bounds; gl.cornerRadius = 6;
    gl.colors = @[(id)[UIColor colorWithRed:0.98 green:0.45 blue:0.35 alpha:1].CGColor, (id)[UIColor colorWithRed:0.55 green:0.25 blue:0.85 alpha:1].CGColor];
    [_photo.layer addSublayer:gl];
    M26Sym(_photo, @"play.fill", 7, CGPointMake(18, 15), nil);
    [_bubbles addObject:_photo];
    BOOL ab = [self on:@"audiobig"];
    UIView *au = M26Box(_chat, CGRectMake(4, 112, ab ? 64 : 44, ab ? 16 : 12), ab ? 8 : 6, recv);
    if (glassB) { au.layer.borderWidth = 0.6; au.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor; }
    CGFloat ah = au.bounds.size.height;
    M26Box(au, CGRectMake(3, ah / 2 - (ab ? 5 : 3.5), ab ? 10 : 7, ab ? 10 : 7), ab ? 5 : 3.5, UIColor.systemBlueColor);
    for (int i = 0; i < (ab ? 12 : 6); i++) { CGFloat h = 2 + (i * 7 % 5); M26Box(au, CGRectMake((ab ? 16 : 13) + i * 3.2, ah / 2 - h / 2, 1.6, h), 0.8, [UIColor colorWithWhite:1 alpha:0.75]); }
    if (!ab) { M26Sym(_chat, @"speaker.wave.2.fill", 5, CGPointMake(54, 118), [UIColor colorWithWhite:1 alpha:0.5]); M26Box(_chat, CGRectMake(5, 127, 20, 2), 1, [UIColor colorWithWhite:1 alpha:0.35]); }
    [_bubbles addObject:au];
    bubble(CGRectMake(S.width - 4 - 30, 136, 30, 12), YES);
    // the message bar
    CGFloat by = S.height - 22;
    if ([self on:@"bar"]) {
        _plus = M26Glass(_chat, CGRectMake(4, by, 14, 14), 7); M26Sym(_plus, @"plus", 6, CGPointMake(7, 7), nil);
        UIView *fld = M26Glass(_chat, CGRectMake(21, by, S.width - 25, 14), 7);
        M26Box(fld, CGRectMake(6, 6, 18, 2), 1, [UIColor colorWithWhite:1 alpha:0.35]);
    } else {
        _plus = M26Box(_chat, CGRectMake(4, by + 2, 10, 10), 3, [UIColor colorWithWhite:1 alpha:0.35]);
        M26Box(_chat, CGRectMake(16, by + 2, 10, 10), 3, [UIColor colorWithWhite:1 alpha:0.35]);
        UIView *fld = M26Box(_chat, CGRectMake(29, by, S.width - 33, 14), 7, UIColor.clearColor);
        fld.layer.borderWidth = 0.7; fld.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
    }
    if (_island) [_screen bringSubviewToFront:_island];
    if (_dot) [_screen bringSubviewToFront:_dot];
}

#pragma mark the Dynamic Island
- (CGRect)islandSmall { return CGRectMake(_screen.bounds.size.width / 2 - 13, 3, 26, 8); }
- (void)buildIsland {
    [_island removeFromSuperview];
    _island = M26Box(_screen, [self islandSmall], 4, UIColor.blackColor);
    _island.clipsToBounds = YES;
    _island.layer.borderWidth = 0.5; _island.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    CGFloat W = _screen.bounds.size.width - 8;
    _islandContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 20)];
    _islandIcon = [UIImageView new]; _islandIcon.contentMode = UIViewContentModeCenter; _islandIcon.frame = CGRectMake(4, 3, 14, 14);
    _islandText = [UILabel new]; _islandText.font = [UIFont systemFontOfSize:7 weight:UIFontWeightBold]; _islandText.textColor = UIColor.whiteColor;
    _islandText.frame = CGRectMake(20, 3, W - 24, 14); _islandText.adjustsFontSizeToFitWidth = YES; _islandText.minimumScaleFactor = 0.6;
    [_islandContent addSubview:_islandIcon]; [_islandContent addSubview:_islandText];
    _islandContent.alpha = 0;
    [_island addSubview:_islandContent];
    _dot = M26Box(_screen, CGRectMake(0, 0, 9, 9), 4.5, [UIColor colorWithWhite:1 alpha:0.9]);
    _dot.layer.shadowColor = UIColor.blackColor.CGColor; _dot.layer.shadowOpacity = 0.5; _dot.layer.shadowRadius = 2; _dot.layer.shadowOffset = CGSizeZero;
    _dot.alpha = 0;
}
- (void)islandSay:(NSString *)text icon:(NSString *)icon on:(BOOL)on {
    [_island.layer removeAllAnimations]; [_islandContent.layer removeAllAnimations];
    _islandText.text = text;
    _islandIcon.image = [UIImage systemImageNamed:icon withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightBold]];
    _islandIcon.tintColor = on ? UIColor.systemGreenColor : UIColor.systemGrayColor;
    CGRect big = CGRectMake(4, 3, _screen.bounds.size.width - 8, 20);
    _islandContent.frame = CGRectMake(0, 0, big.size.width, big.size.height);
    _islandContent.center = CGPointMake(_island.bounds.size.width / 2, _island.bounds.size.height / 2);
    [_screen bringSubviewToFront:_island];
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self->_island.frame = big; self->_island.layer.cornerRadius = 10;
        self->_islandContent.center = CGPointMake(big.size.width / 2, big.size.height / 2);
    } completion:nil];
    [UIView animateWithDuration:0.25 delay:0.12 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self->_islandContent.alpha = 1; } completion:nil];
    NSUInteger g = ++_gen;   // the loop waits while the island talks
    __weak M26Phone *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        M26Phone *s = ws; if (!s || s->_gen != g) return;
        [UIView animateWithDuration:0.15 animations:^{ s->_islandContent.alpha = 0; }];
        CGRect small = [s islandSmall];
        [UIView animateWithDuration:0.5 delay:0.05 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            s->_island.frame = small; s->_island.layer.cornerRadius = 4;
            s->_islandContent.center = CGPointMake(small.size.width / 2, small.size.height / 2);
        } completion:nil];
        [s after:0.8 gen:g do:^{ [s loop:g]; }];
    });
}
- (void)flip:(NSString *)key on:(BOOL)on {
    if (!key.length) return;
    _p[key] = @(on);
    NSDictionary *names = @{@"enabled": @[@"Messages26", @"bubble.left.and.bubble.right.fill"], @"bar": @[@"Glass Message Bar", @"character.cursor.ibeam"],
                            @"menu": @[@"Glass + Menu", @"plus.circle.fill"], @"topbar": @[@"Glass Top Bar", @"chevron.left.circle.fill"],
                            @"bigphoto": @[@"Contact Photo", @"person.crop.circle.fill"], @"bubbles": @[@"Glass Bubbles", @"bubble.left.fill"],
                            @"swipereply": @[@"Swipe to Reply", @"arrowshape.turn.up.left.fill"], @"viewer": @[@"Photo Viewer", @"photo.fill"],
                            @"audiobig": @[@"Audio Bubbles", @"waveform"], @"speaker": @[@"Play on Speaker", @"speaker.wave.3.fill"],
                            @"searchpill": @[@"Search Pill", @"magnifyingglass"], @"lgcompat": @[@"LiquidAss", @"drop.fill"], @"debug": @[@"Debug Info", @"ladybug.fill"]};
    NSArray *n = names[key] ?: @[key, @"gearshape.fill"];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    for (UIView *v in @[_menu ?: (id)NSNull.null, _viewer ?: (id)NSNull.null]) if ([v isKindOfClass:[UIView class]]) [v removeFromSuperview];
    _menu = nil; _viewer = nil; _dot.alpha = 0;
    UIView *old = _chat;
    [self renderChat];
    UIView *nw = _chat; nw.alpha = 0;
    if (old) [_screen insertSubview:old aboveSubview:nw];
    [UIView animateWithDuration:0.35 animations:^{ nw.alpha = 1; old.alpha = 0; } completion:^(__unused BOOL f) { [old removeFromSuperview]; }];
    // the real Dynamic Island at the top of the screen says what changed
    (void)n;
    NSUInteger g = ++_gen;
    [self after:0.7 gen:g do:^{ [self loop:g]; }];
}

#pragma mark the loop
- (void)restart { _gen++; if (self.window && _chat) [self loop:_gen]; }
- (void)after:(CGFloat)t gen:(NSUInteger)g do:(void (^)(void))b {
    __weak M26Phone *ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ M26Phone *s = ws; if (s && s->_gen == g && s.window) b(); });
}
- (void)tapAt:(CGPoint)p {
    [_screen bringSubviewToFront:_dot];
    _dot.center = p; _dot.alpha = 0; _dot.transform = CGAffineTransformMakeScale(1.6, 1.6);
    [UIView animateWithDuration:0.18 animations:^{ self->_dot.alpha = 1; self->_dot.transform = CGAffineTransformMakeScale(0.8, 0.8); } completion:^(__unused BOOL f) {
        [UIView animateWithDuration:0.25 delay:0.05 options:0 animations:^{ self->_dot.alpha = 0; self->_dot.transform = CGAffineTransformIdentity; } completion:nil];
    }];
}
- (void)loop:(NSUInteger)g {
    CGSize S = _screen.bounds.size;
    [_menu removeFromSuperview]; _menu = nil; [_viewer removeFromSuperview]; _viewer = nil;
    // 1. the chat fills in
    for (NSUInteger i = 0; i < _bubbles.count; i++) {
        UIView *b = _bubbles[i];
        [b.layer removeAllAnimations];
        b.alpha = 0; b.transform = CGAffineTransformMakeScale(0.6, 0.6);
        [UIView animateWithDuration:0.45 delay:0.2 + i * 0.12 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:0 animations:^{ b.alpha = 1; b.transform = CGAffineTransformIdentity; } completion:nil];
    }
    CGFloat t = 1.3;
    // 2. swipe to reply
    if ([self on:@"swipereply"]) {
        UIView *r1 = _r1;
        [self after:t gen:g do:^{
            [self->_replyArrow removeFromSuperview];
            UIImageView *ar = M26Sym(self->_chat, @"arrowshape.turn.up.left.fill", 6, CGPointMake(8, CGRectGetMidY(r1.frame)), [UIColor colorWithWhite:1 alpha:0.8]);
            ar.alpha = 0; self->_replyArrow = ar;
            [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ r1.transform = CGAffineTransformMakeTranslation(16, 0); ar.alpha = 1; } completion:^(__unused BOOL f) {
                [UIView animateWithDuration:0.5 delay:0.25 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:0 animations:^{ r1.transform = CGAffineTransformIdentity; ar.alpha = 0; } completion:nil];
            }];
        }];
        t += 1.5;
    }
    // 3. + grows into the glass menu
    if ([self on:@"bar"] && [self on:@"menu"]) {
        [self after:t gen:g do:^{ [self tapAt:self->_plus.center]; }];
        [self after:t + 0.2 gen:g do:^{
            CGRect from = self->_plus.frame, to = CGRectMake(4, S.height - 26 - 52, 58, 52);
            UIView *m = M26Glass(self->_screen, from, 7); m.clipsToBounds = YES;
            m.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.85];
            UIView *rows = [[UIView alloc] initWithFrame:CGRectMake(0, 0, to.size.width, to.size.height)]; rows.alpha = 0;
            NSArray *cols = @[UIColor.systemBlueColor, UIColor.systemGrayColor, UIColor.systemGreenColor];
            for (int i = 0; i < 3; i++) { M26Box(rows, CGRectMake(5, 5 + i * 15.5, 9, 9), 4.5, cols[i]); M26Box(rows, CGRectMake(18, 8 + i * 15.5, 30, 3), 1.5, [UIColor colorWithWhite:1 alpha:0.8]); }
            [m addSubview:rows];
            self->_menu = m; [self->_screen bringSubviewToFront:self->_island];
            [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:0 animations:^{ m.frame = to; m.layer.cornerRadius = 10; } completion:nil];
            [UIView animateWithDuration:0.25 delay:0.15 options:0 animations:^{ rows.alpha = 1; } completion:nil];
        }];
        [self after:t + 1.7 gen:g do:^{
            UIView *m = self->_menu; CGRect back = self->_plus.frame;
            [UIView animateWithDuration:0.12 animations:^{ m.subviews.firstObject.alpha = 0; }];
            [UIView animateWithDuration:0.4 delay:0.04 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{ m.frame = back; m.layer.cornerRadius = 7; } completion:^(__unused BOOL f) {
                [UIView animateWithDuration:0.12 animations:^{ m.alpha = 0; } completion:^(__unused BOOL d) { [m removeFromSuperview]; }];
            }];
        }];
        t += 2.4;
    }
    // 4. a video opens in the iOS 26 viewer
    if ([self on:@"viewer"]) {
        [self after:t gen:g do:^{ [self tapAt:self->_photo.center]; }];
        [self after:t + 0.2 gen:g do:^{
            CGRect from = self->_photo.frame;
            UIView *v = M26Box(self->_screen, from, 6, UIColor.blackColor); v.clipsToBounds = YES;
            UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0, 0, S.width, S.height)]; c.alpha = 0;
            UIView *pic = M26Box(c, CGRectMake(0, S.height / 2 - 30, S.width, 60), 0, UIColor.clearColor);
            CAGradientLayer *gl = [CAGradientLayer layer]; gl.frame = pic.bounds;
            gl.colors = @[(id)[UIColor colorWithRed:0.98 green:0.45 blue:0.35 alpha:1].CGColor, (id)[UIColor colorWithRed:0.55 green:0.25 blue:0.85 alpha:1].CGColor];
            [pic.layer addSublayer:gl];
            UIView *x = M26Glass(c, CGRectMake(4, 13, 12, 12), 6); M26Sym(x, @"xmark", 5, CGPointMake(6, 6), nil);
            M26Box(c, CGRectMake(S.width / 2 - 10, 18, 20, 3), 1.5, UIColor.whiteColor);
            UIView *pl = M26Glass(c, CGRectMake(S.width / 2 - 10, S.height / 2 - 10, 20, 20), 10); pl.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.75]; M26Sym(pl, @"play.fill", 8, CGPointMake(10, 10), nil);
            for (int i = -1; i <= 1; i += 2) { UIView *s = M26Glass(c, CGRectMake(S.width / 2 + i * 24 - 7, S.height / 2 - 7, 14, 14), 7); s.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.75]; }
            UIView *bar = M26Glass(c, CGRectMake(4, S.height - 44, S.width - 8, 12), 6);
            UIView *fill = M26Box(bar, CGRectMake(14, 5, 0, 2), 1, UIColor.whiteColor);
            M26Glass(c, CGRectMake(4, S.height - 26, 30, 14), 7);
            M26Glass(c, CGRectMake(S.width - 18, S.height - 26, 14, 14), 7);
            [v addSubview:c];
            self->_viewer = v; [self->_screen bringSubviewToFront:self->_island];
            [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:0 animations:^{ v.frame = self->_screen.bounds; v.layer.cornerRadius = 13; } completion:nil];
            [UIView animateWithDuration:0.25 delay:0.18 options:0 animations:^{ c.alpha = 1; } completion:nil];
            [UIView animateWithDuration:1.4 delay:0.6 options:UIViewAnimationOptionCurveLinear animations:^{ fill.frame = CGRectMake(14, 5, S.width - 40, 2); } completion:nil];
        }];
        [self after:t + 2.4 gen:g do:^{
            UIView *v = self->_viewer; CGRect back = self->_photo.frame;
            [UIView animateWithDuration:0.12 animations:^{ v.subviews.firstObject.alpha = 0; }];
            [UIView animateWithDuration:0.45 delay:0.04 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{ v.frame = back; v.layer.cornerRadius = 6; } completion:^(__unused BOOL f) {
                [UIView animateWithDuration:0.12 animations:^{ v.alpha = 0; } completion:^(__unused BOOL d) { [v removeFromSuperview]; }];
            }];
        }];
        t += 3.2;
    }
    [self after:t + 0.8 gen:g do:^{ [self loop:g]; }];
}
@end

#pragma mark - the cell and the page

static void M26PreviewLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    if (![cv viewWithTag:0x4D323650]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *t = [UILabel new]; t.tag = 0x4D323651; t.numberOfLines = 0;
        t.text = @"Live Preview"; t.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold]; t.textColor = UIColor.labelColor;
        UILabel *b = [UILabel new]; b.tag = 0x4D323652; b.numberOfLines = 0;
        b.text = @"Your chat with Messages26. Flip a switch below and watch it change: it changes right away.";
        b.font = [UIFont systemFontOfSize:15]; b.textColor = UIColor.secondaryLabelColor;
        M26Phone *ph = [[M26Phone alloc] initWithFrame:CGRectMake(0, 0, 100, 206)]; ph.tag = 0x4D323650;
        [cv addSubview:t]; [cv addSubview:b]; [cv addSubview:ph];
    }
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height, m = 18;
    UIView *ph = [cv viewWithTag:0x4D323650];
    ph.frame = CGRectMake(W - 100 - 22, (H - 206) / 2, 100, 206);
    CGFloat tw = CGRectGetMinX(ph.frame) - m - 16;
    UILabel *t = (UILabel *)[cv viewWithTag:0x4D323651], *b = (UILabel *)[cv viewWithTag:0x4D323652];
    CGFloat th = ceil([t sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height), bh = ceil([b sizeThatFits:CGSizeMake(tw, CGFLOAT_MAX)].height);
    CGFloat y = MAX(12, (H - th - 6 - bh) / 2);
    t.frame = CGRectMake(m, y, tw, th); b.frame = CGRectMake(m, y + th + 6, tw, bh);
}
static Class M26PreviewClass(void) {
    Class sup = NSClassFromString(@"PSTableCell"); if (!sup) return nil;
    Class c = objc_getClass("M26PreviewCell");
    if (!c) { c = objc_allocateClassPair(sup, "M26PreviewCell", 0); class_addMethod(c, @selector(layoutSubviews), (IMP)M26PreviewLayout, "v@:"); objc_registerClassPair(c); }
    return c;
}

#pragma mark - Insights demo (a little phone: swipe up on the search pill, the Dynamic Pill opens and closes)

@interface M26InsDemo : UIView
@end
@implementation M26InsDemo {
    UIView *_screen, *_pill, *_island, *_content, *_dot, *_drop, *_neck;
    NSUInteger _gen;
    CGRect _pillR, _bigR;
}
static UIView *M26IBox(UIView *in, CGRect r, CGFloat rad, UIColor *c) {
    UIView *v = [[UIView alloc] initWithFrame:r]; v.backgroundColor = c; v.layer.cornerRadius = rad;
    // capsules and circles stay round (a continuous curve at half the height turns them into lenses)
    v.layer.cornerCurve = rad >= MIN(r.size.width, r.size.height) / 2 - 0.5 ? kCACornerCurveCircular : kCACornerCurveContinuous;
    [in addSubview:v]; return v;
}
// the search pill's glass: dark, with a bright rim along the top (like the real one)
static void M26IGlass(UIView *v) {
    v.layer.borderWidth = 0.6; v.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    CAGradientLayer *hi = [CAGradientLayer layer]; hi.frame = v.bounds; hi.cornerRadius = v.layer.cornerRadius;
    hi.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.16].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    hi.endPoint = CGPointMake(0.5, 0.45); [v.layer insertSublayer:hi atIndex:0];
}
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    CGFloat W = f.size.width, H = f.size.height;
    UIView *body = M26IBox(self, self.bounds, 22, [UIColor colorWithWhite:0.1 alpha:1]);
    body.layer.borderWidth = 2; body.layer.borderColor = [UIColor colorWithWhite:0.35 alpha:1].CGColor;
    _screen = M26IBox(body, CGRectInset(body.bounds, 4, 4), 18, UIColor.blackColor); _screen.clipsToBounds = YES;
    CGFloat sw = _screen.bounds.size.width, sh = _screen.bounds.size.height;
    M26IBox(_screen, CGRectMake((sw - 30) / 2, 5, 30, 8), 4, [UIColor colorWithWhite:0 alpha:1]).layer.borderWidth = 0;
    [self label:@"Messages" in:_screen frame:CGRectMake(9, 18, sw, 14) size:11 weight:UIFontWeightBold];
    // the chat list
    for (int i = 0; i < 6; i++) {
        CGFloat y = 40 + i * 27;
        M26IBox(_screen, CGRectMake(9, y, 18, 18), 9, [UIColor colorWithHue:0.1 + i * 0.13 saturation:0.45 brightness:0.8 alpha:1]);
        M26IBox(_screen, CGRectMake(32, y + 2, 34 + (i * 7) % 20, 5), 2.5, [UIColor colorWithWhite:1 alpha:0.75]);
        M26IBox(_screen, CGRectMake(32, y + 10, 48 - (i * 5) % 16, 4), 2, [UIColor colorWithWhite:1 alpha:0.3]);
    }
    // the search pill and the compose button, like the real ones
    _pillR = CGRectMake(9, sh - 31, sw - 18 - 27, 21);
    _pill = M26IBox(_screen, _pillR, _pillR.size.height / 2, [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:1]);
    M26IGlass(_pill);
    UIImageView *mag = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightSemibold]]];
    mag.tintColor = [UIColor colorWithWhite:1 alpha:0.6]; mag.contentMode = UIViewContentModeCenter; mag.frame = CGRectMake(5, 0, 12, 21); [_pill addSubview:mag];
    UILabel *sl = [self label:@"Search" in:_pill frame:CGRectMake(18, 0, 40, 21) size:8.5 weight:UIFontWeightRegular]; sl.textColor = [UIColor colorWithWhite:1 alpha:0.55];
    UIImageView *mic = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"mic" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:8 weight:UIImageSymbolWeightRegular]]];
    mic.tintColor = [UIColor colorWithWhite:1 alpha:0.8]; mic.contentMode = UIViewContentModeCenter; mic.frame = CGRectMake(_pillR.size.width - 16, 0, 12, 21); [_pill addSubview:mic];
    UIView *comp = M26IBox(_screen, CGRectMake(sw - 9 - 21, sh - 31, 21, 21), 10.5, [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:1]);
    M26IGlass(comp);
    UIImageView *pen = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.and.pencil" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:8.5 weight:UIImageSymbolWeightSemibold]]];
    pen.tintColor = UIColor.whiteColor; pen.contentMode = UIViewContentModeCenter; pen.frame = comp.bounds; [comp addSubview:pen];
    // the liquid drop (neck + ball) that pulls out of the pill
    _neck = M26IBox(_screen, CGRectZero, 0, [UIColor colorWithRed:0.115 green:0.115 blue:0.12 alpha:1]);
    _drop = M26IBox(_screen, CGRectMake(0, 0, 14, 14), 7, [UIColor colorWithRed:0.07 green:0.07 blue:0.075 alpha:1]);
    _drop.layer.borderWidth = 0.6; _drop.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    [_screen bringSubviewToFront:_pill];
    // the island (hidden until it opens)
    _bigR = CGRectMake(4, 18, sw - 8, sh - 18 - 6);
    _island = M26IBox(_screen, _pillR, 10, [UIColor colorWithWhite:0.06 alpha:1]);
    _island.layer.borderWidth = 0.6; _island.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor; _island.clipsToBounds = YES; _island.alpha = 0;
    _content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bigR.size.width, _bigR.size.height)];
    [_island addSubview:_content];
    CGFloat cw = _bigR.size.width;
    [self label:@"Insights" in:_content frame:CGRectMake(9, 8, cw, 16) size:13 weight:UIFontWeightHeavy];
    [self label:@"12,480" in:_content frame:CGRectMake(9, 28, cw, 18) size:15 weight:UIFontWeightBold];
    UIView *bar = M26IBox(_content, CGRectMake(9, 50, cw - 18, 4), 2, [UIColor colorWithWhite:1 alpha:0.15]);
    M26IBox(bar, CGRectMake(0, 0, (cw - 18) * 0.46, 4), 2, UIColor.systemBlueColor);
    NSArray *tc = @[UIColor.systemOrangeColor, UIColor.systemPinkColor, UIColor.systemRedColor, UIColor.systemPurpleColor];
    CGFloat tw = (cw - 18 - 5) / 2;
    for (int i = 0; i < 4; i++) {
        UIView *tile = M26IBox(_content, CGRectMake(9 + (i % 2) * (tw + 5), 60 + (i / 2) * 25, tw, 21), 6, [UIColor colorWithWhite:1 alpha:0.08]);
        M26IBox(tile, CGRectMake(4, 5, 11, 11), 3, tc[i]);
        M26IBox(tile, CGRectMake(19, 8, 16 + i * 3, 5), 2.5, [UIColor colorWithWhite:1 alpha:0.7]);
    }
    UIView *wk = M26IBox(_content, CGRectMake(9, 114, cw - 18, 50), 7, [UIColor colorWithWhite:1 alpha:0.08]);
    CGFloat hs[] = {0.4, 0.55, 0.35, 0.7, 1, 0.8, 0.5};
    CGFloat bw = (wk.bounds.size.width - 12) / 7;
    for (int i = 0; i < 7; i++) M26IBox(wk, CGRectMake(6 + i * bw + bw * 0.22, 44 - 36 * hs[i], bw * 0.56, 36 * hs[i]), 2, i == 4 ? UIColor.systemBlueColor : [UIColor colorWithWhite:1 alpha:0.22]);
    UILabel *em = [self label:@"😂 🔥 ❤️ 💀 😭" in:_content frame:CGRectMake(9, 170, cw, 16) size:11 weight:UIFontWeightRegular]; (void)em;
    _dot = M26IBox(_screen, CGRectMake(0, 0, 16, 16), 8, [UIColor colorWithWhite:1 alpha:0.75]);
    _dot.layer.borderWidth = 1.5; _dot.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:0.9].CGColor; _dot.alpha = 0;
    return self;
}
- (UILabel *)label:(NSString *)s in:(UIView *)v frame:(CGRect)f size:(CGFloat)sz weight:(UIFontWeight)w {
    UILabel *l = [[UILabel alloc] initWithFrame:f]; l.text = s; l.font = [UIFont systemFontOfSize:sz weight:w]; l.textColor = UIColor.whiteColor; [v addSubview:l]; return l;
}
- (void)didMoveToWindow { [super didMoveToWindow]; _gen++; if (self.window) [self loop:_gen]; }
- (void)after:(double)t gen:(NSUInteger)g do:(void (^)(void))b { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(t * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (g == self->_gen && self.window) b(); }); }
- (void)loop:(NSUInteger)g {
    UIView *pill = _pill, *isl = _island, *ct = _content, *dot = _dot;
    CGRect P = _pillR, B = _bigR;
    [UIView performWithoutAnimation:^{
        isl.alpha = 0; isl.frame = P; isl.layer.cornerRadius = P.size.height / 2;
        ct.alpha = 0; ct.transform = CGAffineTransformMakeScale(0.3, 0.3); ct.center = CGPointMake(P.size.width / 2, P.size.height / 2);
        pill.alpha = 1; pill.transform = CGAffineTransformIdentity;
        dot.center = CGPointMake(CGRectGetMidX(P), CGRectGetMidY(P) + 6); dot.alpha = 0; dot.transform = CGAffineTransformIdentity;
    }];
    UIView *drop = _drop, *neck = _neck;
    CGFloat dx = CGRectGetMidX(P) - 6, top = CGRectGetMinY(P);
    [UIView performWithoutAnimation:^{
        drop.alpha = 0; drop.bounds = CGRectMake(0, 0, 8, 8); drop.layer.cornerRadius = 4; drop.center = CGPointMake(dx, top + 2);
        neck.alpha = 0; neck.frame = CGRectMake(dx - 4, top, 8, 2); neck.layer.cornerRadius = 0;
    }];
    // a finger comes down on the pill and pulls up: a drop of the pill's glass stretches out on a neck
    [UIView animateWithDuration:0.25 delay:0.5 options:0 animations:^{ dot.alpha = 1; dot.center = CGPointMake(dx, CGRectGetMidY(P)); dot.transform = CGAffineTransformMakeScale(0.85, 0.85); } completion:nil];
    [self after:0.85 gen:g do:^{
        drop.alpha = 1; neck.alpha = 1;
        [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.5 options:0 animations:^{
            dot.center = CGPointMake(dx, top - 26);
            drop.bounds = CGRectMake(0, 0, 16, 17); drop.layer.cornerRadius = 8; drop.center = CGPointMake(dx, top - 22);
            neck.frame = CGRectMake(dx - 2.5, top - 16, 5, 17); neck.layer.cornerRadius = 2.5;
        } completion:nil];
    }];
    // the neck snaps and the island grows out of the drop
    [self after:1.45 gen:g do:^{
        [UIView animateWithDuration:0.2 animations:^{ dot.alpha = 0; }];
        [UIView animateWithDuration:0.12 animations:^{ neck.frame = CGRectMake(dx - 1, top - 3, 2, 3); neck.alpha = 0; }];
        CGRect c = [drop convertRect:drop.bounds toView:self->_screen];
        [UIView performWithoutAnimation:^{ isl.frame = c; isl.layer.cornerRadius = c.size.width / 2; isl.alpha = 1; drop.alpha = 0; ct.center = CGPointMake(c.size.width / 2, c.size.height / 2); }];
        CGRect tall = CGRectMake(CGRectGetMidX(c) - 10, CGRectGetMaxY(c) - 44, 20, 44);
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ isl.frame = tall; isl.layer.cornerRadius = 10; ct.center = CGPointMake(10, 22); } completion:^(__unused BOOL f) {
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.8 options:0 animations:^{
                isl.frame = B; isl.layer.cornerRadius = 16;
                ct.transform = CGAffineTransformIdentity; ct.center = CGPointMake(B.size.width / 2, B.size.height / 2);
            } completion:nil];
        }];
        [UIView animateWithDuration:0.18 delay:0.07 options:0 animations:^{ ct.alpha = 1; } completion:nil];
        [self after:0.3 gen:g do:^{ pill.alpha = 0; }];
    }];
    // a moment later it closes like the Dynamic Island, into a drop above the pill that's sucked back in
    [self after:3.8 gen:g do:^{
        CGRect dr = CGRectMake(dx - 8, top - 30, 16, 16);
        CGRect mid = CGRectMake(B.origin.x + 4, CGRectGetMinY(dr) - 40, B.size.width - 8, 56);
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            isl.frame = mid; isl.layer.cornerRadius = 14; ct.alpha = 0; ct.transform = CGAffineTransformMakeScale(0.5, 0.5); ct.center = CGPointMake(mid.size.width / 2, mid.size.height / 2);
        } completion:^(__unused BOOL f) {
            [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ isl.frame = dr; isl.layer.cornerRadius = 8; } completion:^(__unused BOOL f2) {
                pill.alpha = 1; isl.alpha = 0;
                [UIView performWithoutAnimation:^{ drop.alpha = 1; drop.bounds = CGRectMake(0, 0, 16, 16); drop.layer.cornerRadius = 8; drop.center = CGPointMake(CGRectGetMidX(dr), CGRectGetMidY(dr)); neck.alpha = 1; neck.frame = CGRectMake(dx - 2.5, CGRectGetMidY(dr), 5, top - CGRectGetMidY(dr)); }];
                [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    drop.bounds = CGRectMake(0, 0, 6, 6); drop.layer.cornerRadius = 3; drop.center = CGPointMake(dx, top + 2);
                    neck.frame = CGRectMake(dx - 4, top, 8, 2);
                } completion:^(__unused BOOL f3) {
                    drop.alpha = 0; neck.alpha = 0;
                    pill.transform = CGAffineTransformMakeScale(1.07, 0.84);
                    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.42 initialSpringVelocity:0.6 options:0 animations:^{ pill.transform = CGAffineTransformIdentity; } completion:nil];
                }];
            }];
        }];
    }];
    [self after:6.2 gen:g do:^{ [self loop:g]; }];
}
@end
static void M26InsDemoLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES;
    UIView *ph = [cv viewWithTag:0x4D324944];
    if (!ph) { ph = [[M26InsDemo alloc] initWithFrame:CGRectMake(0, 0, 112, 226)]; ph.tag = 0x4D324944; [cv addSubview:ph]; }
    ph.center = CGPointMake(cv.bounds.size.width / 2, cv.bounds.size.height / 2);
}
static Class M26InsDemoClass(void) {
    Class sup = NSClassFromString(@"PSTableCell"); if (!sup) return nil;
    Class c = objc_getClass("M26InsDemoCell");
    if (!c) { c = objc_allocateClassPair(sup, "M26InsDemoCell", 0); class_addMethod(c, @selector(layoutSubviews), (IMP)M26InsDemoLayout, "v@:"); objc_registerClassPair(c); }
    return c;
}

static NSArray *(*origM26Specs)(id, SEL);
static NSArray *M26Specs(id self, SEL _cmd) {
    NSArray *a = origM26Specs(self, _cmd);
    @try {
        for (id s in a) {
            if (![s respondsToSelector:@selector(identifier)]) continue;
            Class c = [[s identifier] isEqualToString:@"M26_PREVIEW"] ? M26PreviewClass() : [[s identifier] isEqualToString:@"M26_INSDEMO"] ? M26InsDemoClass() : nil;
            if (c && [s propertyForKey:@"cellClass"] != c) ((void (*)(id, SEL, id, id))objc_msgSend)(s, @selector(setProperty:forKey:), c, @"cellClass");
        }
    } @catch (__unused id e) {}
    return a;
}
static void (*origM26SetPref)(id, SEL, id, id);
static void M26SetPref(id self, SEL _cmd, id value, id spec) {
    origM26SetPref(self, _cmd, value, spec);
    @try {
        if ([[spec propertyForKey:@"defaults"] isEqualToString:@"com.nano.messages26"] && [spec propertyForKey:@"key"])
            [[NSNotificationCenter defaultCenter] postNotificationName:kM26Flip object:nil userInfo:@{@"key": [spec propertyForKey:@"key"], @"value": value ?: @NO}];
    } @catch (__unused id e) {}
}
static void StartM26Settings(void) {
    static BOOL done; if (done) return;
    Class PS = NSClassFromString(@"PSListController");
    if (!PS) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ StartM26Settings(); }); return; }
    done = YES;
    MSHookMessageEx(PS, @selector(specifiers), (IMP)M26Specs, (IMP *)&origM26Specs);
    MSHookMessageEx(PS, @selector(setPreferenceValue:specifier:), (IMP)M26SetPref, (IMP *)&origM26SetPref);
}
