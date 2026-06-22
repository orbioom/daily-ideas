import Foundation
import SwiftData

@Model
class CustomPack {
    var id: UUID = UUID()
    var name: String = ""
    var words: [String] = []
    var createdAt: Date = Date()

    init(name: String, words: [String]) {
        self.id = UUID()
        self.name = name
        self.words = words
        self.createdAt = Date()
    }
}
