import SwiftUI

struct PackDetailView: View {
    let pack: Pack
    @Binding var selectedTab: Int

    @Environment(StudioModel.self) private var studio
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var locked: Bool { pack.isProOnly && !isPro }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if locked { lockedBanner }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(pack.presets) { preset in
                        presetTile(preset)
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var lockedBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pro pack", systemImage: "lock.fill")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.accent)
            Text("Unlock Mural Pro to open these presets in the Studio.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Button {
                showPaywall = true
            } label: {
                Text("Unlock Pro · \(Pro.priceLabel)")
                    .font(Theme.rounded(15, .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.heroGradient, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.subtleCardGradient, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    private func presetTile(_ preset: WallpaperSpec) -> some View {
        Button {
            open(preset)
        } label: {
            ZStack {
                WallpaperPreview(spec: preset, aspect: AspectRatioOption.phone.ratio, cornerRadius: Theme.radius)
                if locked {
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.style.displayName) preset\(locked ? ", locked" : "")")
        .accessibilityHint(locked ? "Unlock Pro to use" : "Opens this preset in the Studio")
    }

    private func open(_ preset: WallpaperSpec) {
        if locked {
            Haptics.warning(enabled: settings.hapticsEnabled)
            showPaywall = true
            return
        }
        studio.load(preset)
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        selectedTab = 0
        dismiss()
    }
}
