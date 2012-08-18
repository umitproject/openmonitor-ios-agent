//
//  ICMWebsiteTableViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "QuartzCore/QuartzCore.h"
#import "ICMWebsiteTableViewController.h"
#import "ICMWebsite.h"
#import "ICMAppDelegate.h"
#import "ICMUpdater.h"

#define kAppIconWidth  32
#define kAppIconHeight 32

@implementation ICMWebsiteTableViewController

@synthesize managedObjectContext;
@synthesize imageDownloadsInProgress, imageCache;


-(id)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        self.managedObjectContext = [ICMAppDelegate GetContext];
		self.titleKey = @"name";
		self.subtitleKey = nil;
		//self.searchKey = nil;//@"text";
        selectedIndex = -1;
        networkEngine = [[MKNetworkEngine alloc] initWithHostName:nil];
        [networkEngine useCache];
        self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
        self.imageCache = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Website";
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self performFetchAndReload];
}

- (void)viewDidUnload {
    refreshBtn = nil;
}

- (void)dealloc {
    self.managedObjectContext = nil;
    self.imageDownloadsInProgress = nil;
    self.imageCache = nil;
}

- (void)performFetchAndReload
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"ICMWebsite" inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                     ascending:YES
                                                                                      selector:nil]];

    //request.predicate = [NSPredicate predicateWithFormat:@"(tags CONTAINS %@)", tag];
    request.fetchBatchSize = 20;
    
    [NSFetchedResultsController deleteCacheWithName:nil];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc]
                                       initWithFetchRequest:request
                                       managedObjectContext:self.managedObjectContext
                                       sectionNameKeyPath:nil
                                       cacheName:@"WebsiteCache"];
    
    request = nil;
    
    self.fetchedResultsController = frc;
    frc = nil;
    
    // fetch and reload
    [self performFetchForTableView:self.tableView];
}

- (UIImage *)thumbnailImageForManagedObject:(NSManagedObject *)managedObject withIndexPath:(NSIndexPath*)indexPath
{
    ICMWebsite* site = (ICMWebsite*)managedObject;
    NSString * imageUrlString = [NSString stringWithFormat:@"%@/favicon.ico", site.url];
    if (imageUrlString && [imageUrlString length] > 0) {
        UIImage *image = [self.imageCache objectForKey:imageUrlString];
        if (image)
        {
            return image;
        }
        //FIXME if last time failed, do we need to download it again?
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
        {
            [self startIconDownload:imageUrlString withIndexPath:indexPath];
        }
    }
    //TODO return a place holder if image url string is not empty.
    return nil;
}

