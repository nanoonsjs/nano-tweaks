// M26Keeper - part of Messages26, runs in imagent (the Messages background service).
// Keep Unsent Messages: right before an unsend wipes a message, its text (and a copy of its photos / videos /
// files) is saved to ~/Library/SMS/M26Unsent so Messages26 can still show it. Only while the switch is on.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#define M26_PRO_NO_UI
#include "M26Pro.h"

#define DIR @"/var/mobile/Library/SMS/M26Unsent"
#define LIST DIR @"/unsent.plist"

// a short log (last ~200 lines) so we can see what happened
static void KLog(NSString *fmt, ...) {
    va_list ap; va_start(ap, fmt); NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap]; va_end(ap);
    NSString *p = DIR @"/log.txt";
    [[NSFileManager defaultManager] createDirectoryAtPath:DIR withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *old = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSArray *ls = [old componentsSeparatedByString:@"\n"];
    if (ls.count > 200) old = [[ls subarrayWithRange:NSMakeRange(ls.count - 150, 150)] componentsJoinedByString:@"\n"];
    NSDateFormatter *f = [NSDateFormatter new]; f.dateFormat = @"MM-dd HH:mm:ss";
    [[old stringByAppendingFormat:@"%@ %@\n", [f stringFromDate:[NSDate date]], s] writeToFile:p atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
// Messages26 drops an "on" file here while the switch is on (prefs of another app can't always be read from here)
static BOOL KeepOn(void) {
    if (!ProUnlocked()) return NO;   // 1.8: Pro
    if ([[NSFileManager defaultManager] fileExistsAtPath:DIR @"/on"]) return YES;
    CFStringRef app = CFSTR("com.apple.MobileSMS");
    CFPreferencesAppSynchronize(app);
    NSNumber *on = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("m26.opt.keepunsent"), app));
    for (NSString *d in @[@"/var/jb/var/mobile/Library/Preferences/", @"/var/mobile/Library/Preferences/"]) {
        NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:[d stringByAppendingString:@"com.nano.messages26.plist"]];
        if ([p[@"enabled"] isKindOfClass:[NSNumber class]] && ![p[@"enabled"] boolValue]) return NO;
    }
    return [on boolValue];
}
static id Get(id o, NSString *k) { @try { return [o valueForKey:k]; } @catch (__unused id e) { return nil; } }

