import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("anchor.onboarded") private var onboarded = false
    @AppStorage("anchor.haptics") private var haptics = true
    @AppStorage("anchor.appearance") private var appearanceRaw = "system"
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]

    private var preferredScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        ZStack {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView(done: $onboarded)
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(preferredScheme)
        .task {
            Haptics.enabled = haptics
            if habits.isEmpty {
                var cal = Calendar.current
                cal.firstWeekday = 1
                SampleData.seed(into: context, calendar: cal)
            }
        }
        .onAppear {
            Haptics.enabled = haptics
        }
        .onChange(of: haptics) { _, newValue in
            Haptics.enabled = newValue
        }
    }
}

// MARK: - Main Tabs

struct MainTabs: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "list.bullet.circle.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
