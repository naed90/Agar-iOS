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

#import "AppDelegate.h"
#import "socketDealer.h"


#define gridSize 5000

#define defVeloc 400


@interface GameScene ()


@property BOOL contentCreated;

@property (nonatomic, strong) SKNode* world;

@property (strong, nonatomic) NSString* playerID;
@property (strong, nonatomic) NSString* gridID;
@property (strong, nonatomic) SKplayer* ourPlayer;

@property (strong, nonatomic) NSMutableDictionary* players;//trackingID to player
@property (strong, nonatomic) NSMutableDictionary* foods;//trackingID to food

@end


@implementation GameScene


- (void)didMoveToView: (SKView *) view
{
    if (!self.contentCreated)
    {
        [self createSceneContents];
        self.contentCreated = YES;
    }
}

- (void)createSceneContents
{
    
    self.backgroundColor = [SKColor whiteColor];
    self.scaleMode = SKSceneScaleModeAspectFit;
    //self.scaleMode = SKSceneScaleModeResizeFill;
    self.anchorPoint = CGPointMake (0.5,0.5);
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    [self createWorld];
    //[self addChild: [self newHelloNode]];
    
    SKAction *makeRocks = [SKAction sequence: @[
                                                [SKAction performSelector:@selector(addRock) onTarget:self],
                                                [SKAction waitForDuration:.3 withRange:.2]
                                                ]];
    //[self runAction: [SKAction repeatActionForever:makeRocks]];
    login* popup = [[login alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width*.92, self.view.frame.size.height*.92)];
    popup.center = self.view.center;
    popup.transform = CGAffineTransformMakeScale(2, 2);
    [self.view addSubview:popup];
    popup.delegate = self;
    [UIView animateWithDuration:.2 animations:^{
        popup.transform = CGAffineTransformMakeScale(1, 1);
    }];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"gridUpdate" sender:self withSelector:@selector(gotResponse:)];
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"requestFoods" sender:self withSelector:@selector(gotFoods:)];
    
    
    //Draw boundaries:
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(-gridSize, -gridSize, gridSize*2, gridSize*2)];
    UIBezierPath* smallMaskPath = [UIBezierPath bezierPathWithRect:CGRectMake(-gridSize/2, -gridSize/2, gridSize, gridSize)];
    [clipPath appendPath:smallMaskPath];
    clipPath.usesEvenOddFillRule = YES;
    SKShapeNode* node = [SKShapeNode shapeNodeWithPath:clipPath.CGPath];
    [self.world addChild:node];
    node.position = CGPointMake(CGRectGetMidX(self.world.frame), CGRectGetMidY(self.world.frame));
    node.fillColor = [SKColor orangeColor];
    //node.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:node.path];
    //node.physicsBody.dynamic = NO;
    //[[UIColor orangeColor] setFill];
    //[clipPath fill];
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
    SKNode *world = [[SKSpriteNode alloc] initWithColor:[SKColor colorWithWhite:.1 alpha:.8] size:CGSizeMake(gridSize, gridSize)];
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
    
        SKplayer *player = self.ourPlayer;
        if(player)
        {
            UITouch * touch = [touches anyObject];
            CGPoint location = [touch locationInNode:self.world];
            
            CGPoint offset = rwSub(location, player.position);
            float lenght = rwLength(offset);
            float scaleVelocity = lenght > 100 ? 1 : lenght/100;//If we get our finger close to player, slow down
            player.dampening = scaleVelocity;
            NSLog([NSString stringWithFormat:@"scaleVeloc:%f", scaleVelocity]);
            
            CGPoint direction = rwNormalize(offset);
            player.physicsBody.velocity = CGVectorMake(direction.x*defVeloc*scaleVelocity, direction.y*defVeloc*scaleVelocity);
    
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

- (SKplayer *)newSpaceshipWithTrackingID:(NSString*)trackingID
{
    SKplayer *hull = [[SKplayer alloc] initWithColor:[SKColor clearColor] size:CGSizeMake(45,45)];
    hull.trackingID = trackingID;
    [self.players setObject:hull forKey:trackingID];
    [self.world addChild:hull];
    
    [hull createTexture];
    
    return hull;
}
- (SKcircle*)newFoodWithTrackingID:(NSString*)trackingID
{
    SKcircle* circle = [[SKcircle alloc] initWithColor:[SKColor clearColor] size:CGSizeMake(15, 15)];
    circle.trackingID = trackingID;
    [self.foods setObject:circle forKey:trackingID];
    [self.world addChild:circle];
    
    [circle createTexture];
    
    return circle;
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

int n = 0;

- (void)addRock
{
    SKSpriteNode *rock = [[SKSpriteNode alloc] initWithColor:[SKColor yellowColor] size:CGSizeMake(8,8)];
    rock.position = CGPointMake(skRand(-gridSize/2, gridSize/2), skRand(-gridSize/2, gridSize/2));
    rock.name = @"rock";
    rock.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:rock.size];
    rock.physicsBody.dynamic = NO;
    [self addChild:rock];
    n++;
    NSLog([NSString stringWithFormat:@"%d",n]);
}

-(void)didSimulatePhysics
{
    [self enumerateChildNodesWithName:@"rock" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y < 0)
            [node removeFromParent];
    }];
    
    //ensure in bounds:
    
    NSArray* players = self.players.allValues;
    for(SKplayer* player in players)
    {
        CGPoint position = player.position;
        int rad = player.size.width/2;
        
        if(position.x > gridSize/2 -  rad|| position.y > gridSize/2 - rad|| position.x < -gridSize/2 + rad || position.y < -gridSize/2 + rad)
        {
            int x = MIN(gridSize / 2 - rad, MAX(position.x, -gridSize / 2 + rad));
            int y = MIN(gridSize / 2 - rad, MAX(position.y, -gridSize / 2 + rad));
            player.position = CGPointMake(x, y);
        }
    }
}

