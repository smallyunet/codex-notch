---
status: active
contract_ids: [PRIVACY-BOUNDARY-003, UPDATE-CHECK-007]
supersedes: []
superseded_by: null
owner: project-maintainer
created_at: 2026-07-20
last_verified_commit: pending
---

# Use a manual, informational GitHub release check

## Context

CodexNotch previously exposed no installed version or way to discover a newer release. Users had to visit the repository and compare versions themselves. A full updater would add persistence, executable replacement, signing complexity, and a larger network and dependency surface.

## Decision

- Show `CFBundleShortVersionString` in the existing status menu.
- Check the fixed CodexNotch `releases/latest` GitHub API endpoint only after the user selects **Check for Updates**.
- Use an ephemeral, uncached session without cookies or authentication and restrict redirects to the original HTTPS host.
- Accept a release page only when it is HTTPS and belongs to the CodexNotch repository on `github.com`.
- Report available, current, and failure states in the menu; open the verified release page only on an explicit click.
- Do not download, install, relaunch, or periodically check for updates.

## Rejected alternatives

- **Sparkle or another updater framework:** unnecessary for an informational check and increases supply-chain and runtime scope.
- **Automatic checks at launch:** creates background network traffic the user did not request.
- **Direct in-app replacement:** an ad-hoc-signed app cannot provide the release integrity and Gatekeeper experience expected of a silent updater.

## Consequences

The app contacts `api.github.com` only after a visible user action. Updating remains a deliberate download-and-install operation through the GitHub release page.
