//
//  GCD.h
//  demo
//
//  Created by 庆烨 段 on 2019/4/23.
//  Copyright © 2019年 ycww. All rights reserved.
//

#import <Foundation/Foundation.h>
#define GCDS [GCD share]
NS_ASSUME_NONNULL_BEGIN

// 自定义timer添加场景
typedef  NS_ENUM(NSInteger,TimerActionOption){
    CancelPreviousTimerAction = 0, // 取消上一次timer计时任务
    MergePreviousTimerAction,      // 合并上一次timer计时任务
};
@interface GCD : NSObject

@property (nonatomic, copy) void(^afterBlock)(void);



+(instancetype)share;

// 主线程异步
-(GCD* (^)(void(^block)(void)))main;

// 全局线程异步
-(GCD* (^)(void(^block)(void)))globle;

// 延时执行
-(GCD* (^)(float time, void(^block)(void)))after;

// 取消延时执行
-(GCD* (^)(void(^block)(void)))cancelAfter;

/* 下面是group操作 */

// 添加到组
-(GCD* (^)(void))enter;

// 离开组（完成）
-(GCD* (^)(void))leave;

// 异步组调用，自动添加到组
-(GCD* (^)(void(^block)(void)))groupAsyn;

// 所有组调用结束后调用
-(GCD* (^)(void(^block)(void)))groupNotify;

// 快速遍历，不按顺序。比for快
extern void apply(size_t time , void(^block)(size_t));

// 计时器
/**
 启动一个timer (默认精度为0.1s)
 @param timerName       timer的名称，作为唯一标识。
 @param interval        执行的时间间隔。
 @param queue           timer将被放入的队列，也就是最终action执行的队列。传入nil将自动放到一个全局子线程队列中。
 @param repeats         timer是否循环调用。
 @param option          多次schedule同一个timer时的操作选项(目前提供将之前的任务废除或合并的选项)。
 @param action          时间间隔到点时执行的block。
 */
- (void)scheduleGCDTimerWithName:(NSString *)timerName
                        interval:(double)interval
                           queue:(dispatch_queue_t)queue
                         repeats:(BOOL)repeats
                          option:(TimerActionOption)option
                          action:(dispatch_block_t)action;

/**
 取消timer
 @param timerName timer的名称，作为唯一标识。
 */
- (void)cancelTimerWithName:(NSString *)timerName;

@end

NS_ASSUME_NONNULL_END
