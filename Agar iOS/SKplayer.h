//
//  SKplayer.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SKcircle.h"

@interface SKplayer : SKcircle

@property (strong, nonatomic) NSString* playerName;
@property (nonatomic) int mass;
@property (nonatomic) int updateSeq;

@property (nonatomic) float dampening;//players remember their dampening so they can send it to the server

- (float)getRadius;

@end
