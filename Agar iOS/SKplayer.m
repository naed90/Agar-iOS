//
//  SKplayer.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKplayer.h"

@interface SKplayer()

@property (nonatomic, getter=getRadius) float radius;
@property (nonatomic) float initialWidth;

@end

@implementation SKplayer

- (instancetype) initWithColor:(UIColor *)color size:(CGSize)size
{
    
    self = [super initWithColor:color size:size];
    if(self)
    {
        self.name = @"player";
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2];
        self.initialWidth = size.width;
    }
    
    return self;
}

#define areaPerOneMass 150
@synthesize radius = _radius;
- (float)getRadius
{
    return _radius;
}

- (void) setRadius:(float)radius
{
    _radius = radius;
    [self setScale:_radius/(self.initialWidth/2)];
}

- (void) setMass:(int)mass
{
    _mass = mass;
    self.radius = sqrtf((self.mass*areaPerOneMass)/3.1415926);
}

@end
