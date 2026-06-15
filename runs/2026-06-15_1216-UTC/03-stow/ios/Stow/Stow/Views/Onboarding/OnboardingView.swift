import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(icon: "tray.and.arrow.down.fill",
              title: "Save anything to read later",
              body: "Paste a link and Stow keeps a clean copy — no clutter, no tracking, no account."),
        Slide(icon: "wifi.slash",
              title: "Read it offline, anywhere",
              body: "Every article is extracted on your device and stored for good. The subway, a flight, the woods — it's all readable."),
        Slide(icon: "highlighter",
              title: "Keep the lines that matter",
              body: "Highlight passages, tag your library, and resume right where you left off.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.top, 8)

                controls
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: slide.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.accent)
                .padding(34)
                .background(Theme.accentSoft, in: Circle())
                .accessibilityHidden(true)

            Text(slide.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(slide.body)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 330)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slide.title). \(slide.body)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<slides.count, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 9 : 7, height: i == page ? 9 : 7)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                advance()
            } label: {
                Text(page == slides.count - 1 ? "Start reading" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                    .foregroundStyle(.white)
            }

            if page < slides.count - 1 {
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Color.clear.frame(height: 20)
            }
        }
    }

    private func advance() {
        settings.haptic { Haptics.tap() }
        if page < slides.count - 1 {
            if reduceMotion {
                page += 1
            } else {
                withAnimation(.easeInOut) { page += 1 }
            }
        } else {
            finish()
        }
    }

    private func finish() {
        settings.haptic { Haptics.success() }
        hasOnboarded = true
    }
}
