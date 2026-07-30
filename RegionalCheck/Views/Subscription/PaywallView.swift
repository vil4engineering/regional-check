import StoreKit
import SwiftUI

struct PaywallView: View {
    @State private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showsManageSubscriptions = false

    private let privacyURL = URL(string: "https://vil4max.github.io/regional-check/privacy-policy.html")!
    private let termsURL = URL(string: "https://vil4max.github.io/regional-check/terms-of-use.html")!

    init(manager: SubscriptionManager) {
        _viewModel = State(initialValue: PaywallViewModel(manager: manager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Drive Check Pro")
                        .font(Theme.Typography.stateTitle)
                        .foregroundStyle(Theme.Colors.onFill)

                    Text("subscription.paywall.subtitle")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.onFillSecondary)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        benefitRow("subscription.benefit.liveActivity")
                        benefitRow("subscription.benefit.badge")
                        benefitRow("subscription.benefit.detail")
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.products) { product in
                            productRow(product)
                        }
                    }

                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.onFillSecondary)
                    }

                    Button {
                        Task { await viewModel.purchase() }
                    } label: {
                        Text("subscription.paywall.subscribe")
                            .font(Theme.Typography.refreshLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(HapticButtonStyle())
                    .disabled(viewModel.isBusy || viewModel.products.isEmpty)

                    Button {
                        Task { await viewModel.restore() }
                    } label: {
                        Text("subscription.paywall.restore")
                            .font(Theme.Typography.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HapticButtonStyle())
                    .disabled(viewModel.isBusy)

                    Button {
                        showsManageSubscriptions = true
                    } label: {
                        Text("subscription.paywall.manage")
                            .font(Theme.Typography.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HapticButtonStyle())

                    Text("subscription.paywall.autoRenew")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.onFillSecondary)

                    HStack(spacing: Theme.Spacing.md) {
                        Link("subscription.paywall.privacy", destination: privacyURL)
                        Link("subscription.paywall.terms", destination: termsURL)
                    }
                    .font(Theme.Typography.caption)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.dashboard.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Got It") { dismiss() }
                }
            }
            .task {
                await viewModel.onAppear()
            }
            .manageSubscriptionsSheet(isPresented: $showsManageSubscriptions)
        }
    }

    private func benefitRow(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.normal)
            Text(key)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.onFill)
        }
    }

    private func productRow(_ product: SubscriptionProduct) -> some View {
        let selected = viewModel.selectedProductID == product.id
        return Button {
            viewModel.selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(Theme.Typography.refreshLabel)
                        .foregroundStyle(Theme.Colors.onFill)
                    Text(product.periodDescription)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.onFillSecondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(Theme.Typography.refreshLabel)
                    .foregroundStyle(Theme.Colors.onFill)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Theme.Colors.normal : Theme.Colors.separator, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
