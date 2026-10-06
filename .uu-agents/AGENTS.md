# Agent Instructions

This repository contains the shared AI-agent guidance for UU open-source libraries. Read these documents in order:

1. agents/MISSION.md
2. agents/DECISION_PRIORITIES.md
3. agents/RULES.md
4. agents/API_DESIGN.md
5. agents/LIBRARY_COMPATIBILITY.md
6. agents/TESTING.md
7. agents/PATTERNS.md
8. agents/ANTI_PATTERNS.md
9. agents/SWIFT.md for Swift work
10. agents/KOTLIN.md for Kotlin or Android work

Read applicable project-local AGENTS.md files too. Project guidance adds the repository's build commands, supported platforms, conventions, and exceptions. Follow a specific local rule within its stated scope; follow the shared guidance elsewhere. A direct user instruction takes precedence over these defaults unless it conflicts with a higher-priority system or safety requirement.

## Core Principle

UU libraries provide small, opinionated layers over native platform APIs. Their purpose is to improve consistency, safety, readability, and reuse without replacing or obscuring the underlying platform.

Every abstraction must have a concrete reason to exist. If a native API already solves the problem clearly and meets the project's needs, use it directly. Consider a UU abstraction when it adds identifiable value such as shared policy, validation, safety, reuse, or testability.

## When in Doubt

Choose correctness, native behavior, simple designs, explicit contracts, focused tests, and clear documentation. Avoid needless indirection, speculative generality, and unrelated rewrites.

## Adopting These Guidelines

Each UU project should keep a reviewed, version-controlled snapshot of the applicable shared guidance in its own repository, and point its root AGENTS.md to that snapshot. Include the platform guidance that applies and add a short project-specific section with supported platforms, build and test commands, and genuine local exceptions. Update snapshots through ordinary reviewable changes from this repository so agent behavior does not depend on network access or a moving branch.
