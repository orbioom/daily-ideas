import Foundation
import SwiftData

/// Single-row settings model persisted in SwiftData.
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var hapticsEnabled: Bool
    var dueSoonWindowDays: Int       // how many days ahead counts as "due soon"
    var currencyCode: String
    var weekStartsMonday: Bool
    var groupTasksByRoom: Bool

    init(hapticsEnabled: Bool = true,
         dueSoonWindowDays: Int = 14,
         currencyCode: String = Locale.current.currency?.identifier ?? "USD",
         weekStartsMonday: Bool = false,
         groupTasksByRoom: Bool = true) {
        self.id = UUID()
        self.hapticsEnabled = hapticsEnabled
        self.dueSoonWindowDays = max(1, dueSoonWindowDays)
        self.currencyCode = currencyCode
        self.weekStartsMonday = weekStartsMonday
        self.groupTasksByRoom = groupTasksByRoom
    }
}
