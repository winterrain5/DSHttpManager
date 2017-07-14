//
//  ViewController.m
//  DSHttpManager
//
//  Created by Derrick on 2017/7/14.
//  Copyright © 2017年 Derrick. All rights reserved.
//

#import "ViewController.h"
#import "DSHttpManager.h"
static NSString * const url1 = @"http://c.m.163.com/nc/video/home/1-10.html";
static NSString * const url2 = @"http://apis.baidu.com/apistore/";
static NSString * const url3 = @"http://yycloudvod1932283664.bs2dl.yy.com/djMxYTkzNjQzNzNkNmU4ODc1NzY1ODQ3ZmU5ZDJlODkxMTIwMjM2NTE5Nw";
static NSString * const url4 = @"http://www.aomy.com/attach/2012-09/1347583576vgC6.jpg";
static NSString * const url5 = @"http://chanyouji.com/api/users/likes/268717.json";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [DSHttpManagerInstance startNetworkMonitoringWithBlock:^(DSNetworkStatus status) {
        switch (status) {
            case DSNetworkStatusReachableViaWiFi:
                NSLog(@"wifi");
                break;
            case DSNetworkStatusReachableViaWWAN:
                NSLog(@"3G");
                break;
            default:
                break;
        }
    }];
   
}

- (IBAction)getData:(id)sender {
    
    [DSHttpManagerInstance getWithUrlString:url5 isNeedCache:YES parameters:nil cacheData:^(id response) {
        NSLog(@"cachedata == %@",response);
    } success:^(id response) {
         NSLog(@"response == %@",response);
    } failure:^(NSError *error) {
        
    }];
    
}
- (IBAction)postData:(id)sender {
    int page = 1;
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@(page).stringValue, @"page", @"10", @"per_page", nil];;
    [DSHttpManagerInstance postWithUrlString:url5 isNeedCache:YES parameters:parameters cacheData:^(id response) {
        NSLog(@"cachedata == %@",response);
    } success:^(id response) {
        NSLog(@"response == %@",response);
    } failure:^(NSError *error) {
        NSLog(@"error == %@",error);
    }];
}
- (IBAction)download:(id)sender {
    
    [DSHttpManagerInstance downloadFileWihtUrlString:url3 parameters:nil path:^(NSString *path) {
        NSLog(@"path == %@",path);

    } complete:^(NSData *data, NSError *error) {
        
    } progress:^(double progress) {
        NSLog(@"%lf",progress);
    }];
    
}
- (IBAction)upload:(id)sender {
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
