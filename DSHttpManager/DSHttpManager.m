//
//  DSHttpManager.m
//  DSHttpManager
//
//  Created by Derrick on 2017/7/14.
//  Copyright © 2017年 Derrick. All rights reserved.
//

#import "DSHttpManager.h"
#import "DSHttpCache.h"
#import "DSHttpConstant.h"

#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>

static NSString * const kAFNetworkingLockName = @"com.alamofire.networking.operation.lock";


@interface DSHttpManager ()
/**递归锁，这个锁可以被同一线程多次请求，而不会引起死锁*/
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property(nonatomic, strong) AFHTTPSessionManager *manager;
/// 存放所有请求的数组
@property (nonatomic, strong) NSMutableArray *tasks;
@end

@implementation DSHttpManager
- (NSMutableArray *)tasks {
    if (_tasks == nil) {
        _tasks = [NSMutableArray array];
    }
    return _tasks;
}
- (AFHTTPSessionManager *)manager {
    if (_manager == nil) {
        // 创建manager对象
        _manager = [AFHTTPSessionManager manager];
        
        // 设置序列化器
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        
        // 设置超时
        [_manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _manager.requestSerializer.timeoutInterval = 30.f;
        [_manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        // 设置请求头
//        [_manager.requestSerializer setValue:@"1.4" forHTTPHeaderField:@"version"];
        
        // 设置接收类型
        [_manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/plain",@"application/json",@"text/json",@"text/javascript",@"text/html", nil]];
        
        /*! 打开状态栏的等待菊花 */
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    }
    return _manager;
}

#pragma mark ----- 初始化
+ (instancetype) shareInstance{
    static DSHttpManager *instance = nil;
    __weak DSHttpManager *weakSelf = instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DSHttpManager alloc] init];
        weakSelf.lock = [[NSRecursiveLock alloc] init];
        weakSelf.lock.name = kAFNetworkingLockName;
    });
    return instance;
}

+ (void)initialize {
    
    [self setupSecurityPolicy];
}

//  配置自建证书的Https请求，只需要将CA证书文件放入根目录就行
+ (void) setupSecurityPolicy {
    NSSet<NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
    
    if (cerSet.count == 0) {
        /*!
         采用默认的defaultPolicy就可以了. AFN默认的securityPolicy就是它, 不必另写代码. AFSecurityPolicy类中会调用苹果security.framework的机制去自行验证本次请求服务端放回的证书是否是经过正规签名.
         */
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        HttpManager.manager.securityPolicy = securityPolicy;
    } else {
        /// 自定义的CA证书配置如下
        // 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        // 如果需要验证自建证书(无效证书)，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        // 是否需要验证域名，默认为YES
        //    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
        
        HttpManager.manager.securityPolicy = securityPolicy;
        
        /*! 如果服务端使用的是正规CA签发的证书, 那么以下几行就可去掉: */
        //            NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        //            AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        //            policy.allowInvalidCertificates = YES;
        //            BANetManagerShare.sessionManager.securityPolicy = policy;
    }
}
#pragma mark - 请求方法
/**
 get请求
 
 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void)getWithUrlString:(NSString *)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *)parameters
                cacheData:(DSCacheDataBlock)cache
                  success:(DSResponseSuccessBlock)success
                  failure:(DSResponseFailBlock)failure {
    
    [self requestWithType:DSHttpRequestTypeGet UrlString:urlString isNeedCache:isNeedCache parameters:parameters cacheData:cache success:success failure:failure];
}

- (void)getWithUrlString:(NSString *)urlString parameters:(NSDictionary *)parameters success:(DSResponseSuccessBlock)success failure:(DSResponseFailBlock)failure {
    
    [self requestWithType:DSHttpRequestTypeGet UrlString:urlString isNeedCache:NO parameters:parameters cacheData:nil success:success failure:failure];
}
/**
 post请求
 
 @param urlString 请求地址
 @param isNeedCache 是否需要缓存
 @param parameters 请求参数
 */
