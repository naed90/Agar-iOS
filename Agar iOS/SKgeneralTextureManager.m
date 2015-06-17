//
//  SKsandItemsTextureManager.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/16/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKgeneralTextureManager.h"

@interface SKgeneralTextureManager()

@property (strong, nonatomic) NSArray* textures;

@end

@implementation SKgeneralTextureManager

- (instancetype) initWithPhotoName:(NSString*)name lowestIndex:(int)lowest highestIndex:(int)highest
{
    self = [super init];
    if(self)
    {
        
        NSString* rootWord = name;
        int highestNumberPicture = highest;
        int lowestNumberPicture = lowest;
        
        NSMutableArray* textures = [[NSMutableArray alloc] init];
        for(int i = lowestNumberPicture; i<= highestNumberPicture; i++)
        {
            SKTexture* texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%@%d", rootWord, i]];
            if(texture)
                [textures addObject:texture];
        }
        
        
        self.textures = textures;
    }
    return self;
}

- (SKTexture*)getRandomTexture
{
    return self.textures[arc4random()%self.textures.count];
}

@end
