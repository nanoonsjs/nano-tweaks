// MusicPill 1.2.5 - made by nano
// 1.2.5: animated cover also matched by the playing song's title on the album
//         page; Lossless badge back to Music's own (no glass).
// 1.2.4: animated cover matched to its album by the header text Music draws
//         itself (no labels after a reboot meant no match).
// 1.2.3: animated cover: only the album's own header video is taken (a music
//         video tile elsewhere was picked before), remembered per album.
// 1.2.2: an album / artist share button no longer stays behind on Library.
// 1.2.1: player ••• / Lossless / album download found by symbol and text too
//        (VoiceOver labels are empty after a reboot, which broke them).
// 1.2.0: public release: package id com.nano.musicpill (replaces com.user.musicpill).
// 1.1.1: rootless and rootful packages kept apart (1.1.0 published the rootful one by mistake).
// 1.1.0: release build: arm64 + arm64e (every iPhone that runs iOS 16), rootless
//        and rootful packages, works on iOS 15.0 - 16.x.
// 1.0.48: the account picture was taken for an album's download button and
//         hidden for good; our own buttons are skipped and un-hidden now.
// 1.0.47: account picture drawn by its own image view (UIKit cleared the
//         button's image after other pages), kept in front, debug line.
// 1.0.46: account picture / Edit come back after returning from an album.
// 1.0.45: zoom page transition turned off (back to the normal slide).
// 1.0.44: iOS 26 zoom: tapping an album / playlist / song tile grows its page
//         out of the tile (back shrinks it into the tile) instead of iOS 16's
//         side slide; picture / Edit leave the bar the moment a page opens.
// 1.0.43: Library's Edit/Done text made clear at the source (no flash at all).
// 1.0.42: closing always lands at the bottom pill (a stale frame sent it up).
// 1.0.41: no frame of the player after swipe-down close, Music's Edit/Done is
//         hidden inside the bar's layout pass (no flash when tapping Edit).
// 1.0.40: closing the player animates into the bar when it's expanded too (it
//         vanished in one frame), a paused song after launch isn't "Not Playing".
// 1.0.39: Library glass Edit always shows (Music's Edit found by position, only
//         ours takes taps), nothing opens when tapping the bar with Not Playing.
// 1.0.38: queue History visible again (pills step aside while it's open),
//         Library glass Edit shows before editing too (Apple's untitled item).
// 1.0.37: queue pills stay when scrolling up into history (no flicker back to
//         Music's), star / ••• placed every frame and hidden until placed,
//         Library: Edit is a glass checklist circle left of the picture, both
//         pop away / jelly back on scroll.
// 1.0.36: queue pills placed right under the song row and the list slid just
//         enough below them, no glass ever on the player's •••.
// 1.0.35: queue pills sit under the song row again (list content inset instead
//         of moving the list), Lossless glass only while the badge shows.
// 1.0.34: player star closer to •••, ••• as big as the star, title/artist fade
//         out before the star, star follows ••• every frame (lyrics, queue).
// 1.0.33: full player: favorite star left of ••• (pops + sparks when on),
//         ••• without its circle, artist name in Music's pink, Lossless badge
//         on liquid glass.
// 1.0.32: motion cover runs while the player is open (it wasn't being checked
//         then), album matched by accessibility text / page title too.
// 1.0.31: player artwork found by any picture-holding square view; motion
//         status shown in the player's debug box.
// 1.0.30: motion cover looked for across the whole album page (+ debug of
//         any video layers seen).
// 1.0.29: no black box behind the album buttons on animated covers; animated
//         album cover plays on the full player's artwork (when that album's
//         page has shown it).
// 1.0.28: account picture smaller, liquid pop out / wobble back in.
// 1.0.27: artists without a photo: the page moves down so the centered name,
//         play and star sit below the top buttons instead of under them.
// 1.0.26: account picture back on Search (a wrong check hid it), and also on
//         Library, Radio and Browse.
// 1.0.25: switch back to its rounded look (no stretching; plain dark selected
//         pill, no gray rim), account picture hidden while searching.
// 1.0.24: selected Apple Music/Library pill fills its half (no gray rim),
//         account picture remembered for launch and hidden the moment the
//         Search page scrolls.
// 1.0.23: account picture fully visible and a fixed size, Apple Music/Library
//         switch has no outline and bounces when switched.
// 1.0.22: switch animation only while searching; it's now the bottom bar's real
//         liquid glass flowing into / out of the search field with the same
//         squeeze + wobble; collapsed tab icon at full size; the circle icons
//         fade at once when the bar expands.
// 1.0.21: Apple Music/Library switch has no fill behind it; hiding is a glass
//         drop that flows up into the search field (which gulps it), and
//         drops back out and spreads into the switch at the top.
// 1.0.20: Apple Music/Library switch narrow and centred, hides the moment the
//         list scrolls (squash + pulled up into the search bar, jelly back
//         at the top), account picture from a plain image bar button too.
// 1.0.19: artist fade covers the photo's last line again (8pt), search bar
//         styled on every tick (was square on first open), X centred and
//         smaller, Apple Music/Library a proper rounded glass switch that
//         fades away when the list scrolls and comes back at the very top.
// 1.0.18: artist fade ends at the header's real bottom (no black band when
//         scrolling), search field back to Apple's height as a glass capsule,
//         "Apple Music | Library" glass capsule switch, Cancel is a round glass
//         X, account picture looked up more ways.
// 1.0.17: artist header fade runs solid black past the photo (no light line),
//         softer status blur, Search page: capsule glass search field, title a
//         bit higher, account picture on the right, no "Browse Categories",
//         rounder category cards.
// 1.0.16: artist header lives in the page's header cell and is removed when the
//         page goes away (it stayed on Search after going back).
// 1.0.15: favorite state read right (star.circle.fill), Music's hidden play no
//         longer takes taps (it started radio), side name hidden by position.
// 1.0.14: our own back button (Music's icon vanished while scrolling), top
//         buttons a bit lower, permanent soft blur behind the status bar,
//         Music's side artist name hidden (attributed label).
// 1.0.13: artist header found again (1.0.12's check was too strict).
// 1.0.12: debug box moves with a two-finger drag; Music's own artist name hidden
//         wherever it is; only the header play button inside the page is taken
//         over (not the small one in the top bar, which made a 2nd copy); star
//         icon drawn above its disc.
// 1.0.11: artist look only on Music's artist header (never the player/lyrics);
//         artist name falls back to the page title when it isn't a label.
// 1.0.10: artist name = the big label level with the play button (not "Similar
//         Artists"), header hidden the moment its play button exists, star disc
//         fixed (was a big square), Music's own circles cut away on moved icons.
// 1.0.9: icons moved by their own transform (Music resets its buttons) so back
//        and share/••• line up, smaller share icon, lighter steady glass, no bar
//        background or small title on any page, artist page: name found across
//        the page, no "i" button, star uses Music's own favorite star.
// 1.0.8: top glass is a steady dark disc (no smear while scrolling), ••• icon
//        itself is moved so the capsule is even, list rows scrolling under the
//        top no longer get glass / hidden chevrons, artist detection widened.
// 1.0.7: share button works (it was outside its parent so taps never landed),
//        back circle and share/••• capsule placed like iOS 26, artist page in
//        the iOS 26 look (centered name, big white play, favorite star with a
//        burst, share/••• capsule, rounded latest-release card with a + circle).
// 1.0.6: no freeze when opening an artist / Show Complete Album (layout work is
//        queued, share button belongs to its own page), one glass on back, no
//        gray bar background on album pages, bigger •••, page tinted white.
// 1.0.5: Apple's album buttons are taken over inside Music's own layout pass
//        (never drawn), share taps no longer land on Music's download button,
//        plus (add to library) shows in the row with an "Added to Library"
//        toast and a smooth morph into the download arrow, iOS 26 sizes.
// 1.0.4: ••• glyph shows (Music's blur inside it is turned off, not masked),
//        share + ••• share one glass capsule, share builds the ••• menu and runs
//        its Share action, the row circle draws the download state itself
//        (arrow, live progress ring, checkmark), top download fully hidden,
//        P3 red detected.
// 1.0.3: album top bar: the glass sits behind the button (the ... icon shows),
//        Music's download button stays in the row circle through every state
//        (arrow, progress, checkmark), a share circle replaces it top right,
//        and red text is found and turned white on the album page itself.
// 1.0.2: album top buttons are found by their icons (they aren't always
//        controls), red text also caught in attributed text and buttons, and
//        a "float:" debug line shows what was found.
// 1.0.1: album page top buttons (Music's floating back / download / ... over
//        the artwork): back and ... in 44pt liquid glass circles with jelly,
//        the download button moves into the album row's right circle (live
//        progress), and Music's red artist name / "Show Complete Album" are white.
// 1.0.0: the Favorited / Unfavorited pop-up is the small iOS 26 one: a glass
//        capsule above the pill with a small star (filled) or crossed-out
//        star and the word, instead of Music's big square.
// 0.9.9: the top-row tile fix now runs on every view class of the menu (the
//        tiles aren't collection cells), bigger icons with the title centered
//        under them; the "Loved" / "Unloved" pop-up says "Favorited" /
//        "Unfavorited" with a star.
// 0.9.8: the menu's top-row tiles are laid out by us (icon centered on top,
//        title centered under it, sized to fit), and menu text uses the
//        iOS 26 look (17pt regular, tiles 15pt).
// 0.9.7: menus (the ... button) no longer count as "the player is open"
//        (no fake open animation / pill hiding), and song menus get the iOS 26
//        look: a top row of Download, Favorite and Share; Love is now Favorite
//        (star) and Unlove is Undo (crossed-out star).
// 0.9.6: slow scrolls collapse / expand like iOS 26: tiny per-frame movement
//        now counts, it triggers after ~40pt of travel in one direction, and
//        a change asked for during the anti-flicker pause is applied right
//        after it instead of being dropped.
// 0.9.5: 3-second hidden cooldown on opening the player (after it opens or
//        closes, the pill ignores taps), jelly on the two glass circles, and
//        the left circle takes you to the tab it shows (Library, Home...).
// 0.9.4: the pill and circles use the same glass as your tab bar (its own
//        blur effect is copied), and the search circle always does the same
//        thing: running animations are cleared first, it grows from a dot at
//        the bar's right end, and quick back-and-forth scrolls are ignored.
// 0.9.3: closing keeps the player's shape (scales down and folds into the
//        pill instead of squashing), Music's own swipe-down is switched off
//        everywhere on the player, and nothing else can close it mid-drag.
// 0.9.2: no flash of the full player when a swipe-down closes it (the player
//        is hidden before its size is reset, not after).
// 0.9.1: swipe-down to close follows your finger (the player slides, shrinks
//        and rounds its corners with the drag), then glides into the pill
//        from where you let go with your flick's speed, or springs back up.
// 0.9.0: our own closing animation: Apple's player-close transition is skipped
//        and the player shrinks straight into the glass pill.
// 0.8.9: undo 0.8.8's hiding of Music's bar container (Music reuses it for the
//        player transition: hiding it could hide the player and crash Music).
//        The pill-grow open animation stays; it only runs once per opening.
// 0.8.8: the player grows out of the pill (a copy of the pill swells to full
//        screen and fades as the player comes up), and Music's gray bar
//        container is hidden along with its bar.
// 0.8.7: the pill comes back as soon as the player starts closing (covers
//        Music's gray closing bar), and its blur glass is rebuilt every time
//        it reappears (iOS stops drawing a blur that was hidden mid-transition).
// 0.8.6: no old-bar flash when the player opens (Music's bar stays hidden,
//        our pill fades out as a snapshot), real blur glass matching the tab
//        bar again (blur views are never faded now), and the pill keeps the
//        last song instead of flashing "Not Playing".
// 0.8.5: tapping the pill opens the player: Music's own bar stays under our
//        pill (invisible via an empty mask, so it still gets touches) and our
//        pill only keeps its play / next buttons; when collapsed, Music's bar
//        moves under the small pill. Swipes reach Music's bar the same way.
// 0.8.4: iOS 26 scrolling title in the pill (pause, glide left with a copy
//        following, faded edges), tapping the pill opens the player again
//        (more ways to reach Music's own tap, result in debug).
// 0.8.3: our pill is used in both states (artwork, title + E, artist, play,
//        next), so the bar looks like iOS 26 expanded too; glass no longer
//        disappears (no fading of blur views); swipe left / right on the pill
//        skips in both states; on the Search tab the left circle shows the
//        last other tab (Library) and the search circle turns red.
// 0.8.2: no freeze: the collapsed pill reads song info from MediaRemote in the
//        background instead of asking Music's player on the main thread.
// 0.8.1: collapsed row redone: our own iOS 26 pill (artwork, full-size title
//        with the E badge, artist, play) instead of shrinking Music's bar,
//        circles sized / spaced like iOS 26, the search circle no longer
//        blows up, and a more liquid morph (stretch, overshoot, settle).
// 0.8.0: iOS 26 tab bar collapse. Scrolling down squeezes the tab bar into a
//        glass circle (current tab), Search splits off into its own circle,
//        and the pill drops into the row between them (skip button hides).
//        Scrolling back up / tapping the circle melts it all back out.
// 0.7.4: queue pills, new method. The queue list is slid down 54pt (transform)
//        and the pills fill the space at its top. Music's own scroll math is
//        untouched, so nothing can end up under the pills; the list's bottom
//        54pt is trimmed (mask + touch area) so it never covers the controls.
// 0.7.3: queue pills are trimmed at the list's top edge (slide under the song
//        info instead of over it), Music's auto-scroll is corrected so the
//        pills show when the queue opens, and Repeat One is read from Music's
//        own repeat button icon.
// 0.7.2: queue pills sit between the song info and "Continue Playing" (made
//        with the table's section-header top padding, so Music's own
//        scrolling can't push the song under them) and have a solid background.
// 0.7.1: iOS 26 queue: shuffle / repeat / autoplay as a pill row above
//        "Continue Playing" (54pt band made with the list's top inset), round
//        queue button (it's 28pt, too small for 0.7.0's check).
// 0.7.0: full player queue: "Playing Next" -> "Continue Playing", round queue
//        button, and a debug map of the player screen to build the iOS 26
//        shuffle/repeat/autoplay row next.
// 0.6.5: normal pill another 4% bigger (about 6% over Small); dragging the page
//        down (finger moving down) grows it 10% more, dragging up returns it
//        to normal. Reversed from 0.6.4, and no reset at the top.
// 0.6.3: no flash of the old Play/Shuffle when an album opens. They're hidden
//        the moment they appear and the new row is built right away, instead
//        of waiting for the next 1/4-second check.
// 0.6.2: the row's right circle shows Music's real download control live
//        (arrow, download progress, checkmark) via a portal view; back-button
//        glass sits behind the chevron, 34pt like iOS 26, off the screen edge.
// 0.6.1: no more flicker. Music's resets of the buttons we replace/clear are now
//        blocked when they happen (hooks) instead of corrected 4x a second, and
//        the top glass is attached to the buttons so it moves with them.
// 0.6.0: scrolling song title in the pill; iOS 26 style album/playlist buttons
//        (shuffle circle, white Play, download circle); glass top buttons.
// 0.5.3: shrink/round the bar's INNER content view instead of its container.
//        Music keeps resetting the container's transform after the full player
//        closes, so forcing it there made it flicker. Plus a back-off if
//        anything still fights over the size.
// 0.5.2: pill is always Small (size setting removed) and is forced back to Small
//        after the full player closes, even when Music leaves its own transform on it.
// 0.5.1: pill stays small after closing the full player; see-through background always on.
// 0.5.0: pill size setting (Normal / Compact / Small) and swipe left/right on
//        the pill for next/previous track.
// Apple Music only.
//  1. "Listen Now" tab -> "Home" with a house icon.
//  2. Now-playing bar -> rounded floating glass pill (iOS 26 style).
//     Only corner radius + transform on the bar; never its frame. All work runs
//     after the layout pass, so it can't loop.
//  3. Hides the shared gray blur behind the now-playing bar and tab bar
//     (PaletteContainerView's UIVisualEffectView) so the gap is see-through.
//  4. Debug overlay listing what it found near the tab bar.
//
// Settings: Music is sandboxed and can't read our prefs through cfprefsd, so
// the switches did nothing in 0.3.0. We now read the plist file directly
// (Dopamine keeps tweak prefs under /var/jb) and fall back to cfprefsd.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
static UIView *GlyphIn(UIView *v, int depth);

// UIKit's private live-mirror view: draws another view's current contents
// (including its animations) somewhere else.
@interface UIView (MPPortal)
- (instancetype)initWithSourceView:(UIView *)source;
@end

#define DOM CFSTR("com.user.musicpill")
#define DOM_NS @"com.user.musicpill"
#define NOTIFY CFSTR("com.user.musicpill/prefschanged")
#define DEBUG_TAG 0x4D504442
#define GLASS_TAG 0x4D50474C
#define MARQUEE_TAG 0x4D504D51
#define ROW_TAG 0x4D50524F
#define NAVGLASS_TAG 0x4D504E47
#define FLOATGLASS_TAG 0x4D50464C
#define SHARE_TAG 0x4D505348
#define PORTAL_TAG 0x4D50504F
#define PLAYERDEBUG_TAG 0x4D505044
#define QUEUEROW_TAG 0x4D505152
#define QUEUE_EXTRA 54.0
#define COLLAPSE_TAG 0x4D50434C

static BOOL gRename = YES, gRound = YES, gDebug = NO, gSwipe = YES;
static BOOL gCollapse = YES, gCollapsed = NO;
static NSString *gFloatDebug = @"-";
static NSString *gNowAlbum;   // album of the song playing (MediaRemote)
static NSString *gNowTitle;   // song playing (MediaRemote)
static const void *kKeepRed = &kKeepRed;   // labels we colour pink on purpose
static CFTimeInterval gPlayerCooldownUntil;   // no reopening the player before this
static NSString *gDismissDebug = @"-";
static void PlayerClosedOurWay(UIWindow *win, UIView *snap, CGRect from);
static void MaybeInstallDrag(UIViewController *vc);
static CGFloat gCloseVelocity;   // finger speed when a drag closes the player
static BOOL gDragging, gOurClose;
static void SetUnclipped(UIView *mini, UIView *root, BOOL on);
static __weak id gPillObj;
static NSString *gCollapseDebug = @"-";
static BOOL gMarquee = YES, gAlbum = YES, gNavGlass = YES, gQueueLook = YES;
static NSString *gAlbumDebug = @"-", *gNavDebug = @"-", *gMarqueeDebug = @"-";
// The see-through background is always on (no longer a setting).
static const BOOL gHideBG = YES;
// Fixed at Small (the size picked in Settings in 0.5.0). 0 Normal, 1 Compact, 2 Small.
static const int gSize = 2;
// Pill scale on top of Small: ~6% bigger normally (1.02 x 1.04), and 10% bigger
// than that while the page is dragged down.
static BOOL gExpanded = NO;
#define PILL_GROW_NORMAL (1.02 * 1.04)
#define PILL_GROW_SCROLL (1.02 * 1.04 * 1.10)
static NSString *gPrefsSource = @"defaults";
static __weak UITabBar *gLastTabBar;

static const void *kMini = &kMini;
static const void *kBusy = &kBusy;
static const void *kHome = &kHome;
static const void *kStyled = &kStyled;
static const void *kHiddenBG = &kHiddenBG;
static const void *kApplied = &kApplied;
static const void *kSwipeAdded = &kSwipeAdded;
static const void *kFight = &kFight;
static const void *kHidByUs = &kHidByUs;
static const void *kClearedBG = &kClearedBG;
static const void *kQueueTable = &kQueueTable;
static const void *kQueuePad = &kQueuePad; // original clipsToBounds of the queue list
static NSString *gQueueDebug = @"-";

#pragma mark - prefs

static NSDictionary *ReadPrefsFile(NSString **source) {
    NSString *name = [DOM_NS stringByAppendingString:@".plist"];
    NSArray *dirs = @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"];
    NSDictionary *best = nil; NSDate *bestDate = nil;
    for (NSString *dir in dirs) {
        NSString *p = [dir stringByAppendingString:name];
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:p];
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        NSDate *m = [[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil][NSFileModificationDate];
        if (!best || (m && bestDate && [m compare:bestDate] == NSOrderedDescending)) {
            best = d; bestDate = m;
            if (source) *source = p;
        }
    }
    return best;
}

static BOOL PrefBool(NSDictionary *file, NSString *key, BOOL def) {
    id v = file[key];
    if (!v) {
        CFPropertyListRef cf = CFPreferencesCopyAppValue((__bridge CFStringRef)key, DOM);
        if (cf) v = (__bridge_transfer id)cf;
    }
    return v ? [v boolValue] : def;
}

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOM);
    NSString *src = nil;
    NSDictionary *file = ReadPrefsFile(&src);
    gPrefsSource = src ?: @"cfprefs/defaults";
    gRename = PrefBool(file, @"rename", YES);
    gRound  = PrefBool(file, @"round", YES);
    gDebug  = PrefBool(file, @"debug", NO);
    gSwipe  = PrefBool(file, @"swipe", YES);
    gMarquee  = PrefBool(file, @"marquee", YES);
    gAlbum    = PrefBool(file, @"album", YES);
    gNavGlass = PrefBool(file, @"navglass", YES);
    gQueueLook = PrefBool(file, @"queuelook", YES);
    gCollapse = PrefBool(file, @"collapse", YES);
}

static void Update(UITabBar *tb);

// iOS 26 wording on the queue screen.
static NSString *MapQueueText(NSString *s) {
    if (!gQueueLook || ![s isKindOfClass:[NSString class]]) return s;
    if ([s isEqualToString:@"Playing Next"]) return @"Continue Playing";
    if ([s isEqualToString:@"Autoplaying similar music"]) return @"AutoPlaying similar music";
    if ([s isEqualToString:@"Loved"]) return @"Favorited";
    if ([s isEqualToString:@"Unloved"]) return @"Unfavorited";
    return s;
}

// Only Music's full player counts (menus and sheets are presented too).
static BOOL IsPlayerVC(UIViewController *p) {
    if (!p) return NO;
    NSString *n = NSStringFromClass([p class]);
    return [n containsString:@"Player"] || [n containsString:@"NowPlaying"];
}
static UIViewController *PresentedPlayer(UIViewController *root) {
    UIViewController *p = root.presentedViewController;
    return IsPlayerVC(p) ? p : nil;
}
static BOOL PlayerIsUp(UIWindow *w, UIView **playerView) {
    UIViewController *p = PresentedPlayer(w.rootViewController);
    if (!p || p.isBeingDismissed) return NO;
    if (playerView) *playerView = p.view;
    return YES;
}

// The queue button (bottom right of the full player) gets a filled background
// when selected; make that background a circle like iOS 26.
static void RoundIfQueueButton(UIView *v) {
    if (!gQueueLook) return;
    CGFloat w = v.bounds.size.width, h = v.bounds.size.height;
    if (w < 24 || w > 70 || fabs(w - h) > 6) return;
    UIWindow *win = v.window;
    UIView *player = nil;
    if (!win || !PlayerIsUp(win, &player) || ![v isDescendantOfView:player]) return;
    CGRect r = [v convertRect:v.bounds toView:win];
    CGFloat H = win.bounds.size.height;
    if (CGRectGetMinY(r) < H * 0.78 || CGRectGetMidX(r) < win.bounds.size.width * 0.6) return;
    // The queue button is a 28pt button whose selected image is a red rounded
    // square; clipping the button to a circle turns that into a red circle.
    BOOL imageButton = [v isKindOfClass:[UIButton class]] && w <= 40;
    BOOL filled = v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) >= 0.05;
    if (!imageButton && !filled) return;
    CGFloat radius = MIN(w, h) / 2;
    if (v.layer.cornerRadius != radius) { v.layer.cornerRadius = radius; v.layer.cornerCurve = kCACornerCurveContinuous; }
    if (imageButton && !v.clipsToBounds) v.clipsToBounds = YES;
}
static void AlbumControlLaidOut(UIControl *c);
static void PositionQueueRow(UIScrollView *table);

static void ReloadAndApply(void) {
    LoadPrefs();
    UITabBar *tb = gLastTabBar;
    if (tb) { @try { Update(tb); } @catch (__unused id e) {} }
}

static void PrefsChanged(CFNotificationCenterRef c, void *o, CFNotificationName n, const void *obj, CFDictionaryRef u) {
    // Settings may finish writing the file a moment after the notification.
    dispatch_async(dispatch_get_main_queue(), ^{ ReloadAndApply(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ReloadAndApply(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ ReloadAndApply(); });
}

#pragma mark - Listen Now -> Home

static BOOL IsListenNow(NSString *s) {
    return gRename && [s isKindOfClass:[NSString class]] && [s isEqualToString:@"Listen Now"];
}
static UIImage *House(void) { return [UIImage systemImageNamed:@"house.fill"]; }

static void MarkHome(UITabBarItem *it) {
    if (objc_getAssociatedObject(it, kHome)) return;
    objc_setAssociatedObject(it, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    it.image = House();
    it.selectedImage = House();
}

static void FixTabItems(UITabBar *tb) {
    if (!gRename) return;
    for (UITabBarItem *it in tb.items)
        if ([it.title isEqualToString:@"Home"] || [it.title isEqualToString:@"Listen Now"]) {
            if ([it.title isEqualToString:@"Listen Now"]) it.title = @"Home";
            MarkHome(it);
        }
}

%hook UITabBarItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSInteger)tag {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), tag);
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)sel {
    if (IsListenNow(title)) {
        id me = %orig(@"Home", House(), House());
        if (me) objc_setAssociatedObject(me, kHome, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return me;
    }
    return %orig;
}
- (void)setTitle:(NSString *)title {
    if (IsListenNow(title)) {
        %orig(@"Home");
        __weak UITabBarItem *weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{ if (weak) MarkHome(weak); });
        return;
    }
    %orig;
}
- (void)setImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
- (void)setSelectedImage:(UIImage *)image {
    %orig((gRename && objc_getAssociatedObject(self, kHome)) ? House() : image);
}
%end

// Library's Edit / Done text is invisible at the source (its colour), so no
// swap or animation can ever show it; our glass button stands in for it.
static void InvisibleBarItem(UIBarButtonItem *it) {
    if (!it || it.customView) return;
    NSDictionary *clear = @{NSForegroundColorAttributeName: UIColor.clearColor};
    UIControlState states[4] = { UIControlStateNormal, UIControlStateHighlighted, UIControlStateDisabled, UIControlStateSelected };
    for (int i = 0; i < 4; i++) [it setTitleTextAttributes:clear forState:states[i]];
    it.tintColor = UIColor.clearColor;
}
static void InvisibleLibraryEdit(UINavigationItem *ni) {
    if (![ni.title isEqualToString:@"Library"]) return;
    for (UIBarButtonItem *it in ni.rightBarButtonItems) InvisibleBarItem(it);
}
// ---- iOS 26 zoom: pages grow out of the tile you tapped, and shrink back ----
static __weak UIView *gTapCell;
static CFTimeInterval gTapTime;
static const void *kZoomCell = &kZoomCell, *kZoomRect = &kZoomRect;
static BOOL gZoomOn = NO;   // zoom turned off (user prefers the normal slide)
static UIView *CellUnder(UIView *v) {
    for (UIView *p = v; p; p = p.superview) {
        if ([p isKindOfClass:[UICollectionViewCell class]] || [p isKindOfClass:[UITableViewCell class]]) return p;
        if ([p isKindOfClass:[UIWindow class]]) break;
    }
    return nil;
}
static void HideTopExtras(UINavigationController *nav) {
    UINavigationBar *nb = nav.navigationBar;
    [nb viewWithTag:0x4D504156].hidden = YES;   // account picture
    [nb viewWithTag:0x4D504544].hidden = YES;   // Library edit
}
static UIView *ZoomBackdrop(UIView *page, UIView *in) {
    UIView *bd = [page snapshotViewAfterScreenUpdates:NO] ?: [UIView new];
    bd.frame = [page convertRect:page.bounds toView:in];
    bd.userInteractionEnabled = NO;
    UIView *dim = [[UIView alloc] initWithFrame:bd.bounds];
    dim.tag = 1; dim.backgroundColor = UIColor.blackColor; dim.alpha = 0;
    [bd addSubview:dim];
    return bd;
}
static void ZoomPush(UINavigationController *nav, UIViewController *vc, CGRect from) {
    UIWindow *w = nav.view.window;
    UIView *oldPage = nav.topViewController.view;
    UIView *bd = ZoomBackdrop(oldPage, w);
    [w addSubview:bd];
    UIView *newPage = vc.view;
    [nav.view layoutIfNeeded]; [newPage layoutIfNeeded];
    CGRect full = [newPage convertRect:newPage.bounds toView:w];
    if (CGRectIsEmpty(full)) full = w.bounds;
    UIView *snap = [newPage snapshotViewAfterScreenUpdates:YES];
    if (!snap) { [bd removeFromSuperview]; return; }
    UIView *wrap = [[UIView alloc] initWithFrame:from];
    wrap.clipsToBounds = YES; wrap.userInteractionEnabled = NO;
    wrap.layer.cornerRadius = 18; wrap.layer.cornerCurve = kCACornerCurveContinuous;
    wrap.backgroundColor = UIColor.blackColor;
    CGFloat s = from.size.width / full.size.width;
    snap.layer.anchorPoint = CGPointZero;
    snap.frame = CGRectMake(0, 0, full.size.width, full.size.height);
    snap.layer.position = CGPointZero;
    snap.transform = CGAffineTransformMakeScale(s, s);
    [wrap addSubview:snap];
    [w addSubview:wrap];
    newPage.alpha = 0;
    UIView *dim = [bd viewWithTag:1];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0.3 options:0 animations:^{
        wrap.frame = full;
        wrap.layer.cornerRadius = 0;
        snap.transform = CGAffineTransformIdentity;
        bd.transform = CGAffineTransformMakeScale(0.94, 0.94);
        dim.alpha = 0.55;
    } completion:^(BOOL d) {
        newPage.alpha = 1;
        [wrap removeFromSuperview];
        [bd removeFromSuperview];
    }];
}
static void ZoomPop(UINavigationController *nav, UIView *oldSnap, CGRect full, UIViewController *back, UIView *cell, CGRect stored) {
    UIWindow *w = nav.view.window;
    [nav.view layoutIfNeeded];
    CGRect to = (cell.window == w) ? [cell convertRect:cell.bounds toView:w] : stored;
    UIView *bd = ZoomBackdrop(back.view, w);
    bd.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [bd viewWithTag:1].alpha = 0.55;
    UIView *wrap = [[UIView alloc] initWithFrame:full];
    wrap.clipsToBounds = YES; wrap.userInteractionEnabled = NO;
    wrap.layer.cornerCurve = kCACornerCurveContinuous;
    wrap.backgroundColor = UIColor.blackColor;
    oldSnap.layer.anchorPoint = CGPointZero;
    oldSnap.frame = CGRectMake(0, 0, full.size.width, full.size.height);
    oldSnap.layer.position = CGPointZero;
    [wrap addSubview:oldSnap];
    [w addSubview:bd];
    [w addSubview:wrap];
    back.view.alpha = 0;
    CGFloat s = to.size.width / full.size.width;
    UIView *dim = [bd viewWithTag:1];
    [UIView animateWithDuration:0.46 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:0.3 options:0 animations:^{
        wrap.frame = to;
        wrap.layer.cornerRadius = 18;
        oldSnap.transform = CGAffineTransformMakeScale(s, s);
        bd.transform = CGAffineTransformIdentity;
        dim.alpha = 0;
    } completion:nil];
    [UIView animateWithDuration:0.16 delay:0.3 options:0 animations:^{ wrap.alpha = 0; } completion:^(BOOL d) {
        [wrap removeFromSuperview];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        back.view.alpha = 1;
        [bd removeFromSuperview];
    });
}

%hook UIWindow
- (void)sendEvent:(UIEvent *)e {
    if (e.type == UIEventTypeTouches) {
        UITouch *t0 = e.allTouches.anyObject;
        if (t0.phase == UITouchPhaseBegan) {
            UIView *c = CellUnder(t0.view);
            if (c && c.bounds.size.width < self.bounds.size.width * 0.98) { gTapCell = c; gTapTime = CACurrentMediaTime(); }
            else if (c) { gTapCell = c; gTapTime = CACurrentMediaTime(); }
            else gTapCell = nil;
        }
    }
    %orig;
}
%end

%hook UINavigationController
- (void)pushViewController:(UIViewController *)vc animated:(BOOL)animated {
    UIView *cell = gTapCell;
    BOOL zoom = gZoomOn && animated && self.view.window && cell.window == self.view.window && CACurrentMediaTime() - gTapTime < 1.2 &&
                self.presentedViewController == nil && self.topViewController && [cell isDescendantOfView:self.topViewController.view];
    HideTopExtras(self);
    if (!zoom) { %orig; return; }
    gTapCell = nil;
    CGRect from = [cell convertRect:cell.bounds toView:self.view.window];
    // The tile's artwork is where it grows from (rows: the whole row).
    objc_setAssociatedObject(vc, kZoomCell, cell, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(vc, kZoomRect, [NSValue valueWithCGRect:from], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIView *oldBackdropSrc = self.topViewController.view;
    (void)oldBackdropSrc;
    UIWindow *w = self.view.window;
    UIView *pre = ZoomBackdrop(self.topViewController.view, w);   // holds the screen while the push happens
    [w addSubview:pre];
    %orig(vc, NO);
    @try { ZoomPush(self, vc, from); } @catch (__unused id e) { vc.view.alpha = 1; }
    [pre removeFromSuperview];
}
- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *top = self.topViewController;
    NSValue *rv = objc_getAssociatedObject(top, kZoomRect);
    UIGestureRecognizerState gs = self.interactivePopGestureRecognizer.state;
    BOOL interactive = gs == UIGestureRecognizerStateBegan || gs == UIGestureRecognizerStateChanged;
    HideTopExtras(self);
    if (!gZoomOn || !animated || !rv || interactive || self.viewControllers.count < 2 || !self.view.window) return %orig;
    UIWindow *w = self.view.window;
    CGRect full = [top.view convertRect:top.view.bounds toView:w];
    UIView *snap = [top.view snapshotViewAfterScreenUpdates:NO];
    UIView *cell = objc_getAssociatedObject(top, kZoomCell);
    UIViewController *back = self.viewControllers[self.viewControllers.count - 2];
    if (!snap) return %orig;
    UIView *hold = [snap snapshotViewAfterScreenUpdates:NO] ?: [UIView new];
    hold.frame = full; hold.userInteractionEnabled = NO;
    [w addSubview:hold];
    UIViewController *r = %orig(NO);
    @try { ZoomPop(self, snap, full, back, cell, rv.CGRectValue); } @catch (__unused id e) { back.view.alpha = 1; }
    [hold removeFromSuperview];
    return r;
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
- (void)setRightBarButtonItems:(NSArray *)items animated:(BOOL)animated { %orig; @try { InvisibleLibraryEdit(self); } @catch (__unused id e) {} }
- (void)setRightBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated { %orig; @try { InvisibleLibraryEdit(self); } @catch (__unused id e) {} }
- (void)setRightBarButtonItems:(NSArray *)items { %orig; @try { InvisibleLibraryEdit(self); } @catch (__unused id e) {} }
- (void)setRightBarButtonItem:(UIBarButtonItem *)item { %orig; @try { InvisibleLibraryEdit(self); } @catch (__unused id e) {} }
%end


%hook UIViewController
- (void)setTitle:(NSString *)title { %orig(IsListenNow(title) ? @"Home" : title); }
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    @try { MaybeInstallDrag(self); } @catch (__unused id e) {}
}
// Closing the full player: skip Apple's transition and shrink it into our pill.
- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    UIViewController *presented = self.presentedViewController ?: self;
    UIWindow *win = presented.view.window;
    UIViewController *root = win.rootViewController;
    NSString *cn = NSStringFromClass([presented class]);
    BOOL player = animated && root && root.presentedViewController == presented && presented.presentedViewController == nil &&
                  ([cn containsString:@"Player"] || [cn containsString:@"NowPlaying"]);
    if (animated && root.presentedViewController == presented) gDismissDebug = cn;
    if (!player || !gCollapse || !gRound || !gLastTabBar || gLastTabBar.window != win) { %orig; return; }
    if (gDragging && !gOurClose) return;   // mid-drag: only our drag may close it
    gOurClose = NO;
    UIView *snap = [presented.view snapshotViewAfterScreenUpdates:NO];
    CGRect from = [presented.view convertRect:presented.view.bounds toView:win];
    // Hide it before undoing the drag's shrink, so it never flashes full size.
    UIView *pv = presented.view;
    pv.hidden = YES;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    pv.transform = CGAffineTransformIdentity;
    pv.layer.cornerRadius = 0;
    [CATransaction commit];
    pv.alpha = 0;
    %orig(NO, ^{
        // Unhidden only once it's gone (an async unhide showed it for a frame).
        pv.hidden = NO; pv.alpha = 1;
        if (completion) completion();
    });
    @try { PlayerClosedOurWay(win, snap, from); } @catch (__unused id e) {}
}
%end

#pragma mark - iOS 26 song menus

static NSString *MenuKind(UIMenuElement *e) {
    if (![e isKindOfClass:[UIAction class]]) return nil;
    NSString *t = e.title.lowercaseString;
    if ([t isEqualToString:@"love"] || [t isEqualToString:@"favorite"]) return @"love";
    if ([t isEqualToString:@"unlove"] || [t isEqualToString:@"undo"] || [t hasPrefix:@"remove from favorites"]) return @"unlove";
    if ([t isEqualToString:@"download"]) return @"download";
    if ([t hasPrefix:@"share song"] || [t hasPrefix:@"share album"] || [t hasPrefix:@"share playlist"] || [t isEqualToString:@"share"] || [t hasPrefix:@"share artist"]) return @"share";
    return nil;
}
static UIImage *MenuSym(NSString *n) { return [UIImage systemImageNamed:n withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]]; }

