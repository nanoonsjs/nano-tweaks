// ===================== Messages26: Conversation Insights =====================
// 1.7: swipe up on the search pill (conversation list) and Insights pulls up with your finger: messages, emojis,
// busiest days, photos / videos, voice messages, most-used words, and the people you text most (tap one for
// that conversation). Counted on the phone by M26Keeper (Insights.m) in the Messages background service.
// Included from Tweak.x after the search pill code.

#define INS_DIR @"/var/mobile/Library/SMS/M26Unsent"

#pragma mark - asking M26Keeper

static NSString *gInsReq;
static void (^gInsCB)(NSDictionary *);
static void InsDone(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef ui) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *r = [NSDictionary dictionaryWithContentsOfFile:INS_DIR @"/insights_res.plist"];
        if (!gInsCB || ![r[@"req"] isEqualToString:gInsReq]) return;
        void (^cb)(NSDictionary *) = gInsCB; gInsCB = nil;
        cb(r);
    });
}
static void InsAsk(NSString *chat, void (^cb)(NSDictionary *)) {
    static dispatch_once_t o;
    dispatch_once(&o, ^{ CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, InsDone, CFSTR("com.nano.messages26/insights.done"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately); });
    NSString *rid = [NSUUID UUID].UUIDString;
    gInsReq = rid; gInsCB = cb;
    [[NSFileManager defaultManager] createDirectoryAtPath:INS_DIR withIntermediateDirectories:YES attributes:nil error:nil];
    [@{@"chat": chat ?: @"*", @"id": rid} writeToFile:INS_DIR @"/insights_req.plist" atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/insights.req"), NULL, NULL, YES);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([gInsReq isEqualToString:rid] && gInsCB) { void (^c2)(NSDictionary *) = gInsCB; gInsCB = nil; c2(@{@"error": @"No answer from the Messages background service. Respring (or reinstall Messages26) and try again."}); }
    });
}
// a chat id (phone / email / group id) as the name Messages shows
static NSString *InsName(NSString *cid, NSString *fallback) {
    Class CL = NSClassFromString(@"CKConversationList"); SEL sh = NSSelectorFromString(@"sharedConversationList");
    id list = [CL respondsToSelector:sh] ? ((id (*)(id, SEL))objc_msgSend)(CL, sh) : nil;
    NSArray *convs = nil; @try { convs = [list valueForKey:@"conversations"]; } @catch (__unused id e) {}
    for (id conv in convs) {
        NSString *k = nil; @try { k = [conv valueForKeyPath:@"chat.chatIdentifier"]; } @catch (__unused id e) {}
        if (![k isEqualToString:cid]) continue;
        for (NSString *nk in @[@"displayName", @"name"]) { NSString *n = nil; @try { n = [conv valueForKey:nk]; } @catch (__unused id e) {} if ([n isKindOfClass:[NSString class]] && n.length) return n; }
    }
    if (fallback.length) return fallback;
    return [cid hasPrefix:@"chat"] ? @"Group" : cid;
}
static NSString *InsNum(long n) { NSNumberFormatter *f = [NSNumberFormatter new]; f.numberStyle = NSNumberFormatterDecimalStyle; return [f stringFromNumber:@(n)]; }

#pragma mark - the sheet

@interface M26Insights : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *dim, *sheet, *grab;
@property (nonatomic, strong) UIVisualEffectView *glass;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIActivityIndicatorView *spin;
@property (nonatomic, strong) UILabel *loading;
@property (nonatomic, strong) NSDictionary *allData;
@property (nonatomic) CGFloat openY, dragStart;
@property (nonatomic) BOOL dark;
@end
static __weak M26Insights *gIns;

