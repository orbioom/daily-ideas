import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var items: [ClothingItem]
    @Query private var outfits: [Outfit]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("neglectDays") private var neglectDays = 60

    @State private var showErase = false
    private let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "INR", "BRL"]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }
                    Section {
                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Neglected after", selection: $neglectDays) {
                            Text("30 days").tag(30)
                            Text("60 days").tag(60)
                            Text("90 days").tag(90)
                        }
                    } header: {
                        Text("Wardrobe")
                    } footer: {
                        Text("Currency is used for cost and value. Neglected threshold flags pieces you haven't worn in a while.")
                    }
                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }
                    Section {
                        LabeledContent("Pieces", value: "\(items.count)")
                        LabeledContent("Outfits", value: "\(outfits.count)")
                        Button(role: .destructive) { showErase = true } label: { Text("Erase everything") }
                            .disabled(items.isEmpty && outfits.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("Stored on this device only — no account, no cloud, no item cap.")
                    }
                    Section {
                        LabeledContent("Version", value: "1.0")
                    } footer: {
                        Text("Capsule — wear what you have. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Erase all pieces and outfits?", isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    for o in outfits { context.delete(o) }
                    for i in items { context.delete(i) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
