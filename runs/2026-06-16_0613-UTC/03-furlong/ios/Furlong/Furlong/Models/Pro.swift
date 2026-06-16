import SwiftUI

/// Simulated one-time Pro unlock (StoreKit-ready, not wired to real purchases).
/// Stored as a single boolean flag.
enum Pro {
    static let price = "$3.99"
    static let freeTripCap = 40
    static let freeVehicleCap = 1

    struct Feature: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    static let features: [Feature] = [
        Feature(symbol: "square.and.arrow.up",
                title: "CSV & PDF export",
                detail: "Hand your accountant a clean, IRS-ready ledger."),
        Feature(symbol: "infinity",
                title: "Unlimited trips",
                detail: "Log past the free \(freeTripCap)-trip cap — a full year, easily."),
        Feature(symbol: "car.2.fill",
                title: "Multiple vehicles",
                detail: "Track every car, van, or bike you drive for work."),
        Feature(symbol: "tag.fill",
                title: "Custom categories",
                detail: "Name expenses your own way beyond the built-ins."),
        Feature(symbol: "calendar.badge.clock",
                title: "Mileage-rate history",
                detail: "Edit or add IRS standard rates for any tax year.")
    ]
}
