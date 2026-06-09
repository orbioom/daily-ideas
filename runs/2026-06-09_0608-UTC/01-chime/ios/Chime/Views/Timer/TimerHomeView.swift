import SwiftUI
import SwiftData

struct TimerHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeditationPreset.sortIndex) private var presets: [MeditationPreset]
    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]

    @State private var selected: MeditationPreset?
    @State private var active: MeditationPreset?

    private var summary: StatsEngine.Summary { StatsEngine.summary(sessions) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    streakHeader
                    if presets.isEmpty {
                        EmptyStateView(icon: "slider.horizontal.3",
                                       title: "No presets yet",
                                       message: "Create a preset in the Presets tab to start your first sit.")
                            .glassCard()
                    } else {
                        chooseCard
                        startButton
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Chime")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selected == nil { selected = presets.first }
            }
            .fullScreenCover(item: $active, onDismiss: { selected = selected ?? presets.first }) { preset in
                SessionPlayerView(preset: preset)
            }
        }
    }

    private var streakHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    StatusDot(color: summary.currentStreak > 0 ? Brand.live : Brand.text3)
                    Eyebrow(text: "Practice")
                }
                Text(summary.currentStreak > 0 ? "\(summary.currentStreak)-day streak" : "Begin again")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text("\(summary.totalMinutes) min over \(summary.totalSessions) sits")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            ZStack {
                ProgressRing(progress: min(1, Double(summary.thisWeekMinutes) / 150.0),
                             lineWidth: 9, tint: Brand.magic)
                    .frame(width: 64, height: 64)
                VStack(spacing: 0) {
                    Text("\(summary.thisWeekMinutes)")
                        .font(Brand.mono(16, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text("wk").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard(padding: 18)
        .accessibilityElement(children: .combine)
    }

    private var chooseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Choose a sit")
            ForEach(presets) { preset in
                Button {
                    Haptics.selection()
                    withAnimation(Brand.ease(0.25)) { selected = preset }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: preset.startBell.symbol)
                            .font(.title3)
                            .foregroundStyle(selected == preset ? Brand.magic : Brand.text3)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            Text(preset.subtitle)
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Image(systemName: selected == preset ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected == preset ? Brand.live : Brand.text3)
                            .accessibilityHidden(true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected == preset ? Brand.magic.opacity(0.10) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(selected == preset ? Brand.magic.opacity(0.4) : Brand.hairline,
                                          lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(preset.name), \(preset.subtitle)")
                .accessibilityAddTraits(selected == preset ? [.isSelected] : [])
            }
        }
        .glassCard()
    }

    private var startButton: some View {
        Button {
            guard let s = selected else { return }
            Haptics.tap()
            active = s
        } label: {
            Label("Begin sit", systemImage: "play.fill")
        }
        .buttonStyle(InkButtonStyle())
        .disabled(selected == nil)
    }
}
