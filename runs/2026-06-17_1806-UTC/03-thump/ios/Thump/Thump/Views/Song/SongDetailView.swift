import SwiftUI
import SwiftData

struct SongDetailView: View {
    @Bindable var song: Song

    @Environment(SequencerStore.self) private var store
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Pattern.createdAt, order: .reverse) private var patterns: [Pattern]

    @State private var player: SongPlayer?
    @State private var showAdd = false
    @State private var toast: ToastMessage?

    private var sections: [SongSection] { song.orderedSections }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if sections.isEmpty {
                    EmptyStateView(
                        symbol: "rectangle.stack.badge.plus",
                        title: "Empty song",
                        message: "Add sections from your saved patterns to build an arrangement.",
                        actionTitle: "Add Section"
                    ) { showAdd = true }
                } else {
                    sectionList
                    transport
                }
            }
        }
        .navigationTitle(song.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel(Text("Add section"))
            }
        }
        .toast($toast)
        .sheet(isPresented: $showAdd) {
            AddSectionSheet(patterns: patterns) { pattern, repeats in
                addSection(pattern: pattern, repeats: repeats)
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if player == nil { player = SongPlayer(store: store) }
        }
        .onDisappear { player?.stop() }
    }

    private var sectionList: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.element.persistentModelID) { index, section in
                sectionRow(section, index: index)
                    .listRowBackground(player?.activeSectionID == index ? Theme.accent.opacity(0.16) : Theme.surface)
            }
            .onMove(perform: move)
            .onDelete(perform: deleteAt)
        }
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private func sectionRow(_ section: SongSection, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(Theme.mono(14, .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(player?.activeSectionID == index ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.inkSoft)))
            VStack(alignment: .leading, spacing: 2) {
                Text(section.patternName)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text("×\(section.repeatCount) bars")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Stepper(value: Binding(
                get: { section.repeatCount },
                set: { section.repeatCount = max(1, min(16, $0)); try? context.save() }
            ), in: 1...16) {
                Text("×\(section.repeatCount)")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .labelsHidden()
            .fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Section \(index + 1), \(section.patternName), repeats \(section.repeatCount) times"))
    }

    private var transport: some View {
        VStack(spacing: 0) {
            if let player, player.isPlaying, sections.indices.contains(player.currentSectionIndex) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(Theme.accent)
                    Text("Playing: \(sections[player.currentSectionIndex].patternName) (\(player.currentRepeat + 1)/\(sections[player.currentSectionIndex].repeatCount))")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: 12) {
                PrimaryButton(
                    title: (player?.isPlaying ?? false) ? "Stop" : "Play Song",
                    symbol: (player?.isPlaying ?? false) ? "stop.fill" : "play.fill",
                    fill: !(player?.isPlaying ?? false)
                ) { togglePlay() }
            }
            .padding(16)
        }
        .background(Theme.surface)
    }

    // MARK: - Actions

    private func togglePlay() {
        guard let player else { return }
        Haptics.medium(settings.hapticsEnabled)
        if player.isPlaying {
            player.stop()
        } else {
            let steps = buildSteps()
            guard !steps.isEmpty else {
                toast = ToastMessage(text: "Add sections first", symbol: "info.circle.fill")
                return
            }
            player.play(steps: steps)
        }
    }

    private func buildSteps() -> [SongPlayer.Step] {
        sections.compactMap { section in
            guard let pattern = patterns.first(where: { $0.persistentModelID == section.patternID }) else { return nil }
            return SongPlayer.Step(
                patternName: pattern.name,
                grid: pattern.grid,
                bpm: pattern.bpm,
                swing: pattern.swing,
                kitID: pattern.kitID,
                repeats: section.repeatCount
            )
        }
    }

    private func addSection(pattern: Pattern, repeats: Int) {
        let order = (sections.map { $0.order }.max() ?? -1) + 1
        let section = SongSection(order: order, patternID: pattern.persistentModelID, patternName: pattern.name, repeatCount: repeats)
        section.song = song
        song.sections.append(section)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        toast = ToastMessage(text: "Added “\(pattern.name)”", symbol: "checkmark.circle.fill")
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = sections
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, section) in ordered.enumerated() { section.order = i }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func deleteAt(_ offsets: IndexSet) {
        let ordered = sections
        for index in offsets where ordered.indices.contains(index) {
            let section = ordered[index]
            context.delete(section)
        }
        // Re-pack order.
        for (i, section) in song.orderedSections.enumerated() { section.order = i }
        try? context.save()
        Haptics.medium(settings.hapticsEnabled)
    }
}

/// Sheet to pick a pattern + repeat count for a new section.
private struct AddSectionSheet: View {
    let patterns: [Pattern]
    let onAdd: (Pattern, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var repeats = 4

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if patterns.isEmpty {
                    EmptyStateView(
                        symbol: "rectangle.stack",
                        title: "No patterns",
                        message: "Save a pattern on the Beats tab first, then add it to your song.",
                        actionTitle: nil, action: nil
                    )
                } else {
                    List {
                        Section {
                            Stepper(value: $repeats, in: 1...16) {
                                Text("Repeat ×\(repeats)")
                                    .font(Theme.rounded(15, .semibold))
                            }
                            .listRowBackground(Theme.surface)
                        } header: { Text("Bars per section") }

                        Section("Choose a pattern") {
                            ForEach(patterns) { pattern in
                                Button {
                                    onAdd(pattern, repeats)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(pattern.name)
                                            .font(Theme.rounded(16, .semibold))
                                            .foregroundStyle(Theme.ink)
                                        Spacer()
                                        Text("\(Int(pattern.bpm)) BPM")
                                            .font(Theme.mono(12))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                                .listRowBackground(Theme.surface)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
