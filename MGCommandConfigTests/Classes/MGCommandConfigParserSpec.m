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
#import "MGSequentialCommandGroup.h"
#import "MGConfigurableCommand.h"
#import "Kiwi.h"

@interface SimpleCommand : NSObject <MGCommand>

@end

@implementation SimpleCommand

- (void)execute {}

@end

@interface ArgumentsCommand : NSObject <MGCommand, MGConfigurableCommand>

@property (nonatomic) NSNumber *number;
@property (nonatomic) NSString *string;
@property (nonatomic) NSNumber *number2;

@end

@implementation ArgumentsCommand

- (void)initWithParameters:(NSArray *)parameters
{
	_number = parameters[0];
	_string = parameters[1];
	_number2 = parameters[2];
}

- (void)execute {}

@end

@interface WithoutProtocolCommand : NSObject

@end

@implementation WithoutProtocolCommand

@end

SPEC_BEGIN(MGCommandConfigParserSpec)

describe(@"MGCommandConfigParser", ^
{
	it(@"should parse nothing", ^
	{
		NSString *config = @"\n";

		id result = [MGCommandConfigParser configForString:config];

		[result shouldBeNil];
	});

	it(@"should ignore comments", ^
	{
		NSString *config = @"# comment\n";

		id result = [MGCommandConfigParser configForString:config];

		[result shouldBeNil];
	});

	it(@"should ignore whitespaces", ^
	{
		NSString *config = @"  	# comment  \n";

		id result = [MGCommandConfigParser configForString:config];

		[result shouldBeNil];
	});

	it(@"should break because unknown command", ^
	{
		NSString *config = 	@"@foo\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Unknown key word '@foo' on line 1!"];
	});

	it(@"should create empty sequential group", ^
	{
		NSString *config = 	@"@sequential\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[result should] beKindOfClass:[MGSequentialCommandGroup class]];
		[[[result commands] should] beEmpty];
	});

	it(@"should create empty concurrent group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[result should] beKindOfClass:[MGCommandGroup class]];
		[[[result commands] should] beEmpty];
	});

	it(@"should fail to have command outside group", ^
	{
		NSString *config = @"simple\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Commands have to be wrapped in '@sequential' or '@concurrent' statements. Can't add command 'simple' on line 1!"];
	});

	it(@"should add command without parameters to group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	simple\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[SimpleCommand class]];
	});

	it(@"should add command with empty parameters to group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	simple:\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[SimpleCommand class]];
	});

	it(@"should add command with empty parameters and spacing to group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	simple :\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[SimpleCommand class]];
	});

	it(@"should add command with parameters to group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	arguments:23.2,\"test\",1\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[ArgumentsCommand class]];
		[[[[result commands][0] number] should] equal:@23.2];
		[[[[result commands][0] string] should] equal:@"test"];
		[[[[result commands][0] number2] should] equal:@1];
	});

	it(@"should add command with parameters and spaces to group", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	arguments:  23.2, \"test\"  , 1	\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[ArgumentsCommand class]];
		[[[[result commands][0] number] should] equal:@23.2];
		[[[[result commands][0] string] should] equal:@"test"];
		[[[[result commands][0] number2] should] equal:@1];
	});

	it(@"should support colons in string parameters", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	arguments: 23.2, \"foo:bar\", 1\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[ArgumentsCommand class]];
		[[[[result commands][0] number] should] equal:@23.2];
		[[[[result commands][0] string] should] equal:@"foo:bar"];
		[[[[result commands][0] number2] should] equal:@1];
	});
	
	it(@"should fail because command with parameters doesn't implement TutorialCommand", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	arguments: 23.2\n"
							@"@end\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Missing arguments for command 'arguments' on line 2!"];
	});

	it(@"should fail because of to few arguments", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	withoutProtocol: 23.2\n"
							@"@end\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Command 'withoutProtocol' doesn't implement <MGConfigurableCommand> on line 2!"];
	});

	it(@"should fail to have unknown command", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	foo\n"
							@"@end\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Unknown command 'foo', could not find corresponding class 'FooCommand' on line 2!"];
	});

	it(@"should nest two groups", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	@sequential\n"
							@"	@end\n"
							@"@end\n";

		id result = [MGCommandConfigParser configForString:config];

		[[[result commands] should] haveCountOf:1];
		[[[result commands][0] should] beKindOfClass:[MGSequentialCommandGroup class]];
		[[[result commands][0] should] haveCountOf:0];
	});

	it(@"should fail to have several groups on the top level", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	simple\n"
							@"@end\n"
							@"@sequential\n"
							@"	simple\n"
							@"@end\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Having several groups on the top level is not allowed! Found second group on line 4!"];
	});

	it(@"should fail to have not matching @end tags", ^
	{
		NSString *config = 	@"@concurrent\n"
							@"	simple\n"
							@"@end\n"
							@"@end\n";

		[[theBlock(^
		{
			[MGCommandConfigParser configForString:config];
		}) should] raiseWithReason:@"Not matching @end tag. Found one too much on line 4!"];
	});
});

SPEC_END