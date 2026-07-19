---
status: active
contract_ids: [MENU-BAR-001, PRIVACY-BOUNDARY-003]
supersedes: [001-fixed-canvas-notch-motion, 002-native-liquid-glass-with-fallback, 003-abandon-cross-window-liquid-glass]
superseded_by: null
owner: project-maintainer
created_at: 2026-07-19
last_verified_commit: 8bd1251
---

# Use a menu bar item and remove notch and session monitoring

## Context

The previous implementation used a transparent panel around the physical notch and parsed local rollout files to show active and recent conversations. That architecture created unnecessary geometry, memory, and private-message exposure risks for a quota display utility.

## Decision

- Use one `NSStatusItem` containing a system icon and the rounded remaining weekly percentage.
- Keep only the local auth reader, the read-only ChatGPT usage request, quota classification, and a small status menu.
- Remove all notch panels, SwiftUI surfaces, screen monitoring, session-log parsing, conversation navigation, and related settings.
- Use an ephemeral network session with no cache or cookies and reject redirects to a different host.

## Rejected alternatives

- **Keep the notch code disabled:** dormant privacy-sensitive code can be restored accidentally and increases review cost.
- **Keep recent conversations in the menu:** quota display does not require prompt, path, or thread access.
- **Use a web view:** it adds browser state, cookies, and a larger attack surface.

## Consequences

The app works on every supported Mac with a smaller executable and narrower data access. The menu bar appearance still requires a real macOS visual check. Historical notch decisions remain available in Git history.
