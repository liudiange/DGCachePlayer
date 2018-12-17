//
//  ViewController.m
//  播放器sdk
//
//  Created by apple on 2018/11/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "ViewController.h"
#import "DGMusicManager.h"
#import "DGCacheMusicController.h"
#import "DGCacheVideoController.h"
#import "DGVideoPlayerController.h"


@interface ViewController ()<DGMusicManagerDelegate>

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UISlider *bufferProgressSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *durationTimeLable;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *playStatusLable;



@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"无缓存的音频播放器";
    
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
        DGMusicInfo *musicInfo = [[DGMusicInfo alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.listenUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index];
        [infoArray addObject:musicInfo];
    }
    
    [DGMusicManager shareInstance].DGDelegate = self;
//    [[DGMusicManager shareInstance] setPlayList:infoArray offset:0];
    
}
#pragma mark - delegate 回调
/**
 播放失败的回调
 @param status 播放状态
 AVPlayerStatusUnknown： 未知
 AVPlayerStatusReadyToPlay： 可以播放
 AVPlayerStatusFailed ：播放失败
 */
- (void)DGPlayerPlayFailure:(AVPlayerStatus)status{
    
    NSLog(@"播放失败了，播放的状态是 %zd",status);
}
/**
 播放器播放的缓冲的进度
 
 @param progress 进度。范围为：0-1
 */
- (void)DGPlayerBufferProgress:(CGFloat)progress{
    
    self.bufferProgressSlider.value = progress;
}
/**
 当模式发生了改变回调
 
 @param playMode 此时此刻的模式
 */
- (void)DGPlayerChangeMode:(DGPlayMode)playMode{
    
    NSLog(@"播放模式发生了改变 %zd",playMode);
    switch (playMode) {
        case DGPlayModeListRoop:
        {
            [self.modeButton setTitle:@"列表循环" forState:UIControlStateNormal];
        }
            break;
        case DGPlayModeSingleRoop:
        {
            [self.modeButton setTitle:@"单曲循环" forState:UIControlStateNormal];
        }
            break;
        case DGPlayModeRandPlay:
        {
            [self.modeButton setTitle:@"随机播放" forState:UIControlStateNormal];
        }
            break;
            
        default:
            break;
    }
}
/**
 当播放状态发生了改变回调
 
 @param status 播放的状态
 */
- (void)DGPlayerChangeStatus:(DGPlayerStatus)status{
    switch (status) {
        case DGPlayerStatusPlay:
        {
            self.playStatusLable.text = @"播放呢";
        }
            break;
        case DGPlayerStatusPause:
        {
            self.playStatusLable.text = @"暂停呢";
        }
            break;
        case DGPlayerStatusBuffer:
        {
            self.playStatusLable.text = @"缓冲呢";
        }
            break;
        case DGPlayerStatusStop:
        {
            self.playStatusLable.text = @"停止了";
        }
            break;
            
        default:
            break;
    }
}
/**
 一首歌曲播放完成的delegate，自动会播放下一首，不要再这里边播放下一首歌曲
 
 @param nextInfo 下一首的musicInfo
 */
- (void)DGPlayerFinished:(DGMusicInfo *)nextInfo{
    
    NSLog(@"一首歌曲播放完成了");
    
}
/**
 代理回调当前的时间、总时间、播放进度
 
 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param progress 播放进度
 */
- (void)DGPlayerCurrentTime:(CGFloat)currentTime
                   duration:(CGFloat)durationTime
               playProgress:(CGFloat)progress{
    
    self.currentTimeLable.text = [NSString stringWithFormat:@"%0.2f",currentTime];
    self.durationTimeLable.text = [NSString stringWithFormat:@"%0.2f",durationTime];
    self.progressSlider.value = progress;
}
#pragma mark - 自己实现的方法的响应
/**
 清空播放列表

 @param sender button
 */
- (IBAction)clearPlayList:(UIButton *)sender {
    
    [[DGMusicManager shareInstance] clearPlayList:YES];
}
/**
 添加播放列表的数组到播放数组

 @param sender 播放数组
 */
