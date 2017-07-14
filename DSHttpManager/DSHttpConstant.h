//
//  DSHttpConstant.h
//  DSHttpManager
//
//  Created by Derrick on 2017/7/14.
//  Copyright © 2017年 Derrick. All rights reserved.
//  接口配置文件

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 服务器返回的errorcode
typedef NS_ENUM(NSUInteger,HttpErrorCode) {
    HttpErrorCodeSuccess = 200,
    HttpErrorCodeFail = 300
};

// 服务器域名
UIKIT_EXTERN NSString * const API_HOST;


// 登录
UIKIT_EXTERN NSString *const login;

