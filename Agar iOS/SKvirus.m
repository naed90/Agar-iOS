//
//  SKvirus.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKvirus.h"

@implementation SKvirus

- (instancetype) initWithTexture:(SKTexture *)texture
{
    self = [super initWithTexture:texture];
    if(self)
    {
        
        SKAction* rotate = [SKAction rotateByAngle:[self randIntBetweenMin:-2*100 max:2*100]/100 duration:1];
        SKAction* repeat = [SKAction repeatActionForever:rotate];
        [self runAction:repeat];
        
        self.zPosition = 102*1.1;//virus mass * 1.1
        
    }
    return self;
}


- (int)randIntBetweenMin:(int)min max:(int)max
{
    if(min>max)return [self randIntBetweenMin:max max:min];//flip
    if(min == max)return min;//they are the same, and mod0 is undefined
    return (arc4random()%(max-min)) + min;
}


@end
