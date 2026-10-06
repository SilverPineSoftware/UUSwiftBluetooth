# Review 001: `UUBluetooth` facade and `UUBluetoothProvider`

**Reviewed:** 2026-10-06  
**Scope:** `Library/UUBluetooth.swift`, `Library/Protocols/UUBluetoothProvider.swift`, and `Library/UUCoreBluetoothProvider.swift` where provider lifecycle affects the facade.  
**Review only:** No library code was changed.

## Overall assessment

The design has good bones. Keeping a provider interface for substitution while offering a default CoreBluetooth-backed entry point fits the goal of making the library easy to adopt without closing off testing and previews. I would keep both ideas.

The current implementation leans too heavily on one mutable process-wide provider. `UUBluetooth.setProvider(_:)` is a global service-locator switch, rather than scoped dependency injection. It is convenient for a single app-wide setup when called once before first use, but it does not provide isolated Bluetooth instances for multiple previews, tests, or app components. More importantly, the protocol currently makes a complete external mock provider impractical because it requires the concrete `UUCentralManager` type.

**Verdict:** Good concept, but the current global injection mechanism is awkward and the central-manager seam is incomplete. Keep the out-of-the-box facade and provider abstraction; add an instance-based client/context that accepts a provider, and let the static facade represent only the default client.

## Findings

### [P1] A custom provider cannot supply a mock central manager from outside this module

