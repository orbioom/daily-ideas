import Foundation
import SwiftData

/// A logged developing run. All the chemistry parameters are *snapshotted* at the
/// time of development so the log stays accurate even if the source recipe is later
/// edited or deleted. Optionally still links back to its recipe.
@Model
final class DevSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var recipeName: String = ""        // snapshot
    var filmStock: String = ""
    var developer: String = ""
    var dilution: String = ""
    var ei: Int = 400                  // exposure index actually used
    var tempC: Double = 20.0
    var pushPull: Int = 0              // stops: − pull / + push
    var devSec: Int = 480             // computed adjusted develop time
    var stopSec: Int = 60
    var fixSec: Int = 300
    var washSec: Int = 600
    var rolls: Int = 1
    var rating: Int = 0               // 0…5
    var notes: String = ""

    var recipe: Recipe?

    init(id: UUID = UUID(),
         date: Date = Date(),
         recipeName: String = "",
         filmStock: String = "",
         developer: String = "",
         dilution: String = "",
         ei: Int = 400,
         tempC: Double = 20.0,
         pushPull: Int = 0,
         devSec: Int = 480,
         stopSec: Int = 60,
         fixSec: Int = 300,
         washSec: Int = 600,
         rolls: Int = 1,
         rating: Int = 0,
         notes: String = "",
         recipe: Recipe? = nil) {
        self.id = id
        self.date = date
        self.recipeName = recipeName
        self.filmStock = filmStock
        self.developer = developer
        self.dilution = dilution
        self.ei = ei
        self.tempC = tempC
        self.pushPull = pushPull
        self.devSec = devSec
        self.stopSec = stopSec
        self.fixSec = fixSec
        self.washSec = washSec
        self.rolls = rolls
        self.rating = rating
        self.notes = notes
        self.recipe = recipe
    }

    var summary: String {
        let dil = dilution.isEmpty ? "" : " \(dilution)"
        return "\(filmStock) · \(developer)\(dil)"
    }

    /// Push/pull as a readable label, e.g. "+1", "−2", "Box".
    var pushPullLabel: String {
        if pushPull == 0 { return "Box" }
        return pushPull > 0 ? "+\(pushPull)" : "−\(abs(pushPull))"
    }
}
