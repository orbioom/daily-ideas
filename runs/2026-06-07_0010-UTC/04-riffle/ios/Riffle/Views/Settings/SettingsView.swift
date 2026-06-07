import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("useMetric") private var useMetric = false
    @AppStorage("defaultSpecies") private var defaultSpecies = "Brown Trout"
    @AppStorage("lowStockThreshold") private var lowStockThreshold = 2
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var patterns: [Pattern]
    @Query private var catches: [Catch]
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Metric units", isOn: $useMetric)
                        Stepper("Low-stock at \(lowStockThreshold)", value: $lowStockThreshold, in: 0...10)
                        TextField("Default species", text: $defaultSpecies)
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") } footer: {
                        Text("Metric switches lengths to centimeters and temperatures to Celsius.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Patterns", value: "\(patterns.count)")
                        LabeledContent("Flies in box",
                                       value: "\(patterns.reduce(0) { $0 + $1.inStock })")
                        LabeledContent("Catches logged", value: "\(catches.count)")
                    } header: { Text("Your data") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }.foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: { Text("Clear all data") }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Riffle").font(.headline).foregroundStyle(Brand.text)
                            Text("A fly-tying and fishing log: recipes, your box, the catch log, and a hatch chart that matches your flies. All on-device.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Clear all data?", isPresented: $confirmClear) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every pattern and catch. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for p in patterns { context.delete(p) }
        for c in catches { context.delete(c) }
        try? context.save()
        Haptics.warning()
    }
}