- (void)postWithUrlString:(NSString *)urlString
               isNeedCache:(BOOL)isNeedCache
                parameters:(NSDictionary *)parameters
                 cacheData:(DSCacheDataBlock)cache
                   success:(DSResponseSuccessBlock)success
                   failure:(DSResponseFailBlock)failure {
     [self requestWithType:DSHttpRequestTypePost UrlString:urlString isNeedCache:isNeedCache parameters:parameters cacheData:cache success:success failure:failure];
}

- (void)postWithUrlString:(NSString *)urlString parameters:(NSDictionary *)parameters success:(DSResponseSuccessBlock)success failure:(DSResponseFailBlock)failure {
    [self requestWithType:DSHttpRequestTypePost UrlString:urlString isNeedCache:NO parameters:parameters cacheData:nil success:success failure:failure];
}

- (void)requestWithType:(DSHttpRequestType)type
               UrlString:(NSString *)urlString
             isNeedCache:(BOOL)isNeedCache
              parameters:(NSDictionary *)parameters
               cacheData:(DSCacheDataBlock)cache
                 success:(DSResponseSuccessBlock)success
                 failure:(DSResponseFailBlock)failure{
    
    // 检查地址中是否有中文
    NSString *str = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];
    // 拼接域名
    NSString *url = [NSString stringWithFormat:@"%@%@",API_HOST,str];
    
    NSURLSessionTask *sessionTask = nil;
    
    
    if (isNeedCache) {
        // 读取缓存
        id cacheData = [DSHttpCache ds_httpCacheWithUrlString:url parameters:parameters];
        if (cacheData != nil) {
            NSError *error;
            id cacheResponse = [NSJSONSerialization JSONObjectWithData:cacheData options:NSJSONReadingMutableContainers error:&error];
            if (cache && !error) {
                cache(cacheResponse);
            }
        }
    }
    
    switch (type) {
        case DSHttpRequestTypeGet:
        {
            sessionTask = [self.manager GET:url parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // 这里需要进一步处理后再返回
                NSError *error;
                id dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
                if (success && !error) {
                    success(dict);
                }
                
                [self.tasks removeObject:sessionTask];
                
                // 异步缓存数据
                if (isNeedCache) {
                    [DSHttpCache ds_setHttpCache:responseObject urlString:url parameters:parameters];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
            break;
        case DSHttpRequestTypePost:
        {
            sessionTask = [self.manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // 这里需要进一步处理后再返回
                NSError *error;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
                if (success && !error) {
                    success(dict);
                }

                
                [self.tasks removeObject:sessionTask];
                
                // 异步缓存数据
                if (isNeedCache) {
                    [DSHttpCache ds_setHttpCache:responseObject urlString:url parameters:parameters];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
            break;
        default:
            break;
    }
    if (sessionTask) {
        [self.tasks addObject:sessionTask];
    }
    
}

/**
 上传图片(多图)
 
 @param urlString 请求地址
 @param parameters 请求参数
 @param images 图片数组
 */
- (void)uploadImageWithUrlString:(NSString *)urlString
                       parameters:(NSDictionary *)parameters
                           images:(NSArray *)images
                          success:(DSResponseSuccessBlock)success
                          failure:(DSResponseFailBlock)failure
                   uploadProgerss:(DSUploadProgressBlock)progress {
    /*! 检查地址中是否有中文 */
    NSString *URLString = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];
    
    NSURLSessionTask *sessionTask = nil;
    sessionTask = [self.manager POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [images enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           // 此处应压缩图片
            NSData *imgData = UIImageJPEGRepresentation((UIImage *)obj, 0.8);
           
            if (imgData) {
                [formData appendPartWithFileData:imgData name:[self dateString] fileName:@"xxx.jpg" mimeType:@"image/jpeg"];
            }
        }];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress)
        {
            double progressValue = 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount;
            
            progress(progressValue);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
        if (success && !error) {
            success(dict);
        }

        [self.tasks removeObject:sessionTask];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
        [self.tasks removeObject:sessionTask];
    }];
    if (sessionTask) {
        [self.tasks addObject:sessionTask];
    }
}

/**
 上传视频
 
 @param urlString 请求地址
 @param parameters 请求参数
 @param videoPath 视频路径
 */
- (void)uploadVideoWithUrlString:(NSString *)urlString
                       parameters:(NSDictionary *)parameters
                        videoPath:(NSString *)videoPath
                          success:(DSResponseSuccessBlock)success
                          failure:(DSResponseFailBlock)failure
                   uploadProgerss:(DSUploadProgressBlock)progress {
    
    /*! 检查地址中是否有中文 */
    NSString *URLString = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];
    
    NSURLSessionTask *sessionTask = nil;
    
    sessionTask = [self.manager POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSData   *fileData = [NSData dataWithContentsOfFile:videoPath];
        NSString *fileName = [videoPath lastPathComponent];
        NSString *mimeType = [self getMIMEType:videoPath];
        [formData appendPartWithFileData:fileData name:@"upfile" fileName:fileName mimeType:mimeType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress)
        {
            double progressValue = 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount;
            
            progress(progressValue);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (success) {
            success(dict);
        }

        [self.tasks removeObject:sessionTask];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
        [self.tasks removeObject:sessionTask];
    }];
    if (sessionTask) {
        [self.tasks addObject:sessionTask];
    }
    
    
    
}
- (void)downloadFileWihtUrlString:(NSString *)urlString
                        parameters:(NSDictionary *)parameters
                              path:(void (^)(NSString *path))path
                          complete:(void (^)(NSData *data, NSError *error))complete progress:(void (^)(double progress))progress{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSURLSessionTask *sessionTask = nil;
    sessionTask = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress)
        {
            double progressValue = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
            
            progress(progressValue);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        
        NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *savepath = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        path(savepath);
        return [NSURL fileURLWithPath:savepath];

        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"下载文件成功");
        // filePath就是下载文件的位置，可以直接拿来使用
        NSData *data = [NSData dataWithContentsOfURL:filePath];
        complete(data, error);
        [self.tasks removeObject:sessionTask];
    }];
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask)
    {
        [self.tasks addObject:sessionTask];
    }

}

