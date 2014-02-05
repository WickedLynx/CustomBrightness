//
//  CUBHelpViewController.m
//  CustomBrightness
//
//  Created by Harshad Dange on 09/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBHelpViewController.h"

@interface CUBHelpViewController ()



@end

@implementation CUBHelpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setTitle:@"Help"];
    
    UIWebView *aWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [aWebView setScalesPageToFit:YES];
    NSString *pdfFilePath = [[NSBundle mainBundle] pathForResource:@"Readme" ofType:@"pdf"];
    if (pdfFilePath != nil) {
        NSURL *fileURL = [NSURL fileURLWithPath:pdfFilePath];
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
        [aWebView loadRequest:request];
    }
    
    [self.view addSubview:aWebView];
}

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
