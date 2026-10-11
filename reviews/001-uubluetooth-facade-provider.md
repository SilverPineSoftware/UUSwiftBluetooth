# Review 001: `UUBluetooth` facade and `UUBluetoothProvider`

> Historical review. The [2026-10-10 full-library review](002-full-library-deep-dive.md) reassesses the renamed stack API, records resolved findings, and validates the current build/test state. The provider filenames and current-state statements below describe the earlier snapshot.

**Reviewed:** 2026-10-06  
**Scope:** `Library/UUBluetooth.swift`, `Library/Protocols/UUBluetoothProvider.swift`, and `Library/UUCoreBluetoothProvider.swift` where provider lifecycle affects the facade.  
**Review only:** No library code was changed.

## Overall assessment

The design has good bones. Keeping a provider interface for substitution while offering a default CoreBluetooth-backed entry point fits the goal of making the library easy to adopt without closing off testing and previews. The immutable `shared` provider removes the risk of swapping the global provider after use, and the configuration initializer gives each provider a fixed configuration.

`UUCoreBluetoothProvider` now has both an explicit `initialize()` method and lazy manager-backed properties. This gives apps an intentional activation call while preserving first-access behavior. The remaining concerns are that lazy initialization is not synchronized, the concrete provider exposes setters for its manager and scanner, and the protocol still requires a concrete `UUCentralManager` that external clients cannot construct.

**Verdict:** The default shared provider plus configured provider instances is a reasonable direction and resembles Foundation's default-instance/custom-instance pattern. Keep the explicit and lazy entry points if both are intended, but make manager creation single-instance under concurrent access, keep provider-owned components read-only, and expose mockable central-manager capabilities if full provider substitution is required.

## Follow-up review: configuration initializer and shared provider

The working tree has since changed the global facade to an immutable `UUBluetooth.shared`, added `init(configuration:)` to the provider protocol, made configuration read-only to clients, and implemented `initialize()` by accessing the lazy central manager. Those changes move the construction pattern closer to `URLSession`: a configured provider instance owns its configuration, while the default shared provider has its own default configuration.

The earlier concern about replacing the process-wide provider after use is resolved by removing `setProvider(_:)` and making `shared` a `static let`. The earlier config-read-before-initialize bug is also removed because configuration is now supplied at construction and stored in a `let`. The authorization finding remains resolved as recorded below.

The explicit activation method is now implemented: `initialize()` accesses `centralManager`, creating it immediately. The manager-backed properties still create the manager lazily if accessed first. This matches the chosen fallback behavior, but the debug-only warning discussed during review is not yet present, so accidental first access currently has no diagnostic. If that warning remains part of the desired developer experience, emit it once from the lazy-creation path and suppress it when `initialize()` caused creation.

