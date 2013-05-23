//
//  WebViewController.m
//  RSS Reader
//
//  Created by James Jia on 5/8/13.
//  Copyright (c) 2013 James Jia. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
@end

@implementation WebViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSURL *weburl = [NSURL URLWithString:_url];
    [_webView loadRequest:[NSURLRequest requestWithURL:weburl]];
}
@end
