import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let accent = Brand.dynamic(0x5E7F9E, 0x8FAEE8)

    private let pages: [(icon: String, title: String, body: String)] = [
        ("tuningfork", "A tuner that's fast and honest",
         "Play a note and Pitch shows it instantly with a steady needle. Audio is analyzed on-device and never recorded."),
        ("guitars", "Every tuning, free",
         "Guitar, bass, ukulele, violin and more — standard, drop, and open tunings included. Build your own, all without a paywall."),
        ("metronome", "Metronome and reference tones",
         "A click-accurate metronome with tap tempo and saved presets, plus pure reference tones for any string or note."),
        ("lock", "No ads, no clutter",
         "No bombardment of upsells, no locked basics. Just the tools you need, on this device."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            ZStack {
                                Circle().fill(accent.opacity(0.16)).frame(width: 120, height: 120)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 44, weight: .light)).foregroundStyle(accent)
                            }
                            .accessibilityHidden(true)
                            Text(pages[i].title).font(.title.bold())
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text)
                            Text(pages[i].body).font(.body)
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text2)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 32).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Start tuning") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                        } else { Haptics.success(); onDone() }
                    }
                    .buttonStyle(InkButtonStyle())
                    if page < pages.count - 1 {
                        Button("Skip") { onDone() }.font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }
}

#Preview { OnboardingView(onDone: {}) }
