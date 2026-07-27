# regional-check — agent notes

**Pilot lab** for iOS Engineering Runtime. Full instructions for agents:

→ **[docs/agent-pilot-brief.md](docs/agent-pilot-brief.md)** (read first)

## Project

- Product: Drive Check (display name); App Store Name: Drive Check UA
- Repo / scheme: `regional-check` / `RegionalCheck` (see `runtime.yml`)
- Context: `.cursor/project-context` → `personal`
- Simulator: `iPhone 17`

## Config

Source of truth: `runtime.yml` (overrides: `runtime.local.yml`).

## Definition of Done

```bash
just verify
```

## Commands

```bash
just doctor
just doctor --json
just diagnose
just format
just lint
just build
just test
just verify
```

## Release / TestFlight

- App Store: **1.0** live (or Ready); **1.1** submitted / in review (build **18**). Repo next: **1.2** / build **1**.
- New marketing version → reset `CURRENT_PROJECT_VERSION` to **1** (builds do not carry over from the previous marketing version).
- Same marketing version → bump `CURRENT_PROJECT_VERSION` above the highest build already uploaded for that version.
- Before Archive → ASC / TestFlight: `MARKETING_VERSION` must be above what is already live or in flight when starting a new version line.
- Symptom if forgotten: Xcode Cloud Archive fails with **Preparing build for App Store Connect failed** (`action_required`) while Test still passes and local archive succeeds.

## Notes

- Prefer `just …` over raw `xcodebuild`.
- Git hooks (optional): `./scripts/install-hooks.sh` — pre-commit = format+lint, pre-push = smoke tests.
- `.cursor/` local only; `AGENTS.md` may be committed.
- Ask before build, test, commit, push.
