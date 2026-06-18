import SwiftUI
import SwiftData

/// Sheet to add a custom quick timer (label + minutes + optional seconds).
struct QuickTimerSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var minutes = 10
    @State private var seconds = 0

    private let presets: [(String, Int)] = [
        ("Fries", 16), ("Wings", 24), ("Salmon", 9), ("Veggies", 12), ("Bacon", 9), ("Reheat", 4),
    ]

    private var totalSeconds: Int {
        max(1, minutes * 60 + seconds)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        labelField
                        durationCard
                        presetsCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") { start() }
                        .font(Theme.roundedStyle(.body, .bold))
                        .disabled(totalSeconds < 1)
                }
            }
        }
    }

    private var labelField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField("e.g. Crispy fries", text: $label)
                .textFieldStyle(.plain)
                .font(Theme.roundedStyle(.body))
                .padding(14)
                .crispCard(radius: Theme.chipRadius)
        }
    }

    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 0) {
                Picker("Minutes", selection: $minutes) {
                    ForEach(0...90, id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Seconds", selection: $seconds) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) {
                        Text("\($0) sec").tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 140)
            Text("Total: \(Fmt.clock(seconds: totalSeconds))")
                .font(Theme.roundedStyle(.subheadline, .bold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .monospacedDigit()
        }
        .padding(16)
        .crispCard()
    }

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick presets")
                .font(Theme.roundedStyle(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(presets, id: \.0) { preset in
                    Button {
                        label = preset.0
                        minutes = preset.1
                        seconds = 0
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        VStack(spacing: 2) {
                            Text(preset.0)
                                .font(Theme.roundedStyle(.subheadline, .bold))
                            Text("\(preset.1)m")
                                .font(Theme.roundedStyle(.caption))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .crispCard(radius: Theme.chipRadius)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .crispCard()
    }

    private func start() {
        let finalLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        timerEngine.start(
            label: finalLabel.isEmpty ? "Timer" : finalLabel,
            seconds: totalSeconds,
            foodId: nil,
            context: context,
            soundEnabled: true
        )
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
