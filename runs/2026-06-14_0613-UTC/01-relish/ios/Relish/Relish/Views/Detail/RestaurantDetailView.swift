import SwiftUI
import SwiftData

/// Full detail for a ranked restaurant: score, dishes, visits, notes, edit, re-rank.
struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var restaurant: Restaurant
    let allRestaurants: [Restaurant]

    @State private var showEdit = false
    @State private var showRerank = false
    @State private var showAddDish = false
    @State private var editingDish: Dish?
    @State private var showAddVisit = false
    @State private var editingVisit: Visit?
    @State private var showDeleteConfirm = false

    private var score: Double {
        ScoreBook(allRestaurants: allRestaurants).score(restaurant)
    }

    private var rankNumber: Int {
        let ordered = allRestaurants
            .filter { !$0.isWishlist && $0.sentiment != nil }
            .sorted { $0.rankIndex < $1.rankIndex }
        return (ordered.firstIndex { $0.id == restaurant.id } ?? restaurant.rankIndex) + 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                metaRow
                actionRow
                if !restaurant.notes.isEmpty { notesCard }
                dishesSection
                visitsSection
                deleteButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit restaurant")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditRestaurantView(restaurant: restaurant)
        }
        .sheet(isPresented: $showRerank) {
            AddFlowView(allRestaurants: allRestaurants, existing: restaurant)
        }
        .sheet(isPresented: $showAddDish) {
            DishEditorView(restaurant: restaurant, dish: nil)
        }
        .sheet(item: $editingDish) { dish in
            DishEditorView(restaurant: restaurant, dish: dish)
        }
        .sheet(isPresented: $showAddVisit) {
            VisitEditorView(restaurant: restaurant, visit: nil)
        }
        .sheet(item: $editingVisit) { visit in
            VisitEditorView(restaurant: restaurant, visit: visit)
        }
        .confirmationDialog("Delete \(restaurant.name)?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes it and re-numbers your ranking. This can't be undone.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ScoreChip(score: score, sentiment: restaurant.sentiment, size: 110)
            Text("Ranked #\(rankNumber) of your visits")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            if let s = restaurant.sentiment {
                Label(s.rawValue, systemImage: s.symbol)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(s.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Pill(text: restaurant.cuisine.rawValue, systemImage: restaurant.cuisine.symbol, tint: restaurant.cuisine.hue)
            Pill(text: restaurant.priceLabel, systemImage: "creditcard")
            if !restaurant.city.isEmpty {
                Pill(text: restaurant.city, systemImage: "mappin")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                restaurant.isFavorite.toggle()
                try? context.save()
                Haptics.tap(settings.hapticsEnabled)
            } label: {
                Label(restaurant.isFavorite ? "Favorited" : "Favorite",
                      systemImage: restaurant.isFavorite ? "star.fill" : "star")
                    .font(Theme.rounded(14, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(restaurant.isFavorite ? Theme.accentSoft : Theme.surface))
                    .foregroundStyle(restaurant.isFavorite ? Theme.accent : Theme.ink)
            }
            .accessibilityLabel(restaurant.isFavorite ? "Remove favorite" : "Add favorite")

            Button {
                showRerank = true
                Haptics.tap(settings.hapticsEnabled)
            } label: {
                Label("Re-rank", systemImage: "arrow.left.arrow.right")
                    .font(Theme.rounded(14, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.surface))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityHint("Re-runs the comparison to reposition this place")
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkFaint)
            Text(restaurant.notes)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var dishesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Dishes", count: restaurant.dishes.count) { showAddDish = true }
            if restaurant.dishes.isEmpty {
                emptyMini("No dishes logged yet.", symbol: "fork.knife")
            } else {
                ForEach(restaurant.dishes.sorted { $0.rating > $1.rating }) { dish in
                    Button { editingDish = dish } label: { dishRow(dish) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func dishRow(_ dish: Dish) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dish.name)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= dish.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.accent)
                    }
                    if dish.wouldOrderAgain {
                        Text("· Order again")
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.good)
                    }
                }
                .accessibilityLabel("\(dish.rating) of 5 stars\(dish.wouldOrderAgain ? ", would order again" : "")")
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }

    private var visitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Visits", count: restaurant.visits.count) { showAddVisit = true }
            if restaurant.visits.isEmpty {
                emptyMini("No visits logged yet.", symbol: "calendar")
            } else {
                ForEach(restaurant.visits.sorted { $0.date > $1.date }) { visit in
                    Button { editingVisit = visit } label: { visitRow(visit) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func visitRow(_ visit: Visit) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    if !visit.companions.isEmpty {
                        Text(visit.companions).lineLimit(1)
                    }
                    if let amt = visit.amountSpent {
                        if !visit.companions.isEmpty { Text("·") }
                        Text(settings.formatMoney(amt))
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete restaurant", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.bad)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.bad.opacity(0.1)))
        }
        .padding(.top, 8)
    }

    private func sectionHeader(_ title: String, count: Int, add: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("\(count)")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkFaint)
            Spacer()
            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityLabel("Add \(title.lowercased())")
        }
    }

    private func emptyMini(_ text: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Theme.inkFaint)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }

    private func performDelete() {
        let wasRanked = !restaurant.isWishlist
        context.delete(restaurant)
        try? context.save()

        if wasRanked {
            // Re-number remaining ranked places to close the gap.
            let remaining = allRestaurants
                .filter { $0.id != restaurant.id && !$0.isWishlist && $0.sentiment != nil }
                .sorted { $0.rankIndex < $1.rankIndex }
            RankingEngine.reindex(remaining)
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
