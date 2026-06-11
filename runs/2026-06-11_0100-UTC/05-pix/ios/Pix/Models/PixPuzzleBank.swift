import Foundation

// Helper for creating Bool rows from compact string "1100101..."
private func row(_ s: String) -> [Bool] { s.map { $0 == "1" } }

enum PixPuzzleBank {
    static let all: [NonogramPuzzle] = puzzles5x5 + puzzles10x10

    // MARK: 5×5 puzzles

    static let puzzles5x5: [NonogramPuzzle] = [
        NonogramPuzzle(id: 0, name: "Heart", size: 5, solution: [
            row("01010"),
            row("11111"),
            row("11111"),
            row("01110"),
            row("00100"),
        ], difficulty: 1),

        NonogramPuzzle(id: 1, name: "House", size: 5, solution: [
            row("00100"),
            row("01110"),
            row("11111"),
            row("11011"),
            row("11011"),
        ], difficulty: 1),

        NonogramPuzzle(id: 2, name: "Diamond", size: 5, solution: [
            row("00100"),
            row("01110"),
            row("11111"),
            row("01110"),
            row("00100"),
        ], difficulty: 1),

        NonogramPuzzle(id: 3, name: "Cross", size: 5, solution: [
            row("00100"),
            row("00100"),
            row("11111"),
            row("00100"),
            row("00100"),
        ], difficulty: 1),

        NonogramPuzzle(id: 4, name: "Smiley", size: 5, solution: [
            row("01110"),
            row("10001"),
            row("10101"),
            row("10001"),
            row("01110"),
        ], difficulty: 1),

        NonogramPuzzle(id: 5, name: "Arrow", size: 5, solution: [
            row("00100"),
            row("01100"),
            row("11111"),
            row("01100"),
            row("00100"),
        ], difficulty: 1),

        NonogramPuzzle(id: 6, name: "Star", size: 5, solution: [
            row("00100"),
            row("11111"),
            row("01110"),
            row("01110"),
            row("10001"),
        ], difficulty: 1),

        NonogramPuzzle(id: 7, name: "Check", size: 5, solution: [
            row("00001"),
            row("00010"),
            row("00100"),
            row("10100"),
            row("11000"),  // hmm, but this should look like a checkmark
        ], difficulty: 1),

        NonogramPuzzle(id: 8, name: "Boat", size: 5, solution: [
            row("00100"),
            row("01110"),
            row("11111"),
            row("11111"),
            row("01110"),
        ], difficulty: 1),

        NonogramPuzzle(id: 9, name: "Crown", size: 5, solution: [
            row("10101"),
            row("10101"),
            row("11111"),
            row("11111"),
            row("01110"),
        ], difficulty: 1),
    ]

    // MARK: 10×10 puzzles

