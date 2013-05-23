//
//  ViewController.m
//  RSS Reader
//
//  Created by James Jia on 4/24/13.
//  Copyright (c) 2013 James Jia. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "WebViewController.h"
#define GOOGLE_API @"https://ajax.googleapis.com/ajax/services/feed/find?v=1.0&q="

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    alertShowing = NO;
    self.rssFeeds = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] objectForKey:@"RSSFeeds"] copy]];
    stories = [[NSMutableArray alloc] init];
    if (self.rssFeeds == nil){
        self.rssFeeds = [[NSMutableArray alloc]init];
    }
    filteredResults = [[NSMutableArray alloc]init];
    searchBar = [[UISearchBar alloc]init];
    searchBar.scopeButtonTitles = [[NSArray alloc]initWithObjects:@"Existing Feeds", @"Explore Feeds", nil];
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    self.tableView.tableHeaderView = searchBar;
    [self.tableView.tableHeaderView sizeToFit];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(checkInternetConnection)
                                                 name: @"didBecomeActive"
                                               object: nil];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target:self action:@selector(addFeed)];
    UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemTrash target:self action:@selector(removeFeed)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:addButton,removeButton, nil];
    
    if ([self.rssFeeds count] == 0 && !alertShowing){
        alertShowing = YES;
        UIAlertView *errorAlertView = [[UIAlertView alloc]
                                       initWithTitle:nil
                                       message:@"Please Start by inputting a RSS feed URL"
                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [errorAlertView show];
    }
    else{
        for (NSString* str in self.rssFeeds){
            [self parseXMLFileAtURL:str];
        }
    }
}

-(void)addFeed
{
    if ([self checkInternetConnection] == YES && !alertShowing){
        alertShowing = YES;
        UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"URL of RSS feed" message:@"\n"
                                                        delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        UITextField *passwordField = [[UITextField alloc] initWithFrame:CGRectMake(16,45,252,25)];
        passwordField.font = [UIFont systemFontOfSize:18];
        passwordField.backgroundColor = [UIColor whiteColor];
        passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [passwordField becomeFirstResponder];
        [prompt addSubview:passwordField];
        [prompt show];
    }
}

- (BOOL)checkInternetConnection
{
    Reachability *r = [Reachability reachabilityWithHostname:@"m.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == NotReachable && !alertShowing){
        alertShowing = YES;
        UIAlertView *errorAlertView = [[UIAlertView alloc]
                                       initWithTitle:@"No internet connection"
                                       message:@"Internet connection is required to use this app"
                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [errorAlertView show];
        return NO;
    }
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [filteredResults removeAllObjects];
    if ([scope isEqualToString:@"Existing Feeds"]){
        for (NSDictionary *dict in stories){
            NSString *str = [dict objectForKey:@"title"];
            NSComparisonResult result = [str compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
            if (result == NSOrderedSame)
            {
                [filteredResults addObject:str];
            }
            
        }
    }
    else{
        [self searchGoogleAPIForText:searchText];
    }
}

-(void)searchGoogleAPIForText:(NSString*)searchText
{
    if([self checkInternetConnection] == YES){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",GOOGLE_API,searchText]]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (error == nil){
                                       NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                       NSDictionary *responseData = [json objectForKey:@"responseData"];
                                       int responseStatus = [[json objectForKey:@"responseStatus"] intValue];
                                       if (responseData != nil && responseStatus==200){
                                           NSArray *entries = [responseData objectForKey:@"entries"];
                                           for (NSDictionary *entry in entries){
                                               [filteredResults addObject:[entry objectForKey:@"url"]];
                                           }
                                           [self.searchDisplayController.searchResultsTableView reloadData];
                                       }
                                   }
                                   else{
                                       if (!alertShowing){
                                           alertShowing = YES;
                                           UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Invalid search" message:@"Please remove any spaces in your search" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                           [alert show];
                                       }
                                   }
                               }
         ];
    }
}

-(void)sync
{
    NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
    [pref setObject:self.rssFeeds forKey:@"RSSFeeds"];
    [pref synchronize];
}

-(void) parseXMLFileAtURL:(NSString * )URL{
    if ([self checkInternetConnection]){
        NSURL *xmlURL = [NSURL URLWithString:URL];
        rssParser = [[NSXMLParser alloc]initWithContentsOfURL:xmlURL];
        [rssParser setDelegate:self];
        [rssParser parse];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"webViewSegue"]) {
        WebViewController *vc = [segue destinationViewController];
        vc.url = storyLink;
        [vc.navigationItem setTitle:storyTitle];
    }
}

