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

## Notes

- Prefer `just …` over raw `xcodebuild`.
- `.cursor/` local only; `AGENTS.md` may be committed.
- Ask before build, test, commit, push.