`UUBluetoothProvider.centralManager` returns the concrete `UUCentralManager` class ([`UUBluetoothProvider.swift:21-22`](../Library/Protocols/UUBluetoothProvider.swift#L21)). `UUCentralManager` is public but not `open`, and its initializer is internal ([`UUCentralManager.swift:26-43`](../Library/Central/UUCentralManager.swift#L26)). A downstream app therefore cannot subclass it or construct an independent instance to return from its own provider.

That prevents the protocol from serving as a full mock/stub seam for the central manager, which is the main object behind scanning and peripheral operations. A custom provider can reuse the real provider's central manager, but then the important part remains backed by CoreBluetooth and is not a complete mock.

**Suggestion:** If full provider substitution is a supported use case, expose the central-manager capability through a protocol with the operations consumers need, or introduce a narrower protocol at the consumer boundary. Keep the concrete CoreBluetooth manager as the production implementation. Avoid making every implementation detail mockable; define the seam around observable operations that app code actually consumes.

### [P1] Reading `config` before `initialize` can make the requested config get ignored

The default provider lazily installs a default config when `config` is read ([`UUCoreBluetoothProvider.swift:19-29`](../Library/UUCoreBluetoothProvider.swift#L19)). Its `initialize(config:)` then treats any non-nil `_config` as proof that initialization already happened and returns without applying the supplied value ([`UUCoreBluetoothProvider.swift:37-49`](../Library/UUCoreBluetoothProvider.swift#L37)). Since the facade exposes `UUBluetooth.config`, this sequence silently keeps default options:

```swift
let currentConfig = UUBluetooth.config
UUBluetooth.initialize(config: customConfig)
```

The caller receives only a log warning, and the central manager may subsequently be created with the default options. This confuses “a default value has been requested” with “the Bluetooth stack has been initialized.”

**Suggestion:** Track initialization separately from whether a config value exists, or make configuration immutable and supplied when the provider/client is created. Define what repeated initialization means and make a rejected reconfiguration visible to callers rather than relying only on a log message.

### [P2] Replacing the global provider can split one app across two provider graphs

The facade stores a mutable static provider ([`UUBluetooth.swift:12-16`](../Library/UUBluetooth.swift#L12)). If a caller retains `UUBluetooth.scanner`, then `setProvider(_:)` is called, the retained scanner still belongs to the old provider while subsequent reads of `centralManager`, `monitor`, or `scanner` use the replacement. The setter neither documents nor enforces a “before first access” rule.

This also creates test-order coupling: one test or preview can leave its provider installed for later users of the static facade. It is reasonable to have one app-wide default, but a mutable global is not a good way to represent multiple isolated dependency graphs.

**Suggestion:** Give each injected client/context its own provider and let app code inject that value into view models or services. Keep the static facade backed by a stable default client for simple applications. If `setProvider(_:)` must remain for compatibility, document and enforce that it may only be called before any facade access, and deprecate it in favor of instance injection over time.

### [P2] The global provider has no synchronization or actor isolation

The static provider is mutable shared state and is read and written without locking or actor isolation. Concurrent `setProvider` and facade-property access can race, and Swift's stricter concurrency checking may flag this design as the package adopts newer language modes.

**Suggestion:** Removing mutation from the global default facade also removes this race. If mutable replacement remains, constrain it to a defined actor or synchronize access, and state the required setup ordering in the API contract.

### [Resolved — P2] The protocol's default authorization value consulted real CoreBluetooth

**Status:** Resolved. `UUBluetoothProvider` now requires conformers to provide `authorizationStatus`, and the CoreBluetooth lookup lives on `UUCoreBluetoothProvider` ([`UUBluetoothProvider.swift:30-31`](../Library/Protocols/UUBluetoothProvider.swift#L30), [`UUCoreBluetoothProvider.swift:82-86`](../Library/UUCoreBluetoothProvider.swift#L82)). Mock providers can return a deterministic value rather than inheriting the machine's real authorization status.

No further change is needed for this finding. The protocol remains CoreBluetooth-specific through the `CBManagerAuthorization` return type, which is appropriate unless the library later aims to support non-CoreBluetooth backends.

## Recommended direction

Add an instantiable facade/client whose lifetime owns one provider graph. App code that needs previews or tests can construct it with a mock provider and pass that client to the relevant view model or service. The default initializer can create `UUCoreBluetoothProvider`, so common production use remains concise. Keep `UUBluetooth` as the static convenience entry point for the default app-wide client and preserve existing static members during a compatibility period.

Conceptually:

```swift
let bluetooth = UUBluetoothClient(provider: PreviewBluetoothProvider())
let viewModel = DeviceListViewModel(bluetooth: bluetooth)
```

For a simple app, callers can continue using the default facade without assembling dependencies. For a preview or test, the app supplies a separate client rather than changing a process-wide switch. The provider protocol should then expose mockable capabilities instead of requiring a concrete, non-constructible `UUCentralManager`.

This direction preserves the convenience the current API is aiming for while making dependency injection explicit and local, so separate previews and tests do not need to replace shared process state. It also avoids forcing every consumer to use a protocol if the production default is sufficient.

## Comparison with Foundation

Foundation commonly pairs an easy default instance with separately created instances when callers need independent configuration or behavior:

- `URLSession.shared` is intended for basic requests. Apple documents its limits and provides configured `URLSession` instances for other use cases. Sessions group related work under their own configuration, so separate parts of an app can have separate session behavior ([`URLSession`](https://developer.apple.com/documentation/foundation/urlsession), [`URLSession.shared`](https://developer.apple.com/documentation/foundation/urlsession/shared)).
- `FileManager.default` is the process-wide convenience manager, while Apple recommends creating a distinct manager when using a delegate ([`FileManager.default`](https://developer.apple.com/documentation/foundation/filemanager/default)).
- `NotificationCenter.default` is available by default, and Apple also describes creating additional notification centers to organize communications into separate contexts ([`NotificationCenter`](https://developer.apple.com/documentation/foundation/notificationcenter)).

The useful analogy is therefore **default convenience plus explicit instances**, not **a global default whose implementation is replaced at runtime**. Foundation APIs are not a direct template for protocol-based app dependency injection, but their instance-oriented configuration model supports isolation in a way this mutable static provider does not.

## Review boundaries

This review focused on facade/provider shape and the lifecycle issues directly exposed by those APIs. It did not assess scanning, sessions, peripheral operations, or the wider public API. The findings are based on source inspection; no tests were run because no code was changed.
