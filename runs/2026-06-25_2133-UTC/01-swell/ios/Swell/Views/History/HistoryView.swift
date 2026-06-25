import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SurfSession.date, order: .reverse) private var sessions: [SurfSession]
    @State private var filterSpot: String = "All"
    @State private var showingAdd = false

    private var allSpots: [String] {
        var seen = Set<String>()
        var result: [String] = ["All"]
        for s in sessions where !s.spotName.isEmpty {
            if seen.insert(s.spotName).inserted { result.append(s.spotName) }
        }
        return result
    }

    private var filtered: [SurfSession] {
        guard filterSpot != "All" else { return sessions }
        return sessions.filter { $0.spotName == filterSpot }
    }

    private var grouped: [(String, [SurfSession])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var groups: [String: [SurfSession]] = [:]
        var order: [String] = []
        for s in filtered {
            let key = fmt.string(from: s.date)
            if groups[key] == nil {
                order.append(key)
                groups[key] = []
            }
            groups[key]?.append(s)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        sessionList
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundStyle(SwellTheme.teal)
                    .accessibilityLabel("Log new session")
                }
            }
            .sheet(isPresented: $showingAdd) {
                LogSessionView(session: nil)
            }
            .navigationDestination(for: SurfSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allSpots, id: \.self) { spot in
                    Button(spot) {
                        filterSpot = spot
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(filterSpot == spot ? SwellTheme.teal : Color(.secondarySystemBackground))
                    .foregroundStyle(filterSpot == spot ? SwellTheme.navy : .primary)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var sessionList: some View {
        List {
            ForEach(grouped, id: \.0) { monthKey, monthSessions in
                Section(header:
                    HStack {
                        Text(monthKey)
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(monthSessions.count) session\(monthSessions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                ) {
                    ForEach(monthSessions) { session in
                        NavigationLink(value: session) {
                            SessionRowView(session: session)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indices in
                        delete(at: indices, in: monthSessions)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(SwellTheme.teal.opacity(0.5))
                .accessibilityHidden(true)
            Text("No sessions logged yet")
                .font(.title3.bold())
            Text("Your full session history will appear here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No sessions logged yet.")
    }

    private func delete(at indices: IndexSet, in arr: [SurfSession]) {
        for i in indices {
            context.delete(arr[i])
        }
        try? context.save()
    }

    @Environment(\.modelContext) private var context
}
