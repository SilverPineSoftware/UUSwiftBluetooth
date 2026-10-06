# Anti-Patterns

Avoid these patterns unless the task requires them and their tradeoffs are documented.

## Wrapper-Only Renaming

Do not wrap a native client or type merely to give it a UU name. A wrapper is appropriate when it adds useful reusable behavior such as policy, validation, safety, logging controls, or test seams.

## Generic Utility Dumps

Avoid catch-all utility containers that collect unrelated functions. Prefer focused types or extensions organized around a clear concept.

## Framework Architecture for Small Problems

Do not introduce registries, dependency containers, middleware stacks, plugin systems, or other framework structures for simple behavior.

## Hidden Side Effects

Avoid APIs that hide consequential behavior. Callers should be able to predict network calls, disk writes, credential access, retries, thread or dispatcher changes, and resource closure.

## Ambiguous Error States

Do not make callers infer whether null, an empty value, a default, or a failure represents a particular outcome. Represent distinct outcomes distinctly and document the contract.

## Broad Rewrite During Focused Work

Do not rewrite unrelated code while implementing a focused change. Change adjacent callers or contracts when needed to keep the requested behavior correct and coherent.
