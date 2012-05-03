//
//  ICMSecondViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICMSecondViewController : UIViewController {
    
    __weak IBOutlet UITextField *putKeyTF;
    __weak IBOutlet UITextField *putValueTF;
    __weak IBOutlet UILabel *putResultLabel;
    __weak IBOutlet UIButton *putKVBtn;
    
    __weak IBOutlet UITextField *getKeyTF;
    __weak IBOutlet UITextField *getValueTF;
    __weak IBOutlet UIButton *getKVBtn;
}

- (IBAction)putKVBtnTapped:(id)sender;
- (IBAction)getKVBtnTapped:(id)sender;

@end
