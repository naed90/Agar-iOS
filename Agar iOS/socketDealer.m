//
//  socketDealer.m
//  Resturant App - User
//
//  Created by Dean Leitersdorf on 11/30/14.
//  Copyright (c) 2014 Dean Leitersdorf. All rights reserved.
//

#import "socketDealer.h"
#import "SocketIOPacket.h"

@interface socketDealer()

@property (strong, nonatomic) NSMutableDictionary* supposedToBeTracking;//used for re-establishing connection
@property (strong, nonatomic) NSMutableDictionary* pendingTracking;//used in case 2 objects request the same tracks at the same time, or before the initial track returned successfully
@property (strong, nonatomic) NSMutableDictionary* actuallyTracking;//used to list trackers which server registered

@property (strong, nonatomic) NSTimer* reconnectTimer;

@end



@implementation socketDealer

-(SocketIO*)socketIO
{
    if(!_socketIO)
    {
        _socketIO = [[SocketIO alloc] initWithDelegate:self];
        [self.delegate setNoConnectionBannerOnOff:YES];
        if(!_socketIO.isConnected)
        {
            [self connectSocketIOWithCompletion:nil];
        }
    }
    return _socketIO;
}

-(void)updateConnected
{
    BOOL connected = self.socketIO.isConnected;
    [self.delegate setNoConnectionBannerOnOff:!connected];
    
}
typedef void (^Block)(void);
-(void)connectSocketIOWithCompletion:(Block)block
{
    
    BOOL localTesting = YES;
    self.socketIO.useSecure = !localTesting;//https -- avoid wireshark
    [self.socketIO connectToHost:localTesting ? @"67.180.17.151" : @"dean-leitersdorf.herokuapp.com" onPort:localTesting?5000:443];
   if(block)
       block();
}
-(NSMutableDictionary*)supposedToBeTracking
{
    if(!_supposedToBeTracking)
    {
        _supposedToBeTracking = [[NSMutableDictionary alloc] init];
    }
    return _supposedToBeTracking;
}
-(NSMutableDictionary*)pendingTracking
{
    if(!_pendingTracking)
    {
        _pendingTracking = [[NSMutableDictionary alloc] init];
    }
    return _pendingTracking;
}
-(NSMutableDictionary*)actuallyTracking
{
    if(!_actuallyTracking)
    {
        _actuallyTracking = [[NSMutableDictionary alloc]init];
    }
    return _actuallyTracking;
}


# pragma mark socket.IO-objc delegate methods && socketDealer methods


- (void) sendEvent:(NSString *)event withData:(id)data
{
    [self.socketIO sendEvent:event withData:data];
}

- (void) signUpForEvent:(NSString*)event sender:(id)sender withSelector:(SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:sender selector:selector name:[NSString stringWithFormat:@"%@%@", socketBaseName, event] object:self];
}
- (void) resignEvent:(NSString*)event  sender:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:sender name:[NSString stringWithFormat:@"%@%@", socketBaseName, event] object:self];
}

- (void) signUpForDataWithInfo:(NSDictionary*)info sender:(id)sender withSelector:(SEL)selector
{
    //info must have:
    /*
     *id
     *field
     */
    
    if([info objectForKey:@"id"] && [info objectForKey:@"field"])
    {
        NSString* objID = [info objectForKey:@"id"];
        NSString* field = [info objectForKey:@"field"];
        NSString* string = [NSString stringWithFormat:@"%@/%@", objID, field];
        long actually =[[self.actuallyTracking objectForKey:string] integerValue];
        long pending =[[self.pendingTracking objectForKey:string] integerValue];
        long supposed =[[self.supposedToBeTracking objectForKey:string] integerValue];
        if(!actually && !pending)
        {
            [self.pendingTracking setValue:[NSNumber numberWithLong:(pending+1)] forKey:string];
            
            [self.socketIO sendEvent:@"registerForNotifications" withData:info];
            [[NSNotificationCenter defaultCenter] addObserver:sender selector:selector name:[NSString stringWithFormat:@"%@%@", socketBaseName, string] object:self];
        }
        else
        {
            if(actually)
            {
                [self.actuallyTracking setValue:[NSNumber numberWithLong:(actually+1)] forKey:string];
            }
            if(pending)
            {
                [self.pendingTracking setValue:[NSNumber numberWithLong:(pending+1)] forKey:string];
            }
        }
        
        [self.supposedToBeTracking setValue:[NSNumber numberWithLong:(supposed+1)] forKey:string];
        
    }
    
}
-(void)resignDataUpdatesWithInfo:(NSDictionary*)info sender:(id)sender
{
    if([info objectForKey:@"id"] && [info objectForKey:@"field"])
    {
        NSString* objID = [info objectForKey:@"id"];
        NSString* field = [info objectForKey:@"field"];
        NSString* string = [NSString stringWithFormat:@"%@/%@", objID, field];
        long actually =[[self.actuallyTracking objectForKey:string] integerValue];
        long pending =[[self.pendingTracking objectForKey:string] integerValue];
        long supposed =[[self.supposedToBeTracking objectForKey:string] integerValue];
        if(actually)
            [self.actuallyTracking setValue:[NSNumber numberWithLong:(actually-1)] forKey:string];
        
        if(pending)
            [self.pendingTracking setValue:[NSNumber numberWithLong:(pending-1)] forKey:string];
        
        if(supposed)
            [self.supposedToBeTracking setValue:[NSNumber numberWithLong:(supposed-1)] forKey:string];
        if(actually==1)
            [self.actuallyTracking removeObjectForKey:string];
        if(pending==1)
            [self.pendingTracking removeObjectForKey:string];
        if(supposed==1)
        {
            [self.supposedToBeTracking removeObjectForKey:string];
            [self.socketIO sendEvent:@"resignNotifications" withData:info];
            [[NSNotificationCenter defaultCenter] removeObserver:sender name:[NSString stringWithFormat:@"%@%@", socketBaseName, string] object:self];
        }

    }
}

