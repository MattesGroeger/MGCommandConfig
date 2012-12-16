#import <Foundation/Foundation.h>
#import "MGAsyncCommand.h"
#import "MGConfigurableCommand.h"

@class ViewController;

@interface DelayCommand : NSObject <MGAsyncCommand, MGConfigurableCommand>
{
	NSTimeInterval _delayInSeconds;
}

@property (nonatomic, strong) CommandCallback callback;

@end