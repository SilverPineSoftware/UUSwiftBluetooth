# Code and design reviews

This folder contains focused reviews of UUSwiftBluetooth APIs and design decisions. Reviews are read-only assessments unless a follow-up task explicitly requests implementation.

## Reviews

- [UUBluetooth facade and provider](001-uubluetooth-facade-provider.md) — dependency injection, default access, lifecycle risks, and comparison with Foundation.
- [Full library deep dive](002-full-library-deep-dive.md) — current stack, scanning, operation lifecycles, sessions, L2CAP, mocks, serialization, build validation, and prioritized regression scenarios; supersedes Review 001's current-state assessment.
