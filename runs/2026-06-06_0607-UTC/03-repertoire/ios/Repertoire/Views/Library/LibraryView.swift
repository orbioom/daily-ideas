import SwiftUI
import SwiftData

/// The repertoire library: every piece grouped by status, each showing its time this
/// week and mastery roll-up. The home of the app.
struct LibraryView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Piece.createdAt, order: .reverse) private var pieces: [Piece]
    @Query private var sessions: [PracticeSession]

    @State private var showingEditor = false
    @State private var searchText = ""

    /// Status display order in the grouped list.
    private let order: [PieceStatus] = [.learning, .polishing, .maintenance, .retired]

    private var filtered: [Piece] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return pieces }
        return pieces.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.composer.localizedCaseInsensitiveContains(trimmed)
                || $0.instrument.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func group(_ status: PieceStatus) -> [Piece] {
        filtered.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if pieces.isEmpty {
                    EmptyStateView(
                        icon: "music.note.list",
                        title: "Your repertoire is empty",
                        message: "Add your first piece — its title, composer, and the passages you'll work on.",
                        actionTitle: "Add a piece",
                        action: { showingEditor = true }
                    )
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "No piece matches “\(searchText)”. Try another title, composer, or instrument."
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Repertoire")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a piece")
                }
            }
            .searchable(text: $searchText, prompt: "Search pieces")
            .sheet(isPresented: $showingEditor) {
                PieceEditView(piece: nil)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                ForEach(order, id: \.self) { status in
                    let items = group(status)
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel(text: status.title)
                                Spacer()
                                Text("\(items.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.text3)
                            }
                            ForEach(items) { piece in
                                NavigationLink {
                                    PieceDetailView(piece: piece)
                                } label: {
                                    PieceRow(piece: piece, sessions: sessions)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

/// A single piece row: title, composer, instrument, status, minutes this week, mastery.
private struct PieceRow: View {
    var piece: Piece
    var sessions: [PracticeSession]

    private var minutesThisWeek: Int {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return piece.entries
            .filter { entry in
                guard let date = entry.session?.date else { return false }
                return interval.contains(date)
            }
            .reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(piece.title)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(2)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    StatusBadge(status: piece.status)
                }

                HStack(spacing: 14) {
                    Label {
                        Text("\(minutesThisWeek) min this week")
                            .font(.caption)
                            .foregroundStyle(Brand.text2)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    if let avg = piece.averageMastery {
                        MasteryDots(level: Int(avg.rounded()))
                    } else {
                        Text("No spots yet")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens piece detail")
    }

    private var subtitle: String {
        let composer = piece.composer.trimmingCharacters(in: .whitespaces)
        if composer.isEmpty { return piece.instrument }
        return "\(composer) · \(piece.instrument)"
    }
}

#Preview {
    LibraryView()
        .environment(SettingsStore())
        .previewContainer()
}
