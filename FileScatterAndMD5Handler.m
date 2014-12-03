//
//  FileScatterAndMD5Handler.m
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/17.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import "FileScatterAndMD5Handler.h"

@interface FileScatterAndMD5Handler()
@property (nonatomic, strong)NSMutableString *MD5Str;
@end

@implementation FileScatterAndMD5Handler
+ (FileScatterAndMD5Handler *)sharedHandler{
    static FileScatterAndMD5Handler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[self alloc]init];
    });
    return handler;
}

- (void)writePartialFileOutWithACompleteFile:(NSData *)File andFilePath:(NSString *)filePath
{
    NSUInteger lengthOfFile = [File length];
    NSUInteger lengthPartialFile = 1024 * 1024 * 5;
    NSUInteger fileNum = lengthOfFile / lengthPartialFile + 1;
    NSUInteger lastPartialFileLength = lengthOfFile % lengthPartialFile;
    unsigned char result[16];
    const void *rawFile = malloc(lengthOfFile);
    rawFile = [File bytes];
    CC_MD5(rawFile, (CC_LONG)lengthOfFile, result);
    _MD5Str = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:
                                                      @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                                      result[0], result[1], result[2], result[3],
                                                      result[4], result[5], result[6], result[7],
                                                      result[8], result[9], result[10], result[11],
                                                      result[12], result[13], result[14], result[15]
                                                       ]];
    NSError *error = nil;
    [_MD5Str writeToFile:[NSString stringWithFormat:@"%@md5.txt",filePath] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    for (int i = 1; i <= fileNum; ++i) {
        if (i<fileNum) {
            void *rawPartialFile = malloc(lengthPartialFile);
            [File getBytes:rawPartialFile range:NSMakeRange(lengthPartialFile * (i-1), lengthPartialFile)];
            NSData *partialFileData = [NSData dataWithBytes:rawPartialFile length:lengthPartialFile];
            [partialFileData writeToFile:[NSString stringWithFormat:@"%@.%d",filePath,i] atomically:NO];
        }
        else{
            void *rawLastPartialFile = malloc(lastPartialFileLength);
            [File getBytes:rawLastPartialFile range:NSMakeRange(lengthPartialFile * (i-1), lastPartialFileLength)];
            NSData *lastPartialFileData = [NSData dataWithBytes:rawLastPartialFile length:lastPartialFileLength];
            [lastPartialFileData writeToFile:[NSString stringWithFormat:@"%@.%d",filePath,i] atomically:NO];
        }
    }
}

//It's unneccessary to make a md5 string for every single partial file because of CRC management.

//- (void)readFileAndWriteMD5OutWithACompleteFile:(NSData *)File andFilePath:(NSString *)filePath
//{
//    NSUInteger lengthOfFile = [File length];
//    NSUInteger lengthPartialFile = 1024 * 1024 * 5;
//    NSUInteger fileNum = lengthOfFile / lengthPartialFile + 1;
//    //每个单独文件的md5都加到MD5Str中，每个字串用.分割
//    for (int i=1; i<=fileNum; ++i) {
//        NSData *partialFile = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@.%d",filePath,i]];
//        unsigned char result[16];
//        const void *rawFile = malloc(lengthPartialFile);
//        rawFile = [partialFile bytes];
//        CC_MD5(rawFile, (CC_LONG)lengthPartialFile, result);
//        [_MD5Str appendFormat:@".%@",[NSString stringWithFormat:
//                                     @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//                                     result[0], result[1], result[2], result[3],
//                                     result[4], result[5], result[6], result[7],
//                                     result[8], result[9], result[10], result[11],
//                                     result[12], result[13], result[14], result[15]
//                                      ]];
//        NSError *error = nil;
//        [_MD5Str writeToFile:[NSString stringWithFormat:@"%@md5.txt",filePath] atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    }
//}
@end
