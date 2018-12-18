//
//  DGCacheMusicPlayer.h
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DGCacheMusicModel.h"

typedef  NS_ENUM(NSUInteger,DGCacheMusicErrorCode) {
    
    DGCacheMusicErrorCode101     = 101, // 非缓存播放出错的错误码
    
};
typedef NS_ENUM(NSUInteger,DGCacheMusicState) {
    DGCacheMusicStatePlay        = 1, // 播放
    DGCacheMusicStatePause       = 2, // 暂停
    DGCacheMusicStateBuffer      = 3, // 缓冲
    DGCacheMusicStateStop        = 4, // 停止
    DGCacheMusicStateError       = 5, // 错误
};
typedef NS_ENUM(NSUInteger, DGCacheMusicMode){
    
    DGCacheMusicModeListRoop       = 1, // 列表循环
    DGCacheMusicModeRandom         = 2, // 随机播放
    DGCacheMusicModeSingleRoop     = 3  // 单曲循环
};
typedef NS_ENUM(NSUInteger, DGCacheMusicOperate){
    
    DGCacheMusicOperatePlay       = 1, // 播放操作
    DGCacheMusicOperatePause      = 2, // 暂停操作
    DGCacheMusicOperateStop       = 3  // 停止操作
};
NS_ASSUME_NONNULL_BEGIN

@protocol DGCacheMusicPlayerDelegate <NSObject>
/**
 播放失败了

 @param error error
 */
- (void)DGCacheMusicPlayFailed:(NSError *)error;

/**
 一首歌曲播放完成了，会把下一首需要播放的歌曲返回来 会自动播放下一首，不要再这里播放下一首

 @param nextModel 下一首歌曲的模型
 */
- (void)DGCacheMusicPlayFinish:(DGCacheMusicModel *)nextModel;
/**
 播放模式发生了改变了

 @param mode 返回来的mode
 */
- (void)DGCacheMusicPlayModeChanged:(DGCacheMusicMode )mode;
/**
 播放状态发生了改变

 @param status 改变后的状态
 */
- (void)DGCacheMusicPlayStatusChanged:(DGCacheMusicState)status;
/**
 缓存的进度 注意：当需要缓存的时候是下载的进度 不需要缓存的时候是监听player loadedTimeRanges的进度

 @param cacheProgress 播放的缓存的进度
 */
- (void)DGCacheMusicCacheProgress:(CGFloat )cacheProgress;

/**
 当前时间 总的时间 缓冲的进度的播放代理回调

 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param playProgress 播放的进度 （0-1）之间
 */
- (void)DGCacheMusicPlayerCurrentTime:(CGFloat)currentTime
                             duration:(CGFloat)durationTime
                         playProgress:(CGFloat)playProgress;



@end
@interface DGCacheMusicPlayer : NSObject
#pragma mark - 初始化
@property (weak, nonatomic) id <DGCacheMusicPlayerDelegate> DGCacheMusicDelegate;
+(instancetype)shareInstance;

#pragma mark - 设置相关的方法
/**
 设置播放列表没有设置播放列表播放器没有播放地址

 @param playList 需要播放的模型数组
 @param offset 偏移量
 @param cache 是否需要缓存 YES：边下边播 NO:不缓存 在线播放
 */
- (void)setPlayList:(NSArray<DGCacheMusicModel *> *)playList
             offset:(NSUInteger)offset
            isCache:(BOOL)cache;
/**
 点击下一首播放
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playNextSong:(BOOL)isNeedSingRoopJump;
/**
 播放上一首歌曲
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playPreviousSong:(BOOL)isNeedSingRoopJump;
/**
 设置当前的播放动作
 
 @param operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGCacheMusicOperate)operate;
/**
 设置当前的播放模式
 
 @param mode 自己要设置的模式
 */
- (void)updateCurrentPlayMode:(DGCacheMusicMode)mode;
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay;
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGCacheMusicModel *>*)deleteList;
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的歌曲的数组
 */
- (void)addPlayList:(NSArray<DGCacheMusicModel *>*)addList;
/**
 快进或者快退
 
 @param time 要播放的那个时间点
 */
- (void)seekTime:(NSUInteger)time;
/**
 设置播放器的音量 非系统也就是不是点击手机音量加减的音量
 
 @param value 【0-10】大于10 等于10  下于0 等于0
 */
- (void)setVolumeValue:(CGFloat)value;
#pragma mark - 可以获得的方法
/**
 当前的播放状态，方便用户随时拿到
 
 @return 对应的播放状态
 */
- (DGCacheMusicState)currentPlayeStatus;
/**
 获取到当前的播放模式
 
 @return 对应的播放模式
 */
- (DGCacheMusicMode)currentPlayMode;
/**
 当前的播放的模型
 
 @return 当前的播放模型
 */
- (DGCacheMusicModel *)currentMusicModel;
/**
 当前播放e歌曲的下标
 
 @return 为了你更加省心 我给你提供出来
 */
- (NSUInteger)currentIndex;
/**
 获得播放列表
 
 @return 播放列表
 */
- (NSArray<DGCacheMusicModel *> *)getPlayList;
/**
 获得当前播放器的总时间
 
 @return 时间
 */
- (CGFloat )durationTime;
/**
 获得播放器的音量
 */
- (CGFloat)getVolueValue;

@end
NS_ASSUME_NONNULL_END
