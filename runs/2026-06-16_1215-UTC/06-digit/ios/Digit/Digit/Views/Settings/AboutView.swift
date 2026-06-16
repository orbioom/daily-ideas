import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 96, height: 96)
                        Text("🧮").font(.system(size: 48))
                    }
                    .accessibilityHidden(true)
                    .padding(.top, 12)

                    Text("Digit")
                        .font(Theme.rounded(30, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Kids math-facts trainer")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            aboutRow("heart.fill", "Built for families",
                                     "Calm, fair and ad-free. Pay once, own it forever.")
                            Divider()
                            aboutRow("brain.head.profile", "Adaptive practice",
                                     "Digit focuses on the facts each child needs most.")
                            Divider()
                            aboutRow("lock.shield.fill", "Private by design",
                                     "All progress stays on this device.")
                        }
                    }
                    .padding(.horizontal, 20)

                    Text("Made with care for curious kids.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
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

    private func aboutRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(Theme.rounded(20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
