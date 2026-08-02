# Release 2.0 checklist

Unified **2.0** release: audit remediation phases 0–8.

## What ships

- Region domain (25 oblasts + Kyiv), adaptive refresh, tabbed phone UI
- `DriveCheckKit` SPM + App Group `SharedStore`
- Status widget, secondary region widget (Pro), Control Center control
- App Intents / Siri shortcuts with optional region parameter
- Pro: extended detail, widget refresh, secondary pin, alternate icon
- Privacy manifests, Ubilling data disclaimer

## Before Archive

1. **Developer Portal:** App Group `group.vil4max.RegionalCheck` on app + widget extension IDs; reissue provisioning profiles.
2. **App Store Connect:** Subscription products Ready and linked to version **2.0**.
3. **Versions aligned:** `MARKETING_VERSION = 2.0`, `CURRENT_PROJECT_VERSION = 1` on app + extension.
4. **Alternate icon:** Replace placeholder `AppIcon-Pro` 1024×1024 asset (owner action).
5. **Screenshots:** Recapture after tabbed UI (`scripts/capture-app-store-screenshots.sh`).
6. **Review notes:** Session-scoped Live Activity; informational data only; Pro = extra surfaces not core status.

## Validation

```bash
just verify
```

Manual: widget after reboot, Siri phrase without prior shortcut setup, CarPlay source line when Pro, icon revert on subscription lapse.
