//
//  DGCacheVideoModel.h
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DGCacheVideoModel : NSObject

/** 视频id*/
@property (nonatomic,copy) NSString *playId;
/** 图片地址*/
@property (nonatomic,copy) NSString *picUrl;
/** 视频播放地址*/
@property (nonatomic,copy) NSString *playUrl;
/** 是否已收藏*/
@property (nonatomic,assign) BOOL isCollection;

@end

NS_ASSUME_NONNULL_END
