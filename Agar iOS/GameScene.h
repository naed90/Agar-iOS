//
//  GameScene.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
//#import "urls.m"
#include <mach/mach.h>
#include <mach/mach_time.h>

#import "SuperSpeedButton.h"
#import "urls.m"

#import "SKplayerBall.h"



@interface GameScene : SKScene <speedDelegate>

- (void) useCreationResponse: (NSDictionary*)response;

- (CGVector)velocityFromDirection:(CGPoint)direction player:(SKplayerBall*)player;


@property (nonatomic, strong) SKVideoNode* background;
@property (nonatomic, strong) SKSpriteNode* sandBackground;

@property (nonatomic, strong) UIScrollView* sv;

@property (nonatomic) BOOL dataSourceIsAccelerometer;

- (void) adjustScale;

- (void) sendSplitEventToServer;

@property (nonatomic) BOOL loginIsUp;

@end
