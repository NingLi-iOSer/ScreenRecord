//
//  SRAudioHandler.m
//  ScreenRecordExtension
//
//  Created by lining on 2022/9/17.
//

#import "SRAudioHandler.h"

const int bufferSize = 48000;

@implementation SRAudioInfo

- (instancetype)initWithData:(NSData *)data desc:(AudioStreamBasicDescription)desc {
    self = [super init];
    if (self) {
        _data = data;
        _desc = desc;
    }
    return self;
}

@end

@implementation SRAudioHandler

+ (SRAudioInfo *)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CFRetain(sampleBuffer);
    OSStatus err = noErr;
    CMBlockBufferRef audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffset;
    size_t totalBytes;
    char *samples;
    err = CMBlockBufferGetDataPointer(audioBuffer,
                                      0,
                                      &lengthAtOffset,
                                      &totalBytes,
                                      &samples);
    
    if (totalBytes == 0) {
        CFRelease(sampleBuffer);
        return nil;
    }
    
    CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *description = CMAudioFormatDescriptionGetStreamBasicDescription(format);
    
    size_t dataPointerSize = 0;
    
    if (description->mChannelsPerFrame == 1) {
        dataPointerSize = bufferSize * 2;
    } else {
        dataPointerSize = bufferSize;
    }
    
    char dataPointer[dataPointerSize];
    err = CMBlockBufferCopyDataBytes(audioBuffer,
                                     0,
                                     totalBytes,
                                     dataPointer);
    
    size_t totalSamples = totalBytes / (description->mBitsPerChannel / 8);
    UInt32 channels = description->mChannelsPerFrame;
    
    if (description->mFormatFlags & kAudioFormatFlagIsFloat) {
        float* floatData = (float*)dataPointer;
        int16_t* intData = (int16_t*)dataPointer;
        for (int i = 0; i < totalSamples; i++) {
            float tmp = floatData[i] * 32767;
            intData[i] = (tmp >= 32767) ?  32767 : tmp;
            intData[i] = (tmp < -32767) ? -32767 : tmp;
        }
    }
    
    if (description->mFormatFlags & kAudioFormatFlagIsBigEndian) {
        uint8_t* p = (uint8_t*)dataPointer;
        for (int i = 0; i < totalBytes; i += 2) {
            uint8_t tmp;
            tmp = p[i];
            p[i] = p[i + 1];
            p[i + 1] = tmp;
        }
    }
    
    if (channels == 2) {
        totalSamples /= 2;
        int16_t* intData = (int16_t*)dataPointer;
        int16_t newBuffer[totalSamples];
        for (int i = 0; i < totalSamples; i++) {
            newBuffer[i] = (intData[2 * i] + intData[2 * i + 1]) / 2;
        }
        memcpy(dataPointer, newBuffer, sizeof(int16_t) * totalSamples);
    }
    
    NSData *resultData = [[NSData alloc] initWithBytes:dataPointer length:sizeof(int16_t) * totalSamples];
    CFRelease(sampleBuffer);
    
    AudioStreamBasicDescription desc = (*description);
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    desc.mChannelsPerFrame = 1;
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    desc.mBytesPerPacket = desc.mFramesPerPacket * desc.mBytesPerFrame;
    SRAudioInfo *audioInfo = [[SRAudioInfo alloc] initWithData:resultData desc:desc];
    return audioInfo;
}

@end
