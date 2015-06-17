//
//  AppDelegate.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "AppDelegate.h"
#import "GSTouchesShowingWindow.h"

#define defaultBarHeight 40

@interface AppDelegate ()

@property (strong, nonatomic)UIView* bar;

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self.socketDealer pauseAllTrackers];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.socketDealer pauseAllTrackers];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self.socketDealer resumeAllTrackers];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self.socketDealer resumeAllTrackers];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self.socketDealer pauseAllTrackers];
}


#pragma mark socketing

-(socketDealer*)socketDealer
{
    if(!_socketDealer)
    {
        _socketDealer = [[socketDealer alloc] init];
        _socketDealer.delegate = self;
        _socketDealer.loggingOff = YES;
        
    }
    return _socketDealer;
}

-(UIView*)bar
{
    if(!_bar)
    {
        CGRect frame = self.window.frame;
        frame.size.height = defaultBarHeight;
        _bar = [[UIView alloc] initWithFrame:frame];
        _bar.backgroundColor = [UIColor blueColor];
        _bar.layer.zPosition = MAXFLOAT;
        
        UILabel* label = [[UILabel alloc] initWithFrame:_bar.bounds];
        label.font = [UIFont fontWithName:@"Chalkduster" size:16];
        label.text = @"Connecting to Server...";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        [_bar addSubview:label];
        
        [self.window addSubview:_bar];
    }
    return _bar;
}
-(void)setNoConnectionBannerOnOff:(BOOL)value
{
    self.bar.alpha = value==1;
}


#pragma mark GSTouchesShowingWindow

/*
 static GSTouchesShowingWindow *window = nil;
 - (GSTouchesShowingWindow *)window {

 if (!window) {
 window = [[GSTouchesShowingWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 }
 return window;
 }*/
@end
