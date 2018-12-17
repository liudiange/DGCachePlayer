//
//  DGResourceLoader.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreServices/CoreServices.h>
#import "DGResourceLoader.h"
#import "DGStrFileHandle.h"

@interface DGResourceLoader ()<DGDownloadManagerDelegate>

/** 存放请求的数组*/
@property (strong, nonatomic) NSMutableArray *requestList;
/** 信号量，加锁保护资源用的*/
@property (strong, nonatomic) dispatch_semaphore_t semaphore;


@end
@implementation DGResourceLoader

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
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
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
    
    // 将loadingRequest 添加进数组
    [self.requestList addObject:loadingRequest];
    NSLog(@"loadingRequest.dataRequest.requestedOffset :%lld ------ loadingRequest.dataRequest.currentOffset: %lld ---  self.downloadManager.requestOffset :%zd",loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.currentOffset,self.downloadManager.requestOffset);
    // 进行判断
    if (self.downloadManager) {
        if (loadingRequest.dataRequest.requestedOffset >= self.downloadManager.requestOffset && loadingRequest.dataRequest.requestedOffset < self.downloadManager.requestOffset + self.downloadManager.cacheLength) {
            NSLog(@"能进入这个判断 说明当前loadingrequest 是缓存好了的");
            // 能进入这个判断 说明当前loadingrequest 是缓存好了的
            [self haveCacheProcessRequestList];
        }else{
            // 不符合缓存规定了 不再缓存了
            if (self.isSeek) {
                NSLog(@"不符合缓存规定了 不再缓存了");
                [self startNewLoadrequest:loadingRequest cache:NO];
            }
        }
    }else{
        // 开始重新请求
        [self startNewLoadrequest:loadingRequest cache:YES];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 处理缓存好的的请求
 */
- (void)haveCacheProcessRequestList{
 
    NSMutableArray *haveFinishRequest = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.requestList) {
        if ([self configFinishLoadingRequest:loadingRequest]) {
            [haveFinishRequest addObject:loadingRequest];
        }
    }
    if (haveFinishRequest.count) {
        [self.requestList removeObjectsInArray:haveFinishRequest];
    }
}

/**
 配置相关的信息，并且判断完成了没

 @param loadingRequest loadingRequest
 @return 是否完成了
 */
- (BOOL)configFinishLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    NSString *mimeType = [self.downloadManager getMyMimeType];
    if (mimeType.length == 0) {
        mimeType = @"audio/mpeg";
    }
    // 填充信息
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.downloadManager.fileLenth;
    // 读文件 进行填充数据
    NSUInteger cacheLength = self.downloadManager.cacheLength;
    NSUInteger requestOffset = loadingRequest.dataRequest.currentOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestOffset = loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestOffset - self.downloadManager.requestOffset);
    NSUInteger respondLendth = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    NSUInteger offset = requestOffset - self.downloadManager.requestOffset;
    if (requestOffset < self.downloadManager.requestOffset) {
        offset = requestOffset;
    }
    [loadingRequest.dataRequest respondWithData:[DGStrFileHandle readTempFileDataWithOffset:offset length:respondLendth]];
    // 判断是否真正的完成了
    NSUInteger nowEndOffset = requestOffset + canReadLength;
    NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
    if (nowEndOffset > reqEndOffset) {
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
    self.downloadManager = [[DGDownloadManager alloc] init];
    self.downloadManager.requestOffset = loadingRequest.dataRequest.requestedOffset;
    self.downloadManager.requestURL = loadingRequest.request.URL;
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
- (void)downloadManager:(DGDownloadManager *)manager updateCacheProgressIsNeed:(BOOL)need{
    
    [self haveCacheProcessRequestList];
    if (need) {
       CGFloat cacheProgrss = 1.0 * self.downloadManager.cacheLength /(self.downloadManager.fileLenth - self.downloadManager.requestOffset);
        if ([self.loaderDelegate respondsToSelector:@selector(loader:resourceLoaderCacheProgress:)]) {
            [self.loaderDelegate loader:self resourceLoaderCacheProgress:cacheProgrss];
        }
    }else{
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
- (void)downloadManager:(DGDownloadManager *)downloadManager failure:(NSError *)error{
    if ([self.loaderDelegate respondsToSelector:@selector(loader:failure:)]) {
        [self.loaderDelegate loader:self failure:error];
    }
}

@end
