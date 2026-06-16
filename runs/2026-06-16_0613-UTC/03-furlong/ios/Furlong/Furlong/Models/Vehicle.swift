import Foundation
import SwiftData

@Model
final class Vehicle {
    var name: String
    var makeModel: String
    var startingOdometer: Double?
    var isDefault: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Trip.vehicle)
    var trips: [Trip] = []

    @Relationship(deleteRule: .nullify, inverse: \Expense.vehicle)
    var expenses: [Expense] = []

    init(name: String,
         makeModel: String = "",
         startingOdometer: Double? = nil,
         isDefault: Bool = false,
         createdAt: Date = .now) {
        self.name = name
        self.makeModel = makeModel
        self.startingOdometer = startingOdometer
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    var displaySubtitle: String {
        makeModel.isEmpty ? "Vehicle" : makeModel
    }
}
