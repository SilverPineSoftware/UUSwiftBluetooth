# API Design

Public APIs should be small, predictable, discoverable, easy to compose, and difficult to misuse.

## Abstraction Test

Before adding a type, protocol, wrapper, helper, or extension, identify at least one concrete benefit:

- Shared project policy or repeated behavior
- Better correctness, validation, or safety
- A useful test seam
- A simpler call site that remains clear about important platform behavior
- A more consistent public contract across UU projects

First check whether a native API already solves the problem clearly and meets the project's needs. If it does, prefer it directly. If not, a focused abstraction is reasonable when it adds one of the benefits above. Do not justify an abstraction only with possible future extensibility.

## UU Wrappers

A good UU wrapper adds behavior or a contract while preserving relevant native concepts. Avoid wrappers whose only purpose is renaming, concealing platform behavior, or making code look uniform without helping callers.

## Public Contracts

Make nullability, default values, errors, side effects, resource ownership, cancellation, and threading clear when they affect callers. Keep naming direct and consistent with both UU conventions and the underlying platform's terminology.
