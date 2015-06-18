//
//  GameScene.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//



#import "GameScene.h"
#import "login.h"
#import "SKplayer.h"
#import "SKcircleTextureManager.h"

#import "AppDelegate.h"
#import "socketDealer.h"


#import "dataSentToServerCacher.h"
#import "entryObj.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

#import "coveredRect.h"

#import "SKvirusTextureManager.h"
#import "SKvirus.h"

#import "SKgeneralTextureManager.h"


#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


#define gridSize 5000




@interface GameScene ()


@property BOOL contentCreated;

@property (nonatomic, strong) SKNode* world;

@property (strong, nonatomic) NSString* playerID;
@property (strong, nonatomic) NSString* gridID;
@property (strong, nonatomic) SKplayer* ourPlayer;

@property (strong, nonatomic) NSMutableDictionary* players;//trackingID to player
@property (strong, nonatomic) NSMutableDictionary* foods;//trackingID to food
@property (strong, nonatomic) SKcircleTextureManager* textureManager;




@property (strong, nonatomic) NSMutableArray* playerRankings;
@property (strong, nonatomic) NSMutableArray* labelsForRanking;

@property (nonatomic) float lastTimeRequestedFoods;//wait at least 2 sec before requesting again
@property (nonatomic) float lastTimeRequestedViruses;

#define kUpdateInterval (1.0f / 60.0f)
@property (assign, nonatomic) CMAcceleration acceleration;
@property (strong, nonatomic) CMMotionManager  *motionManager;
@property (strong, nonatomic) NSOperationQueue *queue;

@property (strong, nonatomic) NSTimer* updateTimer;


@property (strong, nonatomic) NSMutableArray* superSpeedRects;
@property (strong, nonatomic) SuperSpeedButton* ssButton;
@property (nonatomic) float scale;
@property (nonatomic) BOOL shouldTurnOffSpeedScale;

@property (strong, nonatomic) SKvirusTextureManager* virusTextureManager;
@property (strong, nonatomic) NSMutableDictionary* viruses;//trackingID to virus

@property (strong, nonatomic) SKgeneralTextureManager* sandItemsTextureManager;
@property (strong, nonatomic) SKgeneralTextureManager* purpleItemsTextureManager;

@property (nonatomic) int borderSize;

@property (strong, nonatomic) SKTexture* sandTexture;

@end


@implementation GameScene



- (void)didMoveToView: (SKView *) view
{
    if (!self.contentCreated)
    {
        [self createSceneContents];
        self.contentCreated = YES;
    }
    
    view.ignoresSiblingOrder = YES;
}

- (void)createSceneContents
{
    self.scale = 1;
    
    self.backgroundColor = [SKColor whiteColor];
    self.scaleMode = SKSceneScaleModeAspectFit;
    //self.scaleMode = SKSceneScaleModeResizeFill;
    self.anchorPoint = CGPointMake (0.5,0.5);
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    
    
    [self createWorld];
    //background:
    
    
    //Draw boundaries:
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(-gridSize*3, -gridSize*3, gridSize*6, gridSize*6)];
    UIBezierPath* smallMaskPath = [UIBezierPath bezierPathWithRect:CGRectMake(-gridSize/2, -gridSize/2, gridSize, gridSize)];
    [clipPath appendPath:smallMaskPath];
    clipPath.usesEvenOddFillRule = YES;
    SKShapeNode* node = [SKShapeNode shapeNodeWithPath:clipPath.CGPath];
    [self.world addChild:node];
    node.zPosition = 7;
    node.position = CGPointMake(CGRectGetMidX(self.world.frame), CGRectGetMidY(self.world.frame));
    node.fillColor = [SKColor colorWithRed:217/255.0 green:148/255.0 blue:22/255.0 alpha:1];
    //node.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:node.path];
    //node.physicsBody.dynamic = NO;
    //[[UIColor orangeColor] setFill];
    //[clipPath fill];
    
    //spawn purple items:
    
    self.purpleItemsTextureManager = [[SKgeneralTextureManager alloc]initWithPhotoName:@"purpleItem" lowestIndex:1 highestIndex:20];
    self.purpleItems = [[NSMutableArray alloc]init];
    
    int numPurpleItemsToSpawn = 1000;//don't spawn too many
    
    
    int prev = gridSize;
    int current = gridSize*2;
    
    for(int i = 0; i < numPurpleItemsToSpawn; i++)
    {
        //get random texture:
        SKTexture* randTexture = [self.purpleItemsTextureManager getRandomTexture];
        SKSpriteNode* item = [SKSpriteNode spriteNodeWithTexture:randTexture];
        [self.world addChild:item];//must add so that we can compare to other items' frames
        //try to place in random loc:
        
        BOOL success = NO;
        while(!success)
        {
            CGPoint randLoc;
            if(i < numPurpleItemsToSpawn/2)//spawn in 1 direction
            {
                randLoc = CGPointMake([self randIntBetweenMin:prev/2 + randTexture.size.width/2 max:current/2 - randTexture.size.width/2]*((arc4random()%2)==0?-1:1), [self randIntBetweenMin:0 max:prev/2 - randTexture.size.height/2]*((arc4random()%2)==0?-1:1));
            }
            else //spawn in other direction
            {
                randLoc = CGPointMake([self randIntBetweenMin:0 max:current/2 - randTexture.size.width/2]*((arc4random()%2)==0?-1:1), [self randIntBetweenMin:prev/2 +randTexture.size.height/2 max:current/2 - randTexture.size.height/2]*((arc4random()%2)==0?-1:1));
            }
            
            
            item.position = randLoc;
            for(SKSpriteNode* otherNode in self.purpleItems)
            {
                if(CGRectContainsRect(otherNode.frame, item.frame))
                {
                    success = NO;
                    break;
                }
            }
            success = YES;
        }
        
        item.hidden = !self.background.hidden;
        item.zPosition = 8;
        [self.purpleItems addObject:item];
        
    }

    
    AVAsset *composition = [self makeAssetComposition];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:composition]];
    player.muted = YES;
    
    
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    SKVideoNode* background = [[SKVideoNode alloc] initWithAVPlayer:player];
    background.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    background.size = self.frame.size;
    [background play];
    [self.world addChild:background];
    self.background = background;
    
    self.sandTexture = [SKTexture textureWithImageNamed:@"sand2Cropped"];
    
    self.sand = [[NSMutableArray alloc] init];
    
    self.borderSize = gridSize;
    
    [self addSandLayer];
    
    self.background2 = [SKSpriteNode spriteNodeWithImageNamed:@"background2"];
    [self.world addChild:self.background2];
    self.background2.hidden = YES;
    self.background2.size = self.frame.size;
    self.background2.zPosition = 6;
    
    
    
    //spawn items on sand:
    
    
    self.sandItemsTextureManager = [[SKgeneralTextureManager alloc] initWithPhotoName:@"beach" lowestIndex:0 highestIndex:13];
    self.sandItems = [[NSMutableArray alloc] init];
    
    [self spawnSandItemsWithHowManySandTilesAdded:[[NSNumber numberWithInteger:self.sand.count] intValue] prevBorderSize:gridSize currentBorderSize:self.borderSize];
    
    
    //[self addChild: [self newHelloNode]];
    
    //[self runAction: [SKAction repeatActionForever:makeRocks]];
    
    [self showLogin];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"gU" sender:self withSelector:@selector(gotResponse:)];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"requestFoods" sender:self withSelector:@selector(gotFoods:)];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"requestViruses" sender:self withSelector:@selector(gotViruses:)];
    
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"youWereEaten" sender:self withSelector:@selector(weLost)];
    
    
    
    
    
    
    self.motionManager = [[CMMotionManager alloc]  init];
    self.queue         = [[NSOperationQueue alloc] init];
    
    self.motionManager.accelerometerUpdateInterval = kUpdateInterval;
    
    self.dataSourceIsAccelerometer = YES;
    
    
    
    //Make super speed display:
    const int superSpeedRectWidth = 8;
    
    const int centerPieceHeight = 50;
    const int superSpeedRectHeight = centerPieceHeight/2;
    const float multNum = 2.5;
    const int centerPieceWidth = 80;
    
    //we need to fit 10 recs, 5 on each side of middle circle
    const float numRects = 24;//define as float so that when we do devision with it, we do float devision; make sure it's div by 4
    float spacing = (self.frame.size.width - numRects*superSpeedRectWidth - centerPieceWidth)/(numRects+3);//+2 b/c 1 more on side and 1 more in the center
    
    self.superSpeedRects = [[NSMutableArray alloc] init];
    
    float centerY = 16 + centerPieceHeight/2 + self.sv.frame.size.height + self.sv.frame.origin.y;
    
    int rectNum = 1;
    for(float i = spacing; rectNum<numRects; i+= spacing + superSpeedRectWidth)
    {
        rectNum = (int)self.superSpeedRects.count +1;
        int relativePos = round(fabsf(rectNum - (numRects+1)/2));//1 is two rects next to center, then increases
        float rectHeight = superSpeedRectHeight*(relativePos<=numRects/4?((multNum-1)/(numRects/4)*((numRects/4)-relativePos +1))+1:1);
        float yOrigin = centerY - rectHeight/2;
        //NSLog([NSString stringWithFormat:@"%d %f",relativePos, rectHeight ]);
        coveredRect* rect = [[coveredRect alloc] initWithFrame:CGRectMake(i, yOrigin, superSpeedRectWidth,
                                                                          rectHeight
                                                                          )];
        [self.view addSubview:rect];
        [self.superSpeedRects addObject:rect];
        
        
        float redPortion = relativePos;
        rect.view.backgroundColor = [UIColor colorWithRed:redPortion/(numRects/2) green:1 - redPortion/(numRects/2) blue:0 alpha:1];
        //rect.alpha = .8;
        
        if(rectNum==numRects/2)
        {
            i += spacing + superSpeedRectWidth;
            SuperSpeedButton* ssB = [[SuperSpeedButton alloc] initWithFrame:CGRectMake(i, centerY - centerPieceHeight/2, centerPieceWidth, centerPieceHeight)];
            self.ssButton = ssB;
            [self.view addSubview:ssB];
            ssB.delegate = self;
            i+=centerPieceWidth + spacing;
            i -= spacing + superSpeedRectWidth;//will be added once for loop ends current iteration
            ssB.layer.zPosition = 999;//not MAXFLOAT b/c login is that value
        }
    }
    
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpToKnowWhenConnectionToServerEstablishedWithSender:self selector:@selector(connectedToServer)];
    
}

