import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var chosen: String?

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    method.tag(1)
                    pick.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(buttonTitle) {
                    if page < 2 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        if let code = chosen, let pack = Lexicon.pack(code: code) {
                            install(pack)
                        }
                        Haptics.success()
                        hasOnboarded = true
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < 2 ? "Shows the next page" : "Finishes setup")
            }
        }
    }

    private var buttonTitle: String {
        if page < 2 { return "Continue" }
        if let code = chosen, let pack = Lexicon.pack(code: code) {
            return "Start with \(pack.name)"
        }
        return "Start empty"
    }

    private func install(_ pack: LanguagePack) {
        let deck = Deck(name: "\(pack.name) essentials", languageCode: pack.code)
        context.insert(deck)
        deck.cards = pack.entries.map { entry in
            Card(front: entry.front, back: entry.back, gender: entry.gender,
                 exampleTarget: entry.exampleTarget, exampleEnglish: entry.exampleEnglish,
                 catalogID: entry.id)
        }
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "text.bubble")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            Eyebrow(text: "Glossa")
            Text("Words that\nactually stick.")
                .font(.system(size: 34, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("A calm vocabulary trainer with real spaced repetition. No streak guilt, no five-minute lockouts, everything on your device.")
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
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "The Leitner system")
            Text("Five boxes.\nSmart timing.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                ruleRow("1", "New words start in box 1 and review immediately.")
                ruleRow("✓", "Each correct answer moves a word up a box — 1, 3, 7, then 14 days between reviews.")
                ruleRow("✕", "Miss a word and it returns to box 1 for a fresh start.")
                ruleRow("⌨", "Stronger words graduate from multiple choice to typed recall.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var pick: some View {
        VStack(spacing: 18) {
            Spacer()
            Eyebrow(text: "First deck")
            Text("Choose a language")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text("Each pack ships ~90 high-frequency words with articles, gender, and example sentences. You can add more decks later.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            VStack(spacing: 10) {
                ForEach(Lexicon.packs) { pack in
                    Button {
                        chosen = chosen == pack.code ? nil : pack.code
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text(pack.flag)
                                .font(.title2)
                                .accessibilityHidden(true)
                            Text(pack.name)
                                .font(.headline)
                                .foregroundStyle(Brand.text)
                            Spacer()
                            Text("\(pack.entries.count) words")
                                .font(Brand.mono(13))
                                .foregroundStyle(Brand.text3)
                            Image(systemName: chosen == pack.code ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(chosen == pack.code ? Brand.live : Brand.text3)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(chosen == pack.code ? Brand.live.opacity(0.6) : Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pack.name), \(pack.entries.count) words")
                    .accessibilityAddTraits(chosen == pack.code ? .isSelected : [])
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func ruleRow(_ badge: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(badge)
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text2)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
