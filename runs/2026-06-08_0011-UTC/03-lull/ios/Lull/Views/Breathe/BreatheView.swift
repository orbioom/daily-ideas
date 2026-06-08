import SwiftUI
import SwiftData

struct BreatheView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BreathPattern.order) private var patterns: [BreathPattern]
    @Query(sort: \BreathSession.date, order: .reverse) private var sessions: [BreathSession]

    @AppStorage("lull.selectedPattern") private var selectedID = ""
    @AppStorage("lull.dailyGoalMin") private var dailyGoal = 5

    @State private var playing: BreathPattern?

    private var selected: BreathPattern? {
        patterns.first { $0.id.uuidString == selectedID } ?? patterns.first
    }
    private var stats: SessionStats { SessionStats.make(from: sessions) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        goalRing
                        if let pattern = selected {
                            selectedCard(pattern)
                            Button {
                                playing = pattern
                            } label: {
                                Label("Begin session", systemImage: "play.fill")
                            }
                            .buttonStyle(InkButtonStyle())
                        } else {
                            EmptyStateView(icon: "wind", title: "No patterns",
                                           message: "Add a breathing pattern to begin.")
                        }
                        quickPatterns
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Lull")
            .fullScreenCover(item: $playing) { pattern in
                SessionPlayerView(pattern: pattern)
            }
        }
    }

    private var goalRing: some View {
        let progress = dailyGoal > 0 ? min(1, stats.todayMinutes / Double(dailyGoal)) : 0
        return GlassCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle().stroke(Brand.hairline, lineWidth: 9).frame(width: 76, height: 76)
                    Circle().trim(from: 0, to: max(0.001, progress))
                        .stroke(Brand.magic, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 76, height: 76)
                    Image(systemName: progress >= 1 ? "checkmark" : "wind")
                        .foregroundStyle(progress >= 1 ? Brand.live : Brand.text2)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Format.minutes(stats.todayMinutes)) today")
                        .font(.headline).foregroundStyle(Brand.text)
                    Text("Goal \(dailyGoal) min · \(stats.streakDays) day streak")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func selectedCard(_ pattern: BreathPattern) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "SELECTED PATTERN")
                Text(pattern.name).font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
                Text(pattern.detail).font(.subheadline).foregroundStyle(Brand.text2)
                HStack(spacing: 14) {
                    metric(pattern.ratioLabel, "ratio")
                    metric("\(pattern.rounds)", "rounds")
                    metric(Format.minutes(pattern.totalSeconds / 60), "length")
                }
                .padding(.top, 4)
            }
        }
    }

    private func metric(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(v).font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickPatterns: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "QUICK START")
            ForEach(patterns.prefix(4)) { p in
                Button {
                    selectedID = p.id.uuidString
                    Haptics.selection()
                } label: {
                    HStack {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(Brand.magic)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text("\(p.ratioLabel) · \(Format.minutes(p.totalSeconds/60))")
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        if p.id.uuidString == (selected?.id.uuidString ?? "") {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.live)
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
