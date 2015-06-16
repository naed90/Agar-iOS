//
//  SKcircleTextureManager.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>

@interface SKcircleTextureManager : NSObject

typedef enum colorKey
{
    red,
    red2,//just makes red more common
    red3,//just makes red more common
    green,
    blue,
    cyan,
    yellow,
    magenta,
    purple,
    orange,
    numColors
    
    
} colorKey;


- (SKTexture*) textureForColor:(colorKey)color withNode:(SKNode*)node;//may use node to create the texture, so make sure node has nothing on it but the colored circle!



@end
