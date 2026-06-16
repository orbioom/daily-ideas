import Foundation
import SwiftData

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var name: String
    var roleRaw: String
    var email: String
    var phone: String
    var linkedIn: String
    var notes: String

    var application: Application?

    init(
        id: UUID = UUID(),
        name: String,
        role: ContactRole = .recruiter,
        email: String = "",
        phone: String = "",
        linkedIn: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.roleRaw = role.rawValue
        self.email = email
        self.phone = phone
        self.linkedIn = linkedIn
        self.notes = notes
    }

    var role: ContactRole {
        get { ContactRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }
}
