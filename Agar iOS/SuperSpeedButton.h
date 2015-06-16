//
//  SuperSpeedButton.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/11/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol speedDelegate <NSObject>

- (void) speedClicked;

@end

@interface SuperSpeedButton : UIView
@property (strong, nonatomic) IBOutlet UIView *view;


- (void) makeVisible:(BOOL)visible;

@property (strong, nonatomic) id <speedDelegate> delegate;
@end
