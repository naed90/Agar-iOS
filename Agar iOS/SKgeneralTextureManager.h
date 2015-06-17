//
//  SKsandItemsTextureManager.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/16/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface SKgeneralTextureManager: NSObject

- (SKTexture*) getRandomTexture;

- (instancetype) initWithPhotoName:(NSString*)name lowestIndex:(int)lowest highestIndex:(int)highest;

@end
