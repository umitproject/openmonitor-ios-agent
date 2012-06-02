//
//  ICMMapViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-6-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMMapViewController.h"
#import "ICMAnnotation.h"

@interface ICMMapViewController ()

@end

@implementation ICMMapViewController
@synthesize mapView;
@synthesize refreshBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {  
    // 1
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 39.9100;
    zoomLocation.longitude= 116.4000;
    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 900*METERS_PER_MILE, 900*METERS_PER_MILE);
    // 3
    MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];                
    // 4
    [mapView setRegion:adjustedRegion animated:YES];      
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = @"Map";
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setRefreshBtn:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (MKAnnotationView *)mapView:(MKMapView *)amapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString *identifier = @"ICMAnnotation";   
    if ([annotation isKindOfClass:[ICMAnnotation class]]) {
        
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            annotationView.annotation = annotation;
        }
        
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    return nil;    
}

- (void)plotCrimePositions {

    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (int i = 0; i < 30; i++) {
        
        NSNumber * latitude = [NSNumber numberWithInt:(arc4random() % 40 + 14)];
        NSNumber * longitude = [NSNumber numberWithInt:(arc4random() % 40 + 88)];
        NSString * name = @"Website Censor";
        NSString * address = @"China";
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude.doubleValue;
        coordinate.longitude = longitude.doubleValue;            
        ICMAnnotation *annotation = [[ICMAnnotation alloc] initWithName:name address:address coordinate:coordinate] ;
        [mapView addAnnotation:annotation];    
    }
}

- (IBAction)refreshBtnTapped:(id)sender {
    [self plotCrimePositions];
}

@end
