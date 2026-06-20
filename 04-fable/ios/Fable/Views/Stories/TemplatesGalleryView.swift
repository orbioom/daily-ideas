import SwiftUI
import SwiftData

struct TemplatesGalleryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGenre: StoryGenre?

    var filtered: [StoryTemplate] {
        guard let g = selectedGenre else { return StoryTemplate.templates }
        return StoryTemplate.templates.filter { $0.genre == g }
    }

    var body: some View {
        NavigationStack {
            List {
                genreFilterRow

                ForEach(filtered) { template in
                    Button(action: { useTemplate(template) }) {
                        TemplateRowView(template: template)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Story Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var genreFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", nil)
                let usedGenres = Set(StoryTemplate.templates.map { $0.genre })
                ForEach(StoryGenre.allCases.filter { usedGenres.contains($0) }, id: \.self) { g in
                    chipButton(g.rawValue, g)
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    private func chipButton(_ label: String, _ genre: StoryGenre?) -> some View {
        let selected = selectedGenre == genre
        return Button(action: { selectedGenre = selected ? nil : genre }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(selected ? FableTheme.accent : FableTheme.secondary))
                .foregroundColor(selected ? .white : FableTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }

    private func useTemplate(_ template: StoryTemplate) {
        let story = FableStory(title: template.title, genre: template.genre, ageGroup: template.ageGroup)
        story.moralLesson = template.moralLesson
        story.settingDescription = template.settingDescription
        story.content = template.pages.joined(separator: "\n\n")
        context.insert(story)

        for (idx, page) in template.pages.enumerated() {
            let p = StoryPage(pageNumber: idx + 1, text: page, story: story)
            context.insert(p)
        }
        for charDef in template.characters {
            let c = StoryCharacter(name: charDef.name, role: charDef.role, story: story)
            c.emoji = charDef.emoji
            context.insert(c)
        }
        try? context.save()
        dismiss()
    }
}

struct TemplateRowView: View {
    let template: StoryTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(template.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FableTheme.label)
                Spacer()
                Label(template.genre.rawValue, systemImage: template.genre.icon)
                    .font(.caption)
                    .foregroundColor(FableTheme.genreColor(template.genre))
            }
            Text(template.moralLesson)
                .font(.caption)
                .foregroundColor(FableTheme.secondaryLabel)
            HStack(spacing: 4) {
                ForEach(template.characters, id: \.name) { c in
                    Text(c.emoji).font(.caption)
                }
                Text("·").foregroundColor(FableTheme.secondaryLabel)
                Text("\(template.pages.count) pages")
                    .font(.caption2)
                    .foregroundColor(FableTheme.secondaryLabel)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.title), \(template.genre.rawValue)")
    }
}
