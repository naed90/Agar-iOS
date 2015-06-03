//
//  GameScene.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 5/31/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//



#import "GameScene.h"






#define gridSize 5000

#define defVeloc 500


@interface GameScene ()
@property BOOL contentCreated;

@property (nonatomic, strong) SKNode* world;

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
    [self addChild: [self newHelloNode]];
    
    SKAction *makeRocks = [SKAction sequence: @[
                                                [SKAction performSelector:@selector(addRock) onTarget:self],
                                                [SKAction waitForDuration:.3 withRange:.2]
                                                ]];
    [self runAction: [SKAction repeatActionForever:makeRocks]];
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
    SKNode *helloNode = [self childNodeWithName:@"//helloNode"];
    if (helloNode != nil)
    {
        helloNode.name = nil;
        SKAction *moveUp = [SKAction moveByX: 0 y: 100.0 duration: 0.5];
        SKAction *zoom = [SKAction scaleTo: 2.0 duration: 0.25];
        SKAction *pause = [SKAction waitForDuration: 0.5];
        SKAction *fadeAway = [SKAction fadeOutWithDuration: 0.25];
        SKAction *remove = [SKAction removeFromParent];
        SKAction *moveSequence = [SKAction sequence:@[moveUp, zoom, pause, fadeAway, remove]];
        [helloNode runAction: moveSequence completion:^{
            SKSpriteNode *spaceship = [self newSpaceship];
            spaceship.position = CGPointMake(CGRectGetMidX(self.world.frame), CGRectGetMidY(self.world.frame)-150);
            [self addChild:spaceship];
        }];
    }
    else //move spaceship thingy
    {
        SKNode *player = [self childNodeWithName:@"//player"];
        if(player)
        {
            UITouch * touch = [touches anyObject];
            CGPoint location = [touch locationInNode:self.world];
            
            CGPoint offset = rwSub(location, player.position);
            float lenght = rwLength(offset);
            float scaleVelocity = lenght > 100 ? 1 : lenght/100;//If we get our finger close to player, slow down
            
            NSLog([NSString stringWithFormat:@"scaleVeloc:%f", scaleVelocity]);
            
            CGPoint direction = rwNormalize(offset);
            player.physicsBody.velocity = CGVectorMake(direction.x*defVeloc*scaleVelocity, direction.y*defVeloc*scaleVelocity);
        }
    }
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesBegan:touches withEvent:event];
}

- (SKSpriteNode *)newSpaceship
{
    SKSpriteNode *hull = [[SKSpriteNode alloc] initWithColor:[SKColor grayColor] size:CGSizeMake(64,32)];
    hull.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:hull.size];
    hull.name = @"player";
    
    SKAction *hover = [SKAction sequence:@[
                                           [SKAction waitForDuration:1.0],
                                           [SKAction moveByX:100 y:50.0 duration:1.0],
                                           [SKAction waitForDuration:1.0],
                                           [SKAction moveByX:-100.0 y:-50 duration:1.0]]];
    //[hull runAction: [SKAction repeatActionForever:hover]];
    
    SKSpriteNode *light1 = [self newLight];
    light1.position = CGPointMake(-28.0, 6.0);
    [hull addChild:light1];
    
    SKSpriteNode *light2 = [self newLight];
    light2.position = CGPointMake(28.0, 6.0);
    [hull addChild:light2];
    
    return hull;
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
}

- (void) didFinishUpdate
{
    SKNode *player = [self childNodeWithName:@"//player"];
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




//Character movement:
@end
