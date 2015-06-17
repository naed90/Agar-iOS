//
//  ViewController.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "ViewController.h"

#import <SpriteKit/SpriteKit.h>

#import "GameScene.h"

#import <MediaPlayer/MediaPlayer.h>




@implementation ViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    SKView *spriteView = (SKView *) self.view;
    //spriteView.showsDrawCount = YES;
    //spriteView.showsNodeCount = YES;
    spriteView.showsFPS = YES;
    
    GameScene* gs = [[GameScene alloc] initWithSize:spriteView.frame.size];
    gs.sv = self.sv;
    [spriteView presentScene:gs];
    //gs.backgroundColor = [UIColor clearColor];
    self.gs = gs;
    
    UITapGestureRecognizer* closeKeyboardsTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)] ;
    closeKeyboardsTap.cancelsTouchesInView = NO;
    closeKeyboardsTap.numberOfTouchesRequired=1;
    [self.view addGestureRecognizer:closeKeyboardsTap];
    
    
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    [[AVAudioSession sharedInstance] setDelegate:self];
    
    /*
    NSString* str = [[NSBundle mainBundle] pathForResource:@"IMG_1182 (online-video-cutter.com)" ofType:@"mp4"];
    MPMoviePlayerController *player =
    [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:str]];
    [player prepareToPlay];
    [player.view setFrame: self.view.bounds];  // player's frame must match parent's
    [self.view addSubview: player.view];
    [player setControlStyle:MPMovieControlStyleNone];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
    [player play];
    player.repeatMode = MPMovieRepeatModeOne;
    self.background = player;
    [self.view sendSubviewToBack:player.view];*/
}

/*
- (void)moviePlayerDidFinish:(NSNotification *)note
{
    if (note.object == self.background) {
        NSInteger reason = [[note.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
        if (reason == MPMovieFinishReasonPlaybackEnded)
        {
            [self.background play];
        }
    }
}*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) closeKeyboard
{
    
    [self.view endEditing:YES];
}

- (IBAction)changeBg:(UISegmentedControl*)sender
{
    NSInteger selected = sender.selectedSegmentIndex ;
    self.gs.background.hidden = selected;
    for(SKSpriteNode* node in self.gs.sand)
    {
        node.hidden = selected;
    }
    for(SKSpriteNode* node in self.gs.sandItems)
    {
        node.hidden = selected;
    }
}

- (IBAction)changeSource:(UISegmentedControl *)sender
{
    self.gs.dataSourceIsAccelerometer = !sender.selectedSegmentIndex;
}
- (IBAction)splitClicked:(id)sender
{
    [self.gs sendSplitEventToServer];
}

@end
