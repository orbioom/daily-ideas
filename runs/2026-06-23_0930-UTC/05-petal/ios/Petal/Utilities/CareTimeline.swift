import Foundation
import SwiftUI

/// A normalized "due item" aggregated from medications, vaccinations, vet
/// follow-ups and feedings across all pets. Drives the Care timeline.
struct CareItem: Identifiable, Hashable {
    enum Kind: String {
        case medication, vaccination, vetFollowUp, feeding

        var label: String {
            switch self {
            case .medication: return "Medication"
            case .vaccination: return "Vaccination"
            case .vetFollowUp: return "Vet follow-up"
            case .feeding: return "Feeding"
            }
        }

        var symbol: String {
            switch self {
            case .medication: return "pills.fill"
            case .vaccination: return "syringe.fill"
            case .vetFollowUp: return "stethoscope"
            case .feeding: return "fork.knife"
            }
        }

        var tint: Color {
            switch self {
            case .medication: return Theme.accent
            case .vaccination: return Theme.amber
            case .vetFollowUp: return Theme.blue
            case .feeding: return Theme.pink
            }
        }
    }

    enum Bucket: String, CaseIterable, Identifiable {
        case overdue, today, soon, upcoming
        var id: String { rawValue }
        var label: String {
            switch self {
            case .overdue: return "Overdue"
            case .today: return "Today"
            case .soon: return "Soon"
            case .upcoming: return "Upcoming"
            }
        }
        var tint: Color {
            switch self {
            case .overdue: return Theme.danger
            case .today: return Theme.accent
            case .soon: return Theme.amber
            case .upcoming: return Theme.secondaryText
            }
        }
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let petName: String
    let petTint: Color
    let petSymbol: String
    let dueDate: Date
    /// Stable reference to the source object id so views can route to detail.
    let sourceID: UUID

    func bucket(soonWindowDays: Int, reference: Date = .now) -> Bucket {
        let days = Fmt.daysBetween(reference, dueDate)
        if days < 0 { return .overdue }
        if days == 0 { return .today }
        if days <= max(1, soonWindowDays) { return .soon }
        return .upcoming
    }
}

/// Pure functions that build the aggregated care timeline. Kept dependency-free
/// so it is trivially unit-testable and previewable.
enum CareTimeline {
    /// Builds and sorts care items for the given pets within `horizonDays`.
    static func build(for pets: [Pet], horizonDays: Int = 60, reference: Date = .now) -> [CareItem] {
        var items: [CareItem] = []
        let horizon = Calendar.current.date(byAdding: .day, value: horizonDays, to: reference) ?? reference

        for pet in pets {
            // Medications
            for med in pet.medications where med.isActive {
                guard med.nextDue <= horizon else { continue }
                items.append(CareItem(
                    id: "med-\(med.id.uuidString)",
                    kind: .medication,
                    title: med.name,
                    subtitle: med.dosage.isEmpty ? med.frequency.label : "\(med.dosage) · \(med.frequency.label)",
                    petName: pet.name,
                    petTint: pet.avatarTint.color,
                    petSymbol: pet.avatarSymbol,
                    dueDate: med.nextDue,
                    sourceID: med.id
                ))
            }

            // Vaccinations with a next-due booster
            for vax in pet.vaccinations {
                guard let due = vax.nextDue, due <= horizon else { continue }
                items.append(CareItem(
                    id: "vax-\(vax.id.uuidString)",
                    kind: .vaccination,
                    title: "\(vax.name) booster",
                    subtitle: vax.clinic.isEmpty ? "Booster due" : vax.clinic,
                    petName: pet.name,
                    petTint: pet.avatarTint.color,
                    petSymbol: pet.avatarSymbol,
                    dueDate: due,
                    sourceID: vax.id
                ))
            }

            // Vet follow-ups
            for visit in pet.vetVisits {
                guard let due = visit.followUpDate, due <= horizon else { continue }
                items.append(CareItem(
                    id: "vet-\(visit.id.uuidString)",
                    kind: .vetFollowUp,
                    title: "Follow-up: \(visit.reason.label)",
                    subtitle: visit.clinic.isEmpty ? "Recheck appointment" : visit.clinic,
                    petName: pet.name,
                    petTint: pet.avatarTint.color,
                    petSymbol: pet.avatarSymbol,
                    dueDate: due,
                    sourceID: visit.id
                ))
            }

            // Today's feedings (recurring daily)
            for feeding in pet.feedings where feeding.isActive {
                items.append(CareItem(
                    id: "feed-\(feeding.id.uuidString)",
                    kind: .feeding,
                    title: feeding.label,
                    subtitle: [feeding.portion, feeding.food].filter { !$0.isEmpty }.joined(separator: " · "),
                    petName: pet.name,
                    petTint: pet.avatarTint.color,
                    petSymbol: pet.avatarSymbol,
                    dueDate: feeding.todayTime,
                    sourceID: feeding.id
                ))
            }
        }

        return items.sorted { $0.dueDate < $1.dueDate }
    }

    /// Groups items into ordered buckets, dropping empty buckets.
    static func grouped(_ items: [CareItem], soonWindowDays: Int, reference: Date = .now) -> [(CareItem.Bucket, [CareItem])] {
        var map: [CareItem.Bucket: [CareItem]] = [:]
        for item in items {
            map[item.bucket(soonWindowDays: soonWindowDays, reference: reference), default: []].append(item)
        }
        return CareItem.Bucket.allCases.compactMap { bucket in
            guard let arr = map[bucket], !arr.isEmpty else { return nil }
            return (bucket, arr)
        }
    }

    static func overdueCount(_ items: [CareItem], soonWindowDays: Int, reference: Date = .now) -> Int {
        items.filter { $0.bucket(soonWindowDays: soonWindowDays, reference: reference) == .overdue }.count
    }
}
