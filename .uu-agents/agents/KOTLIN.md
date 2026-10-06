# Kotlin and Android Guidance

Use this guidance for Kotlin/JVM and Android projects alongside the shared mission, rules, API, compatibility, and testing documents. Follow the module's actual target platforms; Android-specific APIs do not belong in shared JVM code.

## Preferred APIs

Prefer suitable Kotlin, Java, and Android platform APIs. Keep platform dependencies at the narrowest module that needs them. Preserve Kotlin nullability and type information in public APIs.

## Coroutines and Cancellation

Prefer structured concurrency and suspend functions for asynchronous work when they fit the surrounding API. Propagate CancellationException rather than converting cancellation into an ordinary Result failure or swallowing it. Make dispatcher changes explicit and avoid switching dispatchers without a reason.

## Results and Errors

Use Result when it matches established project APIs and callers benefit from explicit success or failure. Keep empty results, nullable absence, configured fallback values, and failures distinct when they have different meanings. Preserve the original cause when translating an exception.

## Resource Ownership

Use use blocks for resources created or owned by the function. Do not unexpectedly close caller-owned streams, files, or other resources. Document ownership, cleanup, and partial side effects, and test the ownership contract when it matters.

## Documentation

Use KDoc for public Kotlin APIs when behavior, parameters, errors, nullability, ownership, threading, or cancellation are not obvious.

## Tests

Follow the module's existing test framework. Use ordinary JVM tests for platform-independent behavior; use Robolectric only when Android framework behavior is needed, and instrumentation tests for behavior that requires a real emulator or device. Keep external service tests separate and document their prerequisites.
