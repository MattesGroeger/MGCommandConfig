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

#import "MGCommandConfigParser.h"
#import "MGAsyncCommand.h"
#import "MGSequentialCommandGroup.h"
#import "MGConfigurableCommand.h"


@implementation MGCommandConfigParser

+ (id <MGAsyncCommand>)configForResource:(NSString *)resource
{
	return [self configForResource:resource ofType:@"config"];
}

+ (id <MGAsyncCommand>)configForResource:(NSString *)resource ofType:(NSString *)type
{
	NSError *error;
	NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
	NSString *string = [NSString stringWithContentsOfFile:path
												 encoding:NSUTF8StringEncoding
													error:&error];

	NSAssert(!error, [error localizedDescription]);

	return [self configForString:string];
}

+ (id <MGAsyncCommand>)configForString:(NSString *)config
{
	return [[[MGCommandConfigParser alloc] init] configForString:config];
}

- (id)init
{
	self = [super init];
	
	if (self)
	{
		_commandGroups = [NSMutableArray array];
	}

	return self;
}

- (id <MGAsyncCommand>)configForString:(NSString *)config
{
	NSArray *lines = [config componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];

	_rootCommand = nil;
	_line = 1;

	for (NSString *line in lines)
	{
		[self parseLine:line];
		_line++;
	}

	return _rootCommand;
}

- (void)parseLine:(NSString *)line
{
	NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if ([trimmedLine isEqualToString:@""])
	{
		return;
	}

	NSString *firstChar = [trimmedLine substringToIndex:1];

	if ([firstChar isEqualToString:@"#"])
	{
		return; // ignore comments
	}
	else if ([firstChar isEqualToString:@"@"])
	{
		[self parseKeyWord:[trimmedLine substringFromIndex:1]];
	}
	else
	{
		[self parseCommand:trimmedLine];
	}
}

- (void)parseKeyWord:(NSString *)keyWord
{
	if ([keyWord isEqualToString:@"end"])
	{
		if (_commandGroups.count == 0)
		{
			[self throwError:@"Not matching @end tag. Found one too much"];
		}

		[_commandGroups removeLastObject];
	}
	else if ([keyWord isEqualToString:@"concurrent"])
	{
		[self addNewCommandGroup:[[MGCommandGroup alloc] init]];
	}
	else if ([keyWord isEqualToString:@"sequential"])
	{
		[self addNewCommandGroup:[[MGSequentialCommandGroup alloc] init]];
	}
	else
	{
		[self throwError:[NSString stringWithFormat:@"Unknown key word '@%@'", keyWord]];
	}
}

- (void)addNewCommandGroup:(MGCommandGroup *)commandGroup
{
	MGCommandGroup *parentGroup = [_commandGroups lastObject];

	[_commandGroups addObject:commandGroup];
	
	if (parentGroup == nil)
	{
		if (_rootCommand)
		{
			[self throwError:[NSString stringWithFormat:@"Having several groups on the top level is not allowed! Found second group"]];
		}

		_rootCommand = commandGroup;
	}
	else
	{
		[parentGroup addCommand:commandGroup];
	}
}

- (void)parseCommand:(NSString *)command
{
	if (![_commandGroups lastObject])
	{
		[self throwError:[NSString stringWithFormat:@"Commands have to be wrapped in '@sequential' or '@concurrent' statements. Can't add command '%@'", command]];
	}

	NSRange colonRange = [command rangeOfString:@":"];
	NSString *commandName = (colonRange.length > 0) ? [self trim:[command substringToIndex:colonRange.location]] : [self trim:command];
	NSString *argumentsString = (colonRange.length > 0) ? [self trim:[command substringFromIndex:colonRange.location+1]] : nil;

	NSString *className = [[self capitalizeString:commandName] stringByAppendingString:@"Command"];
	Class type = NSClassFromString(className);

	if (!type)
	{
		[self throwError:[NSString stringWithFormat:@"Unknown command '%@', could not find corresponding class '%@'", commandName, className]];
	}

	id instance = [[type alloc] init];

	[self parseAndSetArguments:commandName argumentsString:argumentsString instance:instance];

	[[_commandGroups lastObject] addCommand:instance];
}

- (NSString *)capitalizeString:(NSString *)string
{
	return [string stringByReplacingCharactersInRange:NSMakeRange(0,1)
										   withString:[[string substringToIndex:1] capitalizedString]];
}

- (void)parseAndSetArguments:(NSString *)commandName argumentsString:(NSString *)argumentsString instance:(id)instance
{
	if (argumentsString && ![argumentsString isEqualToString:@""])
	{
		if ([instance conformsToProtocol:@protocol(MGConfigurableCommand)])
		{
			NSArray *arguments = [argumentsString componentsSeparatedByString:@","];
			NSMutableArray *processedArguments = [NSMutableArray array];

			for (NSString *argument in arguments)
			{
				[processedArguments addObject:[self convertType:[self trim:argument]]];
			}

			@try
			{
				[(id <MGConfigurableCommand>)instance initWithParameters:processedArguments];
			}
			@catch (NSException *exception)
			{
				[self throwError:[NSString stringWithFormat:@"Missing arguments for command '%@'", commandName]];
			}
		}
		else
		{
			[self throwError:[NSString stringWithFormat:@"Command '%@' doesn't implement <MGConfigurableCommand>", commandName]];
		}
	}
}

- (id)convertType:(NSString *)string
{
	if ([[string substringToIndex:1] isEqualToString:@"\""])
	{
		return [string substringWithRange:NSMakeRange(1, string.length-2)];
	}
	else
	{
		return [NSNumber numberWithDouble:[string doubleValue]];
	}
}

- (NSString *)trim:(NSString *)string
{
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)throwError:(NSString *)line
{
	NSString *error = [NSString stringWithFormat:@"%@ on line %d!", line, _line];

	NSAssert(NO, error);
}

@end