- (void) connectedToServer
{
    NSLog(@"Requesting players!!!");
    
    if(self.gridID)
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/fullplayerupdate" withData:@{@"gridID":self.gridID}];
}


- (void) spawnSandItemsWithHowManySandTilesAdded:(int)tilesAdded prevBorderSize:(int)prev currentBorderSize:(int)current
{
    int numToSpawn = tilesAdded * 5 * 1;
    for(int i = 0; i < numToSpawn; i++)
    {
        //get random texture:
        SKTexture* randTexture = [self.sandItemsTextureManager getRandomTexture];
        SKSpriteNode* item = [SKSpriteNode spriteNodeWithTexture:randTexture];
        [self.world addChild:item];//must add so that we can compare to other items' frames
        //try to place in random loc:
        
        BOOL success = NO;
        while(!success)
        {
            CGPoint randLoc;
            if(i < numToSpawn/2)//spawn in 1 direction
            {
                randLoc = CGPointMake([self randIntBetweenMin:prev/2 + randTexture.size.width/2 max:current/2 - randTexture.size.width/2]*((arc4random()%2)==0?-1:1), [self randIntBetweenMin:0 max:current/2 - randTexture.size.height/2]*((arc4random()%2)==0?-1:1));
            }
            else //spawn in other direction
            {
                randLoc = CGPointMake([self randIntBetweenMin:0 max:current/2 - randTexture.size.width/2]*((arc4random()%2)==0?-1:1), [self randIntBetweenMin:prev/2 +randTexture.size.height/2 max:current/2 - randTexture.size.height/2]*((arc4random()%2)==0?-1:1));
            }
            
            
            item.position = randLoc;
            for(SKSpriteNode* otherNode in self.sandItems)
            {
                if(CGRectContainsRect(otherNode.frame, item.frame))
                {
                    success = NO;
                    break;
                }
            }
            success = YES;
        }
        
        item.hidden = self.background.hidden;
        item.zPosition = 10;
        [self.sandItems addObject:item];
        
    }
}

- (void) extendSandToCoverWithCenterPoint:(CGPoint)center distanceFromCenter:(int)dist
{
    float minSizeToExtendBy = 0;
    
    float boundaryMax = self.borderSize/2;
    //check top:
    float topMin = (center.y + dist) - boundaryMax;
    if(topMin > minSizeToExtendBy)minSizeToExtendBy = topMin;
    
    //check bottom:
    float bottomMin = -(center.y - dist) -boundaryMax;
    if(bottomMin>minSizeToExtendBy)minSizeToExtendBy = bottomMin;
    
    //check right:
    float rightMin = (center.x + dist) - boundaryMax;
    if(rightMin > minSizeToExtendBy) minSizeToExtendBy = rightMin;
    
    //check left:
    float leftMin = -(center.x - dist) -boundaryMax;
    if(leftMin > minSizeToExtendBy) minSizeToExtendBy = leftMin;
    
    if(minSizeToExtendBy==0)return;
    int numberToAdd = ceilf(minSizeToExtendBy/self.sandTexture.size.height);
    
    int originalSandCount = [[NSNumber numberWithInteger:self.sand.count]intValue];
    for(int i = 0; i < numberToAdd; i++)
    {
        [self addSandLayer];
    }
    int newSandCount =[[NSNumber numberWithInteger:self.sand.count]intValue];
    
    [self spawnSandItemsWithHowManySandTilesAdded:newSandCount - originalSandCount prevBorderSize:boundaryMax*2 currentBorderSize:self.borderSize];
    
    
        
}

- (void) addSandLayer
{
    
    SKTexture* texture = self.sandTexture;
    
    CGSize textureSize = texture.size;
    
    int borderHeight = self.borderSize + textureSize.height*2;
    int borderWidth = self.borderSize + textureSize.width*2;
    
    for(int i = -borderWidth/2; i <= borderWidth/2 - 1*textureSize.width; i+=textureSize.width)
    {
        //top:
        SKSpriteNode* node = [[SKSpriteNode alloc]initWithTexture:texture];
        node.position = CGPointMake(i + textureSize.width/2, borderHeight/2 - textureSize.height/2);
        
        //bottom:
        SKSpriteNode* node2 = [[SKSpriteNode alloc]initWithTexture:texture];
        node2.position = CGPointMake(i + textureSize.width/2, -borderHeight/2 + textureSize.height/2);
        
        [self.sand addObject:node]; [self.sand addObject:node2];
    }
    
    for(int j = - borderHeight/2; j <= borderHeight/2 - 1*textureSize.height; j+=textureSize.height)
    {
        //top:
        SKSpriteNode* node = [[SKSpriteNode alloc]initWithTexture:texture];
        node.position = CGPointMake(-borderWidth/2 + textureSize.width/2, j + textureSize.height/2);
        
        //bottom:
        SKSpriteNode* node2 = [[SKSpriteNode alloc]initWithTexture:texture];
        node2.position = CGPointMake(borderWidth/2 - textureSize.width/2, j + textureSize.height/2);
        
        [self.sand addObject:node]; [self.sand addObject:node2];
    }
    
    for(SKSpriteNode* node in self.sand)
    {
        if(!node.parent)
            [self.world addChild:node];
        node.hidden = self.background.hidden;
        node.zPosition = 9;
    }
    
    self.borderSize = borderHeight;

}


