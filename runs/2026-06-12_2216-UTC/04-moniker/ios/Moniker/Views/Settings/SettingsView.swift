import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decisions: [Decision]

    @AppStorage("partnerAName") private var partnerAName = "Partner A"
    @AppStorage("partnerBName") private var partnerBName = "Partner B"
    @AppStorage("showMeanings") private var showMeanings = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("deckSeed") private var deckSeed = 0

    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First partner", text: $partnerAName)
                    TextField("Second partner", text: $partnerBName)
                } header: {
                    Text("Partners")
                } footer: {
                    Text("Names are shown on the swipe screen and the hand-off ritual.")
                }

                Section("Swiping") {
                    Toggle("Show meanings on cards", isOn: $showMeanings)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    Button("Reshuffle the deck order") {
                        Haptics.tap()
                        deckSeed = Int.random(in: 1...Int.max)
                    }
                    Button("Reset all swipes…", role: .destructive) {
                        confirmingReset = true
                    }
                } header: {
                    Text("Deck")
                } footer: {
                    Text("Reshuffling changes the order of undecided names for both partners. Resetting erases every verdict — matches included.")
                }

                Section {
                    LabeledContent("Names in catalog", value: "\(NameCatalog.all.count)")
                    LabeledContent("Verdicts recorded", value: "\(decisions.count)")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Your data", value: "Stays on this device")
                } header: {
                    Text("About")
                } footer: {
                    Text("Moniker runs entirely on this iPhone — no accounts, no sync servers, no ads. Pass the phone; that's the whole protocol.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Erase every swipe from both partners?",
                isPresented: $confirmingReset,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    for decision in decisions {
                        modelContext.delete(decision)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
