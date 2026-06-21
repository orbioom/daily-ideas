import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PushTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }

    // MARK: Page 1 — Logo + tagline

    private var page1: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(PushTheme.box)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                Text("P")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("Push")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(PushTheme.wall)

                Text("Think it through.")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundColor(PushTheme.wall.opacity(0.6))
            }

            Spacer()
            Spacer()
        }
        .padding(40)
    }

    // MARK: Page 2 — How to play

    private var page2: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Push boxes")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.wall)
                Text("to their targets.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.accent)
            }
            .multilineTextAlignment(.center)

            // Mini diagram
            HStack(spacing: 6) {
                miniCell(color: PushTheme.player, icon: "person.fill")
                Image(systemName: "arrow.right")
                    .foregroundColor(PushTheme.wall.opacity(0.4))
                miniCell(color: PushTheme.box, icon: nil)
                Image(systemName: "arrow.right")
                    .foregroundColor(PushTheme.wall.opacity(0.4))
                miniCell(color: PushTheme.boxOnTarget, icon: "checkmark")
            }

            VStack(spacing: 16) {
                featureRow(icon: "arrow.up.arrow.down", text: "Swipe or use the D-pad to move")
                featureRow(icon: "arrow.uturn.backward", text: "Undo any move — unlimited")
                featureRow(icon: "star.fill", text: "Earn stars by beating par moves")
            }

            Spacer()
            Spacer()
        }
        .padding(40)
    }

    // MARK: Page 3 — Start

    private var page3: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("50 puzzles.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.wall)
                Text("Level 1 starts easy.")
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .foregroundColor(PushTheme.wall.opacity(0.6))
                Text("Can you reach Expert?")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundColor(PushTheme.accent)
            }
            .multilineTextAlignment(.center)

            Button {
                onComplete()
            } label: {
                HStack(spacing: 10) {
                    Text("Start Playing")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(PushTheme.accent)
                        .shadow(color: PushTheme.accent.opacity(0.4), radius: 12, y: 6)
                )
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .padding(40)
    }

    // MARK: Helpers

    private func miniCell(color: Color, icon: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 52, height: 52)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PushTheme.accent)
                .frame(width: 28)
            Text(text)
                .font(.system(.callout, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.75))
            Spacer()
        }
    }
}

#Preview {
    OnboardingView { }
}
