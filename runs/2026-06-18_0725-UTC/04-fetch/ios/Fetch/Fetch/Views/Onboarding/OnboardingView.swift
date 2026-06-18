import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hasSeeded") private var hasSeeded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0
    @State private var dogName = ""
    @State private var dogBreed = ""

    private let pages: [(icon: String, title: String, body: String)] = [
        ("pawprint.fill", "Welcome to Fetch",
         "Your pocket dog-training coach. Teach commands and tricks with clear, step-by-step lessons \u{2014} no $40-a-month subscription required."),
        ("books.vertical.fill", "Lessons that actually help",
         "Over 40 tricks across Basics, Manners, Tricks and Agility, each broken into bite-sized steps with real trainer tips."),
        ("timer", "Practice with a clicker",
         "Run timed sessions, count reps, and use the built-in clicker. Track every dog's progress and watch the streaks grow.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        valuePage(pages[i])
                            .tag(i)
                    }
                    createDogPage
                        .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.vertical, 16)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        }
    }

    private var totalPages: Int { pages.count + 1 }

    private func valuePage(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 150, height: 150)
                Image(systemName: p.icon)
                    .font(.system(size: 62, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
    }

    private var createDogPage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 120, height: 120)
                Image(systemName: "dog.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text("Add your dog")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("Let's set up your first trainee. You can add more dogs later.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                LabeledField(title: "Name", text: $dogName, prompt: "e.g. Cooper")
                LabeledField(title: "Breed (optional)", text: $dogBreed, prompt: "e.g. Golden Retriever")
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)

            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var footer: some View {
        if page < pages.count {
            Button {
                advance()
            } label: {
                Text(page == pages.count - 1 ? "Get started" : "Next")
            }
            .buttonStyle(PrimaryButtonStyle())
        } else {
            VStack(spacing: 10) {
                Button("Start training") { finish() }
                    .buttonStyle(PrimaryButtonStyle(enabled: canFinish))
                    .disabled(!canFinish)
                if !canFinish {
                    Text("Enter a name to continue")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var canFinish: Bool {
        !dogName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func advance() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            page = min(totalPages - 1, page + 1)
        }
    }

    private func finish() {
        let name = dogName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let breed = dogBreed.trimmingCharacters(in: .whitespacesAndNewlines)

        let dog = Dog(name: name, breed: breed, isActive: true)
        context.insert(dog)
        try? context.save()

        // Mark seeding done so we don't inject the sample Cooper on top of the user's dog.
        hasSeeded = true
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}

/// Reusable labeled text field used in onboarding & dog editing.
struct LabeledField: View {
    let title: String
    @Binding var text: String
    var prompt: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField(prompt, text: $text)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surfaceAlt)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }
}
