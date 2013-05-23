//
//  ViewController.h
//  RSS Reader
//
//  Created by James Jia on 4/24/13.
//  Copyright (c) 2013 James Jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface ViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, NSXMLParserDelegate, UIAlertViewDelegate, UISearchDisplayDelegate, UIActionSheetDelegate>{
    CGSize cellSize;
    NSXMLParser *rssParser;
    NSMutableArray *stories;
    NSMutableDictionary *item;
    NSMutableArray *filteredResults;
    NSString *currentElem;
    NSMutableString *currTitle, *currDate, *currSummary, *currLink;
    UISearchBar* searchBar;
    UISearchDisplayController* searchDisplayController;
    NSString* lastURL;
    NSString* storyLink;
    NSString* storyTitle;
    BOOL alertShowing;
    BOOL hasInternet;
}
@property NSMutableArray* rssFeeds;

@end
