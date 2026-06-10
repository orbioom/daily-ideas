import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("nameA") private var nameA = ""
    @AppStorage("nameB") private var nameB = ""
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var fieldA = ""
    @State private var fieldB = ""
    @State private var anniversary = Calendar.current.date(byAdding: .year, value: -2, to: .now) ?? .now
    @State private var hasAnniversary = true
    @State private var error: String?

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    ritual.tag(1)
                    names.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Continue" : "Start your first question") {
                    if page < 2 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        finish()
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private func finish() {
        let a = fieldA.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = fieldB.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !a.isEmpty, !b.isEmpty else {
            error = "Both names are needed — that's the whole duet."
            return
        }
        nameA = a
        nameB = b
        if hasAnniversary {
            context.insert(Occasion(title: "Anniversary", date: anniversary, repeatsAnnually: true))
        }
        Haptics.success()
        hasOnboarded = true
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "heart.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Duet")
            Text("One phone.\nTwo answers.")
                .font(.system(size: 34, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("A daily question you answer separately on the same phone — then reveal together. Plus date ideas, shared memories, and a weekly pulse.")
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private var ritual: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "The ritual")
            Text("Answer. Pass.\nReveal.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                step("1", "One of you answers today's question — the other doesn't peek.")
                step("2", "Pass the phone. The screen hides the first answer.")
                step("3", "Reveal both at once. The gap between answers is where the conversation lives.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var names: some View {
        VStack(spacing: 18) {
            Spacer()
            Eyebrow(text: "Who's playing")
            Text("Introduce yourselves")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Brand.text)
            VStack(spacing: 12) {
                TextField("First partner's name", text: $fieldA)
                    .textFieldStyle(.roundedBorder)
                TextField("Second partner's name", text: $fieldB)
                    .textFieldStyle(.roundedBorder)
                Toggle(isOn: $hasAnniversary) {
                    Text("We have an anniversary")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                }
                .tint(Brand.live)
                if hasAnniversary {
                    DatePicker("Anniversary", selection: $anniversary, displayedComponents: .date)
                        .font(.subheadline)
                }
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(Brand.danger)
                }
            }
            .glassCard()
            .padding(.horizontal, 24)
            Text("Names stay on this phone. No accounts, no second download, no subscription for your relationship.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n)
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text2)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
