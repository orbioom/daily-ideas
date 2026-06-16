import SwiftUI
import SwiftData

struct TimersView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(TimerEngine.self) private var engine
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @Query(sort: \KitchenTimer.createdAt) private var timers: [KitchenTimer]

    @State private var showingSettings = false
    @State private var showingAdd = false
    @State private var showingPaywall = false

    private var atFreeLimit: Bool { !isPro && timers.count >= FreeTier.maxTimers }

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                if timers.isEmpty {
                    EmptyStateView(
                        symbol: "timer",
                        title: "No timers",
                        message: "Add a named timer — pasta, oven, proof — and run as many as you like at once.",
                        actionTitle: "Add a timer",
                        action: addTapped
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Timers")
            .toolbar {
                settingsToolbar($showingSettings)
                ToolbarItem(placement: .topBarLeading) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add timer")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingAdd) { AddTimerSheet() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Timer done", isPresented: bindingFiredAlert) {
                Button("OK") { engine.acknowledge() }
            } message: {
                Text("\(engine.firedTimerLabel) has finished.")
            }
        }
    }

    private var bindingFiredAlert: Binding<Bool> {
        Binding(get: { engine.showingFiredAlert }, set: { if !$0 { engine.acknowledge() } })
    }

    private var content: some View {
        // A single TimelineView drives every timer's live countdown.
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            ScrollView {
                VStack(spacing: 14) {
                    if atFreeLimit {
                        Button { showingPaywall = true } label: {
                            Label("Free plan: \(FreeTier.maxTimers) timers. Upgrade for unlimited.", systemImage: "lock")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)
                    }
                    ForEach(timers) { timer in
                        TimerCard(timer: timer, now: timeline.date)
                    }
                }
                .padding(16)
            }
            .onChange(of: timeline.date) { _, newDate in
                engine.evaluate(timers: timers, at: newDate, context: context)
            }
        }
    }

    private func addTapped() {
        if atFreeLimit { showingPaywall = true } else { showingAdd = true }
    }
}

private struct TimerCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(TimerEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timer: KitchenTimer
    let now: Date

    private var remaining: Int { timer.remaining(at: now) }
    private var progress: Double {
        guard timer.totalSeconds > 0 else { return 0 }
        return min(1, max(0, Double(remaining) / Double(timer.totalSeconds)))
    }
    private var isDone: Bool { !timer.isRunning && timer.remainingWhenPaused <= 0 }

    var body: some View {
        GalleyCard {
            VStack(spacing: 14) {
                HStack {
                    Text(timer.label)
                        .font(.headline)
                        .foregroundStyle(GalleyTheme.primaryText(scheme))
                    Spacer()
                    Button(role: .destructive) { delete() } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                    }
                    .accessibilityLabel("Delete \(timer.label)")
                }

                ZStack {
                    Circle()
                        .stroke(GalleyTheme.subtleSurface(scheme), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timer.isRunning ? GalleyTheme.terracotta : GalleyTheme.sage,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .linear(duration: 0.4), value: progress)
                    VStack(spacing: 2) {
                        Text(Self.format(remaining))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(isDone ? GalleyTheme.terracotta : GalleyTheme.primaryText(scheme))
                        Text(stateLabel)
                            .font(.caption)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                    }
                }
                .frame(width: 160, height: 160)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(timer.label) timer")
                .accessibilityValue("\(Self.spokenRemaining(remaining)), \(stateLabel)")

                controls
            }
        }
    }

    private var stateLabel: String {
        if isDone { return "Done" }
        return timer.isRunning ? "Running" : "Paused"
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 10) {
            if timer.isRunning {
                Button { engine.pause(timer, context: context) } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(GalleySecondaryButtonStyle())
            } else {
                Button { engine.start(timer, context: context) } label: {
                    Label(isDone ? "Restart" : "Start", systemImage: "play.fill")
                }
                .buttonStyle(GalleyPrimaryButtonStyle())
            }
            Button { engine.reset(timer, context: context) } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(GalleySecondaryButtonStyle())
        }
    }

    private func delete() {
        if timer.isRunning { engine.pause(timer, context: context) }
        context.delete(timer)
        try? context.save()
    }

    static func format(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    static func spokenRemaining(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) hour\(h == 1 ? "" : "s")") }
        if m > 0 { parts.append("\(m) minute\(m == 1 ? "" : "s")") }
        if sec > 0 || parts.isEmpty { parts.append("\(sec) second\(sec == 1 ? "" : "s")") }
        return parts.joined(separator: " ") + " remaining"
    }
}

/// Add a timer with a label and an hours/minutes/seconds wheel.
struct AddTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @State private var label = ""
    @State private var hours = 0
    @State private var minutes = 10
    @State private var seconds = 0

    private var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }
    private var canSave: Bool { totalSeconds > 0 }

    private let presets: [(String, Int)] = [
        ("Soft egg", 6 * 60), ("Pasta", 9 * 60), ("Tea", 4 * 60), ("Rice", 18 * 60)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("e.g. Pasta", text: $label)
                        .accessibilityLabel("Timer label")
                }
                Section("Duration") {
                    HStack(spacing: 0) {
                        wheel("hr", value: $hours, range: 0...12)
                        wheel("min", value: $minutes, range: 0...59)
                        wheel("sec", value: $seconds, range: 0...59)
                    }
                    .frame(height: 130)
                    .accessibilityElement(children: .contain)
                }
                Section("Quick presets") {
                    ForEach(presets, id: \.0) { preset in
                        Button {
                            if label.isEmpty { label = preset.0 }
                            hours = preset.1 / 3600
                            minutes = (preset.1 % 3600) / 60
                            seconds = preset.1 % 60
                        } label: {
                            HStack {
                                Text(preset.0)
                                Spacer()
                                Text(TimerCard.format(preset.1))
                                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }.disabled(!canSave)
                }
            }
        }
    }

    private func wheel(_ unit: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 2) {
            Picker(unit, selection: value) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            Text(unit)
                .font(.caption)
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
        }
        .accessibilityLabel("\(unit), \(value.wrappedValue)")
    }

    private func add() {
        let name = label.trimmingCharacters(in: .whitespaces).isEmpty ? "Timer" : label.trimmingCharacters(in: .whitespaces)
        let timer = KitchenTimer(label: name, totalSeconds: totalSeconds)
        context.insert(timer)
        try? context.save()
        Haptics.light()
        dismiss()
    }
}