// Rename / re-icon the actions in place; collect the three top-row actions.
static void RestyleMenu(NSArray *children, NSMutableDictionary *found) {
    for (UIMenuElement *e in children) {
        if ([e isKindOfClass:[UIMenu class]]) { RestyleMenu(((UIMenu *)e).children, found); continue; }
        NSString *k = MenuKind(e);
        if (!k) continue;
        UIAction *a = (UIAction *)e;
        if ([k isEqualToString:@"love"]) { a.title = @"Favorite"; a.image = MenuSym(@"star"); found[@"fav"] = a; }
        else if ([k isEqualToString:@"unlove"]) { a.title = @"Undo"; a.image = MenuSym(@"star.slash"); a.attributes &= ~UIMenuElementAttributesDestructive; found[@"fav"] = a; }
        else if ([k isEqualToString:@"download"]) { a.image = MenuSym(@"arrow.down.circle.fill"); found[@"download"] = a; }
        else if ([k isEqualToString:@"share"]) { a.title = @"Share"; a.image = MenuSym(@"square.and.arrow.up.fill"); if (!found[@"share"]) found[@"share"] = a; }
    }
}
static NSArray *WithoutElements(NSArray *children, NSSet *drop) {
    NSMutableArray *out = [NSMutableArray array];
    for (__strong UIMenuElement *e in children) {
        if ([drop containsObject:e]) continue;
        if ([e isKindOfClass:[UIMenu class]]) {
            UIMenu *m = (UIMenu *)e;
            NSArray *kids = WithoutElements(m.children, drop);
            if (!kids.count) continue;
            if (kids.count != m.children.count) e = [m menuByReplacingChildren:kids];
        }
        [out addObject:e];
    }
    return out;
}
#define MP_ROW_ID @"com.user.musicpill.toprow"
static NSArray *IOS26MenuChildren(NSArray *children, UIMenuOptions options) {
    NSMutableDictionary *found = [NSMutableDictionary dictionary];
    RestyleMenu(children, found);
    if (options & UIMenuOptionsDisplayInline) return children;   // sections: only rename
    for (UIMenuElement *e in children) if ([e isKindOfClass:[UIMenu class]] && [((UIMenu *)e).identifier isEqualToString:MP_ROW_ID]) return children;
    NSMutableArray *row = [NSMutableArray array];
    for (NSString *k in @[@"download", @"fav", @"share"]) if (found[k]) [row addObject:found[k]];
    if (row.count < 2) return children;
    UIMenu *top = [UIMenu menuWithTitle:@"" image:nil identifier:MP_ROW_ID options:UIMenuOptionsDisplayInline children:row];
    if ([top respondsToSelector:@selector(setPreferredElementSize:)]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(top, @selector(setPreferredElementSize:), 1);   // medium: icon over title, side by side
        return [@[top] arrayByAddingObjectsFromArray:WithoutElements(children, [NSSet setWithArray:row])];
    }
    return children;
}

// Menu cells (UIKit's context menu list): fix the top-row tiles and fonts.
static void FixMenuCell(UIView *cell) {
    if (!gQueueLook) return;
    if (!cell.window) return;
    NSMutableArray *imgs = [NSMutableArray array], *labels = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray arrayWithArray:cell.subviews];
    while (stack.count) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.hidden) continue;
        if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image) [imgs addObject:v];
        else if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) [labels addObject:v];
        [stack addObjectsFromArray:v.subviews];
    }
    CGFloat winW = cell.window.bounds.size.width ?: UIScreen.mainScreen.bounds.size.width;
    BOOL tile = cell.bounds.size.width < winW * 0.36 && cell.bounds.size.width > 40 && cell.bounds.size.height < 110 && imgs.count == 1 && labels.count == 1;
    if (tile && imgs.count && labels.count) {
        UIImageView *iv = imgs.firstObject; UILabel *l = labels.firstObject;
        CGSize S = cell.bounds.size;
        UIFont *f = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
        if (![l.font isEqual:f]) l.font = f;
        l.textAlignment = NSTextAlignmentCenter;
        l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.75; l.numberOfLines = 1;
        CGFloat ih = 30, gap = 6, lh = ceil(f.lineHeight);
        CGFloat top = MAX(6, (S.height - ih - gap - lh) / 2);
        CGPoint ic = [iv.superview convertPoint:CGPointMake(S.width / 2, top + ih / 2) fromView:cell];
        iv.contentMode = UIViewContentModeCenter;
        iv.bounds = CGRectMake(0, 0, ih + 8, ih);
        iv.center = ic;
        CGRect lr = [l.superview convertRect:CGRectMake(4, top + ih + gap, S.width - 8, lh) fromView:cell];
        l.frame = lr;
        iv.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium];
        return;
    }
    if (![NSStringFromClass([cell class]) containsString:@"Cell"]) return;
    // Ordinary rows: iOS 26 font (regular 17).
    for (UILabel *l in labels) {
        if (l.font.pointSize >= 15 && l.font.pointSize <= 20) {
            UIFont *f = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
            if (![l.font isEqual:f]) l.font = f;
        }
    }
}

// The menu's views are private UIKit classes: hook layoutSubviews on every
// _UIContextMenu* view class so the tiles are fixed whatever they're called.
static NSMutableDictionary *gMenuLayoutIMPs;
static void MenuLayoutHook(UIView *self, SEL _cmd) {
    IMP orig = NULL;
    for (Class c = object_getClass(self); c && !orig; c = class_getSuperclass(c)) orig = [gMenuLayoutIMPs[NSStringFromClass(c)] pointerValue];
    if (orig) ((void (*)(id, SEL))orig)(self, _cmd);
    @try { FixMenuCell(self); } @catch (__unused id e) {}
}
static void HookMenuClasses(void) {
    gMenuLayoutIMPs = [NSMutableDictionary dictionary];
    unsigned int n = 0;
    Class *all = objc_copyClassList(&n);
    SEL sel = @selector(layoutSubviews);
    for (unsigned int i = 0; i < n; i++) {
        const char *name = class_getName(all[i]);
        if (strncmp(name, "_UIContextMenu", 14) != 0) continue;
        Class c = all[i];
        BOOL isView = NO;
        for (Class s = class_getSuperclass(c); s; s = class_getSuperclass(s)) if (s == [UIView class]) { isView = YES; break; }
        if (!isView) continue;
        // only classes that implement layoutSubviews themselves
        unsigned int mc = 0; Method *ms = class_copyMethodList(c, &mc); BOOL own = NO;
        for (unsigned int j = 0; j < mc; j++) if (method_getName(ms[j]) == sel) { own = YES; break; }
        free(ms);
        if (!own) continue;
        IMP old = NULL;
        MSHookMessageEx(c, sel, (IMP)MenuLayoutHook, &old);
        if (old) gMenuLayoutIMPs[@(name)] = [NSValue valueWithPointer:(const void *)old];
    }
    free(all);
}

%hook UIMenu
+ (UIMenu *)menuWithTitle:(NSString *)title image:(UIImage *)image identifier:(UIMenuIdentifier)identifier options:(UIMenuOptions)options children:(NSArray *)children {
    if (gQueueLook && ![identifier isEqualToString:MP_ROW_ID]) { @try { children = IOS26MenuChildren(children, options); } @catch (__unused id e) {} }
    return %orig(title, image, identifier, options, children);
}
- (UIMenu *)menuByReplacingChildren:(NSArray *)children {
    if (gQueueLook && ![self.identifier isEqualToString:MP_ROW_ID]) { @try { children = IOS26MenuChildren(children, self.options); } @catch (__unused id e) {} }
    return %orig(children);
}
%end

#pragma mark - geometry helpers

// Frame of v in root's coordinates, ignoring v's own transform.
static CGRect UntransformedRect(UIView *v, UIView *root) {
    if (!v.superview) return CGRectNull;
    CGPoint c = [v.superview convertPoint:v.center toView:root];
    CGSize s = v.bounds.size;
    return CGRectMake(c.x - s.width / 2, c.y - s.height / 2, s.width, s.height);
}

static BOOL BarSized(UIView *v, UIView *root) {
    if (v.hidden || v.alpha < 0.01 || v.tag == DEBUG_TAG || v.tag == GLASS_TAG) return NO;
    CGFloat h = v.bounds.size.height;
    return h >= 44 && h <= 100 && v.bounds.size.width >= root.bounds.size.width * 0.6;
}

static BOOL Geometry(UIView *v, UIView *root, CGRect tabRect, CGFloat minGap) {
    if (!BarSized(v, root)) return NO;
    CGRect r = UntransformedRect(v, root);
    if (CGRectIsNull(r)) return NO;
    CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
    return gap >= minGap && gap <= 40;
}

#pragma mark - find the now-playing bar

// iOS 16 Music: PaletteContainerView (h~172, the gray blur behind bar + tab bar)
//   -> UIVisualEffectView -> ... -> PaletteContainerView...ContainerView (h~68)  <- the bar
static UIView *FindByName(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]]) continue;
        NSString *n = NSStringFromClass([sub class]);
        BOOL nameHit = [n containsString:@"MiniPlayer"] ||
                       ([n containsString:@"PaletteContainerView"] && [n hasSuffix:@"ContainerView"] && ![n isEqualToString:@"PaletteContainerView"] && ![n hasSuffix:@"20PaletteContainerView"]);
        if (nameHit && Geometry(sub, root, tabRect, -20)) return sub;
        if (depth < 7) { UIView *f = FindByName(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

static UIView *FindByShape(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth) {
    for (UIView *sub in view.subviews) {
        if (sub == tb || [sub isKindOfClass:[UIScrollView class]] || [sub isKindOfClass:[UITabBar class]]) continue;
        if (Geometry(sub, root, tabRect, -12)) return sub; // outermost match
        if (depth < 5) { UIView *f = FindByShape(sub, root, tabRect, tb, depth + 1); if (f) return f; }
    }
    return nil;
}

// The big gray blur: a PaletteContainerView taller than the bar, and its effect views.
static UIView *FindPalette(UIView *view, int depth) {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:[UIScrollView class]]) continue;
        NSString *n = NSStringFromClass([sub class]);
        if ([n containsString:@"PaletteContainerView"] && sub.bounds.size.height > 100) return sub;
        if (depth < 4) { UIView *f = FindPalette(sub, depth + 1); if (f) return f; }
    }
    return nil;
}

#pragma mark - styling

// The bar container (PaletteContainerView...ContainerView) holds one full-size
// content view (the "UIView h=68" in the debug box). Music animates the
// container; it leaves the content view alone, so that's where we style.
static UIView *InnerContent(UIView *c) {
    for (UIView *s in c.subviews) {
        if (s.tag == GLASS_TAG || s.tag == DEBUG_TAG || s.hidden) continue;
        if (fabs(s.bounds.size.width - c.bounds.size.width) < 2 && fabs(s.bounds.size.height - c.bounds.size.height) < 2) return s;
    }
    return c;
}

static CGRect gCollapsedPill;

// The tab bar's own glass (from your tab bar tweak or iOS), so ours matches it.
static UIVisualEffect *TabGlassEffect(void) {
    static UIVisualEffect *cached;
    UITabBar *tb = gLastTabBar;
    if (tb) {
        NSMutableArray *stack = [NSMutableArray arrayWithObject:tb];
        UIVisualEffectView *best = nil; int guard = 0;
        while (stack.count && guard++ < 300) {
            UIView *v = stack.firstObject; [stack removeObjectAtIndex:0];
            if ([v isKindOfClass:[UIVisualEffectView class]] && ((UIVisualEffectView *)v).effect && !v.hidden && v.alpha > 0.01 &&
                v.bounds.size.width > tb.bounds.size.width * 0.5) { best = (UIVisualEffectView *)v; break; }
            [stack addObjectsFromArray:v.subviews];
        }
        if (best.effect) cached = best.effect;
    }
    return cached ?: [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
}   // where the pill sits when collapsed (root coords)
static CGAffineTransform PillTransform(UIView *m) {
    CGFloat W = m.bounds.size.width, H = m.bounds.size.height;
    // Collapsed: Music's (invisible) bar sits right under our small pill so taps reach it.
    if (gCollapsed && !CGRectIsEmpty(gCollapsedPill) && gLastTabBar && W > 0 && H > 0) {
        UIView *root = gLastTabBar.superview;
        CGRect u = UntransformedRect(m, root);
        CGFloat sx = gCollapsedPill.size.width / W, sy = gCollapsedPill.size.height / H;
        return CGAffineTransformScale(CGAffineTransformMakeTranslation(CGRectGetMidX(gCollapsedPill) - CGRectGetMidX(u), CGRectGetMidY(gCollapsedPill) - CGRectGetMidY(u)), sx, sy);
    }

    // Total horizontal inset for Normal / Compact / Small.
    CGFloat inset = gSize == 0 ? 24 : (gSize == 1 ? 56 : 96);
    CGFloat s = W > inset + 100 ? (W - inset) / W : 1;
    s = MIN(1.0, s * (gExpanded ? PILL_GROW_SCROLL : PILL_GROW_NORMAL));
    // Scaling shrinks around the center; shift down a bit so a smaller pill
    // keeps the same small gap above the tab bar instead of floating up.
    CGFloat ty = -6 + H * (1 - s) / 2;
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, ty), s, s);
}

// force: the bar is settled (no animation running, full player closed), so put
// our size back no matter what transform Music left on it. Closing the full
// player leaves Music's own (non-identity) transform behind, which is why
// 0.5.1 never shrank it again.
static void ApplyPillTransform(UIView *m, BOOL force) {
    CGAffineTransform t = PillTransform(m);
    NSValue *last = objc_getAssociatedObject(m, kApplied);
    // Back-off: if we've had to force it more than 4 times in 2 seconds,
    // something else is fighting us. Stop forcing for 5 seconds so it can't flicker.
    if (force) {
        CFTimeInterval now = CACurrentMediaTime();
        NSArray *f = objc_getAssociatedObject(m, kFight); // @[windowStart, count, backoffUntil]
        double start = f ? [f[0] doubleValue] : now, until = f ? [f[2] doubleValue] : 0;
        int count = f ? [f[1] intValue] : 0;
        if (now < until) force = NO;
        else if (!CGAffineTransformEqualToTransform(m.transform, t)) {
            if (now - start > 2.0) { start = now; count = 0; }
            count++;
            if (count > 4) { until = now + 5.0; count = 0; start = now; force = NO; }
        }
        objc_setAssociatedObject(m, kFight, @[@(start), @(count), @(until)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    BOOL ours = force || CGAffineTransformIsIdentity(m.transform) ||
                (last && CGAffineTransformEqualToTransform(m.transform, last.CGAffineTransformValue));
    if (ours && !CGAffineTransformEqualToTransform(m.transform, t)) {
        // Already styled once and now coming back from Music's reset: ease
        // back down instead of snapping.
        if (last && m.window) {
            [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{ m.transform = t; } completion:nil];
        } else {
            m.transform = t;
        }
    }
    if (ours) objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - swipe to skip

typedef Boolean (*MRSendCommandFn)(int command, CFDictionaryRef options);

static void SkipTrack(BOOL next) {
    static MRSendCommandFn send;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) send = (MRSendCommandFn)dlsym(h, "MRMediaRemoteSendCommand");
    });
    // MediaRemote commands: 4 = next track, 5 = previous track.
    if (send && send(next ? 4 : 5, NULL)) return;
    MPMusicPlayerController *p = [MPMusicPlayerController systemMusicPlayer];
    if (next) [p skipToNextItem]; else [p skipToPreviousItem];
}

@interface MPSwipeTarget : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end

@implementation MPSwipeTarget
+ (instancetype)shared { static MPSwipeTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPSwipeTarget new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g { return gSwipe && gRound; }
- (void)swiped:(UISwipeGestureRecognizer *)g {
    UIView *m = g.view;
    if (!m || !gSwipe) return;
    BOOL next = g.direction == UISwipeGestureRecognizerDirectionLeft;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SkipTrack(next);
    id pillObj = gPillObj;
    if (pillObj && [pillObj respondsToSelector:@selector(bumpDir:)]) [pillObj performSelector:@selector(bumpDir:) withObject:@(next ? -1 : 1)];
    // Little slide-and-bounce so the swipe feels like it did something.
    CGAffineTransform base = PillTransform(m);
    CGAffineTransform nudge = CGAffineTransformTranslate(base, next ? -26 : 26, 0);
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        m.transform = nudge;
    } completion:^(BOOL done) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ m.transform = base; }
                         completion:^(BOOL d) {
            objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:base], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }];
    }];
    objc_setAssociatedObject(m, kApplied, [NSValue valueWithCGAffineTransform:base], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

static void AddSwipes(UIView *m) {
    if (objc_getAssociatedObject(m, kSwipeAdded)) return;
    objc_setAssociatedObject(m, kSwipeAdded, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    for (NSNumber *dir in @[@(UISwipeGestureRecognizerDirectionLeft), @(UISwipeGestureRecognizerDirectionRight)]) {
        UISwipeGestureRecognizer *s = [[UISwipeGestureRecognizer alloc] initWithTarget:[MPSwipeTarget shared] action:@selector(swiped:)];
        s.direction = dir.unsignedIntegerValue;
        s.delegate = [MPSwipeTarget shared];
        s.cancelsTouchesInView = YES; // a swipe shouldn't also count as a tap that opens the player
        [m addGestureRecognizer:s];
    }
}

static void StylePill(UIView *m) {
    CGFloat r = m.bounds.size.height / 2;
    if (m.layer.cornerRadius != r) {
        m.layer.cornerRadius = r;
        m.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (!objc_getAssociatedObject(m, kStyled)) {
        objc_setAssociatedObject(m, kStyled, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        m.clipsToBounds = YES;
        m.layer.borderWidth = 0.75;
        m.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    }
    // Own glass background, so the pill still has one when the gray blur is hidden.
    UIView *glass = [m viewWithTag:GLASS_TAG];
    if (gHideBG && !glass) {
        UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        g.tag = GLASS_TAG;
        g.userInteractionEnabled = NO;
        g.frame = m.bounds;
        g.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [m insertSubview:g atIndex:0];
    } else if (!gHideBG && glass) {
        [glass removeFromSuperview];
    }
    ApplyPillTransform(m, NO);
    AddSwipes(m);
}

static void UnstylePill(UIView *m) {
    if (!m || !objc_getAssociatedObject(m, kStyled)) return;
    objc_setAssociatedObject(m, kStyled, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSValue *last = objc_getAssociatedObject(m, kApplied);
    if (last && CGAffineTransformEqualToTransform(m.transform, last.CGAffineTransformValue)) m.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(m, kApplied, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    m.layer.cornerRadius = 0;
    m.layer.borderWidth = 0;
    [[m viewWithTag:GLASS_TAG] removeFromSuperview];
}

// The bar's content lives INSIDE the effect view we hide, so hiding the effect
// view would hide the bar too. Instead, clear only the blur layers and keep the
// content view visible.
static void SetBackdropClear(UIView *palette, BOOL clear) {
    if (!palette) return;
    for (UIView *s in palette.subviews) {
        if (![s isKindOfClass:[UIVisualEffectView class]]) continue;
        UIVisualEffectView *ev = (UIVisualEffectView *)s;
        for (UIView *part in ev.subviews) {
            if (part == ev.contentView) continue;
            if (clear) {
                if (part.alpha != 0) { part.alpha = 0; objc_setAssociatedObject(part, kHiddenBG, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            } else if (objc_getAssociatedObject(part, kHiddenBG)) {
                part.alpha = 1;
                objc_setAssociatedObject(part, kHiddenBG, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}

#pragma mark - debug overlay

static void CollectCandidates(UIView *view, UIView *root, CGRect tabRect, UITabBar *tb, int depth, NSMutableArray *out) {
    for (UIView *sub in view.subviews) {
        if (out.count >= 10) return;
        if (sub == tb || sub.tag == DEBUG_TAG || sub.tag == GLASS_TAG || sub.tag == MARQUEE_TAG || [sub isKindOfClass:[UIScrollView class]]) continue;
        CGRect r = UntransformedRect(sub, root);
        if (!CGRectIsNull(r)) {
            CGFloat gap = CGRectGetMinY(tabRect) - CGRectGetMaxY(r);
            if (r.size.width >= root.bounds.size.width * 0.6 && r.size.height >= 30 && r.size.height <= 220 && gap > -160 && gap < 60) {
                NSString *name = NSStringFromClass([sub class]);
                if (name.length > 40) name = [@"…" stringByAppendingString:[name substringFromIndex:name.length - 39]];
                [out addObject:[NSString stringWithFormat:@"%@ h=%.0f gap=%.0f d=%d a=%.1f%@", name, r.size.height, gap, depth, sub.alpha, sub.hidden ? @" hidden" : @""]];
            }
        }
        if (depth < 6) CollectCandidates(sub, root, tabRect, tb, depth + 1, out);
    }
}

static CGFloat gDebugY = 110;
@interface MPDebugDrag : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation MPDebugDrag
+ (instancetype)shared { static MPDebugDrag *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPDebugDrag new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *l = [g.view viewWithTag:DEBUG_TAG];
    if (!l) return;
    static CGFloat startY;
    if (g.state == UIGestureRecognizerStateBegan) startY = gDebugY;
    CGFloat maxY = g.view.bounds.size.height - 60;
    gDebugY = MAX(0, MIN(maxY, startY + [g translationInView:g.view].y));
    CGRect f = l.frame; f.origin.y = gDebugY; l.frame = f;
}
@end
static void UpdateDebug(UITabBar *tb, UIView *root, CGRect tabRect, UIView *mini) {
    UIWindow *w = tb.window;
    if (!w) return;
    UILabel *l = (UILabel *)[w viewWithTag:DEBUG_TAG];
    if (!gDebug || PlayerIsUp(w, NULL)) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = DEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.85];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
        static const void *kDbgPan = &kDbgPan;
        if (!objc_getAssociatedObject(w, kDbgPan)) {
            // Two fingers anywhere move the box up / down; one finger still uses the app.
            UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:[MPDebugDrag shared] action:@selector(pan:)];
            p.minimumNumberOfTouches = 2; p.maximumNumberOfTouches = 2;
            p.cancelsTouchesInView = NO; p.delaysTouchesBegan = NO; p.delaysTouchesEnded = NO;
            p.delegate = [MPDebugDrag shared];
            [w addGestureRecognizer:p];
            objc_setAssociatedObject(w, kDbgPan, p, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    NSMutableArray *c = [NSMutableArray array];
    CollectCandidates(root, root, tabRect, tb, 0, c);
    NSString *found = @"none";
    if (mini) {
        NSString *n = NSStringFromClass([mini class]);
        if (n.length > 40) n = [@"…" stringByAppendingString:[n substringFromIndex:n.length - 39]];
        found = [NSString stringWithFormat:@"%@ h=%.0f", n, mini.bounds.size.height];
    }
    NSString *text = [NSString stringWithFormat:@" MusicPill 1.2.5 debug\n prefs: %@\n rename=%d round=%d size=%d swipe=%d\n tab y=%.0f h=%.0f\n PICKED: %@\n title: %@\n album: %@\n nav: %@\n float: %@\n collapse: %@\n %@",
                      gPrefsSource, gRename, gRound, gSize, gSwipe,
                      CGRectGetMinY(tabRect), tabRect.size.height, found, gMarqueeDebug, gAlbumDebug, gNavDebug, gFloatDebug, gCollapseDebug,
                      [c componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 24;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(12, gDebugY, width, s.height + 8);
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

#pragma mark - driver

static void SetCollapsed(BOOL collapse, BOOL animated);
static void Update(UITabBar *tb) {
    FixTabItems(tb);
    // Full player open: bars back to normal so Music's own animation looks right.
    if (gCollapsed) {
        UIViewController *rv = tb.window.rootViewController;
        if (PresentedPlayer(rv)) SetCollapsed(NO, NO);
        else { UIView *m = objc_getAssociatedObject(tb, kMini); if (m.alpha > 0.01) m.alpha = 0; }
    }
    UIView *root = tb.superview;
    if (!root || !tb.window) return;
    CGRect tabRect = UntransformedRect(tb, root);

    UIView *palette = FindPalette(root, 0);
    SetBackdropClear(palette, gRound && gHideBG);

    UIView *mini = objc_getAssociatedObject(tb, kMini);
    if (gRound) {
        // Stick with the bar we already picked while it's on screen and bar-sized.
        // Re-picking is what caused two nested pills in 0.3.0.
        BOOL keep = mini && mini.window && [mini isDescendantOfView:root] && BarSized(mini, root);
        if (!keep) {
            UIView *byName = FindByName(root, root, tabRect, tb, 0);
            UIView *found = byName ? InnerContent(byName) : FindByShape(root, root, tabRect, tb, 0);
            if (found != mini) UnstylePill(mini);
            mini = found;
            objc_setAssociatedObject(tb, kMini, mini, OBJC_ASSOCIATION_ASSIGN);
        }
        if (mini) StylePill(mini);
    } else if (mini) {
        UnstylePill(mini);
    }
    UpdateDebug(tb, root, tabRect, gRound ? mini : nil);
}

#pragma mark - iOS 26 collapse

@interface MPCollapse : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
- (void)tapTab;
- (void)tapSearch;
- (void)jelly:(UILongPressGestureRecognizer *)g;
@end


static UIView *TabButtonRow(UITabBar *tb, CGFloat *rowY, UIView *root) {
    UIView *first = nil;
    for (UIView *s in tb.subviews) if ([NSStringFromClass([s class]) containsString:@"TabBarButton"] && !s.hidden) { first = s; break; }
    if (first) *rowY = CGRectGetMidY([first.superview convertRect:first.frame toView:root]);
    else *rowY = CGRectGetMinY(UntransformedRect(tb, root)) + 28;
    return first;
}

static __weak UITabBarItem *gLastOtherTab;
static BOOL IsSearchItem(UITabBar *tb, UITabBarItem *it) {
    if (!it) return NO;
    if ([it.title.lowercaseString containsString:@"search"]) return YES;
    return it == tb.items.lastObject && tb.items.count >= 4;
}
static UIImage *SelectedTabImage(UITabBar *tb) {
    UITabBarItem *it = tb.selectedItem;
    if (IsSearchItem(tb, it)) it = gLastOtherTab ?: tb.items[MAX(0, (NSInteger)tb.items.count - 2)];
    else if (it) gLastOtherTab = it;
    UIImage *img = it.selectedImage ?: it.image;
    if (!img) return nil;
    // Tab bar images are drawn small; in the circle they get the search icon's size.
    if (img.isSymbolImage) {
        img = [img imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightSemibold]];
    } else if (img.size.height > 0 && img.size.height < 27) {
        CGFloat s = 27 / img.size.height;
        CGSize ns = CGSizeMake(round(img.size.width * s), 27);
        UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:ns];
        UIImage *src = [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        img = [r imageWithActions:^(UIGraphicsImageRendererContext *c) { [src drawInRect:CGRectMake(0, 0, ns.width, ns.height)]; }];
    }
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static UIView *GlassCircle(NSString *ident, UIView *host) {
    for (UIView *v in host.subviews) if ([v.accessibilityIdentifier isEqualToString:ident]) return v;
    UIView *c = [UIView new];
    c.accessibilityIdentifier = ident;
    c.clipsToBounds = NO;
    UIView *g = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
    g.tag = 1; g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    [c addSubview:g];
    UIImageView *iv = [UIImageView new];
    iv.tag = 2; iv.contentMode = UIViewContentModeCenter; iv.userInteractionEnabled = NO;
    [c addSubview:iv];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[MPCollapse shared]
                                                                          action:[ident isEqualToString:@"tab"] ? @selector(tapTab) : @selector(tapSearch)];
    [c addGestureRecognizer:tap];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[MPCollapse shared] action:@selector(jelly:)];
    lp.minimumPressDuration = 0;
    lp.cancelsTouchesInView = NO;
    lp.delegate = (id<UIGestureRecognizerDelegate>)[MPCollapse shared];
    [c addGestureRecognizer:lp];
    [host addSubview:c];
    return c;
}
static void RebuildCircleGlass(UIView *c) {
    UIView *old = [c viewWithTag:1];
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
    g.tag = 1; g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    g.frame = old ? old.frame : c.bounds; g.layer.cornerRadius = old.layer.cornerRadius;
    [c insertSubview:g atIndex:0];
    [old removeFromSuperview];
}
static void LayoutCircle(UIView *c, CGRect f) {
    c.bounds = CGRectMake(0, 0, f.size.width, f.size.height);
    c.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
    UIView *g = [c viewWithTag:1];
    g.frame = c.bounds;
    g.layer.cornerRadius = MIN(f.size.width, f.size.height) / 2;
    [c viewWithTag:2].frame = c.bounds;
}

@interface MPPassHost : UIView @end
@implementation MPPassHost
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { UIView *h = [super hitTest:p withEvent:e]; return h == self ? nil : h; }
@end

static UIView *CollapseHost(UITabBar *tb) {
    UIView *root = tb.superview;
    UIView *h = [root viewWithTag:COLLAPSE_TAG];
    if (h.superview != root) {
        h = [MPPassHost new];
        h.tag = COLLAPSE_TAG;
        [root addSubview:h];
    }
    [root bringSubviewToFront:h];
    h.frame = root.bounds;
    return h;
}



static void SetCollapsedFwd(BOOL c);
// ---- our compact iOS 26 pill (shown only while collapsed) ----
typedef Boolean (*MRSendFn)(int command, CFDictionaryRef options);
static void SendMR(int cmd) {
    static MRSendFn send; static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) send = (MRSendFn)dlsym(h, "MRMediaRemoteSendCommand");
    });
    if (send) send(cmd, NULL);
}

// Stand-in for a gesture recognizer so Music's tap handler sees "ended".
@interface MPGRProxy : NSProxy
@property (nonatomic, strong) UIGestureRecognizer *gr;
@end
@implementation MPGRProxy
- (UIGestureRecognizerState)state { return UIGestureRecognizerStateEnded; }
- (BOOL)isKindOfClass:(Class)c { return [_gr isKindOfClass:c]; }
- (BOOL)respondsToSelector:(SEL)s { return [_gr respondsToSelector:s]; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)s { return [_gr methodSignatureForSelector:s]; }
- (void)forwardInvocation:(NSInvocation *)i { [i invokeWithTarget:_gr]; }
@end

static NSString *gOpenDebug = @"-";
// Open the full player the way a tap on Music's bar does.
static BOOL OpenPlayer(UIView *mini) {
    for (UIView *v = mini; v; v = v.superview) {
        for (UIGestureRecognizer *g in v.gestureRecognizers) {
            if (![g isKindOfClass:[UITapGestureRecognizer class]] || !g.enabled) continue;
            NSArray *targets = nil;
            @try { targets = [g valueForKey:@"_targets"]; } @catch (__unused id e) {}
            for (id tg in targets) {
                id target = nil; SEL action = NULL;
                @try { target = [tg valueForKey:@"_target"]; } @catch (__unused id e) {}
                Ivar iv = class_getInstanceVariable([tg class], "_action");
                if (iv) action = *(SEL *)((uint8_t *)(__bridge void *)tg + ivar_getOffset(iv));
                if (!target || !action || ![target respondsToSelector:action]) continue;
                NSString *tc = NSStringFromClass([target class]);
                if ([tc isEqualToString:@"MPMiniPill"] || [tc isEqualToString:@"MPCollapse"] || [tc isEqualToString:@"MPSwipeTarget"]) continue;
                MPGRProxy *p = [MPGRProxy alloc]; p.gr = g;
                ((void (*)(id, SEL, id))objc_msgSend)(target, action, p);
                gOpenDebug = [NSString stringWithFormat:@"tap -[%@ %@]", tc, NSStringFromSelector(action)];
                return YES;
            }
        }
        if ([NSStringFromClass([v class]) isEqualToString:@"PaletteContainerView"] || [NSStringFromClass([v class]) hasSuffix:@".PaletteContainerView"]) break;
    }
    // A control covering the bar (Music may use a button).
    NSMutableArray *stack = [NSMutableArray arrayWithObject:mini ?: [UIView new]];
    for (UIView *v = mini.superview; v && stack.count < 4; v = v.superview) [stack addObject:v];
    for (UIView *top in [stack copy]) {
        if ([top isKindOfClass:[UIControl class]] && top.bounds.size.width > mini.bounds.size.width * 0.6) {
            [(UIControl *)top sendActionsForControlEvents:UIControlEventTouchUpInside];
            gOpenDebug = [NSString stringWithFormat:@"control %@", NSStringFromClass([top class])];
            return YES;
        }
    }
    // Accessibility: the bar's own "activate".
    for (UIView *v = mini; v; v = v.superview) {
        if (v.isAccessibilityElement && [v accessibilityActivate]) { gOpenDebug = [NSString stringWithFormat:@"a11y %@", NSStringFromClass([v class])]; return YES; }
        if ([NSStringFromClass([v class]) hasSuffix:@"PaletteContainerView"]) break;
    }
    gOpenDebug = @"nothing found to open the player";
    return NO;
}

static NSString *MusicBarTitle(UIView *mini);
@interface MPMiniPill : UIView
@property (nonatomic, strong) UIView *glass;
@property (nonatomic, strong) UIImageView *art, *badge;
@property (nonatomic, strong) UILabel *title, *artist, *title2;
@property (nonatomic, strong) UIView *titleBox, *titleStrip;
@property (nonatomic, strong) CAGradientLayer *fade;
@property (nonatomic, copy) NSString *scrollKey;
@property (nonatomic, strong) UIButton *play, *next;
@property (nonatomic) BOOL compact;
- (void)refresh;
@end
@implementation MPMiniPill
- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    _glass = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
    _glass.userInteractionEnabled = NO; _glass.clipsToBounds = YES;
    _glass.layer.cornerCurve = kCACornerCurveContinuous;
    _glass.layer.borderWidth = 0.75; _glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    [self addSubview:_glass];
    _art = [UIImageView new]; _art.contentMode = UIViewContentModeScaleAspectFill; _art.clipsToBounds = YES;
    _art.layer.cornerRadius = 8; _art.layer.cornerCurve = kCACornerCurveContinuous;
    _art.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [self addSubview:_art];
    // Title lives in a clipped box with faded edges so it can scroll.
    _titleBox = [UIView new]; _titleBox.clipsToBounds = YES; _titleBox.userInteractionEnabled = NO;
    [self addSubview:_titleBox];
    _titleStrip = [UIView new]; [_titleBox addSubview:_titleStrip];
    _title = [UILabel new]; _title.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; _title.textColor = UIColor.whiteColor;
    [_titleStrip addSubview:_title];
    _title2 = [UILabel new]; _title2.font = _title.font; _title2.textColor = _title.textColor; _title2.hidden = YES;
    [_titleStrip addSubview:_title2];
    _fade = [CAGradientLayer layer];
    _fade.startPoint = CGPointMake(0, 0.5); _fade.endPoint = CGPointMake(1, 0.5);
    _artist = [UILabel new]; _artist.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular]; _artist.textColor = [UIColor colorWithWhite:1 alpha:0.62];
    [self addSubview:_artist];
    _badge = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"e.square.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium]]];
    _badge.tintColor = [UIColor colorWithWhite:1 alpha:0.62]; _badge.contentMode = UIViewContentModeCenter;
    [self addSubview:_badge];
    _play = [UIButton buttonWithType:UIButtonTypeSystem];
    _play.tintColor = UIColor.whiteColor;
    [_play addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_play];
    _next = [UIButton buttonWithType:UIButtonTypeSystem];
    _next.tintColor = UIColor.whiteColor;
    [_next setImage:[UIImage systemImageNamed:@"forward.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    [_next addTarget:self action:@selector(skipNext) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_next];
    return self;
}
// Only our buttons take touches; taps and swipes anywhere else fall through to
// Music's own (invisible) bar underneath, which opens the player / skips.
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    for (UIButton *b in @[_play, _next]) {
        if (b.hidden || b.alpha < 0.05) continue;
        if (CGRectContainsPoint(CGRectInset(b.frame, -4, -6), p)) return b;
    }
    return nil;
}
- (void)bumpDir:(NSNumber *)d { [self bump:d.doubleValue]; }
- (void)rebuildGlass {
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
    g.userInteractionEnabled = NO; g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    g.frame = self.bounds; g.layer.cornerRadius = self.bounds.size.height / 2;
    [self insertSubview:g aboveSubview:_glass];
    [_glass removeFromSuperview];
    _glass = g;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize S = self.bounds.size;
    _glass.frame = self.bounds; _glass.layer.cornerRadius = S.height / 2;
    CGFloat a = S.height - 14;
    _art.frame = CGRectMake(8, 7, a, a);
    CGFloat pw = 44, btns = _compact ? pw : pw * 2;
    CGFloat x = 8 + a + 11, maxW = S.width - x - btns - 8;
    CGFloat bw = _badge.hidden ? 0 : 18;
    CGFloat full = ceil([_title sizeThatFits:CGSizeMake(2000, 30)].width);
    CGFloat boxW = MIN(full, maxW - bw);
    BOOL scrolls = full > maxW - bw + 0.5;
    _titleBox.frame = CGRectMake(x, S.height / 2 - 21, boxW, 22);
    _title.frame = CGRectMake(0, 0, full, 22);
    CGFloat gap = 34;
    _title2.text = _title.text; _title2.hidden = !scrolls;
    _title2.frame = CGRectMake(full + gap, 0, full, 22);
    _titleStrip.frame = CGRectMake(0, 0, full * 2 + gap, 22);
    _badge.frame = CGRectMake(x + boxW + 3, S.height / 2 - 20, 15, 19);
    // Faded edges only while it scrolls.
    if (scrolls) {
        _fade.frame = _titleBox.bounds;
        CGFloat e = MIN(0.12, 14 / MAX(boxW, 1));
        _fade.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
        _fade.locations = @[@0, @(e), @(1 - e), @1];
        _titleBox.layer.mask = _fade;
    } else _titleBox.layer.mask = nil;
    NSString *key = [NSString stringWithFormat:@"%@|%.0f|%d", _title.text, boxW, scrolls];
    if (![key isEqualToString:_scrollKey]) {
        _scrollKey = key;
        [_titleStrip.layer removeAnimationForKey:@"marquee"];
        if (scrolls) {
            // iOS 26: rest, then glide left until the copy takes its place; repeat.
            CGFloat dist = full + gap, speed = 32, pause = 2.0;
            CFTimeInterval move = dist / speed, total = move + pause;
            CAKeyframeAnimation *m = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
            m.values = @[@0, @0, @(-dist)];
            m.keyTimes = @[@0, @(pause / total), @1];
            m.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            m.duration = total; m.repeatCount = HUGE_VALF;
            [_titleStrip.layer addAnimation:m forKey:@"marquee"];
        }
    }
    _artist.frame = CGRectMake(x, S.height / 2 + 1, maxW, 18);
    _next.frame = CGRectMake(S.width - pw - 8, (S.height - pw) / 2, pw, pw);
    _play.frame = CGRectMake(S.width - btns - 8, (S.height - pw) / 2, pw, pw);
    _next.alpha = _compact ? 0 : 1;
}
- (void)refresh {
    // Ask MediaRemote (async, off the main thread); never Music's own player.
    typedef void (*InfoFn)(dispatch_queue_t, void (^)(CFDictionaryRef));
    typedef void (*PlayingFn)(dispatch_queue_t, void (^)(Boolean));
    static InfoFn info; static PlayingFn playing; static dispatch_once_t once;
    dispatch_once(&once, ^{
        void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        if (h) { info = (InfoFn)dlsym(h, "MRMediaRemoteGetNowPlayingInfo"); playing = (PlayingFn)dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"); }
    });
    __weak MPMiniPill *weak = self;
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    if (info) info(q, ^(CFDictionaryRef d) {
        NSDictionary *dict = (__bridge NSDictionary *)d;
        NSString *title = dict[@"kMRMediaRemoteNowPlayingInfoTitle"], *artist = dict[@"kMRMediaRemoteNowPlayingInfoArtist"];
        NSString *albumName = dict[@"kMRMediaRemoteNowPlayingInfoAlbum"];
        if ([albumName isKindOfClass:[NSString class]]) dispatch_async(dispatch_get_main_queue(), ^{ gNowAlbum = albumName; });
        if ([title isKindOfClass:[NSString class]]) dispatch_async(dispatch_get_main_queue(), ^{ gNowTitle = title; });
        BOOL explicitTrack = [dict[@"kMRMediaRemoteNowPlayingInfoIsExplicitTrack"] boolValue];
        NSData *art = dict[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
        static NSData *lastArt; static UIImage *lastImg;
        UIImage *img = nil;
        if ([art isKindOfClass:[NSData class]]) {
            if ([art isEqualToData:lastArt]) img = lastImg;
            else { img = [UIImage imageWithData:art]; lastArt = art; lastImg = img; }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            MPMiniPill *me = weak; if (!me) return;
            BOOL have = [title isKindOfClass:[NSString class]] && [title length];
            if (!have && me.title.text.length && ![me.title.text isEqualToString:@"Not Playing"]) return;   // keep the last song
            if (!have) {
                UIView *m = gLastTabBar ? objc_getAssociatedObject(gLastTabBar, kMini) : nil;
                NSString *mt = m ? MusicBarTitle(m) : nil;
                if (mt.length && ![mt isEqualToString:@"Not Playing"]) { if (![me.title.text isEqualToString:mt]) me.title.text = mt; [me setNeedsLayout]; return; }
            }
            NSString *t2 = have ? title : @"Not Playing";
            NSString *a2 = [artist isKindOfClass:[NSString class]] ? artist : @"";
            if (![me.title.text isEqualToString:t2]) me.title.text = t2;
            if (![me.artist.text isEqualToString:a2]) me.artist.text = a2;
            me.badge.hidden = !explicitTrack;
            if (img && me.art.image != img) me.art.image = img;
            else if (!img && !have) me.art.image = nil;
            [me setNeedsLayout];
        });
    });
    if (playing) playing(q, ^(Boolean p) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MPMiniPill *me = weak; if (!me) return;
            NSString *sym = p ? @"pause.fill" : @"play.fill";
            if (![me.play.accessibilityValue isEqualToString:sym]) {
                me.play.accessibilityValue = sym;
                [me.play setImage:[UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
            }
        });
    });
}
- (void)skipNext { SkipTrack(YES); [self bump:-1]; }
- (void)swiped:(UISwipeGestureRecognizer *)g {
    if (!gSwipe) return;
    BOOL next = g.direction == UISwipeGestureRecognizerDirectionLeft;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SkipTrack(next);
    [self bump:next ? -1 : 1];
}
// Slide-and-bounce so a skip feels like it did something, then pick up the new song.
- (void)bump:(CGFloat)dir {
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    k.values = @[@0, @(22 * dir), @(-6 * dir), @0]; k.keyTimes = @[@0, @0.25, @0.65, @1]; k.duration = 0.45;
    k.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.layer addAnimation:k forKey:@"bump"];
    for (NSNumber *d in @[@0.2, @0.6, @1.2]) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self refresh]; });
}
- (void)togglePlay {
    SendMR(2);
    UIImageView *iv = _play.imageView;
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@1, @0.6, @1.12, @1]; k.keyTimes = @[@0, @0.3, @0.7, @1]; k.duration = 0.35;
    [iv.layer addAnimation:k forKey:@"p"];
    for (NSNumber *d in @[@0.15, @0.5]) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self refresh]; });
}
- (void)open {
    UITabBar *tb = gLastTabBar;
    {
        UIView *m = tb ? objc_getAssociatedObject(tb, kMini) : nil;
        NSString *mt = m ? MusicBarTitle(m) : nil;
        if ([self.title.text isEqualToString:@"Not Playing"] && (!mt.length || [mt isEqualToString:@"Not Playing"])) { [self bump:0]; return; }
    }
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (!OpenPlayer(mini)) SetCollapsedFwd(NO);
}
@end

static const CGFloat kCD = 52;     // circle / pill height, like iOS 26
static const CGFloat kSide = 30;   // circles' distance from the screen edges
static const CGFloat kGap = 14;    // gap between circle and pill

static void SetCollapsed(BOOL collapse, BOOL animated) {
    UITabBar *tb = gLastTabBar;
    UIView *root = tb.superview;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (collapse == gCollapsed) return;
    static CFTimeInterval lastToggle;
    static BOOL pending; static BOOL pendingWant;
    CFTimeInterval since = CACurrentMediaTime() - lastToggle;
    if (animated && since < 0.45) {
        // Too soon after the last change: apply it once the pause is over.
        pendingWant = collapse;
        if (!pending) {
            pending = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((0.47 - since) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                pending = NO;
                SetCollapsed(pendingWant, YES);
            });
        }
        return;
    }
    lastToggle = CACurrentMediaTime();
    if (collapse && (!gCollapse || !gRound || !tb.window || tb.hidden || !mini.window || !objc_getAssociatedObject(mini, kStyled))) return;
    UIView *host = CollapseHost(tb);
    UIView *tab = GlassCircle(@"tab", host), *search = GlassCircle(@"search", host);
    MPMiniPill *pill = nil;
    for (UIView *v in host.subviews) if ([v isKindOfClass:[MPMiniPill class]]) pill = (MPMiniPill *)v;
    if (!pill) { pill = [MPMiniPill new]; pill.hidden = YES; [host addSubview:pill]; }
    CGFloat W = root.bounds.size.width, rowY = 0;
    TabButtonRow(tb, &rowY, root);
    CGRect tr = UntransformedRect(tb, root);
    CGRect wide = CGRectMake(CGRectGetMinX(tr) + 14, rowY - 29, tr.size.width - 28, 58);   // the tab bar's pill
    CGRect left = CGRectMake(kSide, rowY - kCD / 2, kCD, kCD), right = CGRectMake(W - kSide - kCD, rowY - kCD / 2, kCD, kCD);
    CGRect rightStart = CGRectMake(CGRectGetMaxX(wide) - kCD - 6, rowY - kCD / 2, kCD, kCD);
    gCollapsedPill = CGRectMake(CGRectGetMaxX(left) + kGap, rowY - kCD / 2, CGRectGetMinX(right) - kGap - CGRectGetMaxX(left) - kGap, kCD);
    CGRect miniRect = [mini convertRect:mini.bounds toView:host];   // where Music's bar is drawn now
    UIImageView *ti = (UIImageView *)[tab viewWithTag:2], *si = (UIImageView *)[search viewWithTag:2];
    ti.image = SelectedTabImage(tb); ti.tintColor = tb.tintColor ?: UIColor.systemPinkColor;
    si.image = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold]];
    BOOL onSearch = IsSearchItem(tb, tb.selectedItem);
    si.tintColor = onSearch ? (tb.tintColor ?: UIColor.systemPinkColor) : UIColor.whiteColor;
    if (onSearch) ti.tintColor = UIColor.whiteColor;
    gCollapsed = collapse;
    UIViewAnimationOptions o = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    // Liquid squish: stretch along the motion, then settle with a little wobble.
    void (^wobble)(UIView *, CGFloat, CGFloat, CGFloat) = ^(UIView *v, CGFloat sx, CGFloat sy, CFTimeInterval delay) {
        CAKeyframeAnimation *kx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
        kx.values = @[@1, @(sx), @(1 + (1 - sx) * 0.6), @(1 - (1 - sx) * 0.2), @1];
        CAKeyframeAnimation *ky = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
        ky.values = @[@1, @(sy), @(1 + (1 - sy) * 0.6), @(1 - (1 - sy) * 0.2), @1];
        for (CAKeyframeAnimation *k in @[kx, ky]) {
            k.keyTimes = @[@0, @0.28, @0.55, @0.8, @1]; k.duration = 0.62;
            k.beginTime = CACurrentMediaTime() + delay;
            k.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            k.additive = NO;
        }
        [v.layer addAnimation:kx forKey:@"wx"]; [v.layer addAnimation:ky forKey:@"wy"];
    };

    if (collapse) {
        RebuildCircleGlass(tab); RebuildCircleGlass(search);
        tab.hidden = search.hidden = pill.hidden = NO;
        pill.alpha = 1; si.alpha = 1;
        for (UIView *v in @[tab, search, ti, si]) [v.layer removeAllAnimations];
        tab.transform = search.transform = CGAffineTransformIdentity;
        LayoutCircle(tab, wide); tab.alpha = 1;
        LayoutCircle(search, rightStart); search.alpha = 1;
        search.transform = CGAffineTransformMakeScale(0.25, 0.25);
        ti.alpha = 1; ti.transform = CGAffineTransformMakeScale(0.4, 0.4);
        [pill refresh];
        if (pill.hidden || CGRectIsEmpty(pill.frame)) { pill.frame = miniRect; [pill layoutIfNeeded]; }
        // 1. The bar's glass takes over from Music's tab bar, and Music's mini bar hands over to our pill.
        [UIView animateWithDuration:0.12 delay:0 options:o animations:^{ tb.alpha = 0; } completion:nil];
        SetUnclipped(mini, root, YES);
        CGAffineTransform under = PillTransform(mini);
        objc_setAssociatedObject(mini, kApplied, [NSValue valueWithCGAffineTransform:under], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        mini.transform = under;
        // 2. The bar squeezes into the left circle (overshoots a touch, settles).
        [UIView animateWithDuration:0.62 delay:0 usingSpringWithDamping:0.68 initialSpringVelocity:0.6 options:o animations:^{
            LayoutCircle(tab, left);
        } completion:nil];
        wobble(tab, 0.9, 1.12, 0.08);
        [UIView animateWithDuration:0.5 delay:0.12 usingSpringWithDamping:0.6 initialSpringVelocity:0.6 options:o animations:^{ ti.transform = CGAffineTransformIdentity; } completion:nil];
        // 3. Search buds off the right end and rolls into its own circle.
        [UIView animateWithDuration:0.6 delay:0.02 usingSpringWithDamping:0.66 initialSpringVelocity:0.5 options:o animations:^{
            LayoutCircle(search, right);
            search.transform = CGAffineTransformIdentity;
        } completion:nil];
        // 4. The pill drops into the row and narrows.
        [UIView animateWithDuration:0.64 delay:0.02 usingSpringWithDamping:0.72 initialSpringVelocity:0.4 options:o animations:^{
            pill.compact = YES;
            pill.frame = gCollapsedPill; [pill layoutIfNeeded];
        } completion:nil];
        wobble(pill, 1.05, 0.9, 0.06);

    } else {
        CGRect miniHome = miniRect;
        [UIView animateWithDuration:0.16 delay:0.18 options:o animations:^{ tb.alpha = 1; } completion:nil];
        [ti.layer removeAllAnimations]; [si.layer removeAllAnimations];
        [UIView animateWithDuration:0.08 delay:0 options:o animations:^{ ti.alpha = 0; si.alpha = 0; } completion:nil];
        for (UIView *v in @[tab, search]) [v.layer removeAllAnimations];
        [UIView animateWithDuration:0.56 delay:0 usingSpringWithDamping:0.74 initialSpringVelocity:0.4 options:o animations:^{
            LayoutCircle(tab, wide);
        } completion:nil];
        wobble(tab, 1.06, 0.9, 0.0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.36 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (!gCollapsed) tab.hidden = YES; });
        [UIView animateWithDuration:0.32 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:0.2 options:o animations:^{
            LayoutCircle(search, rightStart);
            search.transform = CGAffineTransformMakeScale(0.25, 0.25);
        } completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.34 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!gCollapsed) { search.hidden = YES; search.transform = CGAffineTransformIdentity; }
        });
        // Our pill rises back up to Music's bar and hands over.
        CGAffineTransform home = PillTransform(mini);
        objc_setAssociatedObject(mini, kApplied, [NSValue valueWithCGAffineTransform:home], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        mini.transform = home;
        SetUnclipped(mini, root, NO);
        miniHome = [mini convertRect:mini.bounds toView:host];
        [UIView animateWithDuration:0.56 delay:0 usingSpringWithDamping:0.76 initialSpringVelocity:0.3 options:o animations:^{
            pill.compact = NO;
            pill.frame = miniHome; [pill layoutIfNeeded];
        } completion:nil];
    }
    gCollapseDebug = [NSString stringWithFormat:@"%@ row=%.0f closed=%@", collapse ? @"collapsed" : @"expanded", rowY, gDismissDebug];
}
static void SetCollapsedFwd(BOOL c) { SetCollapsed(c, YES); }

