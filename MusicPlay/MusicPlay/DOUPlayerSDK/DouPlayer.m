//
//  DouPlayer.m
//  MusicPlay
//
//  Created by 段庆烨 on 2019/5/3.
//  Copyright © 2019年 段庆烨. All rights reserved.
//

#import "DouPlayer.h"
#import "DOUAudioStreamer.h"
#import "GCD.h"
#import <MediaPlayer/MediaPlayer.h>
static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;
@interface DouPlayer()
@property (nonatomic , strong) DOUAudioStreamer * streamer;
@property(nonatomic, strong) Track * currentTrack;
@property(nonatomic, strong) GCD * timeGcd;
@end
@implementation DouPlayer

+(instancetype)sharePlayer{
    static DouPlayer * z = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        z = [[DouPlayer alloc] init];
    });
    return z;
}

-(instancetype)init{
    if (self == [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomActive) name:UIApplicationDidEnterBackgroundNotification object:nil];
    };
    return self;
}


-(void)becomActive{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self observeRemoteControl];
}

-(void)gotoBackGroud{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}


-(void)play{
    [self.streamer play];
}

-(void)pause{
    [self.streamer pause];
}

-(void)togglePlayOrPause{
    if (self.streamer.status == DOUAudioStreamerPlaying) {
        [self pause];
    }else if(self.streamer.status == DOUAudioStreamerPaused){
        [self play];
    }
}

-(void)next{
    if (self.playingIndex < self.trackArray.count-1) {
        self.playingIndex ++;
//        [self play];
    }
}

-(void)previous{
    if (self.playingIndex > 0) {
        self.playingIndex --;
//        [self play];
    }
}

-(void)seekTo:(NSTimeInterval)time{
    self.streamer.currentTime = time;
}

-(void)setTrackArray:(NSArray<Track *> *)trackArray{
    _trackArray = trackArray;
}

-(void)setPlayingIndex:(NSInteger)playingIndex{
    if (_playingIndex == playingIndex) {
        return;
    }
    self.streamer = [DOUAudioStreamer streamerWithAudioFile:self.trackArray[playingIndex]];
    self.currentTrack = self.trackArray[playingIndex];
}

-(void)setStreamer:(DOUAudioStreamer *)streamer{
    if (_streamer) {
        [_streamer removeObserver:self forKeyPath:@"status"];
        [_streamer removeObserver:self forKeyPath:@"duration"];
        [_streamer removeObserver:self forKeyPath:@"bufferingRatio"];
        _streamer = nil;
    }
    _streamer = streamer;
    [_streamer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kStatusKVOKey];
    [_streamer addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:kDurationKVOKey];
    [_streamer addObserver:self forKeyPath:@"bufferingRatio" options:NSKeyValueObservingOptionNew context:kBufferingRatioKVOKey];
    self.duration = streamer.duration;
    [_streamer play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kStatusKVOKey) {
        [self performSelector:@selector(updateStatus)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
    }
    else if (context == kDurationKVOKey) {
        [self performSelector:@selector(changePlayTime)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
    }
    else if (context == kBufferingRatioKVOKey) {
        //        [self performSelector:@selector(_updateBufferingStatus)
        //                     onThread:[NSThread mainThread]
        //                   withObject:nil
        //                waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// MARK: -- 改变播放状态
- (void)updateStatus{
    switch ([self.streamer status]) {
            
        case DOUAudioStreamerPlaying:{
            // 播放状态
            self.status = PlayerStatusPlaying;
            [self.timeGcd scheduleGCDTimerWithName:@"监听进程" interval:1 queue:dispatch_get_global_queue(1, 1) repeats:NO option:CancelPreviousTimerAction action:^{
                [self changePlayTime];
            }];
            
        }
            break;
        case DOUAudioStreamerPaused:
            // 暂停状态  123
            self.status = PlayerStatusPause;
            break;
        case DOUAudioStreamerIdle:
            // 闲置状态
            break;
        case DOUAudioStreamerFinished:
            // 结束状态 可以自动下一曲
            self.status = PlayerStatusFinish;
            break;
        case DOUAudioStreamerBuffering:
            // 缓冲状态
            self.status = PlayerStatusBuffer;
            break;
        case DOUAudioStreamerError:
            // 错误状态
            self.status = PlayerStatusError;
            if ([self.delegate respondsToSelector:@selector(playerDidUpdateBufferProgress:)]) {
                [self.delegate playerDidUpdateBufferProgress:self.streamer.bufferingRatio];
            }
            break;
    }
    if ([self.delegate respondsToSelector:@selector(playerWillChangeState:)]) {
        [self.delegate playerWillChangeState:self.status];
    }
}

-(void)changePlayTime{
    self.currentTime = self.streamer.currentTime;
    if ([self.delegate respondsToSelector:@selector(playerDidChangedPlaybackTime:)]) {
        [self.delegate playerDidChangedPlaybackTime:self];
    }
    [self setBackGroudIOnfo];
}

- (void)setBackGroudIOnfo{
    MPNowPlayingInfoCenter * mpc = [MPNowPlayingInfoCenter defaultCenter];
    MPMediaItemArtwork * album;
    if (@available(iOS 10.0, *)) {
        album = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(400, 400) requestHandler:^UIImage * _Nonnull(CGSize size) {
            return self.currentTrack.img;
        }];
    } else {
        album = [[MPMediaItemArtwork alloc] initWithImage:self.currentTrack.img];
    }
    mpc.nowPlayingInfo = @{MPMediaItemPropertyTitle:self.currentTrack.title,
                           MPMediaItemPropertyArtist:self.currentTrack.artist,
                           MPMediaItemPropertyArtwork:album,
                           MPMediaItemPropertyPlaybackDuration:[NSNumber numberWithDouble:self.streamer.duration] ,
                           MPNowPlayingInfoPropertyElapsedPlaybackTime:[NSNumber numberWithDouble:self.streamer.currentTime]
                           };
}


-(GCD *)timeGcd{
    if (!_timeGcd) {
        _timeGcd = [GCD new];
    }
    return _timeGcd;
}

- (void)observeRemoteControl {
    [self removeObserveRemoteControl];
    
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand addTarget:self action:@selector(play)];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand addTarget:self action:@selector(pause)];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand addTarget:self action:@selector(next)];
    [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand addTarget:self action:@selector(previous)];
    // 耳机
    [[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand setEnabled:YES];
    [[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand addTarget:self action:@selector(togglePlayOrPause)];
    //在控制台拖动进度条调节进度（仿QQ音乐的效果）
    if (@available(iOS 9.1, *)) {
        [[MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            NSTimeInterval positionTime = playbackPositionEvent.positionTime;
            NSLog(@"positionTime:%f",positionTime);
            [self.streamer setCurrentTime:positionTime];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }
}

- (void)removeObserveRemoteControl {
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget:self action:@selector(play)];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget:self action:@selector(pause)];
    [[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand removeTarget:self action:@selector(togglePlayOrPause)];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget:self action:@selector(next)];
    [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget:self action:@selector(previous)];
}
@end
