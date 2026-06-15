import Foundation

/// Pure, testable filtering and sorting for the Library. Kept off the view so
/// the logic stays simple and predictable.
enum LibraryEngine {
    /// Filter notebooks by search text (title) and optional folder.
    static func filter(
        _ notebooks: [Notebook],
        search: String,
        folder: Folder?
    ) -> [Notebook] {
        var result = notebooks
        if let folder {
            result = result.filter { $0.folder?.id == folder.id }
        }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.title.lowercased().contains(query) }
        }
        return result
    }

    /// Sort notebooks by the chosen criterion.
    static func sort(_ notebooks: [Notebook], by sort: NotebookSort) -> [Notebook] {
        switch sort {
        case .recent:
            return notebooks.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return notebooks.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .pageCount:
            return notebooks.sorted { $0.pageCount > $1.pageCount }
        }
    }

    /// Combined filter + sort.
    static func process(
        _ notebooks: [Notebook],
        search: String,
        folder: Folder?,
        sort: NotebookSort
    ) -> [Notebook] {
        let filtered = filter(notebooks, search: search, folder: folder)
        return self.sort(filtered, by: sort)
    }
}
