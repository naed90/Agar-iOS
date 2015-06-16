//
//  login.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "login.h"
#import "socketDealer.h"
#import "AppDelegate.h"

@interface login()

@property (nonatomic) BOOL proceedDisabled;//after sending to server, disable button to not allow continous resends

@end


@implementation login

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"login" owner:self options:nil];
		
		self.frame = frame;
		self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		
		[self addSubview:self.view];
		
		[self addTouchesForButtons];
        
        //connect to server
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"playerRegistered" sender:self withSelector:@selector(gotResponse:)];
		
        self.activityIndicator.alpha = 0;
        self.proceedDisabled = YES;
        self.proceedView.alpha = .5;
        
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//if login is up, the app can sleep if user doesn't touch it
		
	}
	return self;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	UITouch* touch = [touches anyObject];//its fine to use any object, b/c there will always be just 1 object since disabled multiple touches
	CGPoint locInView = [touch locationInView:self.proceedView];
	if(locInView.x > 0 && locInView.y
	   >0 && locInView.x < self.proceedView.frame.size.width && locInView.y < self.proceedView.frame.size.height)
	{
		self.proceedView.alpha = .5;
	}
	
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	self.proceedView.alpha = 1;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	self.proceedView.alpha = 1;
}

- (void) addTouchesForButtons
{
	UITapGestureRecognizer* gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(proceedTapped)];
	[self.proceedView addGestureRecognizer:gest];
	
	
}

#define AUTHLENGTH 18 // this is max username length
- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	NSUInteger oldLength = [textField.text length];
	NSUInteger replacementLength = [string length];
	NSUInteger rangeLength = range.length;
	
	NSUInteger newLength = oldLength - rangeLength + replacementLength;
	
	BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
	
    BOOL retval = newLength <= AUTHLENGTH || returnKey;
    if(retval)
    {
        if(newLength>0)
            {self.proceedDisabled = NO; self.proceedView.alpha = 1;}
        else
            {self.proceedDisabled = YES; self.proceedView.alpha = .5;}
    }
    
	
    return retval;
}

- (void) proceedTapped
{
	if(self.proceedDisabled || self.textView.text.length == 0)return;
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/startgamewithname" withData:@{@"name":self.textView.text}];
	self.activityIndicator.alpha = 1;
	[self.activityIndicator startAnimating];
	self.proceedDisabled = YES;
	self.textView.enabled = NO;
	self.proceedView.alpha = .5;//disabled
}

- (void) gotResponse:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	
	self.activityIndicator.alpha = 0;
	[self.activityIndicator stopAnimating];
	self.proceedDisabled = NO;
	self.textView.enabled = YES;
	self.proceedView.alpha = 1;//enabled
    
    [self.delegate useCreationResponse:desc];
    [UIView animateWithDuration:.1
                     animations:^{
                         //self.frame = CGRectMake(self.center.x - 350, self.center.y - 350, 700,700);
                         self.alpha = 0;
                     } ];
    [self unregisterUsernameEntered];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];//make app not sleep when user is playing
    self.delegate.loginIsUp = NO;
    
}

- (void) unregisterUsernameEntered
{
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"playerRegistered" sender:self];
}
- (void) dealloc
{
    [self unregisterUsernameEntered];
}


- (IBAction)creditsClicked:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://dean-leitersdorf.herokuapp.com/agarios/credits"]];
    
}

@end
