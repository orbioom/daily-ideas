import SwiftUI
import SwiftData

/// A standalone what-if calculator: enter a daily load (or import a saved
/// system's total) and Reserve recommends the battery and solar to match.
struct SizingView: View {
    @Query(sort: \PowerSystem.createdAt, order: .reverse) private var systems: [PowerSystem]

    @AppStorage(PrefKey.defaultChemistry) private var defaultChemistryRaw = Chemistry.lifepo4.rawValue
    @AppStorage(PrefKey.defaultSunHours) private var defaultSunHours = 4.5

    @State private var dailyWh = 1200.0
    @State private var desiredDays = 2
    @State private var systemVoltage = 12
    @State private var chemistry: Chemistry = .lifepo4
    @State private var peakSunHours = 4.5
    @State private var solarEfficiency = 0.75
    @State private var chargeEfficiency = 0.85
    @State private var importSelection: UUID?
    @State private var primed = false

    private let voltages = [12, 24, 48]

    private var usableDoD: Double { chemistry.defaultDoD }

    private var recommendedBatteryAh: Double {
        PowerEngine.recommendedBatteryAh(
            dailyWh: dailyWh,
            days: Double(desiredDays),
            systemVoltage: systemVoltage,
            usableDoD: usableDoD
        )
    }

    private var recommendedSolarW: Double {
        PowerEngine.recommendedSolarW(
            dailyWh: dailyWh,
            peakSunHours: peakSunHours,
            solarEfficiency: solarEfficiency,
            chargeEfficiency: chargeEfficiency
        )
    }

    private var dailyAh: Double {
        systemVoltage > 0 ? dailyWh / Double(systemVoltage) : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    consumptionCard
                    targetsCard
                    solarCard
                    resultsCard
                    guidanceCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Sizing")
            .onAppear(perform: primeIfNeeded)
        }
    }

    // MARK: - Consumption

    private var consumptionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(text: "Daily consumption")
                HStack {
                    Text("Energy per day")
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Fmt.wh(dailyWh))
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $dailyWh, in: 100...8000, step: 50)
                InfoRow(label: "Equivalent draw", value: Fmt.ah(dailyAh), mono: true)

                if !systems.isEmpty {
                    Divider().overlay(Brand.hairline)
                    Text("Import from a saved system")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    Picker("Import", selection: $importSelection) {
                        Text("None").tag(UUID?.none)
                        ForEach(systems) { system in
                            Text(system.name.isEmpty ? "Untitled" : system.name)
                                .tag(UUID?.some(system.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Brand.text)
                    .onChange(of: importSelection) { _, newValue in
                        importSystem(id: newValue)
                    }
                }
            }
        }
    }

    // MARK: - Targets

    private var targetsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(text: "Targets")
                Stepper(value: $desiredDays, in: 1...14) {
                    HStack {
                        Text("Days of autonomy")
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(desiredDays)")
                            .font(Brand.mono(16, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                }
                Picker("System voltage", selection: $systemVoltage) {
                    ForEach(voltages, id: \.self) { Text("\($0) V").tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Chemistry", selection: $chemistry) {
                    ForEach(Chemistry.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Brand.text)
                InfoRow(label: "Usable DoD", value: Fmt.percent(usableDoD), mono: true)
            }
        }
    }

    // MARK: - Solar inputs

    private var solarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(text: "Solar assumptions")
                sliderRow("Peak sun hours", value: $peakSunHours, range: 1...8, step: 0.5, text: "\(Fmt.dec1(peakSunHours)) h")
                sliderRow("Solar derate", value: $solarEfficiency, range: 0.4...1.0, step: 0.05, text: Fmt.percent(solarEfficiency))
                sliderRow("Charge efficiency", value: $chargeEfficiency, range: 0.6...1.0, step: 0.05, text: Fmt.percent(chargeEfficiency))
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).foregroundStyle(Brand.text2)
                Spacer()
                Text(text)
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    // MARK: - Results

    private var resultsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Recommended build")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(value: Fmt.ah(recommendedBatteryAh), label: "Battery bank", accent: Brand.live)
                    StatTile(value: Fmt.watts(recommendedSolarW), label: "Solar array", accent: Brand.warn)
                }
                InfoRow(label: "Stored energy", value: Fmt.wh(recommendedBatteryAh * Double(systemVoltage) * usableDoD), mono: true)
                InfoRow(label: "Break-even harvest", value: Fmt.wh(dailyWh), mono: true)
            }
        }
        .animation(Brand.ease(0.3), value: recommendedBatteryAh)
        .animation(Brand.ease(0.3), value: recommendedSolarW)
    }

    // MARK: - Guidance

    private var guidanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "In plain English")
                Text(guidanceSentence)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var guidanceSentence: String {
        let bank = Fmt.ah(recommendedBatteryAh)
        let solar = Fmt.watts(recommendedSolarW)
        return "To run \(Fmt.wh(dailyWh)) a day through \(desiredDays) day\(desiredDays == 1 ? "" : "s") with no sun, you want about \(bank) of \(chemistry.label) at \(systemVoltage) V. To break even on a \(Fmt.dec1(peakSunHours))-hour solar day, plan on roughly \(solar) of panels."
    }

    // MARK: - Helpers

    private func primeIfNeeded() {
        guard !primed else { return }
        primed = true
        chemistry = Chemistry(rawValue: defaultChemistryRaw) ?? .lifepo4
        peakSunHours = defaultSunHours
    }

    private func importSystem(id: UUID?) {
        guard let id, let system = systems.first(where: { $0.id == id }) else { return }
        let r = PowerEngine.evaluate(system)
        dailyWh = max(100, min(8000, r.systemDailyWh.rounded()))
        systemVoltage = system.systemVoltage
        chemistry = system.chemistry
        peakSunHours = system.peakSunHours
        solarEfficiency = system.solarEfficiency
        chargeEfficiency = system.chargeEfficiency
        Haptics.selection()
    }
}

#Preview {
    SizingView()
        .modelContainer(for: [PowerSystem.self, Load.self], inMemory: true)
}
