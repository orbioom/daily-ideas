import Foundation
import SwiftData

struct InvoiceNumberGenerator {
    static func nextNumber(settings: BriefSettings) -> String {
        return settings.nextNumber()
    }

    static func preview(prefix: String, number: Int) -> String {
        return "\(prefix)-\(number)"
    }
}
