import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let accent = Brand.dynamic(0xB0653E, 0xE0A878)

    private let pages: [(icon: String, title: String, body: String)] = [
        ("square.grid.2x2", "Beautiful collages, fast",
         "Pick from nine layouts, drop in your photos, and arrange them with a tap. Square, portrait, and story sizes for every feed."),
        ("hand.draw", "Place every photo just right",
         "Drag to reposition and pinch to zoom inside any cell. Adjust spacing, corners, borders, and the background to taste."),
        ("camera.filters", "Filters that feel film, not phony",
         "Eight tasteful filters — mono, noir, sepia, vivid, and warm fades — applied per photo, all processed on your device."),
        ("square.and.arrow.up", "Export clean, no watermark",
         "Save or share in high resolution with no watermark, ever. Your photos never leave your device. No ads, no subscription on the basics."),
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
                    Button(page < pages.count - 1 ? "Continue" : "Start creating") {
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
