//
//  DGCacheVideoPlayer.m
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGCacheVideoPlayer.h"
#import "DGVideoResourceLoader.h"
#import "DGVideoStrFileHandle.h"


#define DGPlayerStatusKey @"status"
#define DGPlayerRateKey @"rate"
#define DGPlayerLoadTimeKey @"loadedTimeRanges"
#define DGPlayerBufferEmty @"playbackBufferEmpty"
#define DGPlayerLikelyToKeepUp @"playbackLikelyToKeepUp"

@interface DGCacheVideoPlayer ()<DGVideoResourceLoaderDelegate>

/** 当前的播放的模型*/
@property (strong, nonatomic) DGCacheVideoModel *currentModel;
/** 当前的播放器状态*/
@property (assign, nonatomic) DGCacheVideoState innerPlayState;
/** 是否需要缓存*/
@property (assign, nonatomic) BOOL isNeedCache;
/** 播放器*/
@property (strong, nonatomic) AVPlayer *player;
/** 预览图层*/
@property (strong, nonatomic) AVPlayerLayer *layer;
/** 播放的item*/
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 播放的数组*/
@property (strong, nonatomic) NSMutableArray *playList;
/** 播放进度的观察者*/
@property (strong, nonatomic) id playerObserver;
/** resourceLoader*/
@property (strong, nonatomic) DGVideoResourceLoader *resourceLoader;
/** needAddView 添加layer的*/
@property (strong, nonatomic) CALayer *needAddLayer;
/** videoFrame*/
@property (assign, nonatomic) CGRect videoFrame;
/** currentVideoGravity*/
@property (assign, nonatomic) AVLayerVideoGravity currentVideoGravity;
/** 是否可以真正的播放*/
@property (assign, nonatomic) BOOL isTurePlay;


@end
@implementation DGCacheVideoPlayer
#pragma mark - 懒加载的创建
-(NSMutableArray *)playList {
    if (!_playList) {
        _playList = [[NSMutableArray alloc] init];
    }
    return _playList;
}
#pragma mark - 初始化
+(instancetype)shareInstance{
    
    static DGCacheVideoPlayer * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}
- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        self.innerPlayState = DGCacheVideoStateStop;
        if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
            [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
        }
        self.currentModel = nil;
        
    }
    return self;
}
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
         layerFrame:(CGRect)frame{
    
    [self.playList removeAllObjects];
    NSAssert(playList.count != 0, @"对不起播放数组不能为空");
    NSAssert(!(offset > playList.count - 1 || offset < 0), @"offset不合法，大于播放列表的个数或者小于0了");
    if (offset > playList.count - 1 || offset < 0 || playList.count == 0) return;
    
    [self.playList addObjectsFromArray:playList];
    self.currentModel = self.playList[offset];
    if (self.currentModel.playUrl.length == 0) return;
    self.isNeedCache = cache;
    [self removeMyObserver];
    if (self.isNeedCache == NO) { // 不需要缓存的情况
        self.needAddLayer = addViewLayer;
        self.videoFrame = frame;
        self.currentVideoGravity = videoGravity;
        
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.currentModel.playUrl]];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        [self.layer removeFromSuperlayer];
        self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.layer.frame = self.videoFrame;
        self.layer.videoGravity = self.currentVideoGravity;
        [self.needAddLayer addSublayer:self.layer];
        
        [self.player play];
        [self addMyObserver];
        
    }else{ // 需要缓存的情况 
        self.resourceLoader.downloadManager.cancel = YES;
        self.resourceLoader = nil;
        [DGVideoStrFileHandle deleleTempFile];
        // 先判断此视频缓存了没
        if ([DGVideoStrFileHandle myCacheFileIsExist:self.currentModel.playUrl]) {
            self.needAddLayer = addViewLayer;
            self.videoFrame = frame;
            self.currentVideoGravity = videoGravity;
            
            self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[DGVideoStrFileHandle getMyCacheFile:self.currentModel.playUrl]]];
            self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            
            [self.layer removeFromSuperlayer];
            self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            self.layer.frame = self.videoFrame;
            self.layer.videoGravity = self.currentVideoGravity;
            [self.needAddLayer addSublayer:self.layer];
            
            [self.player play];
            [self addMyObserver];
            
            
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:1.0];
            }
            self.innerPlayState = DGCacheVideoStatePlay;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
            return;
        }
        self.needAddLayer = addViewLayer;
        self.videoFrame = frame;
        self.currentVideoGravity = videoGravity;
        
        self.resourceLoader = [[DGVideoResourceLoader alloc] init];
        self.resourceLoader.loaderDelegate = self;
        AVURLAsset *urlAset = [AVURLAsset URLAssetWithURL:[DGVideoStrFileHandle customSchemeStr:self.currentModel.playUrl] options:nil];
        [urlAset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
        self.playerItem = [AVPlayerItem playerItemWithAsset:urlAset];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        [self.layer removeFromSuperlayer];
        self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.layer.frame = self.videoFrame;
        self.layer.videoGravity = self.currentVideoGravity;
        [self.needAddLayer addSublayer:self.layer];
        
        [self.player play];
        [self addMyObserver];
        
    }
}
/**
 点击下一个播放
 */
