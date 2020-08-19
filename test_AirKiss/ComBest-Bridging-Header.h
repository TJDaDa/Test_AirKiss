//
//  ComBest-Bridging-Header.h
//  ComBest
//
//  Created by huanjia on 2017/8/29.
//  Copyright © 2017年 huanjia. All rights reserved.
//

#ifndef ComBest_Bridging_Header_h
#define ComBest_Bridging_Header_h

//#import "UMessage.h"
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

//JShare
#import "JSHAREService.h"
#import "ShareView.h"

#import "Citys.h"
#import "CityPicker.h"
#import "BaiduMobStat.h"
#import "HYNoticeView.h"

//AirKiss配网
#import "FengAirKiss.h"
#import "JMAirKissShareTools.h"

//XMPP
#import "XMLReader.h"

#import <MOBFoundation/MOBFoundation.h>
#import <MobLink/MobLink.h>
#import <MobLink/MLSDKScene.h>
#import <MobLink/IMLSDKRestoreDelegate.h>
#import <MobLink/UIViewController+MLSDKRestore.h>
#import <SVProgressHUD/SVProgressHUD.h>

//RabbitMQ
#import <RMQClient/RMQClient.h>
#import "TJHexAndData.h"
#import "NSData+TJUTF8.h"
#import "AirSmartLinkVC.h"

//MJFooterManager
#import "UITableView+FooterManager.h"
#import "UICollectionView+FooterManager.h"

//AVPlayer
#import "WebPImage.h"

//ZFPlayer
#import "ZFPlayer.h"

#endif /* ComBest_Bridging_Header_h */
