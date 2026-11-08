// LGCompat.h - get along with the Liquid (Gl)ass tweak ("LiquidAss" by dylv / WinsAviation).
//
// LiquidAss puts its own glass (LGButtonView, LGLiveBackdropView, ...) behind bar buttons in every app.
// Where one of our tweaks already draws its own glass button, the two stack up. With this, wherever
// we draw glass, LiquidAss's glass right underneath it is hidden (only there; the rest of LiquidAss
// keeps working). Nothing happens when LiquidAss isn't installed.
//
// Use: LGCompatRegister(view) for each view we draw glass for, and set gLGCompatOn from the prefs.
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
static void LGCompatPass(void) {
    if (!gLGCompatOn) {   // turned off: give LiquidAss its views back
        for (UIView *v in [gLGHidden allObjects]) LGSetHidden(v, NO);
        return;
    }
    for (UIView *g in [gLGOurs allObjects]) {
        if (!g.window || g.hidden || g.alpha < 0.05) continue;
        CGRect R = [g convertRect:g.bounds toView:nil];
        if (R.size.width < 8 || R.size.height < 8) continue;
        // look around our view: up to 4 levels up (a bar or its button stack), then down through that
        UIView *root = g;
        for (int i = 0; i < 4 && root.superview && root.superview != g.window; i++) root = root.superview;
        NSMutableArray *q = [NSMutableArray arrayWithObject:root];
        int n = 0;
        while (q.count && n++ < 500) {
            UIView *v = q.firstObject; [q removeObjectAtIndex:0];
            if (LGIsTheirs(v) && !LGHoldsContent(v)) {
                CGRect L = [v convertRect:v.bounds toView:nil];
                CGRect I = CGRectIntersection(L, R);
                CGFloat la = L.size.width * L.size.height, ia = CGRectIsNull(I) ? 0 : I.size.width * I.size.height;
                // theirs sits on ours: mostly inside it and not much bigger than it (a whole-bar backdrop is left alone)
                if (la > 0 && ia / la > 0.45 && la < R.size.width * R.size.height * 3.0) LGSetHidden(v, YES);
                continue;
            }
            [q addObjectsFromArray:v.subviews];
        }
    }
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
