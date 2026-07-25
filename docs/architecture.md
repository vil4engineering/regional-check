# Architecture

See `docs/product-charter.md`.

MVC · single app target · no SPM packages.

```
RegionalCheck/
  App/       lifecycle, CarPlay, Theme
  Views/     HomeView, StatusView, StatusController
  Data/      AlertRegion, AlertStatusSnapshot, StatusProviding, Ubilling, location, region store
  Resources/
```

Shared `provider` / `location` / `regions` live in `RegionalCheckApp.swift` (`AppDependencies`) for phone + CarPlay.

Flow: GPS → Region → Ubilling → All Clear / Alert Active / Checking / Unavailable

Smoke: `./scripts/smoke-tests.sh`
