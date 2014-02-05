//
//  CUBNavigationController.m
//  
//
//  Created by Harshad Dange on 02/02/2014.
//
//

#import "CUBNavigationController.h"

@implementation CUBNavigationController

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
