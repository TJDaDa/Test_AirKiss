//
//  LarkSmartConfig.m
//  AirKiss
//
//  Created by Feng on 2018/11/22.
//  Copyright © 2018年 Feng. All rights reserved.
//

#import "FengAirKiss.h"
#import "GCDAsyncUdpSocket.h"
#import "FengAirkissEncoder.h"
#import "FengAirKissDefines.h"
#include <ifaddrs.h>
#import <arpa/inet.h>
#include <net/if.h>

#define kAirKiss_Port                    10000
#define kAirKiss_Host                    @"255.255.255.255"
#define kAirKiss_Limit_Return_Random_Num 20

@interface FengAirKiss()<GCDAsyncUdpSocketDelegate>{
    
    FengAirkissEncoder *_airKissEncoder;
    NSTimer *_timer;          // 超过1分钟未连接成功则表示失败
    
    GCDAsyncUdpSocket *_clientUdpSocket;
    GCDAsyncUdpSocket *_serverUdpSocket;
    
    int _returnRandomNum;
    BOOL _connectionDone;
}

@end

@implementation FengAirKiss

- (instancetype)init {
    self = [super init];
    if (self) {
        _airKissEncoder = [[FengAirkissEncoder alloc] init];
        _returnRandomNum = 0;
        _connectionDone = NO;
        
        [self createClientUdpSocket];
        [self createServerUdpSocket];
    }
    return self;
}

#pragma mark - 创建 udp socket
- (LarkResutCode)createClientUdpSocket {
    NSError *error = nil;
    if (!_clientUdpSocket) {
        _clientUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_clientUdpSocket enableBroadcast:YES error:&error];
    }
    if (![_clientUdpSocket bindToPort:0 error:&error]){
        return LarkResutCodeCreatScocketFail;
    }
    if (![_clientUdpSocket beginReceiving:&error]){
        return LarkResutCodeCreatScocketFail;
    }
    return LarkResutCodeSuccess;
}

- (LarkResutCode)createServerUdpSocket {
    if (!_serverUdpSocket) {
        _serverUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_serverUdpSocket enableBroadcast:YES error:nil];
    }
    
    NSError *error = nil;
    if (![_serverUdpSocket bindToPort:kAirKiss_Port error:&error]){
        return LarkResutCodeCreatScocketFail;
    }
    
    if (![_serverUdpSocket beginReceiving:&error]){
        return LarkResutCodeCreatScocketFail;
    }
    return LarkResutCodeSuccess;
}

#pragma mark --开始配网
- (LarkResutCode)connectAirKissWithSSID:(NSString *)ssid password:(NSString *)password {
    _timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timeOutAction:) userInfo:nil repeats:NO];
    
    [self sendData:ssid psk:password];

    return LarkResutCodeSuccess;
}

#pragma mark --超时
-(void)timeOutAction:(NSTimer *)timer {
    [_timer invalidate];
    _timer = nil;
    
    _connectionDone = YES;
    
    [self closeConnection]; //停止配网
    if (_connectionFailure) {
        _connectionFailure();
    }
}

- (void)closeConnection {
    _connectionDone = YES;
    
    [_timer invalidate];
    _timer = nil;
    
    [_clientUdpSocket close];
    [_serverUdpSocket close];
    
    _clientUdpSocket = nil;
    _serverUdpSocket = nil;
}

#pragma mark --发送数据线程
-(void)sendData:(NSString *)ssid psk:(NSString *)psk{
    _returnRandomNum = 0;
    _connectionDone = NO;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *dataArry = [self->_airKissEncoder airKissEncorderWithSSID:ssid password:psk];
        while (1) {
            if (self->_connectionDone) {//已关闭或超时
                break;
            }
            [self sendWifi:dataArry];
            [NSThread sleepForTimeInterval:0.04];
        }
    });
}
#pragma mark --发送WIFI数据
-(void)sendWifi:(NSMutableArray *)dataArry{
    if (_connectionDone) {
        return;
    }
    for (int i = 0 ; i < dataArry.count; i++) {
        if (_connectionDone) {
            return;
        }
        LarkInt16_t  length = [dataArry[i] unsignedShortValue];
        NSMutableData *mData = [NSMutableData data];
        unsigned int value = 0;
        for (int j = 0; j < length; j++) {
            if (_connectionDone) {
                return;
            }
            [mData appendBytes:&value length:1];
        }
        [_clientUdpSocket sendData:mData
                                toHost:kAirKiss_Host
                                  port:kAirKiss_Port
                           withTimeout:-1
                                   tag:99999];
        [NSThread sleepForTimeInterval:0.004];
    }
}

#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    // 已发送的数据包 tag
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    // 发送失败的数据包 tag
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext{
        
    if (_serverUdpSocket == sock) {
        // 设备连接WIFI成功后会向10000端口发送至少20个UDP广播包所附带的随机数
        if (data != nil) {
            LarkInt8_t *bytes = (LarkInt8_t *)[data bytes];
            LarkInt8_t random = bytes[0];
//            NSLog(@"对比下两个: %hhd,   和  %hhd",bytes[0],_airKissEncoder.random);
            if (random == _airKissEncoder.random) {
                NSString *macAddress = [self getMacWithBytes:bytes];
                macAddress = [macAddress stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
//                NSLog(@"对比下两个地址: '%@' == '%@'", macAddress,self.mac);
                if ([macAddress isEqualToString:self.mac]) {
                    _returnRandomNum ++;
//                    NSLog(@"打印下成功数据报数: %d 的Mac地址: %@", _returnRandomNum, macAddress);
                }
                if (_returnRandomNum >= kAirKiss_Limit_Return_Random_Num) {
                    //成功之后不要停止配网, 不然配不上床垫
//                    [self closeConnection]; //停止配网
//                    [_timer invalidate];
//                    _timer = nil;
                    
                    if (_returnRandomNum == kAirKiss_Limit_Return_Random_Num) {
                        _connectionDone = YES;
                        if (_connectionSuccess) {
                            _connectionSuccess();
                        }
                    }
                }
            }
        }
    }
}

//截掉char的第一位 再转化为mac
- (NSString *)getMacWithBytes:(LarkInt8_t *)bytes {
    NSInteger len = strlen(bytes);
    LarkInt8_t orc[len-1];
    memset(orc, 0, len-1);
    for (int i=1; i<len; i++) {
//        NSLog(@"输出First: %hhd", first);
        orc[i-1] = bytes[i];
    }
    NSString *mac = [NSString stringWithFormat:@"%s",orc];
    return mac;
}

@end