- (int)randIntBetweenMin:(int)min max:(int)max
{
    if(min>max)return [self randIntBetweenMin:max max:min];//flip
    if(min == max)return min;//they are the same, and mod0 is undefined
    return (arc4random()%(max-min)) + min;
}

- (void) setDataSourceIsAccelerometer:(BOOL)dataSourceIsAccelerometer
{
    if(dataSourceIsAccelerometer == _dataSourceIsAccelerometer)return;
    
    _dataSourceIsAccelerometer = dataSourceIsAccelerometer;

    if(!self.ourPlayer)
        return;
    
    if(dataSourceIsAccelerometer)
    {
        [self startAccelerometerUpdates];
    }
    else
    {
        [self.motionManager stopAccelerometerUpdates];
    }
}

- (void) startAccelerometerUpdates
{
    if(!self.dataSourceIsAccelerometer)return;
    //stop all updates before starting new ones, don't want some duplicate thing going on
    [self.motionManager stopAccelerometerUpdates];
    
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:
     ^(CMAccelerometerData *accelerometerData, NSError *error) {
         [(id) self setAcceleration:accelerometerData.acceleration];
         
         
         //direction:
         CGPoint direction = CGPointMake(accelerometerData.acceleration.x, accelerometerData.acceleration.y);
        
         //scale direciton so that the sqrt of the sum of the squares of x and y is 1
         float hypo = sqrtf(direction.x*direction.x + direction.y*direction.y);
         float scaled = 1/hypo;
         direction = CGPointMake(direction.x*scaled, direction.y*scaled);
         
         
         [self.ourPlayer setDirectionOfAllBalls:direction];
         
         
         //scale velocity now:
         //.19 hypo is considered 100%
         float scaleVeloc = hypo < .19 ? hypo/.19 : 1;
         self.ourPlayer.dampening = scaleVeloc;
         
         
         //[self performSelectorOnMainThread:@selector(accelerometerDataUpdated) withObject:nil waitUntilDone:NO];
     }];
    

}


