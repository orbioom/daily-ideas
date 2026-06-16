import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0

    // First-profile inputs
    @State private var childName = ""
    @State private var avatar = "🦊"
    @State private var startLevelIndex = 0

    private let avatars = ["🦊", "🐼", "🐯", "🦄", "🐢", "🐙", "🦉", "🐳", "🦁", "🐸"]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    parentPage.tag(2)
                    createProfilePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.vertical, 12)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: Pages

    private var welcomePage: some View {
        OnboardingPage(
            emoji: "🧮",
            title: "Welcome to Digit",
            message: "A calm, friendly way for kids 5–11 to build real math-fact fluency — no ads, no subscriptions.")
    }

    private var howItWorksPage: some View {
        OnboardingPage(
            emoji: "⭐️",
            title: "Practice that adapts",
            message: "Digit picks the facts your child needs most — new ones, tricky ones, and ones due for review — and celebrates every win.")
    }

    private var parentPage: some View {
        OnboardingPage(
            emoji: "📊",
            title: "A real parent dashboard",
            message: "See the mastery grid, accuracy and speed trends, streaks and badges. Know exactly how your child is growing.")
    }

    private var createProfilePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create your first child")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("You can add more children later with Digit Pro.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    TextField("e.g. Ava", text: $childName)
                        .textInputAutocapitalization(.words)
                        .font(Theme.rounded(18))
                        .padding(14)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1))
                        .accessibilityLabel("Child's name")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick an avatar")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(avatars, id: \.self) { emoji in
                            Button {
                                avatar = emoji
                                Haptics.tap(settings.hapticsEnabled)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 54, height: 54)
                                    .background(avatar == emoji ? Theme.accent.opacity(0.18) : Theme.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(avatar == emoji ? Theme.accent : Theme.hairline,
                                                             lineWidth: avatar == emoji ? 2 : 1))
                            }
                            .accessibilityLabel("Avatar \(emoji)")
                            .accessibilityAddTraits(avatar == emoji ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting level")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    ForEach(freeStartLevels) { level in
                        Button {
                            startLevelIndex = level.id
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            HStack {
                                Text(level.emoji).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.title)
                                        .font(Theme.rounded(16, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(level.subtitle)
                                        .font(Theme.rounded(13))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                Image(systemName: startLevelIndex == level.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(startLevelIndex == level.id ? Theme.accent : Theme.inkSoft.opacity(0.5))
                                    .font(.system(size: 22))
                            }
                            .padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous)
                                .stroke(startLevelIndex == level.id ? Theme.accent : Theme.hairline,
                                        lineWidth: startLevelIndex == level.id ? 2 : 1))
                        }
                        .accessibilityAddTraits(startLevelIndex == level.id ? .isSelected : [])
                    }
                    Text("Multiplication, division and more unlock with Digit Pro.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(24)
        }
    }

    /// Only free levels are offered at onboarding (add/sub).
    private var freeStartLevels: [Level] {
        Curriculum.levels.filter { !$0.requiresPro }
    }

    // MARK: Controls

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.inkSoft.opacity(0.3))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var controls: some View {
        if page < 3 {
            HStack {
                Button("Skip") { goToCreate() }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                PrimaryButton(title: "Next", systemImage: "arrow.right") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                    Haptics.tap(settings.hapticsEnabled)
                }
                .frame(width: 160)
            }
        } else {
            PrimaryButton(title: "Start practicing", systemImage: "sparkles") {
                finish()
            }
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.5 : 1)
        }
    }

    private var trimmedName: String {
        childName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func goToCreate() {
        withAnimation(reduceMotion ? nil : .easeInOut) { page = 3 }
    }

    private func finish() {
        let name = trimmedName.isEmpty ? "My Child" : trimmedName
        let level = Curriculum.level(at: startLevelIndex)
        let profile = Profile(name: name,
                              avatarEmoji: avatar,
                              currentLevelIndex: level.id,
                              maxNumber: level.maxNumber,
                              enabledOps: Set(level.ops))
        context.insert(profile)
        try? context.save()
        settings.selectedProfileID = profile.id.uuidString
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}

/// A single centered onboarding info page.
private struct OnboardingPage: View {
    let emoji: String
    let title: String
    let message: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(emoji)
                .font(.system(size: 96))
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.8))
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
