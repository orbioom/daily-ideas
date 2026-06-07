import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage(Season.Keys.springMonth) private var springMonth = 5
    @AppStorage(Season.Keys.springDay) private var springDay = 10
    @AppStorage(Season.Keys.fallMonth) private var fallMonth = 10
    @AppStorage(Season.Keys.fallDay) private var fallDay = 10
    @AppStorage(Season.Keys.zone) private var zone = "6b"
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var crops: [Crop]
    @Query private var plantings: [Planting]
    @Query private var beds: [Bed]
    @State private var confirmClear = false

    private var springBinding: Binding<Date> {
        Binding(
            get: { FrostMath.date(month: springMonth, day: springDay, year: Season.currentYear) },
            set: { newValue in
                let c = Calendar.current.dateComponents([.month, .day], from: newValue)
                springMonth = c.month ?? 5; springDay = c.day ?? 10
            }
        )
    }
    private var fallBinding: Binding<Date> {
        Binding(
            get: { FrostMath.date(month: fallMonth, day: fallDay, year: Season.currentYear) },
            set: { newValue in
                let c = Calendar.current.dateComponents([.month, .day], from: newValue)
                fallMonth = c.month ?? 10; fallDay = c.day ?? 10
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        DatePicker("Last spring frost", selection: springBinding, displayedComponents: .date)
                        DatePicker("First fall frost", selection: fallBinding, displayedComponents: .date)
                        LabeledContent("Frost-free days", value: "\(Season.frostFreeDays)")
                    } header: { Text("Frost dates") } footer: {
                        Text("All sow, transplant, and harvest dates are computed from these.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        TextField("Hardiness zone", text: $zone)
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") }
                        .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Crops in catalog", value: "\(crops.count)")
                        LabeledContent("Beds", value: "\(beds.count)")
                        LabeledContent("Plantings", value: "\(plantings.count)")
                    } header: { Text("Your garden") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }.foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: { Text("Clear all data") }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tilth").font(.headline).foregroundStyle(Brand.text)
                            Text("A frost-aware succession planner. Your crops, your beds, your two frost dates — all on-device.")
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
                Text("This removes every crop, bed, and planting. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for p in plantings { context.delete(p) }
        for b in beds { context.delete(b) }
        for c in crops { context.delete(c) }
        try? context.save()
        Haptics.warning()
    }
}
