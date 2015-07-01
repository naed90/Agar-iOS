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

@property (nonatomic, strong) UIDynamicAnimator* animator;


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
        self.proceedView.alpha = .3;
        
        self.textView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Your Nickname" attributes:@{NSForegroundColorAttributeName: self.textView.textColor}];
        
        [[UITextField appearance] setTintColor:self.textView.textColor];
        
        [self.activityIndicator setColor:self.textView.textColor];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString* lastName = [defaults valueForKey:@"lastName"];
        
        if(lastName)
        {
            //calls our method below, for checking
            if([self textField:self.textView shouldChangeCharactersInRange:NSRangeFromString(self.textView.text) replacementString:lastName])
                self.textView.text = lastName;
        }
        
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//if login is up, the app can sleep if user doesn't touch it
        
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(createAnime) userInfo:nil repeats:YES];
        
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(createSignAnime) userInfo:nil repeats:YES];
       
        //[self createSignAnime];
        
        /*
        CABasicAnimation *animation =
        [CABasicAnimation animationWithKeyPath:@"position"];
        [animation setDuration:0.3];
        //[animation setRepeatCount:2];
        [animation setAutoreverses:YES];
        for(int i = 0; i < 2; i++)
        {
            [animation setFromValue:[NSValue valueWithCGPoint:
                                     CGPointMake([self.bounceAbleView center].x - 20.0f, [self.bounceAbleView center].y)]];
            [animation setToValue:[NSValue valueWithCGPoint:
                                   CGPointMake([self.bounceAbleView center].x + 20.0f, [self.bounceAbleView center].y)]];
        }
        [animation setToValue:[NSValue valueWithCGPoint:
                               CGPointMake([self.bounceAbleView center].x -20.0f, [self.bounceAbleView center].y)]];
        [[self.bounceAbleView layer] addAnimation:animation forKey:@"position"];*/
		
	}
	return self;
}

- (void) createAnime
{
    [self.bounceAbleView.layer removeAllAnimations];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = 1.5f;
    animation.values = @[ @(0), @(-20), @(20), @(-20), @(20), @(0) ];
    [self.bounceAbleView.layer addAnimation:animation forKey:@"shake"];
}


- (void) createSignAnime
{
    [self.enterView.layer removeAllAnimations];
    
    if(self.textView.isEditing)return;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = 1.5;
    animation.values = @[ @(0), @(-.34), @(.34), @(-.34), @(.34), @(0) ];
    //animation.values = @[ @(0), @(-50), @(0), @(-30), @(0), @(-10), @(0) ];
    
    [self.enterView.layer addAnimation:animation forKey:@"rotation"];
    /*
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / 500.0;
    self.enterView.layer.transform = transform;*/
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self proceedTapped];
    return NO;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	UITouch* touch = [touches anyObject];//its fine to use any object, b/c there will always be just 1 object since disabled multiple touches
	CGPoint locInView = [touch locationInView:self.proceedView];
	if(locInView.x > 0 && locInView.y
	   >0 && locInView.x < self.proceedView.frame.size.width && locInView.y < self.proceedView.frame.size.height)
	{
        self.proceedView.alpha = .3;
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
        {self.proceedDisabled = YES; self.proceedView.alpha = .3;}
    }
    
	
    return retval;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.placeholder = nil;
    
    [self.enterView.layer removeAllAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Your Nickname" attributes:@{NSForegroundColorAttributeName: self.textView.textColor}];
}

- (void) proceedTapped
{
	if(self.proceedDisabled || self.textView.text.length == 0)return;
    
    //make sure name is appropriate:
    NSArray* words = [self.textView.text componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* nospacestring = [words componentsJoinedByString:@""];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"bannedWords"
                                                     ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray* bannedWords = [content componentsSeparatedByString:@"\r\n"];
    NSString* lowerCaseNoSpace = [nospacestring lowercaseString];
    
    BOOL containsBannedWord = NO;
    for(NSString* string in bannedWords)
    {
        if([lowerCaseNoSpace containsString:string])
        {
            containsBannedWord = YES;
            break;
        }
    }
    
    if(containsBannedWord)
    {
        [[[UIAlertView alloc] initWithTitle:@"Word Usage" message:@"Please refrain from using obscene language in your nickname." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
        return;
    }
    
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/agarios/startgamewithname" withData:@{@"name":self.textView.text}];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.textView.text forKey:@"lastName"];
    
	self.activityIndicator.alpha = 1;
	[self.activityIndicator startAnimating];
	self.proceedDisabled = YES;
	self.textView.enabled = NO;
    self.proceedView.alpha = 1;//.3;//disabled
    self.arrow.alpha = 0;
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
    [UIView animateWithDuration:.3
                     animations:^{
                         //self.frame = CGRectMake(self.center.x - 350, self.center.y - 350, 700,700);
                         self.transform = CGAffineTransformMakeScale(3, 3);
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
- (IBAction)showTutorial:(id)sender
{
    [self.vc showTut];
}

@end
