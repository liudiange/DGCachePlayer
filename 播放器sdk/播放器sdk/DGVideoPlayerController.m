//
//  DGVideoPlayerController.m
//  播放器sdk
//
//  Created by apple on 2018/11/22.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "DGVideoPlayerController.h"
#import "DGVideoManager.h"

@interface DGVideoPlayerController ()<DGVideoManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLable;
@property (weak, nonatomic) IBOutlet UILabel *durationTimeLable;
@property (weak, nonatomic) IBOutlet UISlider *playProgressSlider;
@property (weak, nonatomic) IBOutlet UISlider *cacheProgressSlider;
@property (weak, nonatomic) IBOutlet UILabel *playStateLable;

@end
@implementation DGVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"无缓存的视频播放器";
    [self creatVideoManager];
    
}
#pragma mark - 自己实现的事件响应
/**
 创建videoManager
 */
- (void)creatVideoManager{
    
    NSArray *temArray = @[@"https://weiboshipin.cmvideo.cn/depository_sp/fsv/trans/2018/11/25/649656072/25/5bfaa1eb6633d9b67e3369fe.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 0; index < temArray.count; index ++) {
        DGVideoInfo *videoInfo = [[DGVideoInfo alloc] init];
        videoInfo.videoId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index];
        [infoArray addObject:videoInfo];
    }
    
    [DGVideoManager shareInstance].DGDelegate = self;
    [[DGVideoManager shareInstance] setPlayList:infoArray offset:0 videoGravity:AVLayerVideoGravityResizeAspect addViewLayer:self.view.layer layerFrame:CGRectMake(0, 64, 375, 300)];
    
}
/**
 上一个点击事件

 @param sender 按钮
 */
- (IBAction)previousAction:(UIButton *)sender {
    
    [[DGVideoManager shareInstance] playPreviousVideo];
}
/**
 下一个的点击事件

 @param sender 下一个按钮
 */
- (IBAction)nextAction:(UIButton *)sender {
    
    [[DGVideoManager shareInstance] playNextVideo];
    
}
/**
 播放或者暂停

 @param sender 播放或者暂停
 */
- (IBAction)playOrPauseAction:(UIButton *)sender {
   
    NSLog(@"点击了播放或者暂停的按钮");
    switch ([[DGVideoManager shareInstance] currentPlayeStatus]) {
        case DGPlayerStatusPlay:
        {
            [[DGVideoManager shareInstance] playOperate:DGPlayerPlayOperatePause];
        }
            break;
        case DGPlayerStatusPause:
        {
            [[DGVideoManager shareInstance] playOperate:DGPlayerPlayOperatePlay];
        }
            break;
        case DGPlayerStatusBuffer:
        {
            [[DGVideoManager shareInstance] playOperate:DGPlayerPlayOperatePlay];
        }
            break;
        default:
        {
            [[DGVideoManager shareInstance] playOperate:DGPlayerPlayOperatePause];
        }
            break;
    }
    
}
/**
 拖动进度条的事件

 @param sender sender
 */
- (IBAction)progressSiderAction:(UISlider *)sender {
    
    CGFloat needTime = sender.value * [[DGVideoManager shareInstance] durationTime];
    [[DGVideoManager shareInstance] seekTime:(NSUInteger)needTime];
    
}
/**
 清空播放列表

 @param sender sender
 */
- (IBAction)cleatPlayList:(UIButton *)sender {
    
    [[DGVideoManager shareInstance] clearPlayList:YES];
    
}
/**
 添加播放列表

 @param sender sender
 */
- (IBAction)addPlayList:(UIButton *)sender {
    
    NSArray *temArray = @[@"http://wvideo.spriteapp.cn/video/2018/1210/89d510bc-fc6f-11e8-a53c-0026b938a8ac_wpd.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGVideoInfo *videoInfo = [[DGVideoInfo alloc] init];
        videoInfo.videoId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index - 10];
        [infoArray addObject:videoInfo];
    }
    [[DGVideoManager shareInstance] addPlayList:infoArray];
    
}
/**
 清空部分播放列表

 @param sender sender
 */
- (IBAction)clearSectionPlayList:(UIButton *)sender {
    
    NSArray *temArray = @[@"http://wvideo.spriteapp.cn/video/2018/1210/89d510bc-fc6f-11e8-a53c-0026b938a8ac_wpd.mp4"];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSInteger index = 10; index < temArray.count+10; index ++) {
        DGVideoInfo *videoInfo = [[DGVideoInfo alloc] init];
        videoInfo.videoId = [NSString stringWithFormat:@"%zd",index];
        videoInfo.playUrl = temArray[index - 10];
        [infoArray addObject:videoInfo];
    }
    [[DGVideoManager shareInstance] deletePlayList:infoArray];
}

/**
 减少音量到1

 @param sender 按钮
 */
- (IBAction)reduceVolumeAction:(UIButton *)sender {
    [[DGVideoManager shareInstance] setVolumeValue:1.0];
}

/**
 增加音量到8

 @param sender 按钮
 */
- (IBAction)addVolumeAction:(UIButton *)sender {
    [[DGVideoManager shareInstance] setVolumeValue:8.0];
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
    
    NSLog(@"播放出错了 %zd",status);
}
/**
 播放器播放的缓冲的进度
 
 @param progress 进度。范围为：0-1
 */
- (void)DGPlayerBufferProgress:(CGFloat)progress{
    
    self.cacheProgressSlider.value = progress;
}
/**
 当播放状态发生了改变回调
 
 @param status 播放的状态
 */
- (void)DGPlayerChangeStatus:(DGPlayerStatus)status{
    switch (status) {
        case DGPlayerStatusStop:
        {
            self.playStateLable.text = @"停止";
        }
            break;
        case DGPlayerStatusPause:
        {
            self.playStateLable.text = @"暂停";
        }
            break;
        case DGPlayerStatusPlay:
        {
            self.playStateLable.text = @"播放";
        }
            break;
        case DGPlayerStatusBuffer:
        {
            self.playStateLable.text = @"缓冲";
        }
        default:
            break;
    }
    
}
/**
 一个视频播放完成的delegate，自动会播放下一个，不要再这里边播放下一个视频
 
 @param nextInfo 下一个的musicInfo
 */
- (void)DGPlayerFinished:(DGVideoInfo *)nextInfo{
    
    NSLog(@"当前视频播放完成了");
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
    self.playProgressSlider.value = progress;
    
}
-(void)dealloc{
    NSLog(@"dealloc =======dealloc =======");
    [[DGVideoManager shareInstance] playOperate:DGPlayerPlayOperateStop];
    
}
@end
