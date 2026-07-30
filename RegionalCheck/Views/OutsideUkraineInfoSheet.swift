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

                Image("OutsideUkraineInfo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)

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
}
