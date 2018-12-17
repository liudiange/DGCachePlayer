//
//  DGCacheVideoController.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//
#import "DGCacheVideoController.h"
#import "DGCacheVideoPlayer.h"


@interface DGCacheVideoController ()<DGCacheVideoPlayerDelegate>

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UISlider *cacheSlider;
@property (weak, nonatomic) IBOutlet UILabel *playStatusLable;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *durationTimeLable;


@end

@implementation DGCacheVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"有缓存的视频播放器";
    [self creatVideoManager];
    
}
#pragma mark - 自己的方法的实现
/**
 创建videoManager
 */
- (void)creatVideoManager{
    
//    NSArray *temArray = @[@"https://weiboshipin.cmvideo.cn/depository_sp/fsv/trans/2018/11/25/649656072/25/5bfaa1eb6633d9b67e3369fe.mp4"];
//    NSArray *temArray = @[@"http://wvideo.spriteapp.cn/video/2018/1210/89d510bc-fc6f-11e8-a53c-0026b938a8ac_wpd.mp4"];
    
    NSArray *temArray = @[@"https://weiboshipin.cmvideo.cn/depository_sp/fsv/trans/2018/11/25/649656072/25/5bfaa1eb6633d9b67e3369fe.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 0; index < temArray.count; index ++) {
        DGCacheVideoModel *videoInfo = [[DGCacheVideoModel alloc] init];
        videoInfo.playId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index];
        [infoArray addObject:videoInfo];
    }
    [DGCacheVideoPlayer shareInstance].DGCacheVideoDelegate = self;
    [[DGCacheVideoPlayer shareInstance] setPlayList:infoArray offset:0 videoGravity:AVLayerVideoGravityResizeAspect addViewLayer:self.view.layer isCache:YES layerFrame:CGRectMake(0, 64, self.view.frame.size.width, 300)];
}
#pragma mark - 方法的实现
/**
 清除所有

 @param sender sender
 */
- (IBAction)clearAllPlayList:(UIButton *)sender {
    
    [[DGCacheVideoPlayer shareInstance] clearPlayList:YES];
}

/**
 清除部分

 @param sender sender
 */
- (IBAction)clearSectionPlayList:(id)sender {
    
    NSArray *temArray = @[@"http://wvideo.spriteapp.cn/video/2018/1210/89d510bc-fc6f-11e8-a53c-0026b938a8ac_wpd.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGCacheVideoModel *videoInfo = [[DGCacheVideoModel alloc] init];
        videoInfo.playId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index - 10];
        [infoArray addObject:videoInfo];
    }
    [[DGCacheVideoPlayer shareInstance] deletePlayList:infoArray];
}
/**
 添加到播放列表

 @param sender sender
 */
- (IBAction)addPlayList:(id)sender {
    
    NSArray *temArray = @[@"http://wvideo.spriteapp.cn/video/2018/1210/89d510bc-fc6f-11e8-a53c-0026b938a8ac_wpd.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGCacheVideoModel *videoInfo = [[DGCacheVideoModel alloc] init];
        videoInfo.playId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index - 10];
        [infoArray addObject:videoInfo];
    }
    [[DGCacheVideoPlayer shareInstance] addPlayList:infoArray];
}

/**
 增大音量到8

 @param sender sender
 */
- (IBAction)addVolumeTo8:(id)sender {
    [[DGCacheVideoPlayer shareInstance] setVolumeValue:8.0];
}
/**
 减少音量到1

 @param sender sender
 */
- (IBAction)reduceVolumeTo1:(id)sender {
     [[DGCacheVideoPlayer shareInstance] setVolumeValue:1.0];
}

/**
 开始拖动

 @param sender sender
 */
- (IBAction)seekAction:(UISlider *)sender {
    
    CGFloat needTime = sender.value * [[DGCacheVideoPlayer shareInstance] durationTime];
    [[DGCacheVideoPlayer shareInstance] seekTime:(NSUInteger)needTime];
    
}
/**
 播放上一个视频

 @param sender sender
 */
- (IBAction)previousAction:(id)sender {
    [[DGCacheVideoPlayer shareInstance] playPreviousVideo];
}
/**
 播放下一个视频

 @param sender sender
 */
- (IBAction)nextAction:(id)sender {
    [[DGCacheVideoPlayer shareInstance] playNextVideo];
}
/**
 播放或者暂停

 @param sender sender
 */
- (IBAction)playOrPause:(id)sender {
    
    NSLog(@"点击了播放或者暂停的按钮");
    switch ([[DGCacheVideoPlayer shareInstance] currentPlayeStatus]) {
        case DGCacheVideoStatePlay:
        {
            [[DGCacheVideoPlayer shareInstance] playOperate:DGCacheVideoOperatePause];
        }
            break;
        case DGCacheVideoStatePause:
        {
            [[DGCacheVideoPlayer shareInstance] playOperate:DGCacheVideoOperatePlay];
        }
            break;
        case DGCacheVideoStateBuffer:
        {
            [[DGCacheVideoPlayer shareInstance] playOperate:DGCacheVideoOperatePlay];
        }
            break;
        default:
        {
            [[DGCacheVideoPlayer shareInstance] playOperate:DGCacheVideoOperatePause];
        }
            break;
    }
    
    
}
#pragma mark - 代理的回调
/**
 播放失败了
 
 @param error error
 */
- (void)DGCacheVideoPlayFailed:(NSError *)error{
    NSLog(@"error --- %@",error);
    
}
/**
 一首歌曲播放完成了，会把下一首需要播放的歌曲返回来 会自动播放下一首，不要再这里播放下一首
 
 @param nextModel 下一首歌曲的模型
 */
- (void)DGCacheVideoPlayFinish:(DGCacheVideoModel *)nextModel{
    
    NSLog(@"播放完成了");
}
/**
 播放状态发生了改变
 
 @param status 改变后的状态
 */
- (void)DGCacheVideoPlayStatusChanged:(DGCacheVideoState)status{
    switch (status) {
        case DGCacheVideoStateStop:
        {
            self.playStatusLable.text = @"停止";
        }
            break;
        case DGCacheVideoStatePause:
        {
            self.playStatusLable.text = @"暂停";
        }
            break;
        case DGCacheVideoStatePlay:
        {
            self.playStatusLable.text = @"播放";
        }
            break;
        case DGCacheVideoStateBuffer:
        {
            self.playStatusLable.text = @"缓冲";
        }
        default:
            break;
    }
    
}
/**
 缓存的进度 注意：当需要缓存的时候是下载的进度 不需要缓存的时候是监听player loadedTimeRanges的进度
 
 @param cacheProgress 播放的缓存的进度
 */
- (void)DGCacheVideoCacheProgress:(CGFloat )cacheProgress{
    self.cacheSlider.value = cacheProgress;
    
}
/**
 当前时间 总的时间 缓冲的进度的播放代理回调
 
 @param currentTime 当前的时间
 @param durationTime 总的时间
 @param playProgress 播放的进度 （0-1）之间
 */
- (void)DGCacheVideoPlayerCurrentTime:(CGFloat)currentTime
                             duration:(CGFloat)durationTime
                         playProgress:(CGFloat)playProgress{
    
    self.currentTimeLable.text = [NSString stringWithFormat:@"%0.2f",currentTime];
    self.durationTimeLable.text = [NSString stringWithFormat:@"%0.2f",durationTime];
    self.progressSlider.value = playProgress;
    
}
-(void)dealloc{
    NSLog(@"dealloc =======dealloc =======");
    [[DGCacheVideoPlayer shareInstance] playOperate:DGCacheVideoOperateStop];
    
}
@end
