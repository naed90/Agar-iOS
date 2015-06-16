//
//  entryObj.h
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface entryObj : NSObject

@property (nonatomic) float dirx;
@property (nonatomic) float diry;
@property (nonatomic) float damp;
@property (nonatomic) float massdamp;
@property (nonatomic) float timestamp;
@property (nonatomic) BOOL superSpeedOn;
@property (nonatomic) BOOL timeSinceSplit;

- (entryObj*)deepCopy;

@end