static void SaveMsg(id msg, NSString *guid, id chat);
static void SaveUnsent(id param) {
    NSString *guid = Get(param, @"editedMessageGUID");
    KLog(@"edit command: guid=%@ type=%@ part=%@ body=%lu files=%lu on=%d", guid, Get(param, @"editType"), Get(param, @"editedMessagePartIndex"),
         (unsigned long)[Get(param, @"editedMessagePartBody") length], (unsigned long)[Get(param, @"editedMessagePartFileTransferGUIDs") count], KeepOn());
    if (!KeepOn()) return;
    if (![guid isKindOfClass:[NSString class]]) return;
    // an edit has new text; an unsend has none
    NSAttributedString *nb = Get(param, @"editedMessagePartBody");
    NSArray *nf = Get(param, @"editedMessagePartFileTransferGUIDs");
    if ([nb isKindOfClass:[NSAttributedString class]] && nb.length) return;
    if ([nf isKindOfClass:[NSArray class]] && nf.count) return;
    Class MS = NSClassFromString(@"IMDMessageStore");
    id store = [MS respondsToSelector:@selector(sharedInstance)] ? [MS performSelector:@selector(sharedInstance)] : nil;
    id msg = nil;
    @try { msg = ((id (*)(id, SEL, id))objc_msgSend)(store, NSSelectorFromString(@"messageWithGUID:"), guid); } @catch (__unused id e) {}
    KLog(@"  message found=%d fromMe=%@", msg != nil, Get(msg, @"isFromMe"));
    SaveMsg(msg, guid, Get(param, @"chat"));
}
// what both ways in end up doing: keep this message's text and attachments
static void SaveMsg(id msg, NSString *guid, id chat) {
    if (!msg || !guid) return;
    NSDictionary *have = [NSDictionary dictionaryWithContentsOfFile:LIST];
    if (have[guid]) return;
    if ([Get(msg, @"isFromMe") boolValue]) return;   // your own unsends aren't kept
    NSString *text = Get(msg, @"plainBody");
    if (![text isKindOfClass:[NSString class]]) { NSAttributedString *b = Get(msg, @"body"); text = [b isKindOfClass:[NSAttributedString class]] ? b.string : @""; }
    text = [[text stringByReplacingOccurrencesOfString:@"￼" withString:@""] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:DIR withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableArray *files = [NSMutableArray array];
    NSArray *tg = Get(msg, @"fileTransferGUIDs");
    if ([tg isKindOfClass:[NSArray class]] && tg.count) {
        Class TC = NSClassFromString(@"IMDFileTransferCenter");
        id tc = [TC respondsToSelector:@selector(sharedInstance)] ? [TC performSelector:@selector(sharedInstance)] : nil;
        NSString *fd = [DIR stringByAppendingPathComponent:guid];
        for (NSString *g in tg) {
            id tr = nil;
            @try { tr = ((id (*)(id, SEL, id))objc_msgSend)(tc, NSSelectorFromString(@"transferForGUID:"), g); } @catch (__unused id e) {}
            NSString *lp = Get(tr, @"localPath");
            if (![lp isKindOfClass:[NSString class]] || ![fm fileExistsAtPath:lp]) continue;
            [fm createDirectoryAtPath:fd withIntermediateDirectories:YES attributes:nil error:nil];
            NSString *to = [fd stringByAppendingPathComponent:lp.lastPathComponent];
            [fm removeItemAtPath:to error:nil];
            if ([fm copyItemAtPath:lp toPath:to error:nil]) [files addObject:to];
        }
    }
    if (!text.length && !files.count) return;
    NSString *chatName = Get(chat, @"displayName");
    if (![chatName isKindOfClass:[NSString class]] || !chatName.length) chatName = Get(chat, @"chatIdentifier");
    NSString *who = Get(msg, @"sender"); if (![who isKindOfClass:[NSString class]]) who = Get(msg, @"handle");
    NSDate *t = Get(msg, @"time");
    NSMutableDictionary *all = [[NSDictionary dictionaryWithContentsOfFile:LIST] mutableCopy] ?: [NSMutableDictionary dictionary];
    all[guid] = @{@"text": text ?: @"", @"files": files, @"who": [who isKindOfClass:[NSString class]] ? who : @"",
                  @"chat": [chatName isKindOfClass:[NSString class]] ? chatName : @"",
                  @"time": @([t isKindOfClass:[NSDate class]] ? t.timeIntervalSince1970 : [NSDate date].timeIntervalSince1970),
                  @"unsentAt": @([NSDate date].timeIntervalSince1970)};
    BOOL ok = [all writeToFile:LIST atomically:YES];
    KLog(@"  kept: %lu chars, %lu files, written=%d", (unsigned long)text.length, (unsigned long)files.count, ok);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/unsent"), NULL, NULL, YES);
}

static id (*origRun)(id, SEL, id);
static id Run(id self, SEL _cmd, id input) {
    @try { SaveUnsent(input); } @catch (__unused id e) {}
    return origRun(self, _cmd, input);
}

// second way in: the message being marked as unsent (its text may still be there)
static void (*origAddRetracted)(id, SEL, long long);
static void AddRetracted(id self, SEL _cmd, long long idx) {
    @try {
        KLog(@"retract mark: guid=%@ part=%lld on=%d", Get(self, @"guid"), idx, KeepOn());
        if (KeepOn() && ![Get(self, @"isFromMe") boolValue]) SaveMsg(self, Get(self, @"guid"), nil);
    } @catch (__unused id e) {}
    origAddRetracted(self, _cmd, idx);
}

%ctor {
    KLog(@"loaded in %@ (pid %d)", [NSProcessInfo processInfo].processName, getpid());
    Class C = NSClassFromString(@"IMEditMessageCommandProcessingPipelineComponent");
    SEL s = NSSelectorFromString(@"runIndividuallyWithInput:");
    if (C && class_getInstanceMethod(C, s)) { MSHookMessageEx(C, s, (IMP)Run, (IMP *)&origRun); KLog(@"hooked edit commands"); }
    else KLog(@"edit command class missing: %@", C);
    Class M = NSClassFromString(@"IMMessageItem");
    SEL r = @selector(addRetractedPartIndex:);
    if (M && class_getInstanceMethod(M, r)) MSHookMessageEx(M, r, (IMP)AddRetracted, (IMP *)&origAddRetracted);
}
