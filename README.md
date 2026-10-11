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

## Concurrent operations

`UUPeripheral` always enqueues operation setup asynchronously on its central manager queue, including calls made from that queue. Calls do not wait for the queue. Validation, callback registration, timer creation, and native submission run together on the queue; operation deadlines start when queued setup executes. Completion handlers run on that queue and may enqueue another operation without blocking it. Busy rejection is also dispatched, never invoked inline by the public method.

Reads and writes use separate pending callback/timer keys per characteristic or descriptor UUID. Characteristic and included-service discovery use service UUIDs; descriptor discovery and notification-state changes use characteristic UUIDs. Different keys may operate concurrently. Service discovery, RSSI reads, and L2CAP channel opening each allow one pending request per peripheral.

A request for an occupied key completes with `UUCoreBluetoothErrorCode.operationInProgress` without changing the original request, timer, or notification subscription. Connection ownership is per peripheral identifier and lasts through disconnection: a duplicate `connect` reports that error through its own `disconnected` callback without replacing the owner's callbacks.

The old `UUCBPeripheralBlockDelegate` properties `discoverIncludedServicesBlock`, `discoverCharacteristicsBlock`, `discoverDescriptorsBlock`, and `setNotifyValueForCharacteristicBlock` were removed. Direct callers should use the corresponding `UUPeripheral` operation APIs.

UUID keys do not distinguish separate attributes sharing the same UUID. A local timeout also does not cancel the native request; retrying before its late response arrives remains a known limitation (review findings #5 and #6).

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
