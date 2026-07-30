import SwiftUI

struct HomeView: View {
    @State private var showsOnboarding = false
    @State private var showsPaywall = false

    private var controller: StatusController {
        AppDependencies.status
    }

    private var location: LocationManager {
        AppDependencies.location
    }

    private var regions: RegionSelection {
        AppDependencies.regions
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
            if let phase = AppLaunchArguments.screenshotPhase {
                controller.applyScreenshotFixture(phase)
                return
            }
            if AppLaunchArguments.showsPaywallOnLaunch {
                showsPaywall = true
            }
            location.beginUpdating()
            controller.setRegion(regions.selectedRegion)
            controller.beginPeriodicRefresh()
            AppDependencies.liveActivity.beginPhoneForegroundSession()
            Task {
                await controller.refresh()
                AppDependencies.syncLiveActivityContent()
            }
        }
        .onChange(of: regions.selectedRegion) { _, region in
            controller.setRegion(region)
            Task {
                await controller.refresh()
                AppDependencies.syncLiveActivityContent()
            }
        }
        .onChange(of: location.coordinateStamp) { _, _ in
            guard let coordinate = location.coordinate else { return }
            regions.updateFromLocation(coordinate: coordinate)
        }
        .onChange(of: controller.state.phase) { _, _ in
            AppDependencies.syncLiveActivityContent()
        }
        .onChange(of: subscription.isPro) { _, _ in
            AppDependencies.syncLiveActivityContent()
        }
        .onDisappear {
            controller.endPeriodicRefresh()
            location.endUpdating()
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingView(
                purpose: .about,
                isPro: subscription.isPro,
                isLiveActivityEnabled: subscription.state.isLiveActivityEnabled,
                onToggleLiveActivity: { enabled in
                    subscription.setLiveActivityEnabled(enabled)
                    if !enabled {
                        AppDependencies.liveActivity.endAll()
                    } else {
                        AppDependencies.liveActivity.beginPhoneForegroundSession()
                        AppDependencies.syncLiveActivityContent()
                    }
                },
                onShowPaywall: {
                    showsOnboarding = false
                    showsPaywall = true
                },
                onContinue: {
                    showsOnboarding = false
                }
            )
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView(manager: subscription)
        }
        .sheet(isPresented: Binding(
            get: { regions.shouldShowOutsideUkraineInfo },
            set: { if !$0 { regions.acknowledgeOutsideUkraineInfo() } }
        )) {
            OutsideUkraineInfoSheet {
                regions.acknowledgeOutsideUkraineInfo()
            }
        }
    }
}

#Preview {
    HomeView()
}
