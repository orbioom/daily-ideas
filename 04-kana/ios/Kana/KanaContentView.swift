import SwiftUI
import SwiftData

struct KanaContentView: View {
    @AppStorage(KanaSettings.onboardingDone) private var onboardingDone: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if !onboardingDone {
                KanaOnboardingView()
            } else {
                KanaTabView()
            }
        }
        .onAppear {
            seedDefaultCards(context: modelContext)
        }
    }
}

struct KanaTabView: View {
    @AppStorage(KanaSettings.onboardingDone) private var onboardingDone: Bool = true

    var body: some View {
        TabView {
            StudyView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.on.rectangle.angled")
                }

            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "square.grid.2x2.fill")
                }

            KanaProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            KanaSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(KanaTheme.crimsonRed)
    }
}
