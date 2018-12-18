//
//  DGDownloadManager.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGDownloadManager.h"
#import "DGStrFileHandle.h"

#define DGTimeInterval 10

@interface DGDownloadManager ()<NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionDataTask *task;
@property (copy, nonatomic) NSString *innerMyMimeType;

@end

@implementation DGDownloadManager
- (instancetype)init{
    if (self = [super init]) {
        [DGStrFileHandle creatTempFile];
    }
    return self;
}
/**
 开始发送请求
 */
- (void)startRequest{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[DGStrFileHandle originalUrl:self.requestURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:DGTimeInterval];
    if (self.requestOffset > 0) {
        // 从那块请求到那块
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",self.requestOffset,self.fileLenth - 1] forHTTPHeaderField:@"Range"];
    }
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}
-(void)setCancel:(BOOL)cancel {
    _cancel = cancel;
    if (self.session) {
        [self.task cancel];
        [self.session invalidateAndCancel];
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
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    if (self.cancel) return;
    
    if (error) {
        if ([self.downloadManagerDelegate respondsToSelector:@selector(downloadManager:failure:)]) {
            [self.downloadManagerDelegate downloadManager:self failure:error];
        }
    }else{
        if (self.isCache) {
            [DGStrFileHandle cacheTempFileData:self.requestURL.absoluteString];
        }else{
            [DGStrFileHandle deleteTempFile];
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
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    self.innerMyMimeType = response.MIMEType;
    if (self.cancel) return;
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString *fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLenth = (NSUInteger)(fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength);
    
}

/**self.cacheLength
 下载好的每一段数据的回调

 @param session session
 @param dataTask 任务
 @param data 数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if (self.cancel) return;
    [DGStrFileHandle writeTempFileData:data];
    self.cacheLength += data.length;
    // 下载进度回调
    if([self.downloadManagerDelegate respondsToSelector:@selector(downloadManager:updateCacheProgressIsNeed:)]){
        [self.downloadManagerDelegate downloadManager:self updateCacheProgressIsNeed:self.isCache == YES ? YES : NO];
    }
}

@end
