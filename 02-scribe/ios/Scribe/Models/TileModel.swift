import Foundation

struct Tile: Identifiable, Equatable {
    let id: UUID
    var letter: Character
    var points: Int
    var isBlank: Bool

    init(letter: Character, isBlank: Bool = false) {
        self.id = UUID()
        self.letter = letter
        self.isBlank = isBlank
        self.points = isBlank ? 0 : LetterValues.points(for: letter)
    }
}

enum LetterValues {
    static let distribution: [(Character, Int, Int)] = [
        ("A",1,9),("B",3,2),("C",3,2),("D",2,4),("E",1,12),("F",4,2),("G",2,3),
        ("H",4,2),("I",1,9),("J",8,1),("K",5,1),("L",1,4),("M",3,2),("N",1,6),
        ("O",1,8),("P",3,2),("Q",10,1),("R",1,6),("S",1,4),("T",1,6),("U",1,4),
        ("V",4,2),("W",4,2),("X",8,1),("Y",4,2),("Z",10,1),("_",0,2)
    ]

    static func points(for letter: Character) -> Int {
        let up = Character(letter.uppercased())
        return distribution.first { $0.0 == up }?.1 ?? 0
    }

    static func makeBag() -> [Tile] {
        var bag: [Tile] = []
        for (letter, _, count) in distribution {
            for _ in 0..<count {
                if letter == "_" {
                    bag.append(Tile(letter: " ", isBlank: true))
                } else {
                    bag.append(Tile(letter: letter))
                }
            }
        }
        return bag.shuffled()
    }
}

enum SquareType: String {
    case normal = "normal"
    case doubleLetter = "DL"
    case tripleLetter = "TL"
    case doubleWord = "DW"
    case tripleWord = "TW"
    case center = "★"
}

struct BoardSquare: Identifiable {
    let id: Int
    let row: Int
    let col: Int
    let type: SquareType
    var tile: Tile?

    var isEmpty: Bool { tile == nil }
}
