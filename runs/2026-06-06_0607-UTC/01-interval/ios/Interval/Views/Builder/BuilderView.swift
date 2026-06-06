import SwiftUI
import SwiftData

/// Create or edit a routine. Works on value-type `SegmentDraft`s so reordering and
/// grouping are instant and Cancel discards cleanly; commits to SwiftData on Save.
struct BuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings

    /// The routine being edited. If it has no segments and an empty name, it's a new draft
    /// that is only inserted into the store when saved.
    let routine: Routine

    @State private var name: String = ""
    @State private var note: String = ""
    @State private var glyph: String = "figure.run"
    @State private var drafts: [SegmentDraft] = []
    @State private var editMode: EditMode = .inactive
    @State private var editingSegment: SegmentDraft?
    @State private var showGlyphPicker = false
    @State private var didLoad = false

    private let glyphChoices = [
        "figure.run", "bolt.fill", "flame.fill", "timer", "stopwatch.fill",
        "figure.cooldown", "figure.core.training", "dumbbell.fill", "heart.fill",
        "figure.strengthtraining.traditional", "wind", "drop.fill"
    ]

    private var isNew: Bool { routine.segments.isEmpty && routine.name.isEmpty }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    detailsSection
                    segmentsSection
                    summarySection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(item: $editingSegment) { draft in
                SegmentEditView(draft: draft) { updated in
                    apply(updated)
                }
            }
            .sheet(isPresented: $showGlyphPicker) {
                glyphPicker
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            HStack(spacing: 12) {
                Button { showGlyphPicker = true } label: {
                    ZStack {
                        Circle().fill(Brand.glassStroke.opacity(0.3)).frame(width: 44, height: 44)
                        Image(systemName: glyph)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Brand.text)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose glyph")
                TextField("Routine name", text: $name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
            }
            TextField("Note (optional)", text: $note, axis: .vertical)
                .lineLimit(1...3)
                .foregroundStyle(Brand.text2)
        } header: {
            Text("Details")
        } footer: {
            if trimmedName.isEmpty {
                Text("A name is required to save.")
                    .foregroundStyle(Brand.rest)
            }
        }
    }

    private var segmentsSection: some View {
        Section {
            if drafts.isEmpty {
                Text("No segments yet. Add prepare, work, rest, and cooldown steps below.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                ForEach(drafts) { draft in
                    Button { editingSegment = draft } label: {
                        BuilderSegmentRow(draft: draft,
                                          isGroupStart: isGroupStart(draft),
                                          isGrouped: draft.isInRepeatGroup)
                    }
                    .buttonStyle(.plain)
                }
                .onMove(perform: move)
                .onDelete(perform: deleteAt)
            }

            Menu {
                ForEach(SegmentKind.allCases) { kind in
                    Button {
                        addSegment(kind)
                    } label: {
                        Label(kind.title, systemImage: kind.symbol)
                    }
                }
            } label: {
                Label("Add segment", systemImage: "plus.circle.fill")
                    .foregroundStyle(Brand.text)
            }
        } header: {
            HStack {
                Text("Segments")
                Spacer()
                if !drafts.isEmpty {
                    Button(editMode == .active ? "Done" : "Reorder") {
                        withAnimation(Brand.ease(0.3)) {
                            editMode = (editMode == .active) ? .inactive : .active
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
                }
            }
        } footer: {
            Text("Tap a segment to edit it. Group consecutive segments to repeat them — set the repeat count inside the first segment of the group.")
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            HStack {
                Label("Total time", systemImage: "clock")
                Spacer()
                Text(DurationFormat.compact(drafts.totalDuration()))
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            HStack {
                Label("Work time", systemImage: "bolt.fill")
                Spacer()
                Text(DurationFormat.compact(drafts.workDuration()))
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.live)
            }
            HStack {
                Label("Expanded steps", systemImage: "square.stack.3d.up")
                Spacer()
                Text("\(drafts.flattenedStepCount())")
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            groupingControls
        }
    }

    @ViewBuilder
    private var groupingControls: some View {
        if drafts.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat groups")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                Text("Select adjacent segments to repeat as a unit.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                HStack(spacing: 10) {
                    Button {
                        groupAll()
                    } label: {
                        Label("Group all work + rest", systemImage: "repeat")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(Brand.text)
                    if drafts.contains(where: { $0.isInRepeatGroup }) {
                        Button(role: .destructive) {
                            ungroupAll()
                        } label: {
                            Label("Ungroup", systemImage: "rectangle.split.3x1")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var glyphPicker: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(glyphChoices, id: \.self) { choice in
                            Button {
                                glyph = choice
                                showGlyphPicker = false
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(choice == glyph ? AnyShapeStyle(Brand.inkGradient)
                                                              : AnyShapeStyle(Brand.glassStroke.opacity(0.25)))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: choice)
                                        .font(.system(size: 22))
                                        .foregroundStyle(choice == glyph ? .white : Brand.text)
                                }
                            }
                            .accessibilityLabel(choice)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Glyph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showGlyphPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Load / mutate

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        name = routine.name
        note = routine.note
        glyph = routine.glyph.isEmpty ? "figure.run" : routine.glyph
        drafts = routine.orderedSegments.map(SegmentDraft.init(from:))
    }

    private func addSegment(_ kind: SegmentKind) {
        withAnimation(Brand.ease(0.3)) {
            drafts.append(SegmentDraft(kind: kind, duration: kind.defaultDuration))
        }
        Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
    }

    private func move(from source: IndexSet, to destination: Int) {
        drafts.move(fromOffsets: source, toOffset: destination)
        // Moving can break group contiguity; normalise grouping afterwards.
        normaliseGroups()
    }

    private func deleteAt(_ offsets: IndexSet) {
        withAnimation(Brand.ease(0.3)) {
            drafts.remove(atOffsets: offsets)
        }
        normaliseGroups()
    }

    private func apply(_ updated: SegmentDraft) {
        guard let idx = drafts.firstIndex(where: { $0.id == updated.id }) else { return }
        var copy = updated
        // Propagate the repeat count to every member of the same group so the group
        // shares one count.
        if let group = copy.repeatGroupID {
            for i in drafts.indices where drafts[i].repeatGroupID == group {
                drafts[i].repeatCount = copy.repeatCount
            }
        }
        copy.repeatCount = SegmentDraft.clampCount(copy.repeatCount)
        copy.duration = SegmentDraft.clampDuration(copy.duration)
        drafts[idx] = copy
    }

    private func isGroupStart(_ draft: SegmentDraft) -> Bool {
        guard let group = draft.repeatGroupID,
              let idx = drafts.firstIndex(where: { $0.id == draft.id }) else { return false }
        if idx == 0 { return true }
        return drafts[idx - 1].repeatGroupID != group
    }

    /// Wrap every work/rest segment between the first and last such segment into one group.
    private func groupAll() {
        let indices = drafts.indices.filter { drafts[$0].kind == .work || drafts[$0].kind == .rest }
        guard let first = indices.first, let last = indices.last, first < last else { return }
        let group = UUID()
        let count = drafts[first].repeatCount > 1 ? drafts[first].repeatCount : 8
        for i in first...last {
            drafts[i].repeatGroupID = group
            drafts[i].repeatCount = SegmentDraft.clampCount(count)
        }
        Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
    }

    private func ungroupAll() {
        for i in drafts.indices {
            drafts[i].repeatGroupID = nil
            drafts[i].repeatCount = 1
        }
        Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
    }

    /// After a reorder/delete, ensure each group is still a contiguous run; split any
    /// group that became non-contiguous and re-id contiguous runs consistently.
    private func normaliseGroups() {
        guard !drafts.isEmpty else { return }
        var i = 0
        while i < drafts.count {
            guard let group = drafts[i].repeatGroupID else { i += 1; continue }
            // Walk the contiguous run sharing this group id.
            var j = i
            while j < drafts.count, drafts[j].repeatGroupID == group { j += 1 }
            let runLength = j - i
            if runLength == 1 {
                // A lone group member is meaningless — make it standalone.
                drafts[i].repeatGroupID = nil
                drafts[i].repeatCount = 1
            } else {
                // Re-stamp a fresh id for this contiguous run so a later identical id
                // elsewhere cannot merge with it; share one repeat count.
                let fresh = UUID()
                let count = SegmentDraft.clampCount(drafts[i].repeatCount)
                for k in i..<j {
                    drafts[k].repeatGroupID = fresh
                    drafts[k].repeatCount = count
                }
            }
            i = j
        }
    }

    // MARK: - Save

    private func save() {
        guard canSave else { return }
        normaliseGroups()

        routine.name = trimmedName
        routine.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.glyph = glyph

        // Replace the routine's segments with the current drafts. Iterate a copy so
        // deletion doesn't mutate the array we're walking.
        let existingSegments = routine.segments
        routine.segments = []
        for existing in existingSegments {
            context.delete(existing)
        }

        var newSegments: [Segment] = []
        for (index, draft) in drafts.enumerated() {
            let segment = Segment(id: draft.id,
                                  order: index,
                                  kind: draft.kind,
                                  duration: SegmentDraft.clampDuration(draft.duration),
                                  label: draft.label.trimmingCharacters(in: .whitespacesAndNewlines),
                                  repeatGroupID: draft.repeatGroupID,
                                  repeatCount: SegmentDraft.clampCount(draft.repeatCount))
            segment.routine = routine
            newSegments.append(segment)
        }
        routine.segments = newSegments

        if isNew {
            context.insert(routine)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// A row in the builder list, showing grouping with a leading rail.
struct BuilderSegmentRow: View {
    var draft: SegmentDraft
    var isGroupStart: Bool
    var isGrouped: Bool

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(isGrouped ? Brand.magic.opacity(0.7) : Color.clear)
                .frame(width: 3)
                .accessibilityHidden(true)
            Image(systemName: draft.kind.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(draft.kind.tint)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(draft.displayLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    if isGroupStart {
                        Text("repeat ×\(draft.repeatCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Brand.magic)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Brand.magic.opacity(0.14), in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Text(draft.kind.title)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    if isGrouped && !isGroupStart {
                        Text("· in group")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.magic)
                    }
                }
            }
            Spacer(minLength: 0)
            Text(DurationFormat.clock(draft.duration))
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(draft.displayLabel), \(draft.kind.title)")
        .accessibilityValue(DurationFormat.compact(draft.duration) +
                            (isGrouped ? ", in repeat group of \(draft.repeatCount)" : ""))
        .accessibilityHint("Opens segment editor")
    }
}

#Preview {
    if let routine = SampleData.makeRoutines().first {
        BuilderView(routine: routine).intervalPreview()
    }
}
