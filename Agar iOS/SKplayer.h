//
//  SKplayer.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GameScene.h"
#import "SKplayerBall.h"

@interface SKplayer : NSObject

@property (strong, nonatomic) NSString* playerName;
@property (strong, nonatomic) NSString* trackingID;

@property (nonatomic) float dampening;//players remember their dampening so they can send it to the server
@property (nonatomic) BOOL isOurPlayer;
@property (nonatomic) BOOL superSpeedOn;
@property (strong, nonatomic) NSMutableArray* balls;

- (NSDictionary*)getCenterAndRadiusOfAllBalls;
- (CGPoint) getCenterPoint;//easier to calculate than also calculating the radius, and sometimes we don't need the rad

- (void) setDirectionOfAllBalls:(CGPoint)dir;
- (void) setDirectionOfAllBallsToAimAtPoint:(CGPoint)point;//use this when user taps screen

@property (weak, nonatomic) GameScene* gs;

- (void) addBall:(SKplayerBall*)ball;
- (void) removeBall:(SKplayerBall*)ball;
- (void) removeAllBalls;

@property (strong, nonatomic) SKcircleTextureManager* textureManager;

@property (nonatomic) int updateSeq;

@property (nonatomic) int totalMass;

@property (nonatomic) int lastServerUpdate;

@property (nonatomic) CGPoint lastTouchPoint;

- (void) runTouchUpdate;//should be run only if player.balls.count>=2 -- this adjusts the speeds of the balls

@end
