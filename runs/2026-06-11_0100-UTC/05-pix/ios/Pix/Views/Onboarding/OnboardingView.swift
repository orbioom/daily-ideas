import SwiftUI

struct OnboardingView: View {
    @AppStorage("pix.onboardingDone") private var done = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 72))
                .foregroundStyle(PixTheme.accent)
                .accessibilityHidden(true)
                .padding(.bottom, 16)

            Text("Pix")
                .font(.system(size: 44, weight: .black, design: .monospaced))
                .padding(.bottom, 8)
            Text("Pixel art logic puzzles")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 20) {
                row(icon: "number", title: "Read the clues",
                    body: "Numbers on rows and columns tell you how many consecutive filled cells there are in each line.")
                row(icon: "hand.tap", title: "Fill or exclude",
                    body: "Tap to fill a cell. Long-press to mark it empty (X). Tap again to clear.")
                row(icon: "checkmark.seal", title: "Solve the picture",
                    body: "Work out all rows and columns using logic — no guessing needed. The solution is unique.")
                row(icon: "calendar", title: "New puzzle daily",
                    body: "A new Pix puzzle every day. Build your streak by solving them all.")
            }
            .padding(.horizontal, 28)

            Spacer()

            Button("Start Playing") {
                done = true
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(PixTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func row(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PixTheme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
                Text(body).font(.system(size: 13)).foregroundStyle(.secondary)
            }
        }
    }
}
