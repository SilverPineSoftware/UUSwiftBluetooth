# Behavioral test fixtures

Unit tests use these internal fixtures rather than the library's public preview
mocks. Keep them in the UnitTests target; production code must not depend on them.

- `TestCentralManager` implements the central injection seam without creating a
  native manager. Automatic connection results use the supplied callback queue.
  Override connect/cancel to hold responses, then use `deliverConnection`,
  `deliverConnectionFailure`, or `deliverDisconnection` on that queue to release
  them. It delivers registered library blocks, not native central delegate events.
- `TestPeripheral` provides the GATT responses used by operation tests. Its native
  peripheral is constructed by `TestShared/Mocks.swift`; the current production
  delegate API requires concrete Core Bluetooth objects. KVC and mutable GATT
  objects here are fixtures, not hardware operations.
- `HeldResponsePeripheral` and `LateResponsePeripheral` retain responses until a
  test releases them, allowing disconnect/timeout ordering to be tested directly.
- `TestPeripheralFixture` composes real `UUPeripheral` and `UUCentralManager`
  instances with the test backends for operation tests and sorting inputs. Each
  fixture owns its central backend and error configuration; no state is global.

Existing `mock…` configuration names on the fixtures are retained to keep the
migration focused. They do not refer to or inherit from public `UUMock…` types.
