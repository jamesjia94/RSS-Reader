//
//  WebViewController.h
//  RSS Reader
//
//  Created by James Jia on 5/8/13.
//  Copyright (c) 2013 James Jia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController
@property IBOutlet UIWebView *webView;
@property NSString *url;
@end