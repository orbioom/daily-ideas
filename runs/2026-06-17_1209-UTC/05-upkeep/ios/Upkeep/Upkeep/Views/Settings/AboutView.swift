import SwiftUI

/// Simple About screen.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 16)
                    .accessibilityHidden(true)
                Text("Upkeep")
                    .font(Theme.serif(28, .bold))
                    .foregroundStyle(Theme.ink)
                Text("A calm, private home-maintenance scheduler. Stay ahead of the recurring upkeep that keeps a home healthy — seasonal jobs, safety checks, and the slow-burn tasks that cost thousands when skipped.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    bullet("lock.shield", "Your home data stays on this device. No account, no cloud.")
                    bullet("calendar.badge.clock", "Smart due, overdue, and seasonal scheduling.")
                    bullet("heart.text.square", "A single home-health score and cost log.")
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                .padding(.horizontal, 20)

                Text("Version 1.0")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 20)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
