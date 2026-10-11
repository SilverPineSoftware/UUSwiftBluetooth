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

Reads and writes use separate operation keys built from full UUID paths: `service/characteristic` for characteristics and `service/characteristic/descriptor` for descriptors. Notification subscriptions, notification-state changes, and descriptor discovery use the same characteristic path. Characteristic and included-service discovery use service UUIDs. Callback registration, response routing, timers, and timeout tokens use matching keys, so equal characteristic UUIDs in different services and equal descriptor UUIDs under different characteristics remain independent. Different keys may operate concurrently. Service discovery, RSSI reads, and L2CAP channel opening each allow one pending request per peripheral.

A request for an occupied key completes with `UUCoreBluetoothErrorCode.operationInProgress` without changing the original request, timer, or notification subscription. Connection ownership is per peripheral identifier and lasts through disconnection: a duplicate `connect` reports that error through its own `disconnected` callback without replacing the owner's callbacks.

The old `UUCBPeripheralBlockDelegate` properties `discoverIncludedServicesBlock`, `discoverCharacteristicsBlock`, `discoverDescriptorsBlock`, and `setNotifyValueForCharacteristicBlock` were removed. Direct callers should use the corresponding `UUPeripheral` operation APIs.

With a positive timeout, each accepted operation completes once with a matching native result/error, a local timeout, or another terminal error such as disconnection. A timeout releases its callback immediately so callers may retry. Native responses match the currently pending operation key: a response from an earlier attempt may satisfy a retry, including its data or error. The library does not promise correlation to the native request that originally caused that response. A response with no pending one-shot callback is ignored for that request; notification subscriptions still receive their normal value updates.

Local timeout work is different: it carries a unique token for the request that scheduled it. The token is checked on the central queue immediately before completion, so an old queued timeout cannot complete a newer request or cancel its deadline. Successful/error completion invalidates that token, and disconnect invalidates all pending timeout tokens. Retries are neither blocked pending old responses nor automatically disconnected. Disabling an operation's timeout removes the deadline guarantee.

Use discovered attributes with their parent context populated. Direct users of `UUCBPeripheralBlockDelegate` must now pass the characteristic or descriptor object to its registration/removal methods, rather than just its `CBUUID`, so the full path is available.

Composite UUID paths still do not distinguish repeated instances with identical paths. Session convenience lookups that accept only a characteristic UUID, and the session's descriptor collection keyed only by characteristic UUID, also remain ambiguous for repeated UUIDs. These remaining parts of review finding #6 are open; use the contextual attribute-based `UUPeripheral` operations for cross-service duplicates.

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
