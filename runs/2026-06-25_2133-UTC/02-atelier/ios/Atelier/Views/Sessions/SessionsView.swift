import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \ArtSession.date, order: .reverse) private var sessions: [ArtSession]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var seeded = false
    @State private var mediumFilter: ArtMedium?

    private var filtered: [ArtSession] {
        guard let m = mediumFilter else { return sessions }
        return sessions.filter { $0.medium == m }
    }

    private var grouped: [(String, [ArtSession])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var groups: [String: [ArtSession]] = [:]
        var order: [String] = []
        for s in filtered {
            let key = fmt.string(from: s.date)
            if groups[key] == nil { order.append(key); groups[key] = [] }
            groups[key]?.append(s)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    private var thisWeekMinutes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.durationMinutes }
    }

    private var streakDays: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: .now)
        let daysDates = Set(sessions.map { cal.startOfDay(for: $0.date) })
        while daysDates.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        summaryBar
                        filterBar
                        sessionList
                    }
                }
            }
            .navigationTitle("Atelier")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if true { HapticManager.impact(.medium) }
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AtelierTheme.amber)
                    }
                    .accessibilityLabel("Log practice session")
                }
            }
            .sheet(isPresented: $showingAdd) {
                SessionFormView(session: nil)
            }
            .onAppear {
                if sessions.isEmpty && !seeded {
                    AtelierSeeder.seed(context: context)
                    seeded = true
                }
            }
            .navigationDestination(for: ArtSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 12) {
            SessionStatChip(value: "\(sessions.count)", label: "Sessions", icon: "paintbrush.fill")
            SessionStatChip(value: "\(totalHours)h", label: "Total Time", icon: "clock.fill")
            SessionStatChip(value: "\(streakDays)d", label: "Streak", icon: "flame.fill")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { mediumFilter = nil }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(mediumFilter == nil ? AtelierTheme.amber : Color(.secondarySystemBackground))
                    .foregroundStyle(mediumFilter == nil ? AtelierTheme.ink : .primary)
                    .clipShape(Capsule())

                ForEach(ArtMedium.allCases) { medium in
                    Button(medium.rawValue) { mediumFilter = medium }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(mediumFilter == medium ? medium.color : Color(.secondarySystemBackground))
                        .foregroundStyle(mediumFilter == medium ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var sessionList: some View {
        List {
            ForEach(grouped, id: \.0) { monthKey, monthSessions in
                Section {
                    ForEach(monthSessions) { session in
                        NavigationLink(value: session) {
                            SessionRowView(session: session)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { idx in
                        for i in idx { context.delete(monthSessions[i]) }
                        try? context.save()
                    }
                } header: {
                    HStack {
                        Text(monthKey).font(.subheadline.bold())
                        Spacer()
                        let mins = monthSessions.reduce(0) { $0 + $1.durationMinutes }
                        Text("\(mins / 60)h \(mins % 60)m").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "paintpalette")
                .font(.system(size: 64))
                .foregroundStyle(AtelierTheme.amber.opacity(0.6))
                .accessibilityHidden(true)
            Text("No sessions yet")
                .font(.title2.bold())
            Text("Tap + to log your first practice session and start building your artistic habit.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No sessions yet. Tap the plus button to log your first practice session.")
    }

    private var totalHours: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes } / 60
    }
}

struct SessionStatChip: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(AtelierTheme.amber).accessibilityHidden(true)
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct SessionRowView: View {
    let session: ArtSession

    private static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(session.medium.color.opacity(0.18))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: session.medium.sfSymbol)
                        .foregroundStyle(session.medium.color)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.subject.isEmpty ? session.practiceType.rawValue : session.subject)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(Self.df.string(from: session.date)).font(.caption).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.secondary)
                    Text(session.durationFormatted).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.mood.emoji).font(.subheadline)
                AtelierRatingView(rating: session.rating, size: 10)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.subject.isEmpty ? session.practiceType.rawValue : session.subject), \(Self.df.string(from: session.date)), \(session.medium.rawValue), rating \(session.rating)")
    }
}
