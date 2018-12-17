//
//  DGCacheMusicController.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGCacheMusicController.h"
#import "DGCacheMusicPlayer.h"


@interface DGCacheMusicController ()<DGCacheMusicPlayerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *changeModeLable;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *durationTimeLable;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UISlider *cacheProgressSlider;
@property (weak, nonatomic) IBOutlet UILabel *playStatusLable;

@end

@implementation DGCacheMusicController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"有缓存的音频播放器";
    
    // 初始化manager
    [self createManager];
}
#pragma mark - 自己的方法实现

/**
 开始创建
 */
- (void)createManager{
    
    [DGCacheMusicPlayer shareInstance].DGCacheMusicDelegate = self;
    // 非缓存的音频播放
    
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=60078701841&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=60070101405&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6005750W085&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=60063505542&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63480215129&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63880300430&ua=Mac_sst&version=1.0
    // http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6990539Z0K8&ua=Mac_sst&version=1.0
    
    NSArray *temArray = @[@"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=60078701841&ua=Mac_sst&version=1.0",
                          @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=60070101405&ua=Mac_sst&version=1.0",
                          @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6005750W085&ua=Mac_sst&version=1.0"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 0; index < temArray.count; index ++) {
        DGCacheMusicModel *musicInfo = [[DGCacheMusicModel alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.lrcUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index];
        [infoArray addObject:musicInfo];
    }
    // 设置播放列表 开始播放
    [[DGCacheMusicPlayer shareInstance] setPlayList:infoArray offset:1 isCache:YES];
}
#pragma mark - 点击方法的实现
/**
 清空播放列列表

 @param sender 按钮
 */
- (IBAction)clearPlayList:(UIButton *)sender {
    
    [[DGCacheMusicPlayer shareInstance] clearPlayList:NO];
    
}
/**
 添加部分播放列表

 @param sender 按钮
 */
- (IBAction)addPlayList:(UIButton *)sender {

    NSArray *temArray = @[@"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63880300430&ua=Mac_sst&version=1.0",
                          @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6990539Z0K8&ua=Mac_sst&version=1.0"];
    
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGCacheMusicModel *musicInfo = [[DGCacheMusicModel alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.lrcUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index - 10];
        [infoArray addObject:musicInfo];
    }
    [[DGCacheMusicPlayer shareInstance] addPlayList:infoArray];
}

/**
 改变播放模式

 @param sender 按钮
 */
- (IBAction)changePlayMode:(UIButton *)sender {
    switch ([[DGCacheMusicPlayer shareInstance] currentPlayMode]) {
        case DGCacheMusicModeListRoop:
        {
            [[DGCacheMusicPlayer shareInstance] updateCurrentPlayMode:DGCacheMusicModeSingleRoop];
        }
            break;
        case DGCacheMusicModeSingleRoop:
        {
            [[DGCacheMusicPlayer shareInstance] updateCurrentPlayMode:DGCacheMusicModeRandom];
        }
            break;
        case DGCacheMusicModeRandom:
        {
            [[DGCacheMusicPlayer shareInstance] updateCurrentPlayMode:DGCacheMusicModeListRoop];
        }
            break;
            
        default:
            break;
    }
}
/**
 清空部分播放列表

 @param sender 按钮
 */
- (IBAction)clearSectionPlayList:(UIButton *)sender {
    
    NSArray *temArray = @[@"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63880300430&ua=Mac_sst&version=1.0",
                         @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6990539Z0K8&ua=Mac_sst&version=1.0"];
    
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGCacheMusicModel *musicInfo = [[DGCacheMusicModel alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.lrcUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index - 10];
        [infoArray addObject:musicInfo];
    }
    [[DGCacheMusicPlayer shareInstance] deletePlayList:infoArray];
    
}
/**
 滑动时间的响应 快进、快退

 @param sender 按钮
 */
- (IBAction)slidAction:(UISlider *)sender {
    NSLog(@"111111111");
    CGFloat needTime = sender.value * [[DGCacheMusicPlayer shareInstance] durationTime];
    [[DGCacheMusicPlayer shareInstance] seekTime:(NSUInteger)needTime];
    
}
/**
 上一首歌曲的点击事件

 @param sender 按钮
 */
- (IBAction)previousAction:(id)sender {
    
    [[DGCacheMusicPlayer shareInstance] playPreviousSong:YES];
}
/**
 播放 、暂停、停止的事件

 @param sender 按钮
 */
- (IBAction)playOrPauseOrStopAction:(UIButton *)sender {
    switch ([[DGCacheMusicPlayer shareInstance] currentPlayeStatus]) {
        case DGCacheMusicStatePlay:
        {
            [[DGCacheMusicPlayer shareInstance] playOperate:DGCacheMusicOperatePause];
        }
            break;
        case DGCacheMusicStatePause:
        {
            [[DGCacheMusicPlayer shareInstance] playOperate:DGCacheMusicOperatePlay];
        }
            break;
        default:
            break;
    }
    
}
/**
 下一首按钮的点击事件

 @param sender 按钮
 */
- (IBAction)nextAction:(UIButton *)sender {
    
    [[DGCacheMusicPlayer shareInstance] playNextSong:NO];
    
}
/**
 添加到8

 @param sender sender
 */
- (IBAction)addVolumeTo8:(UIButton *)sender {
    
    [[DGCacheMusicPlayer shareInstance] setVolumeValue:8];
    
}
/**
 减去到1

 @param sender sender
 */
- (IBAction)reduceVolumeTo1:(UIButton *)sender {
    
    [[DGCacheMusicPlayer shareInstance] setVolumeValue:1];
}
#pragma mark - delegate 回调
/**
 播放失败了
 
 @param error error
 */
- (void)DGCacheMusicPlayFailed:(NSError *)error{
    NSLog(@"播放失败了：%@",error);
}
/**
 一首歌曲播放完成了，会把下一首需要播放的歌曲返回来 会自动播放下一首，不要再这里播放下一首
 
 @param nextModel 下一首歌曲的模型
 */
- (void)DGCacheMusicPlayFinish:(DGCacheMusicModel *)nextModel{
    NSLog(@"一首歌曲播放完成了 %@",nextModel);
}

/**
 播放模式发生了改变了
 
 @param mode 返回来的mode
 */
- (void)DGCacheMusicPlayModeChanged:(DGCacheMusicMode )mode{
    NSLog(@"播放模式发生了改变 %zd",mode);
    switch (mode) {
        case DGCacheMusicModeListRoop:
        {
            self.changeModeLable.text = @"列表循环";
        }
            break;
        case DGCacheMusicModeSingleRoop:
        {
            self.changeModeLable.text = @"单曲循环";
           
        }
            break;
        case DGCacheMusicModeRandom:
        {
            self.changeModeLable.text = @"随机播放";
           
        }
            break;
            
        default:
            break;
    }
}

/**
 播放状态发生了改变
 
 @param status 改变后的状态
 */
- (void)DGCacheMusicPlayStatusChanged:(DGCacheMusicState)status{
    switch (status) {
        case DGCacheMusicStatePlay:
        {
            self.playStatusLable.text = @"播放呢";
        }
            break;
        case DGCacheMusicStatePause:
        {
            self.playStatusLable.text = @"暂停呢";
        }
            break;
        case DGCacheMusicStateBuffer:
        {
            self.playStatusLable.text = @"缓冲呢";
        }
            break;
        case DGCacheMusicStateStop:
        {
            self.playStatusLable.text = @"停止了";
        }
            break;
        case DGCacheMusicStateError:
        {
            self.playStatusLable.text = @"播放出错了";
        }
            break;
            
        default:
            break;
    }
}

/**
 缓存的进度
 
 @param cacheProgress 播放的缓存的进度
 */
- (void)DGCacheMusicCacheProgress:(CGFloat )cacheProgress{
    self.cacheProgressSlider.value = cacheProgress;
}


/**
 当前时间 总的时间 缓冲的进度的播放代理回调
 
 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param playProgress 播放的进度 （0-1）之间
 */
- (void)DGCacheMusicPlayerCurrentTime:(CGFloat)currentTime
                             duration:(CGFloat)durationTime
                         playProgress:(CGFloat)playProgress{
    
    self.currentTimeLable.text = [NSString stringWithFormat:@"%0.2f",currentTime];
    self.durationTimeLable.text = [NSString stringWithFormat:@"%0.2f",durationTime];
    self.progressSlider.value = playProgress;
    
}
- (void)dealloc
{
    [[DGCacheMusicPlayer shareInstance] playOperate:DGCacheMusicOperateStop];
}
@end
