// ===================== Messages26 Pro =====================
// Keep Unsent Messages and Conversation Insights are Pro: $2.99 once, through Gumroad. Each purchase comes with
// its own key; entering it checks with Gumroad (and counts it used), then Pro is unlocked for good on this phone.
// Gumroad's product id and the buy link come from pro.json on the repo, so they can change without an update.
// Used by Messages (paywall), the Settings app (Pro card) and M26Keeper in imagent (Foundation only).
#pragma once
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <dlfcn.h>

#define PRO_FILE @"/var/mobile/Library/SMS/M26Unsent/pro.plist"
#define PRO_CONFIG_URL @"https://nanoonsjs.github.io/nano-repo/pro.json"

// this iPhone (the key is tied to it)
static NSString *ProDevice(void) {
    static NSString *dev;
    if (dev) return dev;
    CFTypeRef (*mg)(CFStringRef) = NULL;
    void *h = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
    if (h) mg = (CFTypeRef (*)(CFStringRef))dlsym(h, "MGCopyAnswer");
    id v = mg ? CFBridgingRelease(mg(CFSTR("UniqueDeviceID"))) : nil;
    if (![v isKindOfClass:[NSString class]]) v = mg ? CFBridgingRelease(mg(CFSTR("SerialNumber"))) : nil;
    dev = [v isKindOfClass:[NSString class]] ? v : @"unknown";
    return dev;
}
static NSString *ProSig(NSString *key, NSString *dev) {
    NSData *d = [[NSString stringWithFormat:@"%@|%@|nano.m26.pro.v1", key ?: @"", dev ?: @""] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(d.bytes, (CC_LONG)d.length, md);
    NSMutableString *s = [NSMutableString string]; for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [s appendFormat:@"%02x", md[i]];
    return s;
}
static BOOL ProUnlocked(void) {
    static BOOL cached; static CFAbsoluteTime at;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (at > 0 && now - at < 4) return cached;
    at = now;
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:PRO_FILE];
    NSString *key = p[@"key"], *dev = ProDevice();
    cached = [key isKindOfClass:[NSString class]] && key.length && [p[@"dev"] isEqual:dev] && [p[@"sig"] isEqual:ProSig(key, dev)];
    return cached;
}
static void ProConfig(void (^cb)(NSDictionary *c)) {
    NSURL *u = [NSURL URLWithString:[PRO_CONFIG_URL stringByAppendingFormat:@"?t=%ld", (long)CFAbsoluteTimeGetCurrent()]];
    [[[NSURLSession sharedSession] dataTaskWithURL:u completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        NSDictionary *c = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{ cb([c isKindOfClass:[NSDictionary class]] ? c : @{}); });
    }] resume];
}
static NSString *ProEsc(NSString *s) { return [s stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet] ?: @""; }
static void ProVerify(NSString *pid, NSString *key, BOOL count, void (^cb)(NSDictionary *res, NSString *err)) {
    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.gumroad.com/v2/licenses/verify"]];
    rq.HTTPMethod = @"POST"; rq.timeoutInterval = 20;
    [rq setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    rq.HTTPBody = [[NSString stringWithFormat:@"product_id=%@&license_key=%@&increment_uses_count=%@", ProEsc(pid), ProEsc(key), count ? @"true" : @"false"] dataUsingEncoding:NSUTF8StringEncoding];
    [[[NSURLSession sharedSession] dataTaskWithRequest:rq completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        NSDictionary *j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![j isKindOfClass:[NSDictionary class]]) { cb(nil, e ? @"No internet connection. Try again in a moment." : @"Couldn't reach the store. Try again in a moment."); return; }
            cb(j, nil);
        });
    }] resume];
}
// checks the key with Gumroad and, the first time it's used, unlocks Pro on this phone
static void ProActivate(NSString *key, void (^cb)(BOOL ok, NSString *msg)) {
    key = [key stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (key.length < 8) { cb(NO, @"That doesn't look like a Messages26 Pro key."); return; }
    ProConfig(^(NSDictionary *c) {
        NSString *pid = c[@"product_id"];
        if (![pid isKindOfClass:[NSString class]] || !pid.length) { cb(NO, @"Pro isn't on sale yet. Check back soon."); return; }
        // look first (without using it up)
        ProVerify(pid, key, NO, ^(NSDictionary *j, NSString *err) {
            if (err) { cb(NO, err); return; }
            NSDictionary *pu = j[@"purchase"];
            if (![j[@"success"] boolValue]) { cb(NO, @"That key isn't valid."); return; }
            if ([pu[@"refunded"] boolValue] || [pu[@"chargebacked"] boolValue] || [pu[@"disputed"] boolValue]) { cb(NO, @"That purchase was refunded, so the key no longer works."); return; }
            if ([j[@"uses"] integerValue] >= 1) { cb(NO, @"That key was already used. Each key unlocks Pro on one iPhone."); return; }
            // now use it
            ProVerify(pid, key, YES, ^(NSDictionary *j2, NSString *err2) {
                if (err2) { cb(NO, err2); return; }
                if (![j2[@"success"] boolValue] || [j2[@"uses"] integerValue] > 1) { cb(NO, @"That key was already used. Each key unlocks Pro on one iPhone."); return; }
                NSString *dev = ProDevice();
                [[NSFileManager defaultManager] createDirectoryAtPath:[PRO_FILE stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                BOOL w = [@{@"key": key, @"dev": dev, @"sig": ProSig(key, dev), @"at": @(CFAbsoluteTimeGetCurrent()), @"email": pu[@"email"] ?: @""} writeToFile:PRO_FILE atomically:YES];
                CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/pro"), NULL, NULL, YES);
                cb(w, w ? @"Messages26 Pro is unlocked. Thank you!" : @"Your key worked, but it couldn't be saved. Contact nano with your key.");
            });
        });
    });
}

#if __has_include(<UIKit/UIKit.h>) && !defined(M26_PRO_NO_UI)
#import <UIKit/UIKit.h>
// the paywall: buy, or enter the key you got
static void ProShowKeyEntry(UIViewController *from, void (^done)(BOOL));
static void ProPaywall(UIViewController *from, NSString *what, void (^done)(BOOL unlocked)) {
    if (!from) { if (done) done(NO); return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Messages26 Pro"
        message:[NSString stringWithFormat:@"%@ is part of Messages26 Pro.\n\nKeep Unsent Messages + Conversation Insights\n$2.99 once, unlocked for good on this iPhone.\n\nAfter buying you get a key by email: enter it here.", what]
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Buy Pro · $2.99" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x) {
        ProConfig(^(NSDictionary *c) {
            NSString *u = c[@"buy_url"];
            if ([u isKindOfClass:[NSString class]] && u.length) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:u] options:@{} completionHandler:nil];
            else {
                UIAlertController *s = [UIAlertController alertControllerWithTitle:@"Coming soon" message:@"Pro isn't on sale yet. Check back soon." preferredStyle:UIAlertControllerStyleAlert];
                [s addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [from presentViewController:s animated:YES completion:nil];
            }
            if (done) done(NO);
        });
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Enter Key" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x) { ProShowKeyEntry(from, done); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Not Now" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *x) { if (done) done(NO); }]];
    [from presentViewController:a animated:YES completion:nil];
}
static void ProShowKeyEntry(UIViewController *from, void (^done)(BOOL)) {
    UIAlertController *k = [UIAlertController alertControllerWithTitle:@"Enter your Pro key" message:@"It's in the email from Gumroad. Each key works on one iPhone." preferredStyle:UIAlertControllerStyleAlert];
    [k addTextFieldWithConfigurationHandler:^(UITextField *t) {
        t.placeholder = @"XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX";
        t.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters; t.autocorrectionType = UITextAutocorrectionTypeNo;
        t.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
        NSString *clip = [UIPasteboard generalPasteboard].string;
        if (clip.length >= 20 && clip.length <= 60 && [clip componentsSeparatedByString:@"-"].count >= 4) t.text = clip;   // pasted for you
    }];
    __weak UIAlertController *wk = k;
    [k addAction:[UIAlertAction actionWithTitle:@"Unlock" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x) {
        NSString *key = wk.textFields.firstObject.text ?: @"";
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Checking your key…" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [from presentViewController:wait animated:YES completion:nil];
        ProActivate(key, ^(BOOL ok, NSString *msg) {
            [wait dismissViewControllerAnimated:YES completion:^{
                UIAlertController *r = [UIAlertController alertControllerWithTitle:ok ? @"Unlocked 🎉" : @"Couldn't unlock" message:msg preferredStyle:UIAlertControllerStyleAlert];
                [r addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *y) { if (done) done(ok); }]];
                if (!ok) [r addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *y) { ProShowKeyEntry(from, done); }]];
                [from presentViewController:r animated:YES completion:nil];
                if (ok) [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
            }];
        });
    }]];
    [k addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *x) { if (done) done(NO); }]];
    [from presentViewController:k animated:YES completion:nil];
}
#endif