- (UIImage *)statusImageForManagedObject:(NSManagedObject *)managedObject
{
    ICMWebsite* website = (ICMWebsite*)managedObject;
    if ([website.status intValue] == 200) {
        return [UIImage imageNamed:@"pinhead-green"];
    }
    return [UIImage imageNamed:@"pinhead-red"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForManagedObject:(NSManagedObject *)managedObject atIndex:(NSIndexPath *)indexPath
{
    //do customizing here
    static NSString *ReuseIdentifier = @"CoreDataTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:ReuseIdentifier] autorelease];
        
        UITableViewCellStyle cellStyle = UITableViewCellStyleSubtitle;//self.subtitleKey ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:ReuseIdentifier];
        cell.textLabel.backgroundColor = [UIColor clearColor];
		//cell.textLabel.textColor = [UIColor lightGrayColor];
        
        //cell.contentView.backgroundColor = [UIColor blackColor];
    }
    if (self.titleKey) cell.textLabel.text = [managedObject valueForKey:self.titleKey];
    if (selectedIndex == indexPath.row) {
        cell.detailTextLabel.textColor = [UIColor darkTextColor];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.detailTextLabel.numberOfLines = 4;
        ICMWebsite* site = (ICMWebsite*)managedObject;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"URL: %@\nStatus: %@\nDate: %@", site.url, site.status, [site.lastcheck descriptionWithLocale:[NSLocale currentLocale]]];
    } else {
        cell.detailTextLabel.text = nil;
    }

    UIImage *statusImage = [self statusImageForManagedObject:managedObject];
    if (statusImage) cell.imageView.image = statusImage;//?
    
    cell.accessoryType = [self accessoryTypeForManagedObject:managedObject];
    UIImage *thumbnailImage = [self thumbnailImageForManagedObject:managedObject withIndexPath:indexPath];
    if(thumbnailImage) {
        UIImageView* thumbnailImageView =  [[UIImageView alloc] initWithImage:thumbnailImage];

        // Following code add shadow, can't work with the round-corner code.
        thumbnailImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        thumbnailImageView.layer.shadowOpacity = 1.0;
        thumbnailImageView.layer.shadowRadius = 3.0;
        thumbnailImageView.layer.shadowOffset = CGSizeMake(0, 0);
        thumbnailImageView.clipsToBounds = NO;
        
        thumbnailImageView.layer.shouldRasterize = YES; // it's said to be good for performance.
        thumbnailImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        cell.accessoryView = thumbnailImageView;
    } else {
        cell.accessoryView = nil;
    }

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ICMWebsite *site = (ICMWebsite *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"selected site with url %@", site.url);
    
    //The user is selecting the cell which is currently expanded
    //we want to minimize it back
    if(selectedIndex == indexPath.row)
    {
        selectedIndex = -1;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        return;
    }

    //First we check if a cell is already expanded.
    //If it is we want to minimize make sure it is reloaded to minimize it back
    if(selectedIndex >= 0)
    {
        NSIndexPath *previousPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        selectedIndex = indexPath.row;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:previousPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    //Finally set the selected index to the new selection and reload it to expand
    selectedIndex = indexPath.row;
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedIndex == indexPath.row) {
        return 120;
    } else {
        return 40;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma -
#pragma events handler

- (IBAction)refreshBtnTapped:(UIBarButtonItem *)sender {
    
    [ICMUpdater fireWebsiteTester];
}

#pragma -
#pragma icon downloader method

- (void)startIconDownload:(NSString *)thumbUrl withIndexPath:(NSIndexPath*)indexPath
{
    UIImage *image = [self.imageCache objectForKey:thumbUrl];
    if (image)
        return;
    
    if ([imageDownloadsInProgress objectForKey:thumbUrl]) {
        return;
    }
    
    MKNetworkOperation *op = [networkEngine operationWithURLString:thumbUrl
                                                   params:nil
                                               httpMethod:@"GET"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        DLog(@"[%d]%@", [operation HTTPStatusCode], operation);
        // Use when fetching binary data
        NSData *responseData = [operation responseData];
        // Set appIcon and clear temporary data/image
        UIImage *image = [[UIImage alloc] initWithData:responseData];
        if (image) {
            image = [ICMWebsiteTableViewController scaleImage:image toSize:CGSizeMake(kAppIconWidth, kAppIconHeight)];
            [imageCache setObject:image forKey:thumbUrl];
            [self.tableView reloadData];
        }
        [imageDownloadsInProgress removeObjectForKey:thumbUrl];
    } onError:^(NSError *error) {
        DLog(@"[%d]%@", [op HTTPStatusCode], error);
    }];
    
    [imageDownloadsInProgress setObject:op forKey:thumbUrl];
    [networkEngine enqueueOperation:op];
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows
{
    if ([[self.fetchedResultsController fetchedObjects] count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
            UITableViewCell * cell = [self tableView:self.tableView cellForManagedObject:managedObject atIndex:indexPath];
            if (!cell.accessoryView) // avoid the app icon download if the app already has an icon
            {
                ICMWebsite* site = (ICMWebsite*)managedObject;
                NSString * imageUrlString = [NSString stringWithFormat:@"%@/favicon.ico", site.url];
                //NSLog(@"thumb url: %@", imageUrlString);
                if (imageUrlString && [imageUrlString length] > 0) {
                    [self startIconDownload:imageUrlString withIndexPath:indexPath];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark Image Resizing and Cropping

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize {
    //If scaleFactor is not touched, no scaling will occur      
    CGFloat scaleFactor = 1.0;
    
    //Deciding which factor to use to scale the image (factor = targetSize / imageSize)
    if (!((scaleFactor = (targetSize.width / image.size.width)) > (targetSize.height / image.size.height))) //scale to fit width, or
        scaleFactor = targetSize.height / image.size.height; // scale to fit heigth.
    
    UIGraphicsBeginImageContext(targetSize); 
    
    //Creating the rect where the scaled image is drawn in
    CGRect rect = CGRectMake((targetSize.width - image.size.width * scaleFactor) / 2,
                             (targetSize.height -  image.size.height * scaleFactor) / 2,
                             image.size.width * scaleFactor, image.size.height * scaleFactor);
    
    //Draw the image into the rect
    [image drawInRect:rect];
    
    //Saving the image, ending image context
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //NSLog(@"dragging end");
    if (!decelerate)
	{
        //NSLog(@"dragging end && not decelerate");
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //NSLog(@"decelerating end");
    [self loadImagesForOnscreenRows];
}

@end
