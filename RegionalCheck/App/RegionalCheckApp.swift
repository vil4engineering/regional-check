import DriveCheckKit
import SwiftUI

@main
struct RegionalCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            rootContent
                .task {
                    await AppDependencies.subscription.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        AppDependencies.liveActivity.beginPhoneForegroundSession()
                        AppDependencies.syncLiveActivityContent()
                    case .background:
                        AppDependencies.liveActivity.endPhoneForegroundSession()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        #if DEBUG
            if let phase = AppLaunchArguments.screenshotPhase {
                screenshotRoot(phase: phase)
            } else {
                MainTabView()
            }
        #else
            MainTabView()
        #endif
    }

    #if DEBUG
        @ViewBuilder
        private func screenshotRoot(phase: String) -> some View {
            switch phase {
            case "launch":
                LaunchScreenCaptureView()
            case "onboarding":
                OnboardingView(purpose: .firstLaunch, onContinue: {})
            case "about":
                OnboardingView(purpose: .about, onContinue: {})
            case "regions":
                MainTabView(initialTab: .regions)
            default:
                HomeView(showsOnboarding: .constant(false), showsPaywall: .constant(false))
            }
        }
    #endif
}

#if DEBUG
    private struct LaunchScreenCaptureView: View {
        var body: some View {
            ZStack {
                Color("LaunchBackground")
                    .ignoresSafeArea()
                Image("LaunchScreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .accessibilityHidden(true)
        }
    }
#endif

@MainActor
enum AppDependencies {
    static let provider = UbillingProvider()
    static let location = LocationManager()
    static let regions = RegionSelection()
    static let status = StatusController(region: regions.selectedRegion, provider: provider)
    static let subscription = SubscriptionManager()
    static let liveActivity = LiveActivityController(
        allowsLiveActivity: { subscription.allows(.liveActivity) },
        entitlementChanges: { subscription.entitlementChanges() }
    )

    static func syncLiveActivityContent() {
        liveActivity.update(
            phase: status.state.phase.activityPhase,
            regionTitle: status.regionTitle,
            checkedAt: status.state.checkedAt,
            sourceLabel: StatusSourceLabel.displayName(for: status.lastSourceRaw),
            isStale: status.isDataStale
        )
    }
}

extension StatusState.Phase {
    var activityPhase: DriveCheckActivityPhase {
        switch self {
        case .idle:
            .idle
        case .quiet:
            .quiet
        case .alarm:
            .alarm
        case .error, .regionUnavailable:
            .error
        }
    }
}
