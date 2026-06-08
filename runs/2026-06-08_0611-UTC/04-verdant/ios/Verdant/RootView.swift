import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("verdant.onboarded") private var onboarded = false
    @AppStorage("verdant.haptics") private var hapticsEnabled = true
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true
    @AppStorage("verdant.appearance") private var appearanceRaw = "system"

    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    @Query private var rooms: [Room]

    private var preferredColorScheme: ColorScheme? {
        switch appearanceRaw {
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
        .tint(Brand.live)
        .preferredColorScheme(preferredColorScheme)
        .task {
            Haptics.enabled = hapticsEnabled
            if plants.isEmpty && rooms.isEmpty {
                SeedData.seed(modelContext: modelContext)
            }
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            Haptics.enabled = newValue
        }
    }
}
