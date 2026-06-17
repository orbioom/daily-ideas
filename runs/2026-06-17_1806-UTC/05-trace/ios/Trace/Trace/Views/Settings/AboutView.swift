import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            WarmBackground()
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 96, height: 96)
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)
                    .padding(.top, 12)

                    Text("Trace")
                        .font(Theme.rounded(30, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Calm, ad-free letter & number tracing for little learners.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 14) {
                        aboutRow("hand.raised.fill", "Private by design", "No accounts, no ads, no tracking. Everything stays on your device.")
                        aboutRow("apple.logo", "Finger or Apple Pencil", "Trace naturally with whatever your child has in hand.")
                        aboutRow("heart.fill", "Made for grown-ups too", "A simple gate keeps settings and purchases out of little hands.")
                    }
                    .padding(18)
                    .card()

                    Text("Trace Pro is a one-time purchase. No subscriptions, ever.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
