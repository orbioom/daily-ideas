import SwiftData

@Model
final class Room {
    var id: UUID
    var name: String
    var symbol: String
    var order: Int

    @Relationship(deleteRule: .nullify)
    var plants: [Plant]?

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String = "door.left.hand.open",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.order = order
        self.plants = []
    }
}
