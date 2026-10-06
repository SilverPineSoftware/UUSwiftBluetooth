# UUSwiftBluetooth Agent Instructions

Read `.uu-agents/AGENTS.md` and the applicable shared guidance before making changes. For Swift work, also read `.uu-agents/agents/SWIFT.md`, `API_DESIGN.md`, `LIBRARY_COMPATIBILITY.md`, and `TESTING.md`. These project instructions add the Bluetooth library's purpose and workflow.

## Project

UUSwiftBluetooth is a Swift library that wraps CoreBluetooth operations with block-based APIs. Its original design goal is to make delegate-driven CoreBluetooth methods easier to consume through completion blocks. This API is still being developed, so follow the established callback and operation patterns when extending it.

The longer-term direction is to offer async/await versions of many operations as well. Add async APIs when requested, alongside existing block-based APIs. Preserve source compatibility and keep both forms consistent in results, errors, timeouts, cancellation, and resource behavior. Do not start a broad callback-to-async migration as part of an unrelated task.

## Supported Platforms

The Swift package manifest, `Package.swift`, is the source of truth for deployment minimums. It currently declares iOS 15 and macOS 13. Update those values in `Package.swift` when changing the package's platform support, and keep this summary in sync. The README currently lists older minimums; treat that Requirements text as stale until it is corrected. Do not infer the package's minimums from Xcode project target settings.

## Source Layout

- `Library/` contains the library source.
- `Protocols/` defines CoreBluetooth-facing protocols and test seams.
- `Delegates/` adapts delegate callbacks into the library's callback flow.
- `Central/`, `Peripheral/`, `Scanning/`, `Session/`, and `L2Cap/` contain the corresponding APIs.
- `Operations/` contains asynchronous operation helpers.
- `Mocks/` contains mock CoreBluetooth implementations.
- `UnitTests/` contains device-independent XCTest coverage.
- `LiveTests/` contains tests that scan for or communicate with nearby Bluetooth peripherals.
- `TestPlans/` separates the unit and live test plans.
- `Sample/` is a sample reference app.
- TestHost/ is the test shell for live interaction tests

## API and Implementation Guidance

- Keep CoreBluetooth behavior recognizable. A UU wrapper should make callback-based operations easier to use while preserving meaningful CoreBluetooth concepts and errors.
- Follow existing completion block naming, timeout, callback queue, delegate cleanup, and operation patterns in adjacent APIs. Check how a callback is registered and cleared so concurrent or later operations cannot receive stale callbacks.
- Make callback completion behavior predictable, including immediate validation failures, timeouts, disconnects, and delegate errors. Avoid silently dropping errors.
- Preserve existing public APIs when adding async alternatives. Use Swift concurrency conventions, propagate task cancellation deliberately, and guarantee any checked continuation is resumed exactly once with delegate handlers and timeout state cleaned up.
- Avoid adding another abstraction layer when a focused wrapper or helper provides the needed behavior.
- Public API changes can affect downstream Swift Package Manager and Xcode users. Update relevant docs, callers, and tests; identify migration needs for breaking changes.

## Build and Test

The Xcode project has a shared `UUSwiftBluetooth` scheme with `UnitTests` and `LiveTests` test plans. Use a currently installed simulator in place of `<iOS Simulator>`:

```sh
swift build
xcodebuild test -project UUSwiftBluetooth.xcodeproj -scheme UUSwiftBluetooth -testPlan UnitTests -destination 'platform=iOS Simulator,name=<iOS Simulator>'
```

Live tests require a real Bluetooth environment and nearby peripherals; current tests look for a peripheral named `Code Ninja Mac`. Run the live test plan only when that hardware and environment are available:

```sh
xcodebuild test -project UUSwiftBluetooth.xcodeproj -scheme UUSwiftBluetooth -testPlan LiveTests -destination 'platform=iOS,id=<device-identifier>'
```

The Xcode project and simulator tests require full Xcode with the relevant SDKs. If Xcode, a simulator, a device, or the required peripheral is unavailable, report that test as not run and say what was missing. Do not report a test as passing unless it ran.
