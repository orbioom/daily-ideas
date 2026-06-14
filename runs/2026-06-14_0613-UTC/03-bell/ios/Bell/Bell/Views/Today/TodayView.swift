import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Binding var activePreset: Preset?

    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]
    @Query(sort: \Preset.sortOrder) private var presets: [Preset]

    @State private var showSetup = false

    private var minutesToday: Int { Stats.minutesToday(sessions) }
    private var streak: Int { Stats.currentStreak(sessions) }
    private var totalMinutes: Int { Stats.totalMinutes(sessions) }
    private var goal: Int { max(1, settings.dailyMinutesGoal) }
    private var ringProgress: Double { min(1, Double(minutesToday) / Double(goal)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    goalRing
                    statsRow
                    quickStart
                    beginButton
                }
                .padding(Theme.spacing)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Today")
            .sheet(isPresented: $showSetup) {
                SessionSetupView(activePreset: $activePreset)
            }
        }
    }

    // MARK: - Goal ring
    private var goalRing: some View {
        Card {
            VStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: ringProgress, lineWidth: 14)
                        .frame(width: 168, height: 168)
                    VStack(spacing: 2) {
                        Text("\(minutesToday)")
                            .font(Theme.rounded(44, .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("of \(goal) min")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.top, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Today's progress")
                .accessibilityValue("\(minutesToday) of \(goal) minutes, \(Int(ringProgress * 100)) percent")

                Text(minutesToday >= goal
                     ? "Goal complete. Beautiful."
                     : minutesToday == 0
                       ? "Your cushion is waiting."
                       : "\(goal - minutesToday) min to your goal.")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(minutesToday >= goal ? Theme.success : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak",
                     symbol: "flame", tint: Theme.warning)
            StatTile(value: "\(totalMinutes)", label: "lifetime min",
                     symbol: "hourglass", tint: Theme.accent)
            StatTile(value: "\(sessions.count)", label: "sessions",
                     symbol: "circle.hexagongrid", tint: Theme.accentDeep)
        }
    }

    // MARK: - Quick start chips
    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick start")
            if presets.isEmpty {
                Text("Create a preset to quick-start a sit.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(presets) { preset in
                            Button {
                                activePreset = preset
                            } label: {
                                presetChip(preset)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func presetChip(_ preset: Preset) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: preset.bellValue.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(preset.name)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Text(preset.isOpenEnded ? "Open" : "\(preset.durationMin) min")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(width: 130, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.name), \(preset.isOpenEnded ? "open ended" : "\(preset.durationMin) minutes")")
        .accessibilityHint("Begins this sit")
    }

    // MARK: - Begin
    private var beginButton: some View {
        PrimaryButton(title: "Begin a sit", systemImage: "circle.fill") {
            showSetup = true
        }
        .padding(.top, 4)
    }
}
