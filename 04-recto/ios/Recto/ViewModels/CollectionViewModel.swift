import SwiftUI
import SwiftData

@Observable final class CollectionViewModel {
    var newCollectionName: String = ""
    var newCollectionIcon: String = "folder"
    var newCollectionColor: String = "#007AFF"
    var isCreating: Bool = false

    let availableIcons: [String] = [
        "folder", "book.closed", "star", "heart", "bookmark",
        "tag", "pencil", "camera", "music.note", "figure.run",
        "house", "briefcase", "graduationcap", "list.bullet", "checkmark.circle"
    ]

    let availableColors: [String] = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#AF52DE", "#5AC8FA", "#FF2D55", "#5856D6"
    ]

    func createCollection(context: ModelContext, all: [Collection]) {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = all.map(\.sortOrder).max() ?? -1
        let col = Collection(
            name: trimmed,
            icon: newCollectionIcon,
            colorHex: newCollectionColor,
            sortOrder: maxOrder + 1
        )
        context.insert(col)
        try? context.save()
        newCollectionName = ""
        newCollectionIcon = "folder"
        newCollectionColor = "#007AFF"
        isCreating = false
    }

    func deleteCollection(_ col: Collection, entries: [BulletEntry], context: ModelContext) {
        for e in entries where e.collectionId == col.id {
            context.delete(e)
        }
        context.delete(col)
        try? context.save()
    }

    func entryCount(for col: Collection, entries: [BulletEntry]) -> Int {
        entries.filter { $0.collectionId == col.id }.count
    }
}
