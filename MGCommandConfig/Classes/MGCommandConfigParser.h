#import <Foundation/Foundation.h>

@protocol MGAsyncCommand;
@class MGCommandGroup;


@interface MGCommandConfigParser : NSObject
{
	int _line;
	NSMutableArray *_commandGroups;
	MGCommandGroup *_rootCommand;
}

/**
* Parses a resource with file extension '.config' from the main bundle.
* Returns the root command group for starting execution.
*/
+ (id <MGAsyncCommand>)configForResource:(NSString *)resource;

/**
* Parses a resource with custom file extension from the main bundle.
* Returns the root command group for starting execution.
*/
+ (id <MGAsyncCommand>)configForResource:(NSString *)resource ofType:(NSString *)type;

/**
* Parses a command config string. Returns the root command group for
* starting execution.
*/
+ (id <MGAsyncCommand>)configForString:(NSString *)config;

@end