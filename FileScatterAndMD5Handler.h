//
//  FileScatterAndMD5Handler.h
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/17.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
@interface FileScatterAndMD5Handler : NSObject
+ (FileScatterAndMD5Handler *)sharedHandler;
- (void)writePartialFileOutWithACompleteFile:(NSData *)File andFilePath:(NSString *)filePath;
//- (void)readFileAndWriteTheirMD5OutWithACompleteFile:(NSData *)File andFilePath:(NSString *)filePath;
@end
