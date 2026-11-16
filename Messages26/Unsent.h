// ===================== Messages26: Keep Unsent Messages =====================
// M26Keeper (in imagent) saves a message right before an unsend wipes it. Here "X unsent a message" gets the
// original text under it, and Messages26 settings list them all (photos / videos / files open from there).
// Included from Tweak.x before %ctor.
#import <QuickLook/QuickLook.h>

#define UNSENT_DIR @"/var/mobile/Library/SMS/M26Unsent"
#define UNSENT_LIST UNSENT_DIR @"/unsent.plist"

static NSDictionary *gUnsent; static NSDate *gUnsentAt;
static NSDictionary *UnsentAll(void) {
    NSDate *m = [[NSFileManager defaultManager] attributesOfItemAtPath:UNSENT_LIST error:nil][NSFileModificationDate];
    if (!gUnsent || (m && ![m isEqualToDate:gUnsentAt])) {
        gUnsent = [NSDictionary dictionaryWithContentsOfFile:UNSENT_LIST] ?: @{};
        gUnsentAt = m;
    }
    return gUnsent;
}
static NSArray *UnsentRows(void) {
    NSMutableArray *a = [NSMutableArray array];
    [UnsentAll() enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSDictionary *d, BOOL *stop) {
        if (![d isKindOfClass:[NSDictionary class]]) return;
        NSMutableDictionary *r = [d mutableCopy]; r[@"guid"] = k; [a addObject:r];
    }];
    [a sortUsingComparator:^NSComparisonResult(NSDictionary *x, NSDictionary *y) { return [y[@"unsentAt"] compare:x[@"unsentAt"]]; }];
    return a;
}
static void UnsentRemove(NSString *guid) {
    NSMutableDictionary *all = [UnsentAll() mutableCopy];
    [all removeObjectForKey:guid];
    [all writeToFile:UNSENT_LIST atomically:YES];
    [[NSFileManager defaultManager] removeItemAtPath:[UNSENT_DIR stringByAppendingPathComponent:guid] error:nil];
    gUnsent = nil;
}

#pragma mark - "X unsent a message" shows what it said

static id (*origRetractText)(id, SEL, unsigned long long, id, BOOL, BOOL, id);
static id RetractText(id self, SEL _cmd, unsigned long long cnt, id names, BOOL fromMe, BOOL failed, id sender) {
    id s = origRetractText(self, _cmd, cnt, names, fromMe, failed, sender);
    if (fromMe || failed || !Opt(@"keepunsent") || !ProUnlocked() || ![s isKindOfClass:[NSAttributedString class]]) return s;
    @try {
        id im = [self valueForKey:@"imMessageRetractionChatItem"];
        NSString *guid = [im valueForKey:@"messageGUID"];
        NSDictionary *d = guid ? UnsentAll()[guid] : nil;
        if (!d) return s;
        NSString *text = d[@"text"];
        NSUInteger nf = [d[@"files"] count];
        NSString *extra = text.length ? [NSString stringWithFormat:@"\n“%@”", text] : @"";
        if (nf) extra = [extra stringByAppendingFormat:@"\n%lu attachment%@ kept · Messages26 settings", (unsigned long)nf, nf == 1 ? @"" : @"s"];
        if (!extra.length) return s;
        NSMutableAttributedString *m = [s mutableCopy];
        NSDictionary *attrs = m.length ? [m attributesAtIndex:0 effectiveRange:NULL] : @{};
        NSMutableDictionary *a2 = [attrs mutableCopy];
        UIFont *f = attrs[NSFontAttributeName];
        if (f) a2[NSFontAttributeName] = [UIFont italicSystemFontOfSize:f.pointSize];
        [m appendAttributedString:[[NSAttributedString alloc] initWithString:extra attributes:a2]];
        return m;
    } @catch (__unused id e) { return s; }
}

#pragma mark - the list in settings

