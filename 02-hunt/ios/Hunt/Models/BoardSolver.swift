import Foundation

struct BoardSolver {
    static func findAllWords(in board: [[Character]]) -> Set<String> {
        var found = Set<String>()

        func dfs(r: Int, c: Int, current: String, visited: [[Bool]]) {
            let word = current + String(board[r][c])
            guard word.count <= 8 else { return }
            if word.count >= 3 && WordList.isValid(word) {
                found.insert(word.lowercased())
            }
            var vis = visited
            vis[r][c] = true

            for dr in -1...1 {
                for dc in -1...1 {
                    if dr == 0 && dc == 0 { continue }
                    let nr = r + dr, nc = c + dc
                    if nr >= 0 && nr < 4 && nc >= 0 && nc < 4 && !vis[nr][nc] {
                        dfs(r: nr, c: nc, current: word, visited: vis)
                    }
                }
            }
        }

        let emptyVis = Array(repeating: Array(repeating: false, count: 4), count: 4)
        for r in 0..<4 {
            for c in 0..<4 {
                dfs(r: r, c: c, current: "", visited: emptyVis)
            }
        }
        return found
    }
}
