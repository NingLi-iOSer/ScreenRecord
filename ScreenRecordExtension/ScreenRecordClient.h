//
//  ScreenRecordClient.h
//  ScreenRecordExtension
//
//  Created by lining on 2022/9/17.
//

#import <Foundation/Foundation.h>
#import "SRAudioHandler.h"

@class ScreenRecordClient;

typedef NS_ENUM(NSInteger, SRScreenShareExtensionError) {
    SRScreenShareExtensionErrorInitFailed = 100,
    SRScreenShareExtensionErrorStop
};

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenRecordClientDelegate <NSObject>

- (void)client:(ScreenRecordClient *)client didDisconnectWithError:(NSError *)error;

@end

@interface ScreenRecordClient : NSObject

@property (nonatomic, weak) id<ScreenRecordClientDelegate> delegate;

+ (instancetype)shareInstance;

- (NSError * _Nullable)startService;

- (void)sendAudioData:(SRAudioInfo *)audioInfo;

- (void)stopService;

@end

NS_ASSUME_NONNULL_END
