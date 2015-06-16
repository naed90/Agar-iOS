//
//  SKcircleTextureManager.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKcircleTextureManager.h"

@interface SKcircleTextureManager()

@property (strong, nonatomic) NSMutableArray* colors;

@end

@implementation SKcircleTextureManager


- (SKTexture*)textureForColor:(colorKey)color withNode:(SKNode *)node
{
    if(color>=numColors)return nil;
    SKTexture* texture = self.colors[color];
    if(texture==[NSNull null])
    {
        texture = [node.scene.view textureFromNode:node];
        self.colors[color] = texture;
    }
    return texture;
}


- (NSMutableArray*)colors
{
    if(!_colors)
    {
        _colors = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < numColors; i++) {
            [_colors addObject:[NSNull null]];
        }
    }
    return _colors;
}

@end
