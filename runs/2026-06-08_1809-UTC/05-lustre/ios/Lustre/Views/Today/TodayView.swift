import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var steps: [RoutineStep]
    @Query private var logs: [RoutineLog]
    @Query private var products: [Product]

    @State private var routine: RoutineKind = defaultRoutine()
    @State private var showSkinCheck = false
    @State private var showSettings = false

    private let cal = Calendar.current

    private static func defaultRoutine() -> RoutineKind {
        Calendar.current.component(.hour, from: .now) >= 16 ? .pm : .am
    }

    private var routineSteps: [RoutineStep] { SkincareEngine.steps(steps, for: routine) }

    private var todayLog: RoutineLog? {
        logs.first { $0.routine == routine && cal.isDateInToday($0.date) }
    }

    private var doneSet: Set<String> { Set(todayLog?.doneStepUUIDs ?? []) }

    private var progress: Double {
        guard !routineSteps.isEmpty else { return 0 }
        return Double(SkincareEngine.completedCount(routineSteps: routineSteps, log: todayLog)) / Double(routineSteps.count)
    }

    private var streak: Int { SkincareEngine.streak(logs: logs, steps: steps) }

    private var expiringSoon: [Product] {
        products.filter { !$0.isFinished }.filter {
            let s = SkincareEngine.expiry(for: $0).state
            return s == .expiringSoon || s == .expired
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    routinePicker
                    headerCard
                    if !expiringSoon.isEmpty { expiryBanner }
                    stepsCard
                    skinCheckCard
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSkinCheck) { SkinLogEditorView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var routinePicker: some View {
        Picker("Routine", selection: $routine) {
            ForEach(RoutineKind.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var headerCard: some View {
        HStack(spacing: 18) {
            RoutineRing(progress: progress) {
                Image(systemName: routine.icon)
                    .font(.title2).foregroundStyle(Color(hex: 0x9E7BA8))
            }
            .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title + " routine").font(.headline).foregroundStyle(Brand.text)
                Text(routineSteps.isEmpty ? "No steps yet" :
                        "\(SkincareEngine.completedCount(routineSteps: routineSteps, log: todayLog)) of \(routineSteps.count) done")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(streak > 0 ? Brand.magic : Brand.text3)
                    Text(Format.streakText(streak)).font(.caption).foregroundStyle(Brand.text2)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    private var expiryBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark").foregroundStyle(Brand.warn)
            Text("\(expiringSoon.count) product\(expiringSoon.count == 1 ? "" : "s") need attention on your shelf.")
                .font(.caption).foregroundStyle(Brand.text2)
            Spacer()
        }
        .padding(12)
        .background(Brand.warn.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Steps")
            if routineSteps.isEmpty {
                Text("Add steps to this routine in the Routines tab.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(Array(routineSteps.enumerated()), id: \.element.uuid) { idx, step in
                    Button { toggle(step) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: doneSet.contains(step.uuid) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(doneSet.contains(step.uuid) ? Brand.live : Brand.text3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(idx + 1). \(step.displayName)")
                                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    .strikethrough(doneSet.contains(step.uuid), color: Brand.text3)
                                Text(step.product?.category.title ?? step.displayCategory)
                                    .font(.caption2).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            if let p = step.product {
                                Image(systemName: p.category.icon).foregroundStyle(p.category.color)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(doneSet.contains(step.uuid) ? "Done" : "Not done")
                }
                if progress >= 1 {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Brand.live)
                        Text("Routine complete. Lovely.").font(.subheadline.weight(.medium)).foregroundStyle(Brand.live)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var skinCheckCard: some View {
        Button { showSkinCheck = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "face.smiling").font(.title2).foregroundStyle(Color(hex: 0x9E7BA8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("How's your skin today?").font(.headline).foregroundStyle(Brand.text)
                    Text("A 10-second check-in").font(.caption).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ step: RoutineStep) {
        let log: RoutineLog
        if let existing = todayLog {
            log = existing
        } else {
            log = RoutineLog(date: .now, routine: routine)
            context.insert(log)
        }
        if let idx = log.doneStepUUIDs.firstIndex(of: step.uuid) {
            log.doneStepUUIDs.remove(at: idx)
            Haptics.tap()
        } else {
            log.doneStepUUIDs.append(step.uuid)
            Haptics.tap()
        }
        let complete = SkincareEngine.isComplete(routineSteps: routineSteps, log: log)
        if complete { Haptics.success() }
        try? context.save()
    }
}

/// Progress ring for routine completion.
struct RoutineRing<Center: View>: View {
    let progress: Double
    @ViewBuilder var center: Center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0x9E7BA8).opacity(0.16), lineWidth: 9)
            Circle().trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(Color(hex: 0x9E7BA8), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.5), value: progress)
            center
        }
        .accessibilityHidden(true)
    }
}
