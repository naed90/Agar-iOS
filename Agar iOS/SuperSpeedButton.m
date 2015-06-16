//
//  SuperSpeedButton.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/11/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SuperSpeedButton.h"


@interface SuperSpeedButton()

@property (weak, nonatomic) IBOutlet UIView *coverRect;

@property (strong, nonatomic) UIView* shineView;

@end


@implementation SuperSpeedButton

- (void) makeVisible:(BOOL)visible
{
    self.coverRect.alpha = visible ? 0 : .5;
    self.shineView.alpha = visible ? 1 : 0;
}
- (IBAction)buttonClick:(id)sender
{
    if(self.coverRect.alpha == 0)//don't register click if coverRect is on (means button is disabled)
        [self.delegate speedClicked];
}


- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"SuperSpeedButton" owner:self options:nil];
        
        self.frame = frame;
        self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        
        [self addSubview:self.view];
        
        
        
        
        UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [whiteView setBackgroundColor:[UIColor whiteColor]];
        [whiteView setUserInteractionEnabled:NO];
        [self.view addSubview:whiteView];
        
        CALayer *maskLayer = [CALayer layer];
        
        // Mask image ends with 0.15 opacity on both sides. Set the background color of the layer
        // to the same value so the layer can extend the mask image.
        maskLayer.backgroundColor = [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f] CGColor];
        maskLayer.contents = (id)[[UIImage imageNamed:@"ShineMask.png"] CGImage];
        
        // Center the mask image on twice the width of the text layer, so it starts to the left
        // of the text layer and moves to its right when we translate it by width.
        maskLayer.contentsGravity = kCAGravityCenter;
        maskLayer.frame = CGRectMake(-whiteView.frame.size.width,
                                     0.0f,
                                     whiteView.frame.size.width * 2,
                                     whiteView.frame.size.height);
        
        // Animate the mask layer's horizontal position
        CABasicAnimation *maskAnim = [CABasicAnimation animationWithKeyPath:@"position.x"];
        maskAnim.byValue = [NSNumber numberWithFloat:self.view.frame.size.width * 9];
        maskAnim.repeatCount = HUGE_VALF;
        maskAnim.duration = 3.0f;
        maskAnim.delegate = self;
        
        [maskLayer addAnimation:maskAnim forKey:@"shineAnim"];
        
        whiteView.layer.mask = maskLayer;
        self.shineView = whiteView;
        
        self.shineView.alpha = 0;
        
    }
    
    
    return self;
}
- (void) animationDidStart:(CAAnimation *)anim
{
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(popButton) userInfo:nil repeats:YES];
}

- (void) popButton
{
    if(self.shineView.alpha)
    {
        [UIView animateWithDuration:.2 animations:^{
            self.view.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.2 animations:^{
                self.view.transform = CGAffineTransformMakeScale(1, 1);
            }];
        }];
    }
}
@end