static const void *kMiniMask = &kMiniMask;
static void HideMini(UIView *m, BOOL hide);
static void HideOne(UIView *m, BOOL hide);
static void HideMini(UIView *m, BOOL hide) {
    if (!m) return;
    HideOne(m, hide);
}
static void HideOne(UIView *m, BOOL hide) {
    if (hide && !objc_getAssociatedObject(m, kMiniMask)) {
        m.layer.mask = [CALayer layer];   // draws nothing, still gets touches
        objc_setAssociatedObject(m, kMiniMask, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (!hide && objc_getAssociatedObject(m, kMiniMask)) {
        m.layer.mask = nil;
        objc_setAssociatedObject(m, kMiniMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
static NSHashTable *gUnclipped;
static __weak UIView *gUnderMini;   // Music's bar while it's moved under the collapsed pill
static void SetUnclipped(UIView *mini, UIView *root, BOOL on) {
    if (!gUnclipped) gUnclipped = [NSHashTable weakObjectsHashTable];
    if (on) {
        for (UIView *p = mini.superview; p && p != root; p = p.superview) if (p.clipsToBounds) { p.clipsToBounds = NO; [gUnclipped addObject:p]; }
        gUnderMini = mini;
    } else {
        for (UIView *p in [gUnclipped allObjects]) p.clipsToBounds = YES;
        [gUnclipped removeAllObjects];
        gUnderMini = nil;
    }
}

// Our pill stands in for Music's bar in both states. Expanded, it sits exactly
// where Music's (hidden) bar is; while the full player is up, Music's bar is back.
static __weak UIView *gHiddenMini;
static CFTimeInterval gFastRefreshUntil;
static void SyncPill(void) {
    UITabBar *tb = gLastTabBar;
    UIView *root = tb.superview;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (!root || !tb.window) return;
    UIView *host = [root viewWithTag:COLLAPSE_TAG];
    MPMiniPill *pill = nil;
    for (UIView *v in host.subviews) if ([v isKindOfClass:[MPMiniPill class]]) pill = (MPMiniPill *)v;
    UIViewController *rv = tb.window.rootViewController;
    BOOL playerUp = PresentedPlayer(rv) != nil && !PresentedPlayer(rv).isBeingDismissed;
    BOOL on = gCollapse && gRound && mini.window && objc_getAssociatedObject(mini, kStyled) && !playerUp && !mini.hidden;
    if (!on && playerUp && pill && !pill.hidden && gCollapse && gRound) {
        // Full player opening: Music's bar stays hidden (no old-bar flash);
        // our pill fades away as a snapshot (fading the blur itself breaks it).
        if (gCollapsed) SetCollapsed(NO, NO);
        // The player grows out of the pill: a copy of the pill swells up to
        // full screen and melts away while the player comes up.
        UIWindow *win = tb.window;
        UIView *snap = pill.window ? [pill snapshotViewAfterScreenUpdates:NO] : nil;
        if (snap && win) {
            CGRect from = [pill convertRect:pill.bounds toView:win];
            UIView *wrap = [[UIView alloc] initWithFrame:from];
            wrap.userInteractionEnabled = NO;
            wrap.clipsToBounds = YES;
            wrap.layer.cornerRadius = from.size.height / 2;
            wrap.layer.cornerCurve = kCACornerCurveContinuous;
            snap.frame = wrap.bounds;
            snap.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [wrap addSubview:snap];
            UIView *tint = [[UIView alloc] initWithFrame:wrap.bounds];
            tint.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
            tint.alpha = 0;
            tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [wrap addSubview:tint];
            [win addSubview:wrap];
            CGRect to = CGRectInset(win.bounds, 0, 0);
            to.origin.y += 44; to.size.height -= 44;
            [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0.3 options:0 animations:^{
                wrap.frame = to;
                wrap.layer.cornerRadius = 38;
                tint.alpha = 1;
            } completion:nil];
            [UIView animateWithDuration:0.18 delay:0.22 options:0 animations:^{ wrap.alpha = 0; } completion:^(BOOL d) { [wrap removeFromSuperview]; }];
        }
        pill.hidden = YES;
        return;
    }
    if (!on && playerUp) { pill.hidden = YES; return; }
    if (!on) {
        if (gCollapsed && playerUp) SetCollapsed(NO, NO);
        pill.hidden = YES;
        UIView *hm = gHiddenMini; gHiddenMini = nil;
        HideMini(hm, NO);
        if (hm && hm.alpha < 0.01) hm.alpha = 1;
        return;
    }
    if (!host) host = CollapseHost(tb);
    if (!pill) {
        pill = [MPMiniPill new];
        [host addSubview:pill];
        [pill refresh];
    }
    if (pill.hidden) {
        pill.hidden = NO; pill.alpha = 1;
        [pill performSelector:@selector(rebuildGlass)];
        [pill refresh]; gFastRefreshUntil = CACurrentMediaTime() + 3;
    }
    gHiddenMini = mini;
    gPillObj = pill;
    if (mini.alpha < 0.01) mini.alpha = 1;
    // Hidden cooldown: for 3 seconds after the player opens or closes, the pill ignores taps.
    BOOL cool = CACurrentMediaTime() < gPlayerCooldownUntil;
    if (mini.userInteractionEnabled == cool) mini.userInteractionEnabled = !cool;
    HideMini(mini, YES);
    if (!gCollapsed && !pill.layer.animationKeys.count) {
        CGRect r = [mini convertRect:mini.bounds toView:host];
        if (!CGRectEqualToRect(pill.frame, r)) { pill.compact = NO; pill.frame = r; [pill setNeedsLayout]; }
    }
    static CFTimeInterval lastRefresh;
    CGFloat every = CACurrentMediaTime() < gFastRefreshUntil ? 0.3 : 1.0;
    if (CACurrentMediaTime() - lastRefresh > every) { lastRefresh = CACurrentMediaTime(); [pill refresh]; }
}

// The player (as a snapshot) shrinks straight into the pill.
static void PlayerClosedOurWay(UIWindow *win, UIView *snap, CGRect from) {
    gPlayerCooldownUntil = CACurrentMediaTime() + 3;
    SyncPill();   // the pill is back right away underneath
    UITabBar *tb = gLastTabBar;
    UIView *host = [tb.superview viewWithTag:COLLAPSE_TAG];
    MPMiniPill *pill = nil;
    for (UIView *v in host.subviews) if ([v isKindOfClass:[MPMiniPill class]]) pill = (MPMiniPill *)v;
    if (!snap) return;
    // Where it lands: our pill, else Music's bar, else just above the tab bar.
    // Only a spot in the bottom part of the screen counts (stale frames sent it up).
    CGFloat WH = win.bounds.size.height, WW = win.bounds.size.width;
    BOOL (^ok)(CGRect) = ^BOOL(CGRect r) { return r.size.height > 20 && r.size.width > 100 && CGRectGetMidY(r) > WH * 0.6 && CGRectGetMidY(r) < WH; };
    UIView *target = nil;
    CGRect to = CGRectZero;
    UIView *mini = objc_getAssociatedObject(tb, kMini);
    if (pill && !pill.hidden && pill.alpha > 0.05 && pill.window && ok([pill convertRect:pill.bounds toView:win])) { target = pill; to = [pill convertRect:pill.bounds toView:win]; }
    else if (mini.window && ok([mini convertRect:mini.bounds toView:win])) { target = mini; to = [mini convertRect:mini.bounds toView:win]; }
    else {
        CGRect tr = tb.window ? [tb convertRect:tb.bounds toView:win] : CGRectMake(0, WH - 100, WW, 100);
        to = CGRectMake(16, CGRectGetMinY(tr) - 64, WW - 32, 56);
    }
    // The player keeps its shape: it scales down to the pill's width and folds
    // its height into the pill while gliding there.
    UIView *wrap = [[UIView alloc] initWithFrame:from];
    wrap.userInteractionEnabled = NO;
    wrap.clipsToBounds = YES;
    wrap.layer.cornerRadius = 40;
    wrap.layer.cornerCurve = kCACornerCurveContinuous;
    wrap.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
    snap.frame = wrap.bounds;
    snap.autoresizingMask = UIViewAutoresizingNone;
    [wrap addSubview:snap];
    [win addSubview:wrap];
    CGFloat s = to.size.width / MAX(1, from.size.width);
    CGFloat hInner = to.size.height / MAX(0.01, s);
    CGFloat dist = MAX(1, CGRectGetMidY(to) - CGRectGetMidY(from));
    CGFloat v0 = MAX(0, MIN(4, gCloseVelocity / dist));
    gCloseVelocity = 0;
    [UIView animateWithDuration:0.48 delay:0 usingSpringWithDamping:0.88 initialSpringVelocity:v0 options:0 animations:^{
        wrap.bounds = CGRectMake(0, 0, from.size.width, hInner);
        wrap.center = CGPointMake(CGRectGetMidX(to), CGRectGetMidY(to));
        wrap.transform = CGAffineTransformMakeScale(s, s);
        wrap.layer.cornerRadius = hInner / 2;
    } completion:nil];
    [UIView animateWithDuration:0.2 delay:0.1 options:0 animations:^{ snap.alpha = 0; } completion:nil];
    [UIView animateWithDuration:0.14 delay:0.34 options:0 animations:^{ wrap.alpha = 0; } completion:^(BOOL d) { [wrap removeFromSuperview]; }];
    // The pill gives a little liquid bounce as the player lands in it.
    CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    k.values = @[@0.92, @0.92, @1.05, @0.98, @1]; k.keyTimes = @[@0, @0.4, @0.65, @0.85, @1]; k.duration = 0.75;
    if (target) [target.layer addAnimation:k forKey:@"land"];
}

#pragma mark - drag to close

@interface MPPlayerDrag : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
static const void *kDragAdded = &kDragAdded;
static UIScrollView *ScrollUnder(UIView *v) {
    for (UIView *p = v; p; p = p.superview) if ([p isKindOfClass:[UIScrollView class]] && ![p isKindOfClass:[UITextView class]]) return (UIScrollView *)p;
    return nil;
}
@implementation MPPlayerDrag
+ (instancetype)shared { static MPPlayerDrag *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPPlayerDrag new]; }); return t; }
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)g {
    CGPoint v = [g velocityInView:g.view];
    if (v.y <= 0 || fabs(v.x) > v.y) return NO;          // downward drags only
    UIView *hit = [g.view hitTest:[g locationInView:g.view] withEvent:nil];
    if ([hit isKindOfClass:[UISlider class]] || [NSStringFromClass([hit class]) containsString:@"Slider"]) return NO;
    UIScrollView *s = ScrollUnder(hit);
    if (s && s != (id)g.view && s.contentSize.height > s.bounds.size.height + 1 &&
        s.contentOffset.y > -s.adjustedContentInset.top + 1) return NO;   // a list that's scrolled: let it scroll
    return YES;
}
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    UIViewController *vc = (UIViewController *)objc_getAssociatedObject(v, kDragAdded);
    CGFloat ty = MAX(0, [g translationInView:v.superview].y);
    CGFloat H = MAX(1, v.bounds.size.height);
    CGFloat p = MIN(1, ty / H);
    if (g.state == UIGestureRecognizerStateBegan) {
        gDragging = YES;
        v.layer.cornerCurve = kCACornerCurveContinuous;
        v.layer.masksToBounds = YES;
    }
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        // Follows the finger 1:1, shrinking and rounding as it goes.
        CGFloat s = 1 - 0.12 * p;
        v.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, ty), s, s);
        v.layer.cornerRadius = 12 + 40 * MIN(1, p * 3);
        return;
    }
    gDragging = NO;
    CGFloat vy = [g velocityInView:v.superview].y;
    BOOL close = g.state == UIGestureRecognizerStateEnded && (ty > H * 0.22 || vy > 900) && vy > -200;
    if (close && vc) {
        gCloseVelocity = MAX(0, vy);
        gOurClose = YES;
        [vc dismissViewControllerAnimated:YES completion:nil];
        gOurClose = NO;
    } else {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            v.transform = CGAffineTransformIdentity;
            v.layer.cornerRadius = 0;
        } completion:nil];
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return NO; }
@end

// When the full player appears: our drag replaces Music's swipe-down.
static void MaybeInstallDrag(UIViewController *vc) {
    {
        NSString *n = NSStringFromClass([vc class]);
        if (vc.view.window.rootViewController.presentedViewController == vc && ([n containsString:@"Player"] || [n containsString:@"NowPlaying"]))
            gPlayerCooldownUntil = CACurrentMediaTime() + 3;
    }
    if (!gCollapse || !gRound) return;
    UIWindow *win = vc.view.window;
    UIViewController *root = win.rootViewController;
    NSString *cn = NSStringFromClass([vc class]);
    if (!root || root.presentedViewController != vc || !([cn containsString:@"Player"] || [cn containsString:@"NowPlaying"])) return;
    UIView *v = vc.view;
    if (objc_getAssociatedObject(v, kDragAdded)) return;
    objc_setAssociatedObject(v, kDragAdded, vc, OBJC_ASSOCIATION_ASSIGN);
    // Music's own swipe-down (pans on the player and its container, not lists).
    for (UIView *p = v; p && p != win; p = p.superview)
        for (UIGestureRecognizer *g in p.gestureRecognizers)
            if ([g isKindOfClass:[UIPanGestureRecognizer class]] && ![p isKindOfClass:[UIScrollView class]]) g.enabled = NO;
    NSMutableArray *stack = [NSMutableArray arrayWithArray:v.subviews];
    int guard = 0;
    while (stack.count && guard++ < 3000) {
        UIView *s = stack.lastObject; [stack removeLastObject];
        NSString *sn = NSStringFromClass([s class]);
        BOOL keep = [s isKindOfClass:[UIScrollView class]] || [s isKindOfClass:[UISlider class]] || [s isKindOfClass:[UIControl class]] ||
                    [sn containsString:@"Slider"] || [sn containsString:@"TimeControl"] || [sn containsString:@"Volume"] || [sn containsString:@"Scrub"];
        if (!keep)
            for (UIGestureRecognizer *g in s.gestureRecognizers)
                if ([g isKindOfClass:[UIPanGestureRecognizer class]] && g.view == s) g.enabled = NO;
        [stack addObjectsFromArray:s.subviews];
    }
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[MPPlayerDrag shared] action:@selector(pan:)];
    pan.delegate = [MPPlayerDrag shared];
    pan.maximumNumberOfTouches = 1;
    [v addGestureRecognizer:pan];
}

@interface MPPillTicker : NSObject
+ (instancetype)shared;
- (void)tick:(CADisplayLink *)l;
@end
static void PlayerStarSync(void);
@implementation MPPillTicker
+ (instancetype)shared { static MPPillTicker *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPPillTicker new]; }); return t; }
- (void)tick:(CADisplayLink *)l {
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    @try { SyncPill(); } @catch (__unused id e) {}
    @try { PlayerStarSync(); } @catch (__unused id e) {}   // star follows ••• every frame (lyrics/queue moves it)
}
@end

@implementation MPCollapse
+ (instancetype)shared { static MPCollapse *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPCollapse new]; }); return t; }
- (void)tapTab {
    // Go to the tab the circle shows (the current one, or the last one before Search).
    UITabBar *tb = gLastTabBar;
    UITabBarItem *it = tb.selectedItem;
    if (IsSearchItem(tb, it)) it = gLastOtherTab ?: (tb.items.count >= 2 ? tb.items[tb.items.count - 2] : nil);
    NSUInteger idx = it ? [tb.items indexOfObject:it] : NSNotFound;
    SetCollapsed(NO, YES);
    UITabBarController *tc = [tb.delegate isKindOfClass:[UITabBarController class]] ? (UITabBarController *)tb.delegate : nil;
    if (tc && idx != NSNotFound && idx < tc.viewControllers.count && tc.selectedIndex != idx) {
        UIViewController *vc = tc.viewControllers[idx];
        if (![tc.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)] || [tc.delegate tabBarController:tc shouldSelectViewController:vc]) {
            tc.selectedIndex = idx;
            if ([tc.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) [tc.delegate tabBarController:tc didSelectViewController:vc];
        }
    }
}
// iOS 26 jelly on the glass circles: swell under the finger, lean toward it, wobble back.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)jelly:(UILongPressGestureRecognizer *)g {
    UIView *c = g.view;
    UIViewAnimationOptions o = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    if (g.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:o animations:^{
            c.transform = CGAffineTransformMakeScale(1.18, 1.18);
        } completion:nil];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [g locationInView:c];
        CGFloat ox = tanh((p.x - c.bounds.size.width / 2) / 40) * 8, oy = tanh((p.y - c.bounds.size.height / 2) / 40) * 8;
        CGFloat sx = 1.18 + fabs(ox) * 0.012 - fabs(oy) * 0.006, sy = 1.18 + fabs(oy) * 0.012 - fabs(ox) * 0.006;
        [UIView animateWithDuration:0.18 delay:0 options:o | UIViewAnimationOptionCurveEaseOut animations:^{
            c.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(ox, oy), sx, sy);
        } completion:nil];
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.38 initialSpringVelocity:0.9 options:o animations:^{
            c.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}
- (void)tapSearch {
    UITabBar *tb = gLastTabBar;
    UITabBarController *tc = [tb.delegate isKindOfClass:[UITabBarController class]] ? (UITabBarController *)tb.delegate : nil;
    NSUInteger idx = NSNotFound;
    for (NSUInteger i = 0; i < tb.items.count; i++) {
        UITabBarItem *it = tb.items[i];
        if (it.tag == 0 && [it.title.lowercaseString containsString:@"search"]) idx = i;
    }
    if (idx == NSNotFound && tb.items.count) idx = tb.items.count - 1;
    SetCollapsed(NO, YES);
    if (tc && idx < tc.viewControllers.count) {
        UIViewController *vc = tc.viewControllers[idx];
        if (![tc.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)] || [tc.delegate tabBarController:tc shouldSelectViewController:vc]) {
            tc.selectedIndex = idx;
            if ([tc.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) [tc.delegate tabBarController:tc didSelectViewController:vc];
        }
    }
}
@end

#pragma mark - grow while scrolling

static void SetPillExpanded(BOOL expanded) {
    if (gExpanded == expanded) return;
    gExpanded = expanded;
    UITabBar *tb = gLastTabBar;
    UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
    if (!mini || !mini.window || !objc_getAssociatedObject(mini, kStyled)) return;
    CGAffineTransform t = PillTransform(mini);
    // Record first so the watchdog treats this size as ours and doesn't fight it.
    objc_setAssociatedObject(mini, kApplied, [NSValue valueWithCGAffineTransform:t], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ mini.transform = t; } completion:nil];
}

static void PageScrolled(UIScrollView *sv, CGFloat dy, CGFloat y) {
    static CGFloat acc = 0;
    if ((dy > 0) != (acc > 0)) acc = 0; // direction changed
    acc += dy;
    if (gCollapse) {
        // iOS 26: scrolling down collapses the bars, scrolling back up (or reaching the top) opens them.
        if (y <= -sv.adjustedContentInset.top + 4) { SetCollapsed(NO, YES); return; }
        if (acc > 40) SetCollapsed(YES, YES);
        else if (acc < -40) SetCollapsed(NO, YES);
        return;
    }
    // dy < 0: finger moving down (page moves back toward the top) -> bigger.
    // dy > 0: finger moving up (page moves down) -> normal.
    if (acc < -12) SetPillExpanded(YES);
    else if (acc > 12) SetPillExpanded(NO);
}

static char gQueueShiftKey;
static __weak UIView *gPlayerMoreQ;
static const void *kNarrowSeg = &kNarrowSeg;
#define SEG_W 236.0
%hook UISegmentedControl
- (void)setFrame:(CGRect)f {
    if (objc_getAssociatedObject(self, kNarrowSeg) && f.size.width > SEG_W) {
        f = CGRectMake(round(CGRectGetMidX(f) - SEG_W / 2), f.origin.y, SEG_W, f.size.height);
    }
    %orig(f);
}
- (void)setBounds:(CGRect)b {
    if (objc_getAssociatedObject(self, kNarrowSeg) && b.size.width > SEG_W) b.size.width = SEG_W;
    %orig(b);
}
%end

static void ScopeEval(BOOL animated);
static __weak UIScrollView *gScopeList;
static __weak UIScrollView *gAvatarList;
static void AvatarEval(void);
%hook UIScrollView
- (void)setContentInset:(UIEdgeInsets)inset {
    // Queue list is slid down 54pt; add 54pt at the bottom so the last song
    // can still scroll fully into view above the trimmed edge.
    if (objc_getAssociatedObject(self, kQueueTable)) inset.bottom += QUEUE_EXTRA;   // last song still reachable above the trimmed edge
    %orig(inset);
}
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)event {
    // Queue list: no touches in its trimmed bottom (play controls stay tappable).
    NSNumber *sh = objc_getAssociatedObject(self, kQueueTable) ? objc_getAssociatedObject(self, &gQueueShiftKey) : nil;
    if (sh && p.y >= self.bounds.origin.y + self.bounds.size.height - sh.doubleValue) return NO;
    return %orig;
}
- (void)setContentOffset:(CGPoint)offset {
    CGPoint old = self.contentOffset;
    %orig;
    if (self == gScopeList) { @try { ScopeEval(YES); } @catch (__unused id e) {} }
    if (self == gAvatarList) { @try { AvatarEval(); } @catch (__unused id e) {} }
    if (objc_getAssociatedObject(self, kQueueTable)) { @try { PositionQueueRow(self); } @catch (__unused id e) {} }
    if (!gRound) return;
    // Only the user scrolling a full page: not side-scrolling rows, not small views.
    if (!(self.isTracking || self.isDecelerating)) return;
    if (self.bounds.size.height < 300) return;
    CGFloat dy = offset.y - old.y, dx = offset.x - old.x;
    if (dy == 0 || (fabs(dx) > fabs(dy) && fabs(dx) > 0.5)) return;
    UITabBar *tb = gLastTabBar;
    if (!tb || self.window != tb.window) return;
    UIViewController *root = self.window.rootViewController;
    if (PresentedPlayer(root) && !PresentedPlayer(root).isBeingDismissed) return; // full player
    PageScrolled(self, dy, offset.y);
}
%end

%hook UIControl
// Our hidden originals (Play/Shuffle/Download): if Music tries to bring them
// back, keep them invisible. This is what stops the old buttons flickering in.
- (void)setAlpha:(CGFloat)alpha {
    if (alpha > 0 && objc_getAssociatedObject(self, kHidByUs)) { %orig(0); return; }
    %orig;
}
// When Music lays out its (hidden) Play/Shuffle, move our row with it right away.
- (void)layoutSubviews {
    %orig;
    if (objc_getAssociatedObject(self, kHidByUs)) AlbumControlLaidOut(self);
}
%end

