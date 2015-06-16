//
//  dataSentToServerCacher.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

#import "entryObj.h"

#include <mach/mach.h>
#include <mach/mach_time.h>


@interface dataSentToServerCacher : NSObject


- (CGPoint) changesSince:(long)timestamp;


//returns the difference in x, y of the player since the given timestamp and deletes all cached entries before timestamp

- (float) cacheDirection:(CGPoint)dir damp:(float)damp massdamp:(float)massdamp superSpeed:(BOOL)ss timeSinceSplit:(int)splitDifference;//need to take timeSinceSplit as a parameter since it is measured in the server's time system - we cannot use our own time system to generate this!

- (entryObj*)lastEntry;

- (dataSentToServerCacher*)deepCopy;


@end

