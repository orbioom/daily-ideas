import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    method.tag(1)
                    care.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Continue" : "Begin") {
                    if page < 2 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        Haptics.success()
                        hasOnboarded = true
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "sun.and.horizon")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Steady")
            Text("Thoughts aren't\nverdicts.")
                .font(.system(size: 34, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("A calm CBT thought diary. Catch the thought, check it against the evidence, and write the fairer version — the technique with the strongest evidence base in psychology.")
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var method: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "scalemass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "How it works")
            Text("Catch. Check.\nChange.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                row("1", "Catch — note the situation, the feeling, and the automatic thought.")
                row("2", "Check — spot the thinking trap and weigh the actual evidence.")
                row("3", "Change — write the balanced thought and re-rate how you feel.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Text("Most people's distress drops measurably in one sitting — and Steady shows you that number.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var care: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Private, and honest")
            Text("Yours alone.")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                row("🔒", "Everything stays on this device. No account, no cloud, no analytics.")
                row("🤍", "Steady is a self-help tool, not therapy or medical care.")
                row("☎️", "If you're in crisis, reach out to local emergency services or a crisis line — that comes before any app.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func row(_ badge: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(badge)
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text2)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
