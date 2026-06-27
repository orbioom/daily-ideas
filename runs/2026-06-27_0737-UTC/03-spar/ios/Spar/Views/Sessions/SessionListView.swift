import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Environment(\.modelContext) private var context
    @State private var showLog = false
    @State private var selected: TrainingSession? = nil
    @State private var filterType: SessionType? = nil

    private var filtered: [TrainingSession] {
        guard let t = filterType else { return sessions }
        return sessions.filter { $0.sessionType == t }
    }

    private var grouped: [(String, [TrainingSession])] {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: filtered) { fmt.string(from: $0.date) }
        return dict.sorted { a, b in
            let ad = filtered.first { fmt.string(from: $0.date) == a.key }?.date ?? .distantPast
            let bd = filtered.first { fmt.string(from: $0.date) == b.key }?.date ?? .distantPast
            return ad > bd
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        filterBar.listRowBackground(Color.clear).listRowInsets(.init())
                        ForEach(grouped, id: \.0) { month, items in
                            Section(header: Text(month)) {
                                ForEach(items) { s in
                                    SessionRowView(session: s)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selected = s }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                context.delete(s)
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showLog = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showLog) { LogSessionView() }
            .sheet(item: $selected) { s in
                SessionDetailView(session: s)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", selected: filterType == nil) { filterType = nil }
                ForEach(SessionType.allCases, id: \.self) { t in
                    chipButton(t.rawValue, selected: filterType == t) {
                        filterType = filterType == t ? nil : t
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
        }
    }

    private func chipButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No sessions yet")
                .font(.title3.bold())
            Text("Tap + to log your first training session")
                .foregroundStyle(.secondary)
            Button("Log Session") { showLog = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SessionRowView: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.sessionType.icon)
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionType.rawValue)
                    .font(.subheadline.bold())
                if !session.focusAreas.isEmpty {
                    Text(session.focusAreas)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationDisplay)
                    .font(.subheadline.bold())
                if session.rounds > 0 {
                    Text(session.roundsDisplay)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(session.intensity.label)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

struct SessionDetailView: View {
    @Bindable var session: TrainingSession
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Session") {
                    row("Type", session.sessionType.rawValue)
                    row("Duration", session.durationDisplay)
                    if session.rounds > 0 {
                        row("Rounds", session.roundsDisplay)
                    }
                    row("Intensity", session.intensity.label)
                    if session.mood > 0 {
                        row("Mood", String(repeating: "★", count: session.mood) + String(repeating: "☆", count: 5 - session.mood))
                    }
                }
                if !session.focusAreas.isEmpty {
                    Section("Focus") {
                        Text(session.focusAreas)
                    }
                }
                if !session.partnerName.isEmpty {
                    Section("Training Partner") {
                        Text(session.partnerName)
                    }
                }
                if !session.notes.isEmpty {
                    Section("Notes") {
                        Text(session.notes)
                    }
                }
            }
            .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Edit") { showEdit = true } }
            }
            .sheet(isPresented: $showEdit) { LogSessionView(editing: session) }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
