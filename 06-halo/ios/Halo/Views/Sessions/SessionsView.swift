import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \HaloSession.date, order: .reverse) private var sessions: [HaloSession]

    private var totalMinutes: Int {
        Int(sessions.reduce(0) { $0 + $1.durationSeconds } / 60)
    }

    private var favoriteCategory: String {
        let counts = Dictionary(grouping: sessions, by: \.category)
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    private var groupedSessions: [(String, [HaloSession])] {
        let grouped = Dictionary(grouping: sessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: session.date)
        }
        return grouped.sorted { a, b in
            let af = sessions.first { s in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.doesRelativeDateFormatting = true
                return formatter.string(from: s.date) == a.0
            }?.date ?? Date.distantPast
            let bf = sessions.first { s in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.doesRelativeDateFormatting = true
                return formatter.string(from: s.date) == b.0
            }?.date ?? Date.distantPast
            return af > bf
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: HaloTheme.spacingM) {
                            statsHeader
                            sessionsList
                        }
                        .padding(.horizontal, HaloTheme.spacingM)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Sessions")
            .toolbarBackground(HaloTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        EmptyStateView(
            icon: "clock.badge.questionmark",
            title: "No Sessions Yet",
            message: "Start your first session from the Home tab. Your history will appear here."
        )
    }

    private var statsHeader: some View {
        HStack(spacing: HaloTheme.spacingM) {
            statCard(value: "\(sessions.count)", label: "Total Sessions", icon: "checkmark.circle.fill")
            statCard(value: "\(totalMinutes)", label: "Total Minutes", icon: "clock.fill")
            statCard(value: favoriteCategory, label: "Top Category", icon: "star.fill")
        }
        .padding(.top, HaloTheme.spacingS)
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(HaloTheme.accent)
            Text(value)
                .font(HaloTheme.headlineFont)
                .foregroundColor(HaloTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(HaloTheme.textTertiary)
                .multilineTextAlignment(.center)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var sessionsList: some View {
        ForEach(groupedSessions, id: \.0) { dateLabel, daySessions in
            VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                Text(dateLabel)
                    .font(HaloTheme.labelFont)
                    .foregroundColor(HaloTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.top, HaloTheme.spacingS)

                ForEach(daySessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: HaloSession

    private var categoryColor: Color {
        session.brainwaveCategory?.color ?? HaloTheme.primary
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        HStack(spacing: HaloTheme.spacingM) {
            // Category dot
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)
                .shadow(color: categoryColor.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.presetName)
                    .font(HaloTheme.bodyFont)
                    .foregroundColor(HaloTheme.textPrimary)
                HStack(spacing: HaloTheme.spacingS) {
                    Text(session.category)
                        .font(HaloTheme.captionFont)
                        .foregroundColor(categoryColor)
                    Text("•")
                        .foregroundColor(HaloTheme.textTertiary)
                    Text(session.durationDisplay)
                        .font(HaloTheme.captionFont)
                        .foregroundColor(HaloTheme.textTertiary)
                    Text("•")
                        .foregroundColor(HaloTheme.textTertiary)
                    Text(timeString)
                        .font(HaloTheme.captionFont)
                        .foregroundColor(HaloTheme.textTertiary)
                }
            }

            Spacer()

            // Mood delta
            if session.moodBefore != session.moodAfter {
                Text(session.moodDeltaSymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(session.moodDelta > 0 ? .green : .red)
            } else {
                Text("→")
                    .font(.system(size: 16))
                    .foregroundColor(HaloTheme.textTertiary)
            }
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
