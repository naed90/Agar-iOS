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
        
        self.colorKey = arc4random()%10;
        shapeNode.fillColor = [self color:self.colorKey];
        shapeNode.lineWidth = 1;
        [self addChild:shapeNode];
        self.circle = shapeNode;
        
        self.zPosition = 1;
        
       
    }
    return self;
}

- (UIColor*)color:(colorKey)color
{
    switch (color) {
        case red:
            return [SKColor redColor];
            break;
        case green:
            return [SKColor greenColor];
            break;
        case blue:
            return [SKColor blueColor];
            break;
        case cyan:
            return [SKColor cyanColor];
            break;
        case yellow:
            return [SKColor yellowColor];
            break;
        case magenta:
            return [SKColor magentaColor];
            break;
        case red2:
            return [SKColor redColor];
            break;
        case purple:
            return [SKColor purpleColor];
            break;
        case orange:
            return [SKColor orangeColor];
            break;
        case red3:
            return [SKColor redColor];
            break;
            
            
            
        default:
            return [SKColor redColor];
            break;
    }
}

- (void) createTexture
{
    SKTexture* texture = [self.textureManager textureForColor:self.colorKey withNode:self];// [self.scene.view textureFromNode:self];
    self.texture = texture;
    [self.circle removeFromParent];
}
- (void) setColorKey:(colorKey)colorKey
{
    _colorKey = colorKey;
    self.circle.fillColor = [self color:colorKey];
}
@end
