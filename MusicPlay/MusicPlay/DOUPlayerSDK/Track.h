

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DOUAudioFile.h"

@interface Track : NSObject <DOUAudioFile>


/**
 专辑
 */
@property (nonatomic, strong) NSString *artist;

/**
 名称
 */
@property (nonatomic, strong) NSString *title;

/**
 图片
 */
@property (nonatomic, strong) UIImage * img;

/**
 url
 */
@property (nonatomic, strong) NSURL *audioFileURL;

@end
