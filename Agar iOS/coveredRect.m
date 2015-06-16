//
//  coveredRect.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/10/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "coveredRect.h"

@interface coveredRect()

@property (weak, nonatomic) IBOutlet UIView *coverView;


@end

@implementation coveredRect

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"coveredRect" owner:self options:nil];
        
        self.frame = frame;
        self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        
        [self addSubview:self.view];
        
    }
    return self;
}

- (void) turnOn:(BOOL)on
{
    self.coverView.alpha = on ? 0 : 0.5;
}


@end
