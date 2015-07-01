//
//  SKplayer.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKplayer.h"
#import "UIColor+inverseColor.h"
#import "SKplayerBall.h"


@implementation SKplayer

- (void) setPlayerName:(NSString *)playerName
{
    _playerName = playerName;
    
    for(SKplayerBall* ball in self.balls)
    {
        ball.playerName = playerName;
    }
    
}

- (void) setIsOurPlayer:(BOOL)isOurPlayer
{
    _isOurPlayer = isOurPlayer;
    
    for(SKplayerBall* ball in self.balls)
    {
        ball.isOurPlayer = isOurPlayer;
    }
}

- (void) setSuperSpeedOn:(BOOL)superSpeedOn
{
    if(superSpeedOn == _superSpeedOn)return;
    _superSpeedOn = superSpeedOn;
    if(self.isOurPlayer)
    {
        [self.gs adjustScale];
        for(SKplayerBall* ball in self.balls)
        {
            [ball.dataCacher cacheDirection:ball.direction damp:self.dampening massdamp:ball.massFactor superSpeed:self.superSpeedOn timeSinceSplit:self.lastServerUpdate - ball.splitTime];
        }
    }
}


- (NSDictionary*)getCenterAndRadiusOfAllBalls
{
    
    
    CGPoint point = [self getCenterPoint];
    
    if(self.balls.count==1)
    {
        return @{@"centerX":[NSNumber numberWithFloat:point.x], @"centerY":[NSNumber numberWithFloat:point.y], @"radius":[NSNumber numberWithFloat:((SKplayerBall*)self.balls[0]).getRadius]};
    }
    
    float avgX = point.x;
    float avgY = point.y;
    
    float largestDistanceSquared = 0;
    float largestRad = 0;//yes, I know that largestDist+largestRad may go OVER the acutual radius of the circle enclosing all the balls, but it's fine
    
    for(SKplayerBall* ball in self.balls)
    {
        float distSqr = (ball.position.x - avgX)*(ball.position.x - avgX) + (ball.position.y - avgY)*(ball.position.y - avgY);
        if(distSqr > largestDistanceSquared)largestDistanceSquared = distSqr;
        if(ball.getRadius>largestRad)largestRad = ball.getRadius;
    }
    
    float largestDist = sqrtf(largestDistanceSquared);
    
    return @{@"centerX":[NSNumber numberWithFloat:avgX], @"centerY":[NSNumber numberWithFloat:avgY], @"radius":[NSNumber numberWithFloat:largestDist+largestRad]};
}
- (CGPoint) getCenterPoint
{
    if(self.balls.count==1)
    {
        return ((SKplayerBall*)self.balls[0]).position;
    }
    
    //just calc the x and y average of all the balls:
    int totalX = 0;
    int totalY = 0;
    for(SKplayerBall* ball in self.balls)
    {
        totalX += ball.position.x;
        totalY += ball.position.y;
    }
    float avgX = totalX/(int)self.balls.count;
    float avgY = totalY/(int)self.balls.count;
    
    
    return CGPointMake(avgX, avgY);
}

- (void) setDirectionOfAllBalls:(CGPoint)dir
{
    for(int i = 0; i < self.balls.count; i++)
    {
        SKplayerBall* ball = self.balls[i];
        ball.direction = dir;
    }
}

//difference between points a and b returned as a vector
static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}


// Normalizes vector
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

//Distance formula
static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

- (void) setDirectionOfAllBallsToAimAtPoint:(CGPoint)location//location is given in terms of the SCENE's coord sys!
{
    for(SKplayerBall* ball in self.balls)
    {
        CGPoint offset = rwSub(location, [ball.scene convertPoint:ball.position fromNode:ball.parent]);
        CGPoint direction = rwNormalize(offset);
        ball.direction = direction;
    }
    
    CGPoint center = [self getCenterPoint];
    CGPoint offset = rwSub(location, center);
    float lenght = rwLength(offset);
    if(isnan(lenght))return;
    float scaleVelocity = lenght > 100 ? 1 : lenght/100;//If we get our finger close to player, slow down
    if(isnan(scaleVelocity))return;
    self.dampening = scaleVelocity;
    
    self.lastTouchPoint = location;

}


- (void) addBall:(SKplayerBall *)ball
{
    [self.balls addObject:ball];
    [ball setPlayer:self];
    ball.playerName = self.playerName;
    ball.isOurPlayer = self.isOurPlayer;
    [self.gs addChild:ball];
    ball.textureManager = self.textureManager;
    
    if(self.balls.count>1)
    {
        ball.colorKey = ((SKplayerBall*)self.balls[0]).colorKey;
    }
    self.totalMass += ball.mass;
    
}

- (void) removeBall:(SKplayerBall *)ball
{
    self.totalMass -=ball.mass;
    [ball removeFromParent];
    [self.balls removeObject:ball];
}

- (void) removeAllBalls
{
    for(int i = 0; i < self.balls.count; i++)
    {
        SKplayerBall* ball = self.balls[i];
        [self removeBall:ball];
        i--;
    }
}

- (void) setTextureManager:(SKcircleTextureManager *)textureManager
{
    _textureManager = textureManager;
    for(SKplayerBall* ball in self.balls)
    {
        ball.textureManager = textureManager;
    }
}

- (NSMutableArray*)balls
{
    if(!_balls)
    {
        _balls = [[NSMutableArray alloc] init];
    }
    return _balls;
}

- (void) runTouchUpdate
{
    if(self.balls.count<2)return;
    if(self.lastTouchPoint.x==0 && self.lastTouchPoint.y==0)return;
    
    [self setDirectionOfAllBallsToAimAtPoint:self.lastTouchPoint];
}
@end
