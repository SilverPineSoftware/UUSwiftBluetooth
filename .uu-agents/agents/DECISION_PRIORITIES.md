# Decision Priorities

Use this order when making implementation decisions. A lower item does not justify violating a higher one.

## Priority 1: Correctness and Safety

Make behavior correct, predictable, and safe. Do not trade correctness for cleverness, brevity, or abstraction.

## Priority 2: Native Platform Behavior

Prefer the platform's standard APIs and language features when they clearly meet the need. Add a UU layer only when it provides concrete value while preserving useful platform concepts.

## Priority 3: Clear Contracts

Make inputs, outputs, nullability, errors, side effects, ownership, cancellation, and threading clear where relevant. Preserve existing public behavior unless the task calls for changing it.

## Priority 4: Readability and Simplicity

Prefer obvious code and the smallest design that solves the problem well. Avoid broad rewrites, generalized frameworks, and speculative extensibility.

## Priority 5: Reuse and Testability

Reuse is valuable when it captures repeated behavior, shared policy, validation, or useful test seams. Do not create reusable abstractions for hypothetical reuse alone.

## Priority 6: Performance

Address demonstrated performance needs or clear risks. Do not make code harder to understand for theoretical gains.
