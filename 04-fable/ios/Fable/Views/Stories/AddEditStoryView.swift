import SwiftUI
import SwiftData

struct AddEditStoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let story: FableStory?

    @State private var title = ""
    @State private var genre: StoryGenre = .bedtime
    @State private var ageGroup: AgeGroup = .preschool
    @State private var length: StoryLength = .medium
    @State private var content = ""
    @State private var moralLesson = ""
    @State private var settingDescription = ""

    private var isEditing: Bool { story != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Story Info") {
                    TextField("Story Title", text: $title)
                        .accessibilityLabel("Story title")
                    Picker("Genre", selection: $genre) {
                        ForEach(StoryGenre.allCases, id: \.self) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g)
                        }
                    }
                    .accessibilityLabel("Genre")
                    Picker("Age Group", selection: $ageGroup) {
                        ForEach(AgeGroup.allCases, id: \.self) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .accessibilityLabel("Age group")
                    Picker("Length", selection: $length) {
                        ForEach(StoryLength.allCases, id: \.self) { l in
                            Text(l.rawValue).tag(l)
                        }
                    }
                    .accessibilityLabel("Story length")
                }

                Section("Setting & Moral") {
                    TextField("Setting (e.g. A magical forest at night)", text: $settingDescription)
                        .accessibilityLabel("Story setting")
                    TextField("Moral lesson (e.g. Kindness matters)", text: $moralLesson)
                        .accessibilityLabel("Moral lesson")
                }

                Section("Story Text") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Story content")
                    Text("\(content.split(separator: " ").count) words · ~\(max(1, content.split(separator: " ").count / 120)) min")
                        .font(.caption)
                        .foregroundColor(FableTheme.secondaryLabel)
                }
            }
            .navigationTitle(isEditing ? "Edit Story" : "New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let s = story else { return }
        title = s.title
        genre = s.genre
        ageGroup = s.ageGroup
        length = s.length
        content = s.content
        moralLesson = s.moralLesson
        settingDescription = s.settingDescription
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let s = story {
            s.title = trimmed
            s.genre = genre
            s.ageGroup = ageGroup
            s.length = length
            s.content = content
            s.moralLesson = moralLesson
            s.settingDescription = settingDescription
        } else {
            let s = FableStory(title: trimmed, genre: genre, ageGroup: ageGroup)
            s.length = length
            s.content = content
            s.moralLesson = moralLesson
            s.settingDescription = settingDescription
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}