- (void)playNextVideo{
    
    NSAssert(self.playList.count != 0, @"没有播放列表，无法播放下一个");
    if (self.playList.count == 0) return;
    if (self.currentModel == nil) {
        self.currentModel = [self.playList firstObject];
    }
    // 播放进度要回调回去
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayerCurrentTime:duration:playProgress:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayerCurrentTime:0.0 duration:0.0 playProgress:0.0];
    }
    // 缓存的进度也要回调回去
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:0.0];
    }
    // 状态也得改了
    self.innerPlayState = DGCacheVideoStateStop;
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
    }
    DGCacheVideoModel *nextModel = [self getNextModel];
    if (nextModel.playUrl.length > 0) {
        [self removeMyObserver];
        if (self.isNeedCache) { // 需要缓存的走这里
            self.resourceLoader.downloadManager.cancel = YES;
            self.resourceLoader = nil;
            [DGVideoStrFileHandle deleleTempFile];
            // 先判断此视频缓存了没
            if ([DGVideoStrFileHandle myCacheFileIsExist:nextModel.playUrl]) {
                self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[DGVideoStrFileHandle getMyCacheFile:nextModel.playUrl]]];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                
                [self.layer removeFromSuperlayer];
                self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                self.layer.frame = self.videoFrame;
                self.layer.videoGravity = self.currentVideoGravity;
                [self.needAddLayer addSublayer:self.layer];
                
                [self.player play];
                [self addMyObserver];
                self.currentModel = nextModel;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:1.0];
                }
                self.innerPlayState = DGCacheVideoStatePlay;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
                return;
            }
            self.resourceLoader = [[DGVideoResourceLoader alloc] init];
            self.resourceLoader.loaderDelegate = self;
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[DGVideoStrFileHandle customSchemeStr:nextModel.playUrl] options:nil];
            [urlAsset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
            self.playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
            self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            
            [self.layer removeFromSuperlayer];
            self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            self.layer.frame = self.videoFrame;
            self.layer.videoGravity = self.currentVideoGravity;
            [self.needAddLayer addSublayer:self.layer];
            
            [self.player play];
            [self addMyObserver];
            self.currentModel = nextModel;
            return;
        }
        
        self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:nextModel.playUrl]];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        [self.layer removeFromSuperlayer];
        self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.layer.frame = self.videoFrame;
        self.layer.videoGravity = self.currentVideoGravity;
        [self.needAddLayer addSublayer:self.layer];
        
        [self.player play];
        [self addMyObserver];
        self.currentModel = nextModel;
        self.innerPlayState = DGCacheVideoStatePlay;
        return;
    }
}
/**
 点击上一个播放
 */
