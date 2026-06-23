import SwiftUI

/// Length picker + technique summary shown before starting a session.
/// For rounds-based techniques the length is fixed by the pattern, so the picker
/// is replaced by a round summary.
struct SessionSetupSheet: View {
    let pattern: BreathPattern
    let defaultMinutes: Int
    var onStart: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int

    private let options = [2, 3, 5, 8, 10, 15, 20]

    init(pattern: BreathPattern, defaultMinutes: Int, onStart: @escaping (Int) -> Void) {
        self.pattern = pattern
        self.defaultMinutes = defaultMinutes
        self.onStart = onStart
        let clamped = max(2, min(20, defaultMinutes))
        _minutes = State(initialValue: clamped)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    summary
                    if pattern.isRounds {
                        roundsInfo
                    } else {
                        lengthPicker
                    }
                    detailText
                }
                .padding(Theme.Spacing.md)
            }
            .emberScreenBackground()
            .navigationTitle("Set Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.shared.tap()
                    onStart(pattern.isRounds ? estimatedRoundsMinutes : minutes)
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle().fill(pattern.style.accent.opacity(0.2)).frame(width: 84, height: 84)
                Image(systemName: pattern.style.systemImage)
                    .font(.system(size: 34))
                    .foregroundStyle(pattern.style.accent)
                    .accessibilityHidden(true)
            }
            Text(pattern.name).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(pattern.subtitle).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Text(pattern.rhythmLabel)
                .font(.callout.monospaced())
                .foregroundStyle(pattern.style.accent)
        }
        .frame(maxWidth: .infinity)
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Session Length", subtitle: "\(minutes) minutes")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { value in
                    Button {
                        Haptics.shared.tap()
                        minutes = value
                    } label: {
                        Text("\(value)m")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                    .fill(minutes == value ? pattern.style.accent.opacity(0.22) : Theme.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                    .strokeBorder(minutes == value ? pattern.style.accent : Theme.textSecondary.opacity(0.2),
                                                  lineWidth: minutes == value ? 2 : 1)
                            )
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) minutes")
                    .accessibilityAddTraits(minutes == value ? [.isSelected] : [])
                }
            }
        }
        .emberCard()
    }

    private var roundsInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Round Structure")
            infoRow("Rounds", "\(pattern.roundCount)")
            infoRow("Power breaths", "\(pattern.powerBreaths) per round")
            infoRow("Retention hold", "\(Int(pattern.retentionSeconds))s on empty")
            infoRow("Recovery hold", "\(Int(pattern.recoverySeconds))s on full")
            infoRow("Estimated", "~\(estimatedRoundsMinutes) min")
        }
        .emberCard()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private var detailText: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "About")
            Text(pattern.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .emberCard()
    }

    private var estimatedRoundsMinutes: Int {
        let perRound = Double(pattern.powerBreaths) * 3.0 + pattern.retentionSeconds + pattern.recoverySeconds
        let total = perRound * Double(pattern.roundCount)
        return max(1, Int((total / 60).rounded()))
    }
}

#Preview {
    SessionSetupSheet(pattern: PatternLibrary.all[0], defaultMinutes: 5) { _ in }
}
