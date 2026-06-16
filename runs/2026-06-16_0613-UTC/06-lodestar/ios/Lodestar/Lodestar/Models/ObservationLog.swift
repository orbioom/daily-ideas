import Foundation
import SwiftData

/// A stargazing-journal entry — what was observed, where and when.
@Model
final class ObservationLog {
    var date: Date
    var objectName: String
    var note: String
    var locationName: String

    init(date: Date = .now, objectName: String, note: String, locationName: String) {
        self.date = date
        self.objectName = objectName
        self.note = note
        self.locationName = locationName
    }
}
