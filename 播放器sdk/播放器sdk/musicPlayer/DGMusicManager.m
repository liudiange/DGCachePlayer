//
//  DGMusicManager.m
//  播放器sdk
//
//  Created by apple on 2018/11/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGMusicManager.h"

#define DGPlayerStatusKey @"status"
#define DGPlayerRate @"rate"
#define DGPlayerLoadTimeKey @"loadedTimeRanges"
#define DGPlayerBufferEmty @"playbackBufferEmpty"
#define DGPlayerLikelyToKeepUp @"playbackLikelyToKeepUp"

@interface DGMusicManager ()

/** 播放器*/
@property (strong, nonatomic)  AVPlayer *player;
/** 当前的播放模式*/
@property (assign, nonatomic) DGPlayMode innerCurrentPlayMode;
/** 当前的播放状态 */
@property (assign, nonatomic) DGPlayerStatus innerCurrentPlayStatus;
/** 当前的音乐的播放信息*/
@property (strong, nonatomic) DGMusicInfo *innerCurrentMusicInfo;
/** AVPlayerItem*/
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 当前的播放列表*/
@property (strong, nonatomic) NSMutableArray *playList;
/** 进度观察的返回者*/
@property (strong, nonatomic) id progressObserver;
/** 是否可以真正的播放*/
@property (assign, nonatomic) BOOL isTurePlay;

@end

@implementation DGMusicManager
-(NSMutableArray *)playList {
    if (!_playList) {
        _playList = [[NSMutableArray alloc] init];
    }
    return _playList;
}
#pragma mark - 初始化的方法，以及相关的设置等等
+(instancetype)shareInstance{
    static id _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}
-(instancetype)init{
    self = [super init];
    if (self) {
        self.innerCurrentPlayMode = DGPlayModeListRoop;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeMode:)]) {
            [self.DGDelegate DGPlayerChangeMode:DGPlayModeListRoop];
        }
        self.innerCurrentPlayStatus = DGPlayerStatusStop;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
        }
    }
    return self;
}
/**
 设置播放列表并且开始播放，此时的播放模式为列表循环
 
 @param listArray 播放的数组
 @param offset 从第几个开始
 */
- (void)setPlayList:(NSArray<DGMusicInfo *> *)listArray offset:(NSUInteger)offset{
    
    [self.playList removeAllObjects];
    [self.playList addObjectsFromArray:listArray];

    NSAssert(!(offset < 0 || offset > self.playList.count - 1), @"歌曲播放位置不合法");
    NSAssert(!(self.playList.count <= 0), @"播放数组不能为空");
    if ((offset < 0 || offset > self.playList.count - 1) || self.playList.count == 0){ return;}
    
    DGMusicInfo *musicInfo = self.playList[offset];
    self.innerCurrentMusicInfo = musicInfo;
    if (musicInfo.listenUrl.length == 0) {return;}
    
    if (!self.player) {
        NSURL *url = [NSURL URLWithString:musicInfo.listenUrl];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.playerItem = item;
        self.player = player;
        [self.player play];
        [self addMyObserver];
    }else{
        [self removeMyObserver];
        NSURL *url = [NSURL URLWithString:musicInfo.listenUrl];
        self.playerItem = [AVPlayerItem playerItemWithURL:url];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player play];
        [self addMyObserver];
        
    }
}
#pragma mark - 观察者的监听、代理的返回等等
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:DGPlayerStatusKey]) { // 监听播放器的状态
        
        NSLog(@"当前的播放状态 %zd",self.playerItem.status);
        
        switch (self.playerItem.status) {
            case AVPlayerStatusReadyToPlay:
            {
                self.innerCurrentPlayStatus = DGPlayerStatusBuffer;
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
                }
            }
                break;
            case AVPlayerStatusFailed:
            {
                self.innerCurrentPlayStatus = DGPlayerStatusStop;
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
                }
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerPlayFailure:)]) {
                    [self.DGDelegate DGPlayerPlayFailure:AVPlayerStatusFailed];
                }
            }
                break;
            case AVPlayerStatusUnknown:
            {
                self.innerCurrentPlayStatus = DGPlayerStatusPause;
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPause];
                }
            }
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:DGPlayerLoadTimeKey]){ //监听播放器的缓冲情况

        NSArray *array = self.playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        CGFloat totalBuffer = startSeconds + durationSeconds;
        CGFloat durationTime = CMTimeGetSeconds(self.playerItem.duration);
        
        CGFloat bufferProgress = totalBuffer/durationTime;
        if (isnan(bufferProgress)) {
            bufferProgress = 0;
        }
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerBufferProgress:)]) {
            [self.DGDelegate DGPlayerBufferProgress:bufferProgress];
        }
        
        if (self.isTurePlay && self.player.rate == 1) {
            NSLog(@"进入了 ---------");
            self.innerCurrentPlayStatus = DGPlayerStatusPlay;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
            }
        }else{
            if (self.player.rate == 0) {
                self.innerCurrentPlayStatus = DGPlayerStatusPause;
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
                }
            }else{
                self.innerCurrentPlayStatus = DGPlayerStatusBuffer;
                if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
                }
            }
        }
    }else if ([keyPath isEqualToString:DGPlayerRate]){ // 播放速度 0 就是暂停了
        if (self.player.rate == 0) {
            self.innerCurrentPlayStatus = DGPlayerStatusPause;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPause];
            }
        }else{
            self.innerCurrentPlayStatus = DGPlayerStatusPlay;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
            }
        }
    }else if([keyPath isEqualToString:DGPlayerBufferEmty]){ //没有足够的缓冲区了，监听播放播放器在缓冲区的状态
        NSLog(@"没有足够的缓冲区了，监听播放播放器在缓冲区的状态");
        self.innerCurrentPlayStatus = DGPlayerStatusBuffer;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusBuffer];
        }
    }else if([keyPath isEqualToString:DGPlayerLikelyToKeepUp]){ // 说明缓冲区有足够的数据可以播放，一般这种情况我们什么都不干
        
    }
}
/**
 一首歌播放完成的通知

 @param info 通知
 */
