import SwiftUI
import SwiftData

struct MemoirContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prompts: [WritingPrompt]
    @State private var onboardingDone: Bool = MemoirSettings.onboardingDone
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if !onboardingDone {
                MemoirOnboardingView {
                    onboardingDone = true
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                MemoirTabView(selectedTab: $selectedTab)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingDone)
        .onAppear {
            seedPromptsIfNeeded()
        }
    }

    private func seedPromptsIfNeeded() {
        guard prompts.isEmpty else { return }
        let defaults = WritingPrompt.defaultPrompts
        for prompt in defaults {
            modelContext.insert(prompt)
        }
        try? modelContext.save()
    }
}

// MARK: - MemoirTabView

struct MemoirTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            WriteView()
                .tabItem {
                    Label("Write", systemImage: selectedTab == 0 ? "pencil.line" : "pencil")
                }
                .tag(0)

            StoriesView()
                .tabItem {
                    Label("Stories", systemImage: selectedTab == 1 ? "books.vertical.fill" : "books.vertical")
                }
                .tag(1)

            MemoirProgressView()
                .tabItem {
                    Label("Progress", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(2)

            MemoirSettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .tint(MemoirTheme.warmAmber)
    }
}
