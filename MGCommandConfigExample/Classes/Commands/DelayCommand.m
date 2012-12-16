#import "DelayCommand.h"
#import "ViewController.h"
#import "Objection.h"


@implementation DelayCommand

- (void)initWithParameters:(NSArray *)parameters
{
	_delayInSeconds = [parameters[0] integerValue];
}

- (void)execute
{
	ViewController *controller = [[JSObjection defaultInjector] getObject:[ViewController class]];

	[controller addOutput:[NSString stringWithFormat:@"DelayCommand (%d second)", (int) _delayInSeconds]];
	
	[self performSelector:@selector(finishAfterDelay)
			   withObject:nil
			   afterDelay:_delayInSeconds];
}

- (void)finishAfterDelay
{
	_callback();
}

@end