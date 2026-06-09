import SwiftUI
import SwiftData

struct MixerView: View {
    @Environment(MixerEngine.self) private var engine
    @Environment(\.modelContext) private var context
    @Query(sort: \Mix.sortIndex) private var mixes: [Mix]

    @State private var showSave = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AuraBackground(active: engine.isPlaying)
                ScrollView {
                    VStack(spacing: 16) {
                        transport
                        ForEach(SoundType.allCases) { type in
                            layerCard(type)
                        }
                        if engine.activeCount > 0 {
                            saveButton
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Hush")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSave) { saveSheet }
        }
    }

    // MARK: - Transport

    private var transport: some View {
        HStack(spacing: 16) {
            Button {
                Haptics.tap()
                if engine.isPlaying { engine.pause() } else { engine.play() }
            } label: {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Brand.inkGradient, in: Circle())
                    .shadow(color: Brand.cardShadow, radius: 8, y: 4)
            }
            .disabled(engine.activeCount == 0)
            .accessibilityLabel(engine.isPlaying ? "Pause" : "Play")

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    StatusDot(color: engine.isPlaying ? Brand.live : Brand.text3)
                    Eyebrow(text: engine.isPlaying ? "Playing" : "Paused")
                }
                Text(engine.activeCount == 0 ? "Pick a sound to begin"
                                             : "\(engine.activeCount) layer\(engine.activeCount == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                if engine.isTimerActive {
                    Text("Sleep in \(Format.clock(engine.timerRemaining))")
                        .font(Brand.mono(13))
                        .foregroundStyle(Brand.magic)
                }
            }
            Spacer()
        }
        .glassCard(padding: 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Layer card

    private func layerCard(_ type: SoundType) -> some View {
        let active = engine.isActive(type)
        return VStack(spacing: 10) {
            Button {
                Haptics.selection()
                withAnimation(Brand.ease(0.25)) { engine.toggle(type) }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(active ? Brand.magic.opacity(0.18) : Brand.hairline.opacity(0.5))
                            .frame(width: 44, height: 44)
                        Image(systemName: type.symbol)
                            .foregroundStyle(active ? Brand.magic : Brand.text3)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(type.label)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            if type.isPremium {
                                Text("PRO")
                                    .font(Brand.mono(9, weight: .medium))
                                    .tracking(0.6)
                                    .foregroundStyle(Brand.magic)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Brand.magic.opacity(0.14), in: Capsule())
                            }
                        }
                        Text(active ? "On" : "Off")
                            .font(.caption)
                            .foregroundStyle(active ? Brand.live : Brand.text3)
                    }
                    Spacer()
                    Image(systemName: active ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(active ? Brand.live : Brand.text3)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(type.label), \(active ? "on" : "off")")
            .accessibilityHint(active ? "Turns this layer off" : "Adds this layer")

            if active {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .font(.caption).foregroundStyle(Brand.text3).accessibilityHidden(true)
                    Slider(value: volumeBinding(type), in: 0...1)
                        .tint(Brand.magic)
                        .accessibilityLabel("\(type.label) volume")
                        .accessibilityValue(Format.percent(engine.volume(for: type)))
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption).foregroundStyle(Brand.text3).accessibilityHidden(true)
                }
                .transition(.opacity)
            }
        }
        .glassCard(padding: 14)
    }

    private func volumeBinding(_ type: SoundType) -> Binding<Double> {
        Binding(
            get: { engine.volume(for: type) },
            set: { engine.setVolume(type, $0) }
        )
    }

    // MARK: - Save mix

    private var saveButton: some View {
        Button {
            newName = ""
            showSave = true
            Haptics.tap()
        } label: {
            Label("Save this mix", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(GlassButtonStyle())
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Rainy night", text: $newName)
                }
                Section("Layers") {
                    ForEach(SoundType.allCases.filter { engine.isActive($0) }) { type in
                        HStack {
                            Label(type.label, systemImage: type.symbol)
                            Spacer()
                            Text(Format.percent(engine.volume(for: type)))
                                .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Save mix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSave = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMix() }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveMix() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let nextIndex = (mixes.map(\.sortIndex).max() ?? -1) + 1
        let mix = Mix(name: name, isBuiltIn: false, sortIndex: nextIndex)
        context.insert(mix)
        for type in SoundType.allCases where engine.isActive(type) {
            let layer = MixLayer(sound: type, volume: engine.volume(for: type))
            layer.mix = mix
            mix.layers.append(layer)
            context.insert(layer)
        }
        try? context.save()
        Haptics.success()
        showSave = false
    }
}
