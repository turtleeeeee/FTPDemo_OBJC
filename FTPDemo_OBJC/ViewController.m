//
//  ViewController.m
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/12.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<FTPHandlerDelegate>
{
    size_t _length;
    NSInteger _allFileNum;
    NSInteger _uploadedFileNum;
}
@property (strong, nonatomic)FTPHandler *ftpHandler;
@property (strong, nonatomic)FileScatterAndMD5Handler *fileScatterAndMD5Handler;
@property (strong, nonatomic)NSString *filePath;
@property (strong, nonatomic)NSString *fileName;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _ftpHandler = [FTPHandler shareHandler];
    _ftpHandler.delegate = self;
    _fileScatterAndMD5Handler = [FileScatterAndMD5Handler sharedHandler];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    //FilePath means the path of the stuff you're going to upload.
    _filePath = [documentDirectory stringByAppendingString:@"/Programming iOS 7 (4th Edition).pdf"];
    _fileName = @"Programming iOS 7 (4th Edition)";
}

- (void)scatterFileAndUploadFile
{
    
    NSData *preuploadFile = [NSData dataWithContentsOfFile:_filePath];
    
    //Scatter a complete file to a bunch of 5mb file,and make md5 verification for the complete one.
    [_fileScatterAndMD5Handler writePartialFileOutWithACompleteFile:preuploadFile andFilePath:_filePath];
    NSUInteger lengthOfFile = [preuploadFile length];
    NSUInteger lengthPartialFile = 1024 * 1024 * 5;
    _allFileNum = lengthOfFile / lengthPartialFile + 1;
    [[NSUserDefaults standardUserDefaults]setInteger:_allFileNum forKey:[NSString stringWithFormat:@"%@_ALL_FILE_NUM",_fileName]];
    _uploadedFileNum = 0;
    
    //start uploading partial files from the first part of them.
    [_ftpHandler uploadDataWithPath:[NSString stringWithFormat:@"%@.1",_filePath]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - FTPHandlerDelegate

- (void)didFinishUpload
{
    ++_uploadedFileNum;
    if (_uploadedFileNum < _allFileNum) {
        [_ftpHandler uploadDataWithPath:[NSString stringWithFormat:@"%@.%ld",_filePath,_uploadedFileNum + 1]];
    }
    if (_uploadedFileNum == _allFileNum) {
        [_ftpHandler uploadDataWithPath:[NSString stringWithFormat:@"%@md5.txt",_filePath]];
    }
    //make the program to memorize the number of uploaded files,even though you shut it down and restart it.
    [[NSUserDefaults standardUserDefaults]setInteger:_uploadedFileNum forKey:[NSString stringWithFormat:@"%@_UPLOADED_FILE_NUM",_fileName]];
}

- (IBAction)StartUpload:(id)sender {
    [self scatterFileAndUploadFile];
}

- (IBAction)StopUpload:(id)sender {
    [_ftpHandler stopSendWithStatus:@"stop transferring" andFlag:NO];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@.%ld.txt",_filePath,_uploadedFileNum + 1] error:nil];
}

- (IBAction)ResumeUpload:(id)sender {
    _uploadedFileNum = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@_UPLOADED_FILE_NUM",_fileName]];
    _allFileNum = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"%@_ALL_FILE_NUM",_fileName]];
    if (_uploadedFileNum < _allFileNum) {
        [_ftpHandler uploadDataWithPath:[NSString stringWithFormat:@"%@.%ld",_filePath,_uploadedFileNum + 1]];
    }
    else if(_uploadedFileNum == _allFileNum){
        [_ftpHandler uploadDataWithPath:[NSString stringWithFormat:@"%@md5.txt",_filePath]];
    }
    else{
        NSLog(@"Mission accomplished");
    }
}
@end
