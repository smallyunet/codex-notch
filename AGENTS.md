# CodexNotch maintenance guide

## Product boundary

CodexNotch is a standalone native macOS menu bar app. It displays the remaining weekly ChatGPT Codex quota as a system icon plus percentage. It does not render a notch overlay and does not inspect Codex session or rollout logs.

## Required change harness

Before changing visible behavior, quota semantics, authentication, privacy, packaging, or release automation, read:

1. `docs/agent-harness.md`
2. `docs/contracts/behavior-contracts.yaml`
3. Relevant active records in `docs/decisions/`

State what changes, what remains unchanged, what is out of scope, the risk level, and the verification plan before editing.

## Privacy boundary

- Never commit or print `CODEX_HOME/auth.json`, access tokens, Authorization headers, complete usage responses, prompts, or conversation metadata.
- Do not add session-log scanning, telemetry, analytics, automatic updates, or third-party network destinations without an explicit contract change and review.
- Keep the production network session ephemeral and restricted to HTTPS on the original host.

## Validation

```sh
swift test
./scripts/verify.sh
./scripts/release.sh
```

`./scripts/release.sh` is only for a distributable local artifact. A pushed version tag triggers the GitHub release workflow.

Menu bar layout and first-launch Gatekeeper behavior require confirmation on a real Mac.

## Git and releases

- Preserve unrelated worktree changes.
- Keep meaningful changes in intentional commits.
- Push or publish only when explicitly requested.
- Version tags must match `CFBundleShortVersionString` and use the form `vMAJOR.MINOR.PATCH`.