- (void)playPreviousVideo{
    
    NSAssert(self.playList.count != 0, @"对不起播放列表不能为空");
    if (self.playList.count == 0) return;
    if (self.currentModel == nil) {
        self.currentModel = [self.playList firstObject];
    }
    // 播放进度要回调回去
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayerCurrentTime:duration:playProgress:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayerCurrentTime:0.0 duration:0.0 playProgress:0.0];
    }
    // 缓存的进度也要回调回去
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:0.0];
    }
    // 状态也得改了
    self.innerPlayState = DGCacheVideoStateStop;
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
    }
    DGCacheVideoModel *previousModel = [self getPreviousModel];
    if (previousModel.playUrl.length > 0) {
        [self removeMyObserver];
        if (self.isNeedCache) { // 需要缓存的走这里
            self.resourceLoader.downloadManager.cancel = YES;
            self.resourceLoader = nil;
            [DGVideoStrFileHandle deleleTempFile];
            // 先判断此视频缓存了没
            if ([DGVideoStrFileHandle myCacheFileIsExist:previousModel.playUrl]) {
                self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:[DGVideoStrFileHandle getMyCacheFile:previousModel.playUrl]]];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                
                [self.layer removeFromSuperlayer];
                self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                self.layer.frame = self.videoFrame;
                self.layer.videoGravity = self.currentVideoGravity;
                [self.needAddLayer addSublayer:self.layer];
                
                [self.player play];
                [self addMyObserver];
                self.currentModel = previousModel;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:1.0];
                }
                self.innerPlayState = DGCacheVideoStatePlay;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
                return;
            }
            self.resourceLoader = [[DGVideoResourceLoader alloc] init];
            self.resourceLoader.loaderDelegate = self;
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[DGVideoStrFileHandle customSchemeStr:previousModel.playUrl] options:nil];
            [urlAsset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
            self.playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
            self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            
            [self.layer removeFromSuperlayer];
            self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            self.layer.frame = self.videoFrame;
            self.layer.videoGravity = self.currentVideoGravity;
            [self.needAddLayer addSublayer:self.layer];
            
            [self.player play];
            [self addMyObserver];
            self.currentModel = previousModel;
            self.innerPlayState = DGCacheVideoStatePlay;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
            return;
        }
        self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:previousModel.playUrl]];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        [self.layer removeFromSuperlayer];
        self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.layer.frame = self.videoFrame;
        self.layer.videoGravity = self.currentVideoGravity;
        [self.needAddLayer addSublayer:self.layer];
        
        [self.player play];
        [self addMyObserver];
        self.currentModel = previousModel;
        self.innerPlayState = DGCacheVideoStatePlay;
        if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
            [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
        }
        return;
    }
}
/**
 设置当前的播放动作
 
 @param operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGCacheVideoOperate)operate{
    
    if (self.currentModel.playUrl.length == 0) {
        self.innerPlayState = DGCacheVideoStateStop;
        if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
            [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
        }
        NSAssert(self.currentModel.playUrl.length != 0, @"对不起当前视频没有链接");
        return;
    }
    switch (operate) {
        case DGCacheVideoOperatePlay:
        {
            if (self.player) {
                [self.player play];
                self.innerPlayState = DGCacheVideoStatePlay;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }
        }
            break;
        case DGCacheVideoOperatePause:
        {
            if (self.player) {
                [self.player pause];
                self.innerPlayState = DGCacheVideoStatePause;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }
        }
            break;
        case DGCacheVideoOperateStop:
        {
            if (self.player) {
                [self.player pause];
                [self removeMyObserver];
                [self.playList removeAllObjects];
                self.player = nil;
                self.playerItem = nil;
                self.needAddLayer = nil;
                self.videoFrame = CGRectZero;
                self.currentModel = nil;
                self.resourceLoader.downloadManager.cancel = YES;
                self.resourceLoader = nil;
                
                self.innerPlayState = DGCacheVideoStateStop;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }
            if (self.isNeedCache) {
                self.resourceLoader.isSeek = YES;
            }
        }
            break;
        default:
            break;
    }
}
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay{
    
    [self.playList removeAllObjects];
    if (isStopPlay) {
        
        [self.player pause];
        [self removeMyObserver];
        self.currentModel = nil;
        self.playerItem = nil;
        self.player = nil;
        self.resourceLoader = nil;
        self.innerPlayState = DGCacheVideoStateStop;
        self.videoFrame = CGRectZero;
        self.needAddLayer = nil;
        if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
            [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
        }
    }
}
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGCacheVideoModel *>*)deleteList{
    
    NSAssert(deleteList.count != 0, @"要删除的数组不能为空");
    NSAssert(deleteList.count <= self.playList.count, @"要删除的数组不能大于播放列表");
    if (deleteList.count == 0 || deleteList.count > self.playList.count ) return;
    
    NSMutableArray *needDeleteArray = [NSMutableArray array];
    [deleteList enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.playList enumerateObjectsUsingBlock:^(DGCacheVideoModel * _Nonnull innerObj, NSUInteger idx, BOOL * _Nonnull innerStop) {
            if ([obj isKindOfClass:[DGCacheVideoModel class]]) {
                DGCacheVideoModel *model = (DGCacheVideoModel *)obj;
                if ([model.playId isEqualToString:innerObj.playId]) {
                    [needDeleteArray addObject:innerObj];
                    *innerStop = YES;
                }
            }
        }];
    }];
    if (needDeleteArray.count == 0) return;
    if ([needDeleteArray containsObject:self.currentModel]) {
        [self.player pause];
        self.innerPlayState = DGCacheVideoStatePause;
        if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
            [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
        }
        [self removeMyObserver];
        self.player = nil;
        self.playerItem = nil;
        self.playerObserver = nil;
        self.currentModel = nil;
    }
    [self.playList removeObjectsInArray:needDeleteArray];
    NSLog(@"播放列表的个数 : %zd -- 删除数组的个数: %zd",self.playList.count,needDeleteArray.count);
}
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的视频的数组
 */
