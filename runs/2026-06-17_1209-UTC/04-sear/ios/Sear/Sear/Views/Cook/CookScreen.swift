import SwiftUI
import SwiftData

/// The "Cook" tab. Shows the live cook(s) in progress, or an empty state inviting
/// the user to start one. Settings is reachable from the toolbar here.
struct CookScreen: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Cook.startDate, order: .reverse) private var cooks: [Cook]

    @State private var showNew = false
    @State private var showSettings = false

    private var activeCooks: [Cook] {
        cooks.filter { $0.status.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("On the Fire")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: {
                        Label("New Cook", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) { NewCookView() }
            .sheet(isPresented: $showSettings) { SettingsScreen() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeCooks.isEmpty {
            EmptyStateView(symbol: "flame",
                           title: "Nothing on the fire",
                           message: "Start a cook to track the timer, temps and phases live.",
                           actionTitle: "Start a cook") { showNew = true }
        } else if activeCooks.count == 1, let cook = activeCooks.first {
            // Single active cook: drop straight into the live view inside the stack.
            LiveCookView(cook: cook)
        } else {
            // Multiple active cooks (Pro): pick which to view.
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(activeCooks) { cook in
                        NavigationLink {
                            LiveCookView(cook: cook)
                        } label: {
                            CookRow(cook: cook).searCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }
}
