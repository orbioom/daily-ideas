import SwiftUI
import SwiftData

struct SequencerView: View {
    @Environment(SequencerStore.self) private var store
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var toast: ToastMessage?
    @State private var showSave = false
    @State private var showMixer = false
    @State private var showPaywall = false
    @State private var newPatternName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Thump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toast($toast)
            .sheet(isPresented: $showSave) { savePatternSheet }
            .sheet(isPresented: $showMixer) {
                MixerSheet(stepCount: store.grid.stepCount)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                if !store.audio.audioAvailable {
                    ErrorBanner(text: "Audio unavailable — you can still build beats; sound will resume when audio is back.")
                }

                TransportBar()

                if store.audio.isLoadingKit {
                    kitLoadingRow
                }

                gridPanel

                stepLengthRow
            }
            .padding(16)
        }
    }

    private var kitLoadingRow: some View {
        HStack(spacing: 10) {
            ProgressView().tint(Theme.accent)
            Text("Loading \(store.kit.name)…")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var gridPanel: some View {
        PanelCard(padding: 12) {
            VStack(spacing: 6) {
                stepRuler
                ForEach(DrumVoice.allCases) { voice in
                    TrackRow(
                        voice: voice,
                        stepCount: store.grid.stepCount,
                        currentStep: store.currentStep,
                        isPlaying: store.isPlaying,
                        isPro: isPro
                    )
                }
            }
        }
    }

    private var stepRuler: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: 54)
            ForEach(0..<store.grid.stepCount, id: \.self) { step in
                Text(step % 4 == 0 ? "\(step / 4 + 1)" : "")
                    .font(Theme.mono(10, .bold))
                    .foregroundStyle(store.isPlaying && step == store.currentStep ? Theme.accent : Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, step % 4 == 0 && step != 0 ? 4 : 0)
            }
        }
        .accessibilityHidden(true)
    }

    private var stepLengthRow: some View {
        PanelCard(padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Pattern length")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        if !isPro { ProBadge() }
                    }
                    Text(isPro ? "16 or 32 steps" : "32 steps with Pro")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Picker("Steps", selection: Binding(
                    get: { store.grid.stepCount },
                    set: { newValue in
                        if newValue > Pro.freeStepCount && !isPro {
                            showPaywall = true
                        } else {
                            store.setStepCount(newValue)
                        }
                    }
                )) {
                    Text("16").tag(16)
                    Text("32").tag(32)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                .accessibilityLabel(Text("Pattern length in steps"))
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showMixer = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel(Text("Mixer"))
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                clearPattern()
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel(Text("Clear pattern"))

            Button {
                newPatternName = "Pattern \(Int.random(in: 1...99))"
                showSave = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel(Text("Save pattern"))
        }
    }

    private var savePatternSheet: some View {
        NavigationStack {
            Form {
                Section("Pattern name") {
                    TextField("Name", text: $newPatternName)
                        .font(Theme.rounded(17))
                }
                Section {
                    LabeledContent("Tempo", value: "\(Int(store.bpm)) BPM")
                    LabeledContent("Kit", value: store.kit.name)
                    LabeledContent("Steps", value: "\(store.grid.stepCount)")
                }
            }
            .navigationTitle("Save Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSave = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePattern() }
                        .disabled(newPatternName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func savePattern() {
        let trimmed = newPatternName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if !isPro {
            let descriptor = FetchDescriptor<Pattern>(predicate: #Predicate { $0.isBuiltIn == false })
            let count = (try? context.fetchCount(descriptor)) ?? 0
            if count >= Pro.freeSavedPatternLimit {
                showSave = false
                Haptics.warning(settings.hapticsEnabled)
                toast = ToastMessage(text: "Free limit reached (\(Pro.freeSavedPatternLimit)). Unlock Pro for unlimited.", symbol: "lock.fill", isError: true)
                showPaywall = true
                return
            }
        }

        let pattern = store.makePattern(named: trimmed)
        context.insert(pattern)
        try? context.save()
        showSave = false
        Haptics.success(settings.hapticsEnabled)
        toast = ToastMessage(text: "Saved “\(trimmed)”", symbol: "checkmark.circle.fill")
    }

    private func clearPattern() {
        guard store.grid.activeTrackCount > 0 else {
            toast = ToastMessage(text: "Grid is already empty", symbol: "info.circle.fill")
            return
        }
        store.clearPattern()
        Haptics.medium(settings.hapticsEnabled)
        toast = ToastMessage(text: "Pattern cleared", symbol: "trash.fill")
    }
}
