import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle().fill(Theme.accentSoft).frame(width: 88, height: 88)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    Text("Nest")
                        .font(Theme.serif(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A private, no-bank-login planner for your savings goals and sinking funds. Set a target and a date, and Nest paces every goal for you.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            row("Your data stays on this device.")
                            row("No bank connections, no fees on what you save.")
                            row("All money math is precise to the cent.")
                        }
                    }
                    Text("Version 1.0")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(24)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
