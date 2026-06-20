import SwiftUI
import SwiftData

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let defaultAuthor: String

    @State private var title = ""
    @State private var author = ""
    @State private var genre = "Drama"
    @State private var logline = ""
    @State private var colorTag = "#F4A261"

    var body: some View {
        NavigationStack {
            Form {
                Section("Script") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    Picker("Genre", selection: $genre) {
                        ForEach(ScriptTheme.genres, id: \.self) { Text($0) }
                    }
                }
                Section("Logline (optional)") {
                    TextField("One sentence summary…", text: $logline, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                Section("Color Label") {
                    ColorTagPicker(selected: $colorTag)
                }
            }
            .navigationTitle("New Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { author = defaultAuthor }
        }
    }

    private func create() {
        let project = ScriptProject(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author,
            genre: genre,
            logline: logline
        )
        project.colorTag = colorTag
        modelContext.insert(project)
        dismiss()
    }
}
