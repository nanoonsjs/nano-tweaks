// NanoGlass 1.1 - made by nano
// 1.1: no slider: just a Liquid Glass switch for all the tweaks (MusicPill too); the blur comes from LiquidAss's own settings
// 1.0: one slider for the glass in all of nano's tweaks: clear liquid glass (LiquidAss's tab bar glass) to frosted,
//      applied live in Messages26, Photos26, InstaGlass and Control26; a live preview in Settings
//
// This tweak is only the settings page (it runs in Settings). The other tweaks read com.nano.glass themselves
// (shared/NanoGlass.h) and refresh when com.nano.glass/changed is posted.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#include "../shared/NanoGlass.h"
#include "../shared/NanoSettings.h"

#pragma mark - live preview: colorful shapes drifting under a glass capsule and a glass button

@interface NGPreview : NSObject
@property (nonatomic, weak) UIView *panel;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) CGFloat shown;
@property (nonatomic) BOOL shownOn;
@end
@implementation NGPreview
- (id)controlIn:(UITableView *)tv key:(NSString *)key cls:(Class)cls {
    for (UITableViewCell *cell in tv.visibleCells) {
        id spec = nil; @try { spec = [cell valueForKey:@"specifier"]; } @catch (__unused id e) {}
        if (![[spec propertyForKey:@"key"] isEqual:key]) continue;
        NSMutableArray *q = [NSMutableArray arrayWithObject:cell]; int n = 0;
        while (q.count && n++ < 60) { UIView *v = q.firstObject; [q removeObjectAtIndex:0]; if ([v isKindOfClass:cls]) return v; [q addObjectsFromArray:v.subviews]; }
    }
    return nil;
}
- (void)tick {
    UIView *p = self.panel;
    if (!p.window) { [self.link invalidate]; self.link = nil; return; }
    UIView *tv = p; while (tv && ![tv isKindOfClass:[UITableView class]]) tv = tv.superview;
    UISlider *sl = [self controlIn:(UITableView *)tv key:@"frost" cls:[UISlider class]];
    UISwitch *sw = [self controlIn:(UITableView *)tv key:@"enabled" cls:[UISwitch class]];
    CGFloat v = sl ? sl.value : NGFrost();
    BOOL on = sw ? sw.isOn : NGOn();
    // the shapes drift
    CFTimeInterval t = CACurrentMediaTime();
    CGFloat W = p.bounds.size.width, H = p.bounds.size.height;
    int i = 0;
    for (CALayer *l in p.layer.sublayers) if ([l.name hasPrefix:@"blob"]) {
        CGFloat ph = i * 2.1;
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        l.position = CGPointMake(W * (0.5 + 0.38 * sin(t * 0.5 + ph)), H * (0.5 + 0.3 * cos(t * 0.7 + ph * 1.3)));
        [CATransaction commit];
        i++;
    }
    if (fabs(v - self.shown) < 0.002 && on == self.shownOn) return;
    self.shown = v; self.shownOn = on;
    BOOL light = p.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark;
    for (NSNumber *tag in @[@21, @22]) {
        UIView *g = [p viewWithTag:tag.intValue];
        UIView *lgv = nil; for (UIView *s in g.subviews) if (NGIsGlass(s)) lgv = s;
        if (on && NGClass()) {
            if (!lgv) { lgv = NGMake(g.bounds); if (lgv) { lgv.layer.zPosition = -100; [g insertSubview:lgv atIndex:0]; } }
            NGFit(lgv, g.bounds, g.layer.cornerRadius);
            NGStyle(lgv, v, light);
            g.backgroundColor = UIColor.clearColor; g.layer.borderWidth = 0;
        } else {
            [lgv removeFromSuperview];
            g.backgroundColor = light ? [UIColor colorWithWhite:1 alpha:0.6] : [UIColor colorWithWhite:0.12 alpha:0.85];
            g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        }
    }
    UILabel *note = (UILabel *)[p viewWithTag:23];
    note.hidden = NGClass() != nil;
}
@end

