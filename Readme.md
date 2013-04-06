[![Build Status](https://travis-ci.org/MattesGroeger/MGCommandConfig.png?branch=master)](https://travis-ci.org/MattesGroeger/MGCommandConfig)

Introduction
===

`MGCommandConfig` is a library aimed to provide a simple way of configuring command execution. It relies on the [MGCommand library](https://github.com/MattesGroeger/MGCommand) which provides the basic command logic. The configuration happens via a proprietary markup language, described [later in this document](https://github.com/MattesGroeger/MGCommandConfig/edit/master/Readme.md#language). This way the command logic gets separated from its configuration. An example use case is scripted sequences in games (e.g. tutorials).

Installation via CocoaPods
===

- Install CocoaPods. See [http://cocoapods.org](http://cocoapods.org)
- Add the MGCommandConfig reference to the Podfile:
```
    platform :ios
      pod 'MGCommandConfig'
    end
```

- Run `pod install` from the command line
- Open the newly created Xcode Workspace file
- Implement your commands and command configurations

Language
===

The configuration is parsed line by line. Therefore every command needs to be on a separate line. Empty lines and spaces are ignored.

Comments
---

Sometimes comments are necessary to explain certain steps. Right now comments are only allowed for full lines.

    # This is a comment

Command groups
---

Every command needs to be wrapped in a command group. Command groups need to be terminated by an `@end` tag. There are two different command groups available.

Sequential command groups execute all their sub-commands one after the other. Every command waits for the previous one to be finished:

    @sequential
        command1
        command2
    @end

Concurrent command groups execute their sub-commands all at once. Still the order they are declared corresponds to the order they get executed:

    @concurrent
        command1
        command2
    @end

Command groups can be nested endlessly. Note that the indentation is not required, it just helps for better readability:

    @sequential
        command1
        @concurrent
            command2
            @sequential
                command3
                command4
            @end
        @end
        command5
    @end

Simple commands
---

The command mapping happens by convention. If you declare a command like this...

    @concurrent
        test
    @end

... the parser will try to load a class named `TestCommand`. The `TestCommand` needs to implement at least the `MGCommand` or `MGAsyncCommand` protocol:

```objective-c
@interface TestCommand : NSObject <MGCommand>

@end
```

```objective-c
@implementation TestCommand

- (void)execute
{
	NSLog(@"Test executed");
}

@end
```

Parametrized commands
---

In most cases you also want to pass some data to the command. A parametrized command needs to have the following format:

	command: parameter1 [, parameter2] [, ...]

A parameter can be either a string (e.g. `"foo"`) or a number (e.g. `23.3`). They get converted into their Objective-C equivalents `NSString` and `NSNumber`.

This is how a parametrized command could look like:

    @concurrent
        test: "a string", 1
    @end

**Consuming parameters inside a command**

In order to retrieve the parameters in the command implementation, it needs to implement the `MGConfigurableCommand` protocol.

```objective-c
@interface TestCommand : NSObject <MGCommand, MGConfigurableCommand>
{
    NSString *_string;
    NSNumber *_number;
}

@end
```

```objective-c
@implementation TestCommand

- (void)initWithParameters:(NSArray *)parameters
{
    _string = parameters[0];
    _number = parameters[1];
}

- (void)execute
{
    NSLog([NSString stringWithFormat:@"Message: '%@', number: '%d'", _string, [_number integerValue]);
}

@end
```

Note that the implementation of `initWithParameters:(NSArray *)parameters` stores the passed in data as instance variables. That way they can be accessed later upon execution. In the above example they are just used for creating a log statement.

Usage
===

The parser always returns an object of type `id <MGAsyncCommand>` which represents the root command group. If the parsing fails it will throw an `NSInternalInconsistencyException` (via NSAssert) that you can catch.

Loading from file
---

The recommended way is to load the configuration from a file in the main bundle. This is how a configuration file could look like:

    # example file
    @sequential
        test: "foo", 1
        test: "bar", 2
    @end

If you add this file as `example.config` to your project, you can parse it like this:

```objective-c
id <MGAsyncCommand> commandGroup = [MGCommandConfigParser configForResource:@"example"];

commandGroup.completeHandler = ^
{
    // execution finished
};

[commandGroup execute];
```

If you want to use a different file extension, you can use it like this:

```objective-c
[MGCommandConfigParser configForResource:@"example" ofType:@"ext"]; // will load example.ext
```

Loading from string
---

If you want to handle the file loading yourself, you can also parse a string.

```objective-c
NSString *config = @"@sequential\n"
                    "    test: \"foo\", 1\n"
                    "    test: \"bar\", 2\n"
                    "@end\n";

id <MGAsyncCommand> commandGroup = [MGCommandConfigParser configForString:config];

// start the execution...
```

Example
===

You can find an example application in the [MGCommandConfigExample subfolder](https://github.com/MattesGroeger/MGCommandConfig/tree/master/MGCommandConfigExample). In this app you can change the configuration at runtime and test the effect immediately. The following commands can be used:

    print: (string)message – prints the given message on screen
    delay: (int)seconds - delays the execution by the given seconds

## Changelog

**0.1.0** (2013/04/01)

* [NEW] Made version compatible with `MGCommand` `0.1.0`
* [NEW] Support colons in string parameters

**0.0.1** (2012/12/16)

* Initial version

## Contribution

This library is released under the [MIT licence](http://opensource.org/licenses/MIT). Contributions are more than welcome!

Also, follow me on Twitter if you like: [@MattesGroeger](https://twitter.com/MattesGroeger).
