//
//  ICMFirstViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICMFirstViewController : UIViewController {
    __weak IBOutlet UIButton *startBtn;
    __weak IBOutlet UISwitch *firstNodeSwitch;
    __weak IBOutlet UILabel *statusLabel;
}

- (IBAction)startBtnTapped:(id)sender;


@end
