import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \SurfSession.date, order: .reverse) private var sessions: [SurfSession]
    @Query private var allSettings: [SurfSettings]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var showingSeeded = false

    private var settings: SurfSettings? { allSettings.first }
    private var recentSessions: [SurfSession] { Array(sessions.prefix(7)) }

    private var totalHours: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes } / 60
    }

    private var weekSessions: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= weekAgo }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        statsChips
                        recentSection
                    }
                }
                .padding()
            }
            .navigationTitle("Swell")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if settings?.hapticsEnabled == true {
                            HapticManager.impact(.medium)
                        }
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SwellTheme.teal)
                    }
                    .accessibilityLabel("Log new session")
                }
            }
            .sheet(isPresented: $showingAdd) {
                LogSessionView(session: nil)
            }
            .onAppear {
                bootstrapIfNeeded()
            }
        }
    }

    private var statsChips: some View {
        HStack(spacing: 12) {
            StatChip(value: "\(sessions.count)", label: "Sessions", icon: "water.waves")
            StatChip(value: "\(totalHours)h", label: "In the Water", icon: "clock.fill")
            StatChip(value: "\(weekSessions)", label: "This Week", icon: "calendar")
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            ForEach(recentSessions) { session in
                NavigationLink(value: session) {
                    SessionRowView(session: session)
                }
                .buttonStyle(.plain)
            }

            if sessions.count > 7 {
                NavigationLink(destination: HistoryView()) {
                    Text("See all \(sessions.count) sessions")
                        .font(.subheadline)
                        .foregroundStyle(SwellTheme.teal)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationDestination(for: SurfSession.self) { session in
            SessionDetailView(session: session)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "water.waves")
                .font(.system(size: 64))
                .foregroundStyle(SwellTheme.teal.opacity(0.6))
                .accessibilityHidden(true)
            Text("No sessions yet")
                .font(.title2.bold())
            Text("Tap + to log your first session and start tracking your surf journey.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No sessions yet. Tap the plus button to log your first session.")
    }

    private func bootstrapIfNeeded() {
        guard !showingSeeded else { return }
        if sessions.isEmpty {
            DataSeeder.seed(context: context)
            showingSeeded = true
        }
    }
}

struct StatChip: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(SwellTheme.teal)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
    let session: SurfSession

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(session.conditions.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: session.conditions.sfSymbol)
                        .foregroundStyle(session.conditions.color)
                        .font(.title3)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.spotName.isEmpty ? "Unknown Spot" : session.spotName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text(Self.dateFormatter.string(from: session.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                WaveHeightView(feet: session.waveHeightFt)
                RatingView(rating: session.rating, size: 10)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.spotName), \(Self.dateFormatter.string(from: session.date)), \(session.conditions.rawValue), rating \(session.rating) out of 5")
    }
}