%hook UIView
// Music's bar moved under the collapsed pill sits outside its container:
// let touches reach it there.
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)e {
    if (gCollapsed) {
        UIView *m = gUnderMini;
        if (m && m.window && self != m && [m isDescendantOfView:self]) {
            if ([m pointInside:[self convertPoint:p toView:m] withEvent:e]) return YES;
        }
    }
    return %orig;
}
// Music's gray circles we cleared behind the top buttons stay clear.
- (void)setBackgroundColor:(UIColor *)color {
    if (color && gNavGlass && objc_getAssociatedObject(self, kClearedBG)) { %orig(UIColor.clearColor); return; }
    %orig;
    // Round the queue button's background the moment Music colors it, so the
    // square never shows.
    if (color && gQueueLook && self.window) { @try { RoundIfQueueButton(self); } @catch (__unused id e) {} }
}
%end

static void StyleSearchBar(UISearchBar *sb);
%hook UISearchBar
- (void)didMoveToWindow {
    %orig;
    if (self.window) { @try { StyleSearchBar(self); } @catch (__unused id e) {} }
}
- (void)layoutSubviews {
    %orig;
    @try { StyleSearchBar(self); } @catch (__unused id e) {}
}
%end

static UIControl *HideMusicEdit(UINavigationBar *nb, BOOL *editingOut);
#define EDIT_TAG_FWD 0x4D504544
%hook UINavigationBar
- (void)layoutSubviews {
    %orig;
    // Library: Music's Edit/Done is swapped on tap; hide the new one before it's drawn.
    if ([self viewWithTag:EDIT_TAG_FWD] && ![self viewWithTag:EDIT_TAG_FWD].hidden) { @try { HideMusicEdit(self, NULL); } @catch (__unused id e) {} }
}
// White top icons; Music sets its red tint per page, which flashed red.
- (void)setTintColor:(UIColor *)color { %orig(gNavGlass ? UIColor.whiteColor : color); }
%end

%hook UIBarButtonItem
- (void)setTintColor:(UIColor *)color {
    if ([color isEqual:UIColor.clearColor]) { %orig; return; }   // Library's invisible Edit
    if ([self.tintColor isEqual:UIColor.clearColor]) return;
    %orig(gNavGlass ? UIColor.whiteColor : color);
}
- (void)setTitle:(NSString *)title {
    %orig;
    // editButtonItem flips Edit <-> Done on the same item: keep it invisible.
    if ([self.tintColor isEqual:UIColor.clearColor]) { @try { InvisibleBarItem(self); } @catch (__unused id e) {} }
}
%end

%hook UITabBar
- (void)setAlpha:(CGFloat)a {
    if (gCollapsed && self == gLastTabBar && a > 0.01) { %orig(0); return; }
    %orig;
}
- (void)setHidden:(BOOL)h {
    %orig;
    if (h && gCollapsed && self == gLastTabBar) {
        dispatch_async(dispatch_get_main_queue(), ^{ SetCollapsed(NO, YES); });
    }
}
- (void)setSelectedItem:(UITabBarItem *)it {
    %orig;
    if (it && !IsSearchItem(self, it)) gLastOtherTab = it;
    if (gCollapsed && self == gLastTabBar) dispatch_async(dispatch_get_main_queue(), ^{ SetCollapsed(NO, YES); });
}
- (void)layoutSubviews {
    %orig;
    gLastTabBar = self;
    if (objc_getAssociatedObject(self, kBusy)) return;
    objc_setAssociatedObject(self, kBusy, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UITabBar *weak = self;
    // Run after this layout pass finishes.
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBar *tb = weak;
        if (!tb) return;
        @try { Update(tb); } @catch (__unused id e) {}
        objc_setAssociatedObject(tb, kBusy, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}
%end


#pragma mark - scrolling title (marquee)

static const void *kMarqText = &kMarqText;
static const void *kHidLabel = &kHidLabel;

static void FindLabels(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (s.tag == MARQUEE_TAG || s.tag == GLASS_TAG || s.hidden) continue;
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) [out addObject:s];
        if (depth < 6) FindLabels(s, depth + 1, out);
    }
}

static UIView *FindMarqueeView(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if ([NSStringFromClass([s class]) containsString:@"Marquee"]) return s;
        if (depth < 6) { UIView *f = FindMarqueeView(s, depth + 1); if (f) return f; }
    }
    return nil;
}

static void RemoveMarquee(UILabel *label) {
    UIView *m = [label.superview viewWithTag:MARQUEE_TAG];
    if (m.superview == label.superview) [m removeFromSuperview];
    if (objc_getAssociatedObject(label, kHidLabel)) {
        label.alpha = 1;
        objc_setAssociatedObject(label, kHidLabel, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static UILabel *CopyLabel(UILabel *src) {
    UILabel *l = [UILabel new];
    l.text = src.text;
    l.font = src.font;
    l.textColor = src.textColor;
    [l sizeToFit];
    return l;
}

static void BuildMarquee(UILabel *label, CGFloat textW) {
    UIView *box = [[UIView alloc] initWithFrame:label.frame];
    box.tag = MARQUEE_TAG;
    box.clipsToBounds = YES;
    box.userInteractionEnabled = NO;

    const CGFloat gap = 40;
    UIView *strip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textW * 2 + gap, box.bounds.size.height)];
    UILabel *a = CopyLabel(label), *b = CopyLabel(label);
    CGFloat y = (box.bounds.size.height - a.bounds.size.height) / 2;
    a.frame = CGRectMake(0, y, textW, a.bounds.size.height);
    b.frame = CGRectMake(textW + gap, y, textW, b.bounds.size.height);
    [strip addSubview:a];
    [strip addSubview:b];
    [box addSubview:strip];

    // Soft fade on both edges.
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = box.bounds;
    mask.startPoint = CGPointMake(0, 0.5);
    mask.endPoint = CGPointMake(1, 0.5);
    mask.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
    mask.locations = @[@0, @0.04, @0.92, @1];
    box.layer.mask = mask;

    // Hold, scroll one full loop at a steady speed, repeat. Loops seamlessly
    // because the second copy lands exactly where the first started.
    CGFloat distance = textW + gap;
    CFTimeInterval hold = 2.0, move = distance / 32.0;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    anim.values = @[@0, @0, @(-distance)];
    anim.keyTimes = @[@0, @(hold / (hold + move)), @1];
    anim.duration = hold + move;
    anim.repeatCount = HUGE_VALF;
    anim.removedOnCompletion = NO;
    [strip.layer addAnimation:anim forKey:@"musicpill.marquee"];

    [label.superview insertSubview:box aboveSubview:label];
}

static void MarqueeTick(UIView *mini) {
    if (!mini || !mini.window) return;
    // 1. Apple's own marquee view, if the bar has one: just switch it on.
    UIView *apple = FindMarqueeView(mini, 0);
    if (apple) {
        @try { [apple setValue:@(gMarquee) forKey:@"marqueeEnabled"]; gMarqueeDebug = @"apple marquee"; return; }
        @catch (__unused id e) {}
    }
    // 2. Otherwise our own: the biggest-font label in the bar is the title.
    NSMutableArray *labels = [NSMutableArray array];
    FindLabels(mini, 0, labels);
    UILabel *title = nil;
    for (UILabel *l in labels) if (!title || l.font.pointSize > title.font.pointSize) title = l;
    if (!title) { gMarqueeDebug = @"no label"; return; }

    CGFloat textW = ceil([title.text sizeWithAttributes:@{NSFontAttributeName: title.font}].width);
    BOOL needs = gMarquee && textW > title.bounds.size.width + 1 && title.bounds.size.width > 20;
    UIView *box = [title.superview viewWithTag:MARQUEE_TAG];
    if (box && box.superview != title.superview) box = nil;
    gMarqueeDebug = [NSString stringWithFormat:@"%@ text=%.0f box=%.0f %@", NSStringFromClass([title class]), textW, title.bounds.size.width, needs ? @"scroll" : @"fits"];

    if (!needs) { if (box || objc_getAssociatedObject(title, kHidLabel)) RemoveMarquee(title); return; }

    NSString *sig = [NSString stringWithFormat:@"%@|%.1f|%.1f", title.text, title.bounds.size.width, title.font.pointSize];
    if (!box || ![objc_getAssociatedObject(title, kMarqText) isEqualToString:sig]) {
        [box removeFromSuperview];
        BuildMarquee(title, textW);
        objc_setAssociatedObject(title, kMarqText, sig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        box = [title.superview viewWithTag:MARQUEE_TAG];
    }
    if (!CGRectEqualToRect(box.frame, title.frame)) {
        box.frame = title.frame;
        box.layer.mask.frame = box.bounds;
    }
    if (title.alpha != 0) {
        title.alpha = 0;
        objc_setAssociatedObject(title, kHidLabel, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - iOS 26 album / playlist buttons

static __weak UIControl *gPlayCtl, *gShuffleCtl, *gDownloadCtl;
// The download/checkmark slot in the top bar (leftmost right-hand button).
static __weak UIView *gSlotView;
static BOOL gPortalLive = NO;

static UIControl *FirstControl(UIView *v, int depth) {
    if ([v isKindOfClass:[UIControl class]]) return (UIControl *)v;
    if (depth > 6) return nil;
    for (UIView *s in v.subviews) { UIControl *c = FirstControl(s, depth + 1); if (c) return c; }
    return nil;
}
static __weak UIView *gRowParent;
static CFTimeInterval gLastHeaderSearch;

static UIControl *ControlAbove(UIView *v) {
    int d = 0;
    for (UIView *p = v; p && d < 6; p = p.superview, d++)
        if ([p isKindOfClass:[UIControl class]]) return (UIControl *)p;
    return nil;
}

static BOOL InBottomBars(UIView *v) {
    for (UIView *p = v; p; p = p.superview) {
        if ([p isKindOfClass:[UITabBar class]] || objc_getAssociatedObject(p, kStyled)) return YES;
        NSString *n = NSStringFromClass([p class]);
        if ([n containsString:@"PaletteContainerView"]) return YES;
    }
    return NO;
}

static void FindHeaderControls(UIView *v, int depth, UIControl **play, UIControl **shuffle, UIControl **download) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.tag == ROW_TAG || s.tag == DEBUG_TAG || s.tag == NAVGLASS_TAG) continue;
        if ([s isKindOfClass:[UILabel class]]) {
            NSString *txt = ((UILabel *)s).text;
            if (!*play && [txt isEqualToString:@"Play"]) { UIControl *c = ControlAbove(s); if (c && !InBottomBars(c)) *play = c; }
            else if (!*shuffle && [txt isEqualToString:@"Shuffle"]) { UIControl *c = ControlAbove(s); if (c && !InBottomBars(c)) *shuffle = c; }
        }
        if (!*download && [s isKindOfClass:[UIControl class]] && ([s.accessibilityLabel isEqualToString:@"Download"] || [((UIImageView *)GlyphIn(s, 0)).image.description containsString:@"arrow.down"]) && !InBottomBars(s))
            *download = (UIControl *)s;
        if (*play && *shuffle && *download) return;
        if (depth < 30) FindHeaderControls(s, depth + 1, play, shuffle, download);
    }
}

static UIView *CommonParent(UIView *a, UIView *b) {
    for (UIView *p = a.superview; p; p = p.superview)
        if ([b isDescendantOfView:p]) return p;
    return nil;
}

static void HideOriginal(UIView *v) {
    if (v.alpha != 0) { v.alpha = 0; objc_setAssociatedObject(v, kHidByUs, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
}
static void ShowOriginal(UIView *v) {
    if (v && objc_getAssociatedObject(v, kHidByUs)) {
        objc_setAssociatedObject(v, kHidByUs, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        v.alpha = 1;
    }
}

static void Forward(UIControl *c) {
    if (!c) return;
    UIControlEvents ev = c.allControlEvents;
    if (ev & UIControlEventTouchUpInside) [c sendActionsForControlEvents:UIControlEventTouchUpInside];
    else if (ev & UIControlEventPrimaryActionTriggered) [c sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
}

@interface MPRowTarget : NSObject
+ (instancetype)shared;
@end
static CFTimeInterval gAddPendingUntil;
static void ShowToast(UILabel *label, NSString *icon, NSString *text);
@implementation MPRowTarget
+ (instancetype)shared { static MPRowTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPRowTarget new]; }); return t; }
- (void)tap:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (b.tag == 1) Forward(gPlayCtl);
    else if (b.tag == 2) Forward(gShuffleCtl);
    else if (b.tag == 3) {
        UIView *slot = gSlotView;
        if (!slot) return;
        if ([objc_getAssociatedObject(b, @selector(MirrorDownload)) isEqual:@"plus"]) {
            gAddPendingUntil = CACurrentMediaTime() + 4;
            ShowToast(nil, @"checkmark", @"Added to Library");
        }
        Forward(FirstControl(slot, 0));
    }
}
@end

static UIButton *RowButton(NSInteger tag, NSString *symbol, NSString *title, BOOL white) {
    UIButtonConfiguration *cfg = white ? [UIButtonConfiguration filledButtonConfiguration] : [UIButtonConfiguration filledButtonConfiguration];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    cfg.baseBackgroundColor = white ? UIColor.whiteColor : [UIColor colorWithWhite:0.20 alpha:1];
    cfg.baseForegroundColor = white ? UIColor.blackColor : UIColor.whiteColor;
    cfg.image = [UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:white ? 17 : 18 weight:UIImageSymbolWeightSemibold]];
    if (title) {
        cfg.title = title;
        cfg.imagePadding = 7;
        cfg.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *in) {
            NSMutableDictionary *d = [in mutableCopy];
            d[NSFontAttributeName] = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
            return d;
        };
    }
    cfg.contentInsets = NSDirectionalEdgeInsetsZero;
    UIButton *b = [UIButton buttonWithConfiguration:cfg primaryAction:nil];
    b.tag = tag;
    [b addTarget:[MPRowTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    if (!white) {
        b.layer.borderWidth = 0.6;
        b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
        b.layer.cornerCurve = kCACornerCurveContinuous;
    }
    return b;
}

static NSHashTable *gPreHidden; // Play/Shuffle hidden early, before the row exists
static CFTimeInterval gPreHideTime;

static void ShowPreHidden(UIControl *keepA, UIControl *keepB) {
    for (UIControl *c in [gPreHidden allObjects]) if (c != keepA && c != keepB) ShowOriginal(c);
    [gPreHidden removeAllObjects];
}

static void TearDownRow(void) {
    UIView *parent = gRowParent;
    [[parent viewWithTag:ROW_TAG] removeFromSuperview];
    ShowOriginal(gPlayCtl); ShowOriginal(gShuffleCtl); ShowOriginal(gDownloadCtl);
    ShowPreHidden(nil, nil);
    gPortalLive = NO;
}

static UIView *GlyphIn(UIView *v, int depth);

// The row's right circle draws Music's download state itself: arrow, a live
// progress ring (copied from Music's ring), then the checkmark.
static NSString *gDLState = @"-";
static CAShapeLayer *FindRing(CALayer *l, int depth) {
    if (depth > 8) return nil;
    CAShapeLayer *best = nil;
    for (CALayer *s in l.sublayers) {
        if ([s isKindOfClass:[CAShapeLayer class]] && ((CAShapeLayer *)s).path && !s.hidden && ((CAShapeLayer *)s).strokeColor && ((CAShapeLayer *)s).lineWidth > 0) {
            CAShapeLayer *sh = (CAShapeLayer *)s;
            if (!best || sh.strokeEnd < best.strokeEnd) best = sh;
        }
        CAShapeLayer *d = FindRing(s, depth + 1);
        if (d && (!best || d.strokeEnd < best.strokeEnd)) best = d;
    }
    return best;
}
static void MirrorDownload(UIButton *bDL, UIView *slot, CGFloat h) {
    NSString *d = nil;
    UIView *g = GlyphIn(slot, 0);
    if ([g isKindOfClass:[UIImageView class]]) d = ((UIImageView *)g).image.description.lowercaseString;
    CAShapeLayer *src = FindRing(slot.layer, 0);
    NSString *state;
    if ([d containsString:@"checkmark"]) state = @"done";
    else if ([d containsString:@"plus"]) state = CACurrentMediaTime() < gAddPendingUntil ? @"idle" : @"add";
    else if ([d containsString:@"arrow.down"] || [d containsString:@"icloud"]) state = src && src.strokeEnd > 0.001 && src.strokeEnd < 0.999 ? @"progress" : @"idle";
    else state = @"progress";   // stop square or no glyph: downloading
    CGFloat p = src ? ((CAShapeLayer *)(src.presentationLayer ?: src)).strokeEnd : -1;
    gDLState = [NSString stringWithFormat:@"%@ p=%.2f glyph=%@", state, p, d ? [d substringFromIndex:MIN(d.length, [d rangeOfString:@"symbol("].location == NSNotFound ? 0 : [d rangeOfString:@"symbol("].location)] : @"none"];
    if (gDLState.length > 70) gDLState = [gDLState substringToIndex:70];

    NSString *sym = [state isEqualToString:@"done"] ? @"checkmark" : [state isEqualToString:@"progress"] ? @"stop.fill" : [state isEqualToString:@"add"] ? @"plus" : @"arrow.down";
    CGFloat pt = [state isEqualToString:@"progress"] ? 11 : 18;
    NSString *prevSym = objc_getAssociatedObject(bDL, @selector(MirrorDownload));
    if (![prevSym isEqual:sym]) {
        objc_setAssociatedObject(bDL, @selector(MirrorDownload), sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:[state isEqualToString:@"progress"] ? UIImageSymbolWeightBlack : UIImageSymbolWeightSemibold]];
        void (^apply)(void) = ^{ UIButtonConfiguration *cfg = bDL.configuration; cfg.image = img; bDL.configuration = cfg; };
        if (prevSym && bDL.window) {
            // Smooth swap (plus -> arrow -> progress -> checkmark): squish, cross-fade, spring back.
            [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ bDL.transform = CGAffineTransformMakeScale(0.82, 0.82); } completion:^(BOOL f) {
                [UIView transitionWithView:bDL duration:0.22 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction animations:apply completion:nil];
                [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.8 options:UIViewAnimationOptionAllowUserInteraction animations:^{ bDL.transform = CGAffineTransformIdentity; } completion:nil];
            }];
        } else apply();
    }
    CAShapeLayer *track = nil, *ring = nil;
    for (CALayer *l in bDL.layer.sublayers) {
        if ([l.name isEqualToString:@"mp.track"]) track = (CAShapeLayer *)l;
        if ([l.name isEqualToString:@"mp.ring"]) ring = (CAShapeLayer *)l;
    }
    BOOL prog = [state isEqualToString:@"progress"];
    if (prog && !ring) {
        track = [CAShapeLayer layer]; track.name = @"mp.track";
        ring = [CAShapeLayer layer]; ring.name = @"mp.ring";
        for (CAShapeLayer *x in @[track, ring]) { x.fillColor = UIColor.clearColor.CGColor; x.lineWidth = 2.5; x.lineCap = kCALineCapRound; [bDL.layer addSublayer:x]; }
        track.strokeColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
        ring.strokeColor = UIColor.whiteColor.CGColor;
    }
    track.hidden = ring.hidden = !prog;
    if (!prog) { [ring removeAnimationForKey:@"spin"]; return; }
    CGRect rr = CGRectMake(h / 2 - 12, h / 2 - 12, 24, 24);
    if (!CGRectEqualToRect(ring.frame, rr)) {
        UIBezierPath *bp = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 12) radius:11 startAngle:-M_PI_2 endAngle:M_PI * 1.5 clockwise:YES];
        track.frame = rr; ring.frame = rr; track.path = bp.CGPath; ring.path = bp.CGPath;
    }
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    if (p >= 0.001 && p < 0.999) {
        [ring removeAnimationForKey:@"spin"];
        ring.transform = CATransform3DIdentity;
        ring.strokeEnd = p;
    } else {
        // Waiting / unknown progress: spinning arc.
        ring.strokeEnd = 0.25;
        if (![ring animationForKey:@"spin"]) {
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            a.fromValue = @0; a.toValue = @(M_PI * 2); a.duration = 0.9; a.repeatCount = HUGE_VALF;
            [ring addAnimation:a forKey:@"spin"];
        }
    }
    [CATransaction commit];
}

static void AlbumTick(UIWindow *w) {
    if (!w) return;
    if (!gAlbum) { TearDownRow(); gAlbumDebug = @"off"; return; }

    UIControl *play = gPlayCtl, *shuffle = gShuffleCtl;
    BOOL lost = !play || !shuffle || !play.window || !shuffle.window;
    if (lost) {
        CFTimeInterval now = CACurrentMediaTime();
        if (now - gLastHeaderSearch < 0.2) return;
        gLastHeaderSearch = now;
        UIControl *p = nil, *s = nil, *d = nil;
        FindHeaderControls(w, 0, &p, &s, &d);
        if (!p || !s) {
            // One of the pair may not have its label yet. Give it half a second
            // before showing any early-hidden button again (no flash either way).
            if (gPreHidden.count && CACurrentMediaTime() - gPreHideTime < 0.5) { gLastHeaderSearch = 0; return; }
            TearDownRow();
            gPlayCtl = nil; gShuffleCtl = nil; gDownloadCtl = nil;
            gAlbumDebug = [NSString stringWithFormat:@"play=%d shuffle=%d", p != nil, s != nil];
            return;
        }
        gPlayCtl = p; gShuffleCtl = s; gDownloadCtl = d;
        play = p; shuffle = s;
    }
    UIView *parent = CommonParent(play, shuffle);
    // Only take over if the originals can be triggered from our buttons.
    if (!parent || !play.allControlEvents || !shuffle.allControlEvents) {
        TearDownRow();
        gAlbumDebug = [NSString stringWithFormat:@"%@ ev=%lu/%lu parent=%d (can't forward taps)",
                       NSStringFromClass([play class]), (unsigned long)play.allControlEvents, (unsigned long)shuffle.allControlEvents, parent != nil];
        return;
    }
    if (gRowParent && gRowParent != parent) TearDownRow();
    gRowParent = parent;

    UIView *row = [parent viewWithTag:ROW_TAG];
    if (row.superview != parent) row = nil;
    if (!row) {
        row = [UIView new];
        row.tag = ROW_TAG;
        UIView *cover = [UIView new];
        cover.tag = 9;
        cover.backgroundColor = UIColor.clearColor;   // Music's buttons are hidden anyway; a fill hid animated covers
        cover.userInteractionEnabled = NO;
        [row addSubview:cover];
        [row addSubview:RowButton(2, @"shuffle", nil, NO)];
        [row addSubview:RowButton(1, @"play.fill", @"Play", YES)];
        [row addSubview:RowButton(3, @"arrow.down", nil, NO)];
        [parent addSubview:row];
    }
    [parent bringSubviewToFront:row];

    CGRect pf = [play convertRect:play.bounds toView:parent];
    CGRect sf = [shuffle convertRect:shuffle.bounds toView:parent];
    CGRect u = CGRectUnion(pf, sf);
    CGFloat h = MAX(u.size.height, 40);
    CGRect rf = CGRectMake(u.origin.x, CGRectGetMidY(u) - h / 2, u.size.width, h);
    if (!CGRectEqualToRect(row.frame, rf)) row.frame = rf;
    // Cover exactly where Music's buttons are (not the taller row), so nothing
    // of the old buttons shows even for a frame.
    UIView *cover = [row viewWithTag:9];
    CGRect cf = CGRectOffset(u, -rf.origin.x, -rf.origin.y);
    if (!CGRectEqualToRect(cover.frame, cf)) cover.frame = cf;

    // Right circle: Music's own download control from the top bar, mirrored
    // live, so the arrow, the download progress and the checkmark all show
    // here in the same spot.
    UIView *slot = gSlotView;
    BOOL showDL = slot && slot.window;
    UIButton *bShuffle = [row viewWithTag:2], *bPlay = [row viewWithTag:1], *bDL = [row viewWithTag:3];
    CGFloat W = rf.size.width, gap = 11, playW = MIN(W * 0.45, 220);
    CGFloat x0 = (W - playW) / 2;
    CGRect fs = CGRectMake(x0 - gap - h, 0, h, h), fp = CGRectMake(x0, 0, playW, h), fd = CGRectMake(x0 + playW + gap, 0, h, h);
    if (!CGRectEqualToRect(bShuffle.frame, fs)) bShuffle.frame = fs;
    if (!CGRectEqualToRect(bPlay.frame, fp)) bPlay.frame = fp;
    if (!CGRectEqualToRect(bDL.frame, fd)) bDL.frame = fd;
    bShuffle.layer.cornerRadius = h / 2;
    bDL.layer.cornerRadius = h / 2;
    for (UIView *s in [bDL.subviews copy]) if (s.tag == PORTAL_TAG) [s removeFromSuperview];
    if (showDL) MirrorDownload(bDL, slot, h);
    gPortalLive = showDL;
    bDL.hidden = !showDL;

    HideOriginal(play);
    HideOriginal(shuffle);
    ShowPreHidden(play, shuffle);
    gAlbumDebug = [NSString stringWithFormat:@"row ok slot=%@ dl=%@", slot ? NSStringFromClass([slot class]) : @"none", gDLState];
}

#pragma mark - instant album triggers

static __weak UIWindow *gAlbumWindow;
static BOOL gAlbumPending;

static void ScheduleAlbum(UIWindow *w) {
    if (w) gAlbumWindow = w;
    static BOOL inside;
    static CFTimeInterval lastSync;
    if (w && !inside && CACurrentMediaTime() - lastSync > 0.05) {
        lastSync = CACurrentMediaTime();
        // Build our row right now (same layout pass), so Music's buttons never show.
        inside = YES;
        @try { AlbumTick(w); } @catch (__unused id e) {}
        inside = NO;
    }
    if (gAlbumPending) return;
    gAlbumPending = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        gAlbumPending = NO;
        UIWindow *win = gAlbumWindow;
        if (win) { @try { AlbumTick(win); } @catch (__unused id e) {} }
    });
}

static void AlbumControlLaidOut(UIControl *c) {
    if (gAlbum && (c == gPlayCtl || c == gShuffleCtl)) ScheduleAlbum(c.window);
}

static BOOL InOurRow(UIView *v) {
    for (UIView *p = v; p; p = p.superview) if (p.tag == ROW_TAG) return YES;
    return NO;
}

// Called the moment a "Play"/"Shuffle" label shows up: hide its button now and
// build the row on this same pass, so the old buttons are never drawn.
static void PreHide(UILabel *label) {
    if (!gAlbum || !label.window || InOurRow(label)) return;
    UIControl *c = ControlAbove(label);
    if (!c || InBottomBars(c)) return;
    if (c != gPlayCtl && c != gShuffleCtl) {
        if (!gPreHidden) gPreHidden = [NSHashTable weakObjectsHashTable];
        HideOriginal(c);
        [gPreHidden addObject:c];
        gPreHideTime = CACurrentMediaTime();
        gLastHeaderSearch = 0; // search immediately, no throttle
    }
    ScheduleAlbum(label.window);
}

static BOOL IsHeaderTitle(NSString *s) {
    return [s isKindOfClass:[NSString class]] && ([s isEqualToString:@"Play"] || [s isEqualToString:@"Shuffle"]);
}

// iOS 26 style pop-up: Music's big square HUD is hidden, a small glass capsule
// with a star and the word shows above the pill instead.
static void ShowToast(UILabel *label, NSString *icon, NSString *text);
static void ShowFavToast(UILabel *label, BOOL fav) {
    ShowToast(label, fav ? @"star.fill" : @"star.slash", fav ? @"Favorited" : @"Unfavorited");
}
static void ShowToast(UILabel *label, NSString *icon, NSString *text) {
    UIWindow *w = label.window ?: gLastTabBar.window;
    if (!w) return;
    // Hide Music's HUD box (the label's biggest ancestor smaller than the screen).
    UIView *box = nil;
    for (UIView *p = label.superview; p && p != w; p = p.superview) {
        if (p.bounds.size.width < w.bounds.size.width * 0.9 && p.bounds.size.height < w.bounds.size.height * 0.7) box = p;
        else break;
    }
    if (box && label) { box.layer.mask = [CALayer layer]; }
    static CFTimeInterval last; static NSString *lastKind;
    NSString *kind = text;
    if (CACurrentMediaTime() - last < 0.6 && [kind isEqualToString:lastKind]) return;
    last = CACurrentMediaTime(); lastKind = kind;
    static __weak UIView *current;
    [current removeFromSuperview];
    UIView *cap = [UIView new];
    cap.userInteractionEnabled = NO;
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    g.clipsToBounds = YES; g.layer.cornerCurve = kCACornerCurveContinuous;
    [cap addSubview:g];
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:icon
                                                    withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]]];
    iv.tintColor = UIColor.whiteColor; iv.contentMode = UIViewContentModeCenter;
    [cap addSubview:iv];
    UILabel *l = [UILabel new];
    l.text = text;
    l.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    l.textColor = UIColor.whiteColor;
    [cap addSubview:l];
    CGFloat lw = ceil([l.text sizeWithAttributes:@{NSFontAttributeName: l.font}].width);
    CGFloat H = 50, W = 22 + 24 + 12 + lw + 26;
    // Just above the pill / bars.
    CGFloat bottom = w.bounds.size.height - w.safeAreaInsets.bottom - 150;
    UIView *host = [gLastTabBar.superview viewWithTag:COLLAPSE_TAG];
    for (UIView *v in host.subviews) if ([v isKindOfClass:NSClassFromString(@"MPMiniPill")] && !v.hidden) bottom = [v convertRect:v.bounds toView:w].origin.y - 14;
    cap.frame = CGRectMake(round((w.bounds.size.width - W) / 2), bottom - H, W, H);
    g.frame = cap.bounds; g.layer.cornerRadius = H / 2;
    iv.frame = CGRectMake(22, 0, 24, H);
    l.frame = CGRectMake(22 + 24 + 12, 0, lw, H);
    [w addSubview:cap];
    current = cap;
    cap.alpha = 0; cap.transform = CGAffineTransformMakeScale(0.85, 0.85);
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        cap.alpha = 1; cap.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:0.3 delay:1.6 options:0 animations:^{
        cap.alpha = 0; cap.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL d) { [cap removeFromSuperview]; }];
}

static BOOL IsMusicRed(UIColor *c) {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (!c) return NO;
    c = [c resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
    if (![c getRed:&r green:&g blue:&b alpha:&a] || a < 0.5) return NO;
    // Music's red is Display P3, so in sRGB terms blue can be below 0.
    return r > 0.75 && r - g > 0.35 && r - b > 0.3 && g < 0.55;
}
static BOOL InBars(UIView *v) {
    for (UIView *p = v.superview; p; p = p.superview) if ([p isKindOfClass:[UITabBar class]] || p.tag == COLLAPSE_TAG) return YES;
    return NO;
}

%hook UILabel
- (void)tintColorDidChange {
    %orig;
    if (gAlbum && IsMusicRed(self.textColor) && !InBars(self) && !objc_getAssociatedObject(self, kKeepRed)) self.textColor = UIColor.whiteColor;
}
- (void)didMoveToSuperview {
    %orig;
    if (gAlbum && self.superview && IsMusicRed(self.textColor) && !InBars(self) && !objc_getAssociatedObject(self, kKeepRed)) self.textColor = UIColor.whiteColor;
}
- (void)setTextColor:(UIColor *)c {
    // iOS 26: the artist name and "Show Complete Album" are white, not red.
    if (gAlbum && IsMusicRed(c) && !InBars(self) && !objc_getAssociatedObject(self, kKeepRed)) { %orig(UIColor.whiteColor); return; }
    %orig;
}
- (void)setText:(NSString *)text {
    NSString *mapped = MapQueueText(text);
    %orig(mapped);
    if (mapped != text && ([mapped isEqualToString:@"Favorited"] || [mapped isEqualToString:@"Unfavorited"])) {
        BOOL fav = [mapped isEqualToString:@"Favorited"];
        __weak UILabel *weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{ @try { ShowFavToast(weak, fav); } @catch (__unused id e) {} });
    }
    if (gAlbum && IsHeaderTitle(mapped) && self.window) { @try { PreHide(self); } @catch (__unused id e) {} }
}
- (void)setAttributedText:(NSAttributedString *)text {
    if (gAlbum && text.length && !InBars(self)) {
        __block NSMutableAttributedString *m = nil;
        [text enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, text.length) options:0 usingBlock:^(id val, NSRange r, BOOL *stop) {
            if ([val isKindOfClass:[UIColor class]] && IsMusicRed(val)) { if (!m) m = [text mutableCopy]; [m addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:r]; }
        }];
        if (m) text = m;
    }
    if (gQueueLook && text.length) {
        NSString *m = MapQueueText(text.string);
        if (m != text.string) {
            NSMutableAttributedString *x = [text mutableCopy];
            [x replaceCharactersInRange:NSMakeRange(0, x.length) withString:m];
            text = x;
        }
    }
    %orig(text);
}
- (void)didMoveToWindow {
    %orig;
    if (gAlbum && self.window && IsHeaderTitle(self.text)) { @try { PreHide(self); } @catch (__unused id e) {} }
}
%end

#pragma mark - glass top buttons

static __weak UIView *gRightHost;

static void CollectBarButtons(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.tag == NAVGLASS_TAG) continue;
        NSString *n = NSStringFromClass([s class]);
        if ([n containsString:@"ButtonBarButton"] || [n containsString:@"BackButton"]) {
            if (s.bounds.size.width > 2) [out addObject:s];
            continue;
        }
        if (depth < 6) CollectBarButtons(s, depth + 1, out);
    }
}

static UIView *GlyphIn(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden || s.alpha < 0.01 || s.bounds.size.width < 2 || s.tag == NAVGLASS_TAG) continue;
        if ([s isKindOfClass:[UIImageView class]] && ((UIImageView *)s).image) return s;
        if (depth < 5) { UIView *g = GlyphIn(s, depth + 1); if (g) return g; }
    }
    return nil;
}

// Music's own gray circles behind its top buttons: clear them once. The
// setBackgroundColor hook below keeps them clear, so they can't flash back.
static void ClearCircles(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UIImageView class]] || [s isKindOfClass:[UILabel class]] || s.tag == NAVGLASS_TAG) continue;
        if (!objc_getAssociatedObject(s, kClearedBG) && s.backgroundColor && CGColorGetAlpha(s.backgroundColor.CGColor) > 0.01 &&
            fabs(s.bounds.size.width - s.bounds.size.height) < 3 && s.bounds.size.width >= 20) {
            objc_setAssociatedObject(s, kClearedBG, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            s.backgroundColor = UIColor.clearColor;
        }
        if (depth < 4) ClearCircles(s, depth + 1);
    }
}

static UIView *GlassIn(UIView *host) {
    for (UIView *s in host.subviews) if (s.tag == NAVGLASS_TAG) return s;
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    g.tag = NAVGLASS_TAG;
    g.userInteractionEnabled = NO;
    g.clipsToBounds = YES;
    g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75;
    g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    [host insertSubview:g atIndex:0];
    return g;
}

static void RemoveGlass(UIView *v, int depth) {
    for (UIView *s in [v.subviews copy]) {
        if (s.tag == NAVGLASS_TAG) { [s removeFromSuperview]; continue; }
        if (depth < 8) RemoveGlass(s, depth + 1);
    }
}

static void SetFrameIfNew(UIView *v, CGRect f, CGFloat radius) {
    if (!CGRectEqualToRect(v.frame, f)) v.frame = f;
    if (v.layer.cornerRadius != radius) v.layer.cornerRadius = radius;
}

// Glass goes right behind the icon, in the icon's own container, so it moves
// and fades with the button during transitions and never covers the icon.
static UIView *GlassBelow(UIView *glyph) {
    UIView *host = glyph.superview;
    UIView *g = nil;
    for (UIView *s in host.subviews) if (s.tag == NAVGLASS_TAG) { g = s; break; }
    if (!g) {
        UIVisualEffectView *e = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        e.tag = NAVGLASS_TAG;
        e.userInteractionEnabled = NO;
        e.clipsToBounds = YES;
        e.layer.cornerCurve = kCACornerCurveContinuous;
        e.layer.borderWidth = 0.75;
        e.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
        g = e;
        [host insertSubview:g belowSubview:glyph];
    } else if ([host.subviews indexOfObject:g] > [host.subviews indexOfObject:glyph]) {
        [host insertSubview:g belowSubview:glyph];
    }
    return g;
}

