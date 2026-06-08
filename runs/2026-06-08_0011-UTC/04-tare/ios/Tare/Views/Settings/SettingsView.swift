import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [WeightEntry]

    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("tare.goalKg") private var goalKg = 0.0
    @AppStorage("tare.heightCm") private var heightCm = 0.0
    @AppStorage("tare.smoothing") private var smoothing = 0.1
    @AppStorage("tare.haptics") private var haptics = true

    @State private var goalDisplay = 0.0
    @State private var hasGoal = false
    @State private var confirmReset = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var goalStep: Double { unit == .kg ? 0.5 : 1.0 }
    private var goalRange: ClosedRange<Double> { unit == .kg ? 30...300 : 66...660 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Units") {
                        Picker("Weight unit", selection: $unitRaw) {
                            ForEach(WeightUnit.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        .onChange(of: unitRaw) { _, _ in syncGoal() }
                    }

                    Section("Goal") {
                        Toggle("Set a goal weight", isOn: $hasGoal)
                            .onChange(of: hasGoal) { _, on in
                                if on { goalKg = Units.toKg(goalDisplay == 0 ? defaultGoal() : goalDisplay, from: unit) }
                                else { goalKg = 0 }
                            }
                        if hasGoal {
                            Stepper(value: $goalDisplay, in: goalRange, step: goalStep) {
                                HStack { Text("Goal"); Spacer()
                                    Text(Units.display(Units.toKg(goalDisplay, from: unit), unit: unit, decimals: 1))
                                        .font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                            }
                            .onChange(of: goalDisplay) { _, v in goalKg = Units.toKg(v, from: unit) }
                        }
                    }

                    Section("For BMI (optional)") {
                        Stepper(value: $heightCm, in: 0...230, step: 1) {
                            HStack { Text("Height"); Spacer()
                                Text(heightCm > 0 ? "\(Int(heightCm)) cm" : "Not set")
                                    .font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                    }

                    Section("Trend smoothing") {
                        VStack(alignment: .leading) {
                            Slider(value: $smoothing, in: 0.05...0.3, step: 0.01)
                                .tint(Brand.info)
                            HStack {
                                Text("Smoother").font(.caption).foregroundStyle(Brand.text3)
                                Spacer()
                                Text(String(format: "α %.2f", smoothing)).font(Brand.mono(12)).foregroundStyle(Brand.text2)
                                Spacer()
                                Text("Faster").font(.caption).foregroundStyle(Brand.text3)
                            }
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }

                    Section("Data") {
                        HStack { Text("Weigh-ins stored"); Spacer()
                            Text("\(entries.count)").foregroundStyle(Brand.text2) }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Delete all weigh-ins", systemImage: "trash")
                        }
                    }

                    Section {
                        Text("Tare 1.0 — all data stays on this device.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear { hasGoal = goalKg > 0; syncGoal() }
            .alert("Delete all weigh-ins?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for e in entries { context.delete(e) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This permanently removes your weight history.") }
        }
    }

    private func syncGoal() {
        goalDisplay = goalKg > 0 ? Units.fromKg(goalKg, to: unit).rounded(toPlaces: 1) : defaultGoal()
    }
    private func defaultGoal() -> Double {
        unit == .kg ? 70 : 154
    }
}
