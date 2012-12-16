#import <Foundation/Foundation.h>

@protocol MGAsyncCommand;
@class MGCommandGroup;


@interface MGCommandConfigParser : NSObject
{
	int _line;
	NSMutableArray *_commandGroups;
	MGCommandGroup *_rootCommand;
}

- (id <MGAsyncCommand>)parseTutorialConfig:(NSString *)config;

@end