import SwiftUI

/// Reference screen: how each piece moves and a glossary of tactics, with live diagrams.
struct LearnScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionTitle("How the pieces move", symbol: "figure.walk")
                        ForEach(LearnContent.pieces) { lesson in
                            NavigationLink(value: LearnRoute.piece(lesson.id)) {
                                pieceRow(lesson)
                            }
                            .buttonStyle(.plain)
                        }

                        sectionTitle("Tactics glossary", symbol: "bolt.fill")
                            .padding(.top, 6)
                        ForEach(LearnContent.tactics) { lesson in
                            NavigationLink(value: LearnRoute.tactic(lesson.id)) {
                                tacticRow(lesson)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: LearnRoute.self) { route in
                LearnDetailView(route: route)
            }
        }
    }

    private func sectionTitle(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.serif(20, .bold))
            .foregroundStyle(Theme.ink)
    }

    private func pieceRow(_ lesson: LearnContent.PieceLesson) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(settings.effectiveBoardTheme(isPro: isPro).darkSquare.opacity(0.25))
                    .frame(width: 56, height: 56)
                PieceGlyph(piece: Piece(color: lesson.glyphColor, type: lesson.id),
                           size: 38, style: settings.pieceStyle)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.name)
                    .font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                Text(lesson.summary)
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func tacticRow(_ lesson: LearnContent.TacticLesson) -> some View {
        HStack(spacing: 14) {
            Image(systemName: tacticSymbol(lesson.id))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accentSoft))
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.name)
                    .font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                Text(lesson.summary)
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func tacticSymbol(_ id: String) -> String {
        switch id {
        case "fork": return "arrow.triangle.branch"
        case "pin": return "pin.fill"
        case "skewer": return "arrow.left.and.right"
        case "discovered": return "eye.fill"
        case "backrank": return "rectangle.compress.vertical"
        default: return "bolt.fill"
        }
    }
}

/// Navigation routes within Learn.
enum LearnRoute: Hashable {
    case piece(PieceType)
    case tactic(String)
}
