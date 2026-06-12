import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("partnerAName") private var partnerAName = ""
    @AppStorage("partnerBName") private var partnerBName = ""
    @AppStorage("genderFilter") private var genderFilterRaw = "all"
    @AppStorage("deckSeed") private var deckSeed = 0

    @State private var step = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MonikerTheme.roseDeep, MonikerTheme.rose.opacity(0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if step == 0 {
                welcome
            } else {
                setup
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Moniker")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Find the name you *both* love.\n\nSwipe names like a dating app, pass the phone, and only mutual loves become matches. Every name comes with its origin and meaning.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 32)
            Spacer()
            Button {
                Haptics.tap()
                withAnimation { step = 1 }
            } label: {
                Text("Set Up in 20 Seconds")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(MonikerTheme.roseDeep)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private var setup: some View {
        VStack(spacing: 16) {
            Text("Who's Choosing?")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 40)

            VStack(spacing: 12) {
                TextField("First partner (e.g. Maya)", text: $partnerAName)
                    .textFieldStyle(.roundedBorder)
                TextField("Second partner (e.g. Sam)", text: $partnerBName)
                    .textFieldStyle(.roundedBorder)

                Picker("Looking for", selection: $genderFilterRaw) {
                    Text("All names").tag("all")
                    ForEach(NameGender.allCases) { g in
                        Text("\(g.displayName) names").tag(g.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)

            Text("You can change everything later in Settings.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Button {
                Haptics.tap()
                if partnerAName.trimmingCharacters(in: .whitespaces).isEmpty { partnerAName = "Partner A" }
                if partnerBName.trimmingCharacters(in: .whitespaces).isEmpty { partnerBName = "Partner B" }
                if deckSeed == 0 { deckSeed = Int.random(in: 1...Int.max) }
                hasOnboarded = true
            } label: {
                Text("Start Swiping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(MonikerTheme.roseDeep)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
}
