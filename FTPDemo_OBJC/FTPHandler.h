//
//  FTPHandler.h
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/12.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

@protocol FTPHandlerDelegate
@required
//- (void)stopSendWithStatus:(NSString *)statusString andFlag:(BOOL) isSucceed;
//- (void)errorWithNetworkStatus:(NSString *)statusString;
//- (void)uploadShouldStart;
- (void)didFinishUpload;
@end

@interface FTPHandler : NSObject
@property (nonatomic, weak) id<FTPHandlerDelegate> delegate;
+ (FTPHandler *)shareHandler;
- (void)uploadDataWithPath:(NSString *)path;
//- (void)downloadDataWithPath:(NSString *)path;
- (size_t) getTotalBytesWritten;
- (void)stopSendWithStatus:(NSString *)statusString andFlag:(BOOL)isSucceed;
@end
