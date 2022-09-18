//
//  ViewController.m
//  ScreenRecord
//
//  Created by lining on 2022/9/16.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import "ScreenRecordServer.h"
#import "SRAudioPlayer.h"

@interface ViewController () <ScreenRecordServerDelegate>

@property (nonatomic, strong) RPSystemBroadcastPickerView *broadcastPickerView;
@property (nonatomic, strong) UIButton *screenRecordButton;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) SRAudioPlayer *player;

@end

@implementation ViewController {
    AudioStreamBasicDescription _audioDesc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.broadcastPickerView = [[RPSystemBroadcastPickerView alloc] init];
    self.broadcastPickerView.preferredExtension = @"com.ln.ScreenRecord.ScreenRecordExtension";
    self.broadcastPickerView.showsMicrophoneButton = NO;
    
    self.screenRecordButton = [[UIButton alloc] init];
    [self.screenRecordButton setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.screenRecordButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.screenRecordButton setTitle:@"停止录制" forState:UIControlStateSelected];
    self.screenRecordButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.screenRecordButton.backgroundColor = UIColor.redColor;
    self.screenRecordButton.layer.cornerRadius = 4;
    self.screenRecordButton.frame = CGRectMake(0, 0, 80, 50);
    self.screenRecordButton.center = self.view.center;
    [self.screenRecordButton addTarget:self action:@selector(screenRecordStateChanged:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.screenRecordButton];
    
    UIButton *playButton = [[UIButton alloc] init];
    [playButton setTitle:@"开始播放" forState:UIControlStateNormal];
    [playButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [playButton setTitle:@"停止播放" forState:UIControlStateSelected];
    playButton.titleLabel.font = [UIFont systemFontOfSize:14];
    playButton.backgroundColor = UIColor.orangeColor;
    playButton.layer.cornerRadius = 4;
    playButton.frame = CGRectOffset(self.screenRecordButton.frame, 0, 100);
    [playButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    
    [ScreenRecordServer shareInstance].delegate = self;
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    self.filePath = [docDir stringByAppendingPathComponent:@"audio.pcm"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.filePath]) {
        [manager removeItemAtPath:self.filePath error:NULL];
    }
    [manager createFileAtPath:self.filePath contents:nil attributes:nil];
    
    self.player = [[SRAudioPlayer alloc] initWithFilePath:self.filePath];
}

- (void)screenRecordStateChanged:(UIButton *)sender {
    if (!sender.isSelected) {
        for (UIView *v in self.broadcastPickerView.subviews) {
            if ([v isKindOfClass:UIButton.class]) {
                [(UIButton *)v sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
        [[ScreenRecordServer shareInstance] startService];
    } else {
        [[ScreenRecordServer shareInstance] stopService];
    }
    
    sender.selected = !sender.isSelected;
}

- (void)playAudio:(UIButton *)sender {
    if (!sender.isSelected) {
        [self.player play:_audioDesc];
    } else {
        [self.player stop];
    }
    sender.selected = !sender.isSelected;
}

#pragma mark - ScreenRecordServerDelegate

- (void)server:(ScreenRecordServer *)server didReceiveAudioData:(NSData *)data audioDesc:(AudioStreamBasicDescription)audioDesc {
    _audioDesc = audioDesc;
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
    [handle closeFile];
}

@end
