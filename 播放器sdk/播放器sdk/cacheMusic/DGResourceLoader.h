//
//  DGResourceLoader.h
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "DGDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN
@class DGResourceLoader;

@protocol DGResourceLoaderDelegate <NSObject>
@required
/**
 下载进度的回调

 @param loader 当前对象
 @param loaderCacheProgress 下载的进度 【0 - 1】之间
 */
- (void)loader:(DGResourceLoader *)loader resourceLoaderCacheProgress:(CGFloat)loaderCacheProgress;
@optional
/**
 失败了 网络等等的什么原因

 @param loader 当前对象
 @param error 错误信息
 */
- (void)loader:(DGResourceLoader *)loader failure:(NSError *)error;

@end
@interface DGResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

@property (weak, nonatomic) id<DGResourceLoaderDelegate> loaderDelegate;
/** 是否向前拖动了，等等大于缓存区域了*/
@property (assign, nonatomic) BOOL isSeek;
/** 下载任务的管理器*/
@property (strong, nonatomic) DGDownloadManager *downloadManager;

@end

NS_ASSUME_NONNULL_END
