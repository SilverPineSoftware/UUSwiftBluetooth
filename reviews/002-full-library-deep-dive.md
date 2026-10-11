# Review 002: Full UUSwiftBluetooth deep dive

**Reviewed:** 2026-10-10  
**Baseline:** Working tree over `93df2d6af1a31099804289efd2de8a644bacb85a`, including the existing uncommitted API renames and sample changes. Line references describe that snapshot.  
**Scope:** Library stack/configuration, central and peripheral delegates, scanning, GATT operations, sessions, operations, L2CAP client/server, representations, mocks, extensions, sniffer, sample integration, package/project configuration, and test coverage.  
**Review only:** No implementation or existing test files changed. This review supersedes the current-state assessment in Review 001 while retaining that document as history.

## Overall assessment

The thin CoreBluetooth wrappers and the session/operation workflow remain useful. The stack's synchronized, externally read-only manager/scanner construction is a substantial improvement over the provider reviewed previously. The iOS sample builds successfully.

The primary risk is lifecycle correctness. Callback slots and timers are shared too broadly, disconnect can discard pending completions, and timeout does not establish a boundary against later delegate events. Those issues can make a caller wait forever or accept a response belonging to another request. L2CAP has similar completion and cleanup problems. The advertised macOS package does not compile, and the unit test plan cannot reach execution because its scheme also builds unmigrated live tests.

**Verdict:** Prioritize build/test recovery and operation completion guarantees before adding async wrappers. Checked continuations would expose the current lost/double-completion paths as hangs or runtime failures. A broad framework rewrite is unnecessary; explicit ownership, serialized state transitions, and narrowly defined request state are the important changes.

## Validation and limits

