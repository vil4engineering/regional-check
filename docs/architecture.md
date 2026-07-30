# Architecture

See `docs/product-charter.md`.

MVC · app + Live Activity widget extension · no SPM packages.

```
RegionalCheck/
  App/           lifecycle, CarPlay, Theme
  Views/         HomeView, StatusView, StatusController, Subscription paywall
  Data/          AlertRegion, AlertStatusSnapshot, StatusProviding, Ubilling, location, region store
  Subscription/  StoreKit 2 protocols, service, cache, manager, PremiumAccess
  LiveActivity/  Activity attributes + session controller
  Resources/
RegionalCheckWidgets/
  Live Activity UI (Lock Screen, Dynamic Island, small family)
```

Shared `provider` / `location` / `regions` / `subscription` / `liveActivity` live in `RegionalCheckApp.swift` (`AppDependencies`) for phone + CarPlay.

Flow: GPS → Region → Ubilling → All Clear / Alert Active / Checking / Unavailable

Status fetch policy and Ubilling rate limits: `docs/aerial-alerts-provider.md`

Analytics and App Store privacy labels: `docs/analytics.md`

StoreKit 2 / Pro + Live Activity: `docs/storekit-subscription-plan.md`, `README_Subscriptions.md`

Smoke: `./scripts/smoke-tests.sh`
