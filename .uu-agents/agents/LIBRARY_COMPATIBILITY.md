# Library Compatibility

UU projects publish reusable libraries. A source change can affect downstream users even when the project itself still builds.

## Check the Contract

Before changing a public API or observable behavior, check its current callers, tests, documentation, and release or compatibility policy. Consider changes to:

- Public types, method signatures, visibility, and generic constraints
- Defaults, nullability, return values, and error behavior
- Serialization formats, enum mappings, and wire representations
- Resource ownership, cleanup, threading, and cancellation
- Minimum platform or toolchain requirements
- Published artifacts and dependency requirements

Preserve behavior by default. If the requested change is breaking, make the migration clear, update in-repository callers and tests that are in scope, and call out what downstream users must change. Do not silently adapt or weaken tests to hide a contract change.

## Resource and Error Contracts

Document who closes resources supplied by callers and who cleans up resources created by a helper. State whether operations can leave partial files, writes, or other side effects on failure.

Keep absence, empty values, fallback values, and failures distinct when callers may need to react differently. Preserve the cause and useful context when returning or translating errors. Do not claim an operation passed unless the relevant checks actually ran.

## Dependency Changes

Follow each project's dependency policy. Dependencies affect users through size, licensing, transitive resolution, security updates, and supported platforms. If the project has no policy, get maintainer approval before adding a production dependency. A direct user request to add a dependency provides that approval for the requested addition.
