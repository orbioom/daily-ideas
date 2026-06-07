import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("gambit.hasOnboarded") private var hasOnboarded = false
    @AppStorage("gambit.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("gambit.appearance") private var appearance = "system"
    @Query private var encounters: [Encounter]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    EncountersView()
                        .tabItem { Label("Encounters", systemImage: "shield.lefthalf.filled") }
                    BestiaryView()
                        .tabItem { Label("Bestiary", systemImage: "pawprint") }
                    DiceView()
                        .tabItem { Label("Dice", systemImage: "dice") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if encounters.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
