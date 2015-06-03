//
//  AppDelegate.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "socketDealer.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, socketDealerDelegate>

@property (strong, nonatomic) UIWindow *window;



//Server:
@property (strong, nonatomic)socketDealer* socketDealer;


@end

