import SwiftUI

struct QuiverView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Quiver Section", selection: $selectedTab) {
                    Text("Boards").tag(0)
                    Text("Spots").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    BoardsView()
                } else {
                    SpotsView()
                }
            }
            .navigationTitle("Quiver")
        }
    }
}
