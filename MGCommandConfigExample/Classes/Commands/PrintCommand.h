#import <Foundation/Foundation.h>
#import "MGCommand.h"
#import "MGConfigurableCommand.h"


@interface PrintCommand : NSObject <MGCommand, MGConfigurableCommand>
{
	NSString *_message;
}

@end