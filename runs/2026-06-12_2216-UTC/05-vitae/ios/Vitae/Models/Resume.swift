import Foundation
import SwiftData

enum TemplateKind: String, CaseIterable, Codable, Identifiable {
    case classic, banner, compact

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .banner: return "Banner"
        case .compact: return "Compact"
        }
    }

    var blurb: String {
        switch self {
        case .classic: return "Centered serif header, ruled sections. Timeless."
        case .banner: return "Full-width accent banner, bold sans. Confident."
        case .compact: return "Dense single column. Fits more on one page."
        }
    }
}

@Model
final class Resume {
    var fullName: String
    var headline: String
    var email: String
    var phone: String
    var location: String
    var website: String
    var summary: String
    var accentHex: String
    var templateRaw: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExperienceItem.resume)
    var experience: [ExperienceItem] = []

    @Relationship(deleteRule: .cascade, inverse: \EducationItem.resume)
    var education: [EducationItem] = []

    @Relationship(deleteRule: .cascade, inverse: \SkillGroup.resume)
    var skillGroups: [SkillGroup] = []

    init(
        fullName: String = "",
        headline: String = "",
        email: String = "",
        phone: String = "",
        location: String = "",
        website: String = "",
        summary: String = "",
        accentHex: String = "2F6BD8",
        template: TemplateKind = .classic
    ) {
        self.fullName = fullName
        self.headline = headline
        self.email = email
        self.phone = phone
        self.location = location
        self.website = website
        self.summary = summary
        self.accentHex = accentHex
        self.templateRaw = template.rawValue
        self.createdAt = .now
        self.updatedAt = .now
    }

    var template: TemplateKind {
        get { TemplateKind(rawValue: templateRaw) ?? .classic }
        set { templateRaw = newValue.rawValue }
    }

    var sortedExperience: [ExperienceItem] {
        experience.sorted { $0.orderIndex < $1.orderIndex }
    }

    var sortedEducation: [EducationItem] {
        education.sorted { $0.orderIndex < $1.orderIndex }
    }

    var sortedSkillGroups: [SkillGroup] {
        skillGroups.sorted { $0.orderIndex < $1.orderIndex }
    }

    var contactLine: String {
        [email, phone, location, website]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "  ·  ")
    }

    /// Rough completeness for the list screen.
    var completeness: Double {
        var score = 0.0
        if !fullName.trimmingCharacters(in: .whitespaces).isEmpty { score += 0.2 }
        if !contactLine.isEmpty { score += 0.2 }
        if !summary.trimmingCharacters(in: .whitespaces).isEmpty { score += 0.2 }
        if !experience.isEmpty { score += 0.25 }
        if !education.isEmpty { score += 0.1 }
        if !skillGroups.isEmpty { score += 0.05 }
        return min(1, score)
    }
}

@Model
final class ExperienceItem {
    var company: String
    var role: String
    var period: String       // free text: "2021 — Present"
    var details: String      // newline-separated bullets
    var orderIndex: Int
    var resume: Resume?

    init(company: String = "", role: String = "", period: String = "", details: String = "", orderIndex: Int = 0) {
        self.company = company
        self.role = role
        self.period = period
        self.details = details
        self.orderIndex = orderIndex
    }

    var bullets: [String] {
        details.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

@Model
final class EducationItem {
    var institution: String
    var degree: String
    var period: String
    var note: String
    var orderIndex: Int
    var resume: Resume?

    init(institution: String = "", degree: String = "", period: String = "", note: String = "", orderIndex: Int = 0) {
        self.institution = institution
        self.degree = degree
        self.period = period
        self.note = note
        self.orderIndex = orderIndex
    }
}

@Model
final class SkillGroup {
    var name: String        // e.g. "Languages"
    var skills: String      // comma-separated
    var orderIndex: Int
    var resume: Resume?

    init(name: String = "", skills: String = "", orderIndex: Int = 0) {
        self.name = name
        self.skills = skills
        self.orderIndex = orderIndex
    }

    var skillList: [String] {
        skills.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
