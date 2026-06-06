import Foundation
import SwiftData

/// Kind of system, for defaults and labelling.
enum TankKind: String, Codable, CaseIterable, Identifiable {
    case reef, fowlr, nano, freshwater
    var id: String { rawValue }
    var label: String {
        switch self {
        case .reef: return "Reef"
        case .fowlr: return "Fish-only (FOWLR)"
        case .nano: return "Nano reef"
        case .freshwater: return "Freshwater"
        }
    }
}

/// An aquarium that owns its readings, dosing log, and maintenance tasks.
@Model
final class Tank {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = TankKind.reef.rawValue
    var volumeLitres: Double = 0
    var setupDate: Date = Date()
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Reading.tank) var readings: [Reading] = []
    @Relationship(deleteRule: .cascade, inverse: \DoseEntry.tank) var doses: [DoseEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \CareTask.tank) var tasks: [CareTask] = []

    init(name: String, kind: TankKind = .reef, volumeLitres: Double = 0) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.volumeLitres = max(0, volumeLitres)
    }

    var kind: TankKind {
        get { TankKind(rawValue: kindRaw) ?? .reef }
        set { kindRaw = newValue.rawValue }
    }

    /// Most recent reading for a parameter, if any.
    func latest(_ p: WaterParameter) -> Reading? {
        readings.filter { $0.parameter == p }.max { $0.date < $1.date }
    }
    /// All readings for a parameter, oldest first.
    func history(_ p: WaterParameter) -> [Reading] {
        readings.filter { $0.parameter == p }.sorted { $0.date < $1.date }
    }
    /// Parameters that currently have a reading.
    var trackedParameters: [WaterParameter] {
        WaterParameter.allCases.filter { latest($0) != nil }
    }
    /// Fraction (0–1) of latest readings that sit in the ideal range.
    var healthScore: Double {
        let latests = WaterParameter.allCases.compactMap { p in latest(p).map { (p, $0.value) } }
        guard !latests.isEmpty else { return 0 }
        let good = latests.filter { $0.0.status(for: $0.1) == .good }.count
        return Double(good) / Double(latests.count)
    }
}

@Model
final class Reading {
    var id: UUID = UUID()
    var parameterRaw: String = WaterParameter.temperature.rawValue
    var value: Double = 0          // canonical units
    var date: Date = Date()
    var note: String = ""
    var tank: Tank?

    init(parameter: WaterParameter, value: Double, date: Date = Date()) {
        self.parameterRaw = parameter.rawValue
        self.value = value
        self.date = date
    }
    var parameter: WaterParameter {
        get { WaterParameter(rawValue: parameterRaw) ?? .temperature }
        set { parameterRaw = newValue.rawValue }
    }
    var status: ParamStatus { parameter.status(for: value) }
}

@Model
final class DoseEntry {
    var id: UUID = UUID()
    var supplement: String = ""
    var amountMl: Double = 0
    var date: Date = Date()
    var note: String = ""
    var tank: Tank?

    init(supplement: String, amountMl: Double, date: Date = Date()) {
        self.supplement = supplement
        self.amountMl = max(0, amountMl)
        self.date = date
    }
}

@Model
final class CareTask {
    var id: UUID = UUID()
    var title: String = ""
    var intervalDays: Int = 7
    var lastDone: Date?
    var createdAt: Date = Date()
    var tank: Tank?

    init(title: String, intervalDays: Int = 7) {
        self.title = title
        self.intervalDays = max(1, intervalDays)
    }

    var nextDue: Date? {
        guard let last = lastDone else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: last)
    }
    /// Days until due (negative = overdue). nil if never done.
    var daysUntilDue: Int? {
        guard let next = nextDue else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: next)
        return Calendar.current.dateComponents([.day], from: start, to: due).day
    }
    var isOverdue: Bool { (daysUntilDue ?? 1) < 0 || lastDone == nil }
}
