import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @Query private var occasions: [Occasion]
    @Query private var gifts: [Gift]

    @AppStorage("trove.currencyCode") private var currencyCode = "USD"
    @AppStorage("trove.showGiven") private var showGiven = true
    @AppStorage("trove.haptics") private var haptics = true

    @State private var showResetConfirm = false

    private var currency: CurrencyOption {
        CurrencyOption(rawValue: currencyCode) ?? .usd
    }

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Currency", selection: Binding(
                    get: { currency },
                    set: { currencyCode = $0.rawValue })) {
                    ForEach(CurrencyOption.allCases) { Text($0.label).tag($0) }
                }
            } footer: {
                Text("Example: \(Format.currency(1234.5, code: currencyCode))")
            }

            Section("Lists") {
                Toggle("Show already-given gifts", isOn: $showGiven)
            } footer: {
                Text("Turn off to hide gifts you've already given from people and occasion lists.")
            }

            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
            }

            Section("Library") {
                LabeledContent("People", value: "\(people.count)")
                LabeledContent("Gifts", value: "\(gifts.count)")
                LabeledContent("Occasions", value: "\(occasions.count)")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Clear all data", systemImage: "trash")
                }
            } footer: {
                Text("Permanently deletes all people, gifts, and occasions. Everything in Trove stays on this device.")
            }

            Section {
                LabeledContent("Trove", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. All data is stored on-device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Clear all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Clear everything", role: .destructive) { clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes \(people.count) people, \(gifts.count) gifts, and \(occasions.count) occasions. This can't be undone.")
        }
    }

    private func clearAll() {
        for g in gifts { context.delete(g) }
        for p in people { context.delete(p) }
        for o in occasions { context.delete(o) }
        try? context.save()
        Haptics.warning()
    }
}
