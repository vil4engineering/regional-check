import SwiftUI

struct OnboardingView: View {
    var purpose: OnboardingPurpose = .firstLaunch
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Theme.Colors.onboardingGradient
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.xl)

                Image(systemName: "steeringwheel")
                    .font(Theme.Typography.symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.Colors.onFill)
                    .shadow(
                        color: Theme.Shadows.glow,
                        radius: Theme.Shadows.glowRadius,
                        y: Theme.Shadows.glowY
                    )
                    .accessibilityHidden(true)

                Text("Drive Check")
                    .font(Theme.Typography.stateTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Colors.onFill)
                    .shadow(
                        color: Theme.Shadows.soft,
                        radius: Theme.Shadows.softRadius,
                        y: Theme.Shadows.softY
                    )

                Text("Onboarding body")
                    .font(Theme.Typography.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Colors.onFillSecondary)
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer(minLength: Theme.Spacing.xl)

                Button(action: onContinue) {
                    Text(LocalizedStringKey(purpose.ctaTitleKey))
                        .font(Theme.Typography.refreshLabel)
                        .foregroundStyle(Theme.Colors.onFill)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(HapticButtonStyle(feedback: Theme.Haptics.button))
                .accessibilityLabel(Text(LocalizedStringKey(purpose.ctaTitleKey)))
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.md)
        }
    }
}

#Preview("First launch") {
    OnboardingView(purpose: .firstLaunch, onContinue: {})
}

#Preview("About") {
    OnboardingView(purpose: .about, onContinue: {})
}
