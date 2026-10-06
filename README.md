# UUSwiftBluetooth

UUSwiftBluetooth makes Core Bluetooth easier to use from Swift while preserving its native behavior. It provides block-based APIs for delegate-driven operations, along with a simple default facade that works out of the box. Applications can inject a custom provider, including a mock-backed provider for previews and tests.

The library supports async/await APIs alongside its existing callback APIs, keeping both forms consistent in their behavior and lifecycle.

Peripheral sessions support a recurring application workflow: connect to a peripheral, discover the needed services and characteristics, perform several reads or writes, and then disconnect. A peripheral operation wraps a session to represent that sequence as one unit of work with a result and completion.

## Installation

### - Swift Package Manager

UUSwiftBluetooth has native SPM support.

### - Carthage

UUSwiftBluetooth may be installed via [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your `Cartfile`:

```
github "SilverPineSoftware/UUSwiftBluetooth"
```

Then, following the instructions for [integrating Carthage frameworks into your app](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos), link the `UUSwiftBluetooth` framework into your project.

## Requirements

This library requires a deployment target of iOS 15.0 or greater or OSX 10.13 or greater.
UUSwiftBluetooth currently supports Swift version 5.3 

## Contributing

Please **open pull requests against the `develop` branch**

## Swift

UUSwiftBluetooth is written entirely in Swift and currently does not support Objective-C interoperability.

## Inspiration

UUSwiftBluetooth is an updated implementation of the Objective-C classes available here:
[https://github.com/cheesemaker/toolbox](https://github.com/cheesemaker/toolbox)

## License

UUSwiftBluetooth is available under the MIT license. See [`LICENSE.md`](https://github.com/SilverPineSoftware/UUSwiftBluetooth/blob/master/LICENSE.md) for more information.

## Contributors

[A list of contributors is available through GitHub.](https://github.com/SilverPineSoftware/UUSwiftBluetooth/graphs/contributors)
