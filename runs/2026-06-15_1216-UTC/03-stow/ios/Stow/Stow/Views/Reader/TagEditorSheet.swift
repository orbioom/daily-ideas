import SwiftUI
import SwiftData

/// Attach/detach tags for an article, and create new ones inline.
struct TagEditorSheet: View {
    @Bindable var article: Article

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var newTagName = ""
    @State private var showPaywall = false

    /// Free tier: limit number of distinct tags created overall.
    private let freeTagLimit = 4

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        addRow

                        if allTags.isEmpty {
                            Text("No tags yet. Create one above to start organizing.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                                .padding(.top, 8)
                        } else {
                            FlowTags(tags: allTags, isOn: { isAttached($0) }) { tag in
                                toggle(tag)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .tags)
            }
        }
    }

    private var addRow: some View {
        HStack {
            TextField("New tag name", text: $newTagName)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit(createTag)
                .accessibilityLabel("New tag name")
            Button(action: createTag) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(canCreate ? Theme.accent : Theme.inkFaint)
            }
            .disabled(!canCreate)
            .accessibilityLabel("Create tag")
        }
        .padding(13)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var canCreate: Bool {
        !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isAttached(_ tag: Tag) -> Bool {
        article.tags.contains { $0.id == tag.id }
    }

    private func toggle(_ tag: Tag) {
        settings.haptic { Haptics.selection() }
        if let idx = article.tags.firstIndex(where: { $0.id == tag.id }) {
            article.tags.remove(at: idx)
        } else {
            article.tags.append(tag)
        }
    }

    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        // Reuse an existing tag with the same name (case-insensitive).
        if let existing = allTags.first(where: { $0.name.lowercased() == name.lowercased() }) {
            if !isAttached(existing) { article.tags.append(existing) }
            newTagName = ""
            return
        }
        guard isPro || allTags.count < freeTagLimit else {
            showPaywall = true
            return
        }
        let hex = TagPalette.hexes[allTags.count % TagPalette.hexes.count]
        let tag = Tag(name: name, colorHex: hex)
        context.insert(tag)
        article.tags.append(tag)
        newTagName = ""
        settings.haptic { Haptics.tap() }
    }
}

/// A simple wrapping layout for selectable tag chips.
struct FlowTags: View {
    let tags: [Tag]
    var isOn: (Tag) -> Bool
    var onTap: (Tag) -> Void

    var body: some View {
        FlexibleWrap(data: tags) { tag in
            Button { onTap(tag) } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: TagPalette.color(for: tag.colorHex)))
                        .frame(width: 9, height: 9)
                    Text(tag.name)
                        .font(.subheadline.weight(.medium))
                    if isOn(tag) {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                    }
                }
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(isOn(tag) ? Color(hex: TagPalette.color(for: tag.colorHex)).opacity(0.18) : Theme.surfaceAlt,
                            in: Capsule())
                .overlay(Capsule().strokeBorder(isOn(tag) ? Color(hex: TagPalette.color(for: tag.colorHex)) : Theme.hairline, lineWidth: 1))
                .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(tag.name)\(isOn(tag) ? ", selected" : "")")
        }
    }
}