-(void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

//repeat the video 25 times before rewinding
- (AVAsset*) makeAssetComposition {
    
    int numOfCopies = 25;
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    NSString* str = [[NSBundle mainBundle] pathForResource:@"IMG_1182 (online-video-cutter.com)" ofType:@"mp4"];
    NSURL* url = [NSURL fileURLWithPath:str];
    AVURLAsset* sourceAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    // calculate time
    CMTimeRange editRange = CMTimeRangeMake(CMTimeMake(0, 600), CMTimeMake(sourceAsset.duration.value, sourceAsset.duration.timescale));
    
    NSError *editError;
    
    // and add into your composition
    BOOL result = [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
    
    if (result) {
        for (int i = 0; i < numOfCopies; i++) {
            [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
        }
    }
    
    return composition;
}

- (void) showLogin
{
    if(self.loginIsUp)return;
    
    login* popup = [[login alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width*.96, self.view.frame.size.height*.96)];
    popup.vc = self.vc;
    popup.center = self.view.center;
    popup.transform = CGAffineTransformMakeScale(2, 2);
    [self.view addSubview:popup];
    popup.layer.zPosition = MAXFLOAT;
    popup.delegate = self;
    [UIView animateWithDuration:.2 animations:^{
        popup.transform = CGAffineTransformMakeScale(1, 1);
    }];
    
    self.loginIsUp = YES;
}

- (void) addChild:(SKNode *)node
{
    if([node.name isEqualToString:@"world"])
    {
        [super addChild:node];
        return;
    }
    
    [self.world addChild:node];
}

- (void)createWorld
{
    SKNode *world = [[SKSpriteNode alloc] initWithColor:[SKColor cyanColor] size:CGSizeMake(gridSize, gridSize)];
    world.name = @"world";
    world.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    [self addChild:world];
    self.world = world;
}


- (SKLabelNode *)newHelloNode
{
    SKLabelNode *helloNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    helloNode.text = @"Hello, World!";
    helloNode.fontSize = 42;
    helloNode.position = CGPointMake(CGRectGetMidX(self.world.frame),CGRectGetMidY(self.world.frame));
    helloNode.name = @"helloNode";
    return helloNode;
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



- (void)touchesBegan:(NSSet *) touches withEvent:(UIEvent *)event
{
    
    if(self.dataSourceIsAccelerometer)return;
    
        SKplayer *player = self.ourPlayer;
        if(player)
        {
            UITouch * touch = [touches anyObject];
            
            //touch in scene:
            CGPoint location = [touch locationInNode:self];
            
            //CGPoint location = [touch locationInView:[UIApplication sharedApplication].keyWindow];
            //CGPoint location = [touch locationInNode:self.world];
            
            [self.ourPlayer setDirectionOfAllBallsToAimAtPoint:location];
    }
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesBegan:touches withEvent:event];
}

- (NSMutableDictionary*)players
{
    if(!_players)
    {
        _players = [[NSMutableDictionary alloc] init];
    }
    return _players;
}

- (NSMutableDictionary*) foods
{
    if(!_foods)
    {
        _foods = [[NSMutableDictionary alloc]init];
    }
    return _foods;
}

- (NSMutableDictionary*) viruses
{
    if(!_viruses)
    {
        _viruses = [[NSMutableDictionary alloc] init];
    }
    return _viruses;
}

- (SKplayer*)newSpaceshipWithTrackingID:(NSString*)trackingID withPlayerName:(NSString*)playerName
{
    SKplayer* player = [[SKplayer alloc] init];
    player.trackingID = trackingID;
    [self.players setObject:player forKey:trackingID];
    player.gs = self;
    player.playerName = playerName;
    player.textureManager = self.textureManager;
    
    return player;
}
- (SKplayerBall*)newBallWithNumber:(int)ballNumber player:(SKplayer*)player
{
    SKplayerBall* ball = [[SKplayerBall alloc] initWithColor:[SKColor clearColor] size:CGSizeMake(45, 45)];
    ball.ballNumber = ballNumber;
    [player addBall:ball];
    
    
    [ball createTexture];
    
    return ball;
}
- (SKcircle*)newFoodWithTrackingID:(NSString*)trackingID
{
    SKcircle* circle = [[SKcircle alloc] initWithColor:[SKColor clearColor] size:CGSizeMake(15, 15)];
    circle.trackingID = trackingID;
    [self.foods setObject:circle forKey:trackingID];
    [self.world addChild:circle];
    circle.textureManager = self.textureManager;
    
    [circle createTexture];
    
    return circle;
}

- (SKvirus*) newVirusWithTrackingID:(NSString*)trackingID
{
    SKvirus* virus = [[SKvirus alloc] initWithTexture:[self.virusTextureManager getRandomTexture]];
    virus.trackingID = trackingID;
    [self.viruses setObject:virus forKey:trackingID];
    [self.world addChild:virus];
    
    return virus;
}

- (SKcircleTextureManager*)textureManager
{
    if(!_textureManager)
    {
        _textureManager = [[SKcircleTextureManager alloc] init];
    }
    return _textureManager;
}

- (SKvirusTextureManager*)virusTextureManager
{
    if(!_virusTextureManager)
    {
        _virusTextureManager = [[SKvirusTextureManager alloc]init];
    }
    return _virusTextureManager;
}

- (SKSpriteNode *)newLight
{
    SKSpriteNode *light = [[SKSpriteNode alloc] initWithColor:[SKColor yellowColor] size:CGSizeMake(8,8)];
    
    SKAction *blink = [SKAction sequence:@[
                                           [SKAction fadeOutWithDuration:0.25],
                                           [SKAction fadeInWithDuration:0.25]]];
    SKAction *blinkForever = [SKAction repeatActionForever:blink];
    [light runAction: blinkForever];
    
    return light;
}

static inline CGFloat skRandf() {
    return rand() / (CGFloat) RAND_MAX;
}

static inline CGFloat skRand(CGFloat low, CGFloat high) {
    return skRandf() * (high - low) + low;
}

-(void)didSimulatePhysics
{
    
    NSArray* players = self.players.allValues;
    
    //ensure no collisions between same player's balls:
    
    for(SKplayer* player in players)
    {
        for(int i = 0; i < player.balls.count - 1; i++)
        {
            SKplayerBall* ball = player.balls[i];
            BOOL ballsCannotCollide = NO;
            float timedif = player.lastServerUpdate - ball.splitTime;
            if(timedif<timeBeforeReconnectAfterSplit)ballsCannotCollide = YES;
            for(int j = i + 1; j < player.balls.count; j++)
            {
                SKplayerBall* ball2 = player.balls[j];
                if(!ballsCannotCollide)
                {
                    float timedif = player.lastServerUpdate - ball2.splitTime;
                    if(timedif<timeBeforeReconnectAfterSplit)ballsCannotCollide = true;
                }
                if(!ballsCannotCollide)continue;
                CGPoint offset = rwSub(ball.position, ball2.position);
                float distSquare = offset.x*offset.x + offset.y*offset.y;
                float radSum = ball.getRadius + ball2.getRadius;
                
                if(distSquare<radSum*radSum)
                {
                    //find unit vector to push ball out of ball2
                    float dist = sqrtf(distSquare);
                    float seperation = radSum-dist;
                    float unVecX = offset.x / dist;
                    float unVecY = offset.y /dist;
                    if(isnan(unVecX)||isnan(unVecY)||isnan(seperation))continue;
                    
                    ball.position = CGPointMake(ball.position.x+unVecX*seperation, ball.position.y + unVecY*seperation);
                }
                
            }
        }
    }
    
    
    //ensure in bounds:
    
    
    for(SKplayer* player in players)
    {
        for(SKplayerBall* ball in player.balls)
        {
            CGPoint position = ball.position;
            /*if(player==self.ourPlayer)
             NSLog([NSString stringWithFormat:@"Log: %f %f %f %f",player.position.x, player.position.y, getUptimeInMilliseconds2(), player.physicsBody.velocity.dy
             ]);*/
            int rad = ball.getRadius;
            
            if(position.x > gridSize/2 -  rad|| position.y > gridSize/2 - rad|| position.x < -gridSize/2 + rad || position.y < -gridSize/2 + rad)
            {
                int x = MIN(gridSize / 2 - rad, MAX(position.x, -gridSize / 2 + rad));
                int y = MIN(gridSize / 2 - rad, MAX(position.y, -gridSize / 2 + rad));
                ball.position = CGPointMake(x, y);
            }
        }
        
    }
    
    //let player recalc speed if needed:
    if(!self.dataSourceIsAccelerometer)
    {
        [self.ourPlayer runTouchUpdate];
    }
    
    //let server handle collisions
    //[self collisionDetection];
}

- (CGPoint)randomLocInRect:(CGRect)rect
{
    return CGPointMake([self randIntBetweenMin:rect.origin.x max:rect.origin.x+rect.size.width], [self randIntBetweenMin:rect.origin.y max:rect.origin.y+rect.size.height]);
}

- (void) didFinishUpdate
{
    SKplayer* player = self.ourPlayer;
    if(player)
    {
        CGPoint center = [player getCenterPoint];
        [self adjustScale];
        [self centerOnPoint:center];
        if(!self.background.hidden)
            [self extendSandToCoverWithCenterPoint:center distanceFromCenter:(self.frame.size.height/self.world.yScale)/2];
        
        /*
        //remove sand items not on screen:
        for(SKNode* sandItem in self.sandItems)
        {
            CGPoint absPos = CGPointMake(fabs(sandItem.position.x), fabs(sandItem.position.y));
            if(absPos.x>center.x+(self.frame.size.height/self.world.xScale)/2 ||
               absPos.y>center.y+(self.frame.size.height/self.world.yScale)/2)
               [sandItem removeFromParent];
            else if (!sandItem.parent)
                [self.world addChild:sandItem];
        }*/
    }

}

- (void) centerOnPoint:(CGPoint)point
{
    if(isnan(point.x)||isnan(point.y))return;
    CGPoint cameraPositionInScene = [self convertPoint:point fromNode:self.world];
    self.world.position = CGPointMake(self.world.position.x - cameraPositionInScene.x,self.world.position.y - cameraPositionInScene.y);
    
    self.background.position = self.background2.position =point;
    
    self.background.size = self.background2.size = CGSizeMake(self.view.frame.size.width/self.world.xScale, self.view.frame.size.height/self.world.yScale);
    //NSLog(NSStringFromCGPoint(node.parent.position));
}

- (void) setGridID:(NSString *)gridID
{
    _gridID = gridID;
    [self connectedToServer];
}

- (void) useCreationResponse:(NSDictionary *)response
{
    self.playerID = [response valueForKey:@"playerID"];
    self.gridID = [response valueForKey:@"gridID"];
    
    response = [response valueForKey:@"playerObject"];
    SKplayer *player = self.ourPlayer;
    if(!player)
        player = [self newSpaceshipWithTrackingID:[response valueForKey:@"trackingID"] withPlayerName:[response valueForKey:@"name"]];
    player.isOurPlayer = YES;
    player.dampening = [[response valueForKey:@"dampening"]floatValue];
    
    response = [response valueForKey:@"b"][0];
    
    NSDictionary* loc = [response valueForKey:@"l"];
    
    SKplayerBall* firstBall = [self newBallWithNumber:1 player:player];
    firstBall.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
    firstBall.targetLocation = firstBall.position;
    
    
    firstBall.mass = [[response valueForKey:@"m"] intValue];
    
    CGPoint direction = CGPointMake([[response valueForKey:@"dx"] floatValue], [[response valueForKey:@"dy"] floatValue]);
    firstBall.physicsBody.velocity = [self velocityFromDirection:direction player:firstBall];
    
    
    self.ourPlayer = player;
    
}


int lastUpdateSeq = 0;
const int superSpeedLastTime = 3000;//3 sec
const int superSpeedCooldown = 30000 + superSpeedLastTime;//33 sec -- 30 sec + 3 sec lasting time. Ignore the first 3s when displaying the "charging" bars
- (void) gotResponse:(NSNotification*)notification
{
    NSDictionary* desc = [notification userInfo];
    //NSLog(desc.description);
    int updateSeq = [[desc valueForKey:@"uS"] intValue];
    if(updateSeq<=lastUpdateSeq)return;
    lastUpdateSeq = updateSeq;
    
    NSArray* players = [desc valueForKey:@"ps"];
    
    
    
    for(NSDictionary* player in players)
    {
        
        
        NSString* trackingID = [player valueForKey:@"id"];
        SKplayer* player2 = [self.players valueForKey:trackingID];
        if(!player2)
        {
            if(![player valueForKey:@"n"])continue;//it will be created when we get its name!
            player2 = [self newSpaceshipWithTrackingID:trackingID withPlayerName:[player valueForKey:@"n"]];
            player2.isOurPlayer = player2==self.ourPlayer;
        }
        
        player2.lastServerUpdate = [[player valueForKey:@"su"] intValue];
        NSNumber* ssu = [player valueForKey:@"ssu"];
        if(ssu)
        {
            player2.lastTimeSpeedUsed = [ssu intValue];
        }
        BOOL superSpeedOn =  (player2.lastServerUpdate - player2.lastTimeSpeedUsed) <= superSpeedLastTime;
        player2.superSpeedOn = superSpeedOn;
        
        NSNumber* d = [player valueForKey:@"d"];
        if(d)
        {
        player2.dampening = [d floatValue];
        }
        
        NSArray* balls = [player valueForKey:@"b"];
        for(int i = 0; i < balls.count; i++)
        {
            NSDictionary* ball = balls[i];
            
            //find matching ball:
            //start by looking at the ball matching this ball's index
            SKplayerBall* ball2;
            int targetBallNumber = [[ball valueForKey:@"bN"] intValue];
            
            for(int j = 0; j < player2.balls.count; j++)
            {
                SKplayerBall* temp = player2.balls[(j+i)%player2.balls.count];
                if(temp.ballNumber == targetBallNumber)
                {
                    ball2 = temp;
                    break;
                }
            }
            if(!ball2)
            {
                ball2 = [self newBallWithNumber:targetBallNumber player:player2];
                //if it was created due to a split, get it's split "parent" and copy over the dataCacher:
                int parentSplit = [[ball valueForKey:@"sFB"] intValue];
                if(parentSplit)
                {
                    SKplayerBall* parentBall;
                    for(SKplayerBall* ballP in player2.balls)
                    {
                        if(ballP.ballNumber==parentSplit)
                        {
                            parentBall = ballP;
                            break;
                        }
                    }
                    
                    if(parentBall)
                    {
                        ball2.dataCacher = [parentBall.dataCacher deepCopy];
                    }
                }
                
                ball2.splitTime = [[ball valueForKey:@"sT"] intValue];
            }
            
            
            CGPoint newLocation;
            int ts = [[player valueForKey:@"ts"]intValue];
            {
                player2.lastTimeStampReceivedFromServer = ts;
            }
            //fix our player
            if(player2==self.ourPlayer)
            {
                int timestamp = ts;
                if(timestamp)
                {
                    CGPoint diffSince = [ball2.dataCacher changesSince:timestamp];
                    //NSLog(@"diffSince");
                    //NSLog(NSStringFromCGPoint(diffSince));
                    //NSLog([NSString stringWithFormat:@"%d", [[player valueForKey:@"xD"] intValue]]);
                    //NSLog([NSString stringWithFormat:@"%d", [[player valueForKey:@"yD"] intValue]]);
                    
                    //scale to world:
                    diffSince.x *= self.world.xScale;
                    diffSince.y *= self.world.yScale;
                    
                    //NSLog([NSString stringWithFormat:@"%d, %d", [[ball valueForKey:@"yD"] intValue], player2.lastServerUpdate]);
                    
                    float x = [[ball valueForKey:@"x"] floatValue];
                    float y = [[ball valueForKey:@"y"] floatValue];
                    
                    int xD = [[ball valueForKey:@"xD"] intValue];
                    int yD = [[ball valueForKey:@"yD"] intValue];
                    if(isnan(x)||isnan(y))
                    {
                        
                    }
                    
                    newLocation =CGPointMake((x&&!isnan(x))?x:ball2.position.x + diffSince.x - ((xD&&!isnan(xD))?xD:0)*self.world.xScale, (y&&!isnan(y))?y:ball2.position.y +diffSince.y - ((yD&&!isnan(yD))?yD:0)*self.world.yScale);
                    //entryObj* lastEntry = self.dataCacher.lastEntry;
                    //self.ourPlayer.physicsBody.velocity = [self velocityFromDirection:CGPointMake(lastEntry.dirx, lastEntry.diry) damp:lastEntry.damp massdamp:lastEntry.massdamp superSpeed:player2.superSpeedOn];
                }
            }
            
            
            else
            {
                float x = [[ball valueForKey:@"x"] floatValue];
                float y = [[ball valueForKey:@"y"] floatValue];
                if(isnan(x)||isnan(y))
                {
                    NSLog(@"nan 2");
                }
                newLocation = CGPointMake((x&&!isnan(x))?x:ball2.position.x, (y&&!isnan(y))?y:ball2.position.y);
                //float scaleVelocity = [[player valueForKey:@"dampening"] floatValue];
                
                //player2.direction = direction;
                
                
                //player2.physicsBody.velocity = [self velocityFromDirection:direction damp:player2.dampening massdamp:player2.massFactor superSpeed:player2.superSpeedOn];
            }
            
            
            
            //SKAction* action = [SKAction moveByX:newLocation.x - player2.position.x y:newLocation.y-player2.position.y duration:.2];
            
            //multiply the "newLocation" - "currentLocation" by 2, so that we will see what we expect the server to see once our current packets arrive at it.
            
            if(ball2.position.x==0 && ball2.position.y==0)//just created the ball
            {
                ball2.position = newLocation;
            }
            else
            {
            CGPoint newLocationDoubled = CGPointMake(newLocation.x+(newLocation.x-ball2.position.x), newLocation.y+(newLocation.y-ball2.position.y));
            
            newLocationDoubled.x = MIN(gridSize / 2 - ball2.getRadius, MAX(newLocationDoubled.x, -gridSize / 2 + ball2.getRadius));
            newLocationDoubled.y = MIN(gridSize / 2 - ball2.getRadius, MAX(newLocationDoubled.y, -gridSize / 2 + ball2.getRadius));
            
            ball2.targetLocation = newLocationDoubled;
            SKAction* action = [SKAction moveTo:ball2.targetLocation duration:.4];
            [ball2 runAction:action];
            }
            
            float dx = [[ball valueForKey:@"dx"] floatValue];
            float dy = [[ball valueForKey:@"dy"] floatValue];
            
            
            if([ball objectForKey:@"dx"]==nil || [ball objectForKey:@"dy"]==nil)
            {
                CGPoint dir = rwNormalize(CGPointMake(ball2.physicsBody.velocity.dx, ball2.physicsBody.velocity.dy));
                dx = dir.x;
                dy = dir.y;
            }
            
            CGPoint direction = CGPointMake(dx, dy);
            CGVector targetVeloc = [self velocityFromDirection:direction player:ball2];
            ball2.physicsBody.velocity = targetVeloc;
            
            
            //increase velocity so that in .2 sec it will also cover the distance newLocation-self.position:
            
            /*
             float newX = player2.physicsBody.velocity.dx + (newLocation.x-player2.position.x)/.2;
             float newY = player2.physicsBody.velocity.dy + (newLocation.y-player2.position.y)/.2;
             
             player2.physicsBody.velocity = CGVectorMake(newX, newY);
             */
            
            
            int newMass = [[ball valueForKey:@"m"] intValue];
            if(newMass)
            {
                ball2.mass = newMass;
            }
            
            ball2.updateSeq = updateSeq;

            
        }
        
        player2.updateSeq = updateSeq;
        
        //Update ss bar on top
        if(player2==self.ourPlayer)
        {
            float timeDif = [[player valueForKey:@"su"] floatValue] - player2.lastTimeSpeedUsed - superSpeedLastTime;//ignore last time when doing this
            float chargePercent = MAX(MIN(1, timeDif/superSpeedCooldown),0);
            
            float halfRects = self.superSpeedRects.count/2;
            int highestChargeOut = (int)(chargePercent*halfRects);
            int i;
            for(i = 0; i < highestChargeOut; i++)
            {
                coveredRect* rect = self.superSpeedRects[i];
                [rect turnOn:YES];
            }
            for(int j = i; j < halfRects; j++)
            {
                coveredRect* rect = self.superSpeedRects[j];
                [rect turnOn:NO];
            }
            
            //other side now:
            for(i = (int)self.superSpeedRects.count-1; i >= self.superSpeedRects.count - highestChargeOut; i--)
            {
                coveredRect* rect = self.superSpeedRects[i];
                [rect turnOn:YES];
            }
            for(int j = i; j >= halfRects; j--)
            {
                coveredRect* rect = self.superSpeedRects[j];
                [rect turnOn:NO];
            }
            
            [self.ssButton makeVisible:chargePercent==1];
            
        }
        
      
    }

    
    
    
      NSArray* allPlayers = self.players.allValues;
        for(SKplayer* player in allPlayers)
        {
            if(player.updateSeq<updateSeq)//means it wasn't included in last update
            {
                for(SKplayerBall* ball in player.balls)
                {
                    [ball removeFromParent];
                }
                [self.players removeObjectForKey:player.trackingID];
            }
            else
            {
                //check balls to see if any of them need to go:
                for(int i = 0; i < player.balls.count; i++)
                {
                    SKplayerBall* ball = player.balls[i];
                    if(ball.updateSeq<updateSeq)
                    {
                        [player removeBall:ball];
                    }
                    
                }

            }
        }
    
    [self rankPlayersWithServerInfo];
    
    NSArray* foodsAdded = [desc valueForKey:@"fA"];
    for(NSDictionary* food in foodsAdded)
    {
        SKcircle* foodObj = [self newFoodWithTrackingID:[food valueForKey:@"id"]];
        NSDictionary* loc = [food valueForKey:@"l"];
        foodObj.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
    }
    
    NSArray* foodsRemoved = [desc valueForKey:@"fR"];
    for(NSDictionary* food in foodsRemoved)
    {
        SKcircle* foodObj = [self.foods valueForKey:[food valueForKey:@"id"]];
        if(foodObj)
        {
            [foodObj removeFromParent];
            [self.foods removeObjectForKey:[food valueForKey:@"id"]];
            
        }
    }
    
    //ensure food count correct:
    
    NSNumber* foodsFromServer = [desc valueForKey:@"aFC"];
    if(foodsFromServer){
    float currentTime = getUptimeInMilliseconds2();
    NSInteger dif = [foodsFromServer integerValue] - self.foods.count;
    if(currentTime - self.lastTimeRequestedFoods > 2000 && labs(dif)>5)//at least 5 foods off - we can be 1 or 2 foods off, its fine.
    {
        NSLog(@"Requesting foods!!!");
        
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/requestfoods" withData:@{@"gridID":self.gridID}];
        self.lastTimeRequestedFoods = currentTime;
    }
    else
    {
        //Ignore for now -- this rarely happens, and when it happens incorrectly it will cause phone to glitch
        /*
        //we may have hidden a food that was accidently mistaken for a collision that didn't happen:
        NSArray* allFoods = self.foods.allValues;
        for(SKcircle* food in allFoods)
        {
            food.alpha = 1;
        }
         */
    }
    }
    //viruses:
    NSArray* virusesAdded = [desc valueForKey:@"vA"];
    for(NSDictionary* virus in virusesAdded)
    {
        SKvirus* virusObj = [self newVirusWithTrackingID:[virus valueForKey:@"id"]];
        NSDictionary* loc = [virus valueForKey:@"l"];
        virusObj.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
    }
    
    NSArray* virusesRemoved = [desc valueForKey:@"vR"];
    for(NSDictionary* virus in virusesRemoved)
    {
        SKcircle* virusObj = [self.viruses valueForKey:[virus valueForKey:@"id"]];
        if(virusObj)
        {
            [virusObj removeFromParent];
            [self.viruses removeObjectForKey:[virus valueForKey:@"id"]];
            
        }
    }
    
    //ensure food count correct:
    NSNumber* virusesFromServer = [desc valueForKey:@"aVC"];
    if(virusesFromServer){
    float currentTime2 = getUptimeInMilliseconds2();
    if(![virusesFromServer isEqualToNumber:[NSNumber numberWithInteger:self.viruses.count]] && currentTime2 - self.lastTimeRequestedViruses > 2000)
    {
        NSLog(@"Requesting viruses!!!");
        
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/requestviruses" withData:@{@"gridID":self.gridID}];
        self.lastTimeRequestedViruses = currentTime2;
    }
    }
    
}
float getUptimeInMilliseconds2()
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


- (void) speedClicked
{
    if(self.ourPlayer && self.gridID && self.playerID)
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/usesuperspeed" withData:@{@"gridID":self.gridID, @"playerID":self.playerID}];
}


- (void) gotFoods:(NSNotification*)notif
{
    NSDictionary* desc = [notif userInfo];
    NSArray* actualFoods = ((NSDictionary*)[desc valueForKey:@"foods"]).allValues;
    
    //remove all old foods:
    NSArray* oldFoods = self.foods.allValues;
    for(SKcircle* food in oldFoods)
    {
        [food removeFromParent];
    }
    
    //create a new dictionary for foods. if a food already exists in current dic and should be used again, just transfer; else, make a new food:
    NSMutableDictionary* newFoods = [[NSMutableDictionary alloc] init];
    for(NSDictionary* serverFood in actualFoods)
    {
        SKcircle* food = [self.foods valueForKey:[serverFood valueForKey:@"id"]];
        if(!food)
        {
            food = [self newFoodWithTrackingID:[serverFood valueForKey:@"id"]];
            NSDictionary* loc = [serverFood valueForKey:@"l"];
            food.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
            
        }
        else
        {   //food was removed above
            [self.world addChild:food];
        }
        [newFoods setObject:food forKey:food.trackingID];
    }
    
    self.foods = newFoods;
}

- (void) gotViruses:(NSNotification*)notif
{
    NSDictionary* desc = [notif userInfo];
    NSArray* actualViruses = ((NSDictionary*)[desc valueForKey:@"viruses"]).allValues;
    
    //remove all old viruses:
    NSArray* oldViruses = self.viruses.allValues;
    for(SKvirus* virus in oldViruses)
    {
        [virus removeFromParent];
    }
    
    //create a new dictionary for foods. if a food already exists in current dic and should be used again, just transfer; else, make a new food:
    NSMutableDictionary* newViruses = [[NSMutableDictionary alloc] init];
    for(NSDictionary* serverVirus in actualViruses)
    {
        SKvirus* virus = [self.viruses valueForKey:[serverVirus valueForKey:@"id"]];
        if(!virus)
        {
            virus = [self newVirusWithTrackingID:[serverVirus valueForKey:@"id"]];
            NSDictionary* loc = [serverVirus valueForKey:@"l"];
            virus.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
            
        }
        else
        {   //food was removed above
            [self.world addChild:virus];
        }
        [newViruses setObject:virus forKey:virus.trackingID];
    }
    
    self.viruses = newViruses;
}


- (NSMutableArray*)playerRankings
{
    if(!_playerRankings)
    {
        _playerRankings = [[NSMutableArray alloc] init];
    }
    return _playerRankings;
}

- (NSMutableArray*)labelsForRanking
{
    if(!_labelsForRanking)
    {
        _labelsForRanking = [[NSMutableArray alloc] init];
        for(int i = 0; i < 10; i ++)
        {
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8, 8*(i+1) + i*20, self.sv.frame.size.width - 8*2, 20)];
            label.text = [NSString stringWithFormat:@"%d", i+1];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont fontWithName:@"Chalkduster" size:18];
            [_labelsForRanking addObject:label];
        }
    }
    return _labelsForRanking;
}

