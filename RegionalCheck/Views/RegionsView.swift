import DriveCheckKit
import SwiftUI

struct RegionsView: View {
    private var controller: StatusController {
        AppDependencies.status
    }

    private var regions: RegionSelection {
        AppDependencies.regions
    }

    private var model: RegionsListModel {
        RegionsListModel(snapshot: controller.lastSnapshot, selected: regions.selectedRegion)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    currentRegionRow
                    Toggle(isOn: followsLocationBinding) {
                        Text("regions.follow_location")
                            .foregroundStyle(Theme.Colors.onFill)
                    }
                    .tint(Theme.Colors.onboarding)
                    .listRowBackground(Theme.Colors.dashboard.opacity(0.92))
                }

                if controller.lastSnapshot == nil {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Theme.Colors.dashboard.opacity(0.92))
                    }
                } else {
                    if !model.alarmRegions.isEmpty {
                        Section("regions.section.alarm") {
                            ForEach(model.alarmRegions, id: \.self) { region in
                                regionRow(region)
                            }
                        }
                    }

                    Section("regions.section.other") {
                        ForEach(model.otherRegions, id: \.self) { region in
                            regionRow(region)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.dashboard)
            .navigationTitle(Text("tab.regions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.dashboard, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var currentRegionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm / 2) {
                Text("regions.current")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.onFillSecondary)
                Text(regions.selectedRegion.title)
                    .font(Theme.Typography.regionTitle)
                    .foregroundStyle(Theme.Colors.onFill)
            }
            Spacer()
            statusLabel(for: regions.selectedRegion)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel(for: regions.selectedRegion))
        .listRowBackground(Theme.Colors.dashboard.opacity(0.92))
    }

    private func regionRow(_ region: AlertRegion) -> some View {
        Button {
            regions.pin(region)
        } label: {
            HStack {
                Text(region.title)
                    .foregroundStyle(Theme.Colors.onFill)
                Spacer()
                if region == regions.selectedRegion {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.Colors.onboarding)
                }
                statusLabel(for: region)
            }
        }
        .accessibilityLabel(rowAccessibilityLabel(for: region))
        .listRowBackground(Theme.Colors.dashboard.opacity(0.92))
    }

    @ViewBuilder
    private func statusLabel(for region: AlertRegion) -> some View {
        switch model.status(for: region) {
        case .alarm:
            Text("Alert Active")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.attention)
        case .quiet:
            Text("All Clear")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.normal)
        case nil:
            ProgressView()
                .controlSize(.small)
        }
    }

    private func rowAccessibilityLabel(for region: AlertRegion) -> String {
        let statusText = switch model.status(for: region) {
        case .alarm:
            String(localized: "Alert Active")
        case .quiet:
            String(localized: "All Clear")
        case nil:
            String(localized: "Checking…")
        }
        return "\(region.title), \(statusText)"
    }

    private var followsLocationBinding: Binding<Bool> {
        Binding(
            get: { regions.followsLocation },
            set: { regions.setFollowsLocation($0) }
        )
    }
}

#Preview {
    RegionsView()
}
