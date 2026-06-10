import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var installStarters = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    progression.tag(1)
                    starters.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Continue" : "Begin training") {
                    if page < 2 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        if installStarters { StarterProgram.install(into: context) }
                        Haptics.success()
                        hasOnboarded = true
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < 2 ? "Shows the next page" : "Finishes setup and opens the app")
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Atlas")
            Text("Programs, not\nguesswork.")
                .font(.system(size: 34, weight: .semibold, design: .default))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("Build reusable routines, run them with a rest timer, and let Atlas decide when to add weight.")
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var progression: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "Progression built in")
            Text("Every session\nknows the last one.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                LabeledRule(symbol: "repeat", text: "Double progression — earn reps inside the range, then add weight.")
                LabeledRule(symbol: "plus.forwardslash.minus", text: "Linear — add a fixed increment whenever you complete the work.")
                LabeledRule(symbol: "timer", text: "A calm rest timer starts itself when you finish a set.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var starters: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Start anywhere")
            Text("Want a proven\nstarting point?")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Toggle(isOn: $installStarters) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Install starter program")
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text("Full Body A/B plus an Upper and Lower day. Edit or delete anything.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
            .tint(Brand.live)
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct LabeledRule: View {
    let symbol: String
    let text: String
    var body: some View {
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
