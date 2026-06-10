import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var showProfileForm = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    honesty.tag(1)
                    start.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Continue" : "Enter your birth details") {
                    if page < 2 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        showProfileForm = true
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)

                if page == 2 {
                    Button("Skip for now") {
                        Haptics.tap()
                        hasOnboarded = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .padding(.top, 12)
                    .accessibilityHint("Opens the app without a birth chart; you can add one later in People")
                }
            }
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showProfileForm) {
            ProfileEditorView(profile: nil, makePrimary: true) {
                Haptics.success()
                hasOnboarded = true
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Ecliptic")
            Text("Your sky,\ncomputed honestly.")
                .font(.system(size: 34, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("A real ephemeris runs on your device — every placement is calculated from orbital mechanics, never fetched, never guessed.")
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var honesty: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "scope")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "No black box")
            Text("The math is\non the screen.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                row("function", "Sun, Moon, and planets from published orbital theory — arcminute precision for a century either side of today.")
                row("house", "Whole-sign houses by default; switch to equal houses any time. Every aspect shows its exact orb.")
                row("lock", "Birth data never leaves this device. No account. No push notifications second-guessing your day.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var start: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "First chart")
            Text("Date, time, place.")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text("Birth time gives you your rising sign and houses. Don't know it? Mark it unknown — your planets are still exact.")
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Brand.text3)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
