//
//  tutorialViewController.m
//  Agar iOS
//
//  Created by Dean Leitersdorf on 6/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "tutorialViewController.h"
#import "AppDelegate.h"

@interface tutorialViewController ()

@end

@implementation tutorialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismiss:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    ((AppDelegate*)[UIApplication sharedApplication].delegate).forceHideBlueBar = NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
