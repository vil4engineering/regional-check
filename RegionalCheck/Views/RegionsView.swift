import SwiftUI

struct RegionsView: View {
    var body: some View {
        NavigationStack {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.dashboard)
                .navigationTitle(Text("tab.regions"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Theme.Colors.dashboard, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    RegionsView()
}
