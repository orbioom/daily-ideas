import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var pulse = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("tuningfork", "Tune anything, fast",
         "A precise chromatic tuner with built-in tunings for guitar, bass, ukulele, violin, and more — accurate to the cent."),
        ("metronome.fill", "Keep perfect time",
         "A clean metronome with tap tempo, subdivisions, accents, and saveable presets — clicks synthesized on device."),
        ("pianokeys", "Hear the right note",
         "A pitch pipe plays any reference tone, and a full note table shows exact frequencies for your A4 setting.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(Brand.warn.opacity(0.16))
                        .frame(width: 184, height: 184)
                        .scaleEffect(pulse && !reduceMotion ? 1.05 : 0.93)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 56, weight: .light)).foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(pages[page].title).font(.title.weight(.bold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].body).font(.body).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
                Button(page == pages.count - 1 ? "Start tuning" : "Continue") {
                    Haptics.tap()
                    if page == pages.count - 1 { hasOnboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 28)
                if page < pages.count - 1 {
                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
