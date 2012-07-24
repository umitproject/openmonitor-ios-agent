//
//  LoginFormViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-7-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginFormViewControllerDelegate;

@interface LoginFormViewController : UITableViewController {
    __weak id<LoginFormViewControllerDelegate> delegate;
    
    UITextField *usernameTF;
    UITextField *passwordTF;
}

@property (weak) id <LoginFormViewControllerDelegate> delegate;

@end

@protocol LoginFormViewControllerDelegate 

- (void)logInWithUsername:(NSString *)name password:(NSString*)pass;
- (void)cancelLogin;

@end