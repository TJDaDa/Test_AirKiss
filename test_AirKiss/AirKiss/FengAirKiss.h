//
//  LarkSmartConfig.h
//  AirKiss
//
//  Created by Feng on 2018/11/22.
//  Copyright © 2018年 Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FengAirKissDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^AirKissConnectionSuccess) (void);
typedef void (^AirKissConnectionFailure) (void);

@interface FengAirKiss: NSObject

@property(nonatomic,copy) AirKissConnectionSuccess connectionSuccess;
@property(nonatomic,copy) AirKissConnectionFailure connectionFailure;
@property(nonatomic,copy) NSString *mac;

/**
 *  AirKiss连接
 *
 *  @param ssid ssid
 *  @param password  psw
 */
- (LarkResutCode)connectAirKissWithSSID:(NSString *)ssid
                      password:(NSString *)password;

- (void)closeConnection;

@end

NS_ASSUME_NONNULL_END
