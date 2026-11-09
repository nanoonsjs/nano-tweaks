// ===================== nano tweaks: settings page header (runs in the Settings app) =====================
// Any tweak's settings plist can start with a big header card, like MusicPill's:
//   { cell = PSStaticTextCell; id = NANO_HEADER; height = 110;
//     nanoName = "Messages26"; nanoSub = "Messages, iOS 26 style"; nanoVersion = "1.3";
//     nanoIcon = "/var/jb/usr/share/Messages26/icon.png"; }
// Every nano tweak loaded in Settings hooks this the same way; whichever runs first sets the cell.
// The cell is a runtime subclass of PSTableCell, so the tweak never links Preferences.framework.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface NSObject (NanoPS)
- (id)propertyForKey:(NSString *)k;
- (NSString *)identifier;
@end

static void NanoHeaderLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *cv = self.contentView;
    id spec = nil; @try { spec = [self valueForKey:@"specifier"]; } @catch (__unused id e) {}
    UIImageView *ic = (UIImageView *)[cv viewWithTag:0x4E414E31];
    if (!ic) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        ic = [UIImageView new]; ic.tag = 0x4E414E31;
        ic.layer.cornerRadius = 16; ic.layer.cornerCurve = kCACornerCurveContinuous; ic.clipsToBounds = YES;
        NSString *path = [spec propertyForKey:@"nanoIcon"];
        UIImage *img = nil;
        for (NSString *p in @[path ?: @"", [path stringByReplacingOccurrencesOfString:@"/var/jb" withString:@""] ?: @""]) if (p.length && (img = [UIImage imageWithContentsOfFile:p])) break;
        ic.image = img;
        UILabel *t = [UILabel new]; t.tag = 0x4E414E32;
        t.text = [spec propertyForKey:@"nanoName"] ?: @"";
        t.font = [UIFont systemFontOfSize:26 weight:UIFontWeightHeavy]; t.textColor = UIColor.labelColor;
        t.adjustsFontSizeToFitWidth = YES; t.minimumScaleFactor = 0.7;
        UILabel *s = [UILabel new]; s.tag = 0x4E414E33; s.numberOfLines = 2;
        NSString *ver = [spec propertyForKey:@"nanoVersion"];
        s.text = [NSString stringWithFormat:@"%@\n%@made by nano", [spec propertyForKey:@"nanoSub"] ?: @"", ver.length ? [NSString stringWithFormat:@"Version %@ · ", ver] : @""];
        s.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium]; s.textColor = UIColor.secondaryLabelColor;
        [cv addSubview:ic]; [cv addSubview:t]; [cv addSubview:s];
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];   // the icon floats a little
        a.fromValue = @(-1.5); a.toValue = @(1.5); a.duration = 1.8; a.autoreverses = YES; a.repeatCount = HUGE_VALF;
        a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [ic.layer addAnimation:a forKey:@"float"];
    }
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    CGFloat H = cv.bounds.size.height, W = cv.bounds.size.width;
    ic.frame = CGRectMake(18, (H - 68) / 2, 68, 68);
    [cv viewWithTag:0x4E414E32].frame = CGRectMake(100, H / 2 - 30, W - 116, 32);
    [cv viewWithTag:0x4E414E33].frame = CGRectMake(100, H / 2 + 2, W - 116, 38);
}
static Class NanoHeaderClass(void) {
    Class sup = NSClassFromString(@"PSTableCell");
    if (!sup) return nil;
    Class c = objc_getClass("NanoHeaderCell");
    if (!c) {
        c = objc_allocateClassPair(sup, "NanoHeaderCell", 0);
        class_addMethod(c, @selector(layoutSubviews), (IMP)NanoHeaderLayout, "v@:");
        objc_registerClassPair(c);
    }
    return c;
}
static NSArray *(*origNanoSpecs)(id, SEL);
static NSArray *NanoSpecs(id self, SEL _cmd) {
    NSArray *a = origNanoSpecs(self, _cmd);
    @try {
        if (![a isKindOfClass:[NSArray class]]) return a;
        for (id s in a) {
            if (![s respondsToSelector:@selector(identifier)] || ![[s identifier] isEqualToString:@"NANO_HEADER"]) continue;
            Class hc = NanoHeaderClass();
            if (hc && [s propertyForKey:@"cellClass"] != hc) ((void (*)(id, SEL, id, id))objc_msgSend)(s, @selector(setProperty:forKey:), hc, @"cellClass");
            break;
        }
    } @catch (__unused id e) {}
    return a;
}
static void StartNanoSettings(void) {
    static BOOL done; if (done) return;
    Class PS = NSClassFromString(@"PSListController");
    if (!PS) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ StartNanoSettings(); }); return; }
    done = YES;
    MSHookMessageEx(PS, @selector(specifiers), (IMP)NanoSpecs, (IMP *)&origNanoSpecs);
}
