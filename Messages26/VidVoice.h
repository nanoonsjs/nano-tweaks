// ===================== Messages26: voice messages =====================
// 1.4.5: forwarding a voice message sends Apple's voice message bubble again (not a .caf file), and
// "Video as Voice" in the + menu sends the sound of a video from your library as a voice message.
// Included from Tweak.x before %ctor.
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>

// a media object of ours made from a file, the way Messages makes one when you attach something
static id VVMediaObject(NSURL *url) {
    Class M = NSClassFromString(@"CKMediaObjectManager");
    id mgr = [M respondsToSelector:@selector(sharedInstance)] ? [M performSelector:@selector(sharedInstance)] : nil;
    SEL s = NSSelectorFromString(@"mediaObjectWithFileURL:filename:transcoderUserInfo:");
    if (!mgr || ![mgr respondsToSelector:s]) return nil;
    return ((id (*)(id, SEL, id, id, id))objc_msgSend)(mgr, s, url, nil, nil);
}
static id VVAudioComposition(id mo) {
    Class C = NSClassFromString(@"CKComposition");
    SEL s = NSSelectorFromString(@"audioCompositionWithMediaObject:");
    if (!mo || ![C respondsToSelector:s]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(C, s, mo);
}
static NSURL *VVTempURL(NSString *ext) {
    // its own folder, named like the voice messages Messages records ("Audio Message.caf")
    NSString *dir = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"m26voice"] stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:[@"Audio Message." stringByAppendingString:ext]]];
}

#pragma mark - forwarding keeps it a voice message

