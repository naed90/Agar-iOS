//
//  ViewController.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameScene.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioSessionDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedView;
- (IBAction)changeBg:(id)sender;

- (IBAction)changeSource:(UISegmentedControl *)sender;

@property (strong, nonatomic) GameScene* gs;
@property (weak, nonatomic) IBOutlet UIScrollView *sv;


@end

