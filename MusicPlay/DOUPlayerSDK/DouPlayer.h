//
//  DouPlayer.h
//  MusicPlay
//
//  Created by 段庆烨 on 2019/5/3.
//  Copyright © 2019年 段庆烨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Track.h"
@class DouPlayer;
// 根据状态设置播放按钮等
typedef enum : NSUInteger {
    PlayerStatusPlaying,
    PlayerStatusPause,
    PlayerStatusFinish,
    PlayerStatusBuffer,
    PlayerStatusError
} PlayerStatus;

@protocol DouPlayerDelegate <NSObject>
-(void)playerWillChangeState:(PlayerStatus)status;
-(void)playerDidChangedPlaybackTime:(DouPlayer *)player;
-(void)playerDidUpdateBufferProgress:(float)progress;
@end

@interface DouPlayer : NSObject
@property(nonatomic, strong)NSArray<Track*> * trackArray;
@property(nonatomic, weak) id <DouPlayerDelegate> delegate;
@property(nonatomic, assign) PlayerStatus status;
@property(nonatomic, strong, readonly) Track * currentTrack;
@property(nonatomic, assign) NSInteger playingIndex;
@property(nonatomic, assign) NSTimeInterval currentTime;
@property(nonatomic, assign) NSTimeInterval duration;
+(instancetype)sharePlayer;
-(void)play;
-(void)pause;
-(void)next;
-(void)previous;
-(void)seekTo:(NSTimeInterval)time;
@end

