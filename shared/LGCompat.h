// LGCompat.h - get along with the Liquid (Gl)ass tweak ("LiquidAss" by dylv / WinsAviation).
//
// LiquidAss puts its own glass (LGButtonView, LGLiveBackdropView, ...) behind bar buttons in every app.
// Where one of our tweaks already draws its own glass, the two stack up. With compatibility on (default),
// our glass steps aside wherever LiquidAss already draws, so LiquidAss's buttons show. With it off, ours
// shows and LiquidAss's glass under it is hidden. Nothing happens when LiquidAss isn't installed.
//
// Use: LGCompatRegister(glassView) for each glass view we draw (the glass itself, not the button), and set gLGCompatOn from the prefs.
#pragma once
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL gLGCompatOn = YES;
static NSHashTable *gLGOurs;      // our glass views (weak)
static NSHashTable *gLGHidden;    // LiquidAss views we hid (weak), so they come back if compat is turned off
static dispatch_source_t gLGTimer;   // a plain timer, so no class names clash between our tweaks

static BOOL LGPresent(void) {
    static int v = -1;
    if (v < 0) v = (NSClassFromString(@"LGButtonView") || NSClassFromString(@"LGLiveBackdropView")) ? 1 : 0;
    return v == 1;
}
static BOOL LGIsTheirs(UIView *v) {
    NSString *n = NSStringFromClass(v.class);
    return [n hasPrefix:@"LG"] && ([n hasSuffix:@"ButtonView"] || [n hasSuffix:@"BackdropView"] || [n hasSuffix:@"PhysicsView"] || [n hasSuffix:@"PillView"] || [n hasSuffix:@"BlurView"]);
}
// if their view wraps the button's icon or title, it isn't just glass: leave it and look inside it instead
static BOOL LGHoldsContent(UIView *v) {
    NSMutableArray *q = [v.subviews mutableCopy]; int n = 0;
    while (q.count && n++ < 80) {
        UIView *x = q.firstObject; [q removeObjectAtIndex:0];
        if (LGIsTheirs(x)) continue;
        if (([x isKindOfClass:[UILabel class]] && ((UILabel *)x).text.length) || ([x isKindOfClass:[UIImageView class]] && ((UIImageView *)x).image && x.bounds.size.width < 60)) return YES;
        [q addObjectsFromArray:x.subviews];
    }
    return NO;
}
static void LGSetHidden(UIView *v, BOOL hide) {
    if (hide) {
        if (!gLGHidden) gLGHidden = [NSHashTable weakObjectsHashTable];
        if (v.alpha != 0) v.alpha = 0;
        if (!v.hidden) v.hidden = YES;
        [gLGHidden addObject:v];
    } else if ([gLGHidden containsObject:v]) {
        v.hidden = NO; v.alpha = 1;
        [gLGHidden removeObject:v];
    }
}
// our own glass, hidden with an empty mask (our code keeps setting alpha/hidden, a mask it leaves alone)
static void LGOursHidden(UIView *g, BOOL hide) {
    BOOL masked = [g.layer.mask.name isEqualToString:@"lg.ours"];
    if (hide && !masked) { CALayer *m = [CALayer layer]; m.name = @"lg.ours"; g.layer.mask = m; }
    if (!hide && masked) g.layer.mask = nil;
}
// LiquidAss glass views sitting on our glass view g
static NSArray *LGTheirsOn(UIView *g) {
    NSMutableArray *out = [NSMutableArray array];
    CGRect R = [g convertRect:g.bounds toView:nil];
    if (R.size.width < 8 || R.size.height < 8) return out;
    // look around our view: up to 4 levels up (a bar or its button stack), then down through that
    UIView *root = g;
    for (int i = 0; i < 4 && root.superview && root.superview != g.window; i++) root = root.superview;
    NSMutableArray *q = [NSMutableArray arrayWithObject:root];
    int n = 0;
    while (q.count && n++ < 500) {
        UIView *v = q.firstObject; [q removeObjectAtIndex:0];
        if (v == g) continue;
        if (LGIsTheirs(v) && !LGHoldsContent(v)) {
            CGRect L = [v convertRect:v.bounds toView:nil];
            CGRect I = CGRectIntersection(L, R);
            CGFloat la = L.size.width * L.size.height, ia = CGRectIsNull(I) ? 0 : I.size.width * I.size.height;
            // theirs sits on ours: mostly inside it and not much bigger than it (a whole-bar backdrop is left alone)
            if (la > 0 && ia / la > 0.45 && la < R.size.width * R.size.height * 3.0) [out addObject:v];
            continue;
        }
        [q addObjectsFromArray:v.subviews];
    }
    return out;
}
// Compatibility on: LiquidAss's glass wins, ours steps aside where both would be.
// Compatibility off: ours wins, LiquidAss's glass under it is hidden.
static void LGCompatPass(void) {
    for (UIView *g in [gLGOurs allObjects]) {
        if (!g.window || g.hidden) { continue; }
        NSArray *theirs = LGTheirsOn(g);
        if (gLGCompatOn) {
            LGOursHidden(g, theirs.count > 0);

        } else {
            LGOursHidden(g, NO);
            for (UIView *v in theirs) LGSetHidden(v, YES);
        }
    }
    if (gLGCompatOn) for (UIView *v in [gLGHidden allObjects]) LGSetHidden(v, NO);   // give theirs back
}
static void LGCompatRegister(UIView *v) {
    if (!v || !LGPresent()) return;
    if (!gLGOurs) gLGOurs = [NSHashTable weakObjectsHashTable];
    [gLGOurs addObject:v];
    if (!gLGTimer) {
        gLGTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(gLGTimer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(0.35 * NSEC_PER_SEC), (uint64_t)(0.05 * NSEC_PER_SEC));
        dispatch_source_set_event_handler(gLGTimer, ^{ @try { LGCompatPass(); } @catch (__unused id e) {} });
        dispatch_resume(gLGTimer);
    }
}
