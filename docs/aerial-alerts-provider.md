# Aerial alerts data provider

Drive Check reads regional air-raid status from the public [Ubilling Aerial Alerts API](https://wiki.ubilling.net.ua/doku.php?id=aerialalertsapi).

## Endpoint

```
https://ubilling.net.ua/aerialalerts/
```

Implementation: `RegionalCheck/Data/UbillingProvider.swift`.

Response fields used by the app:

| Field | Meaning |
| --- | --- |
| `source` | Upstream data source selected by Ubilling |
| `cachedat` | Server cache timestamp (informational) |
| `states[region].alertnow` | `true` = alert active, `false` = all clear |
| `states[region].changed` | Last change time for that region (informational) |

Region keys match Ukrainian oblast names and `м. Київ` for Kyiv city.

## Ubilling limits (upstream)

From the official wiki (as of 2026):

| Rule | Value |
| --- | --- |
| Rate limit | **2 requests per second per host** (since 2024-02-13) |
| Over limit | HTTP **429** |
| Server cache | Raw data cached for **3 seconds** |

The API is public (no keys). Ubilling describes it as informational only — not for safety-critical decisions.

## Drive Check refresh policy

The app keeps requests well below Ubilling limits.

| Trigger | Network request |
| --- | --- |
| Screen open (`onAppear`) | Yes — immediate check |
| Region change (GPS) | Yes |
| Manual **Refresh** | Yes |
| Periodic background refresh | Yes — every **5 minutes** while the iPhone screen or CarPlay session is active |
| App in background (no active UI / CarPlay) | No |

### Five-minute polling

`StatusController.beginPeriodicRefresh()` starts a shared timer used by both iPhone (`HomeView`) and CarPlay (`CarPlaySceneDelegate`). Reference counting ensures one timer when both surfaces are active.

- Interval: `StatusController.periodicRefreshInterval` = **300 seconds (5 minutes)**
- First fetch on open/connect is still immediate; the timer only schedules later checks
- Stops when the iPhone home screen disappears and CarPlay disconnects

At 5-minute intervals the app sends about **0.003 rps** from periodic polling alone — far below the 2 rps host limit. Event-driven refreshes (open, region change, manual) may add a few extra requests but remain safe in normal use.

## Operational notes

- Do not add aggressive client polling (for example every 30 seconds). Server data is cached for 3 seconds, so faster polling adds load without fresher data.
- If Ubilling returns HTTP 429, treat it as rate limiting and back off; the UI currently surfaces a generic unavailable state on fetch failure.
- Optional query parameters (`?source=`, `?xml=true`, maps, etc.) are documented on the Ubilling wiki; Drive Check uses the default JSON endpoint only.
