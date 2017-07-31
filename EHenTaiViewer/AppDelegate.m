//
//  AppDelegate.m
//  EHenTaiViewer
//
//  Created by QinJ on 2017/5/17.
//  Copyright © 2017年 kayanouriko. All rights reserved.
//  TODO:第三方跳转识别

#import "AppDelegate.h"
#import "QJNetworkTool.h"
#import "QJProtectTool.h"
#import "QJTouchIDViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Tag+CoreDataClass.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //TODO:检查更新,弹窗提醒
    
    //TODO:检查相册权限,一次性检查
    
    //设置数据库
    [self setCoreData];
    //解决iOS遗留bug,导航栏push或者pop存在黑块问题
    self.window.backgroundColor = [UIColor whiteColor];
    //判断全局的版块变量,确保初始化必须有值
    if (!NSObjForKey(@"ExHentaiStatus")) {
        NSObjSetForKey(@"ExHentaiStatus", @(NO));
        NSObjSynchronize();
    }
    //观看模块
    if (!NSObjForKey(@"WatchMode")) {
        NSObjSetForKey(@"WatchMode", @(NO));
        NSObjSynchronize();
    }
    //保护模块
    if (!NSObjForKey(@"ProtectMode")) {
        NSObjSetForKey(@"ProtectMode", @(NO));
        NSObjSynchronize();
    }
    //网络监测
    [[QJNetworkTool shareTool] starNotifier];
    
    /*
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController *vc = [storyBoard instantiateViewControllerWithIdentifier:isPad ? @"ipadInput" : @"iphoneInput"];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    */
    return YES;
}

- (void)setCoreData {
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Model.sqlite"];
    Tag *tag = (Tag *)[Tag MR_findFirst];
    if (nil == tag) {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(saveAllTags) object:nil];
        [thread start];
    }
}

- (void)saveAllTags {
    //存储全部Tag标签,以后备用更新本地离线Tag值
    //数据库操作
    NSString *path = [[NSBundle mainBundle] pathForResource:@"EhTag_CN" ofType:@"json"];
    NSDictionary *tagJson = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:NSJSONReadingAllowFragments error:nil];
    NSArray<NSDictionary *> *catgoery = tagJson[@"dataset"];
    NSInteger i = 0;
    for (NSDictionary *subCat in catgoery) {
        NSArray<NSDictionary *> *tags = subCat[@"tags"];
        for (NSDictionary *tagDic in tags) {
            NSString *type = isnull(@"type", tagDic);
            if (![type isEqualToString:@"0"]) {
                continue;
            }
            Tag *tag = [Tag MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            tag.name = isnull(@"name", tagDic);
            tag.cname = isnull(@"cname", tagDic);
            tag.info = isnull(@"info", tagDic);
            i++;
            if (i % 1000 == 0) {
                [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
            }
        }
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[QJGlobalInfo sharedInstance] putAttribute:@"BackgroundTime" value:@([[NSProcessInfo processInfo] systemUptime])];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (NSObjForKey(@"ProtectMode") && [NSObjForKey(@"ProtectMode") boolValue]) {
        NSTimeInterval beginTime = [[[QJGlobalInfo sharedInstance] getAttribute:@"BackgroundTime"] integerValue];
        NSTimeInterval endTime = [[NSProcessInfo processInfo] systemUptime];
        if (endTime - beginTime > 120) {
            if ([[QJProtectTool shareTool] isEnableTouchID]) {
                //TouchID
                UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                if (![vc isKindOfClass:[QJTouchIDViewController class]]) {
                    QJTouchIDViewController *subVC = [QJTouchIDViewController new];
                    [vc presentViewController:subVC animated:nil completion:nil];
                }
            }
            else {
                //密码
            }
        }
    }
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
