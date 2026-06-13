import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("rectangle.split.2x2.fill", "Beautiful templates, instantly",
         "Stories, square posts and collages — pick a layout and drop your photos straight in."),
        ("textformat", "Make it yours",
         "Add captions you can drag anywhere, choose a background gradient and style the text to match your vibe."),
        ("square.and.arrow.up", "Export & share in a tap",
         "Save a crisp, full-size image to your library and share it to any app. No watermark, no subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i).padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 { page += 1 } else { hasOnboarded = true }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start creating")
                        .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28).padding(.bottom, 12)

                Button("Skip") { hasOnboarded = true }
                    .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft).padding(.bottom, 20)
            }
        }
    }

    private func pageView(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon).font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(p.title).font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(p.body).font(Theme.rounded(17, .regular)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            Spacer(); Spacer()
        }
    }
}

#Preview { OnboardingView() }
