Introduction
===

`MGCommandConfig` is a library aimed to provide a simple way of configuring command execution. It relies on the [MGCommand library](https://github.com/MattesGroeger/MGCommand) which provides the basic command classes. The configuration happens via a proprietary markup language, described [later in this document](https://github.com/MattesGroeger/MGCommandConfig/edit/master/Readme.md#language). This way the commmand logic gets separated from its configuration. An example use case is for scripted sequences in games (e.g. tutorials).

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

Comments
---

Command groups
---

Simple commands
---

Parametrized commands
---

Usage
===

Loading from string
---

Loading from file
---