- (void) didFinishUpdate
{
    SKNode *player = self.ourPlayer;
    if(player)
    {
        [self centerOnNode:player];
       // NSLog(NSStringFromCGPoint(player.position));
    }

}

- (void) centerOnNode: (SKNode *) node
{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x,                                       node.parent.position.y - cameraPositionInScene.y);
}

- (void) useCreationResponse:(NSDictionary *)response
{
    self.playerID = [response valueForKey:@"playerID"];
    self.gridID = [response valueForKey:@"gridID"];
    
    response = [response valueForKey:@"playerObject"];
    SKplayer *player = self.ourPlayer;
    if(!player)
        player = [self newSpaceshipWithTrackingID:[response valueForKey:@"trackingID"]];
    NSDictionary* loc = [response valueForKey:@"location"];
    player.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
    
    float scaleVelocity = [[response valueForKey:@"dampening"] floatValue];
    CGPoint direction = CGPointMake([[response valueForKey:@"dirx"] floatValue], [[response valueForKey:@"diry"] floatValue]);
    player.physicsBody.velocity = CGVectorMake(direction.x*defVeloc*scaleVelocity, direction.y*defVeloc*scaleVelocity);
    
    player.playerName = [response valueForKey:@"name"];
    player.mass = [[response valueForKey:@"mass"] intValue];
    player.dampening = [[response valueForKey:@"dampening"]floatValue];
    
    self.ourPlayer = player;
    
}

