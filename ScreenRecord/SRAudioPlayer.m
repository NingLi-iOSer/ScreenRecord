//
//  SRAudioPlayer.m
//  ScreenRecord
//
//  Created by lining on 2022/9/17.
//

#import "SRAudioPlayer.h"
#import <AudioUnit/AudioUnit.h>

const uint32_t CONST_BUFFER_SIZE = 0x10000;
#define INPUT_BUS 1
#define OUTPUT_BUS 0

@interface SRAudioPlayer ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation SRAudioPlayer {
    AudioUnit audioUnit;
    AudioBufferList *bufferList;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self registerNotify];
    }
    return self;
}

- (void)registerNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)dealloc {
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    
    if (bufferList != NULL) {
        if (bufferList->mBuffers[0].mData) {
            free(bufferList->mBuffers[0].mData);
            bufferList->mBuffers[0].mData = NULL;
        }
        free(bufferList);
        bufferList = NULL;
    }
}

#pragma mark - Notify

- (void)applicationWillTerminate {
    [self stop];
}

#pragma mark - Public Methods

- (void)playWithFilePath:(NSString *)filePath audioDesc:(AudioStreamBasicDescription)audioDesc {
    [self initPlayer:audioDesc];
    [self openInputStream:filePath];
    AudioOutputUnitStart(audioUnit);
}

#pragma mark - Private Methods

- (void)openInputStream:(NSString *)filePath {
    _inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    if (!_inputStream) {
        NSLog(@"SR_ open file failed.");
        return;
    } else {
        [_inputStream open];
    }
}

- (void)initPlayer:(AudioStreamBasicDescription)outputDesc {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    AudioComponentDescription audioDesc = {0};
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &audioUnit);
    
    bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    bufferList->mNumberBuffers = 1;
    bufferList->mBuffers[0].mNumberChannels = 1;
    bufferList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
    bufferList->mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
    
    UInt32 flag = 1;
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output,
                                           OUTPUT_BUS,
                                           &flag,
                                           sizeof(flag));
    if (status) {
        NSLog(@"SR_ Audio unit set property output failed, errorCode: %d.", status);
        return;
    }
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &outputDesc,
                                  sizeof(outputDesc));
    if (status) {
        NSLog(@"SR_ Audio unit set property input failed, errorCode: %d.", status);
        return;
    }
    
    AURenderCallbackStruct playCallback = {0};
    playCallback.inputProc = SRPlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &playCallback,
                                  sizeof(playCallback));
    if (status) {
        NSLog(@"SR_ Audio unit set property renderCallback failed, errorCode: %d.", status);
        return;
    }
    
    status = AudioUnitInitialize(audioUnit);
    NSLog(@"SR_ Audio unit init result: %d", status);
}

OSStatus SRPlayCallback(void *inRefCon,
                        AudioUnitRenderActionFlags *ioActionFlags,
                        const AudioTimeStamp *inTimeStamp,
                        UInt32 inBusNumber,
                        UInt32 inNumberFrames,
                        AudioBufferList * __nullable ioData) {
    SRAudioPlayer *player = (__bridge SRAudioPlayer *)inRefCon;
    ioData->mBuffers[0].mDataByteSize = (UInt32)[player.inputStream read:ioData->mBuffers[0].mData maxLength:ioData->mBuffers[0].mDataByteSize];
    if (ioData->mBuffers[0].mDataByteSize <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
    }
    return noErr;
}

- (void)stop {
    AudioOutputUnitStop(audioUnit);
    if (bufferList != NULL) {
        if (bufferList->mBuffers[0].mData) {
            free(bufferList->mBuffers[0].mData);
            bufferList->mBuffers[0].mData = NULL;
        }
        free(bufferList);
        bufferList = NULL;
    }
    
    [self.inputStream close];
}

@end