- (IBAction)addSongArrayToPlayList:(UIButton *)sender {
    
    NSArray *temArray = @[@"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63880300430&ua=Mac_sst&version=1.0",
                          @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6990539Z0K8&ua=Mac_sst&version=1.0"];
    
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGMusicInfo *musicInfo = [[DGMusicInfo alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.listenUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index - 10];
        [infoArray addObject:musicInfo];
    }
    [[DGMusicManager shareInstance] addPlayList:infoArray];
}

/**
 清除部分播放列表

 @param sender 按钮
 */
- (IBAction)clearSectionList:(UIButton *)sender {
    
    NSArray *temArray = @[@"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=63880300430&ua=Mac_sst&version=1.0",
                          @"http://218.200.160.29/rdp2/test/mac/listen.do?contentid=6990539Z0K8&ua=Mac_sst&version=1.0"];
    
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGMusicInfo *musicInfo = [[DGMusicInfo alloc] init];
        musicInfo.musicId = [NSString stringWithFormat:@"%zd",index];
        musicInfo.musicName = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.singerName = [NSString stringWithFormat:@"singer%zd",index];
        musicInfo.albumName = [NSString stringWithFormat:@"album%zd",index];
        musicInfo.listenUrl = [NSString stringWithFormat:@"aa%zd",index];
        musicInfo.listenUrl = temArray[index - 10];
        [infoArray addObject:musicInfo];
    }
    [[DGMusicManager shareInstance] deletePlayList:infoArray];
    
}
/**
 改变播放的模式

 @param sender 按钮
 */
- (IBAction)changePlayModeButton:(UIButton *)sender {
    
    switch ([[DGMusicManager shareInstance] currentPlayMode]) {
        case DGPlayModeListRoop:
        {
            [[DGMusicManager shareInstance] updateCurrentPlayMode:DGPlayModeSingleRoop];
        }
            break;
        case DGPlayModeSingleRoop:
        {
            [[DGMusicManager shareInstance] updateCurrentPlayMode:DGPlayModeRandPlay];
        }
            break;
        case DGPlayModeRandPlay:
        {
            [[DGMusicManager shareInstance] updateCurrentPlayMode:DGPlayModeListRoop];
        }
            break;
            
        default:
            break;
    }
}
/**
 播放和暂停的事件

 @param sender 按钮的点击事件
 */
- (IBAction)playOrPauseAction:(UIButton *)sender {
    switch ([[DGMusicManager shareInstance] currentPlayeStatus]) {
        case DGPlayerStatusPlay:
        {
            [[DGMusicManager shareInstance] playOperate:DGPlayerPlayOperatePause];
        }
            break;
        case DGPlayerStatusPause:
        {
            [[DGMusicManager shareInstance] playOperate:DGPlayerPlayOperatePlay];
        }
            break;
        case DGPlayerStatusBuffer:
        {
            [[DGMusicManager shareInstance] playOperate:DGPlayerPlayOperatePlay];
        }
            break;
        default:
            break;
    }
}

/**
 播放上一首歌曲

 @param sender 按钮
 */
- (IBAction)previousButtonAction:(UIButton *)sender {
    
    [[DGMusicManager shareInstance] playPreviousSong:YES];
}

/**
 下一首歌曲

 @param sender button
 */
- (IBAction)nextButtonAction:(UIButton *)sender {
    
    [[DGMusicManager shareInstance] playNextSong:NO];
}
/**
 滑动进度调播放到摸个时间段

 @param sender slider
 */
- (IBAction)seekToTimeSlider:(UISlider *)sender {
    
    CGFloat needTime = sender.value * [[DGMusicManager shareInstance] durationTime];
    [[DGMusicManager shareInstance] seekTime:(NSUInteger)needTime];
}
#pragma mark - 点击进入下一页的事件
/**
 点击进入有缓存的音频控制器

 @param sender 按钮
 */
- (IBAction)clickCacheMusic:(UIButton *)sender {
    
    DGCacheMusicController *cacheMusicVc = [[DGCacheMusicController alloc] init];
    [self.navigationController pushViewController:cacheMusicVc animated:YES];
    
}
/**
 点击进入有缓存的视频播放器

 @param sender 按钮
 */
- (IBAction)clickCacheVideo:(UIButton *)sender {
    DGCacheVideoController *cacheVideoVc = [[DGCacheVideoController alloc] init];
    [self.navigationController pushViewController:cacheVideoVc animated:YES];
    
}

/**
 点击无缓存的video

 @param sender 按钮
 */
- (IBAction)clickNoCacheVideo:(UIButton *)sender {
    
    DGVideoPlayerController *VideoVc = [[DGVideoPlayerController alloc] init];
    [self.navigationController pushViewController:VideoVc animated:YES];
}









@end
