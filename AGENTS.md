# regional-check — agent notes

**Pilot lab** for iOS Engineering Runtime. Full instructions for agents:

→ **[docs/agent-pilot-brief.md](docs/agent-pilot-brief.md)** (read first)

## Project

- Product: Drive Check (display name); App Store Name: DriveCheckUA
- Repo / scheme: `regional-check` / `RegionalCheck` (see `Tooling/runtime.yml`)
- Context: `.cursor/project-context` → `personal`
- Simulator: `iPhone 17`
- Runtime: `Tooling/` (ios-agent-harness **0.2.2**)

## Config

Source of truth for scheme / simulator / backend: [`Tooling/runtime.yml`](Tooling/runtime.yml) (overrides: `Tooling/runtime.local.yml`).

Style (app-owned): [`Tooling/.swiftlint.yml`](Tooling/.swiftlint.yml), [`Tooling/.swiftformat`](Tooling/.swiftformat) — how to change: [`Tooling/docs/style-config.md`](Tooling/docs/style-config.md).

## Definition of Done

```bash
just verify
```

Technical DoD only (Runtime). Before commit: Brain runs defect-first **automatically**, reports findings, fixes only after owner OK.

## Commands

```bash
brew bundle --file=Tooling/Brewfile
just doctor
just doctor --json
just diagnose
just format
just lint
just build
just test
just verify
just run-sim
just scenario allClear
just scenario alertActive
just paywall
just screenshots
```

App-local recipes live in the root `justfile` (`import 'Tooling/justfile'`). Do not hand-edit `Tooling/scripts/` / `Tooling/backend/` — use `just harness-update`.

## Release / TestFlight

- App Store: **1.0** live (or Ready); **1.1** submitted / in review (build **18**). Repo next: **1.2** / build **1**.
- New marketing version → reset `CURRENT_PROJECT_VERSION` to **1** (builds do not carry over from the previous marketing version).
- Same marketing version → bump `CURRENT_PROJECT_VERSION` above the highest build already uploaded for that version.
- Before Archive → ASC / TestFlight: `MARKETING_VERSION` must be above what is already live or in flight when starting a new version line.
- Symptom if forgotten: Xcode Cloud Archive fails with **Preparing build for App Store Connect failed** (`action_required`) while Test still passes and local archive succeeds.

## Notes

- Prefer `just …` over raw `xcodebuild`.
- Git hooks (optional): `./scripts/install-hooks.sh` — pre-commit = `just format`+`just lint`, pre-push = smoke tests.
- App-local scripts under root `scripts/`: `capture-app-store-screenshots.sh`, `install-hooks.sh`, `smoke-tests.sh`.
- `.cursor/` local only; `AGENTS.md` may be committed.
- Ask before build, test, commit, push.

## Planned: StoreKit 2 (Pro)

Implemented on this branch: **[docs/storekit-subscription-plan.md](docs/storekit-subscription-plan.md)** + **[README_Subscriptions.md](README_Subscriptions.md)**.  
Phase scope: StoreKit + symbolic Pro (Live Activity, badge, extended detail). Notifications not included.