    static let puzzles10x10: [NonogramPuzzle] = [
        NonogramPuzzle(id: 100, name: "Fish", size: 10, solution: [
            row("0001100000"),
            row("0011110000"),
            row("1111111110"),
            row("1111111111"),
            row("1111111110"),
            row("0111111110"),
            row("0011111000"),
            row("0001100100"),
            row("0000000110"),
            row("0000000000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 101, name: "Tree", size: 10, solution: [
            row("0000100000"),
            row("0001110000"),
            row("0001110000"),
            row("0011111000"),
            row("0011111000"),
            row("0111111100"),
            row("0111111100"),
            row("1111111110"),
            row("0001110000"),
            row("0001110000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 102, name: "Rocket", size: 10, solution: [
            row("0000110000"),
            row("0001111000"),
            row("0011111100"),
            row("0011111100"),
            row("0111111110"),
            row("0111111110"),
            row("0011111100"),
            row("0001111000"),
            row("0100110010"),
            row("1100000011"),
        ], difficulty: 2),

        NonogramPuzzle(id: 103, name: "Cat", size: 10, solution: [
            row("1100000011"),
            row("1110001110"),
            row("0111111110"),
            row("0111111110"),
            row("0110110110"),
            row("0111111110"),
            row("0011111100"),
            row("0001001000"),
            row("0011111100"),
            row("0011111100"),
        ], difficulty: 2),

        NonogramPuzzle(id: 104, name: "Moon", size: 10, solution: [
            row("0001111000"),
            row("0011111100"),
            row("0111111100"),
            row("0111100000"),
            row("1111000000"),
            row("1111000000"),
            row("0111100000"),
            row("0111111100"),
            row("0011111100"),
            row("0001111000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 105, name: "Crown", size: 10, solution: [
            row("1010000101"),
            row("1011001101"),
            row("1111111111"),
            row("1111111111"),
            row("1111111111"),
            row("0111111110"),
            row("0111111110"),
            row("0011111100"),
            row("0011111100"),
            row("0001111000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 106, name: "Butterfly", size: 10, solution: [
            row("1100000011"),
            row("1111000111"),
            row("0111111110"),
            row("0011111100"),
            row("0001111000"),
            row("0001111000"),
            row("0011111100"),
            row("0111111110"),
            row("1111000111"),
            row("1100000011"),
        ], difficulty: 2),

        NonogramPuzzle(id: 107, name: "Lock", size: 10, solution: [
            row("0011111100"),
            row("0110000110"),
            row("0100000010"),
            row("0110000110"),
            row("0011111100"),
            row("0111111110"),
            row("0111111110"),
            row("0110111110"),
            row("0111011110"),
            row("0111111110"),
        ], difficulty: 2),

        NonogramPuzzle(id: 108, name: "Flower", size: 10, solution: [
            row("0001111000"),
            row("0111111110"),
            row("0111001110"),
            row("1111111111"),
            row("1110111011"),
            row("1110111011"),
            row("1111111111"),
            row("0111001110"),
            row("0111111110"),
            row("0001111000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 109, name: "Robot", size: 10, solution: [
            row("0011111100"),
            row("0111111110"),
            row("0110110110"),
            row("0111111110"),
            row("0011111100"),
            row("1111111111"),
            row("1101111011"),
            row("1101111011"),
            row("1111111111"),
            row("0110000110"),
        ], difficulty: 2),

        NonogramPuzzle(id: 110, name: "Anchor", size: 10, solution: [
            row("0001111000"),
            row("0011111100"),
            row("0001111000"),
            row("0001001000"),
            row("0011111100"),
            row("0111111110"),
            row("1110001011"),
            row("1100001001"),
            row("0100001000"),
            row("0001111000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 111, name: "Hourglass", size: 10, solution: [
            row("1111111111"),
            row("0111111110"),
            row("0011111100"),
            row("0001111000"),
            row("0000110000"),
            row("0000110000"),
            row("0001111000"),
            row("0011111100"),
            row("0111111110"),
            row("1111111111"),
        ], difficulty: 2),

        NonogramPuzzle(id: 112, name: "Lightning", size: 10, solution: [
            row("0001111100"),
            row("0001111100"),
            row("0001111100"),
            row("0001111100"),
            row("0011111100"),
            row("0111111100"),
            row("0011100000"),
            row("0011100000"),
            row("0011100000"),
            row("0011100000"),
        ], difficulty: 3),

        NonogramPuzzle(id: 113, name: "House 10", size: 10, solution: [
            row("0000110000"),
            row("0001111000"),
            row("0011111100"),
            row("0111111110"),
            row("1111111111"),
            row("0111111110"),
            row("0110110110"),
            row("0110110110"),
            row("0111111110"),
            row("0111111110"),
        ], difficulty: 2),

        NonogramPuzzle(id: 114, name: "Diamond 10", size: 10, solution: [
            row("0000110000"),
            row("0001111000"),
            row("0011111100"),
            row("0111111110"),
            row("1111111111"),
            row("1111111111"),
            row("0111111110"),
            row("0011111100"),
            row("0001111000"),
            row("0000110000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 115, name: "Skull", size: 10, solution: [
            row("0011111100"),
            row("0111111110"),
            row("1110110111"),
            row("1110110111"),
            row("0111111110"),
            row("0011111100"),
            row("0011111100"),
            row("0111001110"),
            row("0111001110"),
            row("0011111100"),
        ], difficulty: 3),

        NonogramPuzzle(id: 116, name: "Leaf", size: 10, solution: [
            row("0000000001"),
            row("0000000111"),
            row("0000011111"),
            row("0001111111"),
            row("0111111111"),
            row("0111111110"),
            row("0111111100"),
            row("0111110000"),
            row("0111000000"),
            row("0100000000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 117, name: "Wave", size: 10, solution: [
            row("0000000000"),
            row("0110000110"),
            row("1111001111"),
            row("1111001111"),
            row("0111111110"),
            row("0011111100"),
            row("0000000000"),
            row("0000000000"),
            row("0000000000"),
            row("0000000000"),
        ], difficulty: 2),

        NonogramPuzzle(id: 118, name: "Key", size: 10, solution: [
            row("0001111000"),
            row("0011111100"),
            row("0110001100"),
            row("0110001100"),
            row("0011111100"),
            row("0001111000"),
            row("0000110000"),
            row("0001111000"),
            row("0001110000"),
            row("0000110000"),
        ], difficulty: 3),

        NonogramPuzzle(id: 119, name: "Bear", size: 10, solution: [
            row("1100000011"),
            row("1110011110"),
            row("0111111110"),
            row("0111111110"),
            row("0110110110"),
            row("0111111110"),
            row("0011111100"),
            row("0011001100"),
            row("0111001110"),
            row("0011001100"),
        ], difficulty: 3),
    ]
}
