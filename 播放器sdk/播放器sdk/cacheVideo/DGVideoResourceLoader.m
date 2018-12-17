//
//  DGVideoResourceLoader.m
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreServices/CoreServices.h>
#import "DGVideoResourceLoader.h"
#import "DGVideoStrFileHandle.h"

@interface DGVideoResourceLoader ()<DGVideoDownloadManagerDelegate>

/** 存放请求的数组*/
@property (strong, nonatomic) NSMutableArray *requestList;
/** 信号量，加锁保护资源用的*/
@property (strong, nonatomic) dispatch_semaphore_t semaphore;

@end
@implementation DGVideoResourceLoader

- (instancetype)init{
    self = [super init];
    if (self) {
        self.requestList = [NSMutableArray array];
    }
    return self;
}
-(dispatch_semaphore_t)semaphore {
    if (!_semaphore) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return _semaphore;
}
#pragma mark - avassetResourceLoaderDelegate
/**
 avasert 每次都会进这个方法，他会返回每次的loadingRequest
 
 @param resourceLoader resourceLoader
 @param loadingRequest loadingRequest
 @return 如果为YES：继续返回 NO:终止返回不在返回loadingRequest
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self handleLoadingRequest:loadingRequest];
    return YES;
}

/**
 处理完成的请求取消
 
 @param resourceLoader resourceLoader
 @param loadingRequest loadingRequest
 */
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    // 已经取消的 从数组中移除
    [self.requestList removeObject:loadingRequest];
}
#pragma mark - 自己事件的处理
/**
 处理delegatee给的loadingRequest
 
 @param loadingRequest loadingRequest
 */
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.requestList addObject:loadingRequest];
    if (self.downloadManager) {
        if (loadingRequest.dataRequest.requestedOffset >= self.downloadManager.requestOffset &&
            loadingRequest.dataRequest.requestedOffset <= self.downloadManager.requestOffset + self.downloadManager.cacheLength) {
            //数据已经缓存，则直接完成
            NSLog(@"数据已经缓存，则直接完成");
            [self haveCacheProcessRequestList];
        }else {
            //数据还没缓存，则等待数据下载；如果是Seek操作，则重新请求
            if (self.isSeek) {
                NSLog(@"Seek操作，则重新请求");
                [self startNewLoadrequest:loadingRequest cache:NO];
            }
        }
    }else {
        [self startNewLoadrequest:loadingRequest cache:YES];
    }
    // 完事就要发送信号
    dispatch_semaphore_signal(self.semaphore);
}
/**
 处理缓存好的的请求
 */
- (void)haveCacheProcessRequestList{
    
    NSMutableArray * finishRequestList = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest * loadingRequest in self.requestList) {
        if ([self configFinishLoadingRequest:loadingRequest]) {
            [finishRequestList addObject:loadingRequest];
        }
    }
    if (finishRequestList.count) {
      [self.requestList removeObjectsInArray:finishRequestList];
    }
}

/**
 配置相关的信息，并且判断完成了没
 
 @param loadingRequest loadingRequest
 @return 是否完成了
 */
- (BOOL)configFinishLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    NSString *mineType = [self.downloadManager getMyMimeType];
    if (mineType.length == 0) {
        mineType = @"video/mp4";
    }
    //填充信息
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mineType), NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.downloadManager.fileLenth;
    
    //读文件，填充数据
    NSUInteger cacheLength = self.downloadManager.cacheLength;
    NSUInteger requestedOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - self.downloadManager.requestOffset);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    NSUInteger offset = requestedOffset - self.downloadManager.requestOffset;
    if (requestedOffset < self.downloadManager.requestOffset) {
        offset = 0;
    }
    [loadingRequest.dataRequest respondWithData:[DGVideoStrFileHandle readTempFileDataWithOffset:offset length:respondLength]];
    //如果完全响应了所需要的数据，则完成
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}
/**
 开始发送新的请求
 
 @param loadingRequest loadingRequest
 @param isCache isCache
 */
- (void)startNewLoadrequest:(AVAssetResourceLoadingRequest *)loadingRequest cache:(BOOL)isCache{
    
    NSUInteger fileLength = 0;
    if (self.downloadManager) {
        fileLength = self.downloadManager.fileLenth;
        self.downloadManager.cancel = YES;
    }
    self.downloadManager = [[DGVideoDownloadManager alloc] init];
    self.downloadManager.requestURL = loadingRequest.request.URL;
    self.downloadManager.requestOffset = loadingRequest.dataRequest.requestedOffset;
    self.downloadManager.isCache = isCache;
    if (fileLength > 0) {
        self.downloadManager.fileLenth = fileLength;
    }
    self.downloadManager.downloadManagerDelegate = self;
    [self.downloadManager startRequest];
    self.isSeek = NO;
}
#pragma mark - downloadManager 的 delegate
/**
 下载的进度 0 - 1
 
 @param manager manager
 @param need 是否需要进度 YES : 需要进度 NO：不需要进度
 */
- (void)downloadManager:(DGVideoDownloadManager *)manager updateCacheProgressIsNeed:(BOOL)need{
    
    [self haveCacheProcessRequestList];
    if (need) {
        NSLog(@"需要");
        CGFloat cacheProgrss = 1.0 * self.downloadManager.cacheLength /(self.downloadManager.fileLenth - self.downloadManager.requestOffset);
        if ([self.loaderDelegate respondsToSelector:@selector(loader:resourceLoaderCacheProgress:)]) {
            [self.loaderDelegate loader:self resourceLoaderCacheProgress:cacheProgrss];
        }
    }else{
        NSLog(@"不需要");
        if ([self.loaderDelegate respondsToSelector:@selector(loader:resourceLoaderCacheProgress:)]) {
            [self.loaderDelegate loader:self resourceLoaderCacheProgress:0];
        }
        
    }
}
/**
 下载失败了
 
 @param downloadManager 下载管理者
 @param error 错误信息
 */
- (void)downloadManager:(DGVideoDownloadManager *)downloadManager failure:(NSError *)error{
    if ([self.loaderDelegate respondsToSelector:@selector(loader:failure:)]) {
        [self.loaderDelegate loader:self failure:error];
    }
}

@end

