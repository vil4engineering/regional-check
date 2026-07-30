import Foundation

struct PremiumAccess {
    let isPro: Bool
    let isLiveActivityEnabled: Bool

    init(isPro: Bool, isLiveActivityEnabled: Bool = true) {
        self.isPro = isPro
        self.isLiveActivityEnabled = isLiveActivityEnabled
    }

    @MainActor
    init(manager: SubscriptionManager) {
        isPro = manager.isPro
        isLiveActivityEnabled = manager.state.isLiveActivityEnabled
    }

    func allows(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .proBadge, .extendedDetail:
            isPro
        case .liveActivity:
            isPro && isLiveActivityEnabled
        }
    }
}
