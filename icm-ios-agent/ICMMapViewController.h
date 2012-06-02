//
//  ICMMapViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-6-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define METERS_PER_MILE 1609.344

@interface ICMMapViewController : UIViewController<MKMapViewDelegate>
{
    BOOL _doneInitialZoom;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshBtn;

- (IBAction)refreshBtnTapped:(id)sender;

@end
