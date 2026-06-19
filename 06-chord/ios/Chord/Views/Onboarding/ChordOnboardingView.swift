import SwiftUI

struct ChordOnboardingView: View {
    @AppStorage(ChordSettings.onboardingDone) private var onboardingDone = false
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("music.note.list", "Sketch Chord Progressions",
         "Capture song ideas the moment they strike. Build progressions with the chords you know, in any key."),
        ("sparkles", "Find Your Sound",
         "Browse classic progressions that power thousands of hits. Tap to load any template instantly."),
        ("chart.bar.fill", "Track Your Creativity",
         "See how many songs you've sketched, which genres you love, and your weekly writing activity."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ChordTheme.deepTeal, Color(red: 0.02, green: 0.18, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 24) {
                            Image(systemName: pages[i].0)
                                .font(.system(size: 72))
                                .foregroundStyle(ChordTheme.teal)
                                .accessibilityHidden(true)
                            Text(pages[i].1)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(pages[i].2)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.82))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? ChordTheme.teal : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                Spacer()

                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { onboardingDone = true }
                } label: {
                    Text(page == pages.count - 1 ? "Start Writing" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ChordTheme.teal, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
