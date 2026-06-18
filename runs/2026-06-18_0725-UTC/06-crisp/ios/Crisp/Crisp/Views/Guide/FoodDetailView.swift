import SwiftUI
import SwiftData

struct FoodDetailView: View {
    let food: Food

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var favorites: [FavoriteFood]
    @Query(filter: #Predicate<CookTimer> { $0.isActive }) private var activeTimers: [CookTimer]

    @State private var isFrozen = false
    @State private var portionSteps = 1            // multiples of base portion (1...8)
    @State private var toast: ToastMessage? = nil
    @State private var showPaywall = false

    private var requestedGrams: Double {
        food.basePortionGrams * Double(max(1, portionSteps))
    }

    private var result: CookEngine.Result {
        CookEngine.compute(
            food: food,
            frozen: isFrozen,
            requestedGrams: requestedGrams,
            includePreheat: settings.includePreheat
        )
    }

    private var isFavorite: Bool {
        favorites.contains { $0.foodId == food.id }
    }

    private var runningCount: Int {
        activeTimers.filter { !$0.isFinished() }.count
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    if food.hasFrozenVariant { freshFrozenToggle }
                    portionCard
                    if let flip = result.shakeOrFlipAtMin { flipCard(flip) }
                    if let internalF = food.targetInternalTempF { donenessCard(internalF) }
                    tipsCard
                    actionButtons
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .toast($toast)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear {
            portionSteps = max(1, min(settings.safeDefaultServings, 8))
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 14) {
            Text(food.icon)
                .font(.system(size: 56))
                .accessibilityHidden(true)
            HStack(spacing: 28) {
                bigStat(
                    value: "\(Fmt.tempValue(fahrenheit: result.tempF, unit: settings.tempUnit))°",
                    unit: settings.tempUnit == .fahrenheit ? "F" : "C",
                    label: "Temp",
                    icon: "thermometer.high"
                )
                Rectangle().fill(Theme.hairline).frame(width: 1, height: 64)
                bigStat(
                    value: "\(result.minutes)",
                    unit: "min",
                    label: "Time",
                    icon: "clock.fill"
                )
            }
            if result.preheatAdded {
                Label("Includes \(CookEngine.preheatMinutes) min preheat", systemImage: "flame")
                    .font(Theme.roundedStyle(.caption, .medium))
                    .foregroundStyle(Theme.warn)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .crispCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(food.name): \(Fmt.temp(fahrenheit: result.tempF, unit: settings.tempUnit)) for \(Fmt.minutesLabel(result.minutes))")
    }

    private func bigStat(value: String, unit: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.rounded(46, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(unit)
                    .font(Theme.roundedStyle(.headline, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text(label)
                .font(Theme.roundedStyle(.caption, .medium))
                .foregroundStyle(Theme.inkSoft)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fresh / Frozen

    private var freshFrozenToggle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Starting state")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Picker("Starting state", selection: $isFrozen) {
                Text("Fresh").tag(false)
                Text("From frozen").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: isFrozen) { _, _ in
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        }
        .padding(16)
        .crispCard()
    }

    // MARK: - Portion

    private var portionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portion")
                    .font(Theme.roundedStyle(.headline, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(Fmt.weight(grams: requestedGrams, unit: settings.weightUnit))
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            HStack(spacing: 14) {
                stepButton(symbol: "minus", disabled: portionSteps <= 1) {
                    if portionSteps > 1 { portionSteps -= 1 }
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                VStack(spacing: 2) {
                    Text("×\(portionSteps)")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text(food.basePortionLabel)
                        .font(Theme.roundedStyle(.caption))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                stepButton(symbol: "plus", disabled: portionSteps >= 8) {
                    if portionSteps < 8 { portionSteps += 1 }
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            }
            Text("Time auto-scales with your batch — bigger loads take a little longer, not linearly.")
                .font(Theme.roundedStyle(.caption))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .crispCard()
        .accessibilityElement(children: .contain)
    }

    private func stepButton(symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 52, height: 52)
                .foregroundStyle(disabled ? Theme.inkSoft : .white)
                .background(Circle().fill(disabled ? Theme.surfaceAlt : Theme.accent))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(symbol == "plus" ? "Increase portion" : "Decrease portion")
    }

    // MARK: - Flip reminder

    private func flipCard(_ flip: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Shake or flip at \(flip) min")
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("About halfway — keeps everything cooking evenly.")
                    .font(Theme.roundedStyle(.caption))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .crispCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Doneness

    private func donenessCard(_ internalF: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Cook to \(Fmt.temp(fahrenheit: internalF, unit: settings.tempUnit)) inside")
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Check the thickest part with a probe for a safe result.")
                    .font(Theme.roundedStyle(.caption))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .crispCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tips

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tips", systemImage: "lightbulb.fill")
                .font(Theme.roundedStyle(.subheadline, .bold))
                .foregroundStyle(Theme.accent)
            Text(food.notes)
                .font(Theme.roundedStyle(.subheadline))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .crispCard()
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Start \(result.minutes)-min timer", systemImage: "play.fill") {
                startTimer()
            }
            PrimaryButton(
                title: isFavorite ? "Saved to favorites" : "Add to favorites",
                systemImage: isFavorite ? "heart.fill" : "heart",
                fill: false
            ) {
                toggleFavorite()
            }
        }
    }

    // MARK: - Logic

    private func startTimer() {
        if runningCount >= pro.timerCap() {
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
            showPaywall = true
            return
        }
        let seconds = max(1, result.minutes * 60)
        timerEngine.start(
            label: food.name,
            seconds: seconds,
            foodId: food.id,
            context: context,
            soundEnabled: true
        )
        // Log the cook so Stats stays meaningful.
        context.insert(CookLog(
            foodId: food.id, name: food.name, date: .now,
            tempF: result.tempF, minutes: result.minutes
        ))
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "timer", text: "Timer started for \(food.name)")
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.foodId == food.id }) {
            context.delete(existing)
            toast = ToastMessage(symbol: "heart.slash", text: "Removed from favorites")
        } else {
            context.insert(FavoriteFood(foodId: food.id))
            toast = ToastMessage(symbol: "heart.fill", text: "Added to favorites")
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
        }
        try? context.save()
    }
}
