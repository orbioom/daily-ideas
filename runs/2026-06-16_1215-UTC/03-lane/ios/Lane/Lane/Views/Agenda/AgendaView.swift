import SwiftUI
import SwiftData

struct AgendaView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query private var allCards: [Card]

    @State private var selectedCard: Card?
    @State private var toast: ToastMessage?

    /// Cards with due dates from non-archived boards, optionally excluding completed.
    private var dueCards: [Card] {
        allCards.filter { card in
            guard card.dueDate != nil else { return false }
            guard let board = card.column?.board, !board.isArchived else { return false }
            if !settings.showCompletedCards && card.isCompleted { return false }
            return true
        }
    }

    private var groups: [AgendaGroup] {
        AgendaGroup.build(from: dueCards)
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    EmptyStateView(
                        symbol: "calendar.badge.checkmark",
                        title: "Nothing scheduled",
                        message: "Cards with a due date show up here, grouped by when they're due."
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.cards) { card in
                                    AgendaRowView(
                                        card: card,
                                        onComplete: { complete(card) }
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedCard = card }
                                }
                            } header: {
                                HStack {
                                    Text(group.title)
                                    Spacer()
                                    Text("\(group.cards.count)")
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Agenda")
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
            .toast($toast)
        }
    }

    private func complete(_ card: Card) {
        CardMover.complete(card, context: context)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "checkmark.seal.fill", text: "Completed")
    }
}

/// Agenda buckets in display order.
struct AgendaGroup: Identifiable {
    let id: String
    let title: String
    let cards: [Card]

    static func build(from cards: [Card], reference: Date = Date()) -> [AgendaGroup] {
        var overdue: [Card] = []
        var today: [Card] = []
        var thisWeek: [Card] = []
        var later: [Card] = []

        for card in cards {
            guard let due = card.dueDate else { continue }
            if !card.isCompleted && DateUtils.isOverdue(due, reference: reference) {
                overdue.append(card)
            } else if DateUtils.isToday(due) {
                today.append(card)
            } else if DateUtils.isThisWeek(due, reference: reference) && due >= reference {
                thisWeek.append(card)
            } else {
                later.append(card)
            }
        }

        func sortByDue(_ a: Card, _ b: Card) -> Bool {
            (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
        }

        var result: [AgendaGroup] = []
        if !overdue.isEmpty { result.append(AgendaGroup(id: "overdue", title: "Overdue", cards: overdue.sorted(by: sortByDue))) }
        if !today.isEmpty { result.append(AgendaGroup(id: "today", title: "Today", cards: today.sorted(by: sortByDue))) }
        if !thisWeek.isEmpty { result.append(AgendaGroup(id: "week", title: "This Week", cards: thisWeek.sorted(by: sortByDue))) }
        if !later.isEmpty { result.append(AgendaGroup(id: "later", title: "Later", cards: later.sorted(by: sortByDue))) }
        return result
    }
}