static void MaskOut(UIView *v);
// ---- Search page, iOS 26 look ----
static NSString *gSearchDebug = @"-";
// A taller capsule search field (the background image sets its height).
static UIColor *GlassFill(void) { return [UIColor colorWithRed:0.16 green:0.16 blue:0.17 alpha:0.94]; }
#define XDISC_TAG 0x4D505844
static void Wobble(UIView *v, CGFloat sx, CGFloat sy, CFTimeInterval delay);
@interface MPSegBounce : NSObject
+ (instancetype)shared;
@end
@implementation MPSegBounce
+ (instancetype)shared { static MPSegBounce *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPSegBounce new]; }); return t; }
- (void)changed:(UISegmentedControl *)seg {
    // Jelly bounce on the switch, and the selected pill pops.
    Wobble(seg, 1.05, 0.9, 0);
    for (UIView *s in seg.subviews) {
        if (![s isKindOfClass:[UIImageView class]] || s.alpha < 0.05 || s.hidden) continue;
        if (s.frame.size.width <= 2 || s.frame.size.width >= seg.bounds.size.width - 4) continue;
        Wobble(s, 1.12, 0.86, 0.04);
    }
}
@end
static void StyleSegment(UISegmentedControl *seg) {
    CGFloat h = seg.bounds.size.height;
    if (h < 10) return;
    if (!objc_getAssociatedObject(seg, @selector(StyleSegment:))) {
        objc_setAssociatedObject(seg, @selector(StyleSegment:), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(seg, kNarrowSeg, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        seg.frame = seg.frame;   // apply the narrow width now
        NSDictionary *ta = @{NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium]};
        [seg setTitleTextAttributes:ta forState:UIControlStateNormal];
        [seg setTitleTextAttributes:ta forState:UIControlStateSelected];
        seg.selectedSegmentTintColor = [UIColor colorWithWhite:0 alpha:0.8];
        seg.layer.borderWidth = 0;
        [seg addTarget:[MPSegBounce shared] action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
        seg.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (seg.backgroundColor && ![seg.backgroundColor isEqual:UIColor.clearColor]) seg.backgroundColor = UIColor.clearColor;
    // UISegmentedControl resets its corners on layout, so this runs every time.
    if (seg.layer.cornerRadius != h / 2) seg.layer.cornerRadius = h / 2;
    if (seg.layer.borderWidth != 0) seg.layer.borderWidth = 0;
    if (!seg.clipsToBounds) seg.clipsToBounds = YES;
    for (UIView *s in seg.subviews) {
        if (![s isKindOfClass:[UIImageView class]]) {
            if (s.backgroundColor && CGColorGetAlpha(s.backgroundColor.CGColor) > 0.01 && ![s isKindOfClass:[UILabel class]]) s.backgroundColor = UIColor.clearColor;
            continue;
        }
        CGRect f = s.frame;
        if (f.size.width <= 2) { if (!s.hidden) s.hidden = YES; continue; }                       // dividers
        if (f.size.width >= seg.bounds.size.width - 4) { if (s.alpha != 0) s.alpha = 0; continue; } // Apple's gray background
        if (!CGAffineTransformIsIdentity(s.transform) && ![s.layer animationForKey:@"wx"]) s.transform = CGAffineTransformIdentity;   // undo 1.0.24
        if (f.size.height > 10) {                                                                // selected pill
            CGFloat bh = s.bounds.size.height;
            if (s.layer.cornerRadius != bh / 2) { s.layer.cornerRadius = bh / 2; s.layer.cornerCurve = kCACornerCurveContinuous; s.clipsToBounds = YES; }
            // Plain dark fill instead of Apple's pill image (its lighter rim showed as gray).
            UIImageView *iv = (UIImageView *)s;
            if (iv.image) iv.image = nil;
            UIColor *fill = [UIColor colorWithWhite:0.02 alpha:0.95];
            if (![iv.backgroundColor isEqual:fill]) iv.backgroundColor = fill;
            if (iv.layer.shadowOpacity != 0) iv.layer.shadowOpacity = 0;
        }
    }
    for (NSUInteger i = 0; i < seg.numberOfSegments; i++)
        if ([[seg titleForSegmentAtIndex:i] isEqualToString:@"Your Library"]) [seg setTitle:@"Library" forSegmentAtIndex:i];
}
static void StyleSearchBar(UISearchBar *sb) {
    static BOOL busy;
    if (busy || !sb.window) return;
    busy = YES;
    @try {
        // Field: Apple's height, as a glass capsule.
        UISearchTextField *tf = sb.searchTextField;
        if (tf.borderStyle != UITextBorderStyleNone) tf.borderStyle = UITextBorderStyleNone;
        if (![tf.backgroundColor isEqual:GlassFill()]) tf.backgroundColor = GlassFill();
        CGFloat h = tf.bounds.size.height;
        if (h > 0 && tf.layer.cornerRadius != h / 2) {
            tf.layer.cornerRadius = h / 2; tf.layer.cornerCurve = kCACornerCurveContinuous; tf.clipsToBounds = YES;
            tf.layer.borderWidth = 0.75; tf.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
        }
        // "Apple Music | Library" scope bar: small glass capsule.
        NSMutableArray *st = [NSMutableArray arrayWithObject:sb];
        int g = 0;
        while (st.count && g++ < 120) {
            UIView *v = st.lastObject; [st removeLastObject];
            if ([v isKindOfClass:[UISegmentedControl class]]) { StyleSegment((UISegmentedControl *)v); continue; }
            [st addObjectsFromArray:v.subviews];
        }
        // Cancel -> round glass X.
        UIButton *cancel = nil;
        @try { cancel = [sb valueForKey:@"cancelButton"]; } @catch (__unused id e) {}
        if ([cancel isKindOfClass:[UIButton class]]) {
            if ([cancel currentTitle].length) [cancel setTitle:@"" forState:UIControlStateNormal];
            if (![cancel imageForState:UIControlStateNormal])
                [cancel setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
            cancel.tintColor = UIColor.whiteColor;
            UIView *disc = [cancel viewWithTag:XDISC_TAG];
            if (!disc) {
                disc = [UIView new];
                disc.tag = XDISC_TAG; disc.userInteractionEnabled = NO;
                disc.backgroundColor = GlassFill();
                disc.layer.borderWidth = 0.75; disc.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
                [cancel insertSubview:disc atIndex:0];
            }
            CGFloat D = 40;
            if (cancel.imageView && !CGAffineTransformIsIdentity(cancel.imageView.transform)) cancel.imageView.transform = CGAffineTransformIdentity;
            CGPoint ic = cancel.imageView ? cancel.imageView.center : CGPointMake(CGRectGetMidX(cancel.bounds), CGRectGetMidY(cancel.bounds));
            CGRect df = CGRectMake(round(ic.x - D / 2), round(ic.y - D / 2), D, D);
            if (!CGRectEqualToRect(disc.frame, df)) { disc.frame = df; disc.layer.cornerRadius = D / 2; }
            [cancel sendSubviewToBack:disc];
            if (cancel.imageView) [cancel bringSubviewToFront:cancel.imageView];
        }
    } @catch (__unused id e) {}
    busy = NO;
}

// Music's account picture (from the Listen Now / Home bar) for the Search title.
static NSString *gAccountDebug = @"";
static UIView *AccountView(UIWindow *w, UIBarButtonItem **outItem) {
    UIViewController *root = w.rootViewController;
    UITabBarController *tbc = nil;
    NSMutableArray *q = [NSMutableArray arrayWithObject:root];
    int g = 0;
    while (q.count && g++ < 50 && !tbc) {
        UIViewController *v = q.firstObject; [q removeObjectAtIndex:0];
        if ([v isKindOfClass:[UITabBarController class]]) { tbc = (UITabBarController *)v; break; }
        [q addObjectsFromArray:v.childViewControllers];
    }
    NSMutableArray *vcs = [NSMutableArray array];
    NSMutableArray *todo = [NSMutableArray arrayWithArray:tbc.viewControllers ?: @[]];
    g = 0;
    while (todo.count && g++ < 200) {
        UIViewController *v = todo.firstObject; [todo removeObjectAtIndex:0];
        [vcs addObject:v];
        [todo addObjectsFromArray:v.childViewControllers];
    }
    NSMutableString *dbg = [NSMutableString string];
    for (UIViewController *v in vcs) {
        UINavigationItem *ni = v.navigationItem;
        UIView *acc = nil;
        for (NSString *k in @[@"_largeTitleAccessoryView", @"largeTitleAccessoryView", @"_largeTitleTrailingAccessoryView"]) {
            @try { id o = [ni valueForKey:k]; if ([o isKindOfClass:[UIView class]]) { acc = o; break; } } @catch (__unused id e) {}
        }
        if (acc) { if (outItem) *outItem = nil; gAccountDebug = [NSString stringWithFormat:@"acc %@", NSStringFromClass([acc class])]; return acc; }
        for (UIBarButtonItem *it in [ni.rightBarButtonItems arrayByAddingObjectsFromArray:ni.leftBarButtonItems ?: @[]]) {
            if (dbg.length < 60) [dbg appendFormat:@"%@ ", it.customView ? NSStringFromClass([it.customView class]) : @"img"];
            if (!it.customView && it.image && it.image.size.width >= 20) {
                if (outItem) *outItem = it;
                gAccountDebug = [NSString stringWithFormat:@"image item in %@", NSStringFromClass([v class])];
                return nil;
            }
            if (it.customView && ([NSStringFromClass([it.customView class]) localizedCaseInsensitiveContainsString:@"account"] || [NSStringFromClass([it.customView class]) localizedCaseInsensitiveContainsString:@"profile"] || [NSStringFromClass([it.customView class]) localizedCaseInsensitiveContainsString:@"avatar"])) {
                if (outItem) *outItem = it;
                gAccountDebug = [NSString stringWithFormat:@"item %@", NSStringFromClass([it.customView class])];
                return it.customView;
            }
        }
    }
    gAccountDebug = [NSString stringWithFormat:@"vcs=%lu items: %@", (unsigned long)vcs.count, dbg];
    return nil;
}
static UIImage *ImageInView(UIView *v) {
    if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image && v.bounds.size.width >= 16) return ((UIImageView *)v).image;
    if ([v isKindOfClass:[UIButton class]] && [(UIButton *)v currentImage]) return [(UIButton *)v currentImage];
    for (UIView *s in v.subviews) { UIImage *i = ImageInView(s); if (i) return i; }
    return nil;
}
@interface MPAvatar : NSObject
+ (instancetype)shared;
@end
static __weak UIBarButtonItem *gAccountItem;
static __weak UIView *gAccountView;
@implementation MPAvatar
+ (instancetype)shared { static MPAvatar *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPAvatar new]; }); return t; }
- (void)tap:(UIButton *)b {
    UIBarButtonItem *it = gAccountItem;
    UIView *cv = it.customView ?: gAccountView;
    UIControl *c = [cv isKindOfClass:[UIControl class]] ? (UIControl *)cv : FirstControl(cv, 0);
    if (c) { Forward(c); return; }
    if (it.target && it.action) { ((void (*)(id, SEL, id))objc_msgSend)(it.target, it.action, it); }
}
@end
#define AVATAR_TAG 0x4D504156
static __weak UIButton *gAvatarBtn;
static void Wobble(UIView *v, CGFloat sx, CGFloat sy, CFTimeInterval delay);
static __weak UIButton *gEditBtn;
static void LiquidPop(UIView *b, BOOL show, CFTimeInterval delay) {
    if (!b) return;
    [b.layer removeAllAnimations];
    UIViewAnimationOptions o = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
    if (!show) {
        // Squash wide, pinch into a drop, vanish upward.
        [UIView animateKeyframesWithDuration:0.36 delay:delay options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.3 animations:^{ b.transform = CGAffineTransformMakeScale(1.18, 0.82); }];
            [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.35 animations:^{ b.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -3), 0.7, 0.95); }];
            [UIView addKeyframeWithRelativeStartTime:0.65 relativeDuration:0.35 animations:^{ b.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -8), 0.12, 0.2); b.alpha = 0; }];
        } completion:nil];
    } else {
        // Drop swells back into the circle and wobbles to rest.
        b.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, -8), 0.15, 0.25);
        [UIView animateWithDuration:0.14 delay:delay options:o animations:^{ b.alpha = 1; } completion:nil];
        [UIView animateWithDuration:0.62 delay:delay usingSpringWithDamping:0.5 initialSpringVelocity:0.9 options:o animations:^{
            b.transform = CGAffineTransformIdentity;
        } completion:nil];
        Wobble(b, 1.12, 0.88, 0.12 + delay);
    }
}
static BOOL RunAction(UIAction *a, id sender);
static __weak UIControl *gEditCtl;
static void Forward(UIControl *c);
static UIControl *HideMusicEdit(UINavigationBar *nb, BOOL *editingOut);
@interface MPEdit : NSObject
+ (instancetype)shared;
@end
static __weak UIBarButtonItem *gEditItem;
@implementation MPEdit
+ (instancetype)shared { static MPEdit *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPEdit new]; }); return t; }
- (void)tap:(UIButton *)b {
    Wobble(b, 1.15, 0.85, 0);
    UIControl *c = gEditCtl;
    if (c) {
        Forward(c);
        UINavigationBar *nb = (UINavigationBar *)b.superview;
        if ([nb isKindOfClass:[UINavigationBar class]]) {
            HideMusicEdit(nb, NULL);
            dispatch_async(dispatch_get_main_queue(), ^{ HideMusicEdit(nb, NULL); });
        }
        return;
    }
    UIBarButtonItem *it = gEditItem;
    if (it.target && it.action) { ((void (*)(id, SEL, id))objc_msgSend)(it.target, it.action, it); return; }
    if (it.primaryAction) { RunAction(it.primaryAction, b); }
}
@end
#define EDIT_TAG 0x4D504544
static char kEditSym;
static void InvisibleBarItem(UIBarButtonItem *it);
static UIControl *HideMusicEdit(UINavigationBar *nb, BOOL *editingOut) {
    UIControl *ctl = nil;
    BOOL editing = NO;
    NSMutableArray *st = [NSMutableArray arrayWithArray:nb.subviews];
    int g = 0;
    while (st.count && g++ < 300) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == EDIT_TAG || v.tag == AVATAR_TAG || [NSStringFromClass([v class]) containsString:@"LargeTitle"]) continue;
        if ([v isKindOfClass:[UIControl class]]) {
            CGRect f = [v convertRect:v.bounds toView:nb];
            if (CGRectGetMidX(f) > nb.bounds.size.width * 0.6 && f.size.width < 120) {
                ctl = (UIControl *)v;
                if (!ctl.layer.mask) ctl.layer.mask = [CALayer layer];
                if (ctl.userInteractionEnabled) ctl.userInteractionEnabled = NO;
                NSMutableArray *s2 = [NSMutableArray arrayWithObject:v];
                int g2 = 0;
                while (s2.count && g2++ < 30) { UIView *x = s2.lastObject; [s2 removeLastObject]; if ([x isKindOfClass:[UILabel class]] && [((UILabel *)x).text isEqualToString:@"Done"]) editing = YES; [s2 addObjectsFromArray:x.subviews]; }
            }
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
    if (editingOut) *editingOut = editing;
    return ctl;
}
static void LibraryEdit(UINavigationBar *nb, CGRect avatarFrame, BOOL avatarHidden, BOOL isLibrary) {
    UIButton *eb = (UIButton *)[nb viewWithTag:EDIT_TAG];
    if (!isLibrary) { eb.hidden = YES; return; }
    for (UIBarButtonItem *it in nb.topItem.rightBarButtonItems) if (!it.customView && ![it.tintColor isEqual:UIColor.clearColor]) InvisibleBarItem(it);
    BOOL editing = NO;
    UIControl *ctl = HideMusicEdit(nb, &editing);
    if (!ctl) { eb.hidden = YES; return; }
    gEditCtl = ctl;
    CGFloat D = avatarFrame.size.width;
    if (!eb) {
        eb = [UIButton buttonWithType:UIButtonTypeCustom];
        eb.tag = EDIT_TAG;
        UIView *disc = [UIView new];
        disc.tag = 1; disc.userInteractionEnabled = NO;
        disc.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.17 alpha:0.94];
        disc.layer.borderWidth = 0.75; disc.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        disc.layer.cornerCurve = kCACornerCurveContinuous;
        [eb addSubview:disc];
        eb.tintColor = UIColor.whiteColor;
        [eb addTarget:[MPEdit shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [nb addSubview:eb];
    }
    NSString *sym = editing ? @"checkmark" : @"checklist";
    if (![objc_getAssociatedObject(eb, &kEditSym) isEqual:sym]) {
        objc_setAssociatedObject(eb, &kEditSym, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightSemibold]] ?: [UIImage systemImageNamed:@"list.bullet"];
        [UIView transitionWithView:eb duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ [eb setImage:img forState:UIControlStateNormal]; } completion:nil];
    }
    UIView *disc = [eb viewWithTag:1];
    if (!CGRectEqualToRect(disc.frame, CGRectMake(0, 0, D, D))) { disc.frame = CGRectMake(0, 0, D, D); disc.layer.cornerRadius = D / 2; }
    CGPoint c = CGPointMake(CGRectGetMinX(avatarFrame) - 10 - D / 2, CGRectGetMidY(avatarFrame));
    if (!CGRectEqualToRect(eb.bounds, CGRectMake(0, 0, D, D)) || !CGPointEqualToPoint(eb.center, c)) { eb.bounds = CGRectMake(0, 0, D, D); eb.center = c; }
    if (eb.imageView) [eb bringSubviewToFront:eb.imageView];
    if (nb.subviews.lastObject != eb) [nb bringSubviewToFront:eb];
    eb.hidden = avatarHidden;
    UIButton *av = gAvatarBtn;
    if (av && !eb.layer.animationKeys.count && fabs(eb.alpha - av.alpha) > 0.01 && !av.layer.animationKeys.count) eb.alpha = av.alpha;
    if (eb.layer.mask) eb.layer.mask = nil;
    if (!eb.userInteractionEnabled) eb.userInteractionEnabled = YES;
    gEditBtn = eb;
}
static void AvatarEval(void) {
    UIButton *b = gAvatarBtn;
    UIScrollView *list = gAvatarList;
    if (!b || !list.window) return;
    BOOL atTop = list.contentOffset.y <= -list.adjustedContentInset.top + 4;
    NSNumber *st = objc_getAssociatedObject(b, &gAvatarList);
    BOOL shown = !st || st.boolValue;
    if (atTop == shown) {
        // Settled but left invisible (an interrupted pop-away): put it back.
        if (shown && !b.layer.animationKeys.count && (b.alpha < 0.99 || !CGAffineTransformIsIdentity(b.transform))) {
            b.alpha = 1; b.transform = CGAffineTransformIdentity;
            UIButton *eb = gEditBtn;
            if (eb && !eb.layer.animationKeys.count) { eb.alpha = 1; eb.transform = CGAffineTransformIdentity; }
        }
        return;
    }
    objc_setAssociatedObject(b, &gAvatarList, @(atTop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    LiquidPop(b, atTop, 0);
    UIButton *eb = gEditBtn;
    if (eb.window && eb.superview == b.superview) LiquidPop(eb, atTop, 0.05);
}
static __weak UISegmentedControl *gScopeSeg;
static __weak UISearchBar *gScopeBar;
static __weak UISearchController *gScopeSC;
static BOOL ViewShowing(UIView *v) {
    for (UIView *p = v; p; p = p.superview) if (p.hidden || p.alpha < 0.05) return NO;
    return v.window != nil && v.bounds.size.height > 4;
}
// Liquid glass (same glass as the bottom bar) that flows between the switch and the field.
static UIView *LiquidBlob(CGRect f, UIView *content) {
    UIView *b = [[UIView alloc] initWithFrame:f];
    b.userInteractionEnabled = NO;
    UIVisualEffectView *g = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
    g.tag = 1; g.frame = b.bounds; g.clipsToBounds = YES;
    g.layer.cornerRadius = MIN(f.size.width, f.size.height) / 2; g.layer.cornerCurve = kCACornerCurveContinuous;
    g.layer.borderWidth = 0.75; g.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    [b addSubview:g];
    if (content) {
        content.tag = 2; content.frame = b.bounds;
        content.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [g.contentView addSubview:content];
    }
    return b;
}
static void LiquidTo(UIView *b, CGRect f) {
    b.bounds = CGRectMake(0, 0, f.size.width, f.size.height);
    b.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
    UIView *g = [b viewWithTag:1];
    g.frame = b.bounds;
    g.layer.cornerRadius = MIN(f.size.width, f.size.height) / 2;
}
static void Wobble(UIView *v, CGFloat sx, CGFloat sy, CFTimeInterval delay) {
    CAKeyframeAnimation *kx = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    kx.values = @[@1, @(sx), @(1 + (1 - sx) * 0.5), @(1 - (1 - sx) * 0.15), @1];
    CAKeyframeAnimation *ky = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    ky.values = @[@1, @(sy), @(1 + (1 - sy) * 0.5), @(1 - (1 - sy) * 0.15), @1];
    for (CAKeyframeAnimation *k in @[kx, ky]) {
        k.keyTimes = @[@0, @0.28, @0.55, @0.8, @1]; k.duration = 0.6;
        k.beginTime = CACurrentMediaTime() + delay;
        k.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    }
    [v.layer addAnimation:kx forKey:@"wx"]; [v.layer addAnimation:ky forKey:@"wy"];
}
static void ScopeEval(BOOL animated) {
    UISegmentedControl *seg = gScopeSeg;
    UIScrollView *list = gScopeList;
    UISearchBar *sb = gScopeBar;
    UIWindow *w = seg.window;
    if (!w || !list.window) return;
    // Only while actually searching (the switch isn't on the plain Search page).
    if (!gScopeSC.isActive) return;
    NSNumber *state = objc_getAssociatedObject(seg, &gScopeSeg);
    BOOL shown = !state || state.boolValue;
    if (shown && !ViewShowing(seg)) return;
    BOOL atTop = list.contentOffset.y <= -list.adjustedContentInset.top + 2;
    if (atTop == shown) return;
    objc_setAssociatedObject(seg, &gScopeSeg, @(atTop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!CGAffineTransformIsIdentity(seg.transform)) seg.transform = CGAffineTransformIdentity;

    static __weak UIView *live;
    [live removeFromSuperview];
    CGRect sf = [seg convertRect:seg.bounds toView:w];
    UISearchTextField *tf = sb.searchTextField;
    CGRect ff = [tf convertRect:tf.bounds toView:w];
    if (!animated) { seg.alpha = atTop ? 1 : 0; return; }
    UIViewAnimationOptions o = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
    // A thin capsule along the bottom of the search field: where the glass merges in.
    CGRect merge = CGRectMake(CGRectGetMidX(ff) - sf.size.width * 0.35, CGRectGetMaxY(ff) - sf.size.height * 0.55, sf.size.width * 0.7, sf.size.height * 0.55);

    if (!atTop) {
        UIView *snap = [seg snapshotViewAfterScreenUpdates:NO];
        UIView *b = LiquidBlob(sf, snap);
        [w addSubview:b];
        live = b;
        seg.alpha = 0;
        // The switch's glass lifts and narrows, flowing up into the field like the bottom bar's squeeze.
        [UIView animateWithDuration:0.16 delay:0 options:o animations:^{ snap.alpha = 0; } completion:nil];
        [UIView animateWithDuration:0.52 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.5 options:o animations:^{
            LiquidTo(b, merge);
        } completion:nil];
        Wobble(b, 0.88, 1.14, 0);
        [UIView animateWithDuration:0.2 delay:0.24 options:o animations:^{ b.alpha = 0; } completion:^(BOOL d) { [b removeFromSuperview]; }];
        Wobble(tf, 1.03, 0.92, 0.2);
    } else {
        UIView *snap = [seg snapshotViewAfterScreenUpdates:YES];
        UIView *b = LiquidBlob(merge, snap);
        snap.alpha = 0;
        b.alpha = 0;
        [w addSubview:b];
        live = b;
        Wobble(tf, 1.03, 0.92, 0);
        [UIView animateWithDuration:0.12 delay:0 options:o animations:^{ b.alpha = 1; } completion:nil];
        // Glass drips out of the field and spreads back into the switch, settling with a wobble.
        [UIView animateWithDuration:0.58 delay:0.02 usingSpringWithDamping:0.68 initialSpringVelocity:0.5 options:o animations:^{
            LiquidTo(b, sf);
        } completion:nil];
        Wobble(b, 1.06, 0.9, 0.1);
        [UIView animateWithDuration:0.2 delay:0.22 options:o animations:^{ snap.alpha = 1; } completion:nil];
        [UIView animateWithDuration:0.18 delay:0.48 options:o animations:^{ seg.alpha = 1; b.alpha = 0; } completion:^(BOOL d) { [b removeFromSuperview]; }];
    }
}
static void ScopeAutoHide(UISearchBar *sb, UINavigationBar *nb) {
    UISegmentedControl *seg = nil;
    NSMutableArray *st = [NSMutableArray arrayWithObject:sb];
    int g = 0;
    while (st.count && g++ < 120 && !seg) {
        UIView *v = st.lastObject; [st removeLastObject];
        if ([v isKindOfClass:[UISegmentedControl class]]) { seg = (UISegmentedControl *)v; break; }
        [st addObjectsFromArray:v.subviews];
    }
    if (!seg.window) return;
    UISearchController *sc = nb.topItem.searchController;
    UIView *page = sc.searchResultsController.view;
    if (!page.window || page.hidden || page.alpha < 0.01) {
        UIResponder *r = nb;
        while (r && ![r isKindOfClass:[UINavigationController class]]) r = r.nextResponder;
        page = ((UINavigationController *)r).topViewController.view;
    }
    UIScrollView *list = nil;
    NSMutableArray *s2 = [NSMutableArray arrayWithObject:page ?: seg.window];
    g = 0;
    while (s2.count && g++ < 400) {
        UIView *v = s2.firstObject; [s2 removeObjectAtIndex:0];
        if (v.hidden || v.alpha < 0.01) continue;
        if ([v isKindOfClass:[UIScrollView class]] && v.bounds.size.height > seg.window.bounds.size.height * 0.4 && ![sb isDescendantOfView:v]) {
            if (!list || v.bounds.size.height * v.bounds.size.width > list.bounds.size.height * list.bounds.size.width) list = (UIScrollView *)v;
            continue;
        }
        [s2 addObjectsFromArray:v.subviews];
    }
    gScopeSeg = seg; gScopeBar = sb; gScopeList = list; gScopeSC = sc;
    ScopeEval(YES);
}

static void SearchPage(UINavigationBar *nb) {
    BOOL isSearch = [nb.topItem.title isEqualToString:@"Search"];
    UISearchBar *bar = nb.topItem.searchController.searchBar;
    if (bar.window) { StyleSearchBar(bar); if (isSearch) ScopeAutoHide(bar, nb); }
    UIView *large = nil;
    for (UIView *s in nb.subviews) if ([NSStringFromClass([s class]) containsString:@"LargeTitle"]) large = s;
    UIView *av = [nb viewWithTag:AVATAR_TAG];
    // The account picture goes on the main page of Search, Library, Radio and Browse.
    NSString *pt = nb.topItem.title;
    UIResponder *nr = nb;
    while (nr && ![nr isKindOfClass:[UINavigationController class]]) nr = nr.nextResponder;
    UINavigationController *nav = (UINavigationController *)nr;
    BOOL avatarPage = pt && [@[@"Search", @"Library", @"Radio", @"Browse"] containsObject:pt] && nav.viewControllers.count <= 1;
    if (!avatarPage) { av.hidden = YES; [nb viewWithTag:0x4D504544].hidden = YES; return; }
    // The page's list (the picture fades as soon as it scrolls).
    {
        NSMutableArray *q = [NSMutableArray arrayWithObject:nav.topViewController.view ?: nb];
        int gq = 0;
        UIScrollView *found = nil;
        while (q.count && gq++ < 300 && !found) {
            UIView *v = q.firstObject; [q removeObjectAtIndex:0];
            if ([v isKindOfClass:[UIScrollView class]] && v.bounds.size.height > 300 && !v.hidden) { found = (UIScrollView *)v; break; }
            [q addObjectsFromArray:v.subviews];
        }
        if (found && gAvatarList != found) gAvatarList = found;
    }
    UILabel *title = nil;
    NSMutableArray *st = [NSMutableArray arrayWithObject:large ?: nb];
    int gd = 0;
    while (st.count && gd++ < 60) {
        UIView *v = st.lastObject; [st removeLastObject];
        if ([v isKindOfClass:[UILabel class]] && [((UILabel *)v).text isEqualToString:pt]) { title = (UILabel *)v; break; }
        [st addObjectsFromArray:v.subviews];
    }
    if (isSearch && title && fabs(title.transform.ty + 10) > 0.5) title.transform = CGAffineTransformMakeTranslation(0, -10);   // Search title a little higher
    // Account picture on the right.
    UIBarButtonItem *it = nil;
    UIView *accView = AccountView(nb.window, &it);
    gAccountItem = it; gAccountView = accView;
    UIImage *img = accView ? ImageInView(accView) : it.image;
    NSString *cache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"musicpill_avatar.png"];
    static UIImage *cached;
    if (img) {
        // Remember it, so it's there right away next launch (Home's page isn't loaded yet then).
        if (img != cached) { cached = img; [UIImagePNGRepresentation(img) writeToFile:cache atomically:YES]; }
    } else {
        if (!cached) cached = [UIImage imageWithContentsOfFile:cache];
        img = cached;
        static BOOL triedLoad;
        if (!triedLoad) {
            triedLoad = YES;
            // Load Home's first page once so Music makes its account button (needed for taps).
            UIViewController *root = nb.window.rootViewController;
            NSMutableArray *q = [NSMutableArray arrayWithObject:root];
            int gq = 0;
            while (q.count && gq++ < 50) {
                UIViewController *v = q.firstObject; [q removeObjectAtIndex:0];
                if ([v isKindOfClass:[UITabBarController class]]) {
                    UIViewController *first = ((UITabBarController *)v).viewControllers.firstObject;
                    if ([first isKindOfClass:[UINavigationController class]]) first = ((UINavigationController *)first).viewControllers.firstObject;
                    @try { [first loadViewIfNeeded]; } @catch (__unused id e) {}
                    break;
                }
                [q addObjectsFromArray:v.childViewControllers];
            }
        }
    }
    if (large && img) {
        // Lives in the bar itself: the big-title strip cut off its top half.
        UIButton *b = (UIButton *)[nb viewWithTag:AVATAR_TAG];
        if (b && b.superview != nb) { [b removeFromSuperview]; b = nil; }
        if (!b) {
            b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.tag = AVATAR_TAG;
            b.clipsToBounds = YES;
            b.layer.borderWidth = 1.5; b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
            b.imageView.contentMode = UIViewContentModeScaleAspectFill;
            [b addTarget:[MPAvatar shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            [nb addSubview:b];
        }
        // The picture is its own image view filling the circle (a button's image view
        // got resized / cleared by UIKit after other pages opened).
        if ([b imageForState:UIControlStateNormal]) [b setImage:nil forState:UIControlStateNormal];
        UIImageView *pic = (UIImageView *)[b viewWithTag:7];
        if (![pic isKindOfClass:[UIImageView class]]) {
            pic = [UIImageView new]; pic.tag = 7; pic.userInteractionEnabled = NO;
            pic.contentMode = UIViewContentModeScaleAspectFill; pic.clipsToBounds = YES;
            [b addSubview:pic];
        }
        if (pic.image != img) pic.image = img;
        CGFloat D = 38;
        // Level with the title's resting spot, same size always (no stretching on pull-down).
        CGRect tf = title ? [title convertRect:title.bounds toView:nb] : [large convertRect:large.bounds toView:nb];
        CGFloat cy = round(CGRectGetMinY(tf) + MIN(tf.size.height, 41) / 2);
        CGRect f = CGRectMake(nb.bounds.size.width - 18 - D, round(cy - D / 2), D, D);
        if (!CGRectEqualToRect(b.bounds, CGRectMake(0, 0, D, D)) || !CGPointEqualToPoint(b.center, CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f)))) {
            b.bounds = CGRectMake(0, 0, D, D); b.center = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f)); b.layer.cornerRadius = D / 2;
        }
        if (!CGRectEqualToRect(pic.frame, b.bounds)) pic.frame = b.bounds;
        // Undo anything that took it for one of Music's buttons (it got masked out).
        if (b.layer.mask) b.layer.mask = nil;
        if (!b.userInteractionEnabled) b.userInteractionEnabled = YES;
        if (pic.hidden || pic.alpha < 1) { pic.hidden = NO; pic.alpha = 1; }
        if (nb.subviews.lastObject != b && b.superview == nb) [nb bringSubviewToFront:b];

        gAvatarBtn = b;
        UISearchController *asc = nb.topItem.searchController;
        CGRect fw = [nb convertRect:f toView:nil];
        b.hidden = large.hidden || large.alpha < 0.5 || asc.isActive || CGRectGetMinY(fw) < nb.window.safeAreaInsets.top;
        @try { LibraryEdit(nb, f, b.hidden, [pt isEqualToString:@"Library"]); } @catch (__unused id e) {}
        // Re-check every tick: opening a page scrolls the list behind the scenes and
        // coming back doesn't always report a scroll, which left the picture popped away.
        if (!b.hidden) { @try { AvatarEval(); } @catch (__unused id e) {} }
    }
    if (!isSearch) {
        UIButton *ab = gAvatarBtn;
        gSearchDebug = [NSString stringWithFormat:@"%@ avatar=%d btn=%d hid=%d a=%.2f t=%.2f pic=%d", pt, img != nil, ab != nil, ab.hidden, ab.alpha, ab.transform.a, ((UIImageView *)[ab viewWithTag:7]).image != nil];
        return;
    }
    // "Browse Categories" goes, category cards get iOS 26 rounding.
    UIResponder *r = nb;
    while (r && ![r isKindOfClass:[UINavigationController class]]) r = r.nextResponder;
    UIView *page = ((UINavigationController *)r).topViewController.view;
    int cards = 0;
    if (page) {
        NSMutableArray *s2 = [NSMutableArray arrayWithObject:page];
        int g2 = 0;
        while (s2.count && g2++ < 2500) {
            UIView *v = s2.lastObject; [s2 removeLastObject];
            if ([v isKindOfClass:[UILabel class]]) {
                if ([((UILabel *)v).text isEqualToString:@"Browse Categories"]) MaskOut(v);
                continue;
            }
            if ([v isKindOfClass:[UICollectionViewCell class]] && v.bounds.size.width > 120 && v.bounds.size.height > 80) {
                UIView *cv = ((UICollectionViewCell *)v).contentView;
                if (cv.layer.cornerRadius != 22) { cv.layer.cornerRadius = 22; cv.layer.cornerCurve = kCACornerCurveContinuous; cv.clipsToBounds = YES; }
                for (UIView *s in cv.subviews) if (s.layer.cornerRadius > 0 && s.layer.cornerRadius < 22) { s.layer.cornerRadius = 22; s.layer.cornerCurve = kCACornerCurveContinuous; }
                cards++;
                continue;
            }
            [s2 addObjectsFromArray:v.subviews];
        }
    }
    gSearchDebug = [NSString stringWithFormat:@"title=%d avatar=%d(%@) cards=%d", title != nil, img != nil, gAccountDebug, cards];
}

static void NavTick(UINavigationBar *nb) {
    if (!nb || !nb.window) return;
    if (!gNavGlass) { RemoveGlass(nb, 0); gNavDebug = @"off"; return; }
    @try { SearchPage(nb); } @catch (__unused id e) {}
    if (![nb.tintColor isEqual:UIColor.whiteColor]) nb.tintColor = UIColor.whiteColor;
    // No gray bar background and no small centered title (e.g. "Library") when
    // scrolled; the big title in the page stays.
    for (UIView *s in nb.subviews) {
        if ([NSStringFromClass([s class]) containsString:@"BarBackground"] && !s.layer.mask) s.layer.mask = [CALayer layer];
    }
    NSString *title = nb.topItem.title;
    if (title.length) {
        NSMutableArray *st = [NSMutableArray arrayWithArray:nb.subviews];
        int gd = 0;
        while (st.count && gd++ < 200) {
            UIView *v = st.lastObject; [st removeLastObject];
            if ([NSStringFromClass([v class]) containsString:@"LargeTitle"]) continue;
            if ([v isKindOfClass:[UILabel class]] && [((UILabel *)v).text isEqualToString:title]) { if (!v.layer.mask) v.layer.mask = [CALayer layer]; continue; }
            [st addObjectsFromArray:v.subviews];
        }
    }

    NSMutableArray *buttons = [NSMutableArray array];
    CollectBarButtons(nb, 0, buttons);
    CGFloat mid = nb.bounds.size.width / 2;
    const CGFloat H = 34;          // iOS 26 top buttons are ~34pt
    const CGFloat edge = 12;       // keep circles off the screen edge
    NSMutableArray *right = [NSMutableArray array];
    for (UIView *b in buttons) {
        ClearCircles(b, 0);
        UIView *g = GlyphIn(b, 0);
        CGRect inNav = [(g ?: b) convertRect:(g ?: b).bounds toView:nb];
        if (CGRectGetMidX(inNav) < mid) {
            if (!g) continue;
            if (gAlbum) {
                // The big floating circle (FloatTick) is the only glass on back.
                for (UIView *s in [g.superview.subviews copy]) if (s.tag == NAVGLASS_TAG) [s removeFromSuperview];
                continue;
            }
            // Nudge the back button right so its circle doesn't hit the edge.
            CGFloat untransformedMid = CGRectGetMidX(inNav) - b.transform.tx;
            CGFloat tx = MAX(0, round(edge + H / 2 - untransformedMid));
            if (b.transform.tx != tx) b.transform = CGAffineTransformMakeTranslation(tx, 0);
            CGRect r = g.frame;
            SetFrameIfNew(GlassBelow(g), CGRectMake(round(CGRectGetMidX(r) - H / 2), round(CGRectGetMidY(r) - H / 2), H, H), H / 2);
        } else {
            [right addObject:b];
        }
    }
    [right sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = CGRectGetMinX([a convertRect:a.bounds toView:nb]), y = CGRectGetMinX([b convertRect:b.bounds toView:nb]);
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    // Leftmost of 2+ right-hand buttons is the add/download/checkmark slot.
    if (right.count >= 2) gSlotView = right.firstObject;
    else if (gSlotView && ![gSlotView isDescendantOfView:nb] && gSlotView.window) {}   // floating album button (FloatTick)
    else gSlotView = nil;
    if (gPortalLive && right.count >= 2) [right removeObjectAtIndex:0]; // shown in the album row instead

    UIView *host = nil, *single = nil;
    if (right.count == 1) { single = GlyphIn(right.firstObject, 0); host = single.superview; }
    else if (right.count > 1) {
        host = [right.firstObject superview];
        for (UIView *b in right) while (host && ![b isDescendantOfView:host]) host = host.superview;
    }
    UIView *old = gRightHost;
    if (old && old != host) for (UIView *s in [old.subviews copy]) if (s.tag == NAVGLASS_TAG) [s removeFromSuperview];
    gRightHost = host;
    if (single) {
        CGRect r = single.frame;
        CGFloat w = MAX(H, r.size.width + 16);
        SetFrameIfNew(GlassBelow(single), CGRectMake(round(CGRectGetMidX(r) - w / 2), round(CGRectGetMidY(r) - H / 2), round(w), H), H / 2);
    } else if (host) {
        CGRect u = CGRectNull;
        for (UIView *b in right) {
            UIView *g = GlyphIn(b, 0) ?: b;
            u = CGRectUnion(u, [g convertRect:g.bounds toView:host]);
        }
        CGFloat w = MAX(H, u.size.width + 28);
        SetFrameIfNew(GlassIn(host), CGRectMake(round(CGRectGetMidX(u) - w / 2), round(CGRectGetMidY(u) - H / 2), round(w), H), H / 2);
    }
    gNavDebug = [NSString stringWithFormat:@"%lu buttons, %lu right, slot=%d", (unsigned long)buttons.count, (unsigned long)right.count, gSlotView != nil];
}

#pragma mark - album page floating buttons

static const void *kFloatGlass = &kFloatGlass;
@interface MPFloatJelly : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
@end
@implementation MPFloatJelly
+ (instancetype)shared { static MPFloatJelly *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPFloatJelly new]; }); return t; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)press:(UILongPressGestureRecognizer *)g {
    UIView *glass = objc_getAssociatedObject(g.view, kFloatGlass);
    if (!glass) return;
    UIViewAnimationOptions o = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    if (g.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:o animations:^{ glass.transform = CGAffineTransformMakeScale(1.18, 1.18); } completion:nil];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [g locationInView:glass];
        CGFloat ox = tanh((p.x - glass.bounds.size.width / 2) / 40) * 7, oy = tanh((p.y - glass.bounds.size.height / 2) / 40) * 7;
        [UIView animateWithDuration:0.18 delay:0 options:o animations:^{
            glass.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(ox, oy), 1.18 + fabs(ox) * 0.01, 1.18 + fabs(oy) * 0.01);
        } completion:nil];
    } else if (g.state >= UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.38 initialSpringVelocity:0.9 options:o animations:^{ glass.transform = CGAffineTransformIdentity; } completion:nil];
    }
}
@end

