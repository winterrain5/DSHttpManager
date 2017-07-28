//
//  DSHttpManager.h
//  DSHttpManager
//
//  Created by Derrick on 2017/7/14.
//  Copyright © 2017年 Derrick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define HttpManager [DSHttpManager shareInstance]

/**
 请求类型枚举
 */
typedef NS_ENUM(NSUInteger,DSHttpRequestType) {
    DSHttpRequestTypeGet = 0,
    DSHttpRequestTypePost,
    DSHttpRequestTypePut,
    DSHttpRequestTypePatch,
    DSHttpRequestTypeDelete
};

/**
 网络状态枚举
 */
typedef NS_ENUM(NSUInteger, DSNetworkStatus)
{
    /*! 未知网络 */
    DSNetworkStatusUnknown           = 0,
    /*! 没有网络 */
    DSNetworkStatusNotReachable,
    /*! 手机 3G/4G 网络 */
    DSNetworkStatusReachableViaWWAN,
    /*! wifi 网络 */
    DSNetworkStatusReachableViaWiFi
};

/// 请求成功block
typedef void (^DSResponseSuccessBlock)(id _Nullable response);

/// 缓存数据
typedef void (^DSCacheDataBlock)(id _Nullable response);

/// 请求失败block
typedef void (^DSResponseFailBlock)(NSError * _Nullable error);

/// 上传进度block
typedef void (^DSUploadProgressBlock)(double progress);

/// 下载进度block
typedef void (^DSDownloadProgressBlock)(int64_t bytesProgress,
                                        int64_t totalBytesProgress);
typedef void (^DSNetworkStatusBlock)(DSNetworkStatus status);

@interface DSHttpManager : NSObject

/// 超时时间
@property (nonatomic, assign) NSTimeInterval timeOut;


/// 单例方法
+ (instancetype _Nullable ) shareInstance;

#pragma mark - 请求方法
/**
 get请求

 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void)getWithUrlString:(NSString *_Nonnull)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *_Nullable)parameters
                cacheData:(DSCacheDataBlock _Nullable )cache
                  success:(DSResponseSuccessBlock _Nullable )success
                  failure:(DSResponseFailBlock _Nullable )failure;

// 不带cache
- (void)getWithUrlString:(NSString *_Nonnull)urlString
               parameters:(NSDictionary *_Nullable)parameters
                  success:(DSResponseSuccessBlock _Nullable )success
                  failure:(DSResponseFailBlock _Nullable )failure;
/**
 post请求
 
 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void)postWithUrlString:(NSString *_Nonnull)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *_Nullable)parameters
                 cacheData:(DSCacheDataBlock _Nullable )cache
                  success:(DSResponseSuccessBlock _Nullable )success
                  failure:(DSResponseFailBlock _Nullable )failure;

- (void)postWithUrlString:(NSString *_Nonnull)urlString
                parameters:(NSDictionary *_Nullable)parameters
                   success:(DSResponseSuccessBlock _Nullable )success
                   failure:(DSResponseFailBlock _Nullable )failure;

/**
 上传图片(多图)

 @param urlString 请求地址
 @param parameters 请求参数
 @param images 图片数组
 */
- (void)uploadImageWithUrlString:(NSString *_Nonnull)urlString
                       parameters:(NSDictionary *_Nullable)parameters
                           images:(NSArray<UIImage *> *_Nonnull)images
                          success:(DSResponseSuccessBlock _Nullable )success
                          failure:(DSResponseFailBlock _Nullable )failure
                   uploadProgerss:(DSUploadProgressBlock _Nullable )progress;

/**
 上传视频

 @param urlString 请求地址
 @param parameters 请求参数
 @param videoPath 视频路径
 */
- (void)uploadVideoWithUrlString:(NSString *_Nonnull)urlString
                       parameters:(NSDictionary *_Nullable)parameters
                           videoPath:(NSString *_Nullable)videoPath
                          success:(DSResponseSuccessBlock _Nullable )success
                          failure:(DSResponseFailBlock _Nullable )failure
                   uploadProgerss:(DSUploadProgressBlock _Nullable )progress;

/**
 下载文件
 */
- (void)downloadFileWihtUrlString:(NSString *_Nonnull)urlString
                        parameters:(NSDictionary *_Nullable)parameters
                           path:(void (^_Nullable)(NSString * _Nullable path))path
                          complete:(void (^_Nullable)(NSData * _Nullable data, NSError * _Nullable error))complete progress:(void (^_Nullable)(double progress))progress;

#pragma mark - 网络状态监测
- (void)startNetworkMonitoringWithBlock:(DSNetworkStatusBlock _Nullable)networkStatus;

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
- (void)cancelAllRequest;

/*!
 *  取消指定 URL 的 Http 请求
 */
- (void)cancelRequestWithURL:(NSString *_Nullable)URL;

#pragma mark - 自定义请求头

/**
 自定义请求头

 @param value value
 @param file key
 */
- (void)setHttpHeadValue:(NSString *_Nullable)value forHeadFile:(NSString *_Nullable)file;

@end
