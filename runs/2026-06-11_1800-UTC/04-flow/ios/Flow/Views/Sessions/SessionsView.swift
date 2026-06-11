import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \CompletedSession.date, order: .reverse) private var completed: [CompletedSession]
    @State private var selectedFocus: SessionFocus? = nil
    @State private var selectedDifficulty: SessionDifficulty? = nil

    private var filtered: [YogaSession] {
        YogaSession.catalog.filter { session in
            (selectedFocus == nil || session.focus == selectedFocus) &&
            (selectedDifficulty == nil || session.difficulty == selectedDifficulty)
        }
    }

    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return completed
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    private var weekStreak: Int {
        var streak = 0
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while true {
            if completed.contains(where: { cal.startOfDay(for: $0.date) == day }) {
                streak += 1
                day = cal.date(byAdding: .day, value: -1, to: day) ?? day
            } else { break }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if todayMinutes > 0 || weekStreak > 0 {
                        statsStrip
                    }
                    filterBar
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "wind")
                                .font(.system(size: 48))
                                .foregroundStyle(FlowTheme.subtle.opacity(0.4))
                                .accessibilityHidden(true)
                            Text("No sessions match")
                                .foregroundStyle(FlowTheme.subtle)
                        }
                        .frame(minHeight: 200)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filtered) { session in
                                NavigationLink(value: session) {
                                    SessionCardView(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .background(FlowTheme.bg)
            .navigationTitle("Flow")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: YogaSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    @ViewBuilder
    private var statsStrip: some View {
        HStack(spacing: 16) {
            if todayMinutes > 0 {
                StatPill(value: "\(todayMinutes)", label: "min today", icon: "clock.fill", color: FlowTheme.sage)
            }
            if weekStreak > 0 {
                StatPill(value: "\(weekStreak)", label: "day streak", icon: "flame.fill", color: .orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isSelected: selectedFocus == nil && selectedDifficulty == nil) {
                    selectedFocus = nil; selectedDifficulty = nil
                }
                Divider().frame(height: 24)
                ForEach(SessionFocus.allCases, id: \.self) { f in
                    FilterPill(label: f.rawValue, isSelected: selectedFocus == f) {
                        selectedFocus = selectedFocus == f ? nil : f
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct StatPill: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.caption).accessibilityHidden(true)
            Text("\(value) \(label)").font(.caption.weight(.medium)).foregroundStyle(FlowTheme.text)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.15), in: Capsule())
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct FilterPill: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? FlowTheme.sage : FlowTheme.card)
                .foregroundStyle(isSelected ? .white : FlowTheme.text)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct SessionCardView: View {
    let session: YogaSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                FlowTheme.gradient(for: session)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.emoji)
                        .font(.system(size: 36))
                        .accessibilityHidden(true)
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FlowTheme.text)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("\(session.totalDurationMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(FlowTheme.subtle)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(FlowTheme.subtle)
                    Text(session.difficulty.rawValue)
                        .font(.caption2)
                        .foregroundStyle(FlowTheme.sage)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.name), \(session.totalDurationMinutes) minutes, \(session.difficulty.rawValue)")
    }
}

extension YogaSession: Hashable {
    static func == (lhs: YogaSession, rhs: YogaSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