@implementation M26Insights
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.dark = self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight;
    self.dim = [[UIView alloc] initWithFrame:self.bounds];
    self.dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35]; self.dim.alpha = 0;
    self.dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    [self addSubview:self.dim];

    CGFloat top = MAX(54, self.safeAreaInsets.top + 10);
    self.openY = top;
    self.sheet = [[UIView alloc] initWithFrame:CGRectMake(0, top, f.size.width, f.size.height - top + 40)];
    self.sheet.layer.shadowColor = UIColor.blackColor.CGColor; self.sheet.layer.shadowOpacity = 0.3; self.sheet.layer.shadowRadius = 24;
    [self addSubview:self.sheet];
    self.glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:self.dark ? UIBlurEffectStyleSystemChromeMaterialDark : UIBlurEffectStyleSystemChromeMaterialLight]];
    self.glass.frame = self.sheet.bounds; self.glass.layer.cornerRadius = 36; self.glass.layer.cornerCurve = kCACornerCurveContinuous; self.glass.clipsToBounds = YES;
    self.glass.layer.borderWidth = 0.75; self.glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:self.dark ? 0.14 : 0.6].CGColor;
    [self.sheet addSubview:self.glass];

    self.grab = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - 40) / 2, 8, 40, 5)];
    self.grab.backgroundColor = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.28]; self.grab.layer.cornerRadius = 2.5;
    [self.sheet addSubview:self.grab];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, f.size.width, self.sheet.bounds.size.height - 20 - 40)];
    self.scroll.alwaysBounceVertical = YES; self.scroll.showsVerticalScrollIndicator = NO;
    [self.sheet addSubview:self.scroll];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sheetPan:)];
    pan.delegate = self; [self.sheet addGestureRecognizer:pan];

    self.spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spin.center = CGPointMake(f.size.width / 2, 170); [self.spin startAnimating];
    [self.sheet addSubview:self.spin];
    self.loading = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, f.size.width - 40, 22)];
    self.loading.text = @"Counting your messages…"; self.loading.textAlignment = NSTextAlignmentCenter;
    self.loading.textColor = UIColor.secondaryLabelColor; self.loading.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.sheet addSubview:self.loading];
    return self;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o { return YES; }
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    CGPoint v = [g velocityInView:self];
    return v.y > fabs(v.x) && (self.scroll.contentOffset.y <= 0 || [g locationInView:self.sheet].y < 40);
}
// pulled down from the top of the list: the sheet follows, and closes past a point
- (void)sheetPan:(UIPanGestureRecognizer *)g {
    CGFloat dy = MAX(0, [g translationInView:self].y);
    if (g.state == UIGestureRecognizerStateChanged) {
        if (self.scroll.contentOffset.y > 0 && [g locationInView:self.sheet].y > 40) return;
        self.scroll.contentOffset = CGPointZero;
        [self setPull:dy];
    } else if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        if (dy > 140 || [g velocityInView:self].y > 900) [self close]; else [self settle];
    }
}
- (void)setPull:(CGFloat)dy {   // dy = how far below fully open
    CGFloat H = self.bounds.size.height;
    self.sheet.transform = CGAffineTransformMakeTranslation(0, dy);
    self.dim.alpha = MAX(0, MIN(1, 1 - dy / (H - self.openY)));
}
- (void)settle {
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{ [self setPull:0]; } completion:nil];
}
- (void)close {
    gInsCB = nil;
    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ [self setPull:self.bounds.size.height - self.openY + 40]; } completion:^(BOOL f) { [self removeFromSuperview]; }];
}

