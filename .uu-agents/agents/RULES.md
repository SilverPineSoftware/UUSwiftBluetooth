# Rules

These rules are intended to be applied directly by coding agents. Follow applicable platform and project-specific guidance as well.

## MUST

- MUST follow the project's structure, naming, style, supported platforms, and test organization.
- MUST keep changes focused on the requested behavior and its necessary callers, tests, and documentation.
- MUST write readable, maintainable code that follows native platform expectations.
- MUST add focused tests for new behavior and meaningful regression risks.
- MUST preserve useful error information and handle failures deliberately.
- MUST document public API behavior when its purpose, compatibility effects, errors, ownership, or concurrency expectations are not obvious.
- MUST consider public API and data-format compatibility before changing shipped behavior; explain required migration when a breaking change is requested or unavoidable.
- MUST report which checks were actually run and their results. Distinguish failures from checks that could not run.

## MUST NOT

- MUST NOT add a third-party dependency without following the project's dependency policy. If no policy is documented, get maintainer approval before adding a production dependency. An explicit user request to add that dependency is approval for that change.
- MUST NOT create wrappers that only rename native APIs.
- MUST NOT obscure standard platform concepts without concrete reusable value.
- MUST NOT perform broad unrelated rewrites.
- MUST NOT silently ignore errors or weaken tests just to make a check pass.
- MUST NOT add framework-style architecture to solve a small problem.
- MUST NOT add speculative abstractions for hypothetical future use.
- MUST NOT log credentials, tokens, private keys, or sensitive payloads.

## SHOULD

- SHOULD use explicit APIs that are difficult to misuse.
- SHOULD favor focused types with clear responsibilities.
- SHOULD test observable behavior instead of private implementation details.
- SHOULD keep tests deterministic and avoid unnecessary timing assumptions.
- SHOULD preserve caller ownership of resources unless the API clearly documents that it takes ownership.

## MAY

- MAY introduce UU abstractions when they provide shared policy, validation, safety, useful reuse, testability, or project consistency.
- MAY add convenience helpers when they significantly reduce duplication and remain easy to understand.
- MAY use third-party dependencies when they provide substantial value unavailable from suitable native APIs and the project dependency policy permits them.
