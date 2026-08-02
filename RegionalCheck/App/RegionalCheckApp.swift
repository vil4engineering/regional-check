import SwiftUI

@main
struct RegionalCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
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
                standardRoot
            }
        #else
            standardRoot
        #endif
    }

    @ViewBuilder
    private var standardRoot: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView(purpose: .firstLaunch) {
                hasCompletedOnboarding = true
            }
        }
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
            default:
                HomeView()
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
    static let liveActivity = LiveActivityController(subscription: subscription)

    static func syncLiveActivityContent() {
        liveActivity.update(
            phase: status.state.phase.activityPhase,
            regionTitle: status.regionTitle,
            checkedAt: status.state.checkedAt,
            sourceLabel: StatusSourceLabel.displayName(for: status.lastSourceRaw)
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
