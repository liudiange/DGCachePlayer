//
//  DGVideoDownloadManager.m
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGVideoDownloadManager.h"
#import "DGVideoStrFileHandle.h"

#define DGTimeInterval 10.0

@interface DGVideoDownloadManager ()<NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionDataTask *task;
@property (copy, nonatomic) NSString *innerMyMimeType;

@end
@implementation DGVideoDownloadManager
-(instancetype)init{
    self = [super init];
    if (self) {
        [DGVideoStrFileHandle createTempFile];
    }
    return self;
}
/**
 开始发送请求
 */
- (void)startRequest{
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[DGVideoStrFileHandle originalUrl:self.requestURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:DGTimeInterval];
    if (self.requestOffset > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.requestOffset, self.fileLenth - 1] forHTTPHeaderField:@"Range"];
    }
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}
-(void)setCancel:(BOOL)cancel {
    _cancel = cancel;
    if (self.session) {
        [self.session invalidateAndCancel];
        [self.task cancel];
        self.session = nil;
        self.task = nil;
    }
}
/**
 获取mimetype
 
 @returnmimetype
 */
-(NSString *)getMyMimeType{
    return self.innerMyMimeType;
}
#pragma mark - delegate
/**
 请求完成
 
 @param session 会话
 @param task 任务
 @param error 错误信息
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
   
    if (self.cancel) return;
    
    if (error) {
        if ([self.downloadManagerDelegate respondsToSelector:@selector(downloadManager:failure:)]) {
            [self.downloadManagerDelegate downloadManager:self failure:error];
        }
    }else{
        if (self.isCache) {
            [DGVideoStrFileHandle cacheTempFileData:self.requestURL.absoluteString];
        }else{
            [DGVideoStrFileHandle deleteTempFile];
        }
    }
}
/**
 开始请求的回调
 
 @param session session
 @param dataTask 任务
 @param response 数据响应
 @param completionHandler 完成的handlehandler
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    self.innerMyMimeType = response.MIMEType;
    if (self.cancel) return;
   
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLenth = (NSUInteger)(fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength);
    // 下载进度回调
    if([self.downloadManagerDelegate respondsToSelector:@selector(downloadManager:updateCacheProgressIsNeed:)]){
        [self.downloadManagerDelegate downloadManager:self updateCacheProgressIsNeed:self.isCache == YES ? YES : NO];
    }
}

/**
 下载好的每一段数据的回调
 
 @param session session
 @param dataTask 任务
 @param data 数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    if (self.cancel) return;
    [DGVideoStrFileHandle writeTempFileData:data];
    self.cacheLength += data.length;
    // 下载进度回调
    if([self.downloadManagerDelegate respondsToSelector:@selector(downloadManager:updateCacheProgressIsNeed:)]){
        [self.downloadManagerDelegate downloadManager:self updateCacheProgressIsNeed:self.isCache == YES ? YES : NO];
    }
}
@end
