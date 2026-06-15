import SwiftUI

struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private let perks: [(String, String)] = [
        ("infinity", "Unlimited saved articles"),
        ("paintpalette.fill", "Every reader theme: Light, Sepia, Dark, Night"),
        ("textformat", "All reading fonts and sizes"),
        ("highlighter", "Save and revisit highlights"),
        ("tag.fill", "Unlimited tags to organize your library"),
        ("square.and.arrow.up", "Export articles and highlights")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    perksList
                    purchaseButtons
                    footnote
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stow Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent)
                .padding(22)
                .background(Theme.accentSoft, in: Circle())
                .accessibilityHidden(true)

            Text(reason.headline)
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(reason.detail)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var perksList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(perks, id: \.1) { perk in
                HStack(spacing: 13) {
                    Image(systemName: perk.0)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(perk.1)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
            }
        }
        .cardSurface(padding: 18)
    }

    private var purchaseButtons: some View {
        VStack(spacing: 12) {
            Button {
                unlock()
            } label: {
                VStack(spacing: 2) {
                    Text("Unlock Stow Pro")
                        .font(.headline)
                    Text("\(Pro.priceLabel) · one-time purchase")
                        .font(.caption)
                        .opacity(0.9)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                .foregroundStyle(.white)
            }

            Button("Restore Purchase") {
                // Simulated restore. In production this calls StoreKit 2.
                unlock()
            }
            .font(.subheadline)
            .foregroundStyle(Theme.inkSoft)
        }
    }

    private var footnote: some View {
        Text("No subscription. No account. No ads. One purchase, yours forever.")
            .font(.caption)
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func unlock() {
        settings.haptic { Haptics.success() }
        withAnimation { isPro = true }
        dismiss()
    }
}
