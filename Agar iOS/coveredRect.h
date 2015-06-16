//
//  coveredRect.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/10/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface coveredRect : UIView
@property (strong, nonatomic) IBOutlet UIView *view;


- (void) turnOn:(BOOL)on;
@end