// A forwarded composition holding a single audio file becomes a voice message composition again.
static id VVFixForward(id comp) {
    @try {
        if (!comp) return comp;
        SEL ia = NSSelectorFromString(@"isAudioComposition");
        if ([comp respondsToSelector:ia] && ((BOOL (*)(id, SEL))objc_msgSend)(comp, ia)) return comp;
        NSArray *mos = [comp valueForKey:@"mediaObjects"];
        if (![mos isKindOfClass:[NSArray class]] || mos.count != 1) return comp;
        id mo = mos.firstObject;
        Class A = NSClassFromString(@"CKAudioMediaObject");
        NSURL *u = [mo respondsToSelector:@selector(fileURL)] ? [mo valueForKey:@"fileURL"] : nil;
        BOOL audio = (A && [mo isKindOfClass:A]) || [u.pathExtension.lowercaseString isEqualToString:@"caf"];
        if (!audio || !u) return comp;
        // text typed with it would be lost: only a bare audio file is turned back into a voice message
        id text = nil; @try { text = [comp valueForKey:@"text"]; } @catch (__unused id e) {}
        NSString *ts = [text isKindOfClass:[NSAttributedString class]] ? [text string] : [text isKindOfClass:[NSString class]] ? text : nil;
        if ([ts stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \n￼"]].length) return comp;
        NSURL *copy = VVTempURL(u.pathExtension.length ? u.pathExtension : @"caf");
        if (![[NSFileManager defaultManager] copyItemAtURL:u toURL:copy error:nil]) copy = u;
        id nc = VVAudioComposition(VVMediaObject(copy) ?: mo);
        return nc ?: comp;
    } @catch (__unused id e) { return comp; }
}
static void (*origFwdComp)(id, SEL, id, id);
static void FwdComp(id self, SEL _cmd, id chat, id comp) {
    origFwdComp(self, _cmd, chat, gOn ? VVFixForward(comp) : comp);
}
static void (*origShowNewComp)(id, SEL, id, id, BOOL);
static void ShowNewComp(id self, SEL _cmd, id rec, id comp, BOOL anim) {
    origShowNewComp(self, _cmd, rec, gOn ? VVFixForward(comp) : comp, anim);
}

// 1.4.6: the forward sheet builds its own composition when you hit send, so the fix is made right as the
// message is created from it
static id (*origMsgWithComp)(id, SEL, id);
static id MsgWithComp(id self, SEL _cmd, id comp) { return origMsgWithComp(self, _cmd, gOn ? VVFixForward(comp) : comp); }
static id (*origMsgsFromComp)(id, SEL, id);
static id MsgsFromComp(id self, SEL _cmd, id comp) { return origMsgsFromComp(self, _cmd, gOn ? VVFixForward(comp) : comp); }

#pragma mark - a video's sound as a voice message

static UIViewController *VVChat(void) {
    UIResponder *r = gEntry;
    Class CC = NSClassFromString(@"CKChatController");
    while (r) { if (CC && [r isKindOfClass:CC]) return (UIViewController *)r; r = r.nextResponder; }
    return nil;
}
// the video's sound, as AAC in a .caf like the voice messages Messages records
static void VVExtract(NSURL *video, void (^done)(NSURL *out, NSString *err)) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video options:nil];
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (!track) { done(nil, @"That has no sound"); return; }
        NSError *e = nil;
        AVAssetReader *rd = [AVAssetReader assetReaderWithAsset:asset error:&e];
        AVAssetReaderTrackOutput *ro = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:@{AVFormatIDKey: @(kAudioFormatLinearPCM), AVSampleRateKey: @48000, AVNumberOfChannelsKey: @2, AVLinearPCMBitDepthKey: @16, AVLinearPCMIsFloatKey: @NO, AVLinearPCMIsBigEndianKey: @NO, AVLinearPCMIsNonInterleaved: @NO}];
        if (!rd || ![rd canAddOutput:ro]) { done(nil, @"Couldn't read the video"); return; }
        [rd addOutput:ro];
        NSURL *out = VVTempURL(@"caf");
        AVAssetWriter *wr = [AVAssetWriter assetWriterWithURL:out fileType:AVFileTypeCoreAudioFormat error:&e];
        // Opus, like the voice messages Messages records; AAC if this phone can't write Opus
        AVAssetWriterInput *wi = nil;
        @try { wi = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:@{AVFormatIDKey: @(kAudioFormatOpus), AVSampleRateKey: @48000, AVNumberOfChannelsKey: @2, AVEncoderBitRateKey: @160000}]; } @catch (__unused id x) { wi = nil; }
        if (!wi || !wr || ![wr canAddInput:wi]) {
            @try { wi = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:@{AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @48000, AVNumberOfChannelsKey: @2, AVEncoderBitRateKey: @256000}]; } @catch (__unused id x) { wi = nil; }
        }
        wi.expectsMediaDataInRealTime = NO;
        if (!wi || !wr || ![wr canAddInput:wi]) { done(nil, @"Couldn't make the voice message"); return; }
        [wr addInput:wi];
        if (![rd startReading] || ![wr startWriting]) { done(nil, @"Couldn't make the voice message"); return; }
        [wr startSessionAtSourceTime:kCMTimeZero];
        dispatch_queue_t q = dispatch_queue_create("m26.vv", DISPATCH_QUEUE_SERIAL);
        [wi requestMediaDataWhenReadyOnQueue:q usingBlock:^{
            while (wi.readyForMoreMediaData) {
                CMSampleBufferRef sb = [ro copyNextSampleBuffer];
                if (sb) { [wi appendSampleBuffer:sb]; CFRelease(sb); continue; }
                [wi markAsFinished];
                BOOL ok = rd.status == AVAssetReaderStatusCompleted;
                [wr finishWritingWithCompletionHandler:^{ done(ok && wr.status == AVAssetWriterStatusCompleted ? out : nil, @"Couldn't make the voice message"); }];
                break;
            }
        }];
    });
}
static void VVSend(NSURL *audio) {
    UIViewController *chat = VVChat();
    id comp = VVAudioComposition(VVMediaObject(audio));
    if (!chat || !comp) { Toast(@"Open a chat first", @"exclamationmark.circle.fill"); return; }
    @try {
        SEL s = NSSelectorFromString(@"sendComposition:");
        if ([chat respondsToSelector:s]) { ((void (*)(id, SEL, id))objc_msgSend)(chat, s, comp); return; }
    } @catch (__unused id e) {}
    Toast(@"Couldn't send", @"exclamationmark.circle.fill");
}

@interface M26VVPicker : NSObject <PHPickerViewControllerDelegate>
@end
@implementation M26VVPicker
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    static M26VVPicker *keep; keep = self;
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSItemProvider *p = results.firstObject.itemProvider;
    if (!p) { keep = nil; return; }
    NSString *type = @"public.movie";
    if (![p hasItemConformingToTypeIdentifier:type]) { keep = nil; return; }
    Toast(@"Making voice message…", @"waveform");
    [p loadFileRepresentationForTypeIdentifier:type completionHandler:^(NSURL *url, NSError *err) {
        // the file is only there during this block: copy it first
        NSURL *copy = url ? VVTempURL(url.pathExtension.length ? url.pathExtension : @"mov") : nil;
        if (!copy || ![[NSFileManager defaultManager] copyItemAtURL:url toURL:copy error:nil]) {
            dispatch_async(dispatch_get_main_queue(), ^{ Toast(@"Couldn't open the video", @"exclamationmark.circle.fill"); keep = nil; });
            return;
        }
        VVExtract(copy, ^(NSURL *out, NSString *msg) {
            [[NSFileManager defaultManager] removeItemAtURL:copy error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (out) VVSend(out); else Toast(msg, @"exclamationmark.circle.fill");
                keep = nil;
            });
        });
    }];
}
@end
static M26VVPicker *gVVDelegate;
#pragma mark - File as Voice (1.8.2, Pro): an audio file (mp3, m4a, wav...) sent as a voice message