static void AttachJelly(UIView *c, UIView *glass) {
    objc_setAssociatedObject(c, kFloatGlass, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (objc_getAssociatedObject(c, kSwipeAdded)) return;
    objc_setAssociatedObject(c, kSwipeAdded, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:[MPFloatJelly shared] action:@selector(press:)];
    lp.minimumPressDuration = 0; lp.cancelsTouchesInView = NO; lp.delaysTouchesEnded = NO;
    lp.delegate = [MPFloatJelly shared];
    [c addGestureRecognizer:lp];
}

// Music's own gray circle on a top button goes away; the glyph stays (white).
static const void *kNoEffect = &kNoEffect;
static void StripMusicCircle(UIView *c) {
    ClearCircles(c, 0);
    if (c.backgroundColor && CGColorGetAlpha(c.backgroundColor.CGColor) > 0.01) { objc_setAssociatedObject(c, kClearedBG, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); c.backgroundColor = UIColor.clearColor; }
    NSMutableArray *stack = [NSMutableArray arrayWithArray:c.subviews];
    int guard = 0;
    while (stack.count && guard++ < 200) {
        UIView *s = stack.lastObject; [stack removeLastObject];
        if ([s isKindOfClass:[UIVisualEffectView class]]) {
            UIVisualEffectView *ev = (UIVisualEffectView *)s;
            if (ev.layer.mask) ev.layer.mask = nil;       // 1.0.3 masked it, which hid the glyph inside
            if (ev.effect) { ev.effect = nil; objc_setAssociatedObject(ev, kNoEffect, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        }
        [stack addObjectsFromArray:s.subviews];
    }
    if (!objc_getAssociatedObject(c, kNoEffect)) { objc_setAssociatedObject(c, kNoEffect, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); c.tintColor = UIColor.whiteColor; }
}

static UIView *FloatGlassIn(id owner, UIView *host, UIView *below, const void *key) {
    UIView *g = objc_getAssociatedObject(owner, key);
    if (!g || g.superview != host) {
        [g removeFromSuperview];
        // Same look whatever scrolls under it (a blur turned smeary over artwork).
        UIView *e = [UIView new];
        e.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.17 alpha:0.94];
        e.userInteractionEnabled = NO; e.clipsToBounds = YES;
        e.layer.cornerCurve = kCACornerCurveContinuous;
        e.layer.borderWidth = 0.75; e.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        e.tag = FLOATGLASS_TAG;
        g = e;
        objc_setAssociatedObject(owner, key, g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSUInteger gi = [host.subviews indexOfObject:g], bi = [host.subviews indexOfObject:below];
    if (bi != NSNotFound && (gi == NSNotFound || gi > bi)) [host insertSubview:g belowSubview:below];
    return g;
}

static CGPoint GlyphCenter(UIView *c, UIView *host) {
    UIView *glyph = GlyphIn(c, 0);
    if (glyph) return [glyph convertPoint:CGPointMake(CGRectGetMidX(glyph.bounds), CGRectGetMidY(glyph.bounds)) toView:host];
    return [c.superview convertPoint:c.center toView:host];
}

static void SetGlassFrame(UIView *g, CGRect f) {
    if (CGAffineTransformIsIdentity(g.transform) && !CGRectEqualToRect(g.frame, f)) g.frame = f;
    if (g.layer.cornerRadius != f.size.height / 2) g.layer.cornerRadius = f.size.height / 2;
}

static const void *kBackGlass = &kBackGlass, *kPairGlass = &kPairGlass;
static void GlassCircleFor(UIControl *c, CGFloat D) {
    if (!c || !c.superview) return;
    UIView *host = c.superview;
    UIView *g = FloatGlassIn(c, host, c, kBackGlass);
    AttachJelly(c, g);
    StripMusicCircle(c);
    CGPoint ctr = GlyphCenter(c, host);
    SetGlassFrame(g, CGRectMake(round(ctr.x - D / 2), round(ctr.y - D / 2), D, D));
    g.hidden = c.hidden || c.alpha < 0.01;
}

// Share + ••• share one glass capsule, like iOS 26.
static __weak UIView *gMoreBtn;
// ---- Music's ••• menu, built off-screen so its actions can be run directly ----
static NSString *MenuKind(UIMenuElement *e);
static UIAction *FindKind(NSArray *kids, NSArray *kinds) {
    for (UIMenuElement *e in kids) {
        if ([e isKindOfClass:[UIMenu class]]) { UIAction *a = FindKind(((UIMenu *)e).children, kinds); if (a) return a; continue; }
        if (![e isKindOfClass:[UIAction class]]) continue;
        NSString *k = MenuKind(e);
        if (k && [kinds containsObject:k]) return (UIAction *)e;
        if ([kinds containsObject:@"share"] && [e.title.lowercaseString hasPrefix:@"share"] && ![e.title.lowercaseString containsString:@"shareplay"] && ![e.title.lowercaseString containsString:@"lyric"]) return (UIAction *)e;
    }
    return nil;
}
static UIContextMenuInteraction *MenuInteractionNear(UIView *v) {
    NSMutableArray *stack = [NSMutableArray arrayWithObject:v];
    int guard = 0;
    while (stack.count && guard++ < 60) {
        UIView *s = stack.lastObject; [stack removeLastObject];
        for (id i in s.interactions) if ([i isKindOfClass:[UIContextMenuInteraction class]]) return i;
        [stack addObjectsFromArray:s.subviews];
    }
    for (UIView *p = v.superview; p && guard++ < 70; p = p.superview)
        for (id i in p.interactions) if ([i isKindOfClass:[UIContextMenuInteraction class]] && p.bounds.size.width < 80) return i;
    return nil;
}
static UIMenu *MenuOf(UIView *more, UIContextMenuInteraction **outMi) {
    if (!more) return nil;
    UIMenu *menu = nil;
    UIControl *ctl = [more isKindOfClass:[UIControl class]] ? (UIControl *)more : nil;
    if ([ctl isKindOfClass:[UIButton class]]) menu = ((UIButton *)ctl).menu;
    UIContextMenuInteraction *mi = MenuInteractionNear(more);
    if (outMi) *outMi = mi;
    if (!menu && mi && [mi.delegate respondsToSelector:@selector(contextMenuInteraction:configurationForMenuAtLocation:)]) {
        @try {
            CGPoint loc = [more convertPoint:CGPointMake(CGRectGetMidX(more.bounds), CGRectGetMidY(more.bounds)) toView:mi.view];
            UIContextMenuConfiguration *cfg = [mi.delegate contextMenuInteraction:mi configurationForMenuAtLocation:loc];
            UIContextMenuActionProvider prov = nil;
            @try { prov = [cfg valueForKey:@"actionProvider"]; } @catch (__unused id e) {}
            if (prov) menu = prov(@[]);
        } @catch (__unused id e) {}
    }
    return menu;
}
static BOOL RunAction(UIAction *a, id sender) {
    if (!a) return NO;
    @try {
        SEL perf = NSSelectorFromString(@"performWithSender:target:");
        if ([a respondsToSelector:perf]) { ((void (*)(id, SEL, id, id))objc_msgSend)(a, perf, sender, nil); return YES; }
        void (^h)(UIAction *) = [a valueForKey:@"handler"];
        if (h) { h(a); return YES; }
    } @catch (__unused id e) {}
    return NO;
}
static void OpenMenu(UIView *more, UIContextMenuInteraction *mi) {
    SEL pres = NSSelectorFromString(@"_presentMenuAtLocation:");
    if (mi && [mi respondsToSelector:pres]) {
        CGPoint loc = [more convertPoint:CGPointMake(CGRectGetMidX(more.bounds), CGRectGetMidY(more.bounds)) toView:mi.view];
        ((void (*)(id, SEL, CGPoint))objc_msgSend)(mi, pres, loc);
    } else if ([more isKindOfClass:[UIControl class]]) [(UIControl *)more sendActionsForControlEvents:UIControlEventTouchUpInside];
}

static __weak UIView *gMoreBtn;
static NSString *gShareDebug = @"-";
@interface MPShare : NSObject
+ (instancetype)shared;
- (void)tap:(UIButton *)b;
@end
@implementation MPShare
+ (instancetype)shared { static MPShare *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPShare new]; }); return t; }
- (void)tap:(UIButton *)b {
    UIView *more = gMoreBtn;
    if (!more) { gShareDebug = @"tap, no ••• button"; return; }
    UIContextMenuInteraction *mi = nil;
    UIMenu *menu = MenuOf(more, &mi);
    UIAction *a = FindKind(menu.children, @[@"share"]);
    gShareDebug = [NSString stringWithFormat:@"tap menu=%lu mi=%d share=%@", (unsigned long)menu.children.count, mi != nil, a.title];
    if (RunAction(a, b ?: more)) return;
    OpenMenu(more, mi);   // fallback: the ••• menu (Share is in it)
}
@end

// Moves a Music button sideways so its icon sits at a fixed x on screen. Skipped
// while the page is sliding in or out (big offsets), so pushes still look right.
// Only the icon of a Music button shows (its own gray circle is cut away), so
// moving the icon never leaves Music's circle behind.
static void GlyphOnly(UIView *c) {
    UIView *g = GlyphIn(c, 0);
    if (!g) return;
    CGRect r = CGRectInset([g convertRect:g.bounds toView:c], -8, -8);
    CALayer *m = c.layer.mask;
    if (!m || ![m.name isEqualToString:@"mp.glyphonly"]) {
        m = [CALayer layer];
        m.name = @"mp.glyphonly";
        m.backgroundColor = UIColor.blackColor.CGColor;
        c.layer.mask = m;
    }
    if (!CGRectEqualToRect(m.frame, r)) { [CATransaction begin]; [CATransaction setDisableActions:YES]; m.frame = r; [CATransaction commit]; }
}
#define TOPDY 8.0   // our top buttons sit a bit lower than Music's
static void AlignGlyph(UIView *c, CGFloat targetX, CGFloat scale, CGFloat dy) {
    UIView *g = GlyphIn(c, 0);
    if (!g || !c.window) return;
    CGFloat vis = GlyphCenter(c, nil).x;
    CGFloat untrans = vis - g.transform.tx;
    CGFloat tx = round(targetX - untrans);
    if (fabs(tx) > 45) return;   // page is sliding in/out: leave it
    if (fabs(g.transform.tx - tx) > 0.5 || fabs(g.transform.a - scale) > 0.01 || fabs(g.transform.ty - dy) > 0.5)
        g.transform = CGAffineTransformMake(scale, 0, 0, scale, tx, dy);
}

#define TOPBTN 46.0
#define TOPMARGIN 18.0
#define PAIRW 117.0
static const void *kShareBtn = &kShareBtn;
// Share + ••• share one glass capsule, like iOS 26 (album and artist pages).
@interface MPWeakBox : NSObject
@property (nonatomic, weak) id obj;
@end
@implementation MPWeakBox
@end
static NSHashTable *gShareBtns;   // every share button made (they live outside their page)
static const void *kShareOwner = &kShareOwner;
static void PlaceSharePair(UIView *more) {
    // Share buttons whose page is gone (popped album / artist) go too; they sit in
    // a shared ancestor, so they outlived their page and showed up on Library.
    for (UIButton *sb in [gShareBtns allObjects]) {
        UIView *owner = ((MPWeakBox *)objc_getAssociatedObject(sb, kShareOwner)).obj;
        if (!owner || !owner.window || owner != more) { [sb removeFromSuperview]; [gShareBtns removeObject:sb]; if (owner) objc_setAssociatedObject(owner, kShareBtn, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    }
    static __weak UIView *lastMore;
    UIView *prev = lastMore;
    if (prev && prev != more) {
        [(UIView *)objc_getAssociatedObject(prev, kShareBtn) setHidden:YES];
        [(UIView *)objc_getAssociatedObject(prev, kPairGlass) setHidden:YES];
    }
    lastMore = more;
    if (!more || !more.superview || !more.window) return;
    UIWindow *w = more.window;
    UIView *host = more.superview;
    [(UIView *)objc_getAssociatedObject(more, kBackGlass) setHidden:YES];
    StripMusicCircle(more);
    UIView *dots = GlyphIn(more, 0);
    AlignGlyph(more, w.bounds.size.width - TOPMARGIN - 28, 1.15, TOPDY);
    GlyphOnly(more);

    UIView *g = FloatGlassIn(more, host, more, kPairGlass);
    AttachJelly(more, g);
    (void)dots;
    CGPoint c = GlyphCenter(more, host);
    SetGlassFrame(g, CGRectMake(round(c.x + 28 - PAIRW), round(c.y - TOPBTN / 2), PAIRW, TOPBTN));
    g.hidden = more.hidden;

    // The share button lives in a big ancestor: Music's ••• sits in a tiny view,
    // and a button outside its parent's bounds never gets the tap.
    CGPoint sc = [host convertPoint:CGPointMake(c.x - 61, c.y) toView:nil];
    UIView *bigHost = nil;
    for (UIView *p = host; p && p != w; p = p.superview) {
        CGPoint q = [w convertPoint:sc toView:p];
        if (CGRectContainsRect(p.bounds, CGRectMake(q.x - 22, q.y - 22, 44, 44)) && p.userInteractionEnabled) { bigHost = p; break; }
    }
    if (!bigHost) bigHost = w;
    UIButton *b = objc_getAssociatedObject(more, kShareBtn);
    if (!b || b.superview != bigHost) {
        [b removeFromSuperview];
        b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.tintColor = UIColor.whiteColor; b.tag = SHARE_TAG;
        [b setImage:[UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
        [b addTarget:[MPShare shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(more, kShareBtn, b, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        MPWeakBox *box = [MPWeakBox new]; box.obj = more;
        objc_setAssociatedObject(b, kShareOwner, box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!gShareBtns) gShareBtns = [NSHashTable weakObjectsHashTable];
        [gShareBtns addObject:b];
        AttachJelly(b, g);
    }
    if (bigHost.subviews.lastObject != b) [bigHost addSubview:b];
    CGPoint bc = [w convertPoint:sc toView:bigHost];
    CGRect bf = CGRectMake(round(bc.x - 26), round(bc.y - 23), 52, 46);
    if (!CGRectEqualToRect(b.frame, bf)) b.frame = bf;
    b.hidden = more.hidden;
}

// Music's top download button is hidden for good (still tappable from our row).
static void HideTopDownload(UIView *dl) {
    if (dl && !dl.layer.mask) dl.layer.mask = [CALayer layer];
    if (dl.userInteractionEnabled) dl.userInteractionEnabled = NO;
}

#pragma mark - artist page (iOS 26 look)

#define ARTIST_TAG 0x4D504152
#define CARD_TAG 0x4D504344
#define PLUS_TAG 0x4D50504C
static __weak UIView *gArtistPlay;
static __weak UIView *gArtistPage;
static __weak UIView *gArtistOverlay;   // our header, removed when its page goes away   // play found (even before the name)
static __weak UIView *gArtistStar;   // Music's own favorite star (top right)
static __weak UIView *gArtistName;
static NSString *gArtistNameText;
static NSString *gArtistDebug = @"-";
static NSString *gAddDebug = @"";
static BOOL gArtistFav, gArtistFavKnown;
static CFTimeInterval gArtistFavLock;

static void MaskOut(UIView *v) { if (v && !v.layer.mask) v.layer.mask = [CALayer layer]; }

static BOOL HasText(UIView *v, int depth) {
    if (v.hidden || v.alpha < 0.01) return NO;
    if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) return YES;
    if (depth > 4) return NO;
    for (UIView *s in v.subviews) if (HasText(s, depth + 1)) return YES;
    return NO;
}
static BOOL InTag(UIView *v, NSInteger tag) {
    for (UIView *p = v; p; p = p.superview) if (p.tag == tag) return YES;
    return NO;
}
// Music's round red play button at the bottom right of the artist photo.
static NSString *gArtistWhy;
static BOOL LooksLikeArtistPlay(UIView *b) {
    UIWindow *w = b.window;
    gArtistWhy = nil;
    if (!w || b.hidden) return NO;
    if (![NSStringFromClass([b class]) containsString:@"HeaderPlayButton"]) return NO;
    CGRect f = [b convertRect:b.bounds toView:nil];
    CGFloat W = w.bounds.size.width;
    if (f.size.width < 24 || f.size.width > 72 || f.size.height < 24 || f.size.height > 72) return NO;
    if (CGRectGetMidX(f) < W * 0.6 || CGRectGetMidY(f) < w.safeAreaInsets.top + 100 || CGRectGetMidY(f) > w.bounds.size.height * 0.7) return NO;
    UIView *g = [b isKindOfClass:[UIImageView class]] ? b : GlyphIn(b, 0);
    if (![g isKindOfClass:[UIImageView class]]) return NO;
    NSString *d = ((UIImageView *)g).image.description.lowercaseString;
    if (![d containsString:@"play"] && ![d containsString:@"pause"]) return NO;
    gArtistWhy = [NSString stringWithFormat:@"%@ %.0fx%.0f@%.0f,%.0f", NSStringFromClass([b class]), f.size.width, f.size.height, CGRectGetMidX(f), CGRectGetMidY(f)];
    if (HasText(b, 0)) { gArtistWhy = [gArtistWhy stringByAppendingString:@" text"]; return NO; }
    if (InBottomBars(b) || InTag(b, ROW_TAG) || InTag(b, ARTIST_TAG) || InTag(b, CARD_TAG)) { gArtistWhy = [gArtistWhy stringByAppendingString:@" ours/bars"]; return NO; }
    return YES;
}
static NSString *gNameDebug = @"";
static UILabel *ArtistNameNear(UIView *play) {
    CGRect pf = [play convertRect:play.bounds toView:nil];
    UIView *root = play.superview;
    for (UIView *p = play.superview; p; p = p.superview) { root = p; if ([p isKindOfClass:[UICollectionView class]] || [p isKindOfClass:[UITableView class]]) break; }
    NSMutableArray *stack = [NSMutableArray arrayWithObject:root];
    UILabel *best = nil;
    NSMutableString *dbg = [NSMutableString string];
    int guard = 0;
    while (stack.count && guard++ < 3000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.tag == ARTIST_TAG || v.tag == CARD_TAG || v.tag == PLUS_TAG) continue;
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *l = (UILabel *)v;
            if (!l.text.length || l.hidden) continue;
            CGRect lf = [l convertRect:l.bounds toView:nil];
            if (fabs(CGRectGetMidY(lf) - CGRectGetMidY(pf)) > 90) continue;
            if (dbg.length < 90) [dbg appendFormat:@"'%@'%.0f ", [l.text substringToIndex:MIN(l.text.length, (NSUInteger)10)], l.font.pointSize];
            CGFloat W = play.window.bounds.size.width;
            BOOL onScreen = CGRectGetMinX(lf) >= -1 && CGRectGetMaxX(lf) <= W + 1;
            CGFloat dy = fabs(CGRectGetMidY(lf) - CGRectGetMidY(pf));
            if (onScreen && dy < 45 && (l.font.pointSize >= 24 || lf.size.height >= 30) && CGRectGetMinX(lf) < CGRectGetMinX(pf)) {
                CGFloat bdy = best ? fabs(CGRectGetMidY([best convertRect:best.bounds toView:nil]) - CGRectGetMidY(pf)) : 1e9;
                if (dy < bdy) best = l;
            }
            continue;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    gNameDebug = dbg;
    return best;
}

static NSString *PageTitleOf(UIView *v) {
    UIResponder *r = v;
    while (r && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
    for (UIViewController *vc = (UIViewController *)r; vc; vc = vc.parentViewController) {
        if ([vc isKindOfClass:[UINavigationController class]] || [vc isKindOfClass:[UITabBarController class]]) break;
        NSString *s = vc.navigationItem.title ?: vc.title;
        if (s.length) return s;
    }
    return nil;
}
// The name may be drawn by a non-label view: the widest text-like view level
// with the play button, to the left of it.
static UIView *NameViewNear(UIView *play, NSMutableString *dbg) {
    CGRect pf = [play convertRect:play.bounds toView:nil];
    CGFloat W = play.window.bounds.size.width;
    UIView *a = play;
    for (int i = 0; i < 4 && a.superview; i++) a = a.superview;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:a];
    UIView *best = nil;
    int guard = 0;
    while (stack.count && guard++ < 400) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v == play || v.tag == ARTIST_TAG || v.hidden) continue;
        CGRect f = [v convertRect:v.bounds toView:nil];
        BOOL level = fabs(CGRectGetMidY(f) - CGRectGetMidY(pf)) < 40 && CGRectGetMaxX(f) <= CGRectGetMinX(pf) + 4;
        if (level && f.size.height >= 20 && f.size.height <= 80 && f.size.width >= 40 && f.size.width <= W * 0.8 && ![v isKindOfClass:[UIImageView class]] && v.subviews.count <= 2) {
            if (dbg.length < 80) [dbg appendFormat:@"%@ ", NSStringFromClass([v class])];
            if (!best || f.size.width > best.bounds.size.width) best = v;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    return best;
}

static UIView *GlassDisc(CGFloat D) {
    UIView *e = [UIView new];
    e.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.17 alpha:0.94];
    e.userInteractionEnabled = NO; e.clipsToBounds = YES;
    e.frame = CGRectMake(0, 0, D, D); e.layer.cornerRadius = D / 2;
    e.layer.cornerCurve = kCACornerCurveContinuous;
    e.layer.borderWidth = 0.75; e.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    return e;
}

static void RefreshArtistFav(void) {
    if (CACurrentMediaTime() < gArtistFavLock) return;
    UIAction *a = FindKind(MenuOf(gMoreBtn, NULL).children, @[@"love", @"unlove"]);
    if (!a) { gArtistFavKnown = NO; return; }
    gArtistFavKnown = YES;
    gArtistFav = [MenuKind(a) isEqualToString:@"unlove"];
}

static void SetStar(UIButton *star, BOOL on, BOOL animated) {
    UIImage *img = [UIImage systemImageNamed:on ? @"star.fill" : @"star" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightSemibold]];
    NSNumber *cur = objc_getAssociatedObject(star, kNoEffect);
    if (cur && cur.boolValue == on) return;
    objc_setAssociatedObject(star, kNoEffect, @(on), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [star setImage:img forState:UIControlStateNormal];
    if (!animated) return;
    // Pop + spring back, and a little burst of sparks when it turns on.
    star.imageView.transform = CGAffineTransformMakeScale(0.45, 0.45);
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.42 initialSpringVelocity:1.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        star.imageView.transform = CGAffineTransformIdentity;
    } completion:nil];
    if (!on) return;
    CGPoint c = CGPointMake(star.bounds.size.width / 2, star.bounds.size.height / 2);
    UIView *ring = [[UIView alloc] initWithFrame:CGRectMake(c.x - 20, c.y - 20, 40, 40)];
    ring.userInteractionEnabled = NO; ring.layer.cornerRadius = 20;
    ring.layer.borderWidth = 2; ring.layer.borderColor = (star.tintColor ?: UIColor.whiteColor).CGColor;
    [star addSubview:ring];
    ring.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ ring.transform = CGAffineTransformMakeScale(1.6, 1.6); ring.alpha = 0; } completion:^(BOOL f) { [ring removeFromSuperview]; }];
    for (int i = 0; i < 8; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(c.x - 2.5, c.y - 2.5, 5, 5)];
        dot.userInteractionEnabled = NO; dot.layer.cornerRadius = 2.5; dot.backgroundColor = star.tintColor ?: UIColor.whiteColor;
        [star addSubview:dot];
        CGFloat ang = i * M_PI / 4 + M_PI / 8;
        [UIView animateWithDuration:0.55 delay:0.04 options:UIViewAnimationOptionCurveEaseOut animations:^{
            dot.center = CGPointMake(c.x + cos(ang) * 38, c.y + sin(ang) * 38);
            dot.transform = CGAffineTransformMakeScale(0.3, 0.3); dot.alpha = 0;
        } completion:^(BOOL f) { [dot removeFromSuperview]; }];
    }
}

@interface MPArtist : NSObject
+ (instancetype)shared;
@end
@implementation MPArtist
+ (instancetype)shared { static MPArtist *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPArtist new]; }); return t; }
- (void)play:(UIButton *)b {
    UIView *p = gArtistPlay;
    UIControl *c = [p isKindOfClass:[UIControl class]] ? (UIControl *)p : FirstControl(p, 0);
    Forward(c);
    b.transform = CGAffineTransformMakeScale(0.88, 0.88);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:1 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
}
- (void)star:(UIButton *)b {
    UIView *ms = gArtistStar;
    if (ms.window) {
        // Music's own favorite star from the top bar (hidden there, used from here).
        UIControl *c = [ms isKindOfClass:[UIControl class]] ? (UIControl *)ms : FirstControl(ms, 0);
        Forward(c);
        gArtistFav = !gArtistFav; gArtistFavKnown = YES;
        gArtistFavLock = CACurrentMediaTime() + 1.5;
        SetStar(b, gArtistFav, YES);
        return;
    }
    UIView *more = gMoreBtn;
    UIContextMenuInteraction *mi = nil;
    UIAction *a = FindKind(MenuOf(more, &mi).children, @[@"love", @"unlove"]);
    if (!a) { gArtistDebug = @"no Favorite in the ••• menu"; OpenMenu(more, mi); return; }
    BOOL willBeFav = ![MenuKind(a) isEqualToString:@"unlove"];
    RunAction(a, b);
    gArtistFav = willBeFav; gArtistFavKnown = YES;
    gArtistFavLock = CACurrentMediaTime() + 1.5;
    SetStar(b, willBeFav, YES);
}
@end

