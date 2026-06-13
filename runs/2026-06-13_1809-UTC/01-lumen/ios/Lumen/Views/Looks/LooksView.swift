import SwiftUI
import UIKit

struct LooksView: View {
    @Environment(ProStore.self) private var pro
    @AppStorage("favoritePresets") private var favoritesRaw = ""

    @State private var thumbs: [String: UIImage] = [:]
    @State private var original: UIImage?
    @State private var detail: Preset?
    @State private var showPaywall = false
    @State private var loaded = false

    private var favorites: Set<String> { Set(favoritesRaw.split(separator: ",").map(String.init)) }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var ordered: [Preset] {
        PresetLibrary.all.sorted { (favorites.contains($0.id) ? 0 : 1, $0.name) < (favorites.contains($1.id) ? 0 : 1, $1.name) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    if !loaded {
                        ProgressView().tint(Theme.accent).padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ordered) { preset in
                                Button { tap(preset) } label: { card(preset) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Looks")
            .task { await loadThumbs() }
            .sheet(item: $detail) { p in
                PresetDetailSheet(preset: p, before: original, after: thumbs[p.id],
                                  isFavorite: favorites.contains(p.id),
                                  locked: p.isPro && !pro.isPro,
                                  onToggleFavorite: { toggleFavorite(p) },
                                  onUnlock: { detail = nil; showPaywall = true })
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func card(_ preset: Preset) -> some View {
        let locked = preset.isPro && !pro.isPro
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let img = thumbs[preset.id] {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 130).frame(maxWidth: .infinity).clipped()
                } else {
                    Rectangle().fill(Theme.surfaceAlt).frame(height: 130)
                }
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        .padding(7).background(.black.opacity(0.45), in: Circle()).padding(8)
                } else if favorites.contains(preset.id) {
                    Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(Theme.accent)
                        .padding(7).background(.white.opacity(0.9), in: Circle()).padding(8)
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Text(preset.blurb).font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                }
                Spacer()
            }
            .padding(10)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.name), \(preset.blurb)\(locked ? ", locked" : "")")
    }

    private func tap(_ preset: Preset) { Haptics.tap(); detail = preset }

    private func toggleFavorite(_ preset: Preset) {
        var set = favorites
        if set.contains(preset.id) { set.remove(preset.id) } else { set.insert(preset.id); Haptics.soft() }
        favoritesRaw = set.sorted().joined(separator: ",")
    }

    private func loadThumbs() async {
        guard !loaded else { return }
        let sample = ImageEngine.shared.sampleImage(size: 500)
        let result = await Task.detached(priority: .userInitiated) { () -> ([String: UIImage], UIImage?) in
            var out: [String: UIImage] = [:]
            for p in PresetLibrary.all {
                if let ui = ImageEngine.shared.processed(source: sample, adjustments: p.adjustments) { out[p.id] = ui }
            }
            let orig = ImageEngine.shared.render(sample)
            return (out, orig)
        }.value
        thumbs = result.0
        original = result.1
        loaded = true
    }
}

struct PresetDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preset: Preset
    let before: UIImage?
    let after: UIImage?
    let isFavorite: Bool
    let locked: Bool
    let onToggleFavorite: () -> Void
    let onUnlock: () -> Void

    @State private var showBefore = false
    @State private var localFav: Bool

    init(preset: Preset, before: UIImage?, after: UIImage?, isFavorite: Bool, locked: Bool,
         onToggleFavorite: @escaping () -> Void, onUnlock: @escaping () -> Void) {
        self.preset = preset; self.before = before; self.after = after
        self.isFavorite = isFavorite; self.locked = locked
        self.onToggleFavorite = onToggleFavorite; self.onUnlock = onUnlock
        _localFav = State(initialValue: isFavorite)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Theme.canvas
                            if let img = showBefore ? before : after {
                                Image(uiImage: img).resizable().scaledToFit()
                            }
                            VStack { Spacer(); HStack { Spacer()
                                Text(showBefore ? "Before" : "After")
                                    .font(Theme.rounded(12, .bold)).foregroundStyle(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(.black.opacity(0.5), in: Capsule()).padding(10)
                            } }
                        }
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { _ in showBefore = true }.onEnded { _ in showBefore = false })

                        Text("Hold the image to see the original").font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkFaint)

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What’s inside").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                                let active = Adjustments.Field.allCases.filter { preset.adjustments[$0] != 0 }
                                if active.isEmpty {
                                    Text("The original, untouched.").foregroundStyle(Theme.inkSoft)
                                } else {
                                    ForEach(active) { f in
                                        HStack {
                                            Label(f.label, systemImage: f.icon).font(Theme.rounded(14, .medium)).foregroundStyle(Theme.ink)
                                            Spacer()
                                            Text("\(preset.adjustments[f] > 0 && f.bipolar ? "+" : "")\(Int((preset.adjustments[f] * 100).rounded()))")
                                                .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if locked {
                            Button { onUnlock() } label: {
                                Label("Unlock with Lumen Pro", systemImage: "lock.fill")
                                    .font(Theme.rounded(16, .bold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(preset.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { localFav.toggle(); onToggleFavorite() } label: {
                        Image(systemName: localFav ? "heart.fill" : "heart").foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel(localFav ? "Remove favorite" : "Add favorite")
                }
            }
        }
    }
}
