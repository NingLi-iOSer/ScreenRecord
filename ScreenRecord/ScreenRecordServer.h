//
//  ScreenRecordServer.h
//  ScreenRecord
//
//  Created by lining on 2022/9/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class ScreenRecordServer;

typedef NS_ENUM(NSInteger, SRScreenShareError) {
    SRScreenShareErrorInitFailed = 1000
};

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenRecordServerDelegate <NSObject>

- (void)server:(ScreenRecordServer *)server didReceiveAudioData:(NSData *)data audioDesc:(AudioStreamBasicDescription)audioDesc;

@end

@interface ScreenRecordServer : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, weak) id<ScreenRecordServerDelegate> delegate;

- (NSError * _Nullable)startService;

- (void)stopService;

@end

NS_ASSUME_NONNULL_END
