import SwiftUI

struct PaywallView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var restoreToast: Toast?

    private let heroSpec: WallpaperSpec = {
        let pal = BuiltInPalettes.palette(withID: "neon-pulse") ?? BuiltInPalettes.defaultPalette
        return WallpaperSpec(style: .aurora, paletteHexes: pal.hexes, paletteName: pal.name, seed: 7, angle: 12, grain: 0.08, vignette: 0.2, complexity: 6)
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    VStack(spacing: 14) {
                        ForEach(Array(Pro.unlocks.enumerated()), id: \.offset) { _, item in
                            unlockRow(icon: item.icon, title: item.title, detail: item.detail)
                        }
                    }
                    .padding(.horizontal, 4)

                    priceBlock
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Mural Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe later") { dismiss() }
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .toast($restoreToast)
        }
    }

    private var hero: some View {
        ZStack {
            WallpaperCanvasView(spec: heroSpec)
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
            VStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("Unlock everything")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        }
        .accessibilityElement()
        .accessibilityLabel("Mural Pro")
    }

    private func unlockRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.subtleCardGradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var priceBlock: some View {
        VStack(spacing: 12) {
            Text("\(Pro.priceLabel) · one-time")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)

            Button {
                unlock()
            } label: {
                Text("Unlock Mural Pro")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.heroGradient, in: Capsule())
                    .foregroundStyle(.white)
            }

            Button("Restore purchase") { restore() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)

            Text("Simulated purchase for this demo. StoreKit-ready.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.top, 4)
    }

    private func unlock() {
        Haptics.success(enabled: settings.hapticsEnabled)
        isPro = true
        dismiss()
    }

    private func restore() {
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        if isPro {
            dismiss()
        } else {
            restoreToast = Toast(kind: .info, message: "No previous purchase found")
        }
    }
}