#pragma mark building the cards
- (UIView *)card:(CGFloat)y height:(CGFloat)h {
    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(16, y, self.bounds.size.width - 32, h)];
    c.backgroundColor = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:self.dark ? 0.07 : 0.045];
    c.layer.cornerRadius = 24; c.layer.cornerCurve = kCACornerCurveContinuous;
    [self.scroll addSubview:c];
    return c;
}
- (UILabel *)label:(NSString *)t size:(CGFloat)s weight:(UIFontWeight)w color:(UIColor *)col in:(UIView *)v frame:(CGRect)fr {
    UILabel *l = [[UILabel alloc] initWithFrame:fr]; l.text = t; l.font = [UIFont systemFontOfSize:s weight:w]; l.textColor = col;
    l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.6; [v addSubview:l]; return l;
}
- (UILabel *)cardTitle:(NSString *)t in:(UIView *)c { return [self label:t.uppercaseString size:13 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:c frame:CGRectMake(18, 14, c.bounds.size.width - 36, 18)]; }
- (void)show:(NSDictionary *)d chat:(NSString *)chat name:(NSString *)name {
    [self.spin stopAnimating]; self.loading.hidden = YES;
    for (UIView *v in self.scroll.subviews.copy) [v removeFromSuperview];
    CGFloat W = self.bounds.size.width, y = 6;
    BOOL all = [chat isEqualToString:@"*"];
    if (!all) {   // back to everything
        UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
        [back setImage:[UIImage systemImageNamed:@"chevron.left" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
        [back setTitle:@" All" forState:UIControlStateNormal]; back.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        back.frame = CGRectMake(14, y, 80, 34); back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [back addTarget:self action:@selector(backToAll) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:back]; y += 34;
    }
    [self label:all ? @"Insights" : name size:34 weight:UIFontWeightBold color:UIColor.labelColor in:self.scroll frame:CGRectMake(22, y, W - 44, 42)]; y += 42;
    NSString *sub = @"All your conversations";
    double first = [d[@"first"] doubleValue];
    if (first > 0) {
        NSDateFormatter *f = [NSDateFormatter new]; f.dateStyle = NSDateFormatterMediumStyle;
        sub = [NSString stringWithFormat:@"%@ · since %@", all ? @"All conversations" : @"This conversation", [f stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:first]]];
    }
    [self label:sub size:15 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:self.scroll frame:CGRectMake(22, y, W - 44, 20)]; y += 32;
    if (d[@"error"]) {
        UIView *c = [self card:y height:90];
        UILabel *l = [self label:d[@"error"] size:15 weight:UIFontWeightRegular color:UIColor.labelColor in:c frame:CGRectInset(c.bounds, 18, 10)];
        l.numberOfLines = 0; l.adjustsFontSizeToFitWidth = NO;
        self.scroll.contentSize = CGSizeMake(W, y + 120); return;
    }

    // big numbers
    long total = [d[@"total"] longValue];
    UIView *hero = [self card:y height:128];
    [self label:InsNum(total) size:46 weight:UIFontWeightHeavy color:UIColor.labelColor in:hero frame:CGRectMake(18, 14, hero.bounds.size.width - 36, 54)];
    [self label:@"messages" size:15 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:hero frame:CGRectMake(20, 64, 200, 20)];
    // sent vs received bar
    CGFloat bw = hero.bounds.size.width - 36, mf = total ? [d[@"mine"] doubleValue] / total : 0.5;
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(18, 94, bw, 10)]; bar.layer.cornerRadius = 5; bar.clipsToBounds = YES;
    bar.backgroundColor = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.15]; [hero addSubview:bar];
    UIView *mb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bw * mf, 10)]; mb.backgroundColor = UIColor.systemBlueColor; [bar addSubview:mb];
    [self label:[NSString stringWithFormat:@"You %@", InsNum([d[@"mine"] longValue])] size:12 weight:UIFontWeightSemibold color:UIColor.systemBlueColor in:hero frame:CGRectMake(18, 106, bw / 2, 16)];
    UILabel *tl = [self label:[NSString stringWithFormat:@"%@ %@", all ? @"Others" : @"Them", InsNum([d[@"theirs"] longValue])] size:12 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:hero frame:CGRectMake(18 + bw / 2, 106, bw / 2, 16)];
    tl.textAlignment = NSTextAlignmentRight;
    y += 128 + 12;

    // tiles
    NSArray *tiles = @[@[@"photo.fill", UIColor.systemOrangeColor, d[@"photos"], @"Photos"], @[@"video.fill", UIColor.systemPinkColor, d[@"videos"], @"Videos"],
                       @[@"waveform", UIColor.systemRedColor, d[@"voice"], @"Voice messages"], @[@"heart.fill", UIColor.systemPurpleColor, d[@"reactions"], @"Reactions"],
                       @[@"calendar", UIColor.systemGreenColor, d[@"activeDays"], @"Days you talked"], @[@"paperclip", UIColor.systemTealColor, d[@"files"], @"Files"]];
    CGFloat tw = (W - 32 - 12) / 2, th = 92;
    for (NSUInteger i = 0; i < tiles.count; i++) {
        NSArray *t = tiles[i];
        UIView *c = [self card:y + (i / 2) * (th + 12) height:th];
        CGRect fr = c.frame; fr.origin.x = 16 + (i % 2) * (tw + 12); fr.size.width = tw; c.frame = fr;
        UIImageView *ic = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:t[0] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold]]];
        ic.tintColor = UIColor.whiteColor; ic.contentMode = UIViewContentModeCenter; ic.backgroundColor = t[1];
        ic.frame = CGRectMake(14, 14, 30, 30); ic.layer.cornerRadius = 9; [c addSubview:ic];
        [self label:InsNum([t[2] longValue]) size:26 weight:UIFontWeightBold color:UIColor.labelColor in:c frame:CGRectMake(14, 48, tw - 28, 28)];
        [self label:t[3] size:12 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor in:c frame:CGRectMake(56, 20, tw - 66, 18)];
    }
    y += ((tiles.count + 1) / 2) * (th + 12);

    // emojis
    NSArray *em = d[@"myEmoji"];
    if (em.count) {
        UIView *c = [self card:y height:118];
        [self cardTitle:@"Your most-used emojis" in:c];
        CGFloat cw = (c.bounds.size.width - 24) / MIN(6, em.count);
        for (NSUInteger i = 0; i < MIN(6, em.count); i++) {
            [self label:em[i][0] size:36 weight:UIFontWeightRegular color:UIColor.labelColor in:c frame:CGRectMake(12 + i * cw, 38, cw, 44)].textAlignment = NSTextAlignmentCenter;
            [self label:InsNum([em[i][1] longValue]) size:12 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:c frame:CGRectMake(12 + i * cw, 84, cw, 16)].textAlignment = NSTextAlignmentCenter;
        }
        y += 118 + 12;
    }

    // busiest days
    NSArray *wd = d[@"weekdays"];
    if (wd.count == 7 && total) {
        UIView *c = [self card:y height:212];
        [self cardTitle:@"Most active days" in:c];
        long mx = 1; NSUInteger best = 0;
        for (NSUInteger i = 0; i < 7; i++) { long v = [wd[i] longValue]; if (v > mx) { mx = v; best = i; } }
        NSArray *names = @[@"M", @"T", @"W", @"T", @"F", @"S", @"S"], *full = @[@"Mondays", @"Tuesdays", @"Wednesdays", @"Thursdays", @"Fridays", @"Saturdays", @"Sundays"];
        CGFloat cw = (c.bounds.size.width - 36) / 7, base = 150, maxH = 96;
        for (NSUInteger i = 0; i < 7; i++) {
            CGFloat h = MAX(4, maxH * [wd[i] doubleValue] / mx);
            UIView *b = [[UIView alloc] initWithFrame:CGRectMake(18 + i * cw + cw * 0.2, base - h, cw * 0.6, h)];
            b.backgroundColor = i == best ? UIColor.systemBlueColor : [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.18];
            b.layer.cornerRadius = MIN(8, cw * 0.3); [c addSubview:b];
            [self label:names[i] size:12 weight:UIFontWeightSemibold color:i == best ? UIColor.systemBlueColor : UIColor.secondaryLabelColor in:c frame:CGRectMake(18 + i * cw, base + 4, cw, 16)].textAlignment = NSTextAlignmentCenter;
        }
        // peak hour and the single busiest day
        NSArray *hr = d[@"hours"]; NSUInteger bh = 0; long hm = -1;
        for (NSUInteger i = 0; i < hr.count; i++) if ([hr[i] longValue] > hm) { hm = [hr[i] longValue]; bh = i; }
        NSString *hs = [NSString stringWithFormat:@"%lu %@", (unsigned long)(bh % 12 == 0 ? 12 : bh % 12), bh < 12 ? @"AM" : @"PM"];
        NSString *line = [NSString stringWithFormat:@"Busiest on %@, around %@", full[best], hs];
        NSArray *bd = d[@"busiest"];
        if (bd.count == 2) {
            NSDateFormatter *in = [NSDateFormatter new]; in.dateFormat = @"yyyy-MM-dd";
            NSDateFormatter *out = [NSDateFormatter new]; out.dateStyle = NSDateFormatterMediumStyle;
            NSDate *dd = [in dateFromString:bd[0]];
            if (dd) line = [line stringByAppendingFormat:@"\nBiggest day: %@ (%@ messages)", [out stringFromDate:dd], InsNum([bd[1] longValue])];
        }
        UILabel *l = [self label:line size:13 weight:UIFontWeightMedium color:UIColor.labelColor in:c frame:CGRectMake(18, 172, c.bounds.size.width - 36, 34)];
        l.numberOfLines = 2; l.adjustsFontSizeToFitWidth = NO;
        y += 212 + 12;
    }

    // words
    NSArray *ws = d[@"myWords"];
    if (ws.count) {
        UIView *c = [self card:y height:60];
        [self cardTitle:@"Your most-used words" in:c];
        CGFloat x = 18, ly = 42, maxW = c.bounds.size.width - 18;
        UIColor *chip = [UIColor colorWithWhite:self.dark ? 1 : 0 alpha:0.1];
        for (NSUInteger i = 0; i < ws.count; i++) {
            UILabel *l = [UILabel new];
            NSMutableAttributedString *a = [[NSMutableAttributedString alloc] initWithString:ws[i][0] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: UIColor.labelColor}];
            [a appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", InsNum([ws[i][1] longValue])] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightMedium], NSForegroundColorAttributeName: UIColor.secondaryLabelColor}]];
            l.attributedText = a; [l sizeToFit];
            CGFloat cw = l.bounds.size.width + 24;
            if (x + cw > maxW) { x = 18; ly += 40; }
            UIView *p = [[UIView alloc] initWithFrame:CGRectMake(x, ly, cw, 32)]; p.backgroundColor = chip; p.layer.cornerRadius = 16;
            l.center = CGPointMake(cw / 2, 16); [p addSubview:l]; [c addSubview:p];
            x += cw + 8;
        }
        CGRect fr = c.frame; fr.size.height = ly + 32 + 16; c.frame = fr;
        y += fr.size.height + 12;
    }

    // the people you text most
    NSArray *top = d[@"top"];
    if (all && top.count) {
        CGFloat rh = 52;
        UIView *c = [self card:y height:44 + top.count * rh];
        [self cardTitle:@"Who you text most" in:c];
        long mx = MAX(1, [top.firstObject[@"count"] longValue]);
        for (NSUInteger i = 0; i < top.count; i++) {
            NSDictionary *t = top[i];
            UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
            row.frame = CGRectMake(0, 40 + i * rh, c.bounds.size.width, rh);
            row.accessibilityIdentifier = t[@"id"]; row.accessibilityLabel = InsName(t[@"id"], t[@"name"]);
            [row addTarget:self action:@selector(openChat:) forControlEvents:UIControlEventTouchUpInside];
            [c addSubview:row];
            [self label:[NSString stringWithFormat:@"%lu", (unsigned long)i + 1] size:15 weight:UIFontWeightBold color:UIColor.secondaryLabelColor in:row frame:CGRectMake(18, 6, 22, 22)];
            [self label:row.accessibilityLabel size:16 weight:UIFontWeightSemibold color:UIColor.labelColor in:row frame:CGRectMake(42, 6, c.bounds.size.width - 150, 22)];
            UILabel *n = [self label:InsNum([t[@"count"] longValue]) size:14 weight:UIFontWeightSemibold color:UIColor.secondaryLabelColor in:row frame:CGRectMake(c.bounds.size.width - 110, 6, 72, 22)];
            n.textAlignment = NSTextAlignmentRight;
            UIImageView *ch = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold]]];
            ch.tintColor = UIColor.tertiaryLabelColor; ch.frame = CGRectMake(c.bounds.size.width - 30, 10, 12, 14); [row addSubview:ch];
            UIView *b = [[UIView alloc] initWithFrame:CGRectMake(42, 33, (c.bounds.size.width - 80) * [t[@"count"] doubleValue] / mx, 6)];
            b.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.75]; b.layer.cornerRadius = 3; b.userInteractionEnabled = NO; [row addSubview:b];
        }
        y += c.bounds.size.height + 12;
    }
    [self label:@"Counted on your iPhone. Nothing leaves it." size:12 weight:UIFontWeightMedium color:UIColor.tertiaryLabelColor in:self.scroll frame:CGRectMake(0, y + 4, W, 16)].textAlignment = NSTextAlignmentCenter;
    self.scroll.contentSize = CGSizeMake(W, y + 60 + self.safeAreaInsets.bottom);
    // the cards float in
    NSArray *vs = self.scroll.subviews; NSUInteger i = 0;
    for (UIView *v in vs) {
        v.alpha = 0; v.transform = CGAffineTransformMakeTranslation(0, 18);
        [UIView animateWithDuration:0.5 delay:0.03 * i++ usingSpringWithDamping:0.85 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ v.alpha = 1; v.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)load:(NSString *)chat name:(NSString *)name {
    self.loading.hidden = NO; [self.spin startAnimating];
    for (UIView *v in self.scroll.subviews.copy) [UIView animateWithDuration:0.15 animations:^{ v.alpha = 0; }];
    __weak typeof(self) me = self;
    InsAsk(chat, ^(NSDictionary *d) {
        if (!me.superview) return;
        if ([chat isEqualToString:@"*"] && !d[@"error"]) me.allData = d;
        [me.scroll setContentOffset:CGPointZero animated:NO];
        [me show:d chat:chat name:name];
    });
}
- (void)openChat:(UIButton *)b { [[[UISelectionFeedbackGenerator alloc] init] selectionChanged]; [self load:b.accessibilityIdentifier name:b.accessibilityLabel]; }
- (void)backToAll {
    if (self.allData) { [self.scroll setContentOffset:CGPointZero animated:NO]; [self show:self.allData chat:@"*" name:nil]; }
    else [self load:@"*" name:nil];
}
@end

#pragma mark - pulled up from the search pill

static M26Insights *InsMake(UIWindow *w) {
    M26Insights *s = [[M26Insights alloc] initWithFrame:w.bounds];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [w addSubview:s];
    gIns = s;
    [s setPull:w.bounds.size.height - s.openY + 40];
    [s load:@"*" name:nil];
    return s;
}
@interface M26InsPan : NSObject <UIGestureRecognizerDelegate>
@end
@implementation M26InsPan
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    if (!Opt(@"insights")) return NO;
    CGPoint v = [g velocityInView:g.view];
    return v.y < 0 && fabs(v.y) > fabs(v.x);   // straight up only (sideways and taps stay the pill's)
}
- (void)pan:(UIPanGestureRecognizer *)g {
    UIWindow *w = g.view.window; if (!w) return;
    M26Insights *s = gIns;
    CGFloat H = w.bounds.size.height;
    if (g.state == UIGestureRecognizerStateBegan) {
        if (!s.superview) s = InsMake(w);
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
        if ([g.view isKindOfClass:[UIControl class]]) [(UIControl *)g.view cancelTrackingWithEvent:nil];
    }
    if (!s) return;
    CGFloat up = -[g translationInView:w].y, closed = H - s.openY + 40;
    if (g.state == UIGestureRecognizerStateChanged) {
        // follows the finger (a little faster than it, so a short swipe goes a long way)
        [s setPull:MAX(0, closed - up * 1.6)];
    } else if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        if (up > 70 || [g velocityInView:w].y < -500) { [s settle]; [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred]; }
        else [s close];
    }
}
@end
static void InsAttach(UIView *pill) {
    if (!pill || objc_getAssociatedObject(pill, "m26ins")) return;
    static M26InsPan *t; if (!t) t = [M26InsPan new];
    UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:t action:@selector(pan:)];
    p.delegate = t; p.cancelsTouchesInView = YES;
    [pill addGestureRecognizer:p];
    objc_setAssociatedObject(pill, "m26ins", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
