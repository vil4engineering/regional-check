import SwiftUI

struct HomeView: View {
    @State private var showsOnboarding = false

    private var controller: StatusController {
        AppDependencies.status
    }

    private var regions: RegionSelection {
        AppDependencies.regions
    }

    var body: some View {
        StatusView(
            controller: controller,
            onRefresh: {
                Task { await controller.refresh() }
            },
            onShowInfo: {
                showsOnboarding = true
            }
        )
        .onAppear {
            if let phase = AppLaunchArguments.screenshotPhase {
                controller.applyScreenshotFixture(phase)
                return
            }
            controller.setRegion(regions.selectedRegion)
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingView(purpose: .about) {
                showsOnboarding = false
            }
        }
    }
}

#Preview {
    HomeView()
}
