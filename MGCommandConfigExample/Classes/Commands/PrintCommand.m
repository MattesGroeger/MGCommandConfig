#import "PrintCommand.h"
#import "ViewController.h"
#import "Objection.h"


@implementation PrintCommand

- (void)initWithParameters:(NSArray *)parameters
{
	_message = parameters[0];
}

- (void)execute
{
	ViewController *controller = [[JSObjection defaultInjector] getObject:[ViewController class]];

	[controller addOutput:_message];
}

@end