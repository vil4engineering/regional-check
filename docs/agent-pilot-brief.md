# Agent pilot brief — Drive Check (RegionalCheck scheme)

You are working in the **pilot lab** for the iOS Engineering Runtime (`ios-agent-harness`), not a greenfield app rewrite.

Product display name: **Drive Check**. Xcode scheme/target and Bundle ID stay `RegionalCheck` / `vil4max.RegionalCheck`.

Human goal: open this chat, watch what you do, and verify the Brain + Runtime workflow.

## Read first (in order)

1. This file: `docs/agent-pilot-brief.md`
2. Root `AGENTS.md` (thin project facts)
3. `runtime.yml` (scheme, simulator, flags)
4. `.cursor/project-context` (expect `personal`)
5. Optional: `docs/architecture.md`, `docs/product-charter.md` only if the task needs product context

Brain (behavior) comes from global Cursor rules/skills (`cursor-agent-kit`). Do not copy kit policy into this repo.

## Stack / facts

| Item | Value |
|------|--------|
| App path | `~/Developer/GitHub/vil4engineering/regional-check` |
| Product name | Drive Check (CFBundleDisplayName) |
| Scheme / target | `RegionalCheck` |
| Tests | `RegionalCheckTests` |
| Simulator | `iPhone 17` (see `runtime.yml`) |
| Runtime | Installed slice (`justfile`, `scripts/`, `backend/`) |
| Context | `personal` |

## Definition of Ready (before Edit)

1. Run `just doctor` (and `just doctor --json` if you automate).
2. Run `just diagnose` if doctor warns about scheme/sim.
3. Confirm you read `AGENTS.md` + `runtime.yml`.
4. Apple `xcode-tools` MCP should stay **configured**. Healthy tools need Xcode open with this project; if not healthy, still use `just build` (xcodebuild baseline).
5. Ask the user before build, test, commit, or push.

If doctor fails, fix environment (or ask) before changing app code.

## How to run work (Runtime API)

Prefer these commands from repo root. Do **not** invent ad-hoc `xcodebuild` flags unless diagnosing a Runtime failure.

```bash
just doctor
just doctor --json
just diagnose
just format
just lint
just build
just test
just verify    # DoD: format → lint → build → test
just ci        # verify + stub CI slots
```

Config truth: `runtime.yml` (optional `runtime.local.yml`).

## Definition of Done

Technical DoD = `just verify` when the user asks for full verification.

Known pilot issue: `just test` may fail compiling `RegionalCheckTests` (`#require` macro). Report that clearly. Do not silently set `tests: false` unless the user asks.

Host-specific summaries (Cursor markdown fence) follow kit `task-completion-response` when finishing an implementation task.

## Do / Do not

**Do**

- Use Runtime (`just …`) for doctor/build/test/format/lint.
- Keep changes small; ask before business-logic or root project file changes.
- Treat `AGENTS.md` as usable/committable thin notes; `.cursor/` stays local.
- Before **push** on a fresh/new setup: check `AGENTS.md`, project-context, Runtime presence; summarize; wait for confirmation.

**Do not**

- Rewrite the app “for cleanliness” without a requested task.
- Hand-edit copied `scripts/` or `backend/` — suggest `just harness-update` / harness repo instead.
- Assume XcodeBuildMCP or xcode-tools execute is required for `just build`.
- Auto-push, force-push, merge, or rebase.
- Auto-build/test unless the user asked.

## Suggested smoke script (when user says “check runtime”)

Run in order and report a short table:

1. `just doctor` / `just doctor --json`
2. `just diagnose`
3. `just format` (show whether files changed)
4. `just lint`
5. `just build`
6. `just test` (expect possible failure — document)
7. Confirm `~/.cursor/rules` still points at `cursor-agent-kit` if relevant to the question

## What to report to the human

After any check or task:

- Commands you ran
- Pass/fail per step
- Backend selected (`xcodebuild` vs other)
- Warnings (e.g. xcode-tools not healthy)
- Files you changed (paths only)
- Blockers / next ask

## Harness source

Canonical Runtime: `~/Developer/GitHub/ios-agent-harness`  
Update slice: `just harness-update` (needs that clone or `IOS_AGENT_HARNESS_ROOT`).
