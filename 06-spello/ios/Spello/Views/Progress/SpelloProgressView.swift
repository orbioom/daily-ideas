import SwiftUI
import SwiftData
import Charts

struct SpelloProgressView: View {
    @Query(sort: \SpelloSession.date, order: .reverse) private var sessions: [SpelloSession]
    @Query private var profiles: [SpelloProfile]
    @Query private var prefs: [SpelloPrefs]

    private var activeProfile: SpelloProfile? {
        guard let id = prefs.first?.activeProfileId else { return profiles.first }
        return profiles.first(where: { $0.id == id }) ?? profiles.first
    }

    private var mysessions: [SpelloSession] {
        guard let p = activeProfile else { return [] }
        return sessions.filter { $0.profileId == p.id }
    }

    private var totalWords: Int { mysessions.map(\.totalWords).reduce(0, +) }
    private var totalCorrect: Int { mysessions.map(\.correctWords).reduce(0, +) }
    private var accuracy: Double { totalWords == 0 ? 0 : Double(totalCorrect) / Double(totalWords) }

    var body: some View {
        NavigationStack {
            if mysessions.isEmpty {
                ContentUnavailableView("No Practice Yet",
                    systemImage: "chart.bar",
                    description: Text("Complete a practice session to see progress."))
                    .navigationTitle("Progress")
            } else {
                List {
                    if let p = activeProfile {
                        Section("\(p.name)'s Progress") {
                            statRow("Sessions", "\(mysessions.count)")
                            statRow("Words Practiced", "\(totalWords)")
                            statRow("Words Correct", "\(totalCorrect)")
                            statRow("Overall Accuracy", String(format: "%.0f%%", accuracy * 100))
                        }
                    }
                    if mysessions.count >= 3 {
                        Section("Accuracy Trend") {
                            Chart(mysessions.prefix(10).reversed()) { s in
                                LineMark(
                                    x: .value("Date", s.date, unit: .day),
                                    y: .value("Accuracy", s.totalWords == 0 ? 0 : Double(s.correctWords) / Double(s.totalWords) * 100)
                                )
                                .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.15))
                                .symbol(.circle)
                            }
                            .frame(height: 100)
                            .chartYScale(domain: 0...100)
                            .chartXAxis(.hidden)
                        }
                    }
                    Section("Recent Sessions") {
                        ForEach(mysessions.prefix(20)) { s in
                            HStack {
                                Image(systemName: sessionIcon(s))
                                    .foregroundStyle(sessionColor(s))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.mode).font(.subheadline.weight(.semibold))
                                    Text("Grade \(s.gradeLevel) · \(s.correctWords)/\(s.totalWords) correct")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(s.date, style: .date)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Progress")
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }

    private func sessionIcon(_ s: SpelloSession) -> String {
        let acc = s.totalWords == 0 ? 0 : Double(s.correctWords) / Double(s.totalWords)
        return acc >= 0.8 ? "star.fill" : acc >= 0.5 ? "checkmark.circle.fill" : "circle"
    }

    private func sessionColor(_ s: SpelloSession) -> Color {
        let acc = s.totalWords == 0 ? 0 : Double(s.correctWords) / Double(s.totalWords)
        return acc >= 0.8 ? .yellow : acc >= 0.5 ? .green : .secondary
    }
}
