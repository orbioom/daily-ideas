import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DrinkLog.date, order: .reverse) private var allLogs: [DrinkLog]
    @Query(sort: \DrinkType.order) private var drinkTypes: [DrinkType]

    // Observe keys that influence the goal/units so the ring stays in sync.
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue
    @AppStorage("useSmartGoal") private var useSmartGoal = true
    @AppStorage("manualGoalML") private var manualGoalML = 2500.0
    @AppStorage("weightKg") private var weightKg = 70.0
    @AppStorage("activityLevel") private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage("climate") private var climateRaw = Climate.temperate.rawValue

    @State private var showSettings = false
    @State private var customDrink: DrinkType?

    private let engine = HydrationEngine()
    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }
    private var goal: Double { GoalSettings.goalML }

    private var todayLogs: [DrinkLog] { engine.logs(allLogs, on: .now) }
    private var effective: Double { engine.effectiveTotal(todayLogs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        ringCard
                        quickAdd
                        todayLogList
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $customDrink) { type in
                CustomAmountSheet(type: type) { ml in add(type, volumeML: ml) }
            }
        }
    }

    private var ringCard: some View {
        VStack(spacing: 14) {
            WaterRing(
                fraction: goal > 0 ? effective / goal : 0,
                centerTop: Units.headline(effective, as: unit),
                centerBottom: "of \(Units.headline(goal, as: unit))"
            )
            HStack(spacing: 24) {
                stat(Units.string(max(0, goal - effective), as: unit), effective >= goal ? "done!" : "to go")
                stat("\(Int((goal > 0 ? effective / goal : 0) * 100))%", "of goal")
                stat("\(Int(engine.caffeineTotal(todayLogs))) mg", "caffeine")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick add").font(.headline).foregroundStyle(Brand.text)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(drinkTypes.prefix(8)) { type in
                    Button {
                        add(type, volumeML: type.defaultVolumeML)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.symbol)
                                .font(.title3)
                                .foregroundStyle(Color(hex: type.colorHex))
                            Text(Units.string(type.defaultVolumeML, as: unit))
                                .font(Brand.mono(10))
                                .foregroundStyle(Brand.text2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(LongPressGesture().onEnded { _ in customDrink = type })
                    .accessibilityLabel("Add \(type.name), \(Units.string(type.defaultVolumeML, as: unit)). Long press for a custom amount.")
                }
            }
            Text("Tip: long-press a drink for a custom amount.")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    @ViewBuilder
    private var todayLogList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's log").font(.headline).foregroundStyle(Brand.text)
            if todayLogs.isEmpty {
                Text("Nothing logged yet. Tap a drink above to start.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(todayLogs) { log in
                    HStack(spacing: 12) {
                        Image(systemName: log.drinkSymbol)
                            .foregroundStyle(Color(hex: log.drinkColorHex))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(log.drinkName).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text(log.date, format: .dateTime.hour().minute())
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Units.string(log.volumeML, as: unit))
                                .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                            if log.hydrationFactor < 1.0 {
                                Text("≈\(Units.string(log.effectiveML, as: unit)) effective")
                                    .font(.caption2).foregroundStyle(Brand.text3)
                            }
                        }
                        Button {
                            context.delete(log); Haptics.warning()
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(Brand.text3)
                        }
                        .accessibilityLabel("Remove \(log.drinkName)")
                    }
                }
            }
        }
        .glassCard()
    }

    private func add(_ type: DrinkType, volumeML: Double) {
        let before = effective
        let log = DrinkLog(from: type, volumeML: volumeML)
        let after = before + log.effectiveML
        context.insert(log)
        // Celebrate the moment the goal is first reached today.
        if goal > 0 && before < goal && after >= goal { Haptics.success() } else { Haptics.tap() }
    }
}
