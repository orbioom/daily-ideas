import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showAddSession = false
    @State private var showDelete = false

    private var sortedSessions: [PlaySession] {
        game.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statusCard
                if game.estimatedHours > 0 || game.hoursPlayed > 0 { progressCard }
                detailsCard
                if !game.notes.isEmpty { notesCard }
                sessionsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { GameEditView(game: game) }
        .sheet(isPresented: $showAddSession) { AddSessionView(game: game) }
        .confirmationDialog("Delete \(game.title)?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(game); try? context.save(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            CoverSwatch(game: game, size: 84)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title).font(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Text("\(game.platform.rawValue) · \(game.genre.rawValue)")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                StarRating(ratingHalf: $game.ratingHalf, size: 20)
                    .onChange(of: game.ratingHalf) { _, _ in try? context.save() }
            }
            Spacer()
        }
        .cpCard()
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GameStatus.allCases) { s in
                    Button {
                        Haptics.tap(); game.status = s
                        if s == .playing && game.dateStarted == nil { game.dateStarted = Date() }
                        if s.isFinished && game.dateFinished == nil { game.dateFinished = Date() }
                        try? context.save()
                    } label: {
                        Label(s.label, systemImage: s.symbol)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(game.status == s ? s.tint : Theme.track,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(game.status == s ? .white : Theme.textPrimary)
                    }
                    .accessibilityAddTraits(game.status == s ? [.isSelected] : [])
                }
            }
        }
        .cpCard()
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progress").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Fmt.hours(game.hoursPlayed)) played")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
            }
            ProgressView(value: game.completion).tint(Theme.accent)
            HStack {
                Text(game.estimatedHours > 0 ? "Est. \(Fmt.hours(game.estimatedHours)) to beat" : "No length estimate")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                if game.hoursRemaining > 0 {
                    Text("\(Fmt.hours(game.hoursRemaining)) left").font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .cpCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            DetailRow(label: "Priority", value: game.priority.label)
            Divider().overlay(Theme.track)
            DetailRow(label: "Price paid", value: game.pricePaid > 0 ? Currency.string(game.pricePaid) : "—")
            if game.pricePaid > 0 && game.hoursPlayed > 0 {
                Divider().overlay(Theme.track)
                DetailRow(label: "Cost per hour", value: Currency.string(game.pricePaid / game.hoursPlayed))
            }
            Divider().overlay(Theme.track)
            DetailRow(label: "Added", value: Fmt.date(game.dateAdded))
            if let f = game.dateFinished {
                Divider().overlay(Theme.track)
                DetailRow(label: "Finished", value: Fmt.date(f))
            }
        }
        .cpCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text(game.notes).font(.body).foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cpCard()
    }

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Play sessions").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Button { Haptics.tap(); showAddSession = true } label: {
                    Label("Log", systemImage: "plus.circle.fill").font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Theme.accent)
            }
            if sortedSessions.isEmpty {
                Text("No sessions logged. Tap Log after a play session to track your hours.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(sortedSessions) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fmt.date(s.date)).font(.subheadline).foregroundStyle(Theme.textPrimary)
                            if !s.note.isEmpty { Text(s.note).font(.caption).foregroundStyle(Theme.textSecondary) }
                        }
                        Spacer()
                        Text(Fmt.hours(s.hours)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) { deleteSession(s) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .cpCard()
    }

    private func deleteSession(_ s: PlaySession) {
        game.hoursPlayed = max(0, game.hoursPlayed - s.hours)
        context.delete(s)
        try? context.save()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
