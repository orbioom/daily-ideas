import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("selectedDogID") private var selectedDogID = ""
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var name = ""
    @State private var breed = ""
    @State private var emoji = "🐶"
    @State private var knowBirthday = false
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    @State private var error: String?

    private static let emojiChoices = ["🐶", "🐕", "🦮", "🐩", "🐕‍🦺", "🌭"]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    intro.tag(0)
                    method.tag(1)
                    addDog.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Continue" : "Start training") {
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
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else {
            error = "What's your dog's name?"
            page = 2
            return
        }
        let dog = Dog(name: n, breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                      birthDate: knowBirthday ? birthDate : nil, emoji: emoji)
        context.insert(dog)
        selectedDogID = dog.uuid.uuidString
        Haptics.success()
        hasOnboarded = true
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🦴")
                .font(.system(size: 64))
                .accessibilityHidden(true)
            Eyebrow(text: "Biscuit")
            Text("A trainer\nin your pocket.")
                .font(.system(size: 34, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            Text("A real positive-reinforcement curriculum, a built-in clicker, and short daily sessions that actually fit your life.")
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
            Image(systemName: "hand.thumbsup")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Eyebrow(text: "Kind and effective")
            Text("Reward what\nyou want.")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 12) {
                row("checkmark.seal", "24 skills across four levels, each broken into concrete steps.")
                row("hand.tap", "A crisp synthesized clicker for precise marker timing — no extra gadget.")
                row("clock", "Sessions stay short by design: 3–5 minutes, always ending on a win.")
                row("lock", "No subscription, no nagging streak guilt, everything on your device.")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var addDog: some View {
        VStack(spacing: 16) {
            Spacer()
            Eyebrow(text: "Your dog")
            Text("Who are we\ntraining?")
                .font(.system(size: 28, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(Self.emojiChoices, id: \.self) { choice in
                        Button {
                            emoji = choice
                            Haptics.selection()
                        } label: {
                            Text(choice)
                                .font(.title2)
                                .padding(8)
                                .background(emoji == choice ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear),
                                            in: Circle())
                                .overlay(Circle().strokeBorder(emoji == choice ? Brand.live : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Avatar \(choice)")
                        .accessibilityAddTraits(emoji == choice ? .isSelected : [])
                    }
                }
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Breed (optional)", text: $breed)
                    .textFieldStyle(.roundedBorder)
                Toggle("I know their birthday", isOn: $knowBirthday)
                    .tint(Brand.live)
                if knowBirthday {
                    DatePicker("Birthday", selection: $birthDate,
                               in: ...Date.now, displayedComponents: .date)
                }
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(Brand.danger)
                }
            }
            .glassCard()
            .padding(.horizontal, 24)
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
