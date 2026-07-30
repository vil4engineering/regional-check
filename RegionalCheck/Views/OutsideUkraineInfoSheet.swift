import SwiftUI

struct OutsideUkraineInfoSheet: View {
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("outsideUkraine.title")
                    .font(Theme.Typography.regionTitle)
                    .foregroundStyle(Theme.Colors.onFill)

                Text("outsideUkraine.body")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.onFillSecondary)

                illustration
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)

                Spacer(minLength: Theme.Spacing.md)

                Button(action: onDismiss) {
                    Text("Got It")
                        .font(Theme.Typography.refreshLabel)
                        .foregroundStyle(Theme.Colors.onFill)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(HapticButtonStyle())
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.Colors.dashboard.ignoresSafeArea())
        }
        .presentationDetents([.medium])
    }

    private var illustration: some View {
        ZStack {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 72, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.Colors.onFill.opacity(0.55))

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 36, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.Colors.onFill)
                .offset(x: 28, y: 18)
                .shadow(
                    color: Theme.Shadows.glow,
                    radius: Theme.Shadows.glowRadius * 0.45,
                    y: Theme.Shadows.glowY * 0.4
                )
        }
        .accessibilityHidden(true)
    }
}
