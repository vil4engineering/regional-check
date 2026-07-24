import SwiftUI

@main
struct RegionalCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

@MainActor
enum AppDependencies {
    static let provider = UbillingProvider()
    static let location = LocationManager()
    static let regions = RegionSelection()
    static let status = StatusController(region: regions.selectedRegion, provider: provider)
}
