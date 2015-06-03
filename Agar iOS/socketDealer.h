//
//  socketDealer.h
//  Resturant App - User
//
//  Created by Dean Leitersdorf on 11/30/14.
//  Copyright (c) 2014 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"
#import "urls.m"

@protocol socketDealerDelegate <NSObject>

-(void)setNoConnectionBannerOnOff:(BOOL)value;

@end

@interface socketDealer : NSObject  <SocketIODelegate>


@property (strong, nonatomic)SocketIO* socketIO;


- (void) signUpForDataWithInfo:(NSDictionary*)info sender:(id)sender withSelector:(SEL)selector;
- (void) resignDataUpdatesWithInfo:(NSDictionary*)info sender:(id)sender;

- (void) signUpForEvent:(NSString*)event sender:(id)sender withSelector:(SEL)selector;
- (void) resignEvent:(NSString*)event  sender:(id)sender;

- (void) pauseAllTrackers;//resign and restore all trackers DO NOT affect app-internal NSNotifications. This is so because when resuming all trackers, we do not know which objects were previously listening. Its ok if we have views still observing notifications and those notifications will never get called. IN OTHER WORDS, pause and resume all trackers only notify the server of changes and do NOTHING inside the app (EVEN NOT moving stuff around in supposed/pending/actuallyTrakcingNSDictionaries)
- (void) resumeAllTrackers;

- (void) sendEvent:(NSString*)event withData:(id)data;

@property (nonatomic) id<socketDealerDelegate> delegate;
@end
