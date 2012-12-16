#import "ViewController.h"
#import "Objection.h"
#import "MGAsyncCommand.h"
#import "PrintCommand.h"
#import "MGCommandConfigParser.h"

@implementation ViewController

objection_register_singleton(ViewController)

- (void)awakeFromObjection
{
	[self initWithNibName:@"ViewController" bundle:nil];
}

- (void)viewDidLoad
{
	_activityIndicator.hidden = YES;
	_outputField.text = @"";
	[_startButton addTarget:self action:@selector(onStartButton) forControlEvents:UIControlEventTouchUpInside];

	[super viewDidLoad];
}

- (void)onStartButton
{
	[self.view endEditing:YES];

	_activityIndicator.hidden = NO;
	[_activityIndicator startAnimating];

	[self clearOutput];
	_startButton.enabled = NO;

	_scriptField.editable = NO;

	[self startCommandExecution];
}

- (void)startCommandExecution
{
	NSString *script = _scriptField.text;
	id <MGAsyncCommand> commandGroup;

	@try
	{
		commandGroup = [MGCommandConfigParser configForString:script];
	}
	@catch (NSException *exception)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:exception.reason
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[self finishExecution];
		return;
	}

	commandGroup.callback = ^
	{
		[self finishExecution];
	};

	[commandGroup execute];
}

- (void)finishExecution
{
	[_activityIndicator stopAnimating];
	_activityIndicator.hidden = YES;

	_startButton.enabled = YES;
	_scriptField.editable = YES;
}

- (void)addOutput:(NSString *)output
{
	if ([_outputField.text isEqualToString:@""])
	{
		_outputField.text = output;
	}
	else
	{
		_outputField.text = [NSString stringWithFormat:@"%@\n%@", _outputField.text, output];
	}

	[_outputField scrollRangeToVisible:NSMakeRange([_outputField.text length], 0)];
}

- (void)clearOutput
{
	_outputField.text = @"";
}

@end