# Swift Guidance

Use this guidance for Swift projects alongside the shared mission, rules, API, compatibility, and testing documents.

## Preferred APIs

Prefer suitable Apple frameworks and Swift features, including Foundation, URLSession, Codable, Swift Concurrency, Task, MainActor, actors, Sendable, CryptoKit, Security, XCTest, and OSLog when appropriate.

## Dependencies

Avoid third-party frameworks for problems handled well by Apple APIs. Follow the repository's dependency policy. If no policy exists, get maintainer approval before adding a production dependency; an explicit user request counts as approval for that addition.

## Concurrency

Prefer async/await and structured concurrency. Avoid custom concurrency wrappers that merely rename Task, actors, MainActor, continuations, or other native primitives. Make cancellation and actor isolation clear when they affect callers.

## Error Handling

Prefer typed errors when they help callers respond correctly. Expose useful error context, preserve underlying causes where appropriate, and do not silently swallow failures. Avoid generic Error values when a more meaningful public error type is practical.

## Extensions

Use extensions for focused reusable behavior. Avoid unrelated helpers in large catch-all extensions and avoid extensions that duplicate obvious standard-library behavior.

## Example

Use URLSession directly for a straightforward request. Add a focused UU request abstraction only when it contributes shared policy, validation, safety, or testability while keeping URLSession behavior understandable.
