import Foundation
import SwiftData

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case unknown = "Unknown"
}

@Model
final class Person {
    var id: UUID
    var firstName: String
    var lastName: String
    var gender: Gender
    var birthDate: Date?
    var birthPlace: String
    var deathDate: Date?
    var deathPlace: String
    var bio: String
    var notes: String
    var photoFilename: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Relationship.person1)
    var relationshipsAsFirst: [Relationship]

    @Relationship(deleteRule: .cascade, inverse: \Relationship.person2)
    var relationshipsAsSecond: [Relationship]

    @Relationship(deleteRule: .cascade, inverse: \LifeEvent.person)
    var lifeEvents: [LifeEvent]

    init(firstName: String, lastName: String, gender: Gender = .unknown) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.birthPlace = ""
        self.deathPlace = ""
        self.bio = ""
        self.notes = ""
        self.createdAt = Date()
        self.relationshipsAsFirst = []
        self.relationshipsAsSecond = []
        self.lifeEvents = []
    }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var isDeceased: Bool { deathDate != nil }

    var age: Int? {
        guard let birth = birthDate else { return nil }
        let end = deathDate ?? Date()
        let comps = Calendar.current.dateComponents([.year], from: birth, to: end)
        return comps.year
    }

    var parents: [Person] {
        let asChild1 = relationshipsAsFirst.filter { $0.type == .parentChild }.compactMap { $0.person2 }
        let asChild2 = relationshipsAsSecond.filter { $0.type == .parentChild }.compactMap { $0.person1 }
        return asChild1 + asChild2
    }

    var children: [Person] {
        let asParent1 = relationshipsAsFirst.filter { $0.type == .childParent }.compactMap { $0.person2 }
        let asParent2 = relationshipsAsSecond.filter { $0.type == .childParent }.compactMap { $0.person1 }
        return asParent1 + asParent2
    }

    var spouses: [Person] {
        let sp1 = relationshipsAsFirst.filter { $0.type == .spouse }.compactMap { $0.person2 }
        let sp2 = relationshipsAsSecond.filter { $0.type == .spouse }.compactMap { $0.person1 }
        return sp1 + sp2
    }

    var siblings: [Person] {
        let sb1 = relationshipsAsFirst.filter { $0.type == .sibling }.compactMap { $0.person2 }
        let sb2 = relationshipsAsSecond.filter { $0.type == .sibling }.compactMap { $0.person1 }
        return sb1 + sb2
    }

    var sortedLifeEvents: [LifeEvent] {
        lifeEvents.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
}
