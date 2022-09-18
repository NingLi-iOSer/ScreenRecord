//
//  ScreenRecordServer.m
//  ScreenRecord
//
//  Created by lining on 2022/9/17.
//

#import "ScreenRecordServer.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

static long const kSRHeaderKey = 0;
static long const kSRBodyKey = 1;

@interface ScreenRecordServer () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *client;

@end

@implementation ScreenRecordServer {
    NSString *_locationIP;
    uint16_t _locationPort;
    GCDAsyncSocket *_server;
    dispatch_queue_t _delegateQueue;
    dispatch_queue_t _socketQueue;
    AudioStreamBasicDescription audioDesc;
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
        _locationIP = @"localhost";
        _locationPort = 20001;
    }
    return self;
}

- (NSError *)startService {
    if (_server) {
        return nil;
    }
    _delegateQueue = dispatch_queue_create("com.lining.screenrecordextension.delegatequeue", DISPATCH_QUEUE_SERIAL);
    _socketQueue = dispatch_queue_create("com.lining.screenrecordextension.socketqueue", DISPATCH_QUEUE_SERIAL);
    _server = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_delegateQueue socketQueue:_socketQueue];
    _server.autoDisconnectOnClosedReadStream = YES;
    [_server enableBackgroundingOnSocket];
    
    NSError *error;
    BOOL ret = [_server acceptOnInterface:_locationIP port:_locationPort error:&error];
    if (error || !ret) {
        NSLog(@"SR_ server accept failed, error: %@.", error);
        [self releaseResource];
        NSError *errorMessage = SRError(SRScreenShareErrorInitFailed, @"共享屏幕初始化失败");
        return errorMessage;
    }
    return nil;
}

- (void)stopService {
    if (_server) {
        NSString *str = @"1";
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [self.client writeData:data withTimeout:-1 tag:1];
    }
}

- (void)releaseResource {
    _delegateQueue = NULL;
    _socketQueue = NULL;
    _server.delegate = nil;
    _server = nil;
    self.client = nil;
}

static inline NSError* SRError(NSInteger errorCode, NSString *description) {
    NSErrorDomain domain = @"com.lining.screenshare";
    NSError *error = [[NSError alloc] initWithDomain:domain code:errorCode userInfo:@{NSLocalizedDescriptionKey: description}];
    return error;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"SR_ client connect.");
    self.client = newSocket;
    [newSocket readDataWithTimeout:-1 tag:kSRHeaderKey];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"SR_ receive data.");
    if (!data) {
        return;
    }
    
    if (tag == kSRHeaderKey) {
        [data getBytes:&audioDesc length:sizeof(audioDesc)];
        [sock readDataWithTimeout:-1 tag:kSRBodyKey];
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(server:didReceiveAudioData:audioDesc:)]) {
        [self.delegate server:self didReceiveAudioData:data audioDesc:audioDesc];
    }
    [sock readDataWithTimeout:-1 tag:kSRHeaderKey];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"SR_ server disconnect, error: %@.", err);
    [self releaseResource];
}

@end
