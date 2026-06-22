import Foundation

struct CardGenerator {

    static func generateNumberCard() -> [[String]] {
        let b = Array((1...15).shuffled().prefix(5))
        let i = Array((16...30).shuffled().prefix(5))
        let n = Array((31...45).shuffled().prefix(5))
        let g = Array((46...60).shuffled().prefix(5))
        let o = Array((61...75).shuffled().prefix(5))

        var grid = [[String]]()
        for row in 0..<5 {
            let rowArr: [String]
            if row == 2 {
                rowArr = ["B\(b[row])", "I\(i[row])", "FREE", "G\(g[row])", "O\(o[row])"]
            } else {
                rowArr = ["B\(b[row])", "I\(i[row])", "N\(n[row])", "G\(g[row])", "O\(o[row])"]
            }
            grid.append(rowArr)
        }
        return grid
    }

    static func generateWordCard(words: [String]) -> [[String]] {
        var shuffled = words.shuffled()
        if shuffled.count < 24 {
            var expanded = shuffled
            while expanded.count < 24 {
                expanded.append(contentsOf: shuffled)
            }
            shuffled = expanded
        }
        let selected = Array(shuffled.prefix(24))

        var grid = [[String]]()
        var idx = 0
        for row in 0..<5 {
            var rowArr = [String]()
            for col in 0..<5 {
                if row == 2 && col == 2 {
                    rowArr.append("FREE")
                } else {
                    rowArr.append(selected[idx])
                    idx += 1
                }
            }
            grid.append(rowArr)
        }
        return grid
    }

    static func isCellFree(row: Int, col: Int) -> Bool {
        return row == 2 && col == 2
    }
}
