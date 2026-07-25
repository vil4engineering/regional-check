# regional-check — agent notes

**Pilot lab** for iOS Engineering Runtime. Full instructions for agents:

→ **[docs/agent-pilot-brief.md](docs/agent-pilot-brief.md)** (read first)

## Project

- Name: regional-check
- Context: `.cursor/project-context` → `personal`
- Scheme: `RegionalCheck` (see `runtime.yml`)
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

- App Store already has marketing version **1.0** (live or in review).
- Before any new Xcode Cloud Archive → App Store Connect / TestFlight upload, bump `MARKETING_VERSION` above what is already on App Store (do not ship another `1.0` prepare). Also keep `CURRENT_PROJECT_VERSION` higher than any build already uploaded for that version.
- Symptom if forgotten: Xcode Cloud Archive fails with **Preparing build for App Store Connect failed** (`action_required`) while Test still passes and local archive succeeds.

## Notes

- Prefer `just …` over raw `xcodebuild`.
- Git hooks (optional): `./scripts/install-hooks.sh` — pre-commit = format+lint, pre-push = smoke tests.
- `.cursor/` local only; `AGENTS.md` may be committed.
- Ask before build, test, commit, push.
