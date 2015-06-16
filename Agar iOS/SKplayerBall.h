//
//  SKplayer.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SKcircle.h"
#import "dataSentToServerCacher.h"

@interface SKplayerBall : SKcircle


@property (nonatomic) int mass;
@property (nonatomic) float massFactor;

- (float)getRadius;

@property (nonatomic) CGPoint direction;
//Use this value JUST for updating the server -- only update this value when a touch occurs and only retrieve it when sending data to the server

@property (nonatomic) CGPoint targetLocation;//location send from server - make it so that it in theory, in .3 sec we'll be here

//@property (nonatomic) int rank;

@property (nonatomic, strong) SKLabelNode* nameLabel;
@property (nonatomic, strong) SKLabelNode* massLabel;

- (void) updateMassLabel;

- (instancetype) initWithColor:(UIColor *)color size:(CGSize)size;

@property (nonatomic) BOOL isOurPlayer;
@property (strong, nonatomic) NSString* playerName;

- (void) setPlayer:(id)player;//make sure to only pass players here!
- (id) getPlayer;

@property (strong, nonatomic) dataSentToServerCacher* dataCacher;

@property (nonatomic) int ballNumber;

@property (nonatomic) int updateSeq;

@property (nonatomic) int splitTime;



@end
