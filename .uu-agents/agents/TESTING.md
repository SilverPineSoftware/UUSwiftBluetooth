# Testing Guidance

Tests describe public expectations and protect against regressions. Choose a test type that matches the behavior and its dependencies.

## Test Behavior, Not Implementation

Verify observable outcomes and public contracts. Avoid coupling tests to private implementation details unless no practical alternative exists.

## Focused Coverage

Add focused tests for new behavior, edge cases, failures, compatibility risks, boundaries, and concurrency behavior where relevant. Include resource ownership, cancellation, and partial side effects when they are part of an API contract.

## Unit Tests

Unit tests should be deterministic, fast, and isolated from external services. Use real implementations when simple and reliable; use fakes, stubs, or mocks when they clarify behavior or isolate external systems. Avoid arbitrary sleeps, timing assumptions, and order dependencies.

## Integration Tests

Use integration tests for behavior that depends on an actual platform, network service, filesystem, emulator, or other external system. Keep these tests identifiable and document their prerequisites, configuration, and invocation. Prefer controlled test services or fixtures over public endpoints when practical. Do not make a network-dependent integration test masquerade as a deterministic unit test.

If the required device, credentials, network, service, or platform is unavailable, report the test as not run and state what was missing. Do not weaken an assertion or turn a failure into a skip merely to get a green run.

## Reporting

Report the exact checks run and whether they passed, failed, were skipped, or could not run. Do not imply broader validation than the executed commands provide.
