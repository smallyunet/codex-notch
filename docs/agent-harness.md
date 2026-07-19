---
status: active
owner: project-maintainer
created_at: 2026-07-19
last_verified_commit: 23b1418
---

# CodexNotch change harness

## Purpose

The harness protects the menu bar behavior, quota meaning, credential boundary, and release integrity. Passing compilation alone is not completion.

## Authority order

1. Active contracts in `docs/contracts/behavior-contracts.yaml`.
2. Active architecture decisions in `docs/decisions/`.
3. Tests and verification scripts.
4. Current implementation and configuration.
5. README and historical Git records.

## Risk levels

- **L0:** Documentation or comments only.
- **L1:** Local implementation with no user-visible or security effect.
- **L2:** Menu bar UI, quota semantics, settings, or packaging.
- **L3:** Authentication, privacy, external endpoints, signing, tagging, or public release.

For L1 and above, state the observable change, preserved contracts, excluded work, risk, and verification plan before editing.

## Implementation rules

1. Inspect the worktree before editing and preserve unrelated changes.
2. Add an outcome-oriented regression guard for a changed behavior.
3. Do not remove a valid regression test to accommodate a broken implementation.
4. Never log or persist tokens, Authorization headers, raw usage responses, prompts, or conversation metadata.
5. Do not restore notch windows or session-log monitoring without explicitly superseding the active contracts.
6. Do not add a new network host, dependency, telemetry, updater, or background persistence without L3 review.
7. Push, tag, or publish only when the user explicitly requests it.

## Verification entry points

| Level | Command | Purpose |
|---|---|---|
| Contracts | `./scripts/check_contracts.sh` | Validate contract structure |
| Fast | `swift test` | Run deterministic tests |
| Full | `./scripts/verify.sh` | Test, build, and inspect the app bundle |
| Release | `./scripts/release.sh` | Produce a verified ZIP and SHA-256 file |

The menu bar icon, percentage spacing, dropdown behavior, and first-launch Gatekeeper flow still require validation on a real Mac.
