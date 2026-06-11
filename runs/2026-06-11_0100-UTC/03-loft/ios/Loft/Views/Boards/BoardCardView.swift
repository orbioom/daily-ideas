import SwiftUI

struct BoardCardView: View {
    let board: VisionBoard
    @State private var coverImage: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover area
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(LoftTheme.categoryColor(board.category).gradient)
                    .frame(height: 140)

                if let img = coverImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )

                Image(systemName: board.category.icon)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(8)
            }
            .frame(height: 140)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: LoftTheme.cardRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: LoftTheme.cardRadius
            ))

            // Title area
            VStack(alignment: .leading, spacing: 4) {
                Text(board.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(board.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: LoftTheme.cardRadius))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(board.title) vision board, category: \(board.category.rawValue)")
        .task {
            if let fn = board.items.first?.imageFilename {
                coverImage = await Task.detached { ImageStore.load(fn) }.value
            }
        }
    }
}
