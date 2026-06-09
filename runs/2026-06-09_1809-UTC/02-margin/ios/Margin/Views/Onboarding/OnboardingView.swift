import SwiftUI

/// First-run onboarding. Lets the reader set a yearly goal before entering the
/// app and flips the `margin.onboarded` gate. Calm, three-beat introduction.
struct OnboardingView: View {
    @AppStorage("margin.onboarded") private var onboarded = false
    @AppStorage("margin.goal") private var goal = 24
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let features: [(String, String, String)] = [
        ("books.vertical.fill", "A shelf you'll love", "Track everything you're reading, want to read, and have finished — with progress, ratings, and tags."),
        ("target", "A yearly challenge", "Set a goal and Margin keeps you honest with pace, projections, and a ring you'll want to fill."),
        ("chart.xyaxis.line", "Insights that read you", "Pages over time, genres, ratings, and streaks — your reading life, charted.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Brand.magic)
                        .accessibilityHidden(true)
                    Eyebrow(text: "Margin")
                    Text("Read more, on purpose.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text("A reading tracker with a yearly challenge built in.")
                        .font(.body)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {
                    ForEach(Array(features.enumerated()), id: \.offset) { _, f in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: f.0)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Brand.magic)
                                .frame(width: 34)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(f.1).font(.headline).foregroundStyle(Brand.text)
                                Text(f.2).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                        .accessibilityElement(children: .combine)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Your \(Calendar.current.component(.year, from: .now)) goal")
                    HStack {
                        Text("\(goal)")
                            .font(Brand.mono(30, weight: .bold))
                            .foregroundStyle(Brand.text)
                            .accessibilityHidden(true)
                        Text("books")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        Stepper("", value: $goal, in: 1...365)
                            .labelsHidden()
                            .accessibilityLabel("Yearly goal")
                            .accessibilityValue("\(goal) books")
                    }
                }
                .glassCard()

                Button {
                    Haptics.success()
                    withAnimation(reduceMotion ? nil : Brand.ease()) { onboarded = true }
                } label: {
                    Text("Start reading")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.bottom, 32)
            }
            .padding(20)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 12)
        }
        .background(Brand.pageBackground)
        .onAppear {
            withAnimation(reduceMotion ? nil : Brand.ease(0.7)) { appear = true }
        }
    }
}
