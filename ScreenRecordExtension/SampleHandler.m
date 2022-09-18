//
//  SampleHandler.m
//  ScreenRecordExtension
//
//  Created by lining on 2022/9/16.
//


#import "SampleHandler.h"
#import "ScreenRecordClient.h"
#import "SRAudioHandler.h"

@interface SampleHandler () <ScreenRecordClientDelegate>

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    NSError *error = [[ScreenRecordClient shareInstance] startService];
    if (error) {
        [self finishBroadcastWithError:error];
        return;
    }
    [ScreenRecordClient shareInstance].delegate = self;
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    [[ScreenRecordClient shareInstance] stopService];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            break;
        case RPSampleBufferTypeAudioApp: {
            @autoreleasepool {
                SRAudioInfo *audioInfo = [SRAudioHandler handleSampleBuffer:sampleBuffer];
                [[ScreenRecordClient shareInstance] sendAudioData:audioInfo];
            }
        }
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

#pragma mark - ScreenRecordClientDelegate

- (void)client:(ScreenRecordClient *)client didDisconnectWithError:(NSError *)error {
    [self finishBroadcastWithError:error];
}

@end
