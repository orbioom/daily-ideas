import Foundation
import SwiftData

/// A saved film-development recipe: the film stock, developer, dilution, and the
/// *base* development time measured at a reference temperature (default 20 °C) at
/// box speed. Every developing run is derived from one of these (or an ad-hoc
/// entry) after applying temperature and push/pull compensation.
@Model
final class Recipe {
    var id: UUID = UUID()
    var name: String = ""
    var filmStock: String = ""
    var developer: String = ""
    var dilution: String = ""          // e.g. "1+1", "Stock", "1+50"
    var boxISO: Int = 400
    var baseTimeSec: Int = 480         // dev time at base temp & box speed
    var baseTempC: Double = 20.0
    var agitationNote: String = ""
    var stopSec: Int = 60
    var fixSec: Int = 300
    var washSec: Int = 600
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \DevSession.recipe)
    var sessions: [DevSession] = []

    init(id: UUID = UUID(),
         name: String = "",
         filmStock: String = "",
         developer: String = "",
         dilution: String = "",
         boxISO: Int = 400,
         baseTimeSec: Int = 480,
         baseTempC: Double = 20.0,
         agitationNote: String = "",
         stopSec: Int = 60,
         fixSec: Int = 300,
         washSec: Int = 600,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.filmStock = filmStock
        self.developer = developer
        self.dilution = dilution
        self.boxISO = boxISO
        self.baseTimeSec = baseTimeSec
        self.baseTempC = baseTempC
        self.agitationNote = agitationNote
        self.stopSec = stopSec
        self.fixSec = fixSec
        self.washSec = washSec
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Compact one-line summary used in lists and headers.
    var summary: String {
        let dil = dilution.isEmpty ? "" : " \(dilution)"
        return "\(filmStock) · \(developer)\(dil)"
    }
}
