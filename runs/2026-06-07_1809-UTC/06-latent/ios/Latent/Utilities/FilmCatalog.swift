import Foundation

/// A reference entry: a real film + developer + dilution combination with a
/// published-style base development time at 20 °C and box speed. The catalog is
/// used both as a one-tap "turn into a recipe" source on the Reference screen and
/// as the seed source for SampleData.
struct FilmReference: Identifiable, Hashable {
    let id = UUID()
    let filmStock: String
    let boxISO: Int
    let developer: String
    let dilution: String
    let baseTimeSec: Int        // at 20 °C, box speed
    let agitationNote: String
    let stopSec: Int
    let fixSec: Int
    let washSec: Int

    init(filmStock: String,
         boxISO: Int,
         developer: String,
         dilution: String,
         baseTimeSec: Int,
         agitationNote: String = "30s initial, then 10s every 60s",
         stopSec: Int = 60,
         fixSec: Int = 300,
         washSec: Int = 600) {
        self.filmStock = filmStock
        self.boxISO = boxISO
        self.developer = developer
        self.dilution = dilution
        self.baseTimeSec = baseTimeSec
        self.agitationNote = agitationNote
        self.stopSec = stopSec
        self.fixSec = fixSec
        self.washSec = washSec
    }

    /// A friendly recipe name derived from the combination.
    var suggestedName: String {
        "\(filmStock) in \(developer) \(dilution)"
    }

    var baseTimeClock: String { DevEngine.clock(baseTimeSec) }
}

/// ~12 common B&W film + developer base times at 20 °C. Times are plausible,
/// published-style values (in seconds) for home development.
enum FilmCatalog {
    static let all: [FilmReference] = [
        FilmReference(filmStock: "Ilford HP5 Plus", boxISO: 400,
                      developer: "ID-11", dilution: "1+1", baseTimeSec: 13 * 60,
                      agitationNote: "30s initial, then 10s every 60s"),
        FilmReference(filmStock: "Kodak Tri-X 400", boxISO: 400,
                      developer: "D-76", dilution: "1+1", baseTimeSec: 9 * 60 + 45,
                      agitationNote: "30s initial, then 5s every 30s"),
        FilmReference(filmStock: "Kodak Tri-X 400", boxISO: 400,
                      developer: "HC-110", dilution: "Dil B", baseTimeSec: 6 * 60,
                      agitationNote: "Initial 30s, then 4 inversions every 60s"),
        FilmReference(filmStock: "Ilford Delta 100", boxISO: 100,
                      developer: "DD-X", dilution: "1+9", baseTimeSec: 9 * 60,
                      agitationNote: "10s every 60s"),
        FilmReference(filmStock: "Ilford FP4 Plus", boxISO: 125,
                      developer: "ID-11", dilution: "1+1", baseTimeSec: 11 * 60,
                      agitationNote: "30s initial, then 10s every 60s"),
        FilmReference(filmStock: "Kodak T-Max 400", boxISO: 400,
                      developer: "T-Max Dev", dilution: "1+4", baseTimeSec: 6 * 60 + 30,
                      agitationNote: "Continuous first 30s, then 5s every 30s"),
        FilmReference(filmStock: "Kentmere 400", boxISO: 400,
                      developer: "D-76", dilution: "1+1", baseTimeSec: 10 * 60 + 30,
                      agitationNote: "30s initial, then 10s every 60s"),
        FilmReference(filmStock: "Fomapan 100", boxISO: 100,
                      developer: "Rodinal", dilution: "1+50", baseTimeSec: 13 * 60,
                      agitationNote: "Gentle 10s every 60s"),
        FilmReference(filmStock: "Ilford Pan F Plus", boxISO: 50,
                      developer: "ID-11", dilution: "1+1", baseTimeSec: 8 * 60,
                      agitationNote: "30s initial, then 10s every 60s"),
        FilmReference(filmStock: "Ilford HP5 Plus", boxISO: 400,
                      developer: "Rodinal", dilution: "1+25", baseTimeSec: 7 * 60,
                      agitationNote: "30s initial, then 10s every 60s"),
        FilmReference(filmStock: "Kodak T-Max 100", boxISO: 100,
                      developer: "D-76", dilution: "1+1", baseTimeSec: 12 * 60,
                      agitationNote: "30s initial, then 5s every 30s"),
        FilmReference(filmStock: "Ilford Delta 3200", boxISO: 3200,
                      developer: "DD-X", dilution: "1+4", baseTimeSec: 9 * 60 + 30,
                      agitationNote: "10s every 60s")
    ]
}
