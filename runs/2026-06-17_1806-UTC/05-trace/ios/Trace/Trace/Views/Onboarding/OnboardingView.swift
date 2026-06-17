import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var page = 0
    @State private var childName = ""
    @State private var selectedColor = AvatarPalette.colors.first ?? 0xFF8A4C
    @State private var ageText = ""

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.draw.fill",
            title: "Welcome to Trace",
            message: "A calm, ad-free place for little hands to learn letters, numbers, and shapes — one happy trace at a time."
        ),
        OnboardingPage(
            icon: "star.circle.fill",
            title: "Follow the dots, earn stars",
            message: "Kids trace along a friendly guide with a finger or Apple Pencil. Good tracing earns up to three stars."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Made for parents you trust",
            message: "No ads, no pop-ups, no data collection. A grown-up gate protects settings and purchases."
        )
    ]

    var body: some View {
        ZStack {
            WarmBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                    profileSetupPage
                        .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private var profileSetupPage: some View {
        ScrollView {
            VStack(spacing: 22) {
                AvatarBubble(
                    initial: childName.isEmpty ? "?" : String(childName.uppercased().prefix(1)),
                    color: Color(hex: UInt(selectedColor)),
                    size: 96
                )
                .padding(.top, 12)

                Text("Add your first kid")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)

                Text("You can add more later. Each child gets their own stars and progress.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    TextField("e.g. Mia", text: $childName)
                        .font(Theme.rounded(20, .semibold))
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .card(cornerRadius: Theme.radiusSmall, fill: Theme.surface)
                        .accessibilityLabel("Child's name")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Age (optional)")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    TextField("e.g. 4", text: $ageText)
                        .font(Theme.rounded(20, .semibold))
                        .keyboardType(.numberPad)
                        .padding(14)
                        .card(cornerRadius: Theme.radiusSmall, fill: Theme.surface)
                        .accessibilityLabel("Child's age")
                }

                ColorPaletteRow(selected: $selectedColor)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder private var controls: some View {
        if page < pages.count {
            HStack {
                Button("Skip") { goToSetup() }
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                ChunkyButton(title: "Next", systemImage: "arrow.right", fullWidth: false) {
                    withAnimation { page += 1 }
                }
            }
        } else {
            ChunkyButton(title: "Start tracing", systemImage: "checkmark") {
                finish()
            }
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.5 : 1)
            .accessibilityHint(trimmedName.isEmpty ? "Enter a name to continue" : "Creates the profile and opens the app")
        }
    }

    private var trimmedName: String { childName.trimmingCharacters(in: .whitespaces) }

    private func goToSetup() {
        withAnimation { page = pages.count }
    }

    private func finish() {
        let name = trimmedName.isEmpty ? "Star" : trimmedName
        let age = Int(ageText.trimmingCharacters(in: .whitespaces))
        let profile = Profile(name: name, colorHex: selectedColor, age: age)
        context.insert(profile)
        try? context.save()
        settings.activeProfileIDString = profile.id.uuidString
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let message: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 160, height: 160)
                Image(systemName: page.icon)
                    .font(.system(size: 76, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(page.title)
                .font(Theme.rounded(30, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(page.message)
                .font(Theme.rounded(18))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
    }
}
