import SwiftUI
import SwiftData

/// Articles filed under a tag, with rename / recolor / delete management.
struct TagArticlesView: View {
    @Bindable var tag: Tag

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var showManage = false
    @State private var draftName = ""
    @State private var draftColor = ""
    @State private var showDeleteConfirm = false

    private var articles: [Article] {
        tag.articles.sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Group {
                if articles.isEmpty {
                    EmptyStateView(
                        icon: "tag",
                        title: "No articles with this tag",
                        message: "Add this tag to articles from the reader to see them gathered here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(articles) { article in
                                NavigationLink {
                                    ReaderView(article: article)
                                } label: {
                                    ArticleCard(article: article)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle(tag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    draftName = tag.name
                    draftColor = tag.colorHex
                    showManage = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Manage tag")
            }
        }
        .sheet(isPresented: $showManage) { manageSheet }
        .alert("Delete tag?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteTag() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the tag from all articles. The articles themselves are kept.")
        }
    }

    private var manageSheet: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.inkSoft)
                            TextField("Tag name", text: $draftName)
                                .textInputAutocapitalization(.words)
                                .padding(13)
                                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
                                .accessibilityLabel("Tag name")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Color").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.inkSoft)
                            FlexibleWrap(data: TagPalette.hexes.map { ColorOption(hex: $0) }) { option in
                                Button {
                                    settings.haptic { Haptics.selection() }
                                    draftColor = option.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: TagPalette.color(for: option.hex)))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle().strokeBorder(Theme.ink.opacity(draftColor == option.hex ? 0.9 : 0), lineWidth: 2.5)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .opacity(draftColor == option.hex ? 1 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Color option")
                                .accessibilityAddTraits(draftColor == option.hex ? .isSelected : [])
                            }
                        }

                        Button(role: .destructive) {
                            showManage = false
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete tag", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Theme.bad.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                                .foregroundStyle(Theme.bad)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Manage Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showManage = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
                        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        tag.name = name
        tag.colorHex = draftColor.isEmpty ? tag.colorHex : draftColor
        try? context.save()
        settings.haptic { Haptics.success() }
        showManage = false
    }

    private func deleteTag() {
        settings.haptic { Haptics.warning() }
        context.delete(tag)
        try? context.save()
        dismiss()
    }
}

private struct ColorOption: Identifiable {
    let hex: String
    var id: String { hex }
}
