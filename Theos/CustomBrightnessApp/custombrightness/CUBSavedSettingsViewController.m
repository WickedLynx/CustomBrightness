//
//  CUBSavedSettingsViewController.m
//  
//
//  Created by Harshad Dange on 09/01/2014.
//
//

#import "CUBSavedSettingsViewController.h"

#import "CUBSavedSettingsTableViewCell.h"
#import "CUBBrightnessSetting.h"
#import "CUBBorderedButton.h"

@interface CUBSavedSettingsViewController () <UITableViewDataSource, UITableViewDelegate> {
    __weak UITableView *_preferencesTableView;
    __strong NSMutableArray *_savedPreferences;
}

- (void)touchDeleteAll;

@end

@implementation CUBSavedSettingsViewController

- (instancetype)initWithSavedPreferences:(NSMutableArray *)savedPreferences {
    
    self = [super init];
    
    if (self != nil) {
        _savedPreferences = savedPreferences;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setTitle:@"Current Settings"];
    
    UITableView *aTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [aTableView setDataSource:self];
    [aTableView setDelegate:self];
    [self.view addSubview:aTableView];
    _preferencesTableView = aTableView;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
    [footerView setBackgroundColor:[UIColor whiteColor]];
    
    CUBBorderedButton *deleteButton = [[CUBBorderedButton alloc] initWithFrame:CGRectMake(100, 5, 120, 35) highlightColor:[UIColor redColor]];
    [deleteButton setTitle:@"Delete all" forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(touchDeleteAll) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:deleteButton];
    
    [_preferencesTableView setTableFooterView:footerView];
}

- (void)touchDeleteAll {
    [_savedPreferences removeAllObjects];
    [_preferencesTableView reloadData];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_savedPreferences count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CUBSavedPreferencesTableCellIdentifier = @"CUBSavedPreferencesTableCellIdentifier";
    
    CUBSavedSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CUBSavedPreferencesTableCellIdentifier];
    
    if (!cell) {
        cell = [[CUBSavedSettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CUBSavedPreferencesTableCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    if (indexPath.row < [_savedPreferences count]) {
        CUBBrightnessSetting *theSetting = _savedPreferences[indexPath.row];
        [cell setLux:theSetting.lux brightness:theSetting.screenBrightness];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 35.0f)];
    [aView setBackgroundColor:[UIColor colorWithWhite:0.7f alpha:1.0f]];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake((aView.bounds.size.width / 2), 0, 1, aView.bounds.size.height)];
    [line setBackgroundColor:[UIColor colorWithWhite:0.3f alpha:1.0f]];
    [aView addSubview:line];
    
    UILabel *luxLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 110, 35)];
    [luxLabel setBackgroundColor:[UIColor clearColor]];
    [luxLabel setTextColor:[UIColor colorWithWhite:0.3f alpha:1.0f]];
    [luxLabel setText:@"Ambient Light"];
    [luxLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [luxLabel setAdjustsFontSizeToFitWidth:YES];
    [aView addSubview:luxLabel];
    
    UILabel *brightnessLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 0, 110, 35)];
    [brightnessLabel setText:@"Brightness"];
    [brightnessLabel setFont:luxLabel.font];
    [brightnessLabel setBackgroundColor:luxLabel.backgroundColor];
    [brightnessLabel setTextColor:luxLabel.textColor];
    [aView addSubview:brightnessLabel];
    
    
    return aView;
}


-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        if (indexPath.row < [_savedPreferences count]) {
            [_savedPreferences removeObjectAtIndex:indexPath.row];
        }
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