- (void) rankPlayersWithServerInfo
{
    
    /*
    for(NSDictionary* player in players)
    {
        NSString* trackingID = [player valueForKey:@"id"];
        SKplayer* player2 = [self.players valueForKey:trackingID];
        if(!player2)continue;//not our job to create player objects
        
        if(player2.rank==0)//not yet ranked
        {
            int newRank = 1;
            while(newRank -1 < self.playerRankings.count && player2.mass < ((SKplayer*)self.playerRankings[newRank-1]).mass)
            {
                newRank++;
            }
            player2.rank = newRank;
            for(int i = newRank-1; i < self.playerRankings.count; i++)
            {
                //self.playerRankings[i+1] = self.playerRankings[i];
                SKplayer* player = self.playerRankings[i];
                player.rank++;
            }
            [self.playerRankings insertObject:player2 atIndex:newRank-1];
        }
        else
        {
            int newRank = player2.rank;
            
            //move up:
            while(newRank > 1 && player2.mass > ((SKplayer*)self.playerRankings[newRank-2]).mass)
            {
                newRank--;
            }
            
            //move down:
            
            while (newRank < self.playerRankings.count && player2.mass < ((SKplayer*)self.playerRankings[newRank]).mass)
            {
                newRank++;
            }
            
            int oldRank = player2.rank;
            
            int dif = newRank - oldRank;
            
            if(dif==0)continue;
            
            if(dif > 0)//moved down the list
            {
                for(int i = oldRank; i < newRank; i++)
                {
                    SKplayer* player = self.playerRankings[i];
                    player.rank--;
                }
            }
            else if (dif<0)//moved up the list
            {
                for(int i = oldRank - 2; i >= newRank - 1; i--)
                {
                    SKplayer* player = self.playerRankings[i];
                    player.rank++;
                }
            }
            
            [self.playerRankings removeObjectAtIndex:oldRank-1];
            
            if(oldRank < newRank)
            {
                newRank--;
            }
            
            [self.playerRankings insertObject:player2 atIndex:newRank-1];
            
            player2.rank = newRank;
            
            
        }
    }*/
    
    NSMutableArray* players = self.players.allValues.mutableCopy;
    [self sortPlayers:players left:0 right:[[NSNumber numberWithInteger:players.count-1 ] intValue]];
    self.playerRankings = players;
    [self updateRankView];
}


