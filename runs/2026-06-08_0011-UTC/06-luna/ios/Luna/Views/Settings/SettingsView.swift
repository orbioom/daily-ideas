import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var periods: [Period]
    @Query private var logs: [DayLog]

    @AppStorage("luna.haptics") private var haptics = true
    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @AppStorage("luna.defaultPeriod") private var defaultPeriod = 5
    @AppStorage("luna.showFertility") private var showFertility = true

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Cycle defaults") {
                        Stepper(value: $defaultCycle, in: 20...45) {
                            HStack { Text("Cycle length"); Spacer()
                                Text("\(defaultCycle) days").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                        Stepper(value: $defaultPeriod, in: 1...10) {
                            HStack { Text("Period length"); Spacer()
                                Text("\(defaultPeriod) days").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                        Text("Used for predictions until Luna has enough of your own history.")
                            .font(.footnote).foregroundStyle(Brand.text3)
                    }
                    Section("Display") {
                        Toggle("Show fertility & ovulation", isOn: $showFertility)
                        Toggle("Haptics", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }
                    Section("Data") {
                        HStack { Text("Periods logged"); Spacer()
                            Text("\(periods.count)").foregroundStyle(Brand.text2) }
                        HStack { Text("Day logs"); Spacer()
                            Text("\(logs.count)").foregroundStyle(Brand.text2) }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Delete all data", systemImage: "trash")
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Luna 1.0 · Private").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Text("Everything you log stays on this device — no account, no cloud, no tracking. Predictions are estimates and are not a form of contraception or medical advice.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Delete all data?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for p in periods { context.delete(p) }
                    for l in logs { context.delete(l) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This permanently removes every period and day log from this device.") }
        }
    }
}