#pragma mark - 网络状态监测
- (void)startNetworkMonitoringWithBlock:(DSNetworkStatusBlock)networkStatus {
    /*! 1.获得网络监控的管理者 */
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    /*! 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示 */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    /*! 2.设置网络状态改变后的处理 */
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        /*! 当网络状态改变了, 就会调用这个block */
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown:
            {
                NSLog(@"未知网络");
                networkStatus?:networkStatus(DSNetworkStatusUnknown);
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"没有网络");
                networkStatus?:networkStatus(DSNetworkStatusNotReachable);
                                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"手机自带网络");
                networkStatus?:networkStatus(DSNetworkStatusReachableViaWWAN);
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"wifi 网络");
                networkStatus?:networkStatus(DSNetworkStatusReachableViaWiFi);
                break;
        }
    }];
    [manager startMonitoring];
}

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
- (void)cancelAllRequest {
    // 锁操作
    @synchronized(self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [self.tasks removeAllObjects];
    }
}

/*!
 *  取消指定 URL 的 Http 请求
 */
- (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL)
    {
        return;
    }
    @synchronized (self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL])
            {
                [task cancel];
                [self.tasks removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - 自定义请求头
- (void)setHttpHeadValue:(NSString *)value forHeadFile:(NSString *)file {
    [self.manager.requestSerializer setValue:value forHTTPHeaderField:file];
}


- (void)setTimeOut:(NSTimeInterval)timeOut {
    _timeOut = timeOut;
    self.manager.requestSerializer.timeoutInterval = timeOut;
}

#pragma mark - private method
- (NSString *)strUTF8Encoding:(NSString *)str
{
    /*! ios9适配的话 打开第一个 */
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0)
    {
        return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    }
    else
    {
        return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
}

- (NSString *) dateString{
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYYMMddhhmmss"];
    return [formatter stringFromDate:date];
}

//获取文件的类型
- (NSString*)getMIMEType:(NSString *)path
{
    NSError *error;
    NSURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];
    return [response MIMEType];
}
@end
