//
//  DGCacheMusicModel.h
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DGCacheMusicModel : NSObject

//歌曲id
@property (nonatomic,copy) NSString *musicId;
//歌曲名称
@property (nonatomic,copy) NSString *musicName;
//歌手名
@property (nonatomic,copy) NSString *singerName;
//专辑名字
@property (nonatomic,copy) NSString *albumName;
//图片地址
@property (nonatomic,copy) NSString *picUrl;
//歌词地址
@property (nonatomic,copy) NSString *lrcUrl;
//歌曲地址
@property (nonatomic,copy) NSString *listenUrl;
//是否已收藏
@property (nonatomic,assign) BOOL isCollection;


@end

NS_ASSUME_NONNULL_END
