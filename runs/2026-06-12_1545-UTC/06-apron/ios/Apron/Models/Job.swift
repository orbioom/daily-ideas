import Foundation
import SwiftData
import SwiftUI

/// Deterministic, launch-stable hue (0...1) from a string via FNV-1a.
enum StableHue {
    static func hue(for s: String) -> Double {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Double(h % 360) / 360.0
    }
}

enum JobRole: String, Codable, CaseIterable, Identifiable {
    case server = "Server", bartender = "Bartender", barista = "Barista"
    case driver = "Delivery / Rideshare", stylist = "Stylist / Barber"
    case dealer = "Casino Dealer", host = "Host", other = "Other"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .server: return "fork.knife"
        case .bartender: return "wineglass.fill"
        case .barista: return "cup.and.saucer.fill"
        case .driver: return "car.fill"
        case .stylist: return "scissors"
        case .dealer: return "suit.spade.fill"
        case .host: return "person.2.fill"
        case .other: return "briefcase.fill"
        }
    }
}

@Model
final class Job {
    @Attribute(.unique) var id: UUID
    var name: String
    var roleRaw: String
    var hourlyWage: Double
    var colorHue: Double
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Shift.job)
    var shifts: [Shift] = []

    init(name: String, role: JobRole = .server, hourlyWage: Double = 0) {
        self.id = UUID()
        self.name = name
        self.roleRaw = role.rawValue
        self.hourlyWage = hourlyWage
        self.colorHue = StableHue.hue(for: name)
        self.isArchived = false
        self.createdAt = Date()
    }

    var role: JobRole {
        get { JobRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }
    var tint: Color { Color(hue: colorHue, saturation: 0.5, brightness: 0.72) }
}

@Model
final class Shift {
    @Attribute(.unique) var id: UUID
    var date: Date
    var hoursWorked: Double
    var cashTips: Double
    var cardTips: Double
    /// Tips you had to pay out to support staff (bussers, bar, etc.).
    var tipOut: Double
    /// Your total sales for the shift (optional, enables tip %).
    var sales: Double
    var notes: String
    var job: Job?

    init(date: Date = Date(), hoursWorked: Double = 0, cashTips: Double = 0,
         cardTips: Double = 0, tipOut: Double = 0, sales: Double = 0, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.hoursWorked = hoursWorked
        self.cashTips = cashTips
        self.cardTips = cardTips
        self.tipOut = tipOut
        self.sales = sales
        self.notes = notes
    }

    /// Tips kept after tip-out.
    var netTips: Double { max(cashTips + cardTips - tipOut, 0) }
    var grossTips: Double { cashTips + cardTips }
    var wages: Double { hoursWorked * (job?.hourlyWage ?? 0) }
    /// Real take-home for the shift.
    var totalEarnings: Double { wages + netTips }
    /// Effective hourly = everything earned divided by hours.
    var effectiveHourly: Double { hoursWorked > 0 ? totalEarnings / hoursWorked : 0 }
    var tipPercent: Double? { sales > 0 ? netTips / sales : nil }
}
