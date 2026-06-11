import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \NightSession.startedAt, order: .reverse) private var sessions: [NightSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(icon: "book.closed",
                                   title: "No nights yet",
                                   message: "Run your first sleep session from the Tonight tab. Every monitored night lands here with its score and timeline.")
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(value: session.persistentModelID) {
                                row(session)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Journal")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let session = context.model(for: id) as? NightSession {
                    NightDetailView(session: session)
                } else {
                    EmptyStateView(icon: "questionmark.circle", title: "Night unavailable",
                                   message: "This night was deleted.")
                }
            }
        }
    }

    private func row(_ session: NightSession) -> some View {
        let score = SnoreEngine.score(for: session)
        return HStack(spacing: 14) {
            Text("\(score)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .frame(width: 52, height: 52)
                .background(Theme.scoreColor(score).opacity(0.18), in: Circle())
                .foregroundStyle(Theme.scoreColor(score))
            VStack(alignment: .leading, spacing: 3) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Text("\(SnoreEngine.formatDuration(session.duration)) · \(session.episodes.count) episodes · \(SnoreEngine.grade(forScore: score).label)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
                if !session.factors.isEmpty {
                    Text(session.factors.map { "\($0.emoji)" }.joined(separator: " "))
                        .font(.caption)
                }
            }
            Spacer()
            if session.morningRating > 0 {
                Label("\(session.morningRating)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.amber)
                    .labelStyle(.titleAndIcon)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.startedAt.formatted(date: .complete, time: .omitted)), score \(score), \(session.episodes.count) episodes")
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}
