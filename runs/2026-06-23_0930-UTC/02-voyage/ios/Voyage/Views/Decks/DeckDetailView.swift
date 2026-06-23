import SwiftUI
import SwiftData

/// Detail for one deck: progress header, category filter, phrase list with
/// favorite/speak/delete, a study CTA, and add-phrase entry.
struct DeckDetailView: View {
    @Bindable var deck: Deck
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]

    @State private var selectedCategory: PhraseCategory? = nil
    @State private var showingStudy = false
    @State private var showingAddPhrase = false
    @State private var showingDeleteDeckConfirm = false

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    private var sortedPhrases: [Phrase] {
        deck.phrases.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var filteredPhrases: [Phrase] {
        guard let cat = selectedCategory else { return sortedPhrases }
        return sortedPhrases.filter { $0.category == cat }
    }

    private var progress: DeckProgress {
        DeckProgress.make(phrases: deck.phrases)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    categoryFilter
                    phraseList
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddPhrase = true
                    } label: { Label("Add Phrase", systemImage: "plus") }
                    Button(role: .destructive) {
                        showingDeleteDeckConfirm = true
                    } label: { Label("Delete Deck", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Deck options")
            }
        }
        .sheet(isPresented: $showingStudy) {
            ReviewSessionView(deck: deck)
        }
        .sheet(isPresented: $showingAddPhrase) {
            AddPhraseView(deck: deck)
        }
        .confirmationDialog(
            "Delete \(deck.name)?",
            isPresented: $showingDeleteDeckConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Deck", role: .destructive, action: deleteDeck)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the deck and all its phrases and progress. This can't be undone.")
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.lg) {
                Text(deck.flag).font(.system(size: 48)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.endonym).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                    Text(deck.subtitle).font(.subheadline).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            HStack(spacing: Theme.Spacing.md) {
                StatPill(value: "\(progress.newCount)", label: "New", tint: Theme.textSecondary)
                StatPill(value: "\(progress.learningCount)", label: "Learning", tint: Theme.warn)
                StatPill(value: "\(progress.masteredCount)", label: "Mastered", tint: Theme.success)
            }

            Button {
                Haptics.tap(enabled: settings.hapticsEnabled)
                showingStudy = true
            } label: {
                Label(
                    progress.dueCount > 0 ? "Study \(progress.dueCount) due now" : "Study new phrases",
                    systemImage: "play.fill"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityHint("Starts a spaced-repetition review session")
        }
        .cardSurface()
    }

    // MARK: Category filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                FilterChip(title: "All", symbol: "square.grid.2x2", isOn: selectedCategory == nil) {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    selectedCategory = nil
                }
                ForEach(PhraseCategory.allCases) { cat in
                    let count = sortedPhrases.filter { $0.category == cat }.count
                    if count > 0 {
                        FilterChip(title: cat.title, symbol: cat.symbol, isOn: selectedCategory == cat) {
                            Haptics.selection(enabled: settings.hapticsEnabled)
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: Phrase list
    @ViewBuilder
    private var phraseList: some View {
        if filteredPhrases.isEmpty {
            EmptyStateView(
                symbol: "text.bubble",
                title: "No phrases here",
                message: selectedCategory == nil
                    ? "This deck has no phrases yet. Add one to begin."
                    : "No phrases in this category. Try another filter.",
                actionTitle: selectedCategory == nil ? "Add Phrase" : nil,
                action: selectedCategory == nil ? { showingAddPhrase = true } : nil
            )
            .cardSurface()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(filteredPhrases.enumerated()), id: \.element.id) { idx, phrase in
                    PhraseRow(
                        phrase: phrase,
                        localeIdentifier: deck.localeIdentifier,
                        showPronunciation: settings.showPronunciation,
                        speechRate: settings.speechRate,
                        hapticsEnabled: settings.hapticsEnabled,
                        onToggleFavorite: { toggleFavorite(phrase) }
                    )
                    .padding(.vertical, Theme.Spacing.sm)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(phrase)
                        } label: { Label("Delete Phrase", systemImage: "trash") }
                    }
                    if idx < filteredPhrases.count - 1 {
                        Divider().background(Theme.textSecondary.opacity(0.1))
                    }
                }
            }
            .cardSurface(padding: Theme.Spacing.md)
        }
    }

    // MARK: Actions
    private func toggleFavorite(_ phrase: Phrase) {
        phrase.isFavorite.toggle()
        try? context.save()
    }

    private func delete(_ phrase: Phrase) {
        Haptics.warning(enabled: settings.hapticsEnabled)
        context.delete(phrase)
        try? context.save()
    }

    private func deleteDeck() {
        Haptics.warning(enabled: settings.hapticsEnabled)
        context.delete(deck)
        try? context.save()
        dismiss()
    }

    @Environment(\.dismiss) private var dismiss
}

// MARK: - Small pieces

private struct StatPill: View {
    let value: String
    let label: String
    let tint: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct FilterChip: View {
    let title: String
    let symbol: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isOn ? .white : Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Capsule().fill(isOn ? Theme.brand : Theme.surface2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        let deck = (try? container.mainContext.fetch(FetchDescriptor<Deck>()))?.first
        NavigationStack {
            if let deck { DeckDetailView(deck: deck) }
        }
        .modelContainer(container)
    }
}
