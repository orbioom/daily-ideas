import SwiftUI
import SwiftData
import Charts

struct NightDetailView: View {
    @Bindable var session: NightSession
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let score = SnoreEngine.score(for: session)
                HStack(spacing: 20) {
                    ScoreDial(score: score, size: 120)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(SnoreEngine.grade(forScore: score).label)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.inkPrimary(scheme))
                        Text(SnoreEngine.grade(forScore: score).detail)
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                        Text("\(session.startedAt.formatted(date: .omitted, time: .shortened)) → \(session.endedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                    }
                    Spacer()
                }
                .timberCard()

                nightChart
                breakdownCard
                if !session.factors.isEmpty { factorsCard }
                episodesCard
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note").font(.headline)
                        Text(session.notes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .timberCard()
                }
            }
            .padding()
        }
        .background(Theme.background(scheme))
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nightChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Night timeline")
                .font(.headline)
                .foregroundStyle(Theme.inkPrimary(scheme))
            if session.levelSamples.isEmpty {
                Text("No level data was captured for this night.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            } else {
                Chart {
                    ForEach(Array(session.levelSamples.enumerated()), id: \.offset) { minute, level in
                        AreaMark(x: .value("Minute", Double(minute)),
                                 y: .value("Level", level))
                        .foregroundStyle(Theme.amber.opacity(0.35))
                        .interpolationMethod(.monotone)
                    }
                    ForEach(session.episodes.sorted { $0.startOffset < $1.startOffset }) { ep in
                        RectangleMark(
                            xStart: .value("Start", ep.startOffset / 60),
                            xEnd: .value("End", (ep.startOffset + ep.duration) / 60),
                            yStart: .value("Bottom", 0.0),
                            yEnd: .value("Top", 1.0))
                        .foregroundStyle(Theme.intensityColor(ep.intensity).opacity(0.30))
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxisLabel("Minutes since lights out")
                .frame(height: 160)
                .accessibilityLabel("Loudness over the night with snore episodes highlighted")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private var breakdownCard: some View {
        let breakdown = SnoreEngine.intensityBreakdown(for: session)
        return HStack(spacing: 12) {
            ForEach(SnoreIntensity.allCases, id: \.self) { intensity in
                VStack(spacing: 4) {
                    Circle()
                        .fill(Theme.intensityColor(intensity))
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(intensity.label)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary(scheme))
                    Text(SnoreEngine.formatDuration(breakdown[intensity] ?? 0))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkPrimary(scheme))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .timberCard()
    }

    private var factorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tagged factors").font(.headline)
            Text(session.factors.map { "\($0.emoji) \($0.name)" }.joined(separator: "   "))
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private var episodesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Episodes (\(session.episodes.count))")
                .font(.headline)
            if session.episodes.isEmpty {
                Text("A completely quiet night — nothing detected.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            } else {
                ForEach(session.episodes.sorted { $0.startOffset < $1.startOffset }) { ep in
                    HStack {
                        Circle()
                            .fill(Theme.intensityColor(ep.intensity))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(timeOfEpisode(ep))
                            .font(.subheadline)
                            .monospacedDigit()
                        Spacer()
                        Text(ep.intensity.label)
                            .font(.caption)
                            .foregroundStyle(Theme.intensityColor(ep.intensity))
                        Text(SnoreEngine.formatDuration(ep.duration))
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                            .frame(width: 56, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private func timeOfEpisode(_ ep: SnoreEpisode) -> String {
        session.startedAt.addingTimeInterval(ep.startOffset)
            .formatted(date: .omitted, time: .shortened)
    }
}
