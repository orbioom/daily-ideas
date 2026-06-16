import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 100, height: 100)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                    .padding(.top, 12)

                    Text("Recall")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Spaced-repetition flashcards that respect your time.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        aboutRow("brain", "Real SM-2 scheduling",
                                 "Recall's engine is a guarded SuperMemo-2 variant — the same family of algorithm that powers Anki. Cards you know return later; cards you miss return sooner.")
                        aboutRow("lock.shield", "Private by design",
                                 "Everything lives on your device with SwiftData. No account, no cloud, no tracking.")
                        aboutRow("heart", "Fair pricing",
                                 "Free covers three decks and flip study. A single one-time Pro unlock opens everything — no subscription.")
                    }
                    .padding(18)
                    .cardSurface()

                    Text("Made by Orbioom Studio")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func aboutRow(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    AboutView()
}