- (void)didFinishAction:(NSNotification *)info{
    // 开始播放下一首
    [self playNextSong:NO];
    // 把下一首歌曲回调回去
    DGMusicInfo *nextMusicInfo = self.playList[[self nextIndex]];
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerFinished:)]) {
        [self.DGDelegate DGPlayerFinished:nextMusicInfo];
    }
    
}
/**
 下一手歌曲的下标

 @return 下一首歌曲下标
 */
-(NSUInteger)nextIndex{
    
    if (self.innerCurrentMusicInfo == nil) return 0;
    
    NSUInteger index = [self.playList indexOfObject:self.currentMusicInfo];
    NSUInteger nextIndex = index + 1;
    if (nextIndex == self.playList.count) {
        nextIndex = 0;
    }
    return nextIndex;
}
/**
 上一首歌曲的下标

 @return 上一首歌曲的下标签
 */
-(NSUInteger)previousIndex{
    
    if (self.innerCurrentMusicInfo == nil) return 0;

    NSUInteger index = [self.playList indexOfObject:self.currentMusicInfo];
    NSUInteger previousIndex = index - 1;
    if (previousIndex == -1) {
        previousIndex = self.playList.count - 1;
    }
    return previousIndex;
}

/**
 移除全部的通知
 */
-(void)removeMyObserver{
    
    self.isTurePlay = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:DGPlayerStatusKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLoadTimeKey];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerLikelyToKeepUp];
        [self.playerItem removeObserver:self forKeyPath:DGPlayerBufferEmty];
    }
    if (self.player) {
        [self.player removeObserver:self forKeyPath:DGPlayerRate];
    }
    if (self.progressObserver && self.player) {
        [self.player removeTimeObserver:self.progressObserver];
        self.progressObserver = nil;
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
    // 监听播放速度
    if (self.player) {
        // 监听当前的播放进度
        __weak typeof(self)weakSelf = self;
        self.progressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            CGFloat duationTime = CMTimeGetSeconds(weakSelf.playerItem.duration);
            CGFloat currentTime = CMTimeGetSeconds(time);
            if (currentTime < 0 ) {
                currentTime = 0;
            }else if (duationTime < 0){
                duationTime = 0;
            }else if (isnan(duationTime)){
                duationTime = 0;
            }
            CGFloat progress = currentTime/duationTime * 1.0;
            weakSelf.isTurePlay = progress > 0;
            if (weakSelf.player.rate == 1.0 && progress > 0) {
                weakSelf.innerCurrentPlayStatus = DGPlayerStatusPlay;
                if ([weakSelf.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                    [weakSelf.DGDelegate DGPlayerChangeStatus:weakSelf.innerCurrentPlayStatus];
                }
            }
            if ([weakSelf.DGDelegate respondsToSelector:@selector(DGPlayerCurrentTime:duration:playProgress:)]) {
                [weakSelf.DGDelegate DGPlayerCurrentTime:currentTime duration:duationTime playProgress:progress];
            }
        }];
        // 添加观察者
        [self.player addObserver:self forKeyPath:DGPlayerRate options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
}

#pragma mark - 需要返回和设置的方法
/**
 当前的播放状态，方便用户随时拿到
 
 @return 对应的播放状态
 */
- (DGPlayerStatus)currentPlayeStatus{
    
    return self.innerCurrentPlayStatus;
}
/**
 获取到当前的播放模式
 
 @return 对应的播放模式
 */
- (DGPlayMode)currentPlayMode{
    
    return self.innerCurrentPlayMode;
}
/**
 当前的播放的模型
 
 @return 当前的播放模型
 */
- (DGMusicInfo *)currentMusicInfo{
    
    return self.innerCurrentMusicInfo;
}
/**
 当前播放e歌曲的下标
 
 @return 为了你更加省心 我给你提供出来
 */
- (NSUInteger)currentIndex{
   return [self.playList indexOfObject:self.innerCurrentMusicInfo];
    
}
/**
 获得当前播放器的总时间
 
 @return 时间
 */
- (CGFloat )durationTime{
    if (self.player == nil) {
        return 0;
    }
   return CMTimeGetSeconds(self.playerItem.duration);
}
/**
 获得播放器的音量
 */
- (CGFloat)getVolueValue{
    return self.player.volume;
}
/**
 获得播放列表
 
 @return 播放列表
 */
- (NSArray<DGMusicInfo *> *)getPlayList{
    return self.playList;
}
#pragma mark - 自己实现的方法
/**
 点击下一首播放
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playNextSong:(BOOL)isNeedSingRoopJump{
    
    NSAssert(self.playList.count != 0, @"你还没有设置播放列表");
    if (self.playList.count == 0) {
        self.innerCurrentPlayStatus = DGPlayerStatusStop;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
        }
        NSAssert(self.playList.count != 0, @"你还没有设置播放列表");
        return;
    }
    if (self.innerCurrentMusicInfo.listenUrl.length == 0) {
        self.innerCurrentMusicInfo = [self.playList firstObject];
    }
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerBufferProgress:)]) {
        [self.DGDelegate DGPlayerBufferProgress:0.0];
    }
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerCurrentTime:duration:playProgress:)]) {
        [self.DGDelegate DGPlayerCurrentTime:0.0 duration:0.0 playProgress:0.0];
    }
    self.innerCurrentPlayStatus = DGPlayerPlayOperateStop;
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
        [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
    }
    
    // 播放当前单曲循环的歌曲
    if (self.innerCurrentPlayMode == DGPlayModeSingleRoop && isNeedSingRoopJump == NO) {
        [self removeMyObserver];
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.innerCurrentMusicInfo.listenUrl]];
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        [self.player play];
        [self addMyObserver];
        self.innerCurrentPlayStatus = DGPlayerStatusPlay;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
        }
        return;
    }
    // 随机播放
    if (self.innerCurrentPlayMode == DGPlayModeRandPlay) {
        NSUInteger randIndex = arc4random_uniform((int32_t)self.playList.count);
        DGMusicInfo *info = self.playList[randIndex];
        if (info.listenUrl.length == 0) {return;}
        
        [self removeMyObserver];
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:info.listenUrl]];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player play];
        self.innerCurrentMusicInfo = info;
        [self addMyObserver];
        
        self.innerCurrentPlayStatus = DGPlayerStatusPlay;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
        }
        return;
    }
    NSUInteger nextIndex = [self nextIndex];
    DGMusicInfo *nextMusicInfo = self.playList[nextIndex];
    if (nextMusicInfo.listenUrl.length == 0) {return;}
    
    [self removeMyObserver];
    self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:nextMusicInfo.listenUrl]];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.player play];
    self.innerCurrentMusicInfo = nextMusicInfo;
    [self addMyObserver];
    
    self.innerCurrentPlayStatus = DGPlayerStatusPlay;
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
        [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
    }
}
/**
 播放上一首歌曲
 
 @param isNeedSingRoopJump 当单曲循环的时候是否需要跳转到下一首（只有在单曲循环的情况下才有用）
 如果传递是yes的情况下，那么单曲循环就会跳转到下一首循环播放
 */
- (void)playPreviousSong:(BOOL)isNeedSingRoopJump{
    
    if (self.playList.count == 0) {
        self.innerCurrentPlayStatus = DGPlayerStatusStop;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
        }
        NSAssert(self.playList.count != 0, @"你还没有设置播放列表");
        return;
    }
    if (self.innerCurrentMusicInfo.listenUrl.length == 0) {
        self.innerCurrentMusicInfo = [self.playList firstObject];
    }
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerBufferProgress:)]) {
        [self.DGDelegate DGPlayerBufferProgress:0.0];
    }
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerCurrentTime:duration:playProgress:)]) {
        [self.DGDelegate DGPlayerCurrentTime:0.0 duration:0.0 playProgress:0.0];
    }
    self.innerCurrentPlayStatus = DGPlayerPlayOperateStop;
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
        [self.DGDelegate DGPlayerChangeStatus:self.innerCurrentPlayStatus];
    }
    
    // 播放当前单曲循环的歌曲
    if (self.innerCurrentPlayMode == DGPlayModeSingleRoop && isNeedSingRoopJump == NO) {
        
        [self removeMyObserver];
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.innerCurrentMusicInfo.listenUrl]];
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        [self.player play];
        [self addMyObserver];
        
        self.innerCurrentPlayStatus = DGPlayerStatusPlay;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
        }
        return;
    }
    // 随机播放
    if (self.innerCurrentPlayMode == DGPlayModeRandPlay) {
        NSUInteger randIndex = arc4random_uniform((int32_t)self.playList.count);
        DGMusicInfo *info = self.playList[randIndex];
        if (info.listenUrl.length == 0) return;
        
        [self removeMyObserver];
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:info.listenUrl]];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.player play];
        self.innerCurrentMusicInfo = info;
        [self addMyObserver];
        
        self.innerCurrentPlayStatus = DGPlayerStatusPlay;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
        }
        return;
    }
    NSUInteger previousIndex = [self previousIndex];
    DGMusicInfo *previousMusicInfo = self.playList[previousIndex];
    if (previousMusicInfo.listenUrl.length == 0) return;
    
    [self removeMyObserver];
    self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:previousMusicInfo.listenUrl]];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.player play];
    self.innerCurrentMusicInfo = previousMusicInfo;
    [self addMyObserver];
    
    self.innerCurrentPlayStatus = DGPlayerStatusPlay;
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
        [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
    }
}
/**
 设置当前的播放动作
 
 @param Operate 动作： 播放、暂停、停止
 停止：清空播放列表，如果在要播放需要重新设置播放列表
 */
