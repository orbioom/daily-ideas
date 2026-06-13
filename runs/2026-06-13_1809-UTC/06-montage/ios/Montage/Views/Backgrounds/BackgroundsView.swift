import SwiftUI

struct BackgroundsView: View {
    @Environment(ProStore.self) private var pro
    @AppStorage("favoriteBackgrounds") private var favoritesRaw = ""
    @State private var showPaywall = false

    private var favorites: Set<String> { Set(favoritesRaw.split(separator: ",").map(String.init)) }
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("A palette of solids and gradients. Tap the heart to pin your favorites — they’re first in the editor’s Style picker.")
                            .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, 16).padding(.top, 8)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(BackgroundLibrary.all) { bg in swatch(bg) }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Backgrounds")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func swatch(_ bg: BackgroundStyle) -> some View {
        let locked = bg.isPro && !pro.isPro
        return VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                bg.fill
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        .padding(6).background(.black.opacity(0.4), in: Circle()).padding(6)
                } else {
                    Button { toggle(bg) } label: {
                        Image(systemName: favorites.contains(bg.id) ? "heart.fill" : "heart")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(favorites.contains(bg.id) ? Theme.accent : .white)
                            .padding(6).background(.black.opacity(0.28), in: Circle())
                    }
                    .padding(6)
                    .accessibilityLabel("\(favorites.contains(bg.id) ? "Unpin" : "Pin") \(bg.name)")
                }
            }
            Text(bg.name).font(Theme.rounded(11, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .onTapGesture { if locked { showPaywall = true } }
    }

    private func toggle(_ bg: BackgroundStyle) {
        var set = favorites
        if set.contains(bg.id) { set.remove(bg.id) } else { set.insert(bg.id); Haptics.soft() }
        favoritesRaw = set.sorted().joined(separator: ",")
    }
}
