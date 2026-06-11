import SwiftUI
import SwiftData

struct BoardEditView: View {
    let board: VisionBoard?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BoardCategory = .personal
    @State private var affirmation = ""

    var isNew: Bool { board == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Board Details") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Board title")
                    Picker("Category", selection: $category) {
                        ForEach(BoardCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .accessibilityLabel("Board category")
                }
                Section {
                    TextField("Daily affirmation or intention…", text: $affirmation, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Affirmation for this board")
                } header: {
                    Text("Affirmation")
                } footer: {
                    Text("This appears at the top of your board as a daily reminder.")
                }
            }
            .navigationTitle(isNew ? "New Board" : "Edit Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let b = board {
                    title = b.title
                    category = b.category
                    affirmation = b.affirmation
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let b = board {
            b.title = trimmed
            b.categoryRaw = category.rawValue
            b.affirmation = affirmation
        } else {
            let b = VisionBoard(title: trimmed, category: category, affirmation: affirmation)
            modelContext.insert(b)
        }
        dismiss()
    }
}
