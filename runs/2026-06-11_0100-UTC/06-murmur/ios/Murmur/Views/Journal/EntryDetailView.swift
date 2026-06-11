import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: VoiceEntry
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var showTagSheet = false
    @State private var newTag = ""
    @State private var isPlaying = false
    @State private var vm = RecorderViewModel()

    @Query private var allTags: [JournalTag]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    moodSection
                    transcriptSection
                    tagsSection
                    playbackSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) { deleteEntry() } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(isPresented: $showTagSheet) { tagSheet }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isEditingTitle {
                TextField("Title", text: $editedTitle)
                    .font(.title2.bold())
                    .onSubmit {
                        entry.title = editedTitle
                        isEditingTitle = false
                    }
            } else {
                HStack {
                    Text(entry.displayTitle)
                        .font(.title2.bold())
                    Spacer()
                    Button { editedTitle = entry.title; isEditingTitle = true } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(MurmurTheme.accent)
                    }
                }
            }
            HStack(spacing: 8) {
                Text(formattedDate(entry.date))
                    .font(MurmurTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(entry.formattedDuration)
                    .font(MurmurTheme.captionFont)
                    .foregroundStyle(.secondary)
                if entry.wordCount > 0 {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("\(entry.wordCount) words")
                        .font(MurmurTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    entry.isFavorite.toggle()
                } label: {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(entry.isFavorite ? .red : .secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    Button {
                        entry.mood = mood
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)
                            Text(mood.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(entry.mood == mood ? MurmurTheme.moodColor(mood) : .secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(entry.mood == mood ? MurmurTheme.moodColor(mood).opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(entry.mood == mood ? MurmurTheme.moodColor(mood) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transcript")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            if entry.transcript.isEmpty {
                Text("No transcript available.")
                    .font(MurmurTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(entry.transcript)
                    .font(MurmurTheme.bodyFont)
                    .lineSpacing(6)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tags")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button { showTagSheet = true } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(MurmurTheme.accent)
                }
            }
            if entry.tags.isEmpty {
                Text("No tags")
                    .font(MurmurTheme.captionFont)
                    .foregroundStyle(.tertiary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(entry.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(MurmurTheme.captionFont)
                .foregroundStyle(MurmurTheme.accent)
            Button {
                entry.tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(MurmurTheme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var playbackSection: some View {
        HStack(spacing: 16) {
            Button {
                if isPlaying {
                    vm.stopPlayback()
                    isPlaying = false
                } else {
                    vm.playEntry(entry.audioFilename)
                    isPlaying = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    Text(isPlaying ? "Stop" : "Play Recording")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(MurmurTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(MurmurTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!AudioStore.exists(entry.audioFilename))
        }
    }

    private var tagSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("Add tag…", text: $newTag)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Add") {
                        let t = newTag.trimmingCharacters(in: .whitespaces).lowercased()
                        if !t.isEmpty && !entry.tags.contains(t) {
                            entry.tags.append(t)
                            upsertTag(t)
                        }
                        newTag = ""
                    }
                    .foregroundStyle(MurmurTheme.accent)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()

                Divider()

                List(allTags.sorted { $0.usageCount > $1.usageCount }, id: \.name) { tag in
                    Button {
                        if !entry.tags.contains(tag.name) { entry.tags.append(tag.name) }
                    } label: {
                        HStack {
                            Text("#\(tag.name)")
                            Spacer()
                            if entry.tags.contains(tag.name) {
                                Image(systemName: "checkmark").foregroundStyle(MurmurTheme.accent)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTagSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func upsertTag(_ name: String) {
        if let existing = allTags.first(where: { $0.name == name }) {
            existing.usageCount += 1
        } else {
            modelContext.insert(JournalTag(name: name))
        }
    }

    private func deleteEntry() {
        AudioStore.delete(entry.audioFilename)
        modelContext.delete(entry)
        dismiss()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (idx, frame) in result.frames.enumerated() {
            subviews[idx].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private struct LayoutResult { var size: CGSize; var frames: [CGRect] }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? 300
        var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        var frames: [CGRect] = []
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: s))
            rowHeight = max(rowHeight, s.height)
            x += s.width + spacing
        }
        return LayoutResult(size: CGSize(width: maxWidth, height: y + rowHeight), frames: frames)
    }
}
