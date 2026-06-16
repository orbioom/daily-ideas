import SwiftUI

/// Shown when a free user opens a Pro-only pack.
struct PackLockedView: View {
    let pack: WordPack
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(pack.color.opacity(0.16))
                        .frame(width: 120, height: 120)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(pack.color)
                }
                .padding(.top, 24)
                .accessibilityHidden(true)

                Text("\(pack.name) is a Pro pack")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("Unlock Seek Pro once to play all 12 themed packs, with unlimited puzzles in every pack.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                PrimaryButton(title: "See Seek Pro", systemImage: "crown.fill") {
                    showPaywall = true
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
