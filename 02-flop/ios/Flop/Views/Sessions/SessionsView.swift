import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlopSession.date, order: .reverse) private var sessions: [FlopSession]
    @Query private var records: [FlopQuizRecord]
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            if sessions.isEmpty {
                emptyState
            } else {
                List {
                    statsSection
                    sessionsSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Session Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(FlopTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSessionView()
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 52))
                .foregroundStyle(FlopTheme.textSecondary)
            Text("No Sessions Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("Log your practice or live sessions to track progress over time.")
                .font(.system(size: 15))
                .foregroundStyle(FlopTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showAddSheet = true
            } label: {
                Text("Log Session")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(FlopTheme.accent, in: Capsule())
            }
        }
    }

    var statsSection: some View {
        Section {
            let totalHands = sessions.reduce(0) { $0 + $1.handCount }
            let totalMinutes = sessions.reduce(0) { $0 + $1.duration } / 60
            let quizCorrect = records.filter { $0.wasCorrect }.count
            let quizTotal = records.count
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(value: "\(sessions.count)", label: "Sessions")
                statCard(value: "\(totalHands)", label: "Hands Logged")
                statCard(value: "\(totalMinutes)m", label: "Time Played")
                statCard(value: quizTotal > 0 ? "\(Int(Double(quizCorrect)/Double(quizTotal)*100))%" : "—", label: "Quiz Accuracy")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Overview")
                .foregroundStyle(FlopTheme.textSecondary)
        }
        .listRowBackground(FlopTheme.felt)
    }

    func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(FlopTheme.accentGold)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(FlopTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(FlopTheme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }

    var sessionsSection: some View {
        Section {
            ForEach(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRowView(session: session)
                }
                .listRowBackground(FlopTheme.felt)
            }
            .onDelete(perform: deleteSessions)
        } header: {
            Text("Recent Sessions")
                .foregroundStyle(FlopTheme.textSecondary)
        }
    }

    func deleteSessions(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(sessions[i]) }
    }
}

struct SessionRowView: View {
    let session: FlopSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.gameType)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FlopTheme.textPrimary)
                Spacer()
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 13))
                    .foregroundStyle(FlopTheme.textSecondary)
            }
            HStack(spacing: 16) {
                Label("\(session.handCount) hands", systemImage: "suit.club.fill")
                Label("\(session.duration / 60)m", systemImage: "clock")
            }
            .font(.system(size: 13))
            .foregroundStyle(FlopTheme.textSecondary)
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.system(size: 13))
                    .foregroundStyle(FlopTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    let session: FlopSession

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            List {
                Section {
                    detailRow("Game Type", session.gameType)
                    detailRow("Date", session.date.formatted(date: .long, time: .shortened))
                    detailRow("Duration", "\(session.duration / 60) minutes")
                    detailRow("Hands Played", "\(session.handCount)")
                } header: {
                    Text("Session Info").foregroundStyle(FlopTheme.textSecondary)
                }
                .listRowBackground(FlopTheme.felt)

                if !session.notes.isEmpty {
                    Section {
                        Text(session.notes)
                            .font(.system(size: 15))
                            .foregroundStyle(FlopTheme.textPrimary)
                    } header: {
                        Text("Notes").foregroundStyle(FlopTheme.textSecondary)
                    }
                    .listRowBackground(FlopTheme.felt)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(FlopTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(FlopTheme.textPrimary)
        }
    }
}

struct AddSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var gameType = "NL Hold'em"
    @State private var handCount = ""
    @State private var duration = ""
    @State private var notes = ""
    @State private var date = Date()

    let gameTypes = ["NL Hold'em", "PLO", "Limit Hold'em", "MTT", "SNG", "Home Game"]

    var body: some View {
        NavigationStack {
            ZStack {
                FlopTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Game Type", selection: $gameType) {
                            ForEach(gameTypes, id: \.self) { Text($0) }
                        }
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        TextField("Hands Played", text: $handCount)
                            .keyboardType(.numberPad)
                        TextField("Duration (minutes)", text: $duration)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("Session Info")
                    }
                    .listRowBackground(FlopTheme.felt)

                    Section {
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(4...8)
                    } header: {
                        Text("Notes")
                    }
                    .listRowBackground(FlopTheme.felt)
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(FlopTheme.textPrimary)
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FlopTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FlopTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(FlopTheme.accent)
                        .disabled(gameType.isEmpty)
                }
            }
        }
    }

    func save() {
        let session = FlopSession(
            date: date,
            duration: (Int(duration) ?? 0) * 60,
            gameType: gameType,
            notes: notes,
            handCount: Int(handCount) ?? 0
        )
        modelContext.insert(session)
        dismiss()
    }
}