- (void)addPlayList:(NSArray<DGCacheVideoModel *>*)addList{
    
    NSAssert(addList.count != 0, @"添加到播放列表不能为空");
    if (addList.count == 0) return;
    // 去重
    NSMutableArray *needAddArray = [NSMutableArray array];
    [needAddArray addObjectsFromArray:addList];
    NSMutableArray *temArray = [NSMutableArray array];
    [addList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[DGCacheVideoModel class]]) {
            DGCacheVideoModel *model = (DGCacheVideoModel *)obj;
            [self.playList enumerateObjectsUsingBlock:^(DGCacheVideoModel *  _Nonnull innerModel, NSUInteger idx, BOOL * _Nonnull innerStop) {
                if ([model.playId isEqualToString:innerModel.playId]) {
                    [temArray addObject:obj];
                    *innerStop = YES;
                }
            }];
        }
    }];
    if (temArray.count > 0) {
        [needAddArray removeObjectsInArray:temArray];
    }
    // 进行添加
    [self.playList addObjectsFromArray:needAddArray];
    NSLog(@"播放列表的个数 : %zd -- 需要添加的数组的个数: %zd",self.playList.count,needAddArray.count);
}
/**
 快进或者快退
 
 @param time 要播放的那个时间点
 */
- (void)seekTime:(NSUInteger)time{
    
    NSAssert(self.player != nil, @"q对不起你的播放器已经不存在了");
    if (!self.player) return;
    
    NSAssert(self.playList.count != 0, @"对不起你的当前播放列表为空或者你还没有设置播放列表");
    NSAssert(self.currentModel.playUrl.length != 0, @"当前播放视频的地址为空");
    if (self.playList.count == 0 || self.currentModel.playUrl.length == 0) return;
    
    CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
    NSAssert(time < duration, @"对不起 你的播放时间大于总时长了");
    if (time > duration) return;
    
    if (!(self.innerPlayState == DGCacheVideoStatePlay || self.innerPlayState == DGCacheVideoStatePause)) return;
    
    self.resourceLoader.isSeek = YES;
    self.innerPlayState = DGCacheVideoStateBuffer;
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
    }
    [self.player seekToTime:CMTimeMake(time, 1.0) completionHandler:^(BOOL finished) {
        if (finished) {
            self.innerPlayState = DGCacheVideoStatePlay;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
        }
    }];
    
}
/**
 设置播放器的音量 非系统也就是不是点击手机音量加减的音量
 
 @param value 【0-10】大于10 等于10  下于0 等于0
 */
- (void)setVolumeValue:(CGFloat)value{
    if(value > 10 )  {
        value = 10;
    }else if (value < 0){
        value = 0;
    }
    if (self.player) {
        self.player.volume = value;
    }
}
#pragma mark - 可以获得的方法
/**
 当前的播放状态，方便用户随时拿到
 
 @return 对应的播放状态
 */
- (DGCacheVideoState)currentPlayeStatus{
    return self.innerPlayState;
}
/**
 当前的播放的模型
 
 @return 当前的播放模型
 */
