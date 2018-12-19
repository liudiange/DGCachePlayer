# DGCachePlayer 一个边下边播的播放器，包括非缓存音频、非缓存视频、缓存音频、缓存视频
### 怎样使用 以缓存的视频为例
````objc
@protocol DGCacheVideoPlayerDelegate <NSObject>
/**
 播放失败了
 
 @param error error
 */
- (void)DGCacheVideoPlayFailed:(NSError *)error;

/**
 一首歌曲播放完成了，会把下一首需要播放的歌曲返回来 会自动播放下一首，不要再这里播放下一首
 
 @param nextModel 下一首歌曲的模型
 */
- (void)DGCacheVideoPlayFinish:(DGCacheVideoModel *)nextModel;
/**
 播放状态发生了改变
 
 @param status 改变后的状态
 */
- (void)DGCacheVideoPlayStatusChanged:(DGCacheVideoState)status;
/**
 缓存的进度 注意：当需要缓存的时候是下载的进度 不需要缓存的时候是监听player loadedTimeRanges的进度
 
 @param cacheProgress 播放的缓存的进度
 */
- (void)DGCacheVideoCacheProgress:(CGFloat )cacheProgress;

/**
 当前时间 总的时间 缓冲的进度的播放代理回调
 
 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param playProgress 播放的进度 （0-1）之间
 */
- (void)DGCacheVideoPlayerCurrentTime:(CGFloat)currentTime
                             duration:(CGFloat)durationTime
                         playProgress:(CGFloat)playProgress;



@end
@interface DGCacheVideoPlayer : NSObject
#pragma mark - 初始化
@property (weak, nonatomic) id <DGCacheVideoPlayerDelegate> DGCacheVideoDelegate;
+(instancetype)shareInstance;
#pragma mark - 设置相关的方法

/**
 设置播放列表没有设置播放列表播放器没有播放地址
 
 @param playList 需要播放的模型数组
 @param offset 偏移量
 @param videoGravity 视频的显示类型
 @param addViewLayer 需要添加的layer
 @param cache 是否缓存 YES: 缓存 NO:不缓存
 @param frame 视频的frame
 */
- (void)setPlayList:(NSArray<DGCacheVideoModel *> *)playList
             offset:(NSUInteger)offset
       videoGravity:(AVLayerVideoGravity)videoGravity
            addViewLayer:(CALayer *)addViewLayer
            isCache:(BOOL)cache
         layerFrame:(CGRect)frame;

/**
 点击下一个播放
 */
- (void)playNextVideo;
/**
 点击上一个播放
 */
- (void)playPreviousVideo;
/**
 设置当前的播放动作
 
 @param operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGCacheVideoOperate)operate;
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay;
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGCacheVideoModel *>*)deleteList;
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的歌曲的数组
 */
- (void)addPlayList:(NSArray<DGCacheVideoModel *>*)addList;
/**
 快进或者快退
 
 @param time 要播放的那个时间点
 */
- (void)seekTime:(NSUInteger)time;
/**
 设置播放器的音量 非系统的  （不是点击手机音量加减键的音量）
 
 @param value 【0-10】大于10 等于10  小于0 等于0
 */
- (void)setVolumeValue:(CGFloat)value;

#pragma mark - 可以获得的方法
/**
 当前的播放状态，方便用户随时拿到
 
 @return 对应的播放状态
 */
- (DGCacheVideoState)currentPlayeStatus;
/**
 当前的播放的模型
 
 @return 当前的播放模型
 */
- (DGCacheVideoModel *)currentMusicModel;
/**
 当前播放歌曲的下标
 
 @return 为了你更加省心 我给你提供出来
 */
- (NSUInteger)currentIndex;
/**
 获得播放列表
 
 @return 播放列表
 */
- (NSArray<DGCacheVideoModel *> *)getPlayList;
/**
 获得当前播放器的总时间
 
 @return 时间
 */
- (CGFloat )durationTime;
/**
 获得播放器的音量
 */
- (CGFloat)getVolueValue;
````
### 整体sdk的分布
![image.png](https://upload-images.jianshu.io/upload_images/7935076-3e31ac54990be654.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
- 拿一个视频缓存的文件介绍
![image.png](https://upload-images.jianshu.io/upload_images/7935076-d9070776217ccbd1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



