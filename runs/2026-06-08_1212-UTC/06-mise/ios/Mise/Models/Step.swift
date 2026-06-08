import Foundation
import SwiftData

@Model
final class Step {
    var id: UUID
    var text: String
    var order: Int
    var recipe: Recipe?

    init(id: UUID = UUID(), text: String, order: Int = 0, recipe: Recipe? = nil) {
        self.id = id
        self.text = text
        self.order = order
        self.recipe = recipe
    }
}