- (void)playOperate:(DGPlayerPlayOperate)Operate{
    
    NSAssert(!(self.innerCurrentMusicInfo.listenUrl.length == 0 || self.playList.count == 0), @"播放列表为空 或者没有播放链接");
    if (self.innerCurrentMusicInfo.listenUrl.length == 0 || self.playList.count == 0) return;
    
    switch (Operate) {
        
        case DGPlayerPlayOperatePlay:
        {
            if (self.innerCurrentMusicInfo.listenUrl.length == 0 || self.player == nil || self.playList.count == 0) {return;}
            [self.player play];
            self.innerCurrentPlayStatus = DGPlayerStatusPlay;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
            }
            
        }
            break;
        case DGPlayerPlayOperatePause:
        {
            if (self.innerCurrentMusicInfo.listenUrl.length == 0 || self.player == nil || self.playList.count == 0) {return;}
            [self.player pause];
            self.innerCurrentPlayStatus = DGPlayerStatusPause;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPause];
            }
        }
            break;
        
        case DGPlayerPlayOperateStop:
        {
            if (self.innerCurrentMusicInfo.listenUrl.length == 0 || self.player == nil || self.playList.count == 0) {return;}
            
            [self.player pause];
            [self removeMyObserver];
            [self.playList removeAllObjects];
            self.innerCurrentMusicInfo = nil;
            self.player = nil;
            self.playerItem = nil;
            self.innerCurrentPlayStatus = DGPlayerStatusStop;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
            }
        }
            break;
        default:
            break;
    }
    
}
/**
 设置当前的播放模式
 
 @param mode 自己要设置的模式
 */
