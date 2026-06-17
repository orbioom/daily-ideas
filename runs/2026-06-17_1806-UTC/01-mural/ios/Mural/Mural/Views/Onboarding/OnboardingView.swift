import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let demoSpec: WallpaperSpec
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardingPage] = {
        func spec(_ style: WallpaperStyle, _ id: String, _ seed: UInt64, angle: Double = 45) -> WallpaperSpec {
            let pal = BuiltInPalettes.palette(withID: id) ?? BuiltInPalettes.defaultPalette
            return WallpaperSpec(style: style, paletteHexes: pal.hexes, paletteName: pal.name, seed: seed, angle: angle, grain: 0.1, vignette: 0.2, complexity: 7)
        }
        return [
            OnboardingPage(
                icon: "wand.and.stars",
                title: "Design beautiful wallpapers",
                body: "Pick a style, choose a palette, and shape gradients, low-poly art, auroras and more in a live studio.",
                demoSpec: spec(.aurora, "neon-pulse", 1, angle: 10)
            ),
            OnboardingPage(
                icon: "square.stack.fill",
                title: "Save your favorites",
                body: "Build a personal library of designs — every wallpaper is reproducible, editable, and fully yours.",
                demoSpec: spec(.lowPoly, "sun-ember", 2)
            ),
            OnboardingPage(
                icon: "photo.on.rectangle.angled",
                title: "Set it as your wallpaper",
                body: "Export to Photos in high resolution, then set it as your background. No watermarks, no accounts, all on-device.",
                demoSpec: spec(.meshGradient, "ocean-deep", 3)
            )
        ]
    }()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: index)

                pageIndicator

                controls
            }
            .padding(.bottom, 24)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            WallpaperPreview(spec: page.demoSpec, aspect: 9.0 / 16.0, cornerRadius: Theme.radiusLarge)
                .frame(maxHeight: 360)
                .shadow(color: Theme.accent.opacity(0.3), radius: 30, y: 14)
                .padding(.horizontal, 56)

            VStack(spacing: 12) {
                Image(systemName: page.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(page.title)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            Spacer(minLength: 8)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.accent : Theme.hairline)
                    .frame(width: i == index ? 22 : 8, height: 8)
            }
        }
        .padding(.vertical, 16)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.impact(.medium, enabled: settings.hapticsEnabled)
                if index < pages.count - 1 {
                    withAnimation(reduceMotion ? .none : .easeInOut) { index += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(index < pages.count - 1 ? "Continue" : "Start designing")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.heroGradient, in: Capsule())
                    .foregroundStyle(.white)
            }
            .accessibilityHint(index < pages.count - 1 ? "Goes to the next intro page" : "Finishes the intro")

            Button("Skip") { finish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
                .opacity(index < pages.count - 1 ? 1 : 0)
                .disabled(index >= pages.count - 1)
        }
        .padding(.horizontal, 28)
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
