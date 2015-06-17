//
//  SKsandItemsTextureManager.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/16/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKsandItemsTextureManager.h"

@interface SKsandItemsTextureManager()

@property (strong, nonatomic) NSArray* textures;

@end

@implementation SKsandItemsTextureManager

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        
        NSString* rootWord = @"beach";
        int highestNumberPicture = 13;
        int lowestNumberPicture = 0;
        
        NSMutableArray* textures = [[NSMutableArray alloc] init];
        for(int i = lowestNumberPicture; i<= highestNumberPicture; i++)
        {
            SKSpriteNode* texture = [SKSpriteNode spriteNodeWithTexture: [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%@%d", rootWord, i]]];
            if(texture)
               [textures addObject:texture];
        }
        
       
        self.textures = textures;
    }
    return self;
}

- (SKSpriteNode*)getRandomNode
{
    return self.textures[arc4random()%self.textures.count];
}

@end
