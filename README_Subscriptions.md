# Drive Check Pro — StoreKit 2 & Live Activity

## Product IDs

| ID | Period | Demo price |
| --- | --- | --- |
| `regioncheck.pro.monthly` | month | $0.29 |
| `regioncheck.pro.yearly` | year | $0.99 |

Local StoreKit config: `RegionalCheck/Resources/Products.storekit` (wired in the `RegionalCheck` scheme).

## Architecture

- `Subscription/` — protocols, StoreKit service, entitlement cache, `SubscriptionManager`, `PremiumAccess`
- Views never import StoreKit except `PaywallView` for `manageSubscriptionsSheet`
- Entitlement comes from verified StoreKit transactions + offline cache with expiry
- Pro features: session Live Activity, Pro badge, friendly extended source label
- Core region status stays free

## Live Activity session

Live Activity is **session-scoped on purpose**. There is no background polling of the alert feed, so a Lock Screen Activity that outlives the session would show a stale air-raid status — worse than showing nothing. Ending the Activity when the phone backgrounds (unless CarPlay still holds a session) is a safety choice, not an unfinished feature.

| Client | Holds Activity | Ends when |
| --- | --- | --- |
| iPhone foreground | `scenePhase == .active` | background → end if no CarPlay (`dismissalPolicy: .immediate`) |
| CarPlay scene | connected | disconnect |

Updates are silent (no alert configuration). `staleDate` is derived from the last `checkedAt` plus twice the current refresh interval, so aged content is marked stale instead of looking fresh forever.

## Testing

```bash
just doctor
just format
just test   # or xcodebuild with an explicit simulator id
```

Unit tests use fakes for StoreKit. Manual: purchase/restore via StoreKit Configuration; open Pro app → Island; background → Activity ends.

## ASC (human)

1. Host Privacy + Terms on GitHub Pages
2. Create subscription group + products at minimum prices
3. App Privacy: Purchases; Live Activities (no push notify product claim)
4. Review Notes: symbolic pricing; session Live Activity; restore path

## Interview notes

- Verified transactions + `Transaction.updates`, not a purchase-button bool
- Cache is UX with expiry, not source of truth
- Honest CarPlay / foreground session scope — no background monitoring claim
