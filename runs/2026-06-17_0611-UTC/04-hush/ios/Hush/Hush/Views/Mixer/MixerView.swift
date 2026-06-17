import SwiftUI
import SwiftData

/// The Mixer: a grid of synthesized-sound tiles to toggle, per-layer volume
/// sliders for active sounds, a master volume, a big play/pause control, and a
/// save-as-mix action. Free users are capped at `AppSettings.freeLayerCap`.
struct MixerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(SoundEngine.self) private var engine
    @Environment(ProStore.self) private var pro
    @Environment(AppSettings.self) private var settings
    @Environment(SleepTimer.self) private var sleepTimer

    @State private var showPaywall = false
    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var capMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    private var layerCap: Int {
        pro.isPro ? Int.max : AppSettings.freeLayerCap
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    transportCard
                    if let capMessage {
                        Text(capMessage)
                            .font(.caption)
                            .foregroundStyle(HushTheme.amber)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }
                    soundGrid
                    if !engine.activeSounds.isEmpty {
                        activeLayersCard
                    }
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Mixer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveName = ""
                        showSaveSheet = true
                    } label: {
                        Label("Save mix", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!engine.hasActiveSound)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSaveSheet) { saveSheet }
        }
    }

    // MARK: - Transport / now-playing

    private var transportCard: some View {
        HushCard {
            VStack(spacing: 16) {
                summary

                Button {
                    handlePlayToggle()
                } label: {
                    Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(engine.hasActiveSound ? HushTheme.teal : HushTheme.secondaryText(scheme))
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(!engine.hasActiveSound)
                .accessibilityLabel(engine.isPlaying ? "Pause" : "Play")
                .accessibilityHint(engine.hasActiveSound ? "" : "Add a sound first.")

                masterRow

                if let err = engine.engineError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(HushTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if sleepTimer.isActive {
                    Label("Sleep timer running — see the Timer tab.", systemImage: "moon.zzz.fill")
                        .font(.caption)
                        .foregroundStyle(HushTheme.amber)
                }
            }
        }
    }

    private var summary: some View {
        let active = engine.activeSounds
        return VStack(spacing: 4) {
            if active.isEmpty {
                Text("Nothing playing")
                    .font(.headline)
                    .foregroundStyle(HushTheme.primaryText(scheme))
                Text("Tap a sound below to begin")
                    .font(.subheadline)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
            } else {
                Text(active.map { $0.type.title }.joined(separator: " · "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HushTheme.primaryText(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(active.count) layer\(active.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var masterRow: some View {
        @Bindable var eng = engine
        return VStack(spacing: 6) {
            HStack {
                Text("Master volume")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HushTheme.secondaryText(scheme))
                Spacer()
                Text(Formatting.percent(engine.masterVolume))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HushTheme.secondaryText(scheme))
            }
            VolumeSlider(label: "Master", value: $eng.masterVolume)
        }
    }

    // MARK: - Sound grid

    private var soundGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HushSectionHeader(title: "Sounds", systemImage: "waveform")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SoundType.allCases) { type in
                    let locked = !type.isFreeTier && !pro.isPro
                    SoundTile(type: type,
                              isEnabled: engine.isEnabled(type),
                              isLocked: locked) {
                        handleTileTap(type, locked: locked)
                    }
                }
            }
        }
    }

    // MARK: - Active layers

    private var activeLayersCard: some View {
        HushCard {
            VStack(alignment: .leading, spacing: 14) {
                HushSectionHeader(title: "Active layers", systemImage: "slider.horizontal.below.rectangle")
                ForEach(engine.activeSounds) { state in
                    layerRow(state)
                    if state.id != engine.activeSounds.last?.id {
                        Divider().overlay(HushTheme.hairline(scheme))
                    }
                }
                Button {
                    engine.clearAll()
                    if engine.isPlaying { engine.stop() }
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Label("Clear all", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(HushTheme.danger)
                .padding(.top, 2)
            }
        }
    }

    private func layerRow(_ state: SoundEngine.SoundState) -> some View {
        let binding = Binding<Double>(
            get: { engine.state(for: state.type)?.volume ?? 0 },
            set: { engine.setVolume(state.type, $0) }
        )
        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: state.type.symbol)
                    .font(.subheadline)
                    .foregroundStyle(state.type.tint)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(state.type.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HushTheme.primaryText(scheme))
                Spacer()
                Button {
                    engine.setEnabled(state.type, false)
                    if !engine.hasActiveSound && engine.isPlaying { engine.stop() }
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(HushTheme.secondaryText(scheme))
                }
                .accessibilityLabel("Remove \(state.type.title)")
            }
            VolumeSlider(label: state.type.title, value: binding, tint: state.type.tint)
        }
    }

    // MARK: - Save sheet

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mix name", text: $saveName)
                } header: {
                    Text("Name")
                } footer: {
                    Text(engine.currentLayers.map { $0.type.title }.joined(separator: ", "))
                }
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Save mix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showSaveSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMix() }
                        .disabled(saveName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    // MARK: - Actions

    private func handleTileTap(_ type: SoundType, locked: Bool) {
        if locked {
            showPaywall = true
            return
        }
        // Enforce the free-tier layer cap on enabling (not on disabling).
        if !engine.isEnabled(type), engine.activeCount >= layerCap {
            Haptics.warning(settings.hapticsEnabled)
            withAnimation {
                capMessage = "Free mixes are limited to \(layerCap) layers. Unlock Pro for unlimited layers."
            }
            showPaywall = true
            return
        }
        withAnimation { capMessage = nil }
        let nowOn = engine.toggle(type)
        Haptics.tap(settings.hapticsEnabled)
        // Auto-start when the first sound is added; stop when the last is removed.
        if nowOn && !engine.isPlaying {
            engine.play()
        } else if !engine.hasActiveSound && engine.isPlaying {
            engine.stop()
        }
    }

    private func handlePlayToggle() {
        engine.togglePlayback()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func saveMix() {
        let trimmed = saveName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let layers = engine.currentLayers
        guard !layers.isEmpty else { showSaveSheet = false; return }

        let mix = SavedMix(name: trimmed)
        let layerModels = layers.map { MixLayer(type: $0.type, volume: $0.volume) }
        mix.layers = layerModels
        layerModels.forEach { $0.mix = mix }
        modelContext.insert(mix)
        try? modelContext.save()

        Haptics.success(settings.hapticsEnabled)
        showSaveSheet = false
    }
}