@interface M26UnsentVC : UITableViewController <QLPreviewControllerDataSource>
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NSArray *preview;
@end
@implementation M26UnsentVC
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Unsent Messages"; self.rows = [UnsentRows() mutableCopy];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.text.magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(showLog)];
}
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return MAX(1, self.rows.count); }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return @"Messages people unsent after this was turned on. Tap one to copy it (or open what was attached), swipe to delete."; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    if (!self.rows.count) { c.textLabel.text = @"No unsent messages yet"; c.textLabel.textColor = UIColor.secondaryLabelColor; return c; }
    NSDictionary *d = self.rows[ip.row];
    NSUInteger nf = [d[@"files"] count];
    NSString *t = [d[@"text"] length] ? d[@"text"] : nf ? [NSString stringWithFormat:@"📎 %lu attachment%@", (unsigned long)nf, nf == 1 ? @"" : @"s"] : @"(empty)";
    if ([d[@"text"] length] && nf) t = [t stringByAppendingFormat:@"  📎 %lu", (unsigned long)nf];
    c.textLabel.text = t; c.textLabel.numberOfLines = 4;
    NSDateFormatter *f = [NSDateFormatter new]; f.doesRelativeDateFormatting = YES; f.dateStyle = NSDateFormatterShortStyle; f.timeStyle = NSDateFormatterShortStyle;
    NSString *who = [d[@"who"] length] ? d[@"who"] : @"Someone";
    NSString *chat = [d[@"chat"] length] && ![d[@"chat"] isEqualToString:who] ? [NSString stringWithFormat:@" in %@", d[@"chat"]] : @"";
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@%@ · unsent %@", who, chat, [f stringFromDate:[NSDate dateWithTimeIntervalSince1970:[d[@"unsentAt"] doubleValue]]]];
    c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    if (nf) c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (!self.rows.count) return;
    NSDictionary *d = self.rows[ip.row];
    NSMutableArray *urls = [NSMutableArray array];
    for (NSString *p in d[@"files"]) if ([[NSFileManager defaultManager] fileExistsAtPath:p]) [urls addObject:[NSURL fileURLWithPath:p]];
    if (urls.count) {
        self.preview = urls;
        QLPreviewController *q = [QLPreviewController new]; q.dataSource = self;
        [self presentViewController:q animated:YES completion:nil];
        return;
    }
    if ([d[@"text"] length]) { [UIPasteboard generalPasteboard].string = d[@"text"]; Toast(@"Copied", @"doc.on.doc.fill"); }
}
- (void)showLog {
    NSString *l = [NSString stringWithContentsOfFile:[UNSENT_DIR stringByAppendingPathComponent:@"log.txt"] encoding:NSUTF8StringEncoding error:nil] ?: @"(no log: the background part never ran)";
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Unsent log" message:[l substringFromIndex:l.length > 1500 ? l.length - 1500 : 0] preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) { [UIPasteboard generalPasteboard].string = l; }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)c { return self.preview.count; }
- (id<QLPreviewItem>)previewController:(QLPreviewController *)c previewItemAtIndex:(NSInteger)i { return self.preview[i]; }
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return self.rows.count > 0; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    UnsentRemove(self.rows[ip.row][@"guid"]);
    [self.rows removeObjectAtIndex:ip.row];
    [tv reloadData];
}
@end

// tells M26Keeper (in imagent) whether to keep unsends
static void UnsentSyncFlag(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:UNSENT_DIR withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *f = [UNSENT_DIR stringByAppendingPathComponent:@"on"];
    if (Opt(@"keepunsent") && ProUnlocked()) { if (![fm fileExistsAtPath:f]) [@"1" writeToFile:f atomically:YES encoding:NSUTF8StringEncoding error:nil]; }
    else [fm removeItemAtPath:f error:nil];
}
static void StartUnsent(void) {
    ProMigrate();
    UnsentSyncFlag();
    Class R = NSClassFromString(@"CKMessageRetractionChatItem");
    SEL s = NSSelectorFromString(@"_loadTranscriptTextWithRetractionUnsupportedCount:unsupportedNames:isFromMe:isFailedRetraction:senderName:");
    if (R && class_getInstanceMethod(R, s)) MSHookMessageEx(R, s, (IMP)RetractText, (IMP *)&origRetractText);
}
