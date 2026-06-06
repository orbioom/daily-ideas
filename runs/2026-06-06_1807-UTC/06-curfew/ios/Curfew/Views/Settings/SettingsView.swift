import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var intakes: [Intake]
    @Query private var sources: [CaffeineSource]

    @AppStorage("halfLifeHours") private var halfLife = 5.0
    @AppStorage("bedtimeHour") private var bedtimeHour = 23
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 0
    @AppStorage("sleepThresholdMg") private var sleepThreshold = 50.0
    @AppStorage("dailyLimitMg") private var dailyLimit = 400.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var bedtime = Date.now
    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .onChange(of: bedtime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            bedtimeHour = c.hour ?? 23; bedtimeMinute = c.minute ?? 0
                        }
                    Picker("Caffeine half-life", selection: $halfLife) {
                        Text("3 h (fast)").tag(3.0)
                        Text("4 h").tag(4.0)
                        Text("5 h (average)").tag(5.0)
                        Text("6 h").tag(6.0)
                        Text("7 h (slow)").tag(7.0)
                    }
                } header: { Text("Your body") } footer: {
                    Text("Caffeine's half-life is ~5 hours for most adults, but varies with genetics, medication, pregnancy, and smoking. Adjust if you metabolize faster or slower.")
                }
                Section("Sleep") {
                    Stepper("Sleep threshold: \(Int(sleepThreshold)) mg",
                            value: $sleepThreshold, in: 10...150, step: 10)
                    Stepper("Daily limit: \(Int(dailyLimit)) mg",
                            value: $dailyLimit, in: 100...800, step: 50)
                }
                Section {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Data") {
                    LabeledContent("Intakes", value: "\(intakes.count)")
                    LabeledContent("Drinks", value: "\(sources.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Curfew runs entirely on your device and is an estimate, not medical advice. It models caffeine with first-order (exponential) decay.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onAppear {
                bedtime = Calendar.current.date(bySettingHour: bedtimeHour, minute: bedtimeMinute,
                                                second: 0, of: .now) ?? .now
            }
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every intake and drink. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo drinks and intakes.") }
        }
    }

    private func deleteAll() {
        for i in intakes { context.delete(i) }
        for s in sources { context.delete(s) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
