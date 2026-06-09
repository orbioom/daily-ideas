import SwiftUI
import SwiftData

struct OccasionsView: View {
    @Query(sort: \Occasion.sortIndex) private var occasions: [Occasion]
    @AppStorage("trove.currencyCode") private var currencyCode = "USD"

    @State private var showAdd = false

    /// Occasions sorted by their next occurrence so the soonest is first.
    private var sortedByNext: [(occasion: Occasion, date: Date, daysAway: Int)] {
        occasions.map {
            let d = GiftEngine.nextOccurrence(of: $0)
            return ($0, d, GiftEngine.daysAway(d))
        }
        .sorted { $0.1 < $1.1 }
        .map { (occasion: $0.0, date: $0.1, daysAway: $0.2) }
    }

    var body: some View {
        ScrollView {
            if occasions.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No occasions yet",
                    message: "Add birthdays, holidays, or anniversaries. Annual ones roll forward automatically. Tap + to start.")
                .glassCard()
                .padding(20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedByNext, id: \.occasion.persistentModelID) { item in
                        NavigationLink {
                            OccasionDetailView(occasion: item.occasion)
                        } label: {
                            OccasionRow(occasion: item.occasion,
                                        nextDate: item.date,
                                        daysAway: item.daysAway,
                                        currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Occasions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add occasion")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { OccasionEditorView() }
        }
    }
}

private struct OccasionRow: View {
    let occasion: Occasion
    let nextDate: Date
    let daysAway: Int
    let currencyCode: String

    private var status: GiftEngine.BudgetStatus { GiftEngine.budgetStatus(for: occasion) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(occasion.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text("\(Format.shortDay.string(from: nextDate)) · \(Format.countdown(daysAway: daysAway))")
                        .font(.caption)
                        .foregroundStyle(daysAway <= 7 ? Brand.warn : Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
            if status.budget > 0 {
                BudgetBar(fraction: status.fraction, overBudget: status.overBudget)
                HStack {
                    Text("\(Format.currency(status.spent, code: currencyCode)) of \(Format.currency(status.budget, code: currencyCode))")
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    if status.overBudget {
                        Text("Over by \(Format.currency(-status.remaining, code: currencyCode))")
                            .font(Brand.mono(11, weight: .medium))
                            .foregroundStyle(Brand.danger)
                    }
                }
            } else {
                Text("\(occasion.gifts.count) gift\(occasion.gifts.count == 1 ? "" : "s") · no budget")
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var s = "\(occasion.name), \(Format.countdown(daysAway: daysAway))"
        if status.budget > 0 {
            s += ", \(Format.currency(status.spent, code: currencyCode)) of \(Format.currency(status.budget, code: currencyCode)) budget"
            if status.overBudget { s += ", over budget" }
        }
        return s
    }
}
