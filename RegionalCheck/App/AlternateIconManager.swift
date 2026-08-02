import UIKit

enum AlternateIconManager {
    static let proIconName = "AppIcon-Pro"

    @MainActor
    static func sync(isPro: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let desired = isPro ? proIconName : nil
        guard UIApplication.shared.alternateIconName != desired else { return }
        UIApplication.shared.setAlternateIconName(desired) { _ in }
    }
}