- (void) pauseAllTrackers
{
    NSArray* data = [self.supposedToBeTracking allKeys];
    [self.socketIO sendEvent:@"resignAllTrackers" withData:data];
}

- (void) resumeAllTrackers
{
    NSArray* data = [self.supposedToBeTracking allKeys];
    if(![self.socketIO isConnected])
    {
        [self connectSocketIOWithCompletion:^{
            [self.socketIO sendEvent:@"registerAllTrackers" withData:data];
        }];
    }
    else{
        
        [self.socketIO sendEvent:@"registerAllTrackers" withData:data];
    }
    
}



-(void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet
{
    
#define updated @"Updated: "
#define acceptedTrack @"accepted track of: "
#define messagesLoaded @"answerForGetMessagesFromChatObject"
    
#define eventRecieved @"eventRecieved"
    
    NSString* string = [packet data];
    if(!self.loggingOff){
    //NSLog(@"didReceiveMessage()");
      //  NSLog(string);
    }
    
    if ([string rangeOfString:updated].location != NSNotFound)
    {
        string = [string stringByReplacingOccurrencesOfString:updated withString:@""];
        NSString* name = [NSString stringWithFormat:@"%@%@", socketBaseName, string];
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
    }
    else if ([string rangeOfString:acceptedTrack].location != NSNotFound)
    {
        string = [string stringByReplacingOccurrencesOfString:acceptedTrack withString:@""];
        long pending =[[self.pendingTracking objectForKey:string] integerValue];
        if(pending)//note: we must check pending, b/c resumeAllTrackers doesn't modify pending, leaving it 0, but the app will still recieve this "acceptedTrack" message when the server realizes it is back on.
        {[self.pendingTracking removeObjectForKey:string];
            [self.actuallyTracking setValue:[NSNumber numberWithLong:pending] forKey:string];}
    }
    else if([string rangeOfString:messagesLoaded].location != NSNotFound)//basicaly an eventRecieved, but was created before eventRecieved - to fix it, have to fix many other places, so just leave as is.
    {
        NSDictionary* dic = [packet dataAsJSON];
        string = [NSString stringWithFormat:@"%@/%@", [dic valueForKey:messagesLoaded], @"messages"];
        NSString* name = [NSString stringWithFormat:@"%@%@", socketBaseName, string];
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:dic];
        
        
    }
    else if([string rangeOfString:eventRecieved].location != NSNotFound )
    {
        NSDictionary* dic = [packet dataAsJSON];
        NSString* name = [NSString stringWithFormat:@"%@%@", socketBaseName, [dic valueForKey:@"eventRecieved"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:dic];
    }
    else{
         NSLog(@"not worked");
    }
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    if ([error code] == SocketIOUnauthorized) {
        NSLog(@"Socket error: not authorized");
    } else {
        NSLog(@"onError() %@", error);
    }
    
    [self attemptReconnect];
}

- (void) socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"Socket connected.");
    [self.reconnectTimer invalidate];
    [self resumeAllTrackers];//trackers might have been lost if server killed connection (e.g. server restart/idle)
    
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* userID = [defaults valueForKey:userIDDefaultsURL];
    NSString* userAuth = [defaults valueForKey:userAuthDefaultsURL];
    NSDictionary* dic = @{@"user1ID": userID, @"user1Auth" : userAuth, @"user2ID":@"001140-3e79e91902cea13e33a8e4abe0ab08d3"};
    
    [self.socketIO sendEvent:@"getChatWithUser" withData:dic];
    */
    
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"Socket disconnected. Error: %@", error);
    [self attemptReconnect];
  
}

-(void)attemptReconnect
{
    if(!self.reconnectTimer.isValid && !self.socketIO.isConnected && !self.socketIO.isConnecting){
    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                     target:self
                                   selector:@selector(reconnect)
                                   userInfo:nil
                                                          repeats:YES];}
}
-(void)reconnect
{
    if(!self.socketIO.isConnected && !self.socketIO.isConnecting)
    {
        [self connectSocketIOWithCompletion:nil];
    }
}

@end
