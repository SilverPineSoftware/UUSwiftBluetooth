# Patterns

Use these patterns to guide implementation choices. Platform-specific examples belong in SWIFT.md and KOTLIN.md.

## Native First

When a platform API clearly meets the need, call it directly. If a helper is proposed, state the behavior or policy it adds and why the call site benefits.

## Thin Policy Layer

A small shared policy type can be useful when callers need the same behavior and should be able to configure or inspect it. Keep it separate from the native operation it governs unless combining them makes the contract clearer.

## Extend Familiar Types Carefully

Focused extensions can make repeated behavior easier to discover while keeping the platform type visible. Avoid extensions that duplicate obvious standard-library behavior or collect unrelated helpers.

## Decision Path

1. State the behavior the caller needs.
2. Check the native API and current project patterns.
3. If they meet the need clearly, use them.
4. Otherwise, identify the concrete value a small UU abstraction would add.
5. Keep important platform behavior visible and cover the public behavior with focused tests.
