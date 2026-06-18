import SwiftUI
import SwiftData

struct GuideView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query private var favorites: [FavoriteFood]

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var favoritesOnly = false
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var favoriteIds: Set<String> {
        Set(favorites.map { $0.foodId })
    }

    private var filteredFoods: [Food] {
        var foods = FoodCatalog.all
        if let cat = selectedCategory {
            foods = foods.filter { $0.category == cat }
        }
        if favoritesOnly {
            foods = foods.filter { favoriteIds.contains($0.id) }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            foods = foods.filter {
                $0.name.lowercased().contains(q) || $0.category.rawValue.lowercased().contains(q)
            }
        }
        return foods
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Guide")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .searchable(text: $searchText, prompt: "Search foods")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: Food.self) { food in
                FoodDetailView(food: food)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                categoryFilters
                if filteredFoods.isEmpty {
                    EmptyStateView(
                        symbol: favoritesOnly ? "heart.slash" : "magnifyingglass",
                        title: favoritesOnly ? "No favorites yet" : "No foods found",
                        message: favoritesOnly
                            ? "Tap the heart on any food to save it here for quick access."
                            : "Try a different search or category.",
                        actionTitle: favoritesOnly ? "Browse all foods" : nil,
                        action: favoritesOnly ? { favoritesOnly = false } : nil
                    )
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredFoods) { food in
                            NavigationLink(value: food) {
                                FoodTile(
                                    food: food,
                                    tempUnit: settings.tempUnit,
                                    isFavorite: favoriteIds.contains(food.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Favorites", icon: "heart.fill", isOn: favoritesOnly) {
                    withAnimation(.easeInOut(duration: 0.2)) { favoritesOnly.toggle() }
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                FilterChip(label: "All", icon: nil, isOn: selectedCategory == nil && !favoritesOnly) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                        favoritesOnly = false
                    }
                }
                ForEach(FoodCategory.allCases) { cat in
                    FilterChip(label: cat.rawValue, emoji: cat.icon, isOn: selectedCategory == cat) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// A pill filter chip used in the category row.
struct FilterChip: View {
    let label: String
    var icon: String? = nil
    var emoji: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let emoji { Text(emoji).font(.system(size: 14)) }
                if let icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .bold))
                }
                Text(label)
                    .font(Theme.roundedStyle(.subheadline, .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isOn ? .white : Theme.ink)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surface))
            )
            .overlay(Capsule().strokeBorder(isOn ? Color.clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
