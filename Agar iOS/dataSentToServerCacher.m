//
//  dataSentToServerCacher.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "dataSentToServerCacher.h"
#import "entryObj.h"
#import "urls.m"

//#import "urls.m"




@interface dataSentToServerCacher()


@property (strong, nonatomic) NSMutableArray* entries;


@end

@implementation dataSentToServerCacher

/*
struct cacheEntry
{
    float damp;
    float dirx;
    float diry;
};

struct node {
    struct cacheEntry entry;
    struct node *next;
};

struct node lastEntry = {.entry = 0, .next=0};
struct node firstEntry = {.entry = 0, .next = &lastEntry};


- (CGPoint) changesSince:(long)timestamp
{
    
}

- (void) cacheDirection:(CGPoint)dir damp:(float)damp
{
    if(firstEntry.entry==0)
    {
        firstEntry
    }
}
*/

- (NSMutableArray*)entries
{
    if (!_entries) {
        _entries = [[NSMutableArray alloc] init];
    }
    return _entries;
}

- (float) cacheDirection:(CGPoint)dir damp:(float)damp massdamp:(float)massdamp superSpeed:(BOOL)ss timeSinceSplit:(int)splitDifference
{
    //only accept objects with a timestamp higher than the current highest:
    float timestamp = getUptimeInMilliseconds();
    if(timestamp < ((entryObj*)self.entries.lastObject).timestamp || dir.x==0 || dir.y==0)
    {
        NSLog(@"Rejecting cache!!!");
        
        return -1;
    }
    
    
    entryObj* entry = [[entryObj alloc] init];
    entry.dirx = dir.x; entry.diry = dir.y; entry.damp = damp; entry.timestamp = timestamp; entry.massdamp = massdamp; entry.superSpeedOn = ss;
    entry.timeSinceSplit = splitDifference;
    [self.entries addObject:entry];
    return timestamp;
}

- (CGPoint) changesSince:(long)timestamp
{
    if(self.entries.count==0)return CGPointMake(0, 0);
    float x = 0;
    float y = 0;
    float deltaTimeSec = .05;//default
    for(int i = 0; i < self.entries.count - 1; i++)
    {
        entryObj* entry1 = self.entries[i];
        entryObj* entry2 = self.entries[i+1];
        
        if(entry1.timestamp < timestamp)
        {
            [self.entries removeObjectAtIndex:0];
            i--;
            continue;
        }
        
        float splitTimeDif = entry1.timeSinceSplit;
        float splitMult = (splitTimeDif>0 && splitTimeDif<threshHoldForSpeedBonus)?maxSplitMult-splitTimeDif*((maxSplitMult-1)/threshHoldForSpeedBonus):1;

        
        deltaTimeSec = (entry2.timestamp - entry1.timestamp)/1000;
        x+= entry1.dirx*deltaTimeSec*defVeloc*entry1.massdamp*entry1.damp*(entry1.superSpeedOn?defaultSuperSpeedMult:1)*splitMult;
        y+= entry1.diry*deltaTimeSec*defVeloc*entry1.massdamp*entry1.damp*(entry1.superSpeedOn?defaultSuperSpeedMult:1)*splitMult;
    }

    entryObj* lastEntry = self.entries[self.entries.count-1];
    float splitTimeDif = lastEntry.timeSinceSplit;
    float splitMult = (splitTimeDif>0 && splitTimeDif<threshHoldForSpeedBonus)?maxSplitMult-splitTimeDif*((maxSplitMult-1)/threshHoldForSpeedBonus):1;
    deltaTimeSec = (getUptimeInMilliseconds() - lastEntry.timestamp)/1000;
    //NSLog([NSString stringWithFormat:@"delta %f", deltaTimeSec]);
    x+= lastEntry.dirx*deltaTimeSec*defVeloc*lastEntry.massdamp*lastEntry.damp*(lastEntry.superSpeedOn?defaultSuperSpeedMult:1)*splitMult;//using latest deltaTime known
    y+= lastEntry.diry*deltaTimeSec*defVeloc*lastEntry.massdamp*lastEntry.damp*(lastEntry.superSpeedOn?defaultSuperSpeedMult:1)*splitMult;
    
    return CGPointMake(x, y);
}


- (entryObj*)lastEntry
{
    return self.entries.lastObject;
}

float getUptimeInMilliseconds()
{
    const int64_t kOneMillion = 1000 * 1000;
    static mach_timebase_info_data_t s_timebase_info;
    
    if (s_timebase_info.denom == 0) {
        (void) mach_timebase_info(&s_timebase_info);
    }
    
    // mach_absolute_time() returns billionth of seconds,
    // so divide by one million to get milliseconds
    return (mach_absolute_time() * 1.0 * s_timebase_info.numer) / (kOneMillion * s_timebase_info.denom);
}

- (dataSentToServerCacher*)deepCopy
{
    dataSentToServerCacher* copy = [[dataSentToServerCacher alloc] init];
    for(entryObj* entry in self.entries)
    {
        [copy.entries addObject:[entry deepCopy]];
    }
    
    return copy;
}

@end



