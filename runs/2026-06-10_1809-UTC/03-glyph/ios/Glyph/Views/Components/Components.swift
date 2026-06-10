import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Generates puzzles off the main thread so the UI never blocks.
enum PuzzleFactory {
    static func make(_ difficulty: SudokuDifficulty, seed: UInt64? = nil) async -> (givens: [Int], solution: [Int]) {
        await Task.detached(priority: .userInitiated) {
            SudokuEngine.generate(difficulty, seed: seed)
        }.value
    }
}
