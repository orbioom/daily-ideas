import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("nocturne.onboarded")  private var onboarded      = false
    @AppStorage("nocturne.haptics")    private var hapticsEnabled = true
    @AppStorage("nocturne.appearance") private var appearance     = "system"
    @Environment(\.modelContext) private var context
    @Query private var logs: [SleepLog]

    var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        Group {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(preferredScheme)
        .task {
            // Sync haptics flag
            Haptics.enabled = hapticsEnabled
            // Seed data if empty
            if logs.isEmpty {
                SeedData.seed(into: context)
            }
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            Haptics.enabled = newValue
        }
    }
}
