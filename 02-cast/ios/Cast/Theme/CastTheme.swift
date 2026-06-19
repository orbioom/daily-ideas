import SwiftUI

enum CastTheme {
    static let purple = Color(red: 0.40, green: 0.22, blue: 0.82)
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.15)
    static let deepBackground = Color(red: 0.06, green: 0.04, blue: 0.14)
    static let cardBackground = Color(red: 0.12, green: 0.09, blue: 0.22)

    static func genreColor(_ genre: PodcastGenre) -> Color {
        switch genre {
        case .trueCrime: return .red
        case .comedy: return .yellow
        case .news: return .blue
        case .technology: return .cyan
        case .society: return .indigo
        case .history: return .brown
        case .science: return .green
        case .business: return .orange
        case .health: return .pink
        case .arts: return .purple
        case .sports: return .mint
        case .education: return .teal
        case .fiction: return Color(red: 0.6, green: 0.2, blue: 0.8)
        case .other: return .gray
        }
    }
}

struct ShowArtwork: View {
    let show: PodcastShow
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(CastTheme.genreColor(show.genre).opacity(0.85).gradient)

            VStack(spacing: 2) {
                Image(systemName: show.genre.icon)
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(.white.opacity(0.9))
                if size >= 80 {
                    Text(String(show.title.prefix(2)).uppercased())
                        .font(.system(size: size * 0.2, weight: .black))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
