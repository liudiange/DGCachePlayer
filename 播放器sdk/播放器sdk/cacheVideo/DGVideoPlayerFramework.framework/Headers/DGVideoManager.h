//
//  DGVideoManager.h
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DGVideoInfo.h"

typedef NS_ENUM(NSUInteger,DGPlayerPlayOperate) {
    DGPlayerPlayOperateStop   = 1,     // 开始的状态
    DGPlayerPlayOperatePlay   = 2,     // 播放状态
    DGPlayerPlayOperatePause  = 3,     // 暂停状态
};
typedef NS_ENUM(NSUInteger,DGPlayerStatus) {
    DGPlayerStatusStop   = 1,     // 停止状态，开始的状态
    DGPlayerStatusPlay   = 2,     // 播放状态
    DGPlayerStatusPause  = 3,     // 暂停状态
    DGPlayerStatusBuffer = 4      // 缓冲状态
};
NS_ASSUME_NONNULL_BEGIN
#pragma mark - 相关的delegate 回调
@protocol DGVideoManagerDelegate <NSObject>
/**
 播放失败的回调
 @param status 播放状态
 AVPlayerStatusUnknown： 未知
 AVPlayerStatusReadyToPlay： 可以播放
 AVPlayerStatusFailed ：播放失败
 */
- (void)DGPlayerPlayFailure:(AVPlayerStatus)status;
/**
 播放器播放的缓冲的进度
 
 @param progress 进度。范围为：0-1
 */
- (void)DGPlayerBufferProgress:(CGFloat)progress;
/**
 当播放状态发生了改变回调
 
 @param status 播放的状态
 */
- (void)DGPlayerChangeStatus:(DGPlayerStatus)status;
/**
 一个视频播放完成的delegate，自动会播放下一个，不要再这里边播放下一个视频
 
 @param nextInfo 下一个的musicInfo
 */
- (void)DGPlayerFinished:(DGVideoInfo *)nextInfo;
/**
 代理回调当前的时间、总时间、播放进度
 
 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param progress 播放进度
 */
- (void)DGPlayerCurrentTime:(CGFloat)currentTime
                   duration:(CGFloat)durationTime
               playProgress:(CGFloat)progress;
@end
@interface DGVideoManager : NSObject

@property (weak, nonatomic) id <DGVideoManagerDelegate> DGDelegate;
#pragma mark - 初始化的方法，以及相关的设置等等
+(instancetype)shareInstance;
#pragma mark 可以直接获得的
/**
 当前的播放状态，方便用户随时拿到
 
 @return 对应的播放状态
 */
- (DGPlayerStatus)currentPlayeStatus;
/**
 当前的播放的模型
 
 @return 当前的播放模型
 */
- (DGVideoInfo *)currentMusicInfo;
/**
 当前播放e视频的下标
 
 @return 为了你更加省心 我给你提供出来
 */
- (NSUInteger)currentIndex;
/**
 获得播放列表
 
 @return 播放列表
 */
- (NSArray<DGVideoInfo *> *)getPlayList;
/**
 获得当前播放器的总时间
 
 @return 时间
 */
- (CGFloat )durationTime;
/**
 获得播放器的音量
 */
- (CGFloat)getVolueValue;
#pragma mark 需要自己实现的
/**
 设置播放列表没有设置播放列表播放器没有播放地址
 
 @param playList 需要播放的模型数组
 @param offset 偏移量
 @param videoGravity 视频的显示类型
 @param addViewLayer 需要添加的layer
 @param frame 视频的frame
 */
- (void)setPlayList:(NSArray<DGVideoInfo *> *)playList
             offset:(NSUInteger)offset
       videoGravity:(AVLayerVideoGravity)videoGravity
       addViewLayer:(CALayer *)addViewLayer
         layerFrame:(CGRect)frame;
/**
 点击下一个播放
 */
- (void)playNextVideo;
/**
 播放上一个视频
 */
- (void)playPreviousVideo;
/**
 设置当前的播放动作
 
 @param Operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGPlayerPlayOperate)Operate;
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay;
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGVideoInfo *>*)deleteList;
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的视频的数组
 */
- (void)addPlayList:(NSArray<DGVideoInfo *>*)addList;
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


@end

NS_ASSUME_NONNULL_END
