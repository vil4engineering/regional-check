import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Theme.Colors.statusGradient(for: .idle)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.xl)

                Image(systemName: "car.side")
                    .font(Theme.Typography.symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.Colors.onFill)
                    .accessibilityHidden(true)

                Text("Regional Check")
                    .font(Theme.Typography.stateTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Colors.onFill)

                Text("Onboarding body")
                    .font(Theme.Typography.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Colors.onFillSecondary)
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer(minLength: Theme.Spacing.xl)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(Theme.Typography.refreshLabel)
                        .foregroundStyle(Theme.Colors.onFill)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel(Text("Continue"))
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.md)
        }
    }
}

#Preview {
    OnboardingView(onContinue: {})
}
