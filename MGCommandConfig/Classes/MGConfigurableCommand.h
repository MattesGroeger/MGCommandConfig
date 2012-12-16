#import "MGCommand.h"

@protocol MGConfigurableCommand <NSObject>

- (void)initWithParameters:(NSArray *)parameters;

@end