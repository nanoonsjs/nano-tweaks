// M26Keeper - Conversation Insights. Runs in imagent, which owns the Messages database (~/Library/SMS/sms.db),
// so the numbers are counted right on the phone. Messages26 asks over a Darwin notification with a request file;
// the answer is written next to it and announced back. Nothing leaves the phone.
#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define IDIR @"/var/mobile/Library/SMS/M26Unsent"

static NSString *IBody(const void *b, int n) {
    // attributedBody is an archived NSAttributedString (typedstream): the text follows "NSString", a few marker
    // bytes, then its length
    if (!b || n < 12) return nil;
    const unsigned char *p = b; const unsigned char *end = p + n;
    const unsigned char *k = memmem(p, n, "NSString", 8);
    if (!k) return nil;
    k += 8 + 5;
    if (k >= end) return nil;
    unsigned long len = *k++;
    if (len == 0x81) { if (k + 2 > end) return nil; len = k[0] | (k[1] << 8); k += 2; }
    else if (len == 0x82) { if (k + 4 > end) return nil; len = k[0] | (k[1] << 8) | (k[2] << 16) | ((unsigned long)k[3] << 24); k += 4; }
    if (k + len > end) return nil;
    return [[NSString alloc] initWithBytes:k length:len encoding:NSUTF8StringEncoding];
}
static BOOL IIsEmoji(NSString *g) {
    if (!g.length) return NO;
    UTF32Char c = 0;
    if (![g getBytes:&c maxLength:4 usedLength:NULL encoding:NSUTF32LittleEndianStringEncoding options:0 range:NSMakeRange(0, g.length) remainingRange:NULL]) return NO;
    if (c >= 0x1F300 && c <= 0x1FAFF) return YES;     // pictographs, faces, people, food, animals...
    if (c >= 0x1F000 && c <= 0x1F2FF) return YES;     // cards, mahjong, enclosed (🅰️ 🆒)
    if (c >= 0x1F1E6 && c <= 0x1F1FF) return YES;     // flags
    if (c >= 0x2600 && c <= 0x27BF) return [g rangeOfString:@"️"].location != NSNotFound || (c >= 0x2614 && c <= 0x2615) || c == 0x26A1 || c == 0x2728 || c == 0x274C || c == 0x2705 || c == 0x2764;
    if (c == 0x2B50 || c == 0x2B55 || c == 0x203C || c == 0x2049) return YES;
    return NO;
}
static NSSet *IStop(void) {
    static NSSet *s; static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [NSSet setWithArray:[@"the and you that this with for are was but not have just what your all can get like its it's i'm im dont don't know yeah yea yes no out about they them then there their when how who why will would could should been from too was were one now got she him her his had has our ours mine also some more very really because cause cuz well okay then than into over did does doing gonna wanna gotta lemme let him tho though see say said see'n can't cant didn't didnt that's thats you're youre i'll ill i've ive we're were he's she's isn't isnt wasn't any here where which while said u ur ok lol" componentsSeparatedByString:@" "]]; });
    return s;
}

