import SwiftUI

struct HomeView: View {
    @State private var showsOnboarding = false

    private var controller: StatusController {
        AppDependencies.status
    }

    private var location: LocationManager {
        AppDependencies.location
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
            location.beginUpdating()
            controller.setRegion(regions.selectedRegion)
            Task { await controller.refresh() }
        }
        .onChange(of: regions.selectedRegion) { _, region in
            controller.setRegion(region)
            Task { await controller.refresh() }
        }
        .onChange(of: location.coordinateStamp) { _, _ in
            guard let coordinate = location.coordinate else { return }
            regions.updateFromLocation(coordinate: coordinate)
        }
        .onDisappear {
            location.endUpdating()
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