The new `lazy` storage also introduces a thread-safety concern. Swift documents that if multiple threads access an uninitialized `lazy` instance property simultaneously, there is no guarantee it initializes only once ([Swift language guide](https://docs.swift.org/swift-book/LanguageGuide/Properties.html)). Concurrent access through `initialize()`, `scanner`, or `managerStateMonitor` could therefore create multiple central managers or scanners. Use synchronized one-time creation or isolate access to a defined actor/queue if the provider is meant to be usable from multiple threads.

In addition, `centralManager` and `scanner` are declared `public lazy var`, so their setters are public on `UUCoreBluetoothProvider`. Replacing `centralManager` after the lazy scanner has captured the original manager can split the provider across two manager instances. These properties represent provider-owned components and should be externally read-only, for example with `public private(set)`.

The current API migration is also incomplete: `Sample/AppDelegate.swift` still uses `UUBluetoothConfig` and `UUBluetooth.initialize(config:)`, while the sample and tests still access removed static members such as `UUBluetooth.scanner` and `UUBluetooth.monitor`. Migrate these callers or add temporary forwarding compatibility before treating the API change as complete. The type rename from `UUBluetoothConfig` to `UUBluetoothConfiguration` is source-breaking as well.

The immutable `UUBluetoothConfiguration` struct already has Swift value semantics, and its current stored fields are value types. A get-only property returning it therefore provides a value copy; no `NSCopying` mechanism is needed. The `configuration` documentation can say “value copy” or “snapshot” to distinguish this from Objective-C's copy-on-set property semantics.

`UUBluetoothProvider.centralManager` still returns the concrete `UUCentralManager`, so the limitation on external full mock providers remains. Also, `UUBluetooth.shared` is fixed to the default configuration; apps needing other options must construct and inject their own configured provider, just as apps needing custom URL session behavior construct a session instead of changing `URLSession.shared`.

**Validation:** No build or tests were run against this latest provider update. A previous `swift build` attempt could not reach source compilation in this environment: the active developer directory is Command Line Tools rather than full Xcode, and its Swift compiler does not match the installed SDK. Source inspection still finds the unmigrated sample/test call sites listed above.

## Findings

### [P1] A custom provider cannot supply a mock central manager from outside this module

`UUBluetoothProvider.centralManager` returns the concrete `UUCentralManager` class ([`UUBluetoothProvider.swift:21-22`](../Library/Protocols/UUBluetoothProvider.swift#L21)). `UUCentralManager` is public but not `open`, and its initializer is internal ([`UUCentralManager.swift:26-43`](../Library/Central/UUCentralManager.swift#L26)). A downstream app therefore cannot subclass it or construct an independent instance to return from its own provider.

That prevents the protocol from serving as a full mock/stub seam for the central manager, which is the main object behind scanning and peripheral operations. A custom provider can reuse the real provider's central manager, but then the important part remains backed by CoreBluetooth and is not a complete mock.

**Suggestion:** If full provider substitution is a supported use case, expose the central-manager capability through a protocol with the operations consumers need, or introduce a narrower protocol at the consumer boundary. Keep the concrete CoreBluetooth manager as the production implementation. Avoid making every implementation detail mockable; define the seam around observable operations that app code actually consumes.

### [Resolved — P1] Reading `config` before `initialize` could make the requested config get ignored

In the earlier implementation, the default provider lazily installed a default config when `config` was read, then treated any non-nil `_config` as proof that initialization had happened. That could silently ignore a later `initialize(config:)` call. The current constructor-supplied immutable configuration removes that particular failure mode.

This does not resolve the separate activation-timing concern described in the follow-up section: current manager-backed getters still construct CoreBluetooth lazily.

### [Resolved — P2] Replacing the global provider could split one app across two provider graphs

The earlier mutable static provider and `setProvider(_:)` setter have been removed; `UUBluetooth.shared` is now a `static let`, so callers cannot switch the process-wide provider after retaining objects from it. Apps that need another provider can construct and inject an instance. The shared provider remains global by design, but its binding is no longer replaceable.

### [Resolved — P2] The global provider reference had no synchronization or actor isolation

The provider reference is now an immutable `static let`, eliminating concurrent reassignment of the global binding. This finding concerned replacement of the global provider; it does not establish that the mutable caches inside `UUCoreBluetoothProvider` are safe for concurrent access.

### [P2] Lazy manager and scanner creation is not guaranteed to happen only once

`centralManager` and `scanner` are now Swift `lazy` instance properties. The Swift language guide states that simultaneous first access from multiple threads is not guaranteed to initialize a lazy property only once. A race can create duplicate CoreBluetooth managers or scanners, and callers may observe different instances. This matters because `initialize()`, `managerStateMonitor`, and `scanner` all converge on the same lazy manager.

**Suggestion:** Synchronize creation and storage, or isolate all access to a documented actor/queue. Do not rely on `lazy` alone to guarantee a single manager instance.

### [P2] The concrete provider exposes writable manager and scanner properties

The protocol requirements are get-only, but `UUCoreBluetoothProvider` declares `public lazy var centralManager` and `public lazy var scanner`, which expose public setters when accessed through the concrete type. Replacing the manager after scanner creation leaves the scanner holding the previous manager.

**Suggestion:** Make these provider-owned properties externally read-only, such as `public private(set) lazy var`, or expose them through computed get-only properties backed by private storage.

### [Resolved — P2] The protocol's default authorization value consulted real CoreBluetooth

**Status:** Resolved. `UUBluetoothProvider` now requires conformers to provide `authorizationStatus`, and the CoreBluetooth lookup lives on `UUCoreBluetoothProvider` ([`UUBluetoothProvider.swift:30-31`](../Library/Protocols/UUBluetoothProvider.swift#L30), [`UUCoreBluetoothProvider.swift:82-86`](../Library/UUCoreBluetoothProvider.swift#L82)). Mock providers can return a deterministic value rather than inheriting the machine's real authorization status.

No further change is needed for this finding. The protocol remains CoreBluetooth-specific through the `CBManagerAuthorization` return type, which is appropriate unless the library later aims to support non-CoreBluetooth backends.

## Recommended direction

The current `UUBluetooth.shared` can remain the simple app-wide default. For custom options, previews, and tests, construct a provider with its own configuration and inject that provider into the services or view models that use it:

```swift
let bluetooth = UUCoreBluetoothProvider(configuration: previewConfig)
let viewModel = DeviceListViewModel(bluetooth: bluetooth)
```

This avoids replacing global process state. A separate `UUBluetoothClient` wrapper is only needed if callers benefit from a facade object beyond the provider itself. If full mocking is required, the provider protocol should expose mockable central-manager capabilities instead of the concrete, non-constructible `UUCentralManager`.

## Comparison with Foundation

Foundation commonly pairs an easy default instance with separately created instances when callers need independent configuration or behavior:

- `URLSession.shared` is intended for basic requests. Apple documents its limits and provides configured `URLSession` instances for other use cases. Sessions group related work under their own configuration, so separate parts of an app can have separate session behavior ([`URLSession`](https://developer.apple.com/documentation/foundation/urlsession), [`URLSession.shared`](https://developer.apple.com/documentation/foundation/urlsession/shared)).
- `FileManager.default` is the process-wide convenience manager, while Apple recommends creating a distinct manager when using a delegate ([`FileManager.default`](https://developer.apple.com/documentation/foundation/filemanager/default)).
- `NotificationCenter.default` is available by default, and Apple also describes creating additional notification centers to organize communications into separate contexts ([`NotificationCenter`](https://developer.apple.com/documentation/foundation/notificationcenter)).

The useful analogy is **default convenience plus explicit configured instances**. Foundation APIs are not a direct template for protocol-based app dependency injection, but their instance-oriented configuration model supports isolation without replacing the default global object.

## Review boundaries

This review focused on facade/provider shape and the lifecycle issues directly exposed by those APIs. It did not assess scanning, sessions, peripheral operations, or the wider public API. The findings are based on source inspection; no tests were run because no code was changed.