//simple quicksort algorythm. it's fine, there's max 20 ppl per grid, not that much work
- (void) sortPlayers:(NSMutableArray*)arr left:(int)left right:(int)right
{
    int i = left, j = right;
    SKplayer* tmp;
    int pivot = ((SKplayer*)arr[(left + right) / 2]).totalMass;
    
    /* partition */
    while (i <= j) {
        while (((SKplayer*)arr[i]).totalMass > pivot)
            i++;
        while (((SKplayer*)arr[j]).totalMass < pivot)
            j--;
        if (i <= j) {
            tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
            i++;
            j--;
        }
    };
    
    /* recursion */
    if (left < j)
        [self sortPlayers:arr left:left right:j];
    if (i < right)
        [self sortPlayers:arr left:i right:right];

    
}





- (void) updateRankView
{
    int i;
    for(i = 0; i < self.playerRankings.count && i < self.labelsForRanking.count; i++)
    {
        UILabel* label = self.labelsForRanking[i];
        label.text = [NSString stringWithFormat:@"\u200E %d. %@: %d", i+1, ((SKplayer*)self.playerRankings[i]).playerName, ((SKplayer*)self.playerRankings[i]).totalMass];
        if((SKplayer*)self.playerRankings[i]==self.ourPlayer)
        {
            label.textColor = [UIColor redColor];
            label.text = [NSString stringWithFormat:@"\u200E %d. %@: %d   <-- You!", i+1, ((SKplayer*)self.playerRankings[i]).playerName, ((SKplayer*)self.playerRankings[i]).totalMass];
        }
        else
        {
            label.textColor = [UIColor blackColor];
        }
        
        if(label.superview != self.sv)
        {
            [self.sv addSubview:label];
            
            
        }
    }
    
    UILabel* bottomLabel = ((UILabel*)self.labelsForRanking[i-1]);
    self.sv.contentSize = CGSizeMake(self.sv.frame.size.width, bottomLabel.frame.size.height + bottomLabel.frame.origin.y + 8);
    
    for(; i < self.labelsForRanking.count;i++)
    {
        UILabel * label = self.labelsForRanking[i];
        [label removeFromSuperview];
    }
    
}


