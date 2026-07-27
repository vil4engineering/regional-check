# Product Charter

Status: binding. **Product name: Drive Check.**

| | |
| --- | --- |
| Product name | Drive Check |
| Repository | `regional-check` |
| Bundle ID | `vil4max.RegionalCheck` |
| Scheme / target | `RegionalCheck` |

## Constitution

Every new line of code must reduce complexity or improve the driver’s experience. Otherwise it should not be added.

## Mission

Know your region's alert status without leaving CarPlay.

## Vision

A glanceable CarPlay utility for drivers: open, see the regional alert status, close. It exists so you do not reach for your phone while driving. Not a monitor, not notifications, not a map, not navigation — closer to Maps / Compass / Weather as a system-style check.

## Product principles

- One Screen
- One Region
- One State
- One Data Provider
- One User Action (Refresh)
- CarPlay is primary; iPhone is a companion that mirrors the same experience

Domain may use `AlertStatus` / `alarm` / `quiet`. UI uses All Clear / Alert Active / Checking / Unavailable with matching circle SF Symbols.

## Never

Accounts, auth, ads, history, user analytics, push, social features, favorites, map product surface. Do not sell the app as an “alert monitor.”

## Analytics

Apple-only observability (App Analytics, crash reports, TestFlight). No third-party analytics SDK. Details: `docs/analytics.md`.

## App Store copy

Paste-ready for App Store Connect (alerts only in description, not in the name).

| Field | Copy |
| --- | --- |
| Name | Drive Check UA |
| Subtitle (≤30) | Regional alerts for CarPlay |
| Promo / first line | Drive Check brings regional alert status to CarPlay, helping drivers stay informed without handling their phone. |
| Description opening | Drive Check brings regional alert status to CarPlay, helping drivers stay informed without handling their phone. |
| Onboarding (EN) | Regional alert status, designed for CarPlay. |
| Primary CTA | Get Started |

Keywords: put alert-related terms in keywords / description only — not in the app name.

## Next

Apple Release: assets, metadata, CarPlay entitlement, TestFlight, Review.
