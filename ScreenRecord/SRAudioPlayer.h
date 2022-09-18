//
//  SRAudioPlayer.h
//  ScreenRecord
//
//  Created by lining on 2022/9/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRAudioPlayer : NSObject

- (void)playWithFilePath:(NSString *)filePath audioDesc:(AudioStreamBasicDescription)audioDesc;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
