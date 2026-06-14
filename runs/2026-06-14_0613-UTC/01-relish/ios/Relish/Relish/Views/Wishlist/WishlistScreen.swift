import SwiftUI
import SwiftData

private enum WishSort: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case cuisine = "Cuisine"
    var id: String { rawValue }
}

/// The want-to-try list. Each entry can be marked visited to enter the compare flow.
struct WishlistScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var allRestaurants: [Restaurant]

    @State private var sort: WishSort = .recent
    @State private var cuisineFilter: Cuisine?
    @State private var markVisitedTarget: Restaurant?
    @State private var showAdd = false

    private var wishlist: [Restaurant] {
        allRestaurants.filter { $0.isWishlist }
    }

    private var filtered: [Restaurant] {
        var list = wishlist
        if let cuisineFilter { list = list.filter { $0.cuisine == cuisineFilter } }
        switch sort {
        case .recent: list.sort { $0.dateAdded > $1.dateAdded }
        case .name: list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .cuisine: list.sort { $0.cuisine.rawValue < $1.cuisine.rawValue }
        }
        return list
    }

    private var availableCuisines: [Cuisine] {
        Array(Set(wishlist.map { $0.cuisine })).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Want to Try")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(WishSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Menu("Cuisine") {
                            Button("All cuisines") { cuisineFilter = nil }
                            ForEach(availableCuisines) { c in
                                Button {
                                    cuisineFilter = (cuisineFilter == c) ? nil : c
                                } label: {
                                    Label(c.rawValue, systemImage: cuisineFilter == c ? "checkmark" : c.symbol)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: cuisineFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Sort and filter")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddFlowView(allRestaurants: allRestaurants)
            }
            .sheet(item: $markVisitedTarget) { target in
                AddFlowView(allRestaurants: allRestaurants, wishlistSource: target)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if wishlist.isEmpty {
            EmptyStateView(symbol: "bookmark",
                           title: "Nothing on deck",
                           message: "Save places you want to try. When you go, mark them visited to fold them into your ranking.",
                           actionTitle: "Add a place") { showAdd = true }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "No want-to-try places fit that cuisine filter.",
                           actionTitle: "Clear filter") { cuisineFilter = nil }
        } else {
            List {
                ForEach(filtered) { r in
                    wishRow(r)
                        .listRowBackground(Theme.bg)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { delete(r) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { markVisitedTarget = r } label: {
                                Label("Visited", systemImage: "checkmark")
                            }
                            .tint(Theme.good)
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func wishRow(_ r: Restaurant) -> some View {
        HStack(spacing: 12) {
            CuisineBadge(cuisine: r.cuisine, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(r.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Text(r.cuisine.rawValue)
                    Text("·")
                    Text(r.priceLabel)
                    if !r.city.isEmpty { Text("·"); Text(r.city).lineLimit(1) }
                }
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button {
                markVisitedTarget = r
                Haptics.tap(settings.hapticsEnabled)
            } label: {
                Text("Visited")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.accentSoft))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(r.name) as visited")
            .accessibilityHint("Starts the comparison flow to rank it")
        }
        .padding(.vertical, 4)
    }

    private var addButton: some View {
        Button {
            showAdd = true
            Haptics.tap(settings.hapticsEnabled)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add a place to try")
    }

    private func delete(_ r: Restaurant) {
        context.delete(r)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
