//
//  SKcircle.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/5/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKcircle.h"

@implementation SKcircle


- (instancetype) initWithColor:(UIColor *)color size:(CGSize)size//use only "width" - ignore height, we want a circle
{
    self = [super initWithColor:color size:size];
    if(self)
    {
        CGRect circle = CGRectMake(-size.width/2, -size.width/2, size.width, size.width);
        SKShapeNode *shapeNode = [[SKShapeNode alloc] init];
        shapeNode.path = [UIBezierPath bezierPathWithOvalInRect:circle].CGPath;
        
        shapeNode.fillColor = [self randomColor];
        shapeNode.lineWidth = 1;
        [self addChild:shapeNode];
        self.circle = shapeNode;
        
       
    }
    return self;
}

- (UIColor*)randomColor
{
    switch (arc4random()%10) {
        case 0:
            return [SKColor redColor];
            break;
        case 1:
            return [SKColor greenColor];
            break;
        case 2:
            return [SKColor blueColor];
            break;
        case 3:
            return [SKColor cyanColor];
            break;
        case 4:
            return [SKColor yellowColor];
            break;
        case 5:
            return [SKColor magentaColor];
            break;
        case 6:
            return [SKColor redColor];
            break;
        case 7:
            return [SKColor purpleColor];
            break;
        case 8:
            return [SKColor orangeColor];
            break;
        case 9:
            return [SKColor redColor];
            break;
            
            
            
        default:
            return [SKColor redColor];
            break;
    }
}

- (void) createTexture
{
    SKTexture* texture = [self.scene.view textureFromNode:self];
    self.texture = texture;
    [self.circle removeFromParent];
}
@end
