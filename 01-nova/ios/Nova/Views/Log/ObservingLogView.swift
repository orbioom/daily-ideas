import SwiftUI
import SwiftData

struct ObservingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ObservingSession.date, order: .reverse) private var sessions: [ObservingSession]
    @State private var showAdd = false
    @State private var selectedSession: ObservingSession?

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                Group {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }
                }
            }
            .navigationTitle("Observing Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(NovaTheme.accent)
                    }
                    .accessibilityLabel("Add observing session")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSessionView()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundStyle(NovaTheme.textSecondary)
            Text("No Sessions Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(NovaTheme.textPrimary)
            Text("Log your stargazing sessions to track what you've observed under the night sky.")
                .font(.system(size: 15))
                .foregroundStyle(NovaTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Log First Session") {
                showAdd = true
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(NovaTheme.skyBackground)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(NovaTheme.accent)
            .cornerRadius(24)
        }
        .padding()
    }

    var sessionList: some View {
        List {
            ForEach(sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    SessionRow(session: session)
                }
                .listRowBackground(NovaTheme.cardBackground)
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func deleteSessions(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(sessions[i]) }
    }
}

struct SessionRow: View {
    let session: ObservingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.locationName.isEmpty ? "No location" : session.locationName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NovaTheme.textPrimary)
                Spacer()
                Text(dateLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(NovaTheme.textSecondary)
            }
            HStack(spacing: 10) {
                skyQualityBar
                Text("Sky quality \(session.skyQuality)/5")
                    .font(.system(size: 13))
                    .foregroundStyle(NovaTheme.textSecondary)
                if !session.objectsNoted.isEmpty {
                    Text("·")
                        .foregroundStyle(NovaTheme.textSecondary)
                    Text("\(session.objectsNoted.count) objects")
                        .font(.system(size: 13))
                        .foregroundStyle(NovaTheme.accent)
                }
            }
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.system(size: 13))
                    .foregroundStyle(NovaTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: session.date)
    }

    var skyQualityBar: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= session.skyQuality ? NovaTheme.accentGold : NovaTheme.textSecondary.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
    }
}

struct AddSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var locationName = ""
    @State private var notes = ""
    @State private var skyQuality = 3
    @State private var objectsText = ""
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Location name (e.g. Backyard)", text: $locationName)
                            .foregroundStyle(NovaTheme.textPrimary)
                        DatePicker("Date & Time", selection: $date)
                            .foregroundStyle(NovaTheme.textPrimary)
                    } header: { Text("Session Details") }
                    .listRowBackground(NovaTheme.cardBackground)

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sky Quality: \(skyQuality)/5")
                                .font(.system(size: 14))
                                .foregroundStyle(NovaTheme.textSecondary)
                            Slider(value: Binding(get: { Double(skyQuality) }, set: { skyQuality = Int($0) }), in: 1...5, step: 1)
                                .tint(NovaTheme.accentGold)
                            Text(skyQualityDesc)
                                .font(.system(size: 12))
                                .foregroundStyle(NovaTheme.textSecondary)
                        }
                    } header: { Text("Sky Quality") }
                    .listRowBackground(NovaTheme.cardBackground)

                    Section {
                        TextField("Objects noted (comma-separated)", text: $objectsText)
                            .foregroundStyle(NovaTheme.textPrimary)
                    } header: { Text("Objects Observed") }
                    .listRowBackground(NovaTheme.cardBackground)

                    Section {
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .foregroundStyle(NovaTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                    } header: { Text("Notes") }
                    .listRowBackground(NovaTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(NovaTheme.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NovaTheme.accent)
                }
            }
        }
    }

    var skyQualityDesc: String {
        switch skyQuality {
        case 1: return "Bright suburb — only brightest stars"
        case 2: return "Suburban — few hundred stars"
        case 3: return "Rural suburb — 1000+ stars"
        case 4: return "Rural — Milky Way visible"
        case 5: return "Dark sky — excellent, zodiacal light"
        default: return ""
        }
    }

    func save() {
        let objects = objectsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let session = ObservingSession(date: date, locationName: locationName, notes: notes, skyQuality: skyQuality, objectsNoted: objects)
        modelContext.insert(session)
        dismiss()
    }
}

struct SessionDetailView: View {
    @Bindable var session: ObservingSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.locationName.isEmpty ? "Unnamed Session" : session.locationName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(NovaTheme.textPrimary)
                            Text(dateLabel)
                                .font(.system(size: 15))
                                .foregroundStyle(NovaTheme.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NovaTheme.cardBackground)
                        .cornerRadius(12)

                        // Sky quality
                        HStack {
                            Text("Sky Quality")
                                .foregroundStyle(NovaTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= session.skyQuality ? "star.fill" : "star")
                                        .foregroundStyle(i <= session.skyQuality ? NovaTheme.accentGold : NovaTheme.textSecondary.opacity(0.3))
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding()
                        .background(NovaTheme.cardBackground)
                        .cornerRadius(12)

                        if !session.objectsNoted.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Objects Observed")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovaTheme.textSecondary)
                                FlowLayout(items: session.objectsNoted) { obj in
                                    Text(obj)
                                        .font(.system(size: 14))
                                        .foregroundStyle(NovaTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(NovaTheme.accent.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                            .padding()
                            .background(NovaTheme.cardBackground)
                            .cornerRadius(12)
                        }

                        if !session.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NovaTheme.textSecondary)
                                Text(session.notes)
                                    .font(.system(size: 15))
                                    .foregroundStyle(NovaTheme.textPrimary)
                            }
                            .padding()
                            .background(NovaTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(NovaTheme.accent)
                }
            }
        }
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f.string(from: session.date)
    }
}

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Simple row-by-row layout
            let rows = makeRows(items: items, rowSize: 3)
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: 8) {
                    ForEach(rows[rowIdx], id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func makeRows(items: [Item], rowSize: Int) -> [[Item]] {
        var rows: [[Item]] = []
        var current: [Item] = []
        for item in items {
            current.append(item)
            if current.count == rowSize { rows.append(current); current = [] }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}
