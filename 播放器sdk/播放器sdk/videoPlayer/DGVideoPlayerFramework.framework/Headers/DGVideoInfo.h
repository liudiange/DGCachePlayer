//
//  DGVideoInfo.h
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DGVideoInfo : NSObject
// 视频id
@property (nonatomic,copy) NSString *videoId;
// 视频地址
@property (nonatomic,copy) NSString *playUrl;
// 是否已收藏
@property (nonatomic,assign) BOOL isCollection;
@end

NS_ASSUME_NONNULL_END