- (void)updateCurrentPlayMode:(DGPlayMode)mode{
    
    self.innerCurrentPlayMode = mode;
    if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeMode:)]) {
        [self.DGDelegate DGPlayerChangeMode:mode];
    }
}
/**
 清空播放列表
 
 @param isStopPlay YES:停止播放 NO:不停止播放
 */
- (void)clearPlayList:(BOOL)isStopPlay{
    
    if (isStopPlay) {
        [self.player pause];
        self.innerCurrentPlayStatus = DGPlayerStatusStop;
        if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
            [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusStop];
        }
        [self removeMyObserver];
        self.player = nil;
        self.playerItem = nil;
        self.innerCurrentMusicInfo = nil;
    }
    [self.playList removeAllObjects];
}
/**
 删除一个播放列表
 
 @param deleteList 要删除的播放列表
 */
- (void)deletePlayList:(NSArray<DGMusicInfo *>*)deleteList{
    
    NSAssert(deleteList.count != 0, @"对不起，删除的数组不能为空");
    if (deleteList.count == 0) {return;}
    
    NSMutableArray *temAttay = [NSMutableArray array];
    __block BOOL isContainCurrentInfo = NO;
    for (NSInteger index = 0; index < deleteList.count; index ++) {
        DGMusicInfo *info = deleteList[index];
        if (info.musicId.length && [info isMemberOfClass:[DGMusicInfo class]]) {
            [self.playList enumerateObjectsUsingBlock:^(DGMusicInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.musicId isEqualToString:info.musicId]) {
                    [temAttay addObject:obj];
                    if ([info.musicId isEqualToString:self.innerCurrentMusicInfo.musicId]) {
                        isContainCurrentInfo = YES;
                    }
                    *stop = YES;
                }
            }];
        }
    }
    NSLog(@"清除的数组个数：%zd",temAttay.count);
    if (temAttay.count == 0) {return;}
    if (isContainCurrentInfo) {
        [self.player pause];
        [self removeMyObserver];
        
        self.playerItem = nil;
        self.progressObserver = nil;
        self.player = nil;
    }
    // 删除数组
    [self.playList removeObjectsInArray:temAttay];
}
/**
 添加一个新的歌单到播放列表
 
 @param addList 新的歌曲的数组
 */
