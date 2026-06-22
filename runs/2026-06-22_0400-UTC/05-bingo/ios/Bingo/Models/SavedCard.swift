import Foundation
import SwiftData

@Model
class SavedCard {
    var id: UUID = UUID()
    var gameId: String? = nil
    var cellsJSON: String = "[]"
    var markedJSON: String = "[]"
    var cardIndex: Int = 0
    var label: String = "Card 1"

    init(gameId: String? = nil, cells: [[String]], cardIndex: Int, label: String) {
        self.id = UUID()
        self.gameId = gameId
        self.cardIndex = cardIndex
        self.label = label
        self.cellsJSON = (try? String(data: JSONEncoder().encode(cells), encoding: .utf8)) ?? "[]"
        var m = Array(repeating: Array(repeating: false, count: 5), count: 5)
        if m.count == 5 && m[2].count == 5 {
            m[2][2] = true
        }
        self.markedJSON = (try? String(data: JSONEncoder().encode(m), encoding: .utf8)) ?? "[]"
    }

    var cells: [[String]] {
        get {
            (try? JSONDecoder().decode([[String]].self, from: Data(cellsJSON.utf8))) ?? []
        }
        set {
            cellsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var marked: [[Bool]] {
        get {
            (try? JSONDecoder().decode([[Bool]].self, from: Data(markedJSON.utf8)))
                ?? Array(repeating: Array(repeating: false, count: 5), count: 5)
        }
        set {
            markedJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }
}