@interface M26FVPicker : NSObject <UIDocumentPickerDelegate>
@end
@implementation M26FVPicker
- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *u = urls.firstObject; if (!u) return;
    BOOL sec = [u startAccessingSecurityScopedResource];
    NSURL *copy = VVTempURL(u.pathExtension.length ? u.pathExtension : @"m4a");
    BOOL ok = [[NSFileManager defaultManager] copyItemAtURL:u toURL:copy error:nil];
    if (sec) [u stopAccessingSecurityScopedResource];
    if (!ok) { Toast(@"Couldn't open that file", @"exclamationmark.circle.fill"); return; }
    Toast(@"Making voice message…", @"waveform");
    VVExtract(copy, ^(NSURL *out, NSString *msg) {
        [[NSFileManager defaultManager] removeItemAtURL:copy error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{ if (out) VVSend(out); else Toast(msg, @"exclamationmark.circle.fill"); });
    });
}
@end
static M26FVPicker *gFVDelegate;
static void FileVoicePick(void) {
    UIWindow *w = gEntry.window ?: [UIApplication sharedApplication].keyWindow;
    NSArray *types = @[@"public.audio", @"public.mp3", @"public.mpeg-4-audio", @"com.microsoft.waveform-audio", @"public.aiff-audio", @"com.apple.coreaudio-format", @"public.movie"];
    UIDocumentPickerViewController *dp = nil;
    if (@available(iOS 14.0, *)) {
        NSMutableArray *ut = [NSMutableArray array];
        Class UT = NSClassFromString(@"UTType");
        for (NSString *s in types) { id t = [UT respondsToSelector:@selector(typeWithIdentifier:)] ? [UT performSelector:@selector(typeWithIdentifier:) withObject:s] : nil; if (t) [ut addObject:t]; }
        dp = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:ut asCopy:YES];
    } else dp = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    gFVDelegate = [M26FVPicker new]; dp.delegate = gFVDelegate;
    [w endEditing:YES];
    [TopVC(w) presentViewController:dp animated:YES completion:nil];
}
// the + menu icon (1.8.3: nano's blue glass file-with-waveform)
static UIImage *FileVoiceIcon(void) {
    static UIImage *img;
    if (!img) img = [UIImage imageWithData:[NSData dataWithBytes:kIc_filevoice length:sizeof(kIc_filevoice)] scale:3];
    return img;
}
static void VidVoicePick(void) {
    UIWindow *w = gEntry.window ?: [UIApplication sharedApplication].keyWindow;
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.filter = [PHPickerFilter videosFilter];
    cfg.selectionLimit = 1;
    cfg.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCurrent;
    PHPickerViewController *pk = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    gVVDelegate = [M26VVPicker new];
    pk.delegate = gVVDelegate;
    [w endEditing:YES];
    [TopVC(w) presentViewController:pk animated:YES completion:nil];
}
static void StartVidVoice(void) {
    Class MC = NSClassFromString(@"CKMessagesController");
    SEL a = NSSelectorFromString(@"chatController:forwardComposition:");
    SEL b = NSSelectorFromString(@"showNewMessageCompositionPanelWithRecipients:composition:animated:");
    if (MC && class_getInstanceMethod(MC, a)) MSHookMessageEx(MC, a, (IMP)FwdComp, (IMP *)&origFwdComp);
    if (MC && class_getInstanceMethod(MC, b)) MSHookMessageEx(MC, b, (IMP)ShowNewComp, (IMP *)&origShowNewComp);
    Class CV = NSClassFromString(@"CKConversation");
    SEL c = NSSelectorFromString(@"messageWithComposition:"), d = NSSelectorFromString(@"messagesFromComposition:");
    if (CV && class_getInstanceMethod(CV, c)) MSHookMessageEx(CV, c, (IMP)MsgWithComp, (IMP *)&origMsgWithComp);
    if (CV && class_getInstanceMethod(CV, d)) MSHookMessageEx(CV, d, (IMP)MsgsFromComp, (IMP *)&origMsgsFromComp);
}
