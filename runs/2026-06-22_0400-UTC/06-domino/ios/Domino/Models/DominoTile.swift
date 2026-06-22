import Foundation

struct DominoTile: Equatable, Codable, Identifiable {
    let a: Int   // pip count 0-6
    let b: Int   // pip count 0-6

    var id: String { "\(min(a, b))|\(max(a, b))" }

    var isDouble: Bool { a == b }
    var totalPips: Int { a + b }

    // Equatable: [3|5] == [5|3]
    static func == (lhs: DominoTile, rhs: DominoTile) -> Bool {
        (lhs.a == rhs.a && lhs.b == rhs.b) ||
        (lhs.a == rhs.b && lhs.b == rhs.a)
    }

    // The full set of 28 tiles
    static var fullSet: [DominoTile] {
        var tiles = [DominoTile]()
        for i in 0...6 {
            for j in i...6 {
                tiles.append(DominoTile(a: i, b: j))
            }
        }
        return tiles
    }

    // Returns a version of the tile oriented so that `rightEnd` is on the right
    func oriented(rightEnd: Int) -> (left: Int, right: Int) {
        if b == rightEnd { return (a, b) }
        if a == rightEnd { return (b, a) }
        return (a, b)  // fallback
    }

    // Returns a version oriented so that `leftEnd` is on the left
    func orientedLeft(leftEnd: Int) -> (left: Int, right: Int) {
        if a == leftEnd { return (a, b) }
        if b == leftEnd { return (b, a) }
        return (a, b)  // fallback
    }

    // Whether this tile can connect to a given pip value
    func canConnect(to pip: Int) -> Bool {
        a == pip || b == pip
    }
}
