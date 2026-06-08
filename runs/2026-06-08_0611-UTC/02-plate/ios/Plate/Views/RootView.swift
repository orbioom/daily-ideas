import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("plate.onboarded") private var onboarded = false
    @AppStorage("plate.haptics") private var hapticsEnabled = true
    @Environment(\.modelContext) private var ctx
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var foods: [FoodItem]
    @Query private var goals: [UserGoal]

    var body: some View {
        Group {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView {
                    withAnimation(reduceMotion ? nil : Brand.ease()) {
                        onboarded = true
                    }
                }
            }
        }
        .tint(Brand.text)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newVal in Haptics.enabled = newVal }
        .task { await seedIfNeeded() }
    }

    private func seedIfNeeded() async {
        if foods.isEmpty {
            for food in SeedData.catalog {
                ctx.insert(food)
            }
            // Mark a few as favorite
            let favoriteNames = [
                "Chicken Breast, Grilled", "Oatmeal, Cooked", "Greek Yogurt, Plain 0%",
                "Salmon Fillet, Baked", "Eggs, Large", "Brown Rice, Cooked"
            ]
            for food in SeedData.catalog where favoriteNames.contains(food.name) {
                food.isFavorite = true
            }

            let insertedFoods = SeedData.catalog
            let diaryEntries = SeedData.diaryEntries(foods: insertedFoods)
            for entry in diaryEntries {
                ctx.insert(entry)
            }
        }

        if goals.isEmpty {
            let goal = SeedData.defaultGoal()
            ctx.insert(goal)
        }

        try? ctx.save()
    }
}

// MARK: - Main tabs

struct MainTabs: View {
    @AppStorage("plate.appearance") private var appearance = "system"

    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book.fill")
                }
            FoodsView()
                .tabItem {
                    Label("Foods", systemImage: "square.grid.2x2.fill")
                }
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar.fill")
                }
            GoalView()
                .tabItem {
                    Label("Goal", systemImage: "target")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(colorScheme(for: appearance))
    }

    private func colorScheme(for value: String) -> ColorScheme? {
        switch value {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}
