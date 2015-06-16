//
//  SKplayer.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "SKplayerBall.h"
#import "GameScene.h"
#import "UIColor+inverseColor.h"
#import "SKplayer.h"

@interface SKplayerBall()

@property (nonatomic, getter=getRadius) float radius;
@property (nonatomic) float initialWidth;


@property (weak, nonatomic) SKplayer* player;


@end

@implementation SKplayerBall

- (instancetype) initWithColor:(UIColor *)color size:(CGSize)size
{
    
    self = [super initWithColor:color size:size];
    if(self)
    {
        self.name = @"ball";
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2];
        self.physicsBody.friction = 0;
        self.initialWidth = size.width;
        self.physicsBody.collisionBitMask = 0;//prevent collisions
        
    }
    
    return self;
}

@synthesize player = _player;

- (void) setPlayer:(id)player
{
    if([player isKindOfClass:[SKplayer class]])
    {
        _player = player;
    }
}
- (id)getPlayer
{
    return _player;
}

- (void) setPlayerName:(NSString*)playerName
{
    //set name labels:
    _playerName = playerName;
    
    self.nameLabel = [[SKLabelNode alloc] initWithFontNamed:@"Chalkduster"];
    float width = self.frame.size.width*.8;
    
    float largestFontSize = 20;
    while ([_playerName sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Chalkduster" size:largestFontSize]}].width > width && largestFontSize > 3)
    {
        largestFontSize--;
    }
    
    self.nameLabel.text = _playerName;
    self.nameLabel.fontSize = largestFontSize;
    self.nameLabel.position = self.position;
    self.nameLabel.fontColor = [self.circle.fillColor inverseColor];
    
    [self addChild:self.nameLabel];
    
    [self updateMassLabel];
}

- (SKLabelNode*)massLabel
{
    if(!_massLabel)
    {
        _massLabel = [[SKLabelNode alloc] initWithFontNamed:@"Chalkduster"];
        [self addChild:_massLabel];
        float width = self.frame.size.width*.7;
        
        float largestFontSize = 20;
        NSString* maxString = @"9999999";
        while ([maxString sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Chalkduster" size:largestFontSize]}].width > width && largestFontSize > 2)
        {
            largestFontSize--;
        }
        _massLabel.fontSize = largestFontSize;
        _massLabel.position = CGPointMake(self.nameLabel.position.x, self.nameLabel.position.y - self.nameLabel.frame.size.height - (8+self.massLabel.frame.size.height)/2);
        _massLabel.fontColor = [self.circle.fillColor inverseColor];
    }
    return _massLabel;
}
- (void) setIsOurPlayer:(BOOL)shouldShowMassLabel
{
    _isOurPlayer = shouldShowMassLabel;
    self.massLabel.alpha = shouldShowMassLabel;
}
- (void) updateMassLabel
{
    self.massLabel.text = [NSString stringWithFormat:@"%d", self.mass];
}
- (void) createTexture
{
    //take texture without the labels
    [self.nameLabel removeFromParent];
    [self.massLabel removeFromParent];
    [super createTexture];
    [self addChild:self.nameLabel];
    [self addChild:self.massLabel];
    
}

#define areaPerOneMass 150
@synthesize radius = _radius;
- (float)getRadius
{
    return _radius;
}

- (void) setRadius:(float)radius
{
    _radius = radius;
    [self setScale:_radius/(self.initialWidth/2)];
    [self updateSceneZoom];
}
- (void) updateSceneZoom
{
    if(!self.isOurPlayer)return;
    GameScene* ourscene = (GameScene*)self.scene;
    [ourscene adjustScale];
}

- (void) setMass:(int)mass
{
    int massChange = mass - _mass;
    if(massChange==0)return;
    self.player.totalMass += massChange;
    _mass = mass;
    self.radius = sqrtf((self.mass*areaPerOneMass)/3.1415926);
    self.massFactor = [self massFactorForMass:_mass currentMassFactor:self.massFactor change:massChange];
    [self updateMassLabel];
    self.zPosition = mass;
    
    if(self.isOurPlayer)
        [self.dataCacher cacheDirection:self.direction damp:self.player.dampening massdamp:self.massFactor superSpeed:self.player.superSpeedOn timeSinceSplit:self.player.lastServerUpdate - self.splitTime];

}

- (void) setMassFactor:(float)massFactor
{
    _massFactor = massFactor;
    CGPoint direction = self.direction;
    if(!isnan(direction.x) && !isnan(direction.y) && !isnan(self.player.dampening))//to make sure not "nan"
    {
        GameScene* ourscene = (GameScene*)self.scene;
        self.physicsBody.velocity = [ ourscene velocityFromDirection:direction player:self];
        
        }
    //CGVector veloc = self.physicsBody.velocity;
    
}

                                    
//Distance formula
static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}


const float base = 0.9993;
const float mult = 1.08;
- (float) massFactorForMass:(int)mass currentMassFactor:(float)currentMassFactor change:(int)change
{
    if(currentMassFactor)
    {
        return MAX(.2,currentMassFactor * pow(base, change));
    }
    return MAX(.2,mult*pow(base, mass));
}


- (dataSentToServerCacher*)dataCacher
{
    if(!_dataCacher)
    {
        _dataCacher = [[dataSentToServerCacher alloc]init];
    }
    return _dataCacher;
}
@end
