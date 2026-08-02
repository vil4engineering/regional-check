# App-owned. Runtime recipes come from Tooling/.
import 'Tooling/justfile'

scenario name:
    just run-sim -- -ScreenshotPhase {{name}}

paywall:
    just run-sim -- -ShowPaywall

screenshots:
    ./scripts/capture-app-store-screenshots.sh