- (DGCacheVideoModel *)currentMusicModel{
    return self.currentModel;
}
/**
 当前播放视频的下标
 
 @return 为了你更加省心 我给你提供出来
 */
- (NSUInteger)currentIndex{
    if (self.currentModel && self.playList.count > 0) {
        return [self.playList indexOfObject:self.currentModel];
    }
    return 0;
}
/**
 获得播放列表
 
 @return 播放列表
 */
- (NSArray<DGCacheVideoModel *> *)getPlayList{
    return self.playList;
}
/**
 获得当前播放器的总时间
 
 @return 时间
 */
- (CGFloat )durationTime{
    if (self.playerItem) {
        CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
        if (isnan(duration)) {
            return 0;
        }
        return duration;
    }
    return 0;
}
/**
 获得播放器的音量
 */
- (CGFloat)getVolueValue{
    return self.player.volume;
}
#pragma mark - 自己方法的实现
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:DGPlayerStatusKey]) {
        switch (self.player.status) {
            case AVPlayerStatusReadyToPlay:
            {
                self.innerPlayState = DGCacheVideoStateBuffer;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }
                break;
            case AVPlayerStatusFailed:
            {
                NSDictionary *errorDic = @{
                                           NSLocalizedFailureReasonErrorKey :@"不缓存播放错误"
                                           };
                NSError * error = [NSError errorWithDomain:@"com.my.error.domaion" code:101 userInfo:errorDic];
                self.innerPlayState = DGCacheVideoStateError;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayFailed:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayFailed:error];
                }
                
            }
                break;
                
            default:
                break;
        }
        
    }else if([keyPath isEqualToString:DGPlayerRateKey]) {
        
        NSLog(@"self.player.rate : %f",self.player.rate);
        if (self.player.rate > 0) {
            self.innerPlayState = DGCacheVideoStatePlay;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
        }else{
            self.innerPlayState = DGCacheVideoStatePause;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
        }
    }else if([keyPath isEqualToString:DGPlayerLoadTimeKey]) {
        
        if (!self.isNeedCache) {
            NSLog(@"DGPlayerLoadTimeKey");
            NSArray *array = self.playerItem.loadedTimeRanges;
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
            CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
            CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
            CGFloat totalBuffer = startSeconds + durationSeconds;
            CGFloat durationTime = CMTimeGetSeconds(self.playerItem.duration);
            CGFloat bufferProgress = totalBuffer/durationTime;
            if (isnan(bufferProgress) || bufferProgress < 0) {
                bufferProgress = 0;
            }
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:bufferProgress];
            }
        }
        if (self.isTurePlay && self.player.rate == 1.0) {
            self.innerPlayState = DGCacheVideoStatePlay;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
            }
        }else {
            if (self.player.rate == 0) {
                self.innerPlayState = DGCacheVideoStatePause;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }else{
                self.innerPlayState = DGCacheVideoStateBuffer;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                }
            }
        }
    }else if([keyPath isEqualToString:DGPlayerBufferEmty]) { //没有足够的缓冲器了 说明正在缓冲中
        
        NSLog(@"没有足够的缓冲器了 说明正在缓冲中");
        if (!self.isNeedCache) {
            self.innerPlayState = DGCacheVideoStateBuffer;
            if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:DGCacheVideoStateBuffer];
            }
        }else{
            if (![DGVideoStrFileHandle myCacheFileIsExist:self.currentModel.playUrl]) {
                self.innerPlayState = DGCacheVideoStateBuffer;
                if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:DGCacheVideoStateBuffer];
                }
            }else{// 存在 判断播放还是暂停
                if (self.player.rate > 0) {
                    self.innerPlayState = DGCacheVideoStatePlay;
                    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                        [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                    }
                }else{
                    self.innerPlayState = DGCacheVideoStatePause;
                    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                        [self.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:self.innerPlayState];
                    }
                }
            }
        }
    }else if([keyPath isEqualToString:DGPlayerLikelyToKeepUp]) { // 说明缓冲器区域有足够的数据在播放，一般这种情况我们什么都不干
        
        
    }
}
/**
 获取下一个视频的坐标model
 
 @return 下一个视频有的d坐标model
 */