| Check | Result |
| --- | --- |
| Default `swift build --skip-update` | Failed before source compilation with Command Line Tools SDK/compiler mismatch and module-cache permissions. |
| Xcode-selected sandboxed build | Passed manifest evaluation but could not fetch the declared dependency because network access was restricted. |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build` with normal cache/network access | **Failed compiling the library for macOS 13**, on unavailable CoreBluetooth protocol requirements. |
| Documented `xcodebuild test ... -scheme UUSwiftBluetooth -testPlan UnitTests` | **Failed:** that scheme no longer exists. |
| Same unit plan using the verified `Library` scheme and installed iPhone 18 Pro / iOS 27 simulator | **Failed during compilation of LiveTests** because `UUBluetooth.scanner` was removed. No XCTest cases executed. |
| `xcodebuild build ... -scheme Sample -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` | **Passed** with Xcode 27.0, build 27A266a. |
| Focused Foundation-only probe | Reproduced all three optional-name JSON round-trip failures and equal-name comparison returning `true` in both sort directions. |
| Live Bluetooth/restoration/L2CAP integration | **Not run:** no controlled peripheral environment was established. |

The Foundation probe copied the current three representation implementations with only their CoreBluetooth convenience initializers removed, plus the current `compareStrings` function. It exercised the unchanged initializers, Codable methods, and comparison logic; it was not a full-library test. Other runtime findings below are source-traced failure scenarios, not claims of hardware reproduction.

The executed iOS commands used derived data under `/tmp/uu-bluetooth-review-derived`. Build logs and result bundles were left under `/tmp/uu-bluetooth-review-*` for this session; they are temporary evidence, not versioned artifacts. Dependency resolution used UUSwiftCore 1.7.2 and, for Xcode tests, UUSwiftTestCore 0.0.5. Its timer implementation confirms that starting a timer with an existing identifier cancels/replaces it, and non-positive timeouts disable it.

## Findings

### 1. [P1] The declared macOS product cannot compile

**Locations:** [`UUCBCentralManager.swift`](../Library/Protocols/UUCBCentralManager.swift#L11), [`UUCBPeripheral.swift:72`](../Library/Protocols/UUCBPeripheral.swift#L72), [`UUMockCBPeripheral.swift:51`](../Library/Mocks/UUMockCBPeripheral.swift#L51), [`Package.swift`](../Package.swift).

The protocols unconditionally require `CBCentralManager.supports`, `registerForConnectionEvents(options:)`, and `CBPeripheral.ancsAuthorized`. The SDK marks these APIs unavailable on macOS, so the concrete conformances cannot satisfy their requirements. The Xcode-selected `swift build` reproduced these errors despite the manifest explicitly supporting macOS 13. The mock also forwards `ancsAuthorized` to the unavailable native property.

**Suggestion:** Apply platform availability/conditional compilation consistently to requirements, conformances, and mock forwarding, preserving the iOS API. Build both declared platforms as release gates. Do not silently drop macOS support to make the check pass.

**Regression:** Compile the package for macOS and the framework for the minimum supported iOS deployment target.

### 2. [Resolved — P1] The unit test scheme builds live tests that still call the removed facade API

**Resolved 2026-10-11:** Active live-test calls now use `UUBluetooth.shared.scanner`, AGENTS.md documents the `Library` scheme, and the unconditional LiveTests build-action entry has been removed. Xcode `build-for-testing` succeeded for both `UnitTests` and `LiveTests` plans using the generic iOS Simulator destination. The UnitTests build graph excludes LiveTests; selecting the LiveTests plan still includes and builds LiveTests. These checks compiled the tests without executing them; the maintainer separately reported a passing unit-test run. The original finding below is retained as review history.

**Locations:** [`Library.xcscheme:35`](../UUSwiftBluetooth.xcodeproj/xcshareddata/xcschemes/Library.xcscheme#L35), [`UULivePeripheralTests.swift:23`](../LiveTests/UULivePeripheralTests.swift#L23), [`UUSwiftBluetoothLiveTests.swift:36`](../LiveTests/UUSwiftBluetoothLiveTests.swift#L36), [`Helpers.swift:57`](../LiveTests/Helpers.swift#L57).

The `Library` scheme explicitly marks LiveTests for building during testing. Selecting the UnitTests plan therefore still compiles those sources. They use `UUBluetooth.scanner`, while the working tree exposes `UUBluetooth.shared.scanner`. The actual unit test invocation failed on these calls. Separately, AGENTS.md still instructs users to select a nonexistent `UUSwiftBluetooth` scheme.

**Suggestion:** Finish migrating active live-test call sites and remove the unconditional live-test build entry from the unit-test path if it is not needed. Update the documented command to the actual shared scheme. Old references inside commented-out unit tests are not themselves compilation failures.

**Regression:** Run the unit plan from a clean checkout without building or running hardware-dependent test targets unnecessarily.

### 3. [P1] Disconnect permanently drops outstanding operation completions

**Locations:** [`UUPeripheral.swift:164`](../Library/Peripheral/UUPeripheral.swift#L164), [`UUPeripheral.swift:943`](../Library/Peripheral/UUPeripheral.swift#L943), [`UUCBPeripheralBlockDelegate.swift:51`](../Library/Delegates/UUCBPeripheralBlockDelegate.swift#L51).

Start a characteristic read, then disconnect before its response. `cleanupAfterDisconnect()` cancels every timer and `clearBlocks()` discards every pending operation callback. Only the connection-level `disconnected` callback is invoked. The read's completion will never execute, including its timeout. Discovery, writes, RSSI, notify-state changes, and channel opening have the same exposure.

**Suggestion:** Finish pending one-shot operations exactly once with an appropriate disconnection/cancellation error before releasing their state. Keep persistent notification subscribers distinct from outstanding requests. Document ordering relative to the connection-level callback.

**Regression:** Disconnect during every operation family and assert one terminal callback per outstanding request, no success afterward, and no retained completion.

### 4. [P1] Overlapping operations overwrite handlers or cancel another request's timeout

**Locations:** [`UUPeripheral.swift:249`](../Library/Peripheral/UUPeripheral.swift#L249), [`UUPeripheral.swift:541`](../Library/Peripheral/UUPeripheral.swift#L541), [`UUPeripheral.swift:920`](../Library/Peripheral/UUPeripheral.swift#L920), [`UUCBPeripheralBlockDelegate.swift:30`](../Library/Delegates/UUCBPeripheralBlockDelegate.swift#L30).

Discovery/notify-state/RSSI/channel-open operations each have one delegate slot per peripheral. A second request overwrites the first completion. Even characteristic reads with different UUIDs share the `readCharacteristic` timer identifier: reading A then B replaces A's timer, and A's completion cancels B's timer. A later missing response can therefore wait forever. Connection registration similarly replaces callbacks for a second `connect` to the same identifier. No busy rejection, request queue, or public serialization contract prevents these calls.

**Suggestion:** Either enforce one active operation in the relevant scope with an explicit busy error, or serialize requests and give each accepted request independent completion/timer ownership. Do not merely document single-thread use: sequential calls can still overlap asynchronously.

**Regression:** Issue two reads on different characteristics, two discoveries, and two connects before the first completes; each accepted request must receive its own terminal result.

### 5. [P1] A late response after timeout can complete the next request

**Locations:** [`UUPeripheral.swift:271`](../Library/Peripheral/UUPeripheral.swift#L271), [`UUPeripheral.swift:570`](../Library/Peripheral/UUPeripheral.swift#L570), [`UUCBPeripheralBlockDelegate.swift:283`](../Library/Delegates/UUCBPeripheralBlockDelegate.swift#L283).

Timeout is synthesized by calling the same delegate handler used for a real response. After request A times out, its caller can start B and install a replacement handler. A delayed response to A then consumes B's handler and cancels B's timer. This occurs even when callers serialize their work and only retry after A's completion. There is an additional race when timeout queues a synthetic handler call, the real callback completes A first, and that queued synthetic call subsequently consumes B.

**Suggestion:** Use request identity for locally scheduled terminal work, and define a recovery boundary for indistinguishable native responses after timeout. A generation token alone cannot identify which request produced a native callback; draining/resetting the relevant connection or refusing a conflicting retry may be necessary.

**Regression:** Deliver A's response after A timed out and B started; verify B cannot complete with A's data/error. Also interleave queued timeout delivery with a real success.

### 6. [P1] GATT UUID keys conflate distinct attributes

**Locations:** [`UUCBPeripheralBlockDelegate.swift:92`](../Library/Delegates/UUCBPeripheralBlockDelegate.swift#L92), [`UUCBPeripheralBlockDelegate.swift:130`](../Library/Delegates/UUCBPeripheralBlockDelegate.swift#L130), [`UUPeripheralSession.swift:23`](../Library/Session/UUPeripheralSession.swift#L23), [`UUPeripheralSession.swift:434`](../Library/Session/UUPeripheralSession.swift#L434).

Read/write/notification maps use only the attribute UUID string. Two characteristics with the same UUID in different services overwrite each other's notification handlers. Descriptors such as `2901` or `2902` commonly repeat across characteristics, so their pending read/write handlers also collide. Session lookup flattens service dictionaries and returns the first matching characteristic UUID, while descriptor results are keyed only by characteristic UUID. The wrong attribute can be selected or receive a callback.

**Suggestion:** Preserve attribute identity and its service/characteristic context. Add context-bearing session lookup APIs while retaining existing convenience APIs with defined ambiguity handling. Service UUID alone is not a complete identity if repeated service instances are supported.

**Regression:** Construct two services with equal characteristic UUIDs and repeated descriptor UUIDs; verify independent notifications, reads, writes, and discovered results.

### 7. [P1] Restarting a scan can steal the delegate from an active peripheral

**Locations:** [`UUCoreBluetoothPeripheralScanner.swift:59`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L59), [`UUCoreBluetoothPeripheralScanner.swift:160`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L160), [`UUCoreBluetoothPeripheralScanner.swift:180`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L180), [`UUPeripheral.swift:36`](../Library/Peripheral/UUPeripheral.swift#L36).

Every scan start clears the wrapper cache. If an app retains a connected peripheral/session from the previous scan, rediscovering that identifier creates another `UUPeripheral` for the same native peripheral. Its initializer replaces `underlyingPeripheral.delegate`. Responses now reach the new wrapper, while the old wrapper still owns pending requests. Both wrappers also use the same globally named timer pool and timer identifiers, allowing one wrapper to cancel the other's timers.

**Suggestion:** Maintain canonical wrapper/delegate ownership for a native peripheral across scan-list resets, or explicitly separate discovery views from the object owning the connection. Include manager/instance ownership in timer storage where independent stacks are supported.

**Regression:** Keep a connected session, restart scanning, rediscover its peripheral, then complete an existing read and receive a notification on that session.

### 8. [P1] Shared state is accessed on caller, delegate, and timer queues without isolation

**Locations:** [`UUCentralManager.swift:86`](../Library/Central/UUCentralManager.swift#L86), [`UUCentralManager.swift:216`](../Library/Central/UUCentralManager.swift#L216), [`UUPeripheral.swift:144`](../Library/Peripheral/UUPeripheral.swift#L144), [`UUCoreBluetoothPeripheralScanner.swift:150`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L150).

Public entry points mutate connection maps, delegate slots, scan state, and listener dictionaries on the caller's queue. Native callbacks and timers access the same state on the private central queue. A normal main-thread call concurrent with a callback is enough to race; clients do not need to call the library from several queues themselves. Scanner writes lock the peripheral map but `getPeripheral` reads it without that lock; `peripherals` and configuration are also shared. The stack's creation lock does not protect this operational state.

**Suggestion:** Choose one execution context for each manager/peripheral state machine and marshal both public work and delegate/timer events onto it. Publish consistent snapshots for synchronous getters and state the completion queue contract. Ensure callbacks can reenter APIs without corrupting state or deadlocking.

**Regression:** Exercise public calls and mock callbacks on different queues under Thread Sanitizer, including register/listen, scan stop/start, and operation completion.

### 9. [P1] Combined discovery loses errors and can complete more than once

**Location:** [`UUPeripheral.swift:441`](../Library/Peripheral/UUPeripheral.swift#L441).

`discoverAllServicesAndCharacteristics` ignores the error returned by `discoverNextCharacteristics`, disconnects, and completes with only the disconnect error. A failed characteristic discovery followed by a clean disconnect is reported as success. A service-discovery error instead invokes completion and returns without disconnecting; a later disconnect invokes completion again. The nil-services path similarly completes without teardown. The supplied timeout is also not forwarded to `discoverServices`.

**Suggestion:** Route all branches through one terminal path, preserve the discovery error across teardown, honor the supplied timeout policy, and define connection ownership explicitly.

**Regression:** Inject service failure, characteristic failure, nil services, and disconnect failure; assert exactly one result, the original meaningful error, and the promised teardown.

### 10. [P2] Internal closure cycles keep managers and operations alive

**Locations:** [`UUCentralManager.swift:50`](../Library/Central/UUCentralManager.swift#L50), [`UUPeripheralOperation.swift:28`](../Library/Operations/UUPeripheralOperation.swift#L28), [`UUBluetoothSniffer.swift:260`](../Library/Sniffer/UUBluetoothSniffer.swift#L260).

The central owns its delegate, and `centralStateChangedBlock = handleCentralStateChanged` retains the central through the bound method. That cycle exists even if scanning never starts. An operation owns a session whose `started` and `ended` closures strongly capture the operation; neither is cleared at completion. The sniffer has the same owner/delegate/bound-method cycle. Releasing configured stacks or completed operations therefore does not release their object graphs as callers would expect.

**Suggestion:** Use weak owner captures for persistent back-references and release one-shot callbacks at terminal completion. Define explicit stop/close behavior for active resources, without relying on deinit to break an existing cycle.

**Regression:** Hold weak references to an initialized custom stack's manager, a completed operation, and a stopped sniffer; release owners and assert deallocation.

### 11. [P2] Scanner startup while the central is unknown can cancel its own deferred scan

**Locations:** [`UUCoreBluetoothPeripheralScanner.swift:35`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L35), [`UUCoreBluetoothPeripheralScanner.swift:61`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L61), [`UUCoreBluetoothPeripheralScanner.swift:107`](../Library/Scanning/UUCoreBluetoothPeripheralScanner.swift#L107).

`checkCentralState` deliberately accepts `.unknown` so the central can resume scanning after power-on. However, the subscription to `@Published nearbyPeripherals` delivers its initial empty list. If that delivery reaches `notifyNearbyPeripherals` before power-on, it calls `endScanning`, which clears the central's `isScanning` intent. Power-on can no longer resume the request. Conversely, later power-off is not observed directly by the scanner, so it may remain logically scanning without an ended event when no more list updates occur.

**Suggestion:** Track manager state explicitly and distinguish a pending start from active scanning. Do not use list publication as the authority for state transitions.

**Regression:** Hold the injected central in `.unknown` through the first list publication, then power it on. Also power it off after a quiet scan and verify the chosen stop/resume contract.

### 12. [P2] Restoration callbacks are never connected to the restoring delegate

**Locations:** [`UUCentralManager.swift:59`](../Library/Central/UUCentralManager.swift#L59), [`UUCentralManager.swift:167`](../Library/Central/UUCentralManager.swift#L167), [`UUCentralManager.swift:184`](../Library/Central/UUCentralManager.swift#L184), [`UUCentralManagerDelegate.swift:236`](../Library/Delegates/UUCentralManagerDelegate.swift#L236).

The options select `UUCentralManagerRestoringDelegate`, but its `willRestoreBlock` is never assigned. `startScan` stores `willRestoreCallback` separately, and `handleWillRestoreState` has no caller. An app can opt into restoration and provide the exposed callback without ever receiving restoration state. Wiring it only when scanning starts would also miss restoration arriving during manager creation.

**Suggestion:** Wire restoration at creation and retain any early state until the appropriate consumer can receive it. Define how restored peripherals acquire wrapper/delegate ownership. Validate/reject empty restoration identifiers consistently with delegate selection.

**Regression:** Inject a restoration event before scan registration and after registration; verify state is delivered once and retained peripherals are usable.

### 13. [P2] Restarting a session carries stale error and discovery work forward

**Locations:** [`UUPeripheralSession.swift:48`](../Library/Session/UUPeripheralSession.swift#L48), [`UUPeripheralSession.swift:199`](../Library/Session/UUPeripheralSession.swift#L199), [`UUPeripheralSession.swift:258`](../Library/Session/UUPeripheralSession.swift#L258), [`UUPeripheralSession.swift:358`](../Library/Session/UUPeripheralSession.swift#L358).

`start()` reconnects without resetting `sessionEndError` or either pending discovery queue. If an earlier run fails midway, a second run appends new work behind old service/characteristic objects. A clean remote disconnect on that run can also report the prior error because `handleDisconnection` preserves any non-nil `sessionEndError`. Repeated starts while active are not rejected either and reach the callback replacement issue above.

**Suggestion:** Either make sessions explicitly single-use and reject subsequent starts, or reset all run-local state at a well-defined start boundary and guard active/ending transitions. Apply the same lifecycle decision to operation result/callback reuse.

**Regression:** Fail during discovery with work remaining, start again, and verify only current objects are processed and only the current run's error is reported.

### 14. [P1] L2CAP message timeout leaves a callback that can report success afterward

**Location:** [`UUL2CapChannel.swift:132`](../Library/L2Cap/UUL2CapChannel.swift#L132).

The timeout closure calls `completion(nil, nil, error)` but never clears `dataReceivedCallback`. A later response invokes the same completion again with success. All messages share one callback and timer, so overlapping messages overwrite each other. The response callback is installed only after the write callback; a timed-out write can still install it later. On the success path it is cleared after calling user code, so a reentrant send whose write completion runs immediately can have its new handler erased by the old completion path.

**Suggestion:** Establish request state before writing, serialize or reject overlap, and atomically take/clear the completion before invoking it. Cancel pending state on timeout/close and define how late bytes are discarded or resynchronized.

**Regression:** Timeout then deliver data; complete a write after timeout; start a second request from completion. Assert one result per accepted message and no cross-request response.

### 15. [P2] L2CAP has no usable close/error lifecycle and does not resume partial writes

**Locations:** [`UUL2CapChannel.swift:100`](../Library/L2Cap/UUL2CapChannel.swift#L100), [`UUL2CapChannel.swift:265`](../Library/L2Cap/UUL2CapChannel.swift#L265), [`UUL2CapChannel.swift:330`](../Library/L2Cap/UUL2CapChannel.swift#L330), [`UUL2CapChannel.swift:464`](../Library/L2Cap/UUL2CapChannel.swift#L464).

`closeStreams` is private and never called. There is no public close or deinit cleanup. EOF and stream-error handlers are empty, so pending messages wait for their timer, or forever with timeouts disabled. Opening again replaces the channel without closing the previous streams. The write helper exits when no space is initially available or when `write` returns zero/negative; `.hasSpaceAvailable` does nothing, so an interrupted write is never resumed. `sendMessage` proceeds to wait for a response even when sending returned nil or only a partial byte count. Calling it before opening returns `(nil, nil, nil)`.

**Suggestion:** Add an idempotent close/terminal path that unschedules streams, cancels debounce/timers, and completes pending work with a useful error. Track unsent bytes and resume on writable events, or explicitly expose partial-send failure instead of treating it as a sent message.

**Regression:** Cover initial backpressure, partial write then zero, write error, EOF, explicit close, reopen, and send-before-open with in-memory/fake streams.

### 16. [P2] Stopping the L2CAP server during startup does not stop startup

**Locations:** [`UUL2CapServer.swift:52`](../Library/L2Cap/UUL2CapServer.swift#L52), [`UUL2CapServer.swift:89`](../Library/L2Cap/UUL2CapServer.swift#L89), [`UUL2CapServer.swift:142`](../Library/L2Cap/UUL2CapServer.swift#L142).

Call `start`, then `stop` before a PSM has been published. `stop` only performs manager teardown when both manager and PSM exist; it does not cancel the startup timer or pending power/publish callbacks. The next power-on event can continue publishing and advertising after stop. `cancelStart` also omits `didPublishServiceBlock`, allowing a late service callback to continue an already timed-out startup. The unpublish callback is retained after use and captures the server, and old PSM state is not reset.

**Suggestion:** Give startup/stop one state machine, invalidate pending startup callbacks on stop, ignore stale manager/generation events, clear the PSM and all terminal closures, and release the manager even when publishing never completed.

**Regression:** Stop at each startup stage and deliver late power, publish-service, advertise, and unpublish callbacks. Verify the server stays stopped and startup completes at most once.

### 17. [P2] Optional representation names fail their own Codable round trip

**Locations:** [`UUDescriptorRepresentation.swift:109`](../Library/Models/UUDescriptorRepresentation.swift#L109), [`UUCharacteristicRepresentation.swift:143`](../Library/Models/UUCharacteristicRepresentation.swift#L143), [`UUServiceRepresentation.swift:145`](../Library/Models/UUServiceRepresentation.swift#L145).

All three classes expose optional `name`, default it to nil, and encode that nil as JSON null. Their decoders then require `decode(String.self, forKey: .name)`. `JSONDecoder().decode(T.self, from: JSONEncoder().encode(T(uuid: ...)))` therefore throws for every default unnamed instance. The focused probe reproduced all three failures. Missing names fail as well.

**Suggestion:** Decode optional names with `decodeIfPresent` and preserve backward compatibility for absent/null values. Separately decide whether the newly required peripheral `name` should accept older exports lacking that key; that format change needs a migration decision.

**Regression:** Round-trip each representation with nil and non-nil names, decode absent/null name keys, and round-trip a nested tree.

### 18. [P2] Mock error configuration changes the most recently created peripheral's central

**Location:** [`UUMockPeripheral.swift:18`](../Library/Mocks/UUMockPeripheral.swift#L18).

Every mock initializer assigns its manager to the global `mockCBCentral`. The `mockCallbackError` setter then updates that global manager instead of the current instance's manager. Create A, create B, set A's error: A's peripheral operations fail, but B's central connect/disconnect behavior changes. A's connection can still succeed. Parallel or multi-device tests become order-dependent.

**Suggestion:** Store the injected mock central on the owning instance and forward configuration to that instance only. Remove global last-created-manager coupling from both mock constructors.

**Regression:** Create A and B, set independent errors and delays, connect/disconnect both in each construction order, and verify isolation.

### 19. [P2] Mock central construction activates a real CoreBluetooth manager

**Location:** [`UUMockCBCentralManager.swift:38`](../Library/Mocks/UUMockCBCentralManager.swift#L38).

The mock creates a real `CBCentralManager` with the production delegate as a backing object, despite advertising synthetic powered-on/authorized state. Native state callbacks can enter the same delegate used by mock operations, so device-independent tests still depend on real manager lifecycle and authorization setup. Synthetic callbacks also use a separate mock queue instead of the injected queue. Private KVC-based `CBPeripheral` construction is another fragile part of this test seam.

**Suggestion:** Separate event delivery from the need to instantiate a live manager; fake the observable manager capabilities and dispatch deterministically on the configured test context. If native callback bridge tests remain necessary, isolate them from the pure unit suite.

**Regression:** Construct and use mock stacks without creating a native manager; drive all state/events explicitly and assert deterministic ordering.

### 20. [P2] Friendly-name comparison says equal names precede each other

**Location:** [`UUPeripheralSorting.swift:149`](../Library/Peripheral/UUPeripheralSorting.swift#L149).

`.orderedSame` returns `true`. Two peripherals named `Sensor`, including comparing a peripheral with itself, therefore compare less-than in both directions. This violates the ordering contract expected by `sorted(by:)`; equal names are a routine discovery case. The focused probe reproduced `true` for both ascending and descending comparisons. Existing tests use four distinct names and miss the boundary.

**Suggestion:** Return false for equal names, or use a consistent secondary key when deterministic ordering among equal names is desired.

**Regression:** Test self-comparison, identical names, empty names, and symmetry in both directions.

### 21. [P2] Stopping a deferred sniffer start still permits a later scan

**Location:** [`UUBluetoothSniffer.swift:282`](../Library/Sniffer/UUBluetoothSniffer.swift#L282).

Starting while the manager is not powered on sets `startOnPowerOn = true`. `stop()` stops the native scan and ends the summary without clearing that flag. A later power-on callback calls `start` again, initiating a scan after the caller has stopped it. Summary replacement, capture, and export also lack one shared synchronization policy: app calls can access the results while the delegate queue appends.

**Suggestion:** Clear pending-start intent on stop and serialize session transitions and summary snapshots. CSV output should escape names containing commas, quotes, or newlines rather than joining raw fields.

**Regression:** Start while off, stop, then power on and assert no scan; export a stable snapshot while advertisements are arriving.

### 22. [P2] Notification handlers change before enable/disable succeeds

**Location:** [`UUPeripheral.swift:479`](../Library/Peripheral/UUPeripheral.swift#L479).

Enabling installs the update handler before validation/native success, and disabling removes it before success. If disable fails, the peripheral can still be notifying but the caller's handler has already disappeared. If enable fails, a handler remains retained for a subscription that was never established. A synthetic read timeout also goes through `handleCharacteristicValueUpdated`, which forwards that read error to an unrelated persistent notification handler.

**Suggestion:** Commit or roll back subscription changes according to the notify-state result, preserving the previous subscription on failure. Separate locally generated read failures from unsolicited value events.

**Regression:** Failed enable, failed disable with an existing subscription, and a timed-out read on a notifying characteristic; assert only the intended callbacks and ownership changes occur.

### 23. [P2] Descriptor lookup failures expose the wrong public error code

**Location:** [`Error+Ext.swift:125`](../Library/Extensions/Error+Ext.swift#L125).

`uuRequiredDescriptorNotFoundError` attaches descriptor context but returns `.characteristicNotDiscovered`. The public enum has a distinct `.descriptorNotDiscovered` case, so downstream code branching on the error code cannot distinguish the failure correctly.

**Suggestion:** Return the descriptor-specific code while preserving the descriptor context.

**Regression:** Read/write an undiscovered descriptor and assert its public error code and metadata.

## Additional API, sample, and coverage notes

These are follow-up design/documentation items, not additional P1 findings.

- **Previous review reconciliation:** `UUCoreBluetoothStack` uses `creationLock` and computed get-only manager/scanner properties, resolving Review 001's lazy initialization race and public setter findings. Authorization is still explicit on the stack protocol. Sample facade usage is migrated and the sample compiles. The concrete `UUCentralManager` requirement remains restrictive for independently authored implementations, but `UUMockCentralManager().mockCentral` is a public construction route; it would be inaccurate to say no external mock-backed stack can be assembled at all. Its present mock implementation has findings 18–19 above.
- **Observation lifetime:** `UUManagerStateMonitor.registerForStateChanges` documents later deregistration, but neither protocol nor manager exposes removal. A registration with a unique identifier retains its handler for the manager's lifetime. Add removal or a cancellation token and specify initial-state delivery and callback queue.
- **Mutable backend replacement:** `UUPeripheral.underlyingPeripheral` remains publicly writable. Assigning a replacement does not install the wrapper's delegate or rebuild its original timer pool. Prefer read-only ownership, or a controlled replacement operation with explicit teardown/migration.
- **Write-without-response contract:** `UUPeripheral.writeValueWithoutResponse` does not use the protocol's `canSendWriteWithoutResponse` property, and the readiness callback is commented out. Decide whether this is a deliberately raw send-attempt API or a queued reliable local submission API; document backpressure and validate maximum length accordingly. Completion currently means only that the wrapper invoked the native write path, not peer receipt.
- **Discovery semantics:** Scanner filters are reapplied on every advertisement, contrary to the config comment promising that a discovered peripheral remains until an out-of-range filter removes it. No such out-of-range API is present. Session discovery accepts empty/missing requested attributes until a later lookup fails; clarify whether configured UUIDs are filters or required attributes.
- **Names and serialization:** Both `UUPeripheralRepresentation(from:)` and `UUExportPeripheralOperation.execute` omit the peripheral name. Import-to-mock also ignores the stored name. `UUMockPeripheral` accepts `friendlyName` but never applies it. Common-name registration stores the input string, whereas lookup uses `uuidString`; normalize the stored key so lowercase custom UUIDs round-trip to their registered name. `CBUUID.uuCreate` supports 16-bit/full UUID strings but not 32-bit strings; document or extend that accepted-input contract.
- **Session convenience APIs:** The Int64 reader is accidentally named `readInt32`, producing confusing overloads. Invalid string decoding can return nil with nil error; decide whether callers should receive a conversion error. Keep any corrected names source-compatible with forwarding/deprecation where appropriate.
- **L2CAP framing:** Client response completion is inferred from one second without incoming bytes. That is a heuristic, not a message boundary: one response with a longer inter-chunk pause can be truncated, and separate messages can merge. Expose stream bytes or provide an explicit framing policy. The sample's `UUL2CapCommand.createToReceive` rejects a header-only chunk (`count > 16`), and its controller discards incomplete headers instead of buffering them; coalesced commands are not split. Its command decoder also omits `ackImage`. These make the sample unsuitable as a robust framing reference without follow-up.
- **Sample read behavior:** `ReadDeviceInfoOperation` discards read errors and reports success with empty strings; it treats System ID as UTF-8. L2CAP settings reads use unchecked loads, and encryption decoding tests `== 0`, reversing the server's encoded Bool. Add length checks and correct the decoding before using this example for device interoperability.
- **Documentation accuracy:** README advertises async/await APIs that are not implemented, lists macOS 10.13 versus the manifest's macOS 13, and advertises Swift 5.3 despite a tools-version 6.0 manifest. The shared scheme name in AGENTS.md is stale. Update these as part of the next implementation/documentation pass.
- **Coverage:** The delegate tests exercise individual callback forwarding, but do not establish wrapper timer ownership, overlap, timeout/retry, disconnect completion, or deallocation. The two session tests are inside a block comment. Sorting tests contain no equal-name case; representation round trips and L2CAP lifecycle need focused coverage. The package defines no SwiftPM test target, and the local workflows publish/tag rather than run these checks. Tests should target the failure scenarios above with explicitly driven events rather than longer sleeps.
- **Logging:** GATT writes log full payloads, central discovery logs advertisement dictionaries, and export logs the whole representation. Consider a payload-redaction/opt-in policy before consumers use the library with sensitive device data. This review does not assert that any particular application currently writes secrets.

## Recommended implementation order

1. Restore macOS compilation and the unit-test entry point; retain the successful iOS sample build as a separate check.
2. Establish callback/timer ownership and one execution context, including overlap policy, disconnect draining, late callbacks, and canonical peripheral ownership.
3. Fix combined discovery, closure cycles, session restart rules, and restoration wiring.
4. Repair L2CAP message completion, stream backpressure, close behavior, and server startup cancellation; then validate framing against controlled peers.
5. Fix representation/error/sorting boundaries, isolate mocks, and turn the listed regression scenarios into deterministic tests.

Add async alternatives only after the corresponding callback contract has tests for exactly-once completion, cancellation, and cleanup. This ordering addresses observable correctness while preserving the useful native concepts and existing public entry ?>,
