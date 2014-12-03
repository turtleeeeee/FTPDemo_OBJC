//
//  FTPHandler.m
//  FTPDemo_OBJC
//
//  Created by Turtleeeeeeeeee on 14/11/12.
//  Copyright (c) 2014年 SCNU. All rights reserved.
//

#import "FTPHandler.h"
#import "Reachability.h"
#import <zlib.h>

const static int kSendBufferSize = 32768;

@interface FTPHandler() <NSStreamDelegate>
{
    uint8_t _buffer[kSendBufferSize];
    BOOL _isSending;
    size_t _bufferOffset;   //目前写出的文件数据长度
    size_t _bufferLimit;
    size_t _totalBytesWritten;
    uint8_t _crcBuffer[kSendBufferSize];
    size_t _crcBufferOffset;
    size_t _crcBufferLimit;
}
@property (nonatomic, strong) NSInputStream *fileStream;
@property (nonatomic, strong) NSOutputStream *networkStream;
@property (nonatomic, strong) NSInputStream *crcFileStream;
@property (nonatomic, strong) NSOutputStream *crcNetworkStream;

- (BOOL) isNetworkReachable;
- (void)stopSendWithStatus:(NSString *)statusString andFlag:(BOOL)isSucceed;
@end


static NSString *kFtpURL = nil;
static NSString *kAccount = nil;
static NSString *kPsw = nil;
static NSString *kCatalog = nil;

@implementation FTPHandler


+ (FTPHandler *)shareHandler
{
    static FTPHandler *Handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Handler = [[self alloc] init];
    });
    return Handler;
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (id)init
{
    if (self = [super init])
    {
        //FTP configuration
        kCatalog = @"turtleeeee";
        kFtpURL = @"ftp://211.66.111.97";
        kAccount = @"xiuhui";
        kPsw = @"xiuhui";
        _totalBytesWritten = 0;
    }
    return self;
}

