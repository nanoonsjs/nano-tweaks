// M26Keeper - part of Messages26, runs in imagent (the Messages background service).
// Keep Unsent Messages: right before an unsend wipes a message, its text (and a copy of its photos / videos /
// files) is saved to ~/Library/SMS/M26Unsent so Messages26 can still show it. Only while the switch is on.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

#define DIR @"/var/mobile/Library/SMS/M26Unsent"
#define LIST DIR @"/unsent.plist"

static BOOL KeepOn(void) {
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

static void SaveUnsent(id param) {
    if (!KeepOn()) return;
    NSString *guid = Get(param, @"editedMessageGUID");
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
    if (!msg) return;
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
    id chat = Get(param, @"chat");
    NSString *chatName = Get(chat, @"displayName");
    if (![chatName isKindOfClass:[NSString class]] || !chatName.length) chatName = Get(chat, @"chatIdentifier");
    NSString *who = Get(msg, @"sender"); if (![who isKindOfClass:[NSString class]]) who = Get(msg, @"handle");
    NSDate *t = Get(msg, @"time");
    NSMutableDictionary *all = [[NSDictionary dictionaryWithContentsOfFile:LIST] mutableCopy] ?: [NSMutableDictionary dictionary];
    all[guid] = @{@"text": text ?: @"", @"files": files, @"who": [who isKindOfClass:[NSString class]] ? who : @"",
                  @"chat": [chatName isKindOfClass:[NSString class]] ? chatName : @"",
                  @"time": @([t isKindOfClass:[NSDate class]] ? t.timeIntervalSince1970 : [NSDate date].timeIntervalSince1970),
                  @"unsentAt": @([NSDate date].timeIntervalSince1970)};
    [all writeToFile:LIST atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/unsent"), NULL, NULL, YES);
}

static id (*origRun)(id, SEL, id);
static id Run(id self, SEL _cmd, id input) {
    @try { SaveUnsent(input); } @catch (__unused id e) {}
    return origRun(self, _cmd, input);
}

%ctor {
    Class C = NSClassFromString(@"IMEditMessageCommandProcessingPipelineComponent");
    SEL s = NSSelectorFromString(@"runIndividuallyWithInput:");
    if (C && class_getInstanceMethod(C, s)) MSHookMessageEx(C, s, (IMP)Run, (IMP *)&origRun);
}
