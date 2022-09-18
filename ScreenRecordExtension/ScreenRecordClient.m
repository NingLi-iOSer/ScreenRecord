//
//  ScreenRecordClient.m
//  ScreenRecordExtension
//
//  Created by lining on 2022/9/17.
//

#import "ScreenRecordClient.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#include <netinet/in.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

@interface ScreenRecordClient () <GCDAsyncSocketDelegate>

@end

@implementation ScreenRecordClient {
    GCDAsyncSocket *_client;
    NSString *_destinationIP;
    uint16_t _destinationPort;
    dispatch_queue_t _delegateQueue;
    dispatch_queue_t _socketQueue;
}

+ (instancetype)shareInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _destinationIP = @"localhost";
        _destinationPort = 20001;
    }
    return self;
}

- (NSError *)startService {
    _delegateQueue = dispatch_queue_create("com.lining.screenrecordextension.delegatequeue", DISPATCH_QUEUE_SERIAL);
    _socketQueue = dispatch_queue_create("com.lining.screenrecordextension.socketqueue", DISPATCH_QUEUE_SERIAL);
    _client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegateQueue socketQueue:_socketQueue];
    [_client enableBackgroundingOnSocket];
    
    NSError *error;
    [_client connectToHost:_destinationIP onPort:_destinationPort withTimeout:1.5 error:&error];
    if (error) {
        NSLog(@"SR_ socket connect failed, error: %@", error);
        [self releaseResource];
        NSError *errorMessage = SRError(SRScreenShareExtensionErrorInitFailed, @"屏幕录制初始化失败");
        return errorMessage;
    }
    return nil;
}

- (void)sendAudioData:(SRAudioInfo *)audioInfo {
    if (!_client.isConnected || !audioInfo.data) {
        return;
    }
    AudioStreamBasicDescription desc = audioInfo.desc;
    NSData *header = [[NSData alloc] initWithBytes:&desc length:sizeof(desc)];
    [_client writeData:header withTimeout:-1 tag:0];
    [_client writeData:audioInfo.data withTimeout:-1 tag:1];
}

- (void)stopService {
    if (_client) {
        [_client disconnect];
        [self releaseResource];
    }
}

- (void)releaseResource {
    NSLog(@"SR_ client release.");
    _client.delegate = nil;
    _client = nil;
    _delegateQueue = NULL;
    _socketQueue = NULL;
}

static inline NSError* SRError(NSInteger errorCode, NSString *description) {
    NSErrorDomain domain = @"com.lining.screenshareextension";
    NSError *error = [[NSError alloc] initWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey: description}];
    return error;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"SR_ connect success.");
    [_client readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"SR_ disconnect, err: %@.", err);
    if (err) {
        if ([self.delegate respondsToSelector:@selector(client:didDisconnectWithError:)]) {
            NSError *newError = SRError(SRScreenShareExtensionErrorStop, @"屏幕共享已结束");
            [self.delegate client:self didDisconnectWithError:newError];
        }
    }
    [self releaseResource];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (!data) {
        return;
    }
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([str isEqualToString:@"1"]) {
        [self stopService];
        if ([self.delegate respondsToSelector:@selector(client:didDisconnectWithError:)]) {
            NSError *newError = SRError(SRScreenShareExtensionErrorStop, @"屏幕共享已结束");
            [self.delegate client:self didDisconnectWithError:newError];
        }
    }
}

@end
