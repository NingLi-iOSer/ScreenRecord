//
//  SRAudioHandler.h
//  ScreenRecordExtension
//
//  Created by lining on 2022/9/17.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRAudioInfo : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) AudioStreamBasicDescription desc;

- (instancetype)initWithData:(NSData *)data desc:(AudioStreamBasicDescription)desc;

@end

@interface SRAudioHandler : NSObject

+ (SRAudioInfo *)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