static const void *kNGPrev = &kNGPrev;
static void NGDemoLayout(UITableViewCell *self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void (*)(struct objc_super *, SEL))objc_msgSendSuper)(&sup, _cmd);
    self.textLabel.hidden = YES; self.detailTextLabel.hidden = YES; self.imageView.hidden = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone; self.backgroundColor = UIColor.clearColor;
    UIView *cv = self.contentView;
    CGFloat W = cv.bounds.size.width, H = cv.bounds.size.height;
    CGRect pf = CGRectMake(14, 8, W - 28, H - 16);
    UIView *panel = [cv viewWithTag:20];
    if (!panel) {
        panel = [[UIView alloc] initWithFrame:pf]; panel.tag = 20;
        panel.layer.cornerRadius = 24; panel.layer.cornerCurve = kCACornerCurveContinuous; panel.clipsToBounds = YES;
        CAGradientLayer *bg = [CAGradientLayer layer]; bg.name = @"bg";
        bg.colors = @[(id)[UIColor colorWithRed:0.06 green:0.08 blue:0.2 alpha:1].CGColor, (id)[UIColor colorWithRed:0.16 green:0.3 blue:0.7 alpha:1].CGColor];
        bg.startPoint = CGPointMake(0, 0); bg.endPoint = CGPointMake(1, 1);
        [panel.layer addSublayer:bg];
        NSArray *cols = @[[UIColor colorWithRed:1 green:0.36 blue:0.55 alpha:1], [UIColor colorWithRed:0.3 green:0.9 blue:0.78 alpha:1], [UIColor colorWithRed:1 green:0.78 blue:0.24 alpha:1]];
        for (int i = 0; i < 3; i++) {
            CALayer *b = [CALayer layer]; b.name = [NSString stringWithFormat:@"blob%d", i];
            b.bounds = CGRectMake(0, 0, 90 + i * 14, 90 + i * 14); b.cornerRadius = b.bounds.size.width / 2;
            b.backgroundColor = [cols[i] CGColor];
            [panel.layer addSublayer:b];
        }
        UILabel *txt = [UILabel new]; txt.tag = 24; txt.text = @"Glass over anything"; txt.textColor = UIColor.whiteColor;
        txt.font = [UIFont systemFontOfSize:22 weight:UIFontWeightHeavy]; [panel addSubview:txt];
        UIView *cap = [UIView new]; cap.tag = 21; cap.clipsToBounds = YES; cap.layer.cornerCurve = kCACornerCurveContinuous; [panel addSubview:cap];
        UILabel *ct = [UILabel new]; ct.tag = 25; ct.text = @"Search"; ct.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium]; [cap addSubview:ct];
        UIView *btn = [UIView new]; btn.tag = 22; btn.clipsToBounds = YES; [panel addSubview:btn];
        UIImageView *ic = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"square.and.pencil" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold]]];
        ic.tag = 26; ic.contentMode = UIViewContentModeCenter; [btn addSubview:ic];
        UILabel *note = [UILabel new]; note.tag = 23; note.numberOfLines = 0; note.textAlignment = NSTextAlignmentCenter;
        note.text = @"LiquidAss isn't installed, so the tweaks keep their own glass.";
        note.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]; note.textColor = [UIColor colorWithWhite:1 alpha:0.85]; [panel addSubview:note];
        [cv addSubview:panel];
        NGPreview *pv = [NGPreview new]; pv.panel = panel; pv.shown = -1;
        objc_setAssociatedObject(self, kNGPrev, pv, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    panel.frame = pf;
    CGFloat pw = pf.size.width, ph = pf.size.height;
    for (CALayer *l in panel.layer.sublayers) if ([l.name isEqualToString:@"bg"]) l.frame = panel.bounds;
    [panel viewWithTag:24].frame = CGRectMake(18, 16, pw - 36, 28);
    BOOL light = panel.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark;
    UIColor *ink = light ? UIColor.blackColor : UIColor.whiteColor;
    UIView *cap = [panel viewWithTag:21], *btn = [panel viewWithTag:22];
    CGFloat bh = 52;
    cap.frame = CGRectMake(14, ph - bh - 14, pw - 28 - bh - 12, bh); cap.layer.cornerRadius = bh / 2;
    UILabel *ct = (UILabel *)[cap viewWithTag:25]; ct.frame = CGRectMake(20, 0, cap.bounds.size.width - 40, bh); ct.textColor = [ink colorWithAlphaComponent:0.75];
    btn.frame = CGRectMake(pw - 14 - bh, ph - bh - 14, bh, bh); btn.layer.cornerRadius = bh / 2;
    UIImageView *ic = (UIImageView *)[btn viewWithTag:26]; ic.frame = btn.bounds; ic.tintColor = ink;
    [panel viewWithTag:23].frame = CGRectMake(18, 48, pw - 36, 34);
    NGPreview *pv = objc_getAssociatedObject(self, kNGPrev);
    pv.shown = -1;
    if (panel.window && !pv.link) {
        pv.link = [CADisplayLink displayLinkWithTarget:pv selector:@selector(tick)];
        [pv.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
}
static Class NGDemoClass(void) {
    Class sup = NSClassFromString(@"PSTableCell"); if (!sup) return nil;
    Class c = objc_getClass("NGDemoCell");
    if (!c) { c = objc_allocateClassPair(sup, "NGDemoCell", 0); class_addMethod(c, @selector(layoutSubviews), (IMP)NGDemoLayout, "v@:"); objc_registerClassPair(c); }
    return c;
}
static NSArray *(*origNGSpecs)(id, SEL);
static NSArray *NGSpecs(id self, SEL _cmd) {
    NSArray *a = origNGSpecs(self, _cmd);
    @try {
        for (id sp in a) {
            if (![sp respondsToSelector:@selector(identifier)] || ![[sp identifier] isEqualToString:@"NG_DEMO"]) continue;
            Class dc = NGDemoClass();
            if (dc && [sp propertyForKey:@"cellClass"] != dc) ((void (*)(id, SEL, id, id))objc_msgSend)(sp, @selector(setProperty:forKey:), dc, @"cellClass");
        }
    } @catch (__unused id e) {}
    return a;
}
static void StartDemo(void) {
    static BOOL done; if (done) return;
    Class PS = NSClassFromString(@"PSListController");
    if (!PS) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ StartDemo(); }); return; }
    done = YES;
    MSHookMessageEx(PS, @selector(specifiers), (IMP)NGSpecs, (IMP *)&origNGSpecs);
}

%ctor {
    StartNanoSettings();
    StartDemo();
}
