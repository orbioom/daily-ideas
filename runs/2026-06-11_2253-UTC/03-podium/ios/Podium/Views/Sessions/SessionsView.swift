import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \SpeechSession.date, order: .reverse) private var sessions: [SpeechSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle",
                                   title: "No takes yet",
                                   message: "Record a practice talk on the Practice tab and it'll be saved here with its full analysis.")
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(value: session) {
                                row(session)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(sessions[i]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Sessions")
            .navigationDestination(for: SpeechSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private func row(_ session: SpeechSession) -> some View {
        HStack(spacing: 14) {
            ScoreBadge(score: session.score)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.promptTitle)
                    .font(.subheadline.weight(.semibold))
                Text("\(SpeechAnalyzer.formatDuration(session.duration)) · \(Int(session.wordsPerMinute)) wpm · \(session.fillerCount) fillers")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

struct SessionDetailView: View {
    let session: SpeechSession
    @Environment(\.colorScheme) private var scheme
    @AppStorage("targetWPMLow") private var targetLow = 120.0
    @AppStorage("targetWPMHigh") private var targetHigh = 160.0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    ScoreBadge(score: session.score, size: 96)
                    Text(SpeechAnalyzer.grade(forScore: session.score).label)
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.ink(scheme))
                    Text(session.promptTitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
                .frame(maxWidth: .infinity)
                .podiumCard()

                HStack(spacing: 12) {
                    tile(value: SpeechAnalyzer.formatDuration(session.duration), label: "Length")
                    tile(value: "\(Int(session.wordsPerMinute))",
                         label: SpeechAnalyzer.paceLabel(wpm: session.wordsPerMinute,
                                                         low: targetLow, high: targetHigh))
                    tile(value: String(format: "%.1f/min", session.fillersPerMinute), label: "Fillers")
                    tile(value: String(format: "%.0f%%", session.vocabularyDiversity * 100), label: "Variety")
                }

                if !session.fillerBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filler breakdown").font(.headline)
                        ForEach(session.fillerBreakdown.sorted { $0.value > $1.value }, id: \.key) { word, count in
                            HStack {
                                Text("“\(word)”")
                                    .foregroundStyle(Theme.gold)
                                Spacer()
                                Text("×\(count)")
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.inkSoft(scheme))
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .podiumCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcript").font(.headline)
                    if session.transcript.isEmpty {
                        Text("No speech was transcribed in this take.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    } else {
                        Text(highlighted(session.transcript))
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .podiumCard()
            }
            .padding()
        }
        .background(Theme.background(scheme))
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink(scheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        for range in SpeechAnalyzer.fillerRanges(in: text) {
            if let lower = AttributedString.Index(range.lowerBound, within: attributed),
               let upper = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[lower..<upper].foregroundColor = Theme.gold
                attributed[lower..<upper].font = .subheadline.weight(.bold)
            }
        }
        return attributed
    }
}
