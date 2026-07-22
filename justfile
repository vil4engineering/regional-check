set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Public Runtime API — thin wrappers only.

doctor *args:
    ./scripts/doctor.sh {{args}}

env:
    ./scripts/env.sh

diagnose:
    ./scripts/diagnose.sh

format:
    ./scripts/format.sh

lint:
    ./scripts/lint.sh

build:
    ./scripts/build.sh

test:
    ./scripts/test.sh

verify:
    ./scripts/verify.sh

ci:
    ./scripts/ci.sh

clean:
    ./scripts/clean.sh

reset:
    ./scripts/reset.sh

release:
    ./scripts/release.sh

profile:
    ./scripts/profile.sh

harness-update:
    ./scripts/harness-update.sh
