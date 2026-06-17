import SwiftUI
import SwiftData

/// The Mixes library: built-in presets plus the user's saved mixes. Tap to load
/// & play; swipe / menu to rename, delete, duplicate, or favorite.
struct MixesView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(SoundEngine.self) private var engine
    @Environment(ProStore.self) private var pro
    @Environment(AppSettings.self) private var settings

    @Query(sort: \SavedMix.createdAt, order: .reverse) private var savedMixes: [SavedMix]

    @State private var showPaywall = false
    @State private var renameTarget: SavedMix?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    presetsSection
                    savedSection
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Mixes")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $renameTarget) { mix in renameSheet(mix) }
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HushSectionHeader(title: "Preset mixes", systemImage: "sparkles")
            LazyVStack(spacing: 10) {
                ForEach(PresetLibrary.all) { preset in
                    let locked = !preset.isFreeTier && !pro.isPro
                    PresetRow(preset: preset, locked: locked) {
                        loadPreset(preset, locked: locked)
                    } onDuplicate: {
                        duplicatePreset(preset, locked: locked)
                    }
                }
            }
        }
    }

    // MARK: - Saved

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HushSectionHeader(title: "Your mixes", systemImage: "heart.fill")
            if savedMixes.isEmpty {
                HushCard {
                    EmptyStateView(
                        icon: "square.stack.3d.up.slash",
                        title: "No saved mixes yet",
                        message: "Build a blend on the Mixer tab, then tap Save to keep it here."
                    )
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(savedMixes) { mix in
                        SavedMixRow(mix: mix,
                                    canLoad: MixLoader.canLoad(mix.resolvedLayers, isPro: pro.isPro),
                                    onLoad: { loadSaved(mix) },
                                    onFavorite: { toggleFavorite(mix) },
                                    onRename: { startRename(mix) },
                                    onDuplicate: { duplicateSaved(mix) },
                                    onDelete: { delete(mix) })
                    }
                }
            }
        }
    }

    // MARK: - Rename sheet

    private func renameSheet(_ mix: SavedMix) -> some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Mix name", text: $renameText)
                }
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { renameTarget = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { mix.name = trimmed; try? modelContext.save() }
                        renameTarget = nil
                    }
                    .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Actions

    private func loadPreset(_ preset: PresetMix, locked: Bool) {
        if locked { showPaywall = true; return }
        engine.apply(layers: preset.layers)
        engine.play()
        Haptics.success(settings.hapticsEnabled)
    }

    private func duplicatePreset(_ preset: PresetMix, locked: Bool) {
        if locked { showPaywall = true; return }
        if !pro.isPro && savedMixes.count >= ProStore.freeSavedMixLimit {
            showPaywall = true
            return
        }
        let mix = SavedMix(name: preset.name)
        let layers = preset.layers.map { MixLayer(type: $0.type, volume: $0.volume) }
        mix.layers = layers
        layers.forEach { $0.mix = mix }
        modelContext.insert(mix)
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func loadSaved(_ mix: SavedMix) {
        let layers = mix.resolvedLayers
        guard MixLoader.canLoad(layers, isPro: pro.isPro) else {
            showPaywall = true
            return
        }
        engine.apply(layers: layers)
        engine.play()
        Haptics.success(settings.hapticsEnabled)
    }

    private func toggleFavorite(_ mix: SavedMix) {
        mix.isFavorite.toggle()
        try? modelContext.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func startRename(_ mix: SavedMix) {
        renameText = mix.name
        renameTarget = mix
    }

    private func duplicateSaved(_ mix: SavedMix) {
        if !pro.isPro && savedMixes.count >= ProStore.freeSavedMixLimit {
            showPaywall = true
            return
        }
        let copy = SavedMix(name: mix.name + " copy", isFavorite: false)
        let layers = mix.resolvedLayers.map { MixLayer(type: $0.type, volume: $0.volume) }
        copy.layers = layers
        layers.forEach { $0.mix = copy }
        modelContext.insert(copy)
        try? modelContext.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func delete(_ mix: SavedMix) {
        modelContext.delete(mix)
        try? modelContext.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}

// MARK: - Preset row

private struct PresetRow: View {
    @Environment(\.colorScheme) private var scheme
    let preset: PresetMix
    let locked: Bool
    let onLoad: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HushCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HushTheme.teal.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: preset.symbol)
                        .font(.title3)
                        .foregroundStyle(HushTheme.teal)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(preset.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HushTheme.primaryText(scheme))
                        if locked { ProBadge() }
                    }
                    Text(preset.subtitle)
                        .font(.caption)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                        .lineLimit(1)
                }
                Spacer()
                Menu {
                    Button { onLoad() } label: { Label("Load & play", systemImage: "play.fill") }
                    Button { onDuplicate() } label: { Label("Save a copy", systemImage: "plus.square.on.square") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                }
                .accessibilityLabel("More actions")
            }
            .contentShape(Rectangle())
            .onTapGesture { onLoad() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.name). \(preset.subtitle).\(locked ? " Pro." : "")")
        .accessibilityHint("Loads and plays this mix.")
    }
}

// MARK: - Saved mix row

private struct SavedMixRow: View {
    @Environment(\.colorScheme) private var scheme
    let mix: SavedMix
    let canLoad: Bool
    let onLoad: () -> Void
    let onFavorite: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    private var layerSummary: String {
        let names = mix.resolvedLayers.map { $0.type.title }
        return names.isEmpty ? "Empty mix" : names.joined(separator: " · ")
    }

    var body: some View {
        HushCard(padding: 14) {
            HStack(spacing: 14) {
                Button(action: onFavorite) {
                    Image(systemName: mix.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(mix.isFavorite ? HushTheme.danger : HushTheme.secondaryText(scheme))
                }
                .accessibilityLabel(mix.isFavorite ? "Unfavorite" : "Favorite")
                VStack(alignment: .leading, spacing: 2) {
                    Text(mix.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HushTheme.primaryText(scheme))
                    Text(layerSummary)
                        .font(.caption)
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                        .lineLimit(1)
                    if !canLoad {
                        Text("Contains Pro sounds — unlock to play")
                            .font(.caption2)
                            .foregroundStyle(HushTheme.amber)
                    }
                }
                Spacer()
                Menu {
                    Button { onLoad() } label: { Label("Load & play", systemImage: "play.fill") }
                    Button { onRename() } label: { Label("Rename", systemImage: "pencil") }
                    Button { onDuplicate() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                }
                .accessibilityLabel("More actions")
            }
            .contentShape(Rectangle())
            .onTapGesture { onLoad() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mix.name). \(layerSummary).\(mix.isFavorite ? " Favorite." : "")")
        .accessibilityHint("Loads and plays this mix.")
    }
}
