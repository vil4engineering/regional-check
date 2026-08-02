import SwiftUI

struct MainTabView: View {
    enum Tab: Hashable {
        case status
        case regions
    }

    @State private var selectedTab: Tab
    @State private var showsOnboarding = false
    @State private var showsPaywall = false

    init(initialTab: Tab = .status) {
        _selectedTab = State(initialValue: initialTab)
    }

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
        TabView(selection: $selectedTab) {
            HomeView(
                showsOnboarding: $showsOnboarding,
                showsPaywall: $showsPaywall
            )
            .tabItem {
                Label("tab.status", systemImage: "steeringwheel")
            }
            .tag(Tab.status)

            RegionsView()
                .tabItem {
                    Label("tab.regions", systemImage: "list.bullet")
                }
                .tag(Tab.regions)
        }
        .tint(Theme.Colors.onboarding)
        .onAppear {
            #if DEBUG
                if AppLaunchArguments.showsPaywallOnLaunch {
                    showsPaywall = true
                }
            #endif
            location.beginUpdating()
            controller.setRegion(regions.selectedRegion)
            controller.beginPeriodicRefresh()
            AppDependencies.liveActivity.beginPhoneForegroundSession()
            AppDependencies.syncLiveActivityContent()
        }
        .onChange(of: regions.selectedRegion) { _, region in
            controller.setRegion(region)
            AppDependencies.syncLiveActivityContent()
        }
        .onChange(of: location.coordinateStamp) { _, _ in
            guard let fix = location.lastFix else { return }
            regions.updateFromLocation(fix: fix)
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
            PaywallView(
                manager: subscription,
                syncLiveActivity: AppDependencies.syncLiveActivityContent,
                onDismiss: { showsPaywall = false }
            )
        }
        .sheet(isPresented: Binding(
            get: { regions.shouldShowOutsideUkraineInfo },
            set: { if !$0 { regions.acknowledgeOutsideUkraineInfo() } }
        )) {
            OutsideUkraineInfoSheet {
                regions.acknowledgeOutsideUkraineInfo()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let notice = regions.regionChangeNotice {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(notice)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.onFill)
                        .lineLimit(2)
                    Spacer(minLength: Theme.Spacing.sm)
                    if regions.previousRegionForUndo != nil {
                        Button("regions.changed_undo") {
                            regions.undoRegionChange()
                        }
                        .font(Theme.Typography.refreshLabel)
                        .foregroundStyle(Theme.Colors.onboarding)
                    }
                    Button {
                        regions.dismissRegionChangeNotice()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.Colors.onFillSecondary)
                    }
                    .accessibilityLabel(Text("Close"))
                }
                .padding(Theme.Spacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
    }
}

#Preview {
    MainTabView()
}
