import SwiftUI

struct HomeView: View {
    @Binding var showsOnboarding: Bool
    @Binding var showsPaywall: Bool

    private var controller: StatusController {
        AppDependencies.status
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
}

#Preview {
    HomeView(showsOnboarding: .constant(false), showsPaywall: .constant(false))
}