int lastUpdateSeq = 0;
- (void) gotResponse:(NSNotification*)notification
{
    NSDictionary* desc = [notification userInfo];
    int updateSeq = [[desc valueForKey:@"updateSeq"] intValue];
    if(updateSeq<=lastUpdateSeq)return;
    lastUpdateSeq = updateSeq;
    
    NSArray* players = [desc valueForKey:@"players"];
    
    for(NSDictionary* player in players)
    {
        NSString* trackingID = [player valueForKey:@"trackingID"];
        SKplayer* player2 = [self.players valueForKey:trackingID];
        if(!player2)
        {
            player2 = [self newSpaceshipWithTrackingID:trackingID];
            player2.playerName = [player valueForKey:@"name"];
        }
        
        NSDictionary* loc = [player valueForKey:@"location"];
        player2.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
            
        //float scaleVelocity = [[player valueForKey:@"dampening"] floatValue];
        //CGPoint direction = CGPointMake([[player valueForKey:@"dirx"] floatValue], [[player valueForKey:@"diry"] floatValue]);
        //player2.physicsBody.velocity = CGVectorMake(direction.x*defVeloc*scaleVelocity, direction.y*defVeloc*scaleVelocity);
        player2.mass = [[player valueForKey:@"mass"] intValue];
        player2.updateSeq = updateSeq;
        //player2.dampening = [[player valueForKey:@"dampening"]floatValue];
      
    }
    
    if(players.count != self.players.count)//means we have to remove some players
    {
        for(SKplayer* player in self.players)
        {
            if(player.updateSeq<updateSeq)//means it wasn't included in last update
            {
                [player removeFromParent];
                [self.players removeObjectForKey:player.trackingID];
            }
        }
    }
    
    NSArray* foodsAdded = [desc valueForKey:@"foodsAdded"];
    for(NSDictionary* food in foodsAdded)
    {
        SKcircle* foodObj = [self newFoodWithTrackingID:[food valueForKey:@"trackingID"]];
        NSDictionary* loc = [food valueForKey:@"location"];
        foodObj.position = CGPointMake([[loc valueForKey:@"x"] floatValue], [[loc valueForKey:@"y"] floatValue]);
    }
    
    NSArray* foodsRemoved = [desc valueForKey:@"foodsRemoved"];
    for(NSDictionary* food in foodsRemoved)
    {
        SKcircle* foodObj = [self.foods valueForKey:[food valueForKey:@"trackingID"]];
        if(foodObj)
        {
            [foodObj removeFromParent];
            [self.foods removeObjectForKey:[food valueForKey:@"trackingID"]];
            
        }
    }
    
    //ensure food count correct:
    NSNumber* foodsFromServer = [desc valueForKey:@"actualFoodCount"];
    if(![foodsFromServer isEqualToNumber:[NSNumber numberWithInteger:self.foods.count]])
    {
        NSLog(@"Requesting foods!!!");
        
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/requestfoods" withData:@{@"gridID":self.gridID}];
    }
    
}

- (void) gotFoods:(NSNotification*)notif
{
    NSDictionary* desc = [notif userInfo];
    NSArray* actualFoods = [desc valueForKey:@"foods"];
    
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
        SKcircle* food = [self.foods valueForKey:[serverFood valueForKey:@"trackingID"]];
        if(!food)
        {
            food = [self newFoodWithTrackingID:[serverFood valueForKey:@"trackingID"]];
            NSDictionary* loc = [serverFood valueForKey:@"location"];
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

struct collision
{
    __unsafe_unretained NSString* first;
    __unsafe_unretained NSString* second;
    BOOL bothArePlayers;
};

//a collision is only considered if the distance between the centers is smaller than the sum of the two radi minus half the smaller radius of the two
- (void) collisionDetection
{
    //compare square of distance since ^2 is faster than sqrt
    
    NSArray* allPlayers = self.players.allValues;
    for(int i = 0; i < allPlayers.count; i++)
    {
        SKplayer* player1 = allPlayers[i];
        for(int j = i + 1; j < allPlayers.count; j++)
        {
            SKplayer* player2 = allPlayers[j];
            float r1 = player1.getRadius;
            float r2 = player2.getRadius;
            float smallest = r1<r2?r1:r2;
            float distSqr = r1+r2;distSqr*=distSqr;
            CGPoint offset = rwSub(player1.position, player2.position);
        }
    }
    
    
}

- (void) setOurPlayer:(SKplayer *)ourPlayer
{
    _ourPlayer = ourPlayer;
    [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(sendMessageToServer) userInfo:nil repeats:YES];
}

- (void) sendMessageToServer
{
    CGPoint direction = rwNormalize(CGPointMake(self.ourPlayer.physicsBody.velocity.dx, self.ourPlayer.physicsBody.velocity.dy));
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/setplayermovement" withData:@{@"gridID":self.gridID, @"playerID":self.playerID, @"dirx":[NSNumber numberWithDouble: direction.x], @"diry":[NSNumber numberWithDouble:direction.y], @"dampening":[NSNumber numberWithFloat:self.ourPlayer.dampening]}];
}

- (void) dealloc
{
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"gridUpdate" sender:self];
}
@end
