import DriveCheckKit
import SwiftUI
import UIKit

struct HomeView: View {
    @Binding var showsOnboarding: Bool
    @Binding var showsPaywall: Bool

    private var controller: StatusController {
        AppDependencies.status
    }

    private var location: LocationManager {
        AppDependencies.location
    }

    private var subscription: SubscriptionManager {
        AppDependencies.subscription
    }

    var body: some View {
        StatusView(
            controller: controller,
            isPro: subscription.isPro,
            sourceLabel: subscription.allows(.extendedDetail)
                ? StatusSourceLabel.displayName(for: controller.lastSourceRaw)
                : nil,
            showsLocationAccessDenied: location.isAuthorizationBlocked,
            secondaryRegionTitle: secondaryRegionLine(isPro: subscription.isPro),
            onRefresh: {
                Task {
                    await controller.refresh()
                    AppDependencies.syncLiveActivityContent()
                }
            },
            onShowInfo: {
                showsOnboarding = true
            },
            onShowPaywall: {
                showsPaywall = true
            },
            onOpenLocationSettings: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        )
        .onAppear {
            #if DEBUG
                if let phase = AppLaunchArguments.screenshotPhase {
                    controller.applyScreenshotFixture(phase)
                }
            #endif
        }
    }

    private func secondaryRegionLine(isPro: Bool) -> String? {
        guard isPro, let region = SharedStore.shared.loadSecondaryRegion() else { return nil }
        return String(format: String(localized: "status.secondary_region"), region.title)
    }
}

#Preview {
    HomeView(showsOnboarding: .constant(false), showsPaywall: .constant(false))
}