- (void)addPlayList:(NSArray<DGMusicInfo *>*)addList{
    
    NSAssert(addList.count != 0, @"添加的数组不能为空");
    if (addList.count == 0) {return;}
    
    NSMutableArray *temArray = [NSMutableArray array];
    for (NSInteger index = 0; index < addList.count; index ++) {
       DGMusicInfo *info = addList[index];
        if ([info isMemberOfClass:[DGMusicInfo class]]) {
            __block BOOL isFlag = NO;
            [self.playList enumerateObjectsUsingBlock:^(DGMusicInfo  *_Nonnull obj, NSUInteger idx, BOOL * stop) {
                if ([obj.musicId isEqualToString:info.musicId]) {
                    isFlag = YES;
                    *stop = YES;
                }
                
            }];
            if (isFlag == NO) {
             [temArray addObject:info];
            }
        }
    }
    NSLog(@"temArray.count : %zd",temArray.count);
    if (temArray.count == 0) return;
    [self.playList addObjectsFromArray:temArray];
}
/**
 快进或者快退
 
 @param time 要播放的那个时间点
 */
- (void)seekTime:(NSUInteger)time{
    
    NSAssert(self.player != nil, @"q对不起你的播放器已经不存在了");
    if (!self.player) return;
    
    NSAssert(self.playList.count != 0, @"对不起你的当前播放列表为空或者你还没有设置播放列表");
    NSAssert(self.innerCurrentMusicInfo.listenUrl.length != 0, @"当前播放歌曲的地址为空");
    
    if (self.playList.count == 0 || self.innerCurrentMusicInfo.listenUrl.length == 0) return;
    CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
    NSAssert(time < duration, @"对不起 你的播放时间大于总时长了");
    if (time > duration) return;
    if (!(self.innerCurrentPlayStatus == DGPlayerStatusPlay || self.innerCurrentPlayStatus == DGPlayerStatusPause)) return;
    
    [self.player seekToTime:CMTimeMake(time, 1.0) completionHandler:^(BOOL finished) {
        if (finished) {
            self.innerCurrentPlayStatus = DGPlayerStatusPlay;
            if ([self.DGDelegate respondsToSelector:@selector(DGPlayerChangeStatus:)]) {
                [self.DGDelegate DGPlayerChangeStatus:DGPlayerStatusPlay];
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

@end
