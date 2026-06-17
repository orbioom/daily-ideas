import SwiftUI

/// About screen — what Ascend is and how progression works.
struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text("Ascend")
                                .font(Theme.num(28, .heavy))
                                .foregroundStyle(Theme.ink)
                            Text("A guided barbell-strength program that tells you what to lift, logs your sets, and auto-progresses your weights — offline, no account.")
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    infoCard(title: "How progression works",
                             symbol: "arrow.up.forward.circle.fill",
                             body: "Hit all your target reps and Ascend adds the lift's increment next session. Miss three sessions in a row and it deloads you 10% (rounded to the nearest 2.5 kg) so you can build back up.")

                    infoCard(title: "Estimated 1RM",
                             symbol: "chart.xyaxis.line",
                             body: "Ascend estimates your one-rep-max from each working set using the Epley and Brzycki formulas, then tracks it over time.")

                    infoCard(title: "Privacy",
                             symbol: "lock.shield.fill",
                             body: "Everything stays on your device. No sign-in, no servers, no tracking.")

                    Text("Version 1.0")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoCard(title: String, symbol: String, body: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
