//
//  ViewController.h
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/12.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTPHandler.h"
#import "FileScatterAndMD5Handler.h"
#import "ASIHTTPRequest.h"

@interface ViewController : UIViewController
- (IBAction)StartUpload:(id)sender;
- (IBAction)StopUpload:(id)sender;
- (IBAction)ResumeUpload:(id)sender;
@end

