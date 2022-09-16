//
//  ViewController.m
//  ScreenRecord
//
//  Created by lining on 2022/9/16.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ViewController ()

@property (nonatomic, strong) RPSystemBroadcastPickerView *broadcastPickerView;
@property (nonatomic, strong) UIButton *screenRecordButton;

@end

@implementation ViewController

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
}

- (void)screenRecordStateChanged:(UIButton *)sender {
    if (!sender.isSelected) {
        for (UIView *v in self.broadcastPickerView.subviews) {
            if ([v isKindOfClass:UIButton.class]) {
                [(UIButton *)v sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
    }
    
    sender.selected = !sender.isSelected;
}


@end
