//
//  DSHttpManager.h
//  DSHttpManager
//
//  Created by 石冬冬 on 2017/7/14.
//  Copyright © 2017年 Derrick. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DSHttpManagerInstance [DSHttpManager shareInstance]

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
typedef void (^DSResponseSuccessBlock)(id response);

/// 缓存数据
typedef void (^DSCacheDataBlock)(id response);

/// 请求失败block
typedef void (^DSResponseFailBlock)(NSError *error);

/// 上传进度block
typedef void (^DSUploadProgressBlock)(double progress);

/// 下载进度block
typedef void (^DSDownloadProgressBlock)(int64_t bytesProgress,
                                        int64_t totalBytesProgress);
typedef void (^DSNetworkStatusBlock)(DSNetworkStatus status);

@interface DSHttpManager : NSObject


/// 单例方法
+ (instancetype) shareInstance;

#pragma mark - 请求方法
/**
 get请求

 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void) getWithUrlString:(NSString *)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *)parameters
                cacheData:(DSCacheDataBlock)cache
                  success:(DSResponseSuccessBlock)success
                  failure:(DSResponseFailBlock)failure;
/**
 post请求
 
 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void) postWithUrlString:(NSString *)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *)parameters
                 cacheData:(DSCacheDataBlock)cache
                  success:(DSResponseSuccessBlock)success
                  failure:(DSResponseFailBlock)failure;

/**
 上传图片(多图)

 @param urlString 请求地址
 @param parameters 请求参数
 @param images 图片数组
 */
- (void) uploadImageWithUrlString:(NSString *)urlString
                       parameters:(NSDictionary *)parameters
                           images:(NSArray *)images
                          success:(DSResponseSuccessBlock)success
                          failure:(DSResponseFailBlock)failure
                   uploadProgerss:(DSUploadProgressBlock)progress;

/**
 上传视频

 @param urlString 请求地址
 @param parameters 请求参数
 @param videoPath 视频路径
 */
- (void) uploadVideoWithUrlString:(NSString *)urlString
                       parameters:(NSDictionary *)parameters
                           videoPath:(NSString *)videoPath
                          success:(DSResponseSuccessBlock)success
                          failure:(DSResponseFailBlock)failure
                   uploadProgerss:(DSUploadProgressBlock)progress;

/**
 下载文件
 */
- (void) downloadFileWihtUrlString:(NSString *)urlString
                        parameters:(NSDictionary *)parameters
                           path:(void (^)(NSString *path))path
                          complete:(void (^)(NSData *data, NSError *error))complete progress:(void (^)(double progress))progress;

#pragma mark - 网络状态监测
- (void) startNetworkMonitoringWithBlock:(DSNetworkStatusBlock)networkStatus;

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
- (void)cancelAllRequest;

/*!
 *  取消指定 URL 的 Http 请求
 */
- (void)cancelRequestWithURL:(NSString *)URL;
@end
