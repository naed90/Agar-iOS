//
//  SKvirusTextureManager.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKvirusTextureManager.h"

@interface SKvirusTextureManager()

@property (strong, nonatomic) NSArray* textures;

@end

@implementation SKvirusTextureManager

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.textures = @[[SKTexture textureWithImageNamed:@"virus1"],[SKTexture textureWithImageNamed:@"virus2"],[SKTexture textureWithImageNamed:@"virus3"],[SKTexture textureWithImageNamed:@"virus4"],[SKTexture textureWithImageNamed:@"virus6"],[SKTexture textureWithImageNamed:@"virus7"],[SKTexture textureWithImageNamed:@"virus8"]];
    }
    return self;
}

- (SKTexture*)getRandomTexture
{
    return self.textures[arc4random()%self.textures.count];
}

@end
