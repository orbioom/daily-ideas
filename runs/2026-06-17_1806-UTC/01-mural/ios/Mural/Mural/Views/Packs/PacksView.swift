import SwiftUI

struct PacksView: View {
    @Binding var selectedTab: Int
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(BuiltInPacks.all) { pack in
                        let locked = pack.isProOnly && !isPro
                        NavigationLink(value: pack) {
                            PackCard(pack: pack, locked: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Packs")
            .navigationDestination(for: Pack.self) { pack in
                PackDetailView(pack: pack, selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

private struct PackCard: View {
    let pack: Pack
    let locked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(Theme.rounded(19, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(pack.tagline)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked { ProLockBadge() }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(pack.presets) { preset in
                        WallpaperCanvasView(spec: preset)
                            .aspectRatio(AspectRatioOption.phone.ratio, contentMode: .fit)
                            .frame(height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                                    .strokeBorder(Theme.hairline, lineWidth: 1)
                            )
                            .overlay {
                                if locked {
                                    RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(Image(systemName: "lock.fill").foregroundStyle(.white))
                                }
                            }
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pack.name) pack, \(pack.tagline)\(locked ? ", Pro only" : "")")
        .accessibilityHint("Opens the pack")
    }
}
