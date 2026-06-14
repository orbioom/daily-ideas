import SwiftUI

/// Short About sheet.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "music.note")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 16)
                        .accessibilityHidden(true)

                    Text("Clef")
                        .font(Theme.serif(30, .bold))
                        .foregroundStyle(Theme.ink)

                    Text("A calm, ad-free sight-reading trainer. See a note, name it, and watch your reading get faster — one drill at a time.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        bullet("eye", "No microphone — answer by tapping a note name or piano key.")
                        bullet("brain.head.profile", "Mastery-weighted drilling focuses on the notes you miss.")
                        bullet("lock.shield", "All your data stays on this device.")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))

                    Text("Version 1.0")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