// Builds / updates our header over Music's (name centered, play big and white,
// favorite star). Safe to call from Music's layout pass.
static BOOL InPageList(UIView *v) {
    // The page's header play button, not the small copy Music shows in the top bar.
    for (UIView *p = v.superview; p; p = p.superview) if ([p isKindOfClass:[UINavigationBar class]]) return NO;
    UIWindow *w = v.window;
    CGRect f = [v convertRect:v.bounds toView:nil];
    if (CGRectGetMidY(f) < w.safeAreaInsets.top + 80) return v == gArtistPlay;   // scrolled up: keep the one we have
    return YES;
}
// Music's own name text anywhere on screen (e.g. a big title label), so it can be hidden.
static void HideNameCopies(UIWindow *w, NSString *name) {
    if (!name.length) return;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w];
    int guard = 0;
    while (stack.count && guard++ < 5000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.tag == ARTIST_TAG || v.tag == COLLAPSE_TAG || v.tag == DEBUG_TAG || [v isKindOfClass:[UITabBar class]] || [v isKindOfClass:NSClassFromString(@"MPMiniPill")]) continue;
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *l = (UILabel *)v;
            NSString *lt = l.text ?: l.attributedText.string;
            BOOL big = l.font.pointSize >= 24 || l.bounds.size.height >= 30;
            if (big && [lt caseInsensitiveCompare:name] == NSOrderedSame) MaskOut(l);
            continue;
        }
        [stack addObjectsFromArray:v.subviews];
    }
}
static NSString *gSideDebug = @"";
static void HideTextLayers(CALayer *l, int depth) {
    if (depth > 6) return;
    for (CALayer *s in l.sublayers) {
        if ([s isKindOfClass:[CATextLayer class]] && !s.hidden) s.hidden = YES;
        HideTextLayers(s, depth + 1);
    }
}
static void HideSideName(UIView *play) {
    UIWindow *w = play.window;
    if (!w) return;
    CGRect pf = [play convertRect:play.bounds toView:nil];
    // Points across where Music draws the name (left part, level with its play button).
    CGFloat ys[] = { CGRectGetMidY(pf), CGRectGetMidY(pf) - 10, CGRectGetMidY(pf) + 10 };
    CGFloat xs[] = { 40, 80, 120 };
    UIView *top = play;
    for (int i = 0; i < 6 && top.superview; i++) top = top.superview;
    NSMutableString *dbg = [NSMutableString string];
    for (int yi = 0; yi < 3; yi++) for (int xi = 0; xi < 3; xi++) {
        CGPoint pt = CGPointMake(xs[xi], ys[yi]);
        // deepest view containing the point (not ours, not images, not big)
        UIView *v = top, *deep = nil;
        BOOL moved = YES;
        int guard = 0;
        while (moved && guard++ < 30) {
            moved = NO;
            for (UIView *s in [v.subviews reverseObjectEnumerator]) {
                if (s.hidden || s.alpha < 0.01 || s.tag == ARTIST_TAG || s.tag == CARD_TAG) continue;
                CGRect f = [s convertRect:s.bounds toView:nil];
                if (!CGRectContainsPoint(f, pt)) continue;
                v = s; moved = YES;
                if (![s isKindOfClass:[UIImageView class]] && f.size.height <= 100 && ![play isDescendantOfView:s]) deep = s;
                break;
            }
        }
        if (deep && !deep.layer.mask) {
            if (dbg.length < 120) [dbg appendFormat:@"%@ ", NSStringFromClass([deep class])];
            deep.layer.mask = [CALayer layer];
        }
        HideTextLayers(v.layer, 0);
    }
    if (dbg.length) gSideDebug = dbg;
}
static void ArtistTick(UIView *play) {
    if (!play.window || !InPageList(play)) return;
    {
        NSNumber *t0 = objc_getAssociatedObject(play, &gAddDebug);
        if (!t0 || CACurrentMediaTime() - t0.doubleValue <= 1.5) MaskOut(play);   // hidden before it's drawn
    }
    UIView *name = gArtistName;
    NSString *nameText = gArtistNameText;
    if (!name || !name.window || ![name isDescendantOfView:play.window]) {
        UILabel *l = ArtistNameNear(play);
        if (l) { name = l; nameText = l.text; }
        else {
            nameText = PageTitleOf(play);
            NSMutableString *nd = [NSMutableString string];
            name = nameText ? NameViewNear(play, nd) : nil;
            gNameDebug = [gNameDebug stringByAppendingFormat:@" title=%@ view=%@", nameText, nd];
            if (!name && nameText) name = play;   // no separate view: just use the title
        }
    }
    if ([name isKindOfClass:[UILabel class]] && ((UILabel *)name).text.length) nameText = ((UILabel *)name).text;
    if (!nameText.length) name = nil;
    gArtistPage = play;
    if (!name) {
        // Hidden early; if it turns out there's no artist name here, show it again.
        NSNumber *t0 = objc_getAssociatedObject(play, &gAddDebug);
        if (!t0) objc_setAssociatedObject(play, &gAddDebug, @(CACurrentMediaTime()), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        else if (CACurrentMediaTime() - t0.doubleValue > 1.5 && play.layer.mask) play.layer.mask = nil; gArtistDebug = [NSString stringWithFormat:@"play=%@ (no name) near: %@", gArtistWhy ?: NSStringFromClass([play class]), gNameDebug]; return; }
    // Our header lives in the page's own header cell, so it leaves with the page.
    UIView *container = nil;
    for (UIView *p = play.superview; p; p = p.superview) if ([p isKindOfClass:[UICollectionReusableView class]]) { container = p; break; }
    if (!container) {
        container = CommonParent(play, name);
        while (container.superview && container.bounds.size.width < play.window.bounds.size.width * 0.9 && ![container.superview isKindOfClass:[UIScrollView class]]) container = container.superview;
    }
    if (!container) return;
    if (gArtistPlay != play || ![gArtistNameText isEqualToString:nameText]) {
        // A new artist header: drop overlays left from another one.
        UIView *old = gArtistPlay;
        for (UIView *p = old.superview; p; p = p.superview) for (UIView *s in [p.subviews copy]) if (s.tag == ARTIST_TAG && old != play) [s removeFromSuperview];
    }
    gArtistPlay = play; gArtistName = name; gArtistNameText = nameText;
    if (play.userInteractionEnabled) play.userInteractionEnabled = NO;   // taps there went to Music's radio play
    HideSideName(play);
    {
        static CFTimeInterval lastHide;
        if (CACurrentMediaTime() - lastHide > 0.3) { lastHide = CACurrentMediaTime(); HideNameCopies(play.window, nameText); }
    }
    MaskOut(play); MaskOut(name);

    MPPassHost *ov = nil;
    for (UIView *s in container.subviews) if (s.tag == ARTIST_TAG) ov = (MPPassHost *)s;
    const CGFloat OH = 260, PD = 78, SD = 52;
    if (!ov) {
        ov = [MPPassHost new];
        ov.tag = ARTIST_TAG;
        CAGradientLayer *gl = [CAGradientLayer layer];
        gl.name = @"mp.fade";
        gl.colors = @[(id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.55].CGColor, (id)[UIColor colorWithWhite:0 alpha:1].CGColor];
        gl.locations = @[@0, @(0.45 * OH / (OH + 8)), @(OH / (OH + 8))];
        [ov.layer addSublayer:gl];
        UILabel *l = [UILabel new];
        l.tag = 1; l.textAlignment = NSTextAlignmentCenter; l.textColor = UIColor.whiteColor;
        l.font = [UIFont systemFontOfSize:44 weight:UIFontWeightBold];
        l.adjustsFontSizeToFitWidth = YES; l.minimumScaleFactor = 0.5;
        [ov addSubview:l];
        UIButton *pb = [UIButton buttonWithType:UIButtonTypeCustom];
        pb.tag = 3; pb.backgroundColor = UIColor.whiteColor; pb.tintColor = UIColor.blackColor;
        pb.layer.cornerRadius = PD / 2;
        [pb setImage:[[UIImage systemImageNamed:@"play.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightBold]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        pb.imageEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        [pb addTarget:[MPArtist shared] action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
        [ov addSubview:pb];
        UIButton *st = [UIButton buttonWithType:UIButtonTypeCustom];
        st.tag = 4; st.tintColor = UIColor.whiteColor;
        [st addSubview:GlassDisc(SD)];
        [st addTarget:[MPArtist shared] action:@selector(star:) forControlEvents:UIControlEventTouchUpInside];
        [ov addSubview:st];
        [container addSubview:ov];
        SetStar(st, NO, NO);
    }
    if (gArtistOverlay && gArtistOverlay != ov) [gArtistOverlay removeFromSuperview];
    gArtistOverlay = ov;
    if (container.subviews.lastObject != ov) [container bringSubviewToFront:ov];
    CGRect pf = [play convertRect:play.bounds toView:container], lf = [name convertRect:name.bounds toView:container];
    CGFloat bottom = MAX(CGRectGetMaxY(pf), CGRectGetMaxY(lf)) + 12, W = container.bounds.size.width;
    // Run to the very bottom of Music's header cell, so no strip of photo shows under it.
    if ([container isKindOfClass:[UICollectionReusableView class]] && container.bounds.size.height - bottom < 60 && container.bounds.size.height > bottom) bottom = container.bounds.size.height;
    CGRect of = CGRectMake(0, bottom - OH, W, OH + 8);   // 8pt solid past the fade covers the photo's last line
    // Artists without a photo have a short header: our name would end up under the
    // top buttons. Push the page down (once, at rest) so there's room above it.
    {
        UIScrollView *cv = nil;
        for (UIView *p = container.superview; p; p = p.superview) if ([p isKindOfClass:[UIScrollView class]]) { cv = (UIScrollView *)p; break; }
        UIWindow *win = play.window;
        BOOL atRest = cv && fabs(cv.contentOffset.y + cv.adjustedContentInset.top) < 2 && !cv.isTracking && !cv.isDecelerating;
        if (cv && atRest && !objc_getAssociatedObject(cv, &gArtistOverlay)) {
            objc_setAssociatedObject(cv, &gArtistOverlay, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CGFloat nameTop = [container convertPoint:CGPointMake(0, bottom - OH + (OH - 14 - PD) - 66) toView:win].y;
            CGFloat want = win.safeAreaInsets.top + 70;
            if (nameTop < want) {
                UIResponder *r = cv;
                while (r && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
                UIViewController *vc = (UIViewController *)r;
                if (vc) {
                    UIEdgeInsets add = vc.additionalSafeAreaInsets;
                    add.top += round(want - nameTop);
                    vc.additionalSafeAreaInsets = add;
                }
                if (container.clipsToBounds) container.clipsToBounds = NO;
            }
        }
    }
    if (!CGRectEqualToRect(ov.frame, of)) {
        ov.frame = of;
        for (CALayer *l in ov.layer.sublayers) if ([l.name isEqualToString:@"mp.fade"]) { [CATransaction begin]; [CATransaction setDisableActions:YES]; l.frame = ov.bounds; [CATransaction commit]; }
        CGFloat rowY = OH - 14 - PD / 2;
        [ov viewWithTag:1].frame = CGRectMake(20, rowY - PD / 2 - 66, W - 40, 54);
        [ov viewWithTag:3].frame = CGRectMake(W / 2 - PD / 2, rowY - PD / 2, PD, PD);
        [ov viewWithTag:4].frame = CGRectMake(W / 2 + 91 - SD / 2, rowY - SD / 2, SD, SD);
    }
    UILabel *l = (UILabel *)[ov viewWithTag:1];
    if (![l.text isEqualToString:nameText]) l.text = nameText;
    UIButton *pb = (UIButton *)[ov viewWithTag:3];
    UIView *g = GlyphIn(play, 0);
    BOOL pausing = [g isKindOfClass:[UIImageView class]] && [((UIImageView *)g).image.description containsString:@"pause"];
    NSString *ps = pausing ? @"pause.fill" : @"play.fill";
    if (![objc_getAssociatedObject(pb, kNoEffect) isEqual:ps]) {
        objc_setAssociatedObject(pb, kNoEffect, ps, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [pb setImage:[[UIImage systemImageNamed:ps withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightBold]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        pb.imageEdgeInsets = UIEdgeInsetsMake(0, pausing ? 0 : 4, 0, 0);
    }
    UIView *ms = gArtistStar;
    if (ms.window) {
        UIView *sg = GlyphIn(ms, 0);
        if ([sg isKindOfClass:[UIImageView class]]) {
            NSString *sd = ((UIImageView *)sg).image.description;
            gArtistFavKnown = YES;
            if (CACurrentMediaTime() > gArtistFavLock) gArtistFav = [sd containsString:@"star"] && [sd containsString:@".fill"];
        }
    }
    if (gArtistFavKnown && CACurrentMediaTime() > gArtistFavLock) SetStar((UIButton *)[ov viewWithTag:4], gArtistFav, NO);
    UIButton *stb = (UIButton *)[ov viewWithTag:4];
    if (stb.imageView && stb.subviews.lastObject != stb.imageView) [stb bringSubviewToFront:stb.imageView];
    gArtistDebug = [NSString stringWithFormat:@"ok name='%@' side=%@ fav=%d/%d%@", nameText, gSideDebug, gArtistFavKnown, gArtistFav, gAddDebug];
}

// Latest release: a rounded card, and a round + instead of "+ Add".
@interface MPArtistAdd : NSObject
+ (instancetype)shared;
@end
static const void *kAddCtl = &kAddCtl;
@implementation MPArtistAdd
+ (instancetype)shared { static MPArtistAdd *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPArtistAdd new]; }); return t; }
- (void)tap:(UIButton *)b {
    UIControl *c = objc_getAssociatedObject(b, kAddCtl);
    if (!c) return;
    BOOL adding = [objc_getAssociatedObject(b, kNoEffect) isEqual:@"plus"];
    Forward(c);
    if (adding) {
        ShowToast(nil, @"checkmark", @"Added to Library");
        objc_setAssociatedObject(b, kClearedBG, @(CACurrentMediaTime() + 4), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
@end
static NSString *ControlText(UIView *v) {
    NSMutableArray *stack = [NSMutableArray arrayWithObject:v];
    int guard = 0;
    while (stack.count && guard++ < 40) {
        UIView *s = stack.lastObject; [stack removeLastObject];
        if ([s isKindOfClass:[UILabel class]] && ((UILabel *)s).text.length) return ((UILabel *)s).text;
        [stack addObjectsFromArray:s.subviews];
    }
    return nil;
}
static void SetPlusSymbol(UIButton *b, NSString *sym) {
    if ([objc_getAssociatedObject(b, kNoEffect) isEqual:sym]) return;
    BOOL had = objc_getAssociatedObject(b, kNoEffect) != nil;
    objc_setAssociatedObject(b, kNoEffect, sym, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *img = [UIImage systemImageNamed:sym withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold]];
    if (!had) { [b setImage:img forState:UIControlStateNormal]; return; }
    [UIView animateWithDuration:0.12 animations:^{ b.transform = CGAffineTransformMakeScale(0.8, 0.8); } completion:^(BOOL f) {
        [UIView transitionWithView:b duration:0.22 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ [b setImage:img forState:UIControlStateNormal]; } completion:nil];
        [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.8 options:UIViewAnimationOptionAllowUserInteraction animations:^{ b.transform = CGAffineTransformIdentity; } completion:nil];
    }];
}
static void ArtistAddTick(UIView *root) {
    int seenAdd = 0, withCtl = 0;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:root];
    NSMutableSet *live = [NSMutableSet set];
    int guard = 0;
    while (stack.count && guard++ < 3000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.tag == ARTIST_TAG || v.tag == PLUS_TAG || v.tag == CARD_TAG) continue;
        if ([v isKindOfClass:[UILabel class]]) {
            NSString *tx = ((UILabel *)v).text;
            if (!([tx isEqualToString:@"Add"] || [tx isEqualToString:@"Added"])) continue;
            seenAdd++;
            UIControl *c = ControlAbove(v);
            if (c) withCtl++;
            UIView *cell = nil;
            for (UIView *p = c.superview; p; p = p.superview) if ([p isKindOfClass:[UICollectionViewCell class]]) { cell = p; break; }
            if (!c || !cell) continue;
            UIView *cv = ((UICollectionViewCell *)cell).contentView;
            [live addObject:[NSValue valueWithNonretainedObject:cv]];
            MaskOut(c);
            // Artwork = the biggest image in the cell.
            UIImageView *art = nil; CGFloat best = 0;
            NSMutableArray *st2 = [NSMutableArray arrayWithObject:cv];
            int g2 = 0;
            while (st2.count && g2++ < 200) {
                UIView *s = st2.lastObject; [st2 removeLastObject];
                if (s.tag == PLUS_TAG || s.tag == CARD_TAG) continue;
                if ([s isKindOfClass:[UIImageView class]]) {
                    CGFloat a = s.bounds.size.width * s.bounds.size.height;
                    if (a > best) { best = a; art = (UIImageView *)s; }
                }
                [st2 addObjectsFromArray:s.subviews];
            }
            UIView *card = [cv viewWithTag:CARD_TAG];
            UIButton *plus = (UIButton *)[cv viewWithTag:PLUS_TAG];
            if (!card) {
                card = [UIView new];
                card.tag = CARD_TAG; card.userInteractionEnabled = NO;
                card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
                card.layer.cornerRadius = 28; card.layer.cornerCurve = kCACornerCurveContinuous;
                card.layer.borderWidth = 0.75; card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.09].CGColor;
                [cv insertSubview:card atIndex:0];
            }
            if (!plus) {
                plus = [UIButton buttonWithType:UIButtonTypeCustom];
                plus.tag = PLUS_TAG; plus.tintColor = UIColor.whiteColor;
                UIView *disc = GlassDisc(44);
                [plus addSubview:disc];
                [plus addTarget:[MPArtistAdd shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
                [cv addSubview:plus];
            }
            objc_setAssociatedObject(plus, kAddCtl, c, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CGRect af = art ? [art convertRect:art.bounds toView:cv] : CGRectInset(cv.bounds, 10, 10);
            CGFloat pad = 10, W = cv.bounds.size.width;
            CGFloat cardX = MAX(4, CGRectGetMinX(af) - pad);
            CGRect cf = CGRectMake(cardX, CGRectGetMinY(af) - pad, W - 2 * cardX, af.size.height + 2 * pad);
            if (!CGRectEqualToRect(card.frame, cf)) card.frame = cf;
            if (art && art.layer.cornerRadius < 13) { art.layer.cornerRadius = 14; art.layer.cornerCurve = kCACornerCurveContinuous; art.clipsToBounds = YES; }
            CGRect pf = CGRectMake(CGRectGetMaxX(cf) - 39 - 22, CGRectGetMidY(cf) - 22, 44, 44);
            if (!CGRectEqualToRect(plus.frame, pf)) plus.frame = pf;
            [cv bringSubviewToFront:plus];
            if (plus.imageView && plus.subviews.lastObject != plus.imageView) [plus bringSubviewToFront:plus.imageView];
            NSNumber *pending = objc_getAssociatedObject(plus, kClearedBG);
            BOOL added = ![ControlText(c) isEqualToString:@"Add"] || (pending && CACurrentMediaTime() < pending.doubleValue);
            SetPlusSymbol(plus, added ? @"checkmark" : @"plus");
            continue;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    gAddDebug = [NSString stringWithFormat:@" add=%d/%d", seenAdd, withCtl];
}

static void ArtistScan(UIWindow *w) {
    UIView *play = gArtistPlay ?: gArtistPage;
    if (play && play.window == w) { ArtistTick(play); }
    else {
        // The artist page is gone (back, or another tab): take our header with it.
        UIView *ov = gArtistOverlay;
        if (ov) { [ov removeFromSuperview]; gArtistOverlay = nil; }
        static CFTimeInterval last;
        if (CACurrentMediaTime() - last < 0.25) return;
        last = CACurrentMediaTime();
        gArtistPlay = nil;
        NSMutableArray *stack = [NSMutableArray arrayWithObject:w];
        int guard = 0;
        UIView *found = nil;
        NSMutableString *seen = [NSMutableString string];
        while (stack.count && guard++ < 6000 && !found) {
            UIView *v = stack.lastObject; [stack removeLastObject];
            if (v.hidden || v.alpha < 0.01 || [v isKindOfClass:[UITabBar class]] || v.tag == COLLAPSE_TAG || v.tag == ARTIST_TAG) continue;
            BOOL tappable = [v isKindOfClass:[UIControl class]] || v.gestureRecognizers.count;
            BOOL looks = v.bounds.size.width >= 24 && v.bounds.size.width <= 72 && LooksLikeArtistPlay(v);
            if (looks && !tappable) gArtistWhy = [gArtistWhy stringByAppendingString:@" notap"];
            if (tappable && looks) {
                ArtistTick(v);
                if (gArtistPlay == v) { found = v; break; }
                continue;
            }
            if (gArtistWhy && seen.length < 160) { [seen appendFormat:@"[%@] ", gArtistWhy]; gArtistWhy = nil; }
            [stack addObjectsFromArray:v.subviews];
        }
        if (!found) { if (![gArtistDebug containsString:@"no name"]) gArtistDebug = [NSString stringWithFormat:@"none %@", seen]; return; }
    }
    UIView *root = gArtistPlay;
    for (UIView *p = root; p; p = p.superview) if ([p isKindOfClass:[UICollectionView class]]) { root = p; break; }
    if (root && root != gArtistPlay) ArtistAddTick(root);
}

static BOOL IsMusicRed(UIColor *c);
// Album page: red labels / buttons (artist name, "Show Complete Album") -> white.
static NSString *gRedDebug = @"-";
static void RedToWhite(UIView *rowParent) {

    UIView *root = rowParent;
    for (UIView *p = rowParent; p; p = p.superview) if ([p isKindOfClass:[UIScrollView class]]) { root = p; break; }
    if (!objc_getAssociatedObject(root, kNoEffect)) { objc_setAssociatedObject(root, kNoEffect, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); root.tintColor = UIColor.whiteColor; }
    int labels = 0;
    NSMutableString *redOther = [NSMutableString string];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:root];
    int guard = 0;
    while (stack.count && guard++ < 4000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.hidden) continue;
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *l = (UILabel *)v;
            labels++;
            if ([l.text containsString:@"Complete"]) {
                CGFloat r = 0, g = 0, b = 0, a = 0;
                [[l.textColor resolvedColorWithTraitCollection:l.traitCollection] getRed:&r green:&g blue:&b alpha:&a];
                gRedDebug = [NSString stringWithFormat:@"%@ rgb=%.2f,%.2f,%.2f %@", NSStringFromClass([l class]), r, g, b, NSStringFromClass([l.superview class])];
            }
            if (IsMusicRed(l.textColor)) l.textColor = UIColor.whiteColor;
            NSAttributedString *as = l.attributedText;
            if (as.length) {
                __block BOOL red = NO;
                [as enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, as.length) options:0 usingBlock:^(id val, NSRange rg, BOOL *stop) { if ([val isKindOfClass:[UIColor class]] && IsMusicRed(val)) { red = YES; *stop = YES; } }];
                if (red) {
                    NSMutableAttributedString *m = [as mutableCopy];
                    [m addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, m.length)];
                    l.attributedText = m;
                }
            }
            continue;
        }
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *bt = (UIButton *)v;
            if (IsMusicRed(bt.tintColor) && bt.titleLabel.text.length) bt.tintColor = UIColor.whiteColor;
            if (IsMusicRed([bt titleColorForState:UIControlStateNormal])) [bt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            UIButtonConfiguration *cfg = nil;
            if ([bt respondsToSelector:@selector(configuration)]) cfg = bt.configuration;
            if (cfg && IsMusicRed(cfg.baseForegroundColor)) { cfg.baseForegroundColor = UIColor.whiteColor; bt.configuration = cfg; }
        }
        if (redOther.length < 120 && ![v isKindOfClass:[UIImageView class]] && IsMusicRed(v.tintColor) && v.subviews.count == 0) [redOther appendFormat:@"%@ ", NSStringFromClass([v class])];
        [stack addObjectsFromArray:v.subviews];
    }
    if (![gRedDebug containsString:@"rgb"] || redOther.length)
        gRedDebug = [NSString stringWithFormat:@"%@ root=%@ labels=%d redviews=%@", [gRedDebug containsString:@"rgb"] ? gRedDebug : @"", NSStringFromClass([root class]), labels, redOther];
}

// Our own back button: Music's is hidden (its look changed while scrolling and
// its icon vanished), ours pops the page.
static const void *kOurBack = &kOurBack;
@interface MPBack : NSObject
+ (instancetype)shared;
@end
@implementation MPBack
+ (instancetype)shared { static MPBack *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPBack new]; }); return t; }
- (void)tap:(UIButton *)b {
    UIView *music = objc_getAssociatedObject(b, kOurBack);
    UIResponder *r = music;
    while (r && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
    UINavigationController *nav = [(UIViewController *)r navigationController];
    if ([r isKindOfClass:[UINavigationController class]]) nav = (UINavigationController *)r;
    if (nav.viewControllers.count > 1) { [nav popViewControllerAnimated:YES]; return; }
    UIControl *c = [music isKindOfClass:[UIControl class]] ? (UIControl *)music : FirstControl(music, 0);
    Forward(c);
}
@end
#define BACK_TAG 0x4D504241
static __weak UIButton *gLastBack;
static void PlaceBack(UIView *back, UIWindow *w) {
    UIView *g = GlyphIn(back, 0);
    if (g && !CGAffineTransformIsIdentity(g.transform)) g.transform = CGAffineTransformIdentity;
    if (!CGAffineTransformIsIdentity(back.transform)) back.transform = CGAffineTransformIdentity;
    CGPoint gc = GlyphCenter(back, nil);
    CGPoint want = CGPointMake(TOPMARGIN + TOPBTN / 2, gc.y + TOPDY);
    if (fabs(gc.x - 30) > 50) return;   // page sliding in / out
    UIView *host = nil;
    for (UIView *p = back.superview; p && p != w; p = p.superview) {
        CGPoint q = [w convertPoint:want toView:p];
        if (CGRectContainsRect(p.bounds, CGRectMake(q.x - TOPBTN / 2, q.y - TOPBTN / 2, TOPBTN, TOPBTN)) && p.userInteractionEnabled) { host = p; break; }
    }
    if (!host) host = w;
    UIButton *b = objc_getAssociatedObject(back, kOurBack);
    if (!b || b.superview != host) {
        [b removeFromSuperview];
        b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = BACK_TAG;
        UIView *disc = [UIView new];
        disc.userInteractionEnabled = NO;
        disc.frame = CGRectMake(0, 0, TOPBTN, TOPBTN); disc.layer.cornerRadius = TOPBTN / 2;
        disc.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.17 alpha:0.94];
        disc.layer.borderWidth = 0.75; disc.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        [b addSubview:disc];
        UIImageView *ch = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.backward" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold]]];
        ch.tintColor = UIColor.whiteColor; ch.contentMode = UIViewContentModeCenter;
        ch.frame = CGRectMake(-1, 0, TOPBTN, TOPBTN); ch.userInteractionEnabled = NO;
        [b addSubview:ch];
        objc_setAssociatedObject(b, kOurBack, back, OBJC_ASSOCIATION_ASSIGN);
        [b addTarget:[MPBack shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        AttachJelly(b, disc);
        objc_setAssociatedObject(back, kOurBack, b, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [host addSubview:b];
    }
    objc_setAssociatedObject(b, kOurBack, back, OBJC_ASSOCIATION_ASSIGN);
    if (host.subviews.lastObject != b) [host bringSubviewToFront:b];
    CGPoint q = [w convertPoint:want toView:host];
    CGRect bf = CGRectMake(round(q.x - TOPBTN / 2), round(q.y - TOPBTN / 2), TOPBTN, TOPBTN);
    if (!CGRectEqualToRect(b.frame, bf)) b.frame = bf;
    if (!back.layer.mask || [back.layer.mask.name isEqualToString:@"mp.glyphonly"]) back.layer.mask = [CALayer layer];
    [(UIView *)objc_getAssociatedObject(back, kFloatGlass) setHidden:YES];
    [(UIView *)objc_getAssociatedObject(back, kBackGlass) setHidden:YES];
    if (gLastBack && gLastBack != b) gLastBack.hidden = YES;
    gLastBack = b;
    b.hidden = back.hidden;
}

// A soft blur behind the status bar, always there (not while the player is up).
#define STATUSBLUR_TAG 0x4D505342
static void StatusBlur(UIWindow *w) {
    UIVisualEffectView *v = (UIVisualEffectView *)[w viewWithTag:STATUSBLUR_TAG];
    BOOL show = !PlayerIsUp(w, NULL) && w.safeAreaInsets.top > 0;
    if (!show) { v.hidden = YES; return; }
    CGFloat H = w.safeAreaInsets.top + 14;
    if (!v) {
        v = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        v.tag = STATUSBLUR_TAG; v.userInteractionEnabled = NO;
        CAGradientLayer *m = [CAGradientLayer layer];
        m.colors = @[(id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
        m.locations = @[@0, @0.6, @1];
        v.layer.mask = m;
        [w addSubview:v];
    }
    v.hidden = NO;
    if (v.alpha != 0.7) v.alpha = 0.7;
    CGRect f = CGRectMake(0, 0, w.bounds.size.width, H);
    if (!CGRectEqualToRect(v.frame, f)) { v.frame = f; v.layer.mask.frame = v.bounds; }
    UIView *dbg = [w viewWithTag:DEBUG_TAG];
    if (dbg) [w insertSubview:v belowSubview:dbg]; else if (w.subviews.lastObject != v) [w bringSubviewToFront:v];
}

// ---- Animated album cover in the full player (iOS 26) ----
// Music only plays motion covers on album pages. When one is showing, we keep its
// video player; when the full player opens on a song from that album, the same
// video plays on the player's artwork (looping, muted).
#define MOTION_TAG 0x4D504D4F
static __weak AVPlayer *gMotionPlayer;
static __weak UIView *gMotionPage;
static NSString *gMotionDebug = @"-";
static NSMutableString *gVideoSeen;
static NSString *PageTitleOf(UIView *v);
// Text a view shows: a label's text, its VoiceOver label, or (for Music's own
// text-drawing views) the string it keeps inside.
static NSString *DrawnText(UIView *v) {
    if ([v isKindOfClass:[UILabel class]]) return ((UILabel *)v).text ?: ((UILabel *)v).attributedText.string;
    if (v.accessibilityLabel.length) return v.accessibilityLabel;
    if (![NSStringFromClass([v class]) containsString:@"TextDrawing"]) return nil;
    for (Class c = [v class]; c && c != [UIView class]; c = class_getSuperclass(c)) {
        unsigned n = 0;
        Ivar *iv = class_copyIvarList(c, &n);
        for (unsigned i = 0; i < n; i++) {
            const char *enc = ivar_getTypeEncoding(iv[i]);
            if (!enc || enc[0] != '@') continue;
            id o = nil;
            @try { o = object_getIvar(v, iv[i]); } @catch (__unused id e) {}
            NSString *s = [o isKindOfClass:[NSAttributedString class]] ? ((NSAttributedString *)o).string : ([o isKindOfClass:[NSString class]] ? o : nil);
            if (s.length) { free(iv); return s; }
        }
        free(iv);
    }
    for (NSString *k in @[@"attributedText", @"text", @"string"]) {
        id o = nil;
        @try { o = [v valueForKey:k]; } @catch (__unused id e) {}
        if ([o isKindOfClass:[NSAttributedString class]]) return ((NSAttributedString *)o).string;
        if ([o isKindOfClass:[NSString class]] && [o length]) return o;
    }
    return nil;
}
static BOOL PageHasLabel(UIView *page, NSString *text) {
    if (!text.length) return NO;
    NSString *pt = PageTitleOf(page);
    if (pt.length && [pt caseInsensitiveCompare:text] == NSOrderedSame) return YES;
    NSString *t1 = text.lowercaseString;
    for (NSString *suf in @[@" - single", @" - ep"]) if ([t1 hasSuffix:suf]) t1 = [t1 substringToIndex:t1.length - suf.length];
    NSMutableArray *st = [NSMutableArray arrayWithObject:page];
    int g = 0;
    while (st.count && g++ < 1500) {
        UIView *v = st.lastObject; [st removeLastObject];
        NSString *l = DrawnText(v);
        if (l.length) {
            l = l.lowercaseString;
            for (NSString *suf in @[@" - single", @" - ep"]) if ([l hasSuffix:suf]) l = [l substringToIndex:l.length - suf.length];
            if ([l isEqualToString:t1] || [l hasPrefix:[t1 stringByAppendingString:@","]]) return YES;
        }
        if ([v isKindOfClass:[UILabel class]]) continue;
        [st addObjectsFromArray:v.subviews];
    }
    return NO;
}
static NSMapTable *gMotionByAlbum;   // album title -> its cover video player
static NSMapTable *gMotionTexts;     // cover video player -> every text on its album page
static NSString *AlbumKey(NSString *s) {
    s = s.lowercaseString;
    for (NSString *suf in @[@" - single", @" - ep"]) if ([s hasSuffix:suf]) s = [s substringToIndex:s.length - suf.length];
    return s;
}
static NSString *PageTitleOf(UIView *v);
static void MotionTick(UIWindow *w) {
    // 1. On an album page with a motion cover: remember its player.
    UIView *rp = gRowParent;
    static NSString *videoDebug = @"";
    if (rp.window == w) {
        // The whole album page (its view controller's view): the cover video sits
        // behind the list, not inside it.
        UIResponder *r = rp;
        while (r && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
        UIView *page = ((UIViewController *)r).view ?: rp;
        static CFTimeInterval lastScan;
        if (CACurrentMediaTime() - lastScan > 0.5) {
            lastScan = CACurrentMediaTime();
            gVideoSeen = [NSMutableString string];
            // The cover video: a big player layer above the album's Play row (not a
            // music-video tile or anything else further down the page).
            CGFloat rowTop = [rp convertPoint:CGPointZero toView:nil].y;
            NSMutableArray *ls = [NSMutableArray arrayWithObject:page.layer];
            AVPlayerLayer *pick = nil;
            int g = 0;
            while (ls.count && g++ < 3000) {
                CALayer *l = ls.lastObject; [ls removeLastObject];
                if ([l isKindOfClass:[AVPlayerLayer class]] && ((AVPlayerLayer *)l).player && !l.hidden) {
                    CGRect f = [l convertRect:l.bounds toLayer:w.layer];
                    if (f.size.width >= w.bounds.size.width * 0.6 && CGRectGetMinY(f) < rowTop) { pick = (AVPlayerLayer *)l; break; }
                    if (gVideoSeen.length < 120) [gVideoSeen appendFormat:@"skip%.0fx%.0f@%.0f ", f.size.width, f.size.height, f.origin.y];
                }
                [ls addObjectsFromArray:l.sublayers ?: @[]];
            }
            if (pick.player) {
                gMotionPlayer = pick.player; gMotionPage = page;
                // Remembered per album (every text in the header above the Play row, as
                // Music draws the title without a label), so the player finds it later.
                if (!gMotionByAlbum) gMotionByAlbum = [NSMapTable strongToWeakObjectsMapTable];
                NSMutableArray *keys = [NSMutableArray array];
                NSString *pt = PageTitleOf(rp);
                if (pt.length) [keys addObject:pt];
                NSMutableArray *vs = [NSMutableArray arrayWithObject:page];
                int gv = 0;
                while (vs.count && gv++ < 1500 && keys.count < 12) {
                    UIView *v = vs.lastObject; [vs removeLastObject];
                    if (v.hidden) continue;
                    CGRect vf = [v convertRect:v.bounds toView:nil];
                    if (CGRectGetMinY(vf) > rowTop) continue;
                    NSString *s = DrawnText(v);
                    if (s.length > 1 && s.length < 120) { [keys addObject:s]; continue; }
                    [vs addObjectsFromArray:v.subviews];
                }
                for (NSString *k in keys) [gMotionByAlbum setObject:pick.player forKey:AlbumKey(k)];
                // Plus every text on the page (song list): the playing song's title is
                // there even when the album title can't be read.
                NSMutableSet *all = [NSMutableSet set];
                NSMutableArray *as = [NSMutableArray arrayWithObject:page];
                int ga = 0;
                while (as.count && ga++ < 3000) {
                    UIView *v = as.lastObject; [as removeLastObject];
                    NSString *s = DrawnText(v);
                    if (s.length > 1 && s.length < 160) [all addObject:AlbumKey(s)];
                    [as addObjectsFromArray:v.subviews];
                }
                if (!gMotionTexts) gMotionTexts = [NSMapTable weakToStrongObjectsMapTable];
                NSMutableSet *old = [gMotionTexts objectForKey:pick.player];
                if (old) [all unionSet:old];
                [gMotionTexts setObject:all forKey:pick.player];
                [gVideoSeen appendFormat:@"cover keys=%@", [keys componentsJoinedByString:@"/"]];
            }
            videoDebug = [gVideoSeen copy];
        }
    }
    // 2. Full player up: put the video on its artwork when the album matches.
    UIView *pv = nil;
    BOOL up = PlayerIsUp(w, &pv);
    UIView *art = nil;
    NSMutableString *cands = [NSMutableString string];
    if (up) {
        // The artwork: the biggest square-ish view showing a picture (an image view,
        // or a view whose layer holds the image).
        CGFloat best = 0;
        NSMutableArray *st = [NSMutableArray arrayWithObject:pv];
        int g = 0;
        while (st.count && g++ < 900) {
            UIView *v = st.lastObject; [st removeLastObject];
            if (v.hidden || v.alpha < 0.01 || v.tag == MOTION_TAG || v.tag == PLAYERDEBUG_TAG) continue;
            CGSize s = v.bounds.size;
            BOOL square = s.width > w.bounds.size.width * 0.3 && fabs(s.width - s.height) < 12;
            BOOL pic = ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image) || v.layer.contents != nil || [NSStringFromClass([v class]) containsString:@"Artwork"];
            if (square && cands.length < 140) [cands appendFormat:@"%@%@ %.0f ", NSStringFromClass([v class]), pic ? @"*" : @"", s.width];
            if (square && pic && s.width * s.height >= best) { best = s.width * s.height; art = v; }
            [st addObjectsFromArray:v.subviews];
        }
    }
    static __weak UIView *shown;
    AVPlayer *mp = gMotionPlayer;
    // This album's own cover video (by title), else the last page's if it matches.
    AVPlayer *byTitle = nil;
    for (NSString *k in gMotionByAlbum.keyEnumerator.allObjects) if ([AlbumKey(k) isEqualToString:AlbumKey(gNowAlbum ?: @"")]) { byTitle = [gMotionByAlbum objectForKey:k]; break; }
    if (!byTitle) {
        NSString *song = AlbumKey(gNowTitle ?: @""), *alb = AlbumKey(gNowAlbum ?: @"");
        for (AVPlayer *p in gMotionTexts.keyEnumerator.allObjects) {
            NSSet *tx = [gMotionTexts objectForKey:p];
            if ((alb.length && [tx containsObject:alb]) || (song.length && [tx containsObject:song])) { byTitle = p; break; }
        }
    }
    if (byTitle) mp = byTitle;
    BOOL match = up && art && mp && (byTitle || (gMotionPage && PageHasLabel(gMotionPage, gNowAlbum)));
    if (match && objc_getAssociatedObject(art, &gMotionByAlbum) != mp) {
        // A different song's video was showing: swap it.
        [[art viewWithTag:MOTION_TAG] removeFromSuperview];
        objc_setAssociatedObject(art, &gMotionByAlbum, mp, OBJC_ASSOCIATION_ASSIGN);
    }
    if (!match) {
        [shown removeFromSuperview];
        gMotionDebug = [NSString stringWithFormat:@"player=%d art=%d video=%d album=%@ page=%d match=%d seen=%@ cands=%@", up, art != nil, mp != nil, gNowAlbum, gMotionPage != nil, gMotionPage ? PageHasLabel(gMotionPage, gNowAlbum) : 0, videoDebug, cands];
        return;
    }
    UIView *mv = [art viewWithTag:MOTION_TAG];
    if (!mv) {
        [shown removeFromSuperview];
        mv = [[UIView alloc] initWithFrame:art.bounds];
        mv.tag = MOTION_TAG; mv.userInteractionEnabled = NO; mv.clipsToBounds = YES;
        mv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        AVPlayerLayer *l = [AVPlayerLayer playerLayerWithPlayer:mp];
        l.videoGravity = AVLayerVideoGravityResizeAspectFill;
        l.name = @"mp.motion";
        [mv.layer addSublayer:l];
        [art addSubview:mv];
        shown = mv;
    }
    CGFloat r = MAX(art.layer.cornerRadius, art.superview.layer.cornerRadius);
    if (mv.layer.cornerRadius != r) { mv.layer.cornerRadius = r; mv.layer.cornerCurve = kCACornerCurveContinuous; }
    for (CALayer *l in mv.layer.sublayers) if ([l.name isEqualToString:@"mp.motion"] && !CGRectEqualToRect(l.frame, mv.bounds)) {
        [CATransaction begin]; [CATransaction setDisableActions:YES]; l.frame = mv.bounds; [CATransaction commit];
    }
    // Keep it moving: muted, and looped from the start when it ends.
    if (!mp.muted) mp.muted = YES;
    if (mp.rate == 0 && mp.currentItem) {
        if (CMTimeCompare(mp.currentTime, mp.currentItem.duration) >= 0 || mp.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            if (CMTIME_IS_NUMERIC(mp.currentItem.duration) && CMTimeCompare(mp.currentTime, mp.currentItem.duration) >= 0) [mp seekToTime:kCMTimeZero];
            [mp play];
        }
    }
    gMotionDebug = [NSString stringWithFormat:@"showing on %@ rate=%.1f", NSStringFromClass([art class]), mp.rate];
}

static void FloatTick(UIWindow *w) {
    @try { MotionTick(w); } @catch (__unused id e) {}
    if (PlayerIsUp(w, NULL)) return;   // the player's ••• is not a page button
    if (!w || !gNavGlass) return;
    CGFloat top = w.safeAreaInsets.top, band = top + 80, W = w.bounds.size.width;
    // Icons in the top band (any view), then the small square-ish view holding each.
    NSMutableArray *found = [NSMutableArray array];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w];
    int guard = 0;
    while (stack.count && guard++ < 8000) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v.hidden || v.alpha < 0.01 || [v isKindOfClass:[UITabBar class]] || v.tag == COLLAPSE_TAG || v.tag == DEBUG_TAG || v.tag == NAVGLASS_TAG || v.tag == SHARE_TAG || v.tag == FLOATGLASS_TAG || v.tag == 0x4D504156 || v.tag == 0x4D504544 || v.tag == BACK_TAG) continue;
        CGRect f = [v convertRect:v.bounds toView:nil];
        if (f.origin.y > band || CGRectGetMaxY(f) < top - 20) continue;
        if ([v isKindOfClass:[UIImageView class]] && ((UIImageView *)v).image && f.size.width <= 40 && f.size.height <= 40 && CGRectGetMidY(f) < band && CGRectGetMidY(f) > top - 10) {
            [found addObject:v];
            continue;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    UIView *back = nil, *more = nil, *dl = nil;
    NSMutableArray *dbg = [NSMutableArray array];
    for (UIImageView *iv in found) {
        UIView *holder = iv;
        for (UIView *p = iv.superview; p && p != w; p = p.superview) {
            CGSize z = p.bounds.size;
            if (z.width > 70 || z.height > 70) break;
            holder = p;
            if ([p isKindOfClass:[UIControl class]]) break;
        }
        BOOL inList = NO;
        for (UIView *p = holder; p && p != w; p = p.superview) if ([p isKindOfClass:[UIScrollView class]]) { inList = YES; break; }
        if (inList) continue;
        NSString *d = iv.image.description.lowercaseString;
        NSString *sym = @"?";
        NSRange r = [d rangeOfString:@"symbol("];
        if (r.location != NSNotFound) { NSString *rest = [d substringFromIndex:r.location]; sym = [rest substringToIndex:MIN(rest.length, (NSUInteger)40)]; }
        CGFloat x = CGRectGetMidX([iv convertRect:iv.bounds toView:nil]);
        if (dbg.count < 4) [dbg addObject:[NSString stringWithFormat:@"%@@%.0f(%@)", sym, x, NSStringFromClass([holder class])]];
        if ([d containsString:@"ellipsis"]) more = holder;
        else if (([d containsString:@"chevron.left"] || [d containsString:@"chevron.backward"]) && x < W / 3) back = holder;
        else if (x > W / 2) dl = holder;   // download in any state: arrow, progress (stop), checkmark
    }
    if (back) PlaceBack(back, w);
    else gLastBack.hidden = YES;
    StatusBlur(w);
    // Mid-download Music swaps in a progress view with no image; keep the last one we caught.
    if (!dl && gSlotView && gSlotView.window == w) {
        CGRect sf = [gSlotView convertRect:gSlotView.bounds toView:nil];
        if (CGRectGetMidY(sf) < band && CGRectGetMidX(sf) > W / 2) dl = gSlotView;
    }
    gMoreBtn = more;
    BOOL album = gRowParent && gRowParent.window == w;
    if (dl && album) { gSlotView = dl; HideTopDownload(dl); }
    @try { ArtistScan(w); } @catch (__unused id e) {}
    BOOL artist = (gArtistPlay && gArtistPlay.window == w) || (gArtistPage && gArtistPage.window == w);
    if (artist && dl) { UIView *sg = GlyphIn(dl, 0); if ([sg isKindOfClass:[UIImageView class]] && [((UIImageView *)sg).image.description containsString:@"star"]) { gArtistStar = dl; HideTopDownload(dl); } }
    PlaceSharePair(album || artist ? more : nil);
    static __weak UIView *favMore;
    if (artist && more && more != favMore) { favMore = more; @try { RefreshArtistFav(); } @catch (__unused id e) {} }
    if (!album && !artist && more) GlassCircleFor((UIControl *)more, TOPBTN);
    if (gRowParent && gRowParent.window == w) RedToWhite(gRowParent);
    gFloatDebug = [NSString stringWithFormat:@"motion: %@ | search: %@ | artist: %@ | share: %@ | red: %@ | %lu icons back=%@ more=%@ dl=%@ | %@", gMotionDebug, gSearchDebug, gArtistDebug, gShareDebug, gRedDebug, (unsigned long)found.count, NSStringFromClass([back class]), NSStringFromClass([more class]), NSStringFromClass([dl class]), [dbg componentsJoinedByString:@" "]];
}

// Music's top buttons (Swift SymbolButton): when the download one changes state
// it's a fresh view; pick it up right away so the row circle keeps mirroring it.
static IMP gSymLayoutOrig;
static void SymLayoutHook(UIView *self, SEL _cmd) {
    if (gSymLayoutOrig) ((void (*)(id, SEL))gSymLayoutOrig)(self, _cmd);
    static BOOL busy;
    if (busy || !gAlbum) return;
    @try {
        UIWindow *w = self.window;
        if (!w) return;
        CGRect f = [self convertRect:self.bounds toView:nil];
        if (CGRectGetMidY(f) > w.safeAreaInsets.top + 80) {
            if (LooksLikeArtistPlay(self)) { busy = YES; @try { ArtistTick(self); } @catch (__unused id e) {} busy = NO; }
            return;
        }
        if (CGRectGetMidX(f) < w.bounds.size.width / 2) return;
        UIView *g = GlyphIn(self, 0);
        BOOL more = [((UIImageView *)g).image.description containsString:@"ellipsis"];
        // Done right here, inside Music's own layout pass, so Apple's version is
        // never put on screen, not even for one frame.
        if (more) StripMusicCircle(self);
        else {
            if (!self.layer.mask) self.layer.mask = [CALayer layer];
            self.userInteractionEnabled = NO;   // taps go to our share button
            if (self == gSlotView && gRowParent.window == w) return;
            gSlotView = self;
        }
        // The rest waits for the next run-loop turn (once), so moving our views
        // can never re-trigger this layout in a loop.
        static BOOL queued;
        if (!queued) {
            queued = YES;
            __weak UIWindow *ww = w;
            dispatch_async(dispatch_get_main_queue(), ^{
                queued = NO;
                UIWindow *win = ww;
                if (!win) return;
                busy = YES;
                @try { AlbumTick(win); FloatTick(win); } @catch (__unused id e) {}
                busy = NO;
            });
        }
    } @catch (__unused id e) { busy = NO; }
}
static IMP gHeadPlayLayoutOrig;
static void HeadPlayLayoutHook(UIView *self, SEL _cmd) {
    if (gHeadPlayLayoutOrig) ((void (*)(id, SEL))gHeadPlayLayoutOrig)(self, _cmd);
    static BOOL busy;
    if (busy) return;
    busy = YES;
    @try {
        if (self.window && !InBottomBars(self)) {
            // Its class alone says "artist header": hide it before it's ever drawn.
            ArtistTick(self);
        }
    } @catch (__unused id e) {}
    busy = NO;
}
static IMP gHeadPlayWinOrig;
static void HeadPlayWinHook(UIView *self, SEL _cmd) {
    if (gHeadPlayWinOrig) ((void (*)(id, SEL))gHeadPlayWinOrig)(self, _cmd);
    @try { if (self.window && !InBottomBars(self)) ArtistTick(self); } @catch (__unused id e) {}
}
static void HookSymbolButton(void) {
    Class hp = objc_getClass("MusicPageHeaderPlayButton") ?: objc_getClass("MusicApplication.MusicPageHeaderPlayButton");
    if (hp) MSHookMessageEx(hp, @selector(layoutSubviews), (IMP)HeadPlayLayoutHook, &gHeadPlayLayoutOrig);
    if (hp) MSHookMessageEx(hp, @selector(didMoveToWindow), (IMP)HeadPlayWinHook, &gHeadPlayWinOrig);
    Class sym = objc_getClass("MusicApplication.SymbolButton");
    if (sym) MSHookMessageEx(sym, @selector(layoutSubviews), (IMP)SymLayoutHook, &gSymLayoutOrig);
}

static UINavigationBar *TopNavBar(UIWindow *w) {
    UIViewController *vc = w.rootViewController;
    while (vc.presentedViewController && !vc.presentedViewController.isBeingDismissed) vc = vc.presentedViewController;
    if ([vc isKindOfClass:[UITabBarController class]]) vc = ((UITabBarController *)vc).selectedViewController;
    if ([vc isKindOfClass:[UINavigationController class]]) return ((UINavigationController *)vc).navigationBar;
    return vc.navigationController.navigationBar;
}

// Opening and closing the full player resets the bar without laying out the
// tab bar again, so nothing re-shrank it. Check a few times a second (cheap:
// it only compares a transform) and re-apply once the bar is settled.
#pragma mark - iOS 26 queue pill row

static __weak UIControl *gQShuffle, *gQRepeat, *gQAuto;
static __weak UIScrollView *gQueueTable;

static UIView *FindQueueHeader(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden) continue;
        if ([NSStringFromClass([s class]) containsString:@"NowPlayingQueueHeaderView"]) return s;
        if (depth < 22) { UIView *f = FindQueueHeader(s, depth + 1); if (f) return f; }
    }
    return nil;
}

static void CollectControls(UIView *v, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if ([s isKindOfClass:[UIControl class]]) { [out addObject:s]; continue; }
        if (depth < 8) CollectControls(s, depth + 1, out);
    }
}

// A header button is "on" if it's selected or has a filled background (Music
// draws active toggles with a red rounded square behind the icon).
static BOOL ToggleOn(UIControl *c) {
    if (!c) return NO;
    if (c.isSelected) return YES;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:c];
    int n = 0;
    while (stack.count && n++ < 40) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if (v != c && v.backgroundColor && CGColorGetAlpha(v.backgroundColor.CGColor) > 0.3 &&
            v.bounds.size.width >= c.bounds.size.width * 0.7) return YES;
        [stack addObjectsFromArray:v.subviews];
    }
    return NO;
}

static void StyleQueuePill(UIButton *b, NSString *symbol, BOOL on) {
    UIButtonConfiguration *cfg = b.configuration ?: [UIButtonConfiguration filledButtonConfiguration];
    UIColor *bg = on ? [UIColor colorWithWhite:0.56 alpha:1] : [UIColor colorWithWhite:0.17 alpha:1];
    UIColor *fg = on ? UIColor.blackColor : UIColor.whiteColor;
    if ([cfg.baseBackgroundColor isEqual:bg] && [cfg.baseForegroundColor isEqual:fg] &&
        [objc_getAssociatedObject(b, kQueueTable) isEqual:symbol]) return;
    cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    cfg.baseBackgroundColor = bg;
    cfg.baseForegroundColor = fg;
    cfg.image = [UIImage systemImageNamed:symbol withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold]];
    cfg.contentInsets = NSDirectionalEdgeInsetsZero;
    b.configuration = cfg;
    objc_setAssociatedObject(b, kQueueTable, symbol, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Repeat One: Music's repeat button switches to the "repeat.1" symbol.
static BOOL ImageIsRepeatOne(UIImage *img) {
    return img && [img.description containsString:@"repeat.1"];
}
static BOOL RepeatOneOn(UIControl *c) {
    if (!c) return NO;
    if ([c isKindOfClass:[UIButton class]] && ImageIsRepeatOne(((UIButton *)c).currentImage)) return YES;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:c];
    int n = 0;
    while (stack.count && n++ < 40) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:[UIImageView class]] && ImageIsRepeatOne(((UIImageView *)v).image)) return YES;
        [stack addObjectsFromArray:v.subviews];
    }
    NSString *val = c.accessibilityValue.lowercaseString;
    if ([val containsString:@"one"] || [val containsString:@"song"] || [val containsString:@"1"]) return YES;
    return [MPMusicPlayerController systemMusicPlayer].repeatMode == MPMusicRepeatModeOne;
}

