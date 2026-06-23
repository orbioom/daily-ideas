import SwiftUI
import SwiftData

/// First-run onboarding gated by the `hasOnboarded` persisted flag. The final
/// page collects the first baby's details so the app opens with real data.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PrefKey.activeBabyID) private var activeBabyIDString = ""

    @State private var page = 0
    @State private var name = ""
    @State private var birthDate = Date()

    private let pages: [(icon: String, title: String, body: String)] = [
        ("leaf.fill", "Welcome to Sprig",
         "A calm, one-tap tracker for your baby's feeds, sleep, diapers and growth — no subscription wall on the basics."),
        ("hand.tap.fill", "Log in a tap",
         "Start a breast timer, jot a bottle, mark a diaper, or capture a sleep — all from the Today screen."),
        ("chart.line.uptrend.xyaxis", "Watch them grow",
         "See real charts for feeds, sleep and diapers, plus a simple weight & length growth log over time.")
    ]

    var body: some View {
        ZStack {
            Theme.ambientGradient(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        introPage(pages[i]).tag(i)
                    }
                    profilePage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.vertical, 12)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func introPage(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 130, height: 130)
                    .shadow(color: Theme.accent.opacity(0.3), radius: 18, y: 8)
                Image(systemName: p.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText(scheme))
            Text(p.body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText(scheme))
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
    }

    private var profilePage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentGradient).frame(width: 110, height: 110)
                Image(systemName: "figure.child")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("Add your baby")
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.primaryText(scheme))

            VStack(spacing: 14) {
                TextField("Baby's name", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline(scheme)))
                    .accessibilityLabel("Baby's name")

                DatePicker("Birth date", selection: $birthDate,
                           in: ...Date(), displayedComponents: .date)
                    .padding(14)
                    .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline(scheme)))
            }
            .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.secondaryText(scheme).opacity(0.3))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var controls: some View {
        if page < pages.count {
            VStack(spacing: 10) {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
                Button("Skip") { page = pages.count }
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
        } else {
            PrimaryButton(title: "Start tracking", systemImage: "checkmark",
                          enabled: !trimmedName.isEmpty) {
                finish()
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func finish() {
        let finalName = trimmedName.isEmpty ? "Baby" : trimmedName
        let baby = Baby(name: finalName, birthDate: birthDate)
        context.insert(baby)
        try? context.save()
        activeBabyIDString = baby.id.uuidString
        hasOnboarded = true
    }
}
