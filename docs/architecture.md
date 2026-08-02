# Architecture

See `docs/product-charter.md`.

MVC · app + Live Activity widget extension · no SPM packages yet (DriveCheckKit planned).

```
RegionalCheck/
  App/           lifecycle, CarPlay, Theme, MainTabView root
  Views/         HomeView (Status tab), RegionsView, StatusView, StatusController, paywall
  Data/          AlertRegion, AlertsSnapshot, StatusProviding, Ubilling,
                 RegionStore / RegionSelection / RegionTracker / AlertRegionResolver,
                 LocationManager, ReverseGeocoding
  Subscription/  StoreKit 2 protocols, service, cache, manager
  LiveActivity/  Activity attributes + session controller
  Resources/
RegionalCheckWidgets/
  Live Activity UI (Lock Screen, Dynamic Island, small family)
Tooling/
  ios-agent-harness Runtime (just API, doctor, verify)
```

Shared `provider` / `location` / `regions` / `status` / `subscription` / `liveActivity` live in `RegionalCheckApp.swift` (`AppDependencies`) for phone + CarPlay.

## Data flow

```text
Ubilling JSON ──► AlertsSnapshot [AlertRegion: AlertStatus]
                         │
GPS ──► RegionTracker ──► selectedRegion ──► StatusController (local select)
                         │                         │
                    Regions list ◄─────────────────┘
```

One network fetch fills all regions. Tab **Regions** reads the same snapshot (no extra request). Region switch applies snapshot immediately, then refreshes in the background.

Phone shell: `MainTabView` → Status | Regions. Onboarding and screenshot roots stay above the tab shell. CarPlay stays a single information template (no full region list while driving).

## Docs map

| Topic | Doc |
|-------|-----|
| Region catalog, resolver, hysteresis | `docs/region-model.md` + ADR 0002 / 0003 / 0005 |
| Ubilling limits / polling rationale | `docs/aerial-alerts-provider.md` |
| Analytics / privacy labels | `docs/analytics.md` |
| StoreKit / Pro | `docs/storekit-subscription-plan.md`, `README_Subscriptions.md` |
| Agent pilot | `docs/agent-pilot-brief.md`, root `AGENTS.md` |

Smoke: `./scripts/smoke-tests.sh`