static const void *kQueueRowObj = &kQueueRowObj;
static UIView *QueueRowOf(UIScrollView *list) { return objc_getAssociatedObject(list, kQueueRowObj); }
static void RefreshQueueRow(void) {
    UIScrollView *table = gQueueTable;
    UIView *row = QueueRowOf(table);
    if (!row) return;
    BOOL repeatOne = RepeatOneOn(gQRepeat);
    StyleQueuePill([row viewWithTag:11], @"shuffle", ToggleOn(gQShuffle));
    StyleQueuePill([row viewWithTag:12], repeatOne ? @"repeat.1" : @"repeat", repeatOne || ToggleOn(gQRepeat));
    StyleQueuePill([row viewWithTag:13], @"infinity", ToggleOn(gQAuto));
    [row viewWithTag:13].hidden = gQAuto == nil;
}

@interface MPQueueTarget : NSObject
+ (instancetype)shared;
@end
@implementation MPQueueTarget
+ (instancetype)shared { static MPQueueTarget *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPQueueTarget new]; }); return t; }
- (void)tap:(UIButton *)b {
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    UIControl *c = b.tag == 11 ? gQShuffle : (b.tag == 12 ? gQRepeat : gQAuto);
    Forward(c);
    // Music updates its button a moment later; mirror it quickly.
    dispatch_async(dispatch_get_main_queue(), ^{ RefreshQueueRow(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RefreshQueueRow(); });
}
@end

static __weak UIView *gQueueHeader;

static void LayoutPillButtons(UIView *row) {
    CGFloat pad = 20, gap = 10, h = 40, n = 3, W = row.bounds.size.width;
    CGFloat w = (W - pad * 2 - gap * (n - 1)) / n;
    for (int i = 0; i < 3; i++) {
        UIView *b = [row viewWithTag:11 + i];
        CGRect bf = CGRectMake(pad + i * (w + gap), (QUEUE_EXTRA - h) / 2, w, h);
        if (!CGRectEqualToRect(b.frame, bf)) b.frame = bf;
    }
}


// The pill row lives inside the list, in the 54pt just above what's scrolled
// into view. With the list slid down 54pt, that band lands exactly where the
// top of the list used to be, and it moves/fades with the list.
static void PositionQueueRow(UIScrollView *list) {
    UIView *row = QueueRowOf(list);
    UIView *host = list.superview;
    UIWindow *w = list.window;
    if (!row || !host || !w) return;
    if (row.superview != host) { [row removeFromSuperview]; [host addSubview:row]; }
    // Pills go right under the song row (the ••• sits in that row), like iOS 26.
    UIView *more = gPlayerMoreQ;
    CGFloat anchor;
    if (more.window == w) anchor = [more convertPoint:CGPointMake(0, more.bounds.size.height / 2) toView:nil].y + 36;
    else anchor = [list convertPoint:CGPointMake(0, list.bounds.origin.y) toView:nil].y + 50;
    if (more.window == w && anchor > w.safeAreaInsets.top + 220) {
        // Scrolled up into History: the song row slides down with it. Pills hide,
        // the whole list shows; everything comes back when scrolled down again.
        if (!row.hidden) [UIView animateWithDuration:0.15 animations:^{ row.alpha = 0; } completion:^(BOOL d) { row.hidden = YES; }];
        if ([list.layer.mask.name isEqualToString:@"mp.queue"]) list.layer.mask = nil;
        return;
    }
    if (row.hidden || row.alpha < 1) { row.hidden = NO; [UIView animateWithDuration:0.15 animations:^{ row.alpha = 1; }]; }
    CGRect rw = CGRectMake(0, anchor, w.bounds.size.width, QUEUE_EXTRA);
    CGRect rf = [host convertRect:rw fromView:nil];
    rf.origin.x = list.frame.origin.x; rf.size.width = list.frame.size.width;
    if (!CGRectEqualToRect(row.frame, rf)) row.frame = rf;
    if ([host.subviews indexOfObject:row] < [host.subviews indexOfObject:list]) [host insertSubview:row aboveSubview:list];
    if (list.hidden || list.alpha < 0.05) row.hidden = YES;
    LayoutPillButtons(row);

    // Slide the list so its first header ("Continue Playing") starts below the pills.
    NSNumber *shN = objc_getAssociatedObject(list, &gQueueShiftKey);
    UIView *hdr = gQueueHeader;
    BOOL atTop = list.contentOffset.y <= -list.adjustedContentInset.top + 1;
    if (!shN && hdr.window == w && atTop) {
        CGFloat hTop = [hdr convertPoint:CGPointZero toView:nil].y - list.transform.ty;
        CGFloat need = MAX(0, MIN(90, (anchor + QUEUE_EXTRA + 6) - (hTop - 10)));
        shN = @(round(need));
        objc_setAssociatedObject(list, &gQueueShiftKey, shN, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGFloat sh = shN.doubleValue;
    if (fabs(list.transform.ty - sh) > 0.5) list.transform = CGAffineTransformMakeTranslation(0, sh);
    if (list.clipsToBounds) list.clipsToBounds = NO;
    // Visible: from below the pills down to the list's own (unshifted) bottom.
    CGRect b = list.bounds;
    CGFloat topIn = [list convertPoint:CGPointMake(0, anchor + QUEUE_EXTRA) fromView:nil].y;
    topIn = MAX(b.origin.y, topIn);
    CGFloat bottomIn = b.origin.y + b.size.height - sh;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    CALayer *mask = list.layer.mask;
    if (!mask || ![mask.name isEqualToString:@"mp.queue"]) { mask = [CALayer layer]; mask.name = @"mp.queue"; mask.backgroundColor = UIColor.blackColor.CGColor; list.layer.mask = mask; }
    CGRect mf = CGRectMake(b.origin.x, topIn, b.size.width, MAX(0, bottomIn - topIn));
    if (!CGRectEqualToRect(mask.frame, mf)) mask.frame = mf;
    [CATransaction commit];
}

static void UnflagQueueTable(UIScrollView *list) {
    if (!list || !objc_getAssociatedObject(list, kQueueTable)) return;
    [QueueRowOf(list) removeFromSuperview];
    objc_setAssociatedObject(list, kQueueRowObj, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(list, kQueueTable, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIEdgeInsets i = list.contentInset; i.bottom -= QUEUE_EXTRA; list.contentInset = i;
    list.transform = CGAffineTransformIdentity;
    objc_setAssociatedObject(list, &gQueueShiftKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    list.layer.mask = nil;
    NSNumber *clip = objc_getAssociatedObject(list, kQueuePad);
    if (clip) list.clipsToBounds = clip.boolValue;
    ShowOriginal(gQShuffle); ShowOriginal(gQRepeat); ShowOriginal(gQAuto);
}

static void QueueTick(UIView *player) {
    UIView *header = gQueueLook ? FindQueueHeader(player, 0) : nil;
    UIScrollView *table = nil;
    for (UIView *p = header.superview; p; p = p.superview) if ([p isKindOfClass:[UIScrollView class]]) { table = (UIScrollView *)p; break; }
    UIScrollView *old = gQueueTable;
    if (!header && old.window && objc_getAssociatedObject(old, kQueueTable)) {
        // Header scrolled off (history above): keep everything as is, no flicker.
        HideOriginal(gQShuffle); HideOriginal(gQRepeat); if (gQAuto) HideOriginal(gQAuto);
        PositionQueueRow(old);
        RefreshQueueRow();
        return;
    }
    if (old && old != table) UnflagQueueTable(old);
    if (!header || !table) { gQueueTable = nil; gQueueDebug = header ? @"no table" : @"no header"; return; }

    NSMutableArray *ctls = [NSMutableArray array];
    CollectControls(header, 0, ctls);
    [ctls sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGFloat x = [a convertRect:a.bounds toView:nil].origin.x, y = [b convertRect:b.bounds toView:nil].origin.x;
        return x < y ? NSOrderedAscending : (x > y ? NSOrderedDescending : NSOrderedSame);
    }];
    UIControl *sh = nil, *rp = nil, *ap = nil;
    for (UIControl *c in ctls) {
        NSString *n = NSStringFromClass([c class]).lowercaseString;
        if ([n containsString:@"shuffle"]) sh = c;
        else if ([n containsString:@"repeat"]) rp = c;
        else if ([n containsString:@"autoplay"] || [n containsString:@"infinit"]) ap = c;
    }
    // Fall back to left-to-right order: shuffle, repeat, autoplay.
    if (!sh && ctls.count >= 1) sh = ctls[0];
    if (!rp && ctls.count >= 2) rp = ctls[1];
    if (!ap && ctls.count >= 3) ap = ctls[2];
    if (!sh || !rp || !sh.allControlEvents || !rp.allControlEvents) {
        UnflagQueueTable(table);
        gQueueTable = nil;
        gQueueDebug = [NSString stringWithFormat:@"header ok, %lu controls, can't forward", (unsigned long)ctls.count];
        return;
    }
    gQShuffle = sh; gQRepeat = rp; gQAuto = ap;
    gQueueTable = table;
    gQueueHeader = header;

    if (!objc_getAssociatedObject(table, kQueueTable)) {
        objc_setAssociatedObject(table, kQueuePad, @(table.clipsToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(table, kQueueTable, @"shift", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        table.contentInset = table.contentInset;   // through the hook: +54 at the bottom
        UIView *row = [UIView new];
        row.tag = QUEUEROW_TAG;
        // Solid background so the list never shows through behind the pills.
        UIColor *bg = table.backgroundColor;
        row.backgroundColor = (bg && CGColorGetAlpha(bg.CGColor) > 0.9) ? bg : UIColor.blackColor;
        for (int i = 0; i < 3; i++) {
            UIButton *b = [UIButton buttonWithConfiguration:[UIButtonConfiguration filledButtonConfiguration] primaryAction:nil];
            b.tag = 11 + i;
            [b addTarget:[MPQueueTarget shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            [row addSubview:b];
        }
        objc_setAssociatedObject(table, kQueueRowObj, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [table.superview addSubview:row];
    }
    HideOriginal(sh); HideOriginal(rp); if (ap) HideOriginal(ap);
    PositionQueueRow(table);
    RefreshQueueRow();
    gQueueDebug = [NSString stringWithFormat:@"row ok (%@, %@) %@ / %@ / %@", objc_getAssociatedObject(table, kQueueTable), NSStringFromClass([table class]),
                   NSStringFromClass([sh class]), NSStringFromClass([rp class]), ap ? NSStringFromClass([ap class]) : @"-"];
}

#pragma mark - full player

static void SweepQueueButtons(UIView *v, int depth) {
    for (UIView *s in v.subviews) {
        if (s.hidden || [s isKindOfClass:[UIScrollView class]]) continue;
        RoundIfQueueButton(s);
        if (depth < 14) SweepQueueButtons(s, depth + 1);
    }
}

static NSString *ShortName(UIView *v) {
    NSString *n = NSStringFromClass([v class]);
    NSRange dot = [n rangeOfString:@"." options:NSBackwardsSearch];
    if (dot.location != NSNotFound) n = [n substringFromIndex:dot.location + 1];
    if (n.length > 30) n = [@"…" stringByAppendingString:[n substringFromIndex:n.length - 29]];
    return n;
}

static void MapPlayer(UIView *v, UIWindow *w, int depth, NSMutableArray *out) {
    for (UIView *s in v.subviews) {
        if (out.count >= 34) return;
        if (s.hidden || s.alpha < 0.01 || s.tag == PLAYERDEBUG_TAG) continue;
        BOOL isCtl = [s isKindOfClass:[UIControl class]];
        BOOL isHeader = [s isKindOfClass:[UILabel class]] &&
            ([((UILabel *)s).text isEqualToString:@"Continue Playing"] || [((UILabel *)s).text isEqualToString:@"Playing Next"]);
        if (isCtl || isHeader) {
            CGRect r = [s convertRect:s.bounds toView:w];
            NSString *ax = s.accessibilityLabel ?: (isHeader ? ((UILabel *)s).text : @"");
            NSString *chain = [NSString stringWithFormat:@"%@<%@", ShortName(s.superview), ShortName(s.superview.superview)];
            [out addObject:[NSString stringWithFormat:@"%@ '%@' %.0f,%.0f %.0fx%.0f in %@",
                            ShortName(s), ax, r.origin.x, r.origin.y, r.size.width, r.size.height, chain]];
        }
        if (isCtl) continue;
        if (depth < 18) MapPlayer(s, w, depth + 1, out);
    }
}

static void PlayerDebug(UIView *player, UIWindow *w) {
    UILabel *l = (UILabel *)[w viewWithTag:PLAYERDEBUG_TAG];
    if (!gDebug || !player) { [l removeFromSuperview]; return; }
    if (![l isKindOfClass:[UILabel class]]) {
        l = [UILabel new];
        l.tag = PLAYERDEBUG_TAG;
        l.numberOfLines = 0;
        l.font = [UIFont monospacedSystemFontOfSize:8.5 weight:UIFontWeightRegular];
        l.textColor = UIColor.whiteColor;
        l.backgroundColor = [UIColor colorWithRed:0.35 green:0 blue:0.35 alpha:0.88];
        l.userInteractionEnabled = NO;
        l.layer.cornerRadius = 8;
        l.clipsToBounds = YES;
        [w addSubview:l];
    }
    NSMutableArray *lines = [NSMutableArray array];
    MapPlayer(player, w, 0, lines);
    NSString *text = [NSString stringWithFormat:@" MusicPill player map (open the queue, screenshot this)\n motion: %@\n queue: %@\n %@", gMotionDebug, gQueueDebug, [lines componentsJoinedByString:@"\n "]];
    if (![l.text isEqualToString:text]) l.text = text;
    CGFloat width = w.bounds.size.width - 16;
    CGSize s = [l sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGRect f = CGRectMake(8, 50, width, MIN(s.height + 6, w.bounds.size.height - 100));
    if (!CGRectEqualToRect(l.frame, f)) l.frame = f;
    [w bringSubviewToFront:l];
}

static void MotionTick(UIWindow *w);
#define BLOCK_TAG 0x4D50424B
// Title Music's own bar shows (nil if none); a paused song after launch counts as loaded.
static NSString *MusicBarTitle(UIView *mini) {
    NSMutableArray *st = [NSMutableArray arrayWithObject:mini];
    int g = 0;
    while (st.count && g++ < 200) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == BLOCK_TAG || [v isKindOfClass:NSClassFromString(@"MPMiniPill")]) continue;
        if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) return ((UILabel *)v).text;
        [st addObjectsFromArray:v.subviews];
    }
    return nil;
}
static void NotPlayingBlock(UIView *mini) {
    NSString *mt = MusicBarTitle(mini);
    BOOL idle = !mt.length || [mt isEqualToString:@"Not Playing"];
    UIView *blk = [mini viewWithTag:BLOCK_TAG];
    if (!idle) { [blk removeFromSuperview]; return; }
    CGFloat stopX = mini.bounds.size.width;
    NSMutableArray *st = [NSMutableArray arrayWithObject:mini];
    int g = 0;
    while (st.count && g++ < 200) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.tag == BLOCK_TAG) continue;
        if ([v isKindOfClass:[UIControl class]] && v.bounds.size.width < 80 && !v.hidden) {
            CGFloat x = [v convertPoint:CGPointZero toView:mini].x;
            if (x > mini.bounds.size.width * 0.4) stopX = MIN(stopX, x);
            continue;
        }
        [st addObjectsFromArray:v.subviews];
    }
    if (!blk) { blk = [UIView new]; blk.tag = BLOCK_TAG; blk.backgroundColor = UIColor.clearColor; blk.userInteractionEnabled = YES; [mini addSubview:blk]; }
    CGRect f = CGRectMake(0, 0, MAX(0, stopX - 4), mini.bounds.size.height);
    if (!CGRectEqualToRect(blk.frame, f)) blk.frame = f;
    if (mini.subviews.lastObject != blk) [mini bringSubviewToFront:blk];
}

// ---- Full player, iOS 26 details ----
static UIColor *MusicPink(void) { return [UIColor colorWithRed:0.98 green:0.24 blue:0.37 alpha:1]; }
#define PSTAR_TAG 0x4D505354
#define LOSSGLASS_TAG 0x4D504C47
static __weak UIView *gPlayerMore;
static __weak UIButton *gPlayerStar;
static NSHashTable *gMarquees;   // the player's scrolling title / artist rows
static void FadeBefore(UIView *v, CGFloat stopX) {
    if (!v.window) return;
    CGFloat x0 = [v convertPoint:CGPointZero toView:nil].x;
    CGFloat wdt = MAX(0, stopX - x0);
    if (wdt >= v.bounds.size.width) { if ([v.layer.mask.name isEqualToString:@"mp.fade"]) v.layer.mask = nil; return; }
    CAGradientLayer *m = (CAGradientLayer *)v.layer.mask;
    if (![m isKindOfClass:[CAGradientLayer class]] || ![m.name isEqualToString:@"mp.fade"]) {
        m = [CAGradientLayer layer]; m.name = @"mp.fade";
        m.startPoint = CGPointMake(0, 0.5); m.endPoint = CGPointMake(1, 0.5);
        m.colors = @[(id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
        v.layer.mask = m;
    }
    CGFloat w = v.bounds.size.width;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    m.frame = v.bounds;
    m.locations = @[@0, @(MAX(0, (wdt - 18) / w)), @(wdt / w)];
    [CATransaction commit];
}
static void PlayerStarSync(void) {
    UIButton *star = gPlayerStar;
    UIView *more = gPlayerMore;
    if (!star.window) return;
    if (!more.window || star.window != more.window) { star.alpha = 0; return; }
    BOOL show = ViewShowing(more);
    if (star.hidden == show) star.hidden = !show;
    if (!show) return;
    UIView *dots = GlyphIn(more, 0);
    if (dots && fabs(dots.transform.a - 1.35) > 0.01) dots.transform = CGAffineTransformMakeScale(1.35, 1.35);
    if (star.alpha < 1 && !star.layer.animationKeys.count) star.alpha = 1;
    CGPoint mc = GlyphCenter(more, nil);
    CGPoint q = [star.superview convertPoint:CGPointMake(mc.x - 40, mc.y) fromView:nil];
    CGPoint c = CGPointMake(round(q.x), round(q.y));
    if (!CGPointEqualToPoint(star.center, c)) star.center = c;
    // Title and artist rows end before the star.
    CGFloat stopX = [star convertPoint:CGPointZero toView:nil].x - 2;
    CGFloat sy = [star convertPoint:CGPointMake(22, 22) toView:nil].y;
    for (UIView *m in [gMarquees allObjects]) {
        if (!m.window) continue;
        CGFloat my = [m convertPoint:CGPointMake(0, m.bounds.size.height / 2) toView:nil].y;
        if (fabs(my - sy) < 45) FadeBefore(m, stopX);
    }
}
static BOOL gSongFav, gSongFavKnown;
static CFTimeInterval gSongFavLock;
static void RefreshSongFav(void) {
    if (CACurrentMediaTime() < gSongFavLock) return;
    UIAction *a = FindKind(MenuOf(gPlayerMore, NULL).children, @[@"love", @"unlove"]);
    gSongFavKnown = a != nil;
    if (a) gSongFav = [MenuKind(a) isEqualToString:@"unlove"];
}
@interface MPSongStar : NSObject
+ (instancetype)shared;
@end
@implementation MPSongStar
+ (instancetype)shared { static MPSongStar *t; static dispatch_once_t o; dispatch_once(&o, ^{ t = [MPSongStar new]; }); return t; }
- (void)tap:(UIButton *)b {
    UIView *more = gPlayerMore;
    UIContextMenuInteraction *mi = nil;
    UIAction *a = FindKind(MenuOf(more, &mi).children, @[@"love", @"unlove"]);
    if (!a) { OpenMenu(more, mi); return; }
    BOOL willFav = ![MenuKind(a) isEqualToString:@"unlove"];
    RunAction(a, b);
    gSongFav = willFav; gSongFavKnown = YES;
    gSongFavLock = CACurrentMediaTime() + 1.5;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    SetStar(b, willFav, YES);
}
@end
static NSString *ControlText(UIView *v);
static void PlayerExtras(UIView *player, UIWindow *w) {
    CGFloat H = w.bounds.size.height;
    UIView *more = nil, *loss = nil; UIButton *artist = nil;
    NSMutableArray *st = [NSMutableArray arrayWithObject:player];
    int g = 0;
    while (st.count && g++ < 900) {
        UIView *v = st.lastObject; [st removeLastObject];
        if (v.hidden || v.alpha < 0.01 || v.tag == PSTAR_TAG || v.tag == PLAYERDEBUG_TAG) continue;
        CGRect f = [v convertRect:v.bounds toView:nil];
        NSString *ax = v.accessibilityLabel;
        // VoiceOver labels are empty until accessibility loads (e.g. after a reboot),
        // so buttons are also recognised by their symbol / text.
        BOOL symBtn = [v isKindOfClass:[UIControl class]] && [NSStringFromClass([v class]) containsString:@"SymbolButton"];
        NSString *glyph = symBtn ? ((UIImageView *)GlyphIn(v, 0)).image.description : nil;
        if (symBtn && !ax.length) {
            NSString *txt = ControlText(v);
            if ([glyph containsString:@"ellipsis"]) ax = @"More";
            else if (txt.length) ax = txt;
        }
        if (!more && symBtn && [ax isEqualToString:@"More"] && ViewShowing(v)) more = v;
        else if ([v isKindOfClass:[UIControl class]] && CGRectGetMidY(f) > H * 0.4 && CGRectGetMidY(f) < H * 0.9) {
            NSString *cn = NSStringFromClass([v class]);
            if (NO) {}
            else if (!loss && [cn containsString:@"SymbolButton"] && ([ax containsString:@"Lossless"] || [ax containsString:@"Dolby"] || [ax containsString:@"Atmos"] || [ax containsString:@"Hi-Res"])) loss = v;
            else if (!artist && [v isKindOfClass:[UIButton class]] && [NSStringFromClass([v.superview class]) containsString:@"Marquee"]) artist = (UIButton *)v;
        }
        if ([NSStringFromClass([v class]) hasSuffix:@"MarqueeView"]) {
            if (!gMarquees) gMarquees = [NSHashTable weakObjectsHashTable];
            [gMarquees addObject:v];
        }
        if ([v isKindOfClass:[UIButton class]] && [NSStringFromClass([v.superview class]) containsString:@"Marquee"] && ViewShowing(v)) {
            objc_setAssociatedObject(((UIButton *)v).titleLabel, kKeepRed, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (![[(UIButton *)v titleColorForState:UIControlStateNormal] isEqual:MusicPink()]) [(UIButton *)v setTitleColor:MusicPink() forState:UIControlStateNormal];
        }
        [st addObjectsFromArray:v.subviews];
    }
    // Artist name in Music's pink, like iOS 26.
    if (artist) {
        objc_setAssociatedObject(artist.titleLabel, kKeepRed, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (![[artist titleColorForState:UIControlStateNormal] isEqual:MusicPink()]) [artist setTitleColor:MusicPink() forState:UIControlStateNormal];
        if (![artist.titleLabel.textColor isEqual:MusicPink()]) artist.titleLabel.textColor = MusicPink();
    }
    // ••• without its circle; a favourite star just left of it.
    if (more) {
        gPlayerMore = more; gPlayerMoreQ = more;
        StripMusicCircle(more);
        const void *keys[4] = { kFloatGlass, kBackGlass, kPairGlass, kShareBtn };
        for (int ki = 0; ki < 4; ki++) {
            UIView *gl = objc_getAssociatedObject(more, keys[ki]);
            if (gl) { [gl removeFromSuperview]; objc_setAssociatedObject(more, keys[ki], nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        }
        for (UIView *s in more.superview.subviews) if (s.tag == FLOATGLASS_TAG) s.hidden = YES;
        if ([more isKindOfClass:[UIButton class]]) {
            UIButton *mb = (UIButton *)more;
            if (mb.configuration && mb.configuration.background.backgroundColor && ![mb.configuration.background.backgroundColor isEqual:UIColor.clearColor]) {
                UIButtonConfiguration *c = mb.configuration; c.background.backgroundColor = UIColor.clearColor; mb.configuration = c;
            }
            if (mb.tintColor && ![mb.tintColor isEqual:MusicPink()]) mb.tintColor = MusicPink();
        }
        UIView *dots = GlyphIn(more, 0);
        if (dots && fabs(dots.transform.a - 1.35) > 0.01) dots.transform = CGAffineTransformMakeScale(1.35, 1.35);
        CGPoint mc = GlyphCenter(more, nil);
        CGPoint want = CGPointMake(mc.x - 40, mc.y);
        UIView *host = nil;
        for (UIView *p = more.superview; p && p != w; p = p.superview) {
            CGPoint q = [w convertPoint:want toView:p];
            if (CGRectContainsRect(p.bounds, CGRectMake(q.x - 22, q.y - 22, 44, 44)) && p.userInteractionEnabled && ![p isKindOfClass:[UIStackView class]]) { host = p; break; }
        }
        if (!host) host = player;
        UIButton *star = (UIButton *)[host viewWithTag:PSTAR_TAG];
        if (!star) {
            for (UIView *o in [player.subviews copy]) if (o.tag == PSTAR_TAG) [o removeFromSuperview];
            star = [UIButton buttonWithType:UIButtonTypeCustom];
            star.tag = PSTAR_TAG;
            star.tintColor = MusicPink();
            [star addTarget:[MPSongStar shared] action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            star.alpha = 0;   // shown once placed next to •••
            [host addSubview:star];
            SetStar(star, NO, NO);
            gSongFavKnown = NO;
        }
        CGPoint q = [w convertPoint:want toView:host];
        CGRect sf = CGRectMake(round(q.x - 22), round(q.y - 22), 44, 44);
        if (!CGRectEqualToRect(star.frame, sf)) star.frame = sf;
        if (host.subviews.lastObject != star) [host bringSubviewToFront:star];
        gPlayerStar = star;
        static NSString *lastSong;
        if (gNowTitle && ![gNowTitle isEqualToString:lastSong]) {
            lastSong = gNowTitle;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ @try { RefreshSongFav(); } @catch (__unused id e) {} });
        }
        static CFTimeInterval lastRefresh;
        if (CACurrentMediaTime() - lastRefresh > 2) { lastRefresh = CACurrentMediaTime(); @try { RefreshSongFav(); } @catch (__unused id e) {} }
        if (gSongFavKnown && CACurrentMediaTime() > gSongFavLock) SetStar(star, gSongFav, NO);
    }
    // Lossless / Dolby badge on liquid glass instead of its outline (only while it shows).
    static __weak UIView *lossGlass;
    BOOL lossShowing = loss && ViewShowing(loss) && (HasText(loss, 0) || GlyphIn(loss, 0));
    if (!lossShowing) lossGlass.hidden = YES;
    for (UIView *s in [loss.superview.subviews copy]) if (s.tag == LOSSGLASS_TAG) [s removeFromSuperview];
    if (NO && lossShowing && loss.superview) {
        NSMutableArray *ls = [NSMutableArray arrayWithObject:loss.layer];
        int lg = 0;
        while (ls.count && lg++ < 40) {
            CALayer *l = ls.lastObject; [ls removeLastObject];
            if (l.borderWidth > 0) l.borderWidth = 0;
            if ([l isKindOfClass:[CAShapeLayer class]] && ((CAShapeLayer *)l).lineWidth > 0 && ((CAShapeLayer *)l).fillColor == NULL) l.hidden = YES;
            [ls addObjectsFromArray:l.sublayers ?: @[]];
        }
        if ([loss isKindOfClass:[UIButton class]] && ((UIButton *)loss).configuration) {
            UIButtonConfiguration *c = ((UIButton *)loss).configuration;
            if (c.background.strokeWidth > 0) { c.background.strokeWidth = 0; ((UIButton *)loss).configuration = c; }
        }
        UIView *hostL = loss.superview;
        UIVisualEffectView *gl = (UIVisualEffectView *)[hostL viewWithTag:LOSSGLASS_TAG];
        if (!gl) {
            gl = [[UIVisualEffectView alloc] initWithEffect:TabGlassEffect()];
            gl.tag = LOSSGLASS_TAG; gl.userInteractionEnabled = NO; gl.clipsToBounds = YES;
            gl.layer.borderWidth = 0.75; gl.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
            gl.layer.cornerCurve = kCACornerCurveContinuous;
            [hostL insertSubview:gl belowSubview:loss];
        }
        CGRect lf = CGRectInset(loss.frame, -4, -3);
        if (!CGRectEqualToRect(gl.frame, lf)) { gl.frame = lf; gl.layer.cornerRadius = lf.size.height / 2; }
        gl.hidden = NO;
        gl.alpha = loss.alpha;
        lossGlass = gl;
    }
}

static void StartWatchdog(void) {
    static int tick = 0;
    CADisplayLink *dl = [CADisplayLink displayLinkWithTarget:[MPPillTicker shared] selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) dl.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
    [dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
        tick++;
        UITabBar *tb = gLastTabBar;
        UIWindow *w = tb.window;
        UIView *mini = tb ? objc_getAssociatedObject(tb, kMini) : nil;
        UIViewController *root = w.rootViewController;
        BOOL playerUp = PresentedPlayer(root) && !PresentedPlayer(root).isBeingDismissed;

        // Keep the pill small.
        if (gRound && mini && mini.window && !mini.hidden && mini.alpha >= 0.01 &&
            !mini.layer.animationKeys.count && !playerUp && objc_getAssociatedObject(mini, kStyled)) {
            @try {
                CGFloat r = mini.bounds.size.height / 2;
                if (mini.layer.cornerRadius != r) mini.layer.cornerRadius = r;
                ApplyPillTransform(mini, YES);
            } @catch (__unused id e) {}
        }
        // Nothing playing: taps on the bar (outside its buttons) do nothing.
        if (mini && mini.window) { @try { NotPlayingBlock(mini); } @catch (__unused id e) {} }
        // Scrolling title.
        if (mini && !playerUp) { @try { MarqueeTick(mini); } @catch (__unused id e) {} }
        // Album/playlist buttons and glass top buttons.
        if (w && !playerUp) {
            @try { AlbumTick(w); } @catch (__unused id e) {}
            @try { NavTick(TopNavBar(w)); } @catch (__unused id e) {}
            @try { FloatTick(w); } @catch (__unused id e) {}
        }
        // Full player: round queue button (backup for the hook) + debug map.
        UIView *player = nil;
        if (w && PlayerIsUp(w, &player)) {
            @try { SweepQueueButtons(player, 0); } @catch (__unused id e) {}
            @try { QueueTick(player); } @catch (__unused id e) {}
            @try { MotionTick(w); } @catch (__unused id e) {}   // animated cover on the artwork
            @try { PlayerExtras(player, w); } @catch (__unused id e) {}
            if (tick % 4 == 0) { @try { PlayerDebug(player, w); } @catch (__unused id e) {} }
        } else if (w) {
            [[w viewWithTag:PLAYERDEBUG_TAG] removeFromSuperview];
        }
        // Keep the debug box current.
        if (gDebug && tb && tick % 4 == 0) { @try { Update(tb); } @catch (__unused id e) {} }
    }];
}

%ctor {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.Music"]) return;
    LoadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefsChanged, NOTIFY, NULL, CFNotificationSuspensionBehaviorCoalesce);
    %init;
    HookMenuClasses();
    HookSymbolButton();
    dispatch_async(dispatch_get_main_queue(), ^{ StartWatchdog(); });
}
