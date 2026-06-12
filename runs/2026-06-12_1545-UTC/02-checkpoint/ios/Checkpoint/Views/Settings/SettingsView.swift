import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [Game]

    @AppStorage("currencyCode") private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultStatusRaw") private var defaultStatusRaw = GameStatus.backlog.rawValue
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "BRL", "INR", "MXN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Defaults") {
                    Picker("New game status", selection: $defaultStatusRaw) {
                        ForEach(GameStatus.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled).tint(Theme.accent)
                }
                Section {
                    LabeledContent("Games tracked", value: "\(games.count)")
                    LabeledContent("Hours logged", value: Fmt.hours(BacklogEngine.totalHoursPlayed(games)))
                } header: {
                    Text("Your library")
                }
                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all games", systemImage: "trash")
                    }
                } footer: {
                    Text("Checkpoint stores your whole library on this iPhone only — never uploaded, no account required.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device (SwiftData)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Delete your entire library?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { wipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func wipe() {
        for g in games { context.delete(g) }
        try? context.save()
        Haptics.success()
    }
}
