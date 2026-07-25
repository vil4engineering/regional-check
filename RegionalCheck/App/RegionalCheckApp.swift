import SwiftUI

@main
struct RegionalCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            rootContent
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if let phase = AppLaunchArguments.screenshotPhase {
            screenshotRoot(phase: phase)
        } else if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView(purpose: .firstLaunch) {
                hasCompletedOnboarding = true
            }
        }
    }

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
}

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

@MainActor
enum AppDependencies {
    static let provider = UbillingProvider()
    static let location = LocationManager()
    static let regions = RegionSelection()
    static let status = StatusController(region: regions.selectedRegion, provider: provider)
}