-(DGCacheVideoModel *)getNextModel{
    
    if (self.currentModel == nil) self.currentModel = [self.playList firstObject];
    NSInteger currentIndex = [self.playList indexOfObject:self.currentModel];
    NSInteger nextIndex = currentIndex + 1;
    if (nextIndex > self.playList.count - 1) {
        nextIndex = 0;
    }
    DGCacheVideoModel *nextModel = self.playList[nextIndex];
    return nextModel;
}
/**
 获取上一个视频的model
 
 @return 获取上一个视频的model
 */
- (DGCacheVideoModel *)getPreviousModel{
    
    if (self.currentModel == nil) self.currentModel = [self.playList firstObject];
    NSInteger currentIndex = [self.playList indexOfObject:self.currentModel];
    NSInteger previousIndex = currentIndex - 1;
    if (previousIndex < 0) {
        previousIndex = self.playList.count - 1;
    }
    DGCacheVideoModel *previousModel = self.playList[previousIndex];
    return previousModel;
}
/**
 移除观察者
 */
- (void)removeMyObserver{
    
    self.isTurePlay = NO;
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:DGPlayerStatusKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLoadTimeKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerBufferEmty];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLikelyToKeepUp];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    if (self.player) {
        [self.player removeObserver:self forKeyPath:DGPlayerRateKey];
    }
    if (self.playerObserver && self.player) {
        [self.player removeTimeObserver:self.playerObserver];
        self.playerObserver = nil;
    }
}
/**
 添加我的观察者
 */
- (void)addMyObserver{
    self.isTurePlay = NO;
    // 添加在播放器开始播放后的通知
    if (self.playerItem) {
        [self.playerItem addObserver:self forKeyPath:DGPlayerStatusKey options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerLoadTimeKey options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerBufferEmty options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:DGPlayerLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    if (self.player) {
        // 监听播放进度等等
        __weak typeof(self)weakSelf = self;
        self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            CGFloat durationTime = CMTimeGetSeconds(weakSelf.playerItem.duration);
            if (isnan(durationTime) || durationTime < 0) {
                durationTime = 0;
            }
            CGFloat currentTime = CMTimeGetSeconds(time);
            if (isnan(currentTime) || currentTime < 0) {
                currentTime = 0;
            }
            CGFloat progress = currentTime/durationTime * 1.0;
            weakSelf.isTurePlay = progress > 0;
            if (progress > 0 && weakSelf.player.rate == 1.0) {
                weakSelf.innerPlayState = DGCacheVideoStatePlay;
                if ([weakSelf.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayStatusChanged:)]) {
                    [weakSelf.DGCacheVideoDelegate DGCacheVideoPlayStatusChanged:weakSelf.innerPlayState];
                }
            }
            if ([weakSelf.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayerCurrentTime:duration:playProgress:)]) {
                [weakSelf.DGCacheVideoDelegate DGCacheVideoPlayerCurrentTime:currentTime duration:durationTime playProgress:progress];
            }
        }];
        // 播放速度
        [self.player addObserver:self forKeyPath:DGPlayerRateKey options:NSKeyValueObservingOptionNew context:nil];
    }
}
/**
 播放完成
 
 @param info 信息
 */
- (void)didFinishAction:(NSNotification *)info{
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayFinish:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayFinish:[self getNextModel]];
    }
   [self playNextVideo];
}
#pragma mark - resourceLoader 的 delegate 回调
/**
 下载进度的回调
 
 @param loader 当前对象
 @param loaderCacheProgress 下载的进度 【0 - 1】之间
 */
- (void)loader:(DGVideoResourceLoader *)loader resourceLoaderCacheProgress:(CGFloat)loaderCacheProgress{
    
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoCacheProgress:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoCacheProgress:loaderCacheProgress];
    }
}
/**
 失败了 网络等等的什么原因
 
 @param loader 当前对象
 @param error 错误信息
 */
- (void)loader:(DGVideoResourceLoader *)loader failure:(NSError *)error{
    
    if ([self.DGCacheVideoDelegate respondsToSelector:@selector(DGCacheVideoPlayFailed:)]) {
        [self.DGCacheVideoDelegate DGCacheVideoPlayFailed:error];
    }
    
}


@end
