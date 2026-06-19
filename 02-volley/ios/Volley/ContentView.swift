import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var questions: [Question]
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]
    @State private var seeded = false

    var body: some View {
        Group {
            if settingsQuery.first?.hasCompletedOnboarding == true || seeded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            seedIfNeeded()
        }
    }

    private func seedIfNeeded() {
        // Seed questions on first launch
        if questions.isEmpty {
            let library = QuestionLibrary.allQuestions()
            for (text, mode, category) in library {
                let q = Question(text: text, mode: mode, category: category)
                modelContext.insert(q)
            }
        }

        // Seed settings singleton
        if settingsQuery.isEmpty {
            let settings = AppSettings()
            modelContext.insert(settings)
        }
    }
}
