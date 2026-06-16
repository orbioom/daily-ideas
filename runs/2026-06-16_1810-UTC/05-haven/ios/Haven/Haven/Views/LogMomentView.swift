import SwiftUI
import SwiftData

/// Gentle flow to log (or edit) a hard moment. Works for both new entries and
/// editing an existing PanicEpisode.
struct LogMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @Query(sort: \Trigger.name) private var allTriggers: [Trigger]
    @Query(sort: [SortDescriptor(\CopingItem.sortOrder)]) private var coping: [CopingItem]

    /// nil = creating a new episode.
    let episode: PanicEpisode?

    @State private var startedAt = Date.now
    @State private var intensityBefore = 6.0
    @State private var hasAfter = true
    @State private var intensityAfter = 3.0
    @State private var contextChoice: EpisodeContext = .home
    @State private var note = ""
    @State private var selectedTriggerIDs: Set<UUID> = []
    @State private var selectedHelped: Set<String> = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        intensityCard
                        contextCard
                        triggersCard
                        helpedCard
                        noteCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(episode == nil ? "Log a moment" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() } }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: Cards

    private var intensityCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("When was it?")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                DatePicker("Time", selection: $startedAt, in: ...Date.now)
                    .labelsHidden()
                    .accessibilityLabel("Time it happened")

                Divider()

                sliderRow(title: "How strong before?", value: $intensityBefore)

                Toggle(isOn: $hasAfter) {
                    Text("It eased afterwards")
                        .font(.subheadline)
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                }
                .tint(HavenTheme.accent)

                if hasAfter {
                    sliderRow(title: "How strong after?", value: $intensityAfter)
                }
            }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>) -> some View {
        let intValue = Int(value.wrappedValue.rounded())
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                Spacer()
                Text("\(intValue) · \(IntensityStyle.label(for: intValue))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IntensityStyle.color(for: intValue))
            }
            Slider(value: value, in: 0...10, step: 1)
                .tint(IntensityStyle.color(for: intValue))
                .accessibilityLabel(title)
                .accessibilityValue("\(intValue) out of 10, \(IntensityStyle.label(for: intValue))")
        }
    }

    private var contextCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Where were you?")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                FlowChips(items: EpisodeContext.allCases.map { ($0.rawValue, $0.label) },
                          isSelected: { $0 == contextChoice.rawValue }) { raw in
                    contextChoice = EpisodeContext.from(raw)
                }
            }
        }
    }

    private var triggersCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("What may have set it off?")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                if allTriggers.isEmpty {
                    Text("No triggers available.")
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                } else {
                    FlowChips(items: allTriggers.map { ($0.id.uuidString, $0.name) },
                              isSelected: { selectedTriggerIDs.contains(UUID(uuidString: $0) ?? UUID()) }) { idString in
                        if let id = UUID(uuidString: idString) {
                            toggle(&selectedTriggerIDs, id)
                        }
                    }
                }
            }
        }
    }

    private var helpedCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("What helped, if anything?")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                if coping.isEmpty {
                    Text("Your coping tools will appear here.")
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                } else {
                    FlowChips(items: coping.map { ($0.title, $0.title) },
                              isSelected: { selectedHelped.contains($0) }) { title in
                        toggle(&selectedHelped, title)
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("A note for yourself (optional)")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                TextEditor(text: $note)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(HavenTheme.subtleFill(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerSmall, style: .continuous))
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                    .accessibilityLabel("Note")
            }
        }
    }

    // MARK: Helpers

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ value: T) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let ep = episode else { return }
        startedAt = ep.startedAt
        intensityBefore = Double(ep.intensityBefore)
        if let after = ep.intensityAfter {
            hasAfter = true
            intensityAfter = Double(after)
        } else {
            hasAfter = false
        }
        contextChoice = EpisodeContext.from(ep.context)
        note = ep.note
        selectedTriggerIDs = Set(ep.triggers.map(\.id))
        selectedHelped = Set(ep.helpedBy)
    }

    private func save() {
        let before = Int(intensityBefore.rounded()).clamped(to: 0...10)
        let after = hasAfter ? Int(intensityAfter.rounded()).clamped(to: 0...10) : nil
        let chosenTriggers = allTriggers.filter { selectedTriggerIDs.contains($0.id) }
        let helped = Array(selectedHelped)

        if let ep = episode {
            ep.startedAt = startedAt
            ep.intensityBefore = before
            ep.intensityAfter = after
            ep.context = contextChoice.rawValue
            ep.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            ep.triggers = chosenTriggers
            ep.helpedBy = helped
        } else {
            let new = PanicEpisode(
                startedAt: startedAt,
                intensityBefore: before,
                intensityAfter: after,
                context: contextChoice.rawValue,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                triggers: chosenTriggers,
                helpedBy: helped
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Flowing chips layout

/// A simple wrapping chip layout that avoids relying on iOS 16+ `Layout` quirks
/// by using an adaptive grid. Each item is (id, label).
struct FlowChips: View {
    let items: [(String, String)]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.0) { item in
                SelectableChip(label: item.1, isSelected: isSelected(item.0)) {
                    onTap(item.0)
                }
            }
        }
    }
}
