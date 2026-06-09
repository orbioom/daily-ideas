import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Person.sortIndex) private var people: [Person]
    @Query(sort: \Occasion.sortIndex) private var occasions: [Occasion]
    @Query private var gifts: [Gift]

    @AppStorage("trove.currencyCode") private var currencyCode = "USD"
    @State private var showAddGift = false

    private var upcoming: [GiftEngine.Upcoming] {
        GiftEngine.upcoming(occasions: occasions, people: people, within: 365)
    }
    private var toBuy: Int { GiftEngine.toBuyCount(gifts) }
    private var spent: Double { GiftEngine.totalSpend(gifts) }
    private var budget: Double { GiftEngine.totalBudget(occasions) }
    private var budgetFraction: Double { budget > 0 ? min(spent / budget, 1) : 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if people.isEmpty && occasions.isEmpty {
                    EmptyStateView(
                        icon: "gift",
                        title: "Welcome to Trove",
                        message: "Add the people you give to and the occasions you're planning for. Everything you track lives right here.")
                    .glassCard()
                } else {
                    summaryCard
                    budgetCard
                    upcomingSection
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Trove")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showAddGift = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add gift")
            }
        }
        .sheet(isPresented: $showAddGift) {
            NavigationStack { GiftEditorView() }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(toBuy)", label: "To buy", tint: Brand.info)
            StatTile(value: "\(people.count)", label: "People")
            StatTile(value: "\(upcoming.count)", label: "Upcoming")
        }
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Budget overview")
            HStack(alignment: .center, spacing: 16) {
                ProgressRing(progress: budgetFraction,
                             lineWidth: 12,
                             tint: spent > budget && budget > 0 ? Brand.danger : Brand.live)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(budget > 0 ? "\(Int((budgetFraction * 100).rounded()))%" : "—")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Format.currency(spent, code: currencyCode)) spent")
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if budget > 0 {
                        Text("of \(Format.currency(budget, code: currencyCode)) budgeted")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    } else {
                        Text("No budgets set yet")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(budget > 0
            ? "Spent \(Format.currency(spent, code: currencyCode)) of \(Format.currency(budget, code: currencyCode)) budget"
            : "Spent \(Format.currency(spent, code: currencyCode)), no budgets set")
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Upcoming")
            if upcoming.isEmpty {
                Text("No occasions or birthdays coming up. Add some to see countdowns here.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .glassCard()
            } else {
                ForEach(upcoming.prefix(8)) { item in
                    UpcomingRow(item: item)
                }
            }
        }
    }
}

private struct UpcomingRow: View {
    let item: GiftEngine.Upcoming

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.kind == .birthday ? "birthday.cake" : "calendar")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(item.kind == .birthday ? Brand.magic : Brand.info)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text("\(item.subtitle) · \(Format.shortDay.string(from: item.date))")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Text(Format.countdown(daysAway: item.daysAway))
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(item.daysAway <= 7 ? Brand.warn : Brand.text2)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(Format.countdown(daysAway: item.daysAway))")
    }
}
