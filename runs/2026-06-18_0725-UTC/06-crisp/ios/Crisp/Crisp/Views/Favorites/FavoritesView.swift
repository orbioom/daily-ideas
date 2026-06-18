import SwiftUI
import SwiftData

struct FavoritesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query(sort: \FavoriteFood.addedAt, order: .reverse) private var favorites: [FavoriteFood]
    @Query(sort: \CustomFood.createdAt, order: .reverse) private var customFoods: [CustomFood]

    @Environment(\.modelContext) private var context

    @State private var showAddCustom = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var editingFood: CustomFood? = nil
    @State private var toast: ToastMessage? = nil

    private var favoriteFoods: [Food] {
        favorites.compactMap { FoodCatalog.byId[$0.foodId] }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if favorites.isEmpty && customFoods.isEmpty {
                    EmptyStateView(
                        symbol: "heart.text.square",
                        title: "Nothing saved yet",
                        message: "Favorite foods from the Guide, or add your own custom recipes here.",
                        actionTitle: "Add a custom food",
                        action: { tryAddCustom() }
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { tryAddCustom() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add custom food")
                }
            }
            .navigationDestination(for: Food.self) { FoodDetailView(food: $0) }
            .sheet(isPresented: $showAddCustom) { CustomFoodEditor(existing: nil) }
            .sheet(item: $editingFood) { CustomFoodEditor(existing: $0) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .toast($toast)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !favoriteFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Favorites", subtitle: "\(favoriteFoods.count) saved")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(favoriteFoods) { food in
                                NavigationLink(value: food) {
                                    FoodTile(food: food, tempUnit: settings.tempUnit, isFavorite: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "My custom foods") {
                        if !pro.isPro {
                            Text("\(customFoods.count)/\(ProLimits.freeCustomFoodCap)")
                                .font(Theme.roundedStyle(.footnote, .bold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    if customFoods.isEmpty {
                        emptyCustomCard
                    } else {
                        ForEach(customFoods) { custom in
                            customRow(custom)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var emptyCustomCard: some View {
        Button { tryAddCustom() } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Add your own food with a saved temp and time.")
                    .font(Theme.roundedStyle(.subheadline, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(16)
            .crispCard()
        }
        .buttonStyle(.plain)
    }

    private func customRow(_ custom: CustomFood) -> some View {
        Button { editingFood = custom } label: {
            HStack(spacing: 14) {
                Text(custom.category.icon)
                    .font(.system(size: 30))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(custom.name)
                        .font(Theme.roundedStyle(.headline, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(Fmt.temp(fahrenheit: custom.tempF, unit: settings.tempUnit))
                        Text("·").foregroundStyle(Theme.inkSoft)
                        Text(Fmt.minutesLabel(custom.minutes))
                    }
                    .font(Theme.roundedStyle(.subheadline, .medium))
                    .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .crispCard()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { editingFood = custom } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { deleteCustom(custom) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityHint("Opens to edit. Long-press to delete.")
    }

    private func tryAddCustom() {
        if customFoods.count >= pro.customFoodCap() {
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
            showPaywall = true
        } else {
            showAddCustom = true
        }
    }

    private func deleteCustom(_ custom: CustomFood) {
        context.delete(custom)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
        toast = ToastMessage(symbol: "trash", text: "Deleted \(custom.name)")
    }
}
