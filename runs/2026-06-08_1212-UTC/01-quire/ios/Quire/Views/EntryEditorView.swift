import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Bindable var entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var newTagName = ""
    @State private var showDeleteConfirm = false
    @FocusState private var bodyFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    if !entry.promptText.isEmpty {
                        Section {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.accentColor)
                                Text(entry.promptText)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                    }

                    Section {
                        TextField("Title (optional)", text: $entry.title)
                            .font(.headline)
                        TextEditor(text: $entry.body)
                            .frame(minHeight: 200)
                            .focused($bodyFocused)
                            .overlay(alignment: .topLeading) {
                                if entry.body.isEmpty {
                                    Text("Write freely…")
                                        .foregroundStyle(Brand.text3)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                        Text("\(entry.wordCount) words")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                    }

                    Section("When") {
                        DatePicker("Date", selection: $entry.date)
                    }

                    Section("How was it?") {
                        moodPicker
                    }

                    Section("Tags") {
                        tagSection
                    }

                    Section {
                        Toggle(isOn: $entry.favorite) {
                            Label("Favorite", systemImage: "heart")
                        }
                        .tint(Color(hex: 0x9E5E7E))
                        Toggle(isOn: $entry.pinned) {
                            Label("Pin to top", systemImage: "pin")
                        }
                        .tint(Color(hex: 0x6E7BA6))
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete entry", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { finish() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { bodyFocused = false }
                    }
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(entry)
                    Haptics.warning()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var moodPicker: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases) { m in
                Button {
                    Haptics.selection()
                    entry.mood = (entry.mood == m.rawValue) ? 0 : m.rawValue
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: m.symbol)
                            .font(.title3)
                        Text(m.label)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entry.mood == m.rawValue
                                  ? Color(hex: m.colorHex).opacity(0.22)
                                  : Color.clear)
                    )
                    .foregroundStyle(entry.mood == m.rawValue
                                     ? Color(hex: m.colorHex)
                                     : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(m.label)
                .accessibilityAddTraits(entry.mood == m.rawValue ? .isSelected : [])
            }
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !allTags.isEmpty {
                FlowChips(tags: allTags, selected: Set(entry.tags.map { $0.id })) { tag in
                    toggle(tag)
                }
            }
            HStack {
                TextField("New tag", text: $newTagName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add") { addTag() }
                    .disabled(trimmedNewTag.isEmpty)
            }
        }
    }

    private var trimmedNewTag: String {
        newTagName.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private func addTag() {
        let name = trimmedNewTag
        guard !name.isEmpty else { return }
        if let existing = allTags.first(where: { $0.name.lowercased() == name }) {
            if !entry.tags.contains(where: { $0.id == existing.id }) {
                entry.tags.append(existing)
            }
        } else {
            let palette: [UInt32] = [0x6E7BA6, 0x7CA68F, 0xB0814E, 0x9E5E7E, 0x3E9E78, 0x6E92A6]
            let color = palette[allTags.count % palette.count]
            let tag = Tag(name: name, colorHex: color)
            context.insert(tag)
            entry.tags.append(tag)
        }
        newTagName = ""
        Haptics.tap()
    }

    private func toggle(_ tag: Tag) {
        if let idx = entry.tags.firstIndex(where: { $0.id == tag.id }) {
            entry.tags.remove(at: idx)
        } else {
            entry.tags.append(tag)
        }
        Haptics.selection()
    }

    private func finish() {
        // Discard an entry the user never wrote anything into.
        if entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            context.delete(entry)
        } else {
            entry.modifiedAt = .now
            try? context.save()
            Haptics.success()
        }
        dismiss()
    }
}

/// A wrapping row of selectable tag chips.
struct FlowChips: View {
    let tags: [Tag]
    let selected: Set<UUID>
    let onTap: (Tag) -> Void

    var body: some View {
        FlexibleWrap(spacing: 8, lineSpacing: 8) {
            ForEach(tags) { tag in
                let isOn = selected.contains(tag.id)
                Button {
                    onTap(tag)
                } label: {
                    Text(tag.name)
                        .font(Brand.mono(12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(isOn
                                ? Color(hex: tag.colorHex).opacity(0.22)
                                : Color.gray.opacity(0.12))
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                isOn ? Color(hex: tag.colorHex) : Color.clear,
                                lineWidth: 1)
                        )
                        .foregroundStyle(isOn ? Color(hex: tag.colorHex) : Brand.text2)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}
