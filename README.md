# CodexNotch

CodexNotch is a small, native macOS menu bar app that shows your remaining weekly ChatGPT Codex quota as an icon and percentage.

## What it does

- Displays `68%` beside a system icon in the macOS menu bar.
- Shows the weekly reset time in a compact menu.
- Refreshes automatically every 60 seconds and supports manual refresh.
- Opens the installed ChatGPT/Codex app from the menu.
- Uses no telemetry, analytics, updater, browser view, or third-party package.

CodexNotch does not create a notch overlay, inspect conversation logs, read prompts, or store conversation metadata.

## Install

Download the latest universal macOS ZIP from [GitHub Releases](https://github.com/smallyunet/codex-notch/releases/latest), unzip it, and move `CodexNotch.app` to Applications.

The automated release is ad-hoc signed because this repository does not currently have an Apple Developer ID certificate. macOS may require Control-clicking the app and choosing **Open** on first launch.

## Authentication and privacy

CodexNotch reads `tokens.access_token` and `tokens.account_id` from `CODEX_HOME/auth.json`. When `CODEX_HOME` is not set, it uses `~/.codex/auth.json`.

The token is used only in memory for this read-only request:

```text
GET https://chatgpt.com/backend-api/wham/usage
```

The network session is ephemeral, has no response cache or cookie store, and rejects redirects to another host. Tokens, headers, and response bodies are never logged or persisted by CodexNotch.

The endpoint is an internal ChatGPT endpoint and may change without notice.

## Build and test

Requirements: macOS 14 or newer, Xcode 15 or newer, and Swift 5.9 or newer.

```sh
swift test
./scripts/verify.sh
```

Create a local universal release archive:

```sh
ARCHITECTURES="arm64 x86_64" ARCHIVE_ARCH=universal ./scripts/release.sh
```

## Release process

1. Update `CFBundleShortVersionString` in `Resources/Info.plist`.
2. Merge the verified change into `main`.
3. Create an annotated tag matching the app version, such as `v0.2.0`.
4. Push the tag.
5. `.github/workflows/release.yml` builds and verifies a universal app, creates the ZIP and SHA-256 file, and publishes both files to the GitHub Release.

The workflow rejects a tag that does not match the version in `Info.plist`.

## License

MIT License. See [LICENSE](LICENSE).