//Collisions disabled now on client side! Ignore what's below!

//a collision is only considered if the distance between the centers is smaller than the sum of the two radi minus half the smaller radius of the two
- (void) collisionDetection
{
    
    NSMutableArray* collisions = [[NSMutableArray alloc] init];//these are just OUR player's collisions - tell server only about what we hit, not what others hit.
    
    //compare square of distance since ^2 is faster than sqrt
    NSArray* allPlayers = self.players.allValues;
    NSArray* allFoods = self.foods.allValues;
    for(int i = 0; i < allPlayers.count; i++)
    {
        SKplayerBall* player1 = allPlayers[i];
        float r1 = player1.getRadius;
        
        for(int j = i + 1; j < allPlayers.count; j++)
        {
            SKplayerBall* player2 = allPlayers[j];
            
            float r2 = player2.getRadius;
            float radSqr = r1+r2;radSqr*=radSqr;
            CGPoint offset = rwSub(player1.position, player2.position);
            float distSquare = offset.x*offset.x + offset.y*offset.y;
            
            if(distSquare<radSqr)
            {
                float smallest = r1<r2?r1:r2;
                float dist = sqrtf(distSquare);
                if(dist < r1+r2 - smallest/2)
                {
                    //collision:
                    NSDictionary* collision = @{@"first":player1.trackingID, @"second":player2.trackingID, @"arePlayers":[NSNumber numberWithBool:YES]};
                    if(player1==self.ourPlayer)
                        [collisions addObject:collision];
                    [self performTakeOver:player1 target:player2];
                }
            }
            
        }
        
        //now compare against the foods:
        float r1Squared = r1*r1;
        for(SKcircle* food in allFoods)
        {
            if(food.alpha==0)continue;//alpha=0 means it was eaten
            CGPoint offset = rwSub(player1.position, food.position);
            float distSquare = offset.x*offset.x + offset.y*offset.y;
            
            if(distSquare < r1Squared)
            {
                //collision:
                NSDictionary* collision = @{@"first":player1.trackingID, @"second":food.trackingID, @"arePlayers":[NSNumber numberWithBool:NO]};
                if(player1==self.ourPlayer)
                    [collisions addObject:collision];
                [self performTakeOver:player1 target:food];
            }
        }
    }
    
    if(collisions.count)
    {
        //Put this off for now - needs caching. Without caching, player moves already by the time the data gets to the server, and thus no collision is detected
        /*
        //tell server
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/collisiondetected" withData:@{@"gridID":self.gridID, @"collisions":collisions}];
         */
    }
    
    
}

