//
//  SKcircle.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/5/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKcircle : SKSpriteNode

@property (strong, nonatomic) SKShapeNode* circle;
@property (strong, nonatomic) NSString* trackingID;


- (void) createTexture;

@end
