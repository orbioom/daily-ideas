import SwiftUI

struct SolvedGroupView: View {
    let group: PuzzleGroup

    var body: some View {
        VStack(spacing: 2) {
            Text(group.category)
                .font(WeaveTheme.categoryFont)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Text(group.words.joined(separator: ", "))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: WeaveTheme.tileCorner)
                .fill(WeaveTheme.difficultyColor(group.difficulty))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.category): \(group.words.joined(separator: ", "))")
    }
}
