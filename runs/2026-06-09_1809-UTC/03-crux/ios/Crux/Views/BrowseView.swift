import SwiftUI
import SwiftData

/// Browse: entry points into the smart lists (Anytime, Someday, Logbook) and a
/// grid of tags. Each opens a filtered task list.
struct BrowseView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var showAddTag = false
    @State private var newTagName = ""

    private var counts: [CruxEngine.SmartList: Int] { CruxEngine.counts(tasks) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 0) {
                    smartRow(.anytime, title: "Anytime", icon: "tray.full", tint: Brand.magic)
                    Divider().background(Brand.hairline)
                    smartRow(.someday, title: "Someday", icon: "moon.stars", tint: Brand.info)
                    Divider().background(Brand.hairline)
                    smartRow(.logbook, title: "Logbook", icon: "checkmark.seal", tint: Brand.live)
                }
                .glassCard(padding: 6)

                tagsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Browse")
        .navigationDestination(for: BrowseRoute.self) { route in
            FilteredListView(route: route)
        }
        .alert("New Tag", isPresented: $showAddTag) {
            TextField("Tag name", text: $newTagName)
            Button("Add", action: commitTag)
            Button("Cancel", role: .cancel) { newTagName = "" }
        }
    }

    @ViewBuilder
    private func smartRow(_ list: CruxEngine.SmartList, title: String, icon: String, tint: Color) -> some View {
        NavigationLink(value: BrowseRoute.smart(list)) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(title).font(.body).foregroundStyle(Brand.text)
                Spacer()
                Text("\(counts[list] ?? 0)")
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text3)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(counts[list] ?? 0) tasks")
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "Tags")
                Spacer()
                Button {
                    newTagName = ""
                    showAddTag = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.magic)
                }
            }
            if tags.isEmpty {
                Text("No tags yet. Add one to label and filter tasks.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 10) {
                    ForEach(tags) { tag in
                        NavigationLink(value: BrowseRoute.tag(tag.persistentModelID)) {
                            HStack(spacing: 6) {
                                Circle().fill(Color(brandHex: tag.colorHex)).frame(width: 8, height: 8)
                                    .accessibilityHidden(true)
                                Text(tag.name).font(.subheadline.weight(.medium))
                                Text("\(tag.activeCount)")
                                    .font(Brand.mono(11))
                                    .foregroundStyle(Brand.text3)
                            }
                            .foregroundStyle(Brand.text)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(tag.name) tag, \(tag.activeCount) active tasks")
                    }
                }
            }
        }
    }

    private func commitTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let index = tags.count
        let tag = Tag(name: trimmed, colorHex: CruxPalette.color(forIndex: index))
        context.insert(tag)
        TaskActions.save(context)
        newTagName = ""
        Haptics.success()
    }
}

/// Navigation routes for Browse and its filtered lists.
enum BrowseRoute: Hashable {
    case smart(CruxEngine.SmartList)
    case tag(PersistentIdentifier)
}
