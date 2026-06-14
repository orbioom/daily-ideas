import Foundation
import SwiftData

/// A user-defined grouping for accounts (e.g. "Work", "Personal", "Crypto").
@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortIndex: Int
    var createdAt: Date

    /// Accounts filed under this folder. Deleting a folder nulls the inverse
    /// (`Account.folder`) rather than deleting the accounts — see ModelContainer
    /// default behaviour; we reassign explicitly in the UI to be safe.
    @Relationship(inverse: \Account.folder)
    var accounts: [Account]

    init(name: String, sortIndex: Int = 0, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.accounts = []
    }
}
