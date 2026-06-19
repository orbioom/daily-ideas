import SwiftData
import Foundation

@Model
class FavoriteWord {
    var word: String
    var dateAdded: Date
    var note: String

    init(word: String, note: String = "") {
        self.word = word
        self.dateAdded = Date()
        self.note = note
    }
}