- (void) performTakeOver:(SKplayerBall*)player target:(SKcircle*)target
{
    if([target isKindOfClass:[SKplayerBall class]])
    {
        SKplayerBall* player2 = (SKplayerBall*)target;
        BOOL firstIsSmaller = player.mass < player2.mass;
        BOOL atLeastTenPercentBigger = firstIsSmaller ? player.mass*1.1<player2.mass : player2.mass*1.1<player.mass;
        
        if(atLeastTenPercentBigger)
        {
            //let server handle
            /*
            SKplayer* winner  = firstIsSmaller ? player2 : player;
            SKplayer* loser = firstIsSmaller ? player : player2;
            
            
            if(loser ==self.ourPlayer)return;//remove our player only if we are told we lost.
            [self.players removeObjectForKey:loser.trackingID];
            [loser removeFromParent];
            loser = nil;
            
            
            winner.mass += loser.mass;*/
        }
    }
    else
    {
        //target.alpha = 0;//just hide for now
        //player.mass++;
    }
    
}

- (void) setOurPlayer:(SKplayer *)ourPlayer
{
    _ourPlayer = ourPlayer;
    if(self.updateTimer)
        [self.updateTimer invalidate];
    if(ourPlayer)//if its nil, dont set a timer
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(sendMessageToServer) userInfo:nil repeats:YES];
    
    if(ourPlayer)
        [self startAccelerometerUpdates];
    else
        [self.motionManager stopAccelerometerUpdates];
}

- (void) sendMessageToServer
{
    
    if(!self.ourPlayer)return;
    if(isnan(self.ourPlayer.dampening))return;
    if(!self.ourPlayer.balls)return;
    if(self.ourPlayer.balls.count==0)return;
    
    NSMutableArray* balls = [[NSMutableArray alloc] init];
    
    int timestamp = 0;
    //float oldDamp = 0;
    for(SKplayerBall* ball in self.ourPlayer.balls)
    {
    
        if(isnan(ball.direction.x) || isnan(ball.direction.y))continue; //to make sure not "nan"
        
        
        float newDx = round(ball.direction.x*100000)/100000;
        float newDy = round(ball.direction.y*100000)/100000;
        
        
        //float oldDx = round(ball.dataCacher.lastEntry.dirx*100000)/100000;
        //float oldDy = round(ball.dataCacher.lastEntry.diry*100000)/100000;
        
        //if(newDx==oldDx && newDy==oldDy)continue;//if direction didn't change, don't send an update for this ball, no need..
        
        [balls addObject:@{@"dx":[NSNumber numberWithDouble: newDx], @"dy":[NSNumber numberWithDouble:newDy], @"bN":[NSNumber numberWithInt:ball.ballNumber]}];
        
        //its fine, timestamp won't change that much from ball to ball!
         timestamp = (int)[ball.dataCacher cacheDirection:ball.direction damp:self.ourPlayer.dampening massdamp:ball.massFactor superSpeed:self.ourPlayer.superSpeedOn timeSinceSplit:self.ourPlayer.lastServerUpdate - ball.splitTime];
        
        ball.physicsBody.velocity = [self velocityFromDirection:ball.direction player:ball];
        
        //oldDamp = ball.dataCacher.lastEntry.damp;
        //oldDamp = roundf(oldDamp*100000)/100000;
    }
    
    float newDamp = roundf(self.ourPlayer.dampening*100000)/100000;
    if(balls.count==0 /*&& fabsf(newDamp-oldDamp)<.001*/)return;
    
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/setplayermovement" withData:@{@"gridID":self.gridID, @"playerID":self.playerID, @"balls":balls, @"dampening":[NSNumber numberWithFloat: newDamp], @"timestamp":[NSNumber numberWithInt:timestamp]}];
    
    
    
}




- (void) weLost
{
    
    NSArray* allPlayers = self.players.allValues;
    for(SKplayer* player in allPlayers)
    {
        [player removeAllBalls];
        [self.players removeObjectForKey:player.trackingID];
    }
    self.players = nil;
    
    self.ourPlayer = nil;
    self.gridID = nil;
    self.playerID = nil;
    
    NSArray* allFoods = self.foods.allValues;
    for(SKcircle* food in allFoods)
    {
        [food removeFromParent];
        [self.foods removeObjectForKey:food.trackingID];
    }
    self.foods = nil;
    
    NSArray* allViruses = self.viruses.allValues;
    for(SKvirus* virus in allViruses)
    {
        [virus removeFromParent];
        [self.foods removeObjectForKey:virus.trackingID];
    }
    self.viruses = nil;
    
    self.lastTimeRequestedFoods = self.lastTimeRequestedViruses = 0;
    
    [self.playerRankings removeAllObjects];
    
    
    lastUpdateSeq = 0;
    
    [self showLogin];
    
    
    
}

- (void) dealloc
{
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"gU" sender:self];
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"requestFoods" sender:self];
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"youWereEaten" sender:self];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer unSignUpToKnowWhenConnectionToServerEstablishedWithSender:self];
}




- (CGVector)velocityFromDirection:(CGPoint)direction player:(SKplayerBall*)ball
{
    float splitTimeDif = ((SKplayer*)ball.getPlayer).lastServerUpdate - ball.splitTime;
    float splitMult = (splitTimeDif>0 && splitTimeDif<threshHoldForSpeedBonus)?maxSplitMult-splitTimeDif*((maxSplitMult-1)/threshHoldForSpeedBonus):1;
    //NSLog([NSString stringWithFormat:@"Velocity: %f",direction.y*defVeloc*((SKplayer*)ball.getPlayer).dampening*ball.massFactor*self.world.yScale*(((SKplayer*)ball.getPlayer).superSpeedOn?defaultSuperSpeedMult:1) * splitMult]);
    
    return CGVectorMake(direction.x*defVeloc*((SKplayer*)ball.getPlayer).dampening*ball.massFactor*self.world.xScale*(((SKplayer*)ball.getPlayer).superSpeedOn?defaultSuperSpeedMult:1) * splitMult
                        /*+(player.targetLocation.x - player.position.x)/.3*/
                        , direction.y*defVeloc*((SKplayer*)ball.getPlayer).dampening*ball.massFactor*self.world.yScale*(((SKplayer*)ball.getPlayer).superSpeedOn?defaultSuperSpeedMult:1) * splitMult
                        /*+(player.targetLocation.y - player.position.y)/.3*/);
    
    
}


- (void) adjustScale
{
    if(!self.ourPlayer)return;
    if(self.ourPlayer.superSpeedOn && self.shouldTurnOffSpeedScale)return;//don't change scale when we're zoomed out for speed
    
    NSDictionary* enclosingCircle = self.ourPlayer.getCenterAndRadiusOfAllBalls;
    
    int screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float currentScale = self.scale;
    float currentWidthToScreen = ([[enclosingCircle valueForKey:@"radius"] floatValue]*2*currentScale)/screenWidth;
    
    float newScale = self.scale;
    if(currentWidthToScreen<.08)
    {
        newScale = currentScale*(.2/currentWidthToScreen);
        [self.world runAction:[SKAction scaleTo:newScale duration:2]];
    }
    else if (currentWidthToScreen>(self.ourPlayer.balls.count>=2 ? .8 : .35))
    {
        newScale = currentScale*((self.ourPlayer.balls.count>=2 ?.6:.2)/currentWidthToScreen);
        [self.world runAction:[SKAction scaleTo:newScale duration:2]];
    }
    
    self.scale = newScale;
    if(self.ourPlayer.superSpeedOn && !self.shouldTurnOffSpeedScale)
    {
        [self.world runAction:[SKAction scaleBy:.5 duration:.2]];
        self.shouldTurnOffSpeedScale = YES;
    }
    else if(self.shouldTurnOffSpeedScale)
    {
        [self.world runAction:[SKAction scaleBy:2 duration:.2]];
        self.shouldTurnOffSpeedScale = NO;
    }
    
}

- (void) sendSplitEventToServer
{
    if(!self.ourPlayer)return;
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/splitplayer" withData:@{@"gridID":self.gridID, @"playerID":self.playerID}];
}
@end
