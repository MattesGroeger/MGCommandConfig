/*
 * Copyright (c) 2012 Mattes Groeger
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ViewController.h"
#import "Objection.h"
#import "MGAsyncCommand.h"
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

	commandGroup.completeHandler = ^
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