//
//  entryObj.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "entryObj.h"

@implementation entryObj

- (entryObj*)deepCopy
{
    entryObj* retval = [[entryObj alloc] init];
    retval.dirx = self.dirx;
    retval.diry = self.diry;
    retval.damp = self.damp;
    retval.massdamp = self.massdamp;
    retval.timestamp = self.timestamp;
    retval.superSpeedOn = self.superSpeedOn;
    retval.timeSinceSplit = self.timeSinceSplit;
    
    return retval;
}

@end