-(void)removeFeed
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select which feed to remove"
                                                             delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString* str in self.rssFeeds){
        [actionSheet addButtonWithTitle:str];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];	// show from our table view (pops up in the middle of the table)
}

#pragma mark - UISearchDisplayDelegate methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:controller.searchBar.text
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:searchOption]];
    
    return YES;
}

#pragma mark - UITableView Methods
-(NSInteger)tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [filteredResults count];
    }
    else{
        return [stories count];
    }
}

#pragma mark - UITableViewDataSource Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *MyIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [filteredResults objectAtIndex:indexPath.row];
    }
    else{
        int storyIndex = [indexPath indexAtPosition:[indexPath length]-1];
        [cell.textLabel setText:[[stories objectAtIndex:storyIndex]objectForKey:@"title"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (tableView != self.searchDisplayController.searchResultsTableView){
        int storyIndex = [indexPath indexAtPosition:[indexPath length]-1];
        [stories removeObjectAtIndex:storyIndex];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITableViewDelegate Methods
-(void)tableView: (UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.searchDisplayController.searchResultsTableView){
        NSString* url = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        if (![self.rssFeeds containsObject: url]){
            [self.rssFeeds addObject: url];
            [self parseXMLFileAtURL: url];
            [self sync];
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Added New Feed" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
        else{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Feed already exists" message:@"Please choose another feed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    else{
        if ([self checkInternetConnection] == YES){
            int storyIndex = [indexPath indexAtPosition:[indexPath length] -1];
            storyLink = [[stories objectAtIndex:storyIndex] objectForKey:@"link"];
            NSArray* words = [storyLink componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            storyLink = [words componentsJoinedByString:@""];
            storyTitle = [[stories objectAtIndex:storyIndex]objectForKey:@"title"];
            [self performSegueWithIdentifier:@"webViewSegue" sender:self];
        }
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - NSXMLParserDelegate Methods
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    currentElem = [elementName copy];
    if ([elementName isEqualToString:@"item"]){
        item = [[NSMutableDictionary alloc] init];
        if ([self.rssFeeds lastObject]!= nil){
            [item setObject:(NSString *)[self.rssFeeds lastObject] forKey:@"URL"];
        }
        currTitle = [[NSMutableString alloc] init];
        currDate = [[NSMutableString alloc]init];
        currSummary = [[NSMutableString alloc] init];
        currLink = [[NSMutableString alloc] init];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"item"]){
        [item setObject: currTitle forKey: @"title"];
        [item setObject: currLink forKey: @"link"];
        [item setObject: currSummary forKey: @"summary"];
        [item setObject: currDate forKey: @"date"];
        
        [stories addObject:[item copy]];
    }
}

-(void) parser: (NSXMLParser*)parser foundCharacters:(NSString *)string{
    if ([currentElem isEqualToString: @"title"]){
        [currTitle appendString:string];
    }
    else if ([currentElem isEqualToString:@"link"]){
        [currLink appendString: string];
    }
    else if ([currentElem isEqualToString:@"description"]){
        [currSummary appendString:string];
    }
    else if ([currentElem isEqualToString:@"pubDate"]){
        [currDate appendString:string];
    }
}

-(void) parserDidEndDocument:(NSXMLParser *)parser {
    [self.tableView reloadData];
}

-(void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSString* error = ([parseError code]==5) ? @"Invalid URL" : @"";
    if (!alertShowing){
        alertShowing = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error has occurred" message:error delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [self.rssFeeds removeObject:lastURL];
        [alertView show];
    }
}

#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    alertShowing = NO;
    if (buttonIndex == 1){
        for (UIView *view in alertView.subviews){
            if ([view isKindOfClass:[UITextField class]]){
                UITextField *textField = (UITextField*)view;
                lastURL = textField.text;
                if (![self.rssFeeds containsObject:lastURL]){
                    [self.rssFeeds addObject:lastURL];
                    [self parseXMLFileAtURL:lastURL];
                    [self sync];
                }
            }
        }
    }
}

#pragma mark UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet numberOfButtons] -1)
	{
        NSString *removeURL = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([self.rssFeeds containsObject: removeURL]){
            [self.rssFeeds removeObject:removeURL];
            NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
            NSMutableDictionary *array;
            NSUInteger index = 0;
            
            for (array in stories) {
                if ([[array objectForKey:@"URL"] isEqualToString:removeURL])
                    [discardedItems addIndex:index];
                index++;
            }
            
            [stories removeObjectsAtIndexes:discardedItems];
            [self.tableView reloadData];
            [self sync];
        }
	}
}
@end
