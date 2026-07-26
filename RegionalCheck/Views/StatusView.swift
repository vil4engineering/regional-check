import SwiftUI

struct StatusView: View {
    var controller: StatusController
    var onRefresh: () -> Void = {}
    var onShowInfo: (() -> Void)?

    @State private var pulseBright = false

    var body: some View {
        ZStack {
            Theme.Colors.statusBackdrop(for: controller.state)
                .ignoresSafeArea()
                .overlay {
                    Theme.Colors.statusAccent(for: controller.state)
                        .opacity(pulseOverlayOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .animation(Theme.Motion.stateSpring, value: controller.state.phase)

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Theme.Spacing.refreshControl)

                Spacer(minLength: Theme.Spacing.md)

                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: controller.state.symbolName)
                        .font(Theme.Typography.symbol)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Theme.Colors.statusAccent(for: controller.state))
                        .shadow(
                            color: Theme.Shadows.glow,
                            radius: Theme.Shadows.glowRadius,
                            y: Theme.Shadows.glowY
                        )
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: controller.state.symbolName)
                        .symbolEffect(.pulse, options: .repeating, isActive: isAlertActive)
                        .symbolEffect(.rotate, options: .repeating, isActive: isChecking)
                        .accessibilityHidden(true)

                    Text(controller.state.title)
                        .font(Theme.Typography.stateTitle)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.Colors.statusAccent(for: controller.state))
                        .shadow(
                            color: Theme.Shadows.soft,
                            radius: Theme.Shadows.softRadius,
                            y: Theme.Shadows.softY
                        )
                        .contentTransition(.interpolate)
                        .padding(.horizontal, Theme.Spacing.md)
                }

                instrumentDivider
                    .padding(.top, Theme.Spacing.lg)

                HStack(alignment: .firstTextBaseline) {
                    Text(controller.regionTitle)
                        .font(Theme.Typography.regionTitle)
                        .foregroundStyle(Theme.Colors.onFill)
                        .lineLimit(2)

                    Spacer(minLength: Theme.Spacing.sm)

                    if let checkedAtLabel = controller.checkedAtLabel {
                        Text(checkedAtLabel)
                            .font(Theme.Typography.caption.monospacedDigit())
                            .foregroundStyle(Theme.Colors.onFillSecondary)
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)

                instrumentDivider

                Text(controller.state.explanation)
                    .font(Theme.Typography.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Colors.onFillSecondary)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.md)

                if case .error = controller.state, let detail = controller.state.detailText {
                    Text(detail)
                        .font(Theme.Typography.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.Colors.onFillSecondary)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.top, Theme.Spacing.sm)
                }

                Spacer(minLength: Theme.Spacing.lg)

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(Theme.Typography.refreshSymbol)
                        .foregroundStyle(Theme.Colors.onFill)
                        .symbolEffect(.rotate, options: .repeating, isActive: controller.isLoading)
                        .frame(width: Theme.Spacing.refreshControl, height: Theme.Spacing.refreshControl)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(
                            color: Theme.Shadows.elevated,
                            radius: Theme.Shadows.elevatedRadius,
                            y: Theme.Shadows.elevatedY
                        )
                }
                .buttonStyle(HapticButtonStyle(feedback: Theme.Haptics.icon))
                .disabled(controller.isLoading)
                .accessibilityLabel(Text("Refresh"))
                .padding(.bottom, Theme.Spacing.xl)
            }
            .animation(Theme.Motion.stateSpring, value: controller.state.phase)

            if let onShowInfo {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onShowInfo) {
                            Image(systemName: "info.circle")
                                .font(Theme.Typography.refreshSymbol)
                                .foregroundStyle(Theme.Colors.onFillSecondary)
                                .frame(width: Theme.Spacing.refreshControl, height: Theme.Spacing.refreshControl)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HapticButtonStyle(feedback: Theme.Haptics.icon))
                        .accessibilityLabel(Text("About"))
                    }
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .sensoryFeedback(trigger: controller.state.phase) { _, new in
            switch new {
            case .alarm:
                .warning
            case .quiet:
                .impact(flexibility: .soft, intensity: 0.7)
            case .error:
                .error
            case .idle:
                nil
            }
        }
        .onAppear {
            syncPulse()
        }
        .onChange(of: controller.state.phase) { _, _ in
            syncPulse()
        }
    }

    private var instrumentDivider: some View {
        Rectangle()
            .fill(Theme.Colors.separator)
            .frame(height: 1)
            .padding(.horizontal, Theme.Spacing.xl)
    }

    private var isAlertActive: Bool {
        if case .alarm = controller.state { return true }
        return false
    }

    private var isChecking: Bool {
        if case .idle = controller.state { return true }
        return false
    }

    private var pulseOverlayOpacity: Double {
        guard isAlertActive else { return 0 }
        return pulseBright ? 0.18 : 0.04
    }

    private func syncPulse() {
        if isAlertActive {
            pulseBright = false
            withAnimation(Theme.Motion.loudPulse) {
                pulseBright = true
            }
        } else {
            withAnimation(Theme.Motion.quietFade) {
                pulseBright = false
            }
        }
    }
}

#Preview {
    StatusView(
        controller: StatusController(
            region: .kyivCity,
            provider: PreviewProvider()
        )
    )
}

private struct PreviewProvider: StatusProviding {
    func fetchStatus(region: AlertRegion) async throws -> AlertStatusSnapshot {
        AlertStatusSnapshot(region: region, status: .quiet, checkedAt: Date(), source: "preview")
    }
}
