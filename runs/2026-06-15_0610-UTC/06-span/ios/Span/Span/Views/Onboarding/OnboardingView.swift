import SwiftUI
import SwiftData

/// First-run onboarding: a short intro, then birth-date + life-expectancy setup that
/// creates the LifeProfile. Gated by `hasOnboarded`.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false

    @State private var page = 0
    @State private var birthDate: Date = Self.defaultBirthDate
    @State private var expectancy: Double = 90

    private static var defaultBirthDate: Date {
        var c = DateComponents(); c.year = 1995; c.month = 6; c.day = 21
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    private struct Intro: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let intros: [Intro] = [
        Intro(symbol: "calendar",
              title: "Your life in weeks",
              body: "Every week you'll ever live, laid out as a single grid of dots. One look, and a lifetime fits on a screen."),
        Intro(symbol: "paintpalette",
              title: "Color it into chapters",
              body: "Childhood, school, the city you moved to, the job that changed you — paint each era and watch your story take shape."),
        Intro(symbol: "hourglass",
              title: "See the time you have",
              body: "The weeks you've lived are filled. This week glows. Everything ahead is still yours to spend.")
    ]

    private var isSetupPage: Bool { page == intros.count }
    private var birthInFuture: Bool { birthDate > Date() }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(intros.enumerated()), id: \.element.id) { index, item in
                        introView(item).tag(index)
                    }
                    setupView.tag(intros.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: isSetupPage ? "Show my life" : "Next",
                                  systemImage: isSetupPage ? "checkmark" : "arrow.right",
                                  enabled: !(isSetupPage && birthInFuture)) {
                        advance()
                    }
                    Button("Skip") { finish(createProfile: true) }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(isSetupPage ? 0 : 1)
                        .disabled(isSetupPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func introView(_ item: Intro) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 74, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.serif(32, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.badge.clock")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 24)
                    .accessibilityHidden(true)
                Text("When did your story begin?")
                    .font(Theme.serif(27, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                CardView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birth date")
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                            DatePicker("Birth date", selection: $birthDate,
                                       in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        Divider().background(Theme.hairline)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Life expectancy")
                                    .font(Theme.rounded(14, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text("\(Int(expectancy)) years")
                                    .font(Theme.rounded(15, .bold))
                                    .foregroundStyle(Theme.accent)
                            }
                            Slider(value: $expectancy,
                                   in: Double(SpanEngine.minExpectancy)...Double(SpanEngine.maxExpectancy),
                                   step: 1)
                                .accessibilityValue("\(Int(expectancy)) years")
                        }
                    }
                }
                .padding(.horizontal, 24)

                Text("You can edit any of this later. Nothing leaves your device.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
        }
    }

    private func advance() {
        if page < intros.count {
            Haptics.select(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish(createProfile: true)
        }
    }

    private func finish(createProfile: Bool) {
        if createProfile {
            // Avoid duplicates if a profile somehow already exists.
            let existing = (try? context.fetch(FetchDescriptor<LifeProfile>())) ?? []
            if existing.isEmpty {
                let profile = LifeProfile(birthDate: min(birthDate, Date()),
                                          lifeExpectancyYears: SpanEngine.clampExpectancy(Int(expectancy)),
                                          weekStartsMonday: true)
                context.insert(profile)
                SeedData.insertSampleChaptersAndMoments(context: context, for: profile)
                try? context.save()
            }
            // Mark seeded so RootView doesn't overwrite the user's profile with the demo life.
            didSeed = true
        }
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