// one pass over the messages (of one chat, or of all of them)
static NSDictionary *IInsights(NSString *chatId) {
    sqlite3 *db = NULL;
    if (sqlite3_open_v2("/var/mobile/Library/SMS/sms.db", &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, NULL) != SQLITE_OK) { if (db) sqlite3_close(db); return @{@"error": @"Couldn't open the Messages database"}; }
    sqlite3_busy_timeout(db, 3000);
    BOOL all = !chatId.length || [chatId isEqualToString:@"*"];
    NSString *where = all ? @"" : @" AND cmj.chat_id IN (SELECT ROWID FROM chat WHERE chat_identifier = ?1)";
    NSString *q = [NSString stringWithFormat:@"SELECT m.text, m.attributedBody, m.is_from_me, m.date, m.is_audio_message, m.associated_message_type, m.cache_has_attachments FROM message m JOIN chat_message_join cmj ON cmj.message_id = m.ROWID WHERE 1=1%@ ORDER BY m.date DESC LIMIT %d", where, all ? 60000 : 400000];
    sqlite3_stmt *st = NULL;
    if (sqlite3_prepare_v2(db, q.UTF8String, -1, &st, NULL) != SQLITE_OK) { NSString *e = @(sqlite3_errmsg(db)); sqlite3_close(db); return @{@"error": e}; }
    if (!all) sqlite3_bind_text(st, 1, chatId.UTF8String, -1, SQLITE_TRANSIENT);

    long total = 0, mine = 0, theirs = 0, voice = 0, reactions = 0, myChars = 0;
    double first = 0, last = 0;
    long wd[7] = {0}, hr[24] = {0};
    NSCountedSet *days = [NSCountedSet new], *myEmoji = [NSCountedSet new], *theirEmoji = [NSCountedSet new], *myWords = [NSCountedSet new];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateFormatter *df = [NSDateFormatter new]; df.dateFormat = @"yyyy-MM-dd"; df.timeZone = cal.timeZone;
    NSSet *stop = IStop();
    while (sqlite3_step(st) == SQLITE_ROW) {
        int assoc = sqlite3_column_int(st, 5);
        if (assoc >= 2000 && assoc < 4000) { reactions++; continue; }   // tapbacks
        total++;
        BOOL me = sqlite3_column_int(st, 2) != 0;
        if (me) mine++; else theirs++;
        if (sqlite3_column_int(st, 4)) voice++;
        sqlite3_int64 raw = sqlite3_column_int64(st, 3);
        double secs = raw > 100000000000LL ? raw / 1e9 : (double)raw;
        NSDate *d = [NSDate dateWithTimeIntervalSinceReferenceDate:secs];
        if (secs > 0) {
            if (!first || secs < first) first = secs;
            if (secs > last) last = secs;
            NSDateComponents *c = [cal components:NSCalendarUnitWeekday | NSCalendarUnitHour fromDate:d];
            wd[(c.weekday + 5) % 7]++;   // Monday first
            hr[c.hour % 24]++;
            [days addObject:[df stringFromDate:d]];
        }
        NSString *text = nil;
        const unsigned char *t = sqlite3_column_text(st, 0);
        if (t) text = @((const char *)t);
        if (!text.length) text = IBody(sqlite3_column_blob(st, 1), sqlite3_column_bytes(st, 1));
        if (!text.length) continue;
        text = [text stringByReplacingOccurrencesOfString:@"￼" withString:@""];
        if (me) myChars += text.length;
        NSCountedSet *es = me ? myEmoji : theirEmoji;
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *g, NSRange r, NSRange er, BOOL *stopIt) {
            if (IIsEmoji(g)) [es addObject:[g stringByReplacingOccurrencesOfString:@"️" withString:@""]];
        }];
        if (me) [text.lowercaseString enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByWords usingBlock:^(NSString *w, NSRange r, NSRange er, BOOL *stopIt) {
            if (w.length >= 3 && w.length <= 18 && ![stop containsObject:w] && [w rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location == NSNotFound) [myWords addObject:w];
        }];
    }
    sqlite3_finalize(st);

    // photos / videos / other files
    long photos = 0, videos = 0, files = 0, myPhotos = 0;
    NSString *aq = [NSString stringWithFormat:@"SELECT a.mime_type, m.is_from_me FROM attachment a JOIN message_attachment_join maj ON maj.attachment_id = a.ROWID JOIN message m ON m.ROWID = maj.message_id JOIN chat_message_join cmj ON cmj.message_id = m.ROWID WHERE 1=1%@", where];
    if (sqlite3_prepare_v2(db, aq.UTF8String, -1, &st, NULL) == SQLITE_OK) {
        if (!all) sqlite3_bind_text(st, 1, chatId.UTF8String, -1, SQLITE_TRANSIENT);
        while (sqlite3_step(st) == SQLITE_ROW) {
            const unsigned char *mt = sqlite3_column_text(st, 0);
            NSString *m = mt ? @((const char *)mt) : @"";
            if ([m hasPrefix:@"image/"]) { photos++; if (sqlite3_column_int(st, 1)) myPhotos++; }
            else if ([m hasPrefix:@"video/"]) videos++;
            else if (![m hasPrefix:@"audio/"] && m.length) files++;
        }
        sqlite3_finalize(st);
    }
    // the people you talk to most (all chats only)
    NSMutableArray *top = [NSMutableArray array];
    if (all && sqlite3_prepare_v2(db, "SELECT c.chat_identifier, MAX(c.display_name), COUNT(*) AS n FROM chat c JOIN chat_message_join cmj ON cmj.chat_id = c.ROWID GROUP BY c.chat_identifier ORDER BY n DESC LIMIT 10", -1, &st, NULL) == SQLITE_OK) {
        while (sqlite3_step(st) == SQLITE_ROW) {
            const unsigned char *ci = sqlite3_column_text(st, 0), *dn = sqlite3_column_text(st, 1);
            [top addObject:@{@"id": ci ? @((const char *)ci) : @"", @"name": dn ? @((const char *)dn) : @"", @"count": @(sqlite3_column_int64(st, 2))}];
        }
        sqlite3_finalize(st);
    }
    sqlite3_close(db);

    NSArray *(^topN)(NSCountedSet *, NSUInteger) = ^NSArray *(NSCountedSet *s, NSUInteger n) {
        NSArray *o = [s.allObjects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) { NSUInteger x = [s countForObject:a], y = [s countForObject:b]; return x > y ? NSOrderedAscending : x < y ? NSOrderedDescending : [a compare:b]; }];
        NSMutableArray *r = [NSMutableArray array];
        for (id k in [o subarrayWithRange:NSMakeRange(0, MIN(n, o.count))]) [r addObject:@[k, @([s countForObject:k])]];
        return r;
    };
    NSArray *busiest = topN(days, 1).firstObject;
    NSMutableArray *wds = [NSMutableArray array], *hrs = [NSMutableArray array];
    for (int i = 0; i < 7; i++) [wds addObject:@(wd[i])];
    for (int i = 0; i < 24; i++) [hrs addObject:@(hr[i])];
    return @{@"chat": chatId ?: @"*", @"total": @(total), @"mine": @(mine), @"theirs": @(theirs), @"voice": @(voice), @"reactions": @(reactions),
             @"photos": @(photos), @"myPhotos": @(myPhotos), @"videos": @(videos), @"files": @(files), @"first": @(first), @"last": @(last),
             @"activeDays": @(days.count), @"weekdays": wds, @"hours": hrs, @"busiest": busiest ?: @[],
             @"myEmoji": topN(myEmoji, 8), @"theirEmoji": topN(theirEmoji, 8), @"myWords": topN(myWords, 12), @"top": top,
             @"avgLen": @(mine ? (double)myChars / mine : 0), @"made": @([NSDate date].timeIntervalSince1970)};
}

static void IRequest(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef ui) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSDictionary *req = [NSDictionary dictionaryWithContentsOfFile:IDIR @"/insights_req.plist"];
            NSString *chat = req[@"chat"] ?: @"*";
            NSDictionary *res = nil;
            @try { res = IInsights(chat); } @catch (NSException *e) { res = @{@"error": e.reason ?: @"failed"}; }
            NSMutableDictionary *r = [res mutableCopy]; r[@"req"] = req[@"id"] ?: @"";
            [[NSFileManager defaultManager] createDirectoryAtPath:IDIR withIntermediateDirectories:YES attributes:nil error:nil];
            [r writeToFile:IDIR @"/insights_res.plist" atomically:YES];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.nano.messages26/insights.done"), NULL, NULL, YES);
        }
    });
}
__attribute__((constructor)) static void IInit(void) {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, IRequest, CFSTR("com.nano.messages26/insights.req"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