- (NSString *) getCRC:(NSString *)filePath
{
    NSString *crcFile = [filePath stringByAppendingString:@".txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:crcFile])
        return nil;
    NSData *hashData = [NSData dataWithContentsOfFile:filePath];
    uint32_t crc = crc32(0, NULL, 0);
    unsigned long creValue = crc32(crc, [hashData bytes], [hashData length]);
    NSString *crcStr = [NSString stringWithFormat:@"%lx", creValue];
    NSData *crcData = [crcStr dataUsingEncoding:NSUTF8StringEncoding];
    [crcData writeToFile:crcFile atomically:YES];
    NSLog(@"Created CRC Checksum");
    return crcFile;
}

- (BOOL) isNetworkReachable
{
    BOOL isNetworkReachable = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
    return isNetworkReachable;
}

- (void) uploadDataWithPath:(NSString *) filePath
{
    NSLog(@"%@",filePath);
    NSString *crcFile = [self getCRC:filePath];
    
    if([self isNetworkReachable])
    {
        if(crcFile)
        {
            //append suffix (file name)
            NSString *str = [kFtpURL stringByAppendingString:[NSString stringWithFormat:@"/%@", [filePath lastPathComponent]]];
            
            NSURL *url = [NSURL URLWithString:[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            BOOL success = (url != nil);
            
            if (success)
            {
                //读取文件，转化为输入流
                //read file,and turn it into input stream
                _fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
                assert(_fileStream != nil);
                
                [_fileStream open];
                
                //为url开启CFFTPStream输出流
                //open CFFTPStream output stream for url.
                _networkStream = CFBridgingRelease(
                                                   CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                                   );
                assert(_networkStream != nil);
                
                //设置ftp账号密码
                //configure account and password for ftp
                [_networkStream setProperty:kAccount forKey:(id)kCFStreamPropertyFTPUserName];
                [_networkStream setProperty:kPsw forKey:(id)kCFStreamPropertyFTPPassword];
                
                //设置networkStream流的代理，任何关于networkStream的事件发生都会调用代理方法
                //set networkStream's delegate.Every event about networkStream will call the delegate's methods.
                _networkStream.delegate = self;
                //设置runloop
                //configure runloop
                [_networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                if(_networkStream.streamStatus == NSStreamStatusNotOpen)
                {
                    [_networkStream open];
                    
                    // Tell the UI we're sending.
//                    [_delegate uploadShouldStart];
                    _totalBytesWritten = _bufferOffset= _bufferLimit = 0;
                    
                }
            }
            //CRC files' configuration
            //添加后缀（文件名称）
            str = [kFtpURL stringByAppendingString:[NSString stringWithFormat:@"/%@", [crcFile lastPathComponent]]];
            
            url = [NSURL URLWithString:[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            success = (url != nil);
            
            if (success)
            {
                //读取文件，转化为输入流
                _crcFileStream = [NSInputStream inputStreamWithFileAtPath:crcFile];
                assert(_crcFileStream != nil);
                
                [_crcFileStream open];
                
                //为url开启CFFTPStream输出流
                _crcNetworkStream = CFBridgingRelease(
                                                      CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                                      );
                assert(_crcNetworkStream != nil);
                
                //设置ftp账号密码
                [_crcNetworkStream setProperty:kAccount forKey:(id)kCFStreamPropertyFTPUserName];
                [_crcNetworkStream setProperty:kPsw forKey:(id)kCFStreamPropertyFTPPassword];
                
                //设置networkStream流的代理，任何关于networkStream的事件发生都会调用代理方法
                _crcNetworkStream.delegate = self;
                
            }
//            [_delegate didFinishUpload];
            
            
        }
        else
            [self stopSendWithStatus:@"重复上传" andFlag:NO];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //aStream 即为设置为代理的networkStream
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"NSStreamEventOpenCompleted");
        }
            break;
            
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"NSStreamEventHasBytesAvailable");
        }
            break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            if(aStream == _networkStream)
            {
                NSLog(@"NSStreamEventHasSpaceAvailable");
                NSLog(@"bufferOffset is %zd",_bufferOffset);
                NSLog(@"bufferLimit is %zu",_bufferLimit);
                if (_bufferOffset == _bufferLimit)
                {
                    NSInteger   bytesRead;
                    bytesRead = [_fileStream read:_buffer maxLength:kSendBufferSize];
                    
                    if (bytesRead == -1)
                    {
                        //读取文件错误
                        [self stopSendWithStatus:@"error with file" andFlag:NO];
                    }
                    else if (bytesRead == 0)
                    {
                        if (_networkStream != nil)
                        {
                            [_networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                            _networkStream.delegate = nil;
                            [_networkStream close];
                            _networkStream = nil;
                        }
                        
                        if (_fileStream != nil)
                        {
                            [_fileStream close];
                            _fileStream = nil;
                        }
                        
                        
                        //设置runloop
                        [_crcNetworkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                        if(_crcNetworkStream.streamStatus == NSStreamStatusNotOpen)
                        {
                            [_crcNetworkStream open];
                            _crcBufferOffset= _crcBufferLimit = 0;
                            
                        }
                        
                    }
                    else
                    {
                        _bufferOffset = 0;
                        _bufferLimit  = bytesRead;
                    }
                }
                
                if (_bufferOffset != _bufferLimit)
                {
                    //写入数据
                    NSInteger bytesWritten;         //bytesWritten为成功写入的数据
                    bytesWritten = [_networkStream write:&_buffer[_bufferOffset]
                                               maxLength:_bufferLimit - _bufferOffset];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1)
                        [self stopSendWithStatus:@"error with writing" andFlag:NO];
                    else
                    {
                        _bufferOffset += bytesWritten;
                        _totalBytesWritten += bytesWritten;
                    }
                }
            }
            else
            {
                NSLog(@"NSStreamEventHasSpaceAvailable");
                NSLog(@"bufferOffset is %zd",_crcBufferOffset);
                NSLog(@"bufferLimit is %zu",_crcBufferLimit);
                if (_crcBufferOffset == _crcBufferLimit)
                {
                    NSInteger   bytesRead;
                    bytesRead = [_crcFileStream read:_crcBuffer maxLength:kSendBufferSize];
                    
                    if (bytesRead == -1)
                    {
                        //读取文件错误
                        [self stopSendWithStatus:@"error with file" andFlag:NO];
                    }
                    else if (bytesRead == 0)
                    {
                        
                        //文件读取完成 上传完成
                        [self stopSendWithStatus:@"successfully uploading" andFlag:YES];
                        
                        [_delegate didFinishUpload];
                    }
                    else
                    {
                        _crcBufferOffset = 0;
                        _crcBufferLimit  = bytesRead;
                    }
                }
                
                if (_crcBufferOffset != _crcBufferLimit)
                {
                    //写入数据
                    NSInteger bytesWritten;         //bytesWritten为成功写入的数据
                    bytesWritten = [_crcNetworkStream write:&_buffer[_crcBufferOffset]
                                                  maxLength:_crcBufferLimit - _crcBufferOffset];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1)
                        [self stopSendWithStatus:@"error with writing" andFlag:NO];
                    else
                        _crcBufferOffset += bytesWritten;
                }
            }
        }
            break;
            
        case NSStreamEventErrorOccurred:
        {
            [self stopSendWithStatus:@"error with writing" andFlag:NO];
        }
            break;
            
        case NSStreamEventEndEncountered:
        {
            // 忽略
        }
            break;
            
        default:
            break;
    }
}

- (void)stopSendWithStatus:(NSString *)statusString andFlag:(BOOL)isSucceed
{
    if (_networkStream != nil)
    {
        [_networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _networkStream.delegate = nil;
        [_networkStream close];
        _networkStream = nil;
    }
    
    if (_fileStream != nil)
    {
        [_fileStream close];
        _fileStream = nil;
    }
    
    if (_crcNetworkStream != nil)
    {
        [_crcNetworkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _crcNetworkStream.delegate = nil;
        [_crcNetworkStream close];
        _crcNetworkStream = nil;
    }
    
    if (_crcFileStream != nil)
    {
        [_crcFileStream close];
        _crcFileStream = nil;
    }
    
//    [_delegate stopSendWithStatus:statusString andFlag:isSucceed];
}


- (size_t) getTotalBytesWritten
{
    return _totalBytesWritten;
}
@end
