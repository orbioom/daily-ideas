import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("cradle.onboarded") private var onboarded = false
    @AppStorage("cradle.haptics") private var hapticsEnabled = true
    @AppStorage("cradle.appearance") private var appearanceRaw = "system"
    @Environment(\.modelContext) private var context
    @Query private var babies: [Baby]

    private var preferredScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
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
            Haptics.enabled = hapticsEnabled
            SeedData.seed(context: context)
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            Haptics.enabled = newValue
        }
    }
}
