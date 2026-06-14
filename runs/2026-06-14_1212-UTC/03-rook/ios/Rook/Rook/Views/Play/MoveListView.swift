import SwiftUI

/// A compact, scrollable two-column move list (white / black) by move number.
struct MoveListView: View {
    let moves: [Move]

    private struct Row: Identifiable {
        let id: Int
        let number: Int
        let white: String
        let black: String?
    }

    private var rows: [Row] {
        var result: [Row] = []
        var i = 0
        var number = 1
        while i < moves.count {
            let white = moves[i].uci
            let black = (i + 1 < moves.count) ? moves[i + 1].uci : nil
            result.append(Row(id: number, number: number, white: white, black: black))
            i += 2
            number += 1
        }
        return result
    }

    var body: some View {
        if moves.isEmpty {
            Text("No moves yet. Tap a piece to begin.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(rows) { row in
                            HStack(spacing: 8) {
                                Text("\(row.number).")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkFaint)
                                    .frame(width: 30, alignment: .leading)
                                Text(row.white)
                                    .font(Theme.rounded(14, .medium).monospaced())
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 64, alignment: .leading)
                                if let black = row.black {
                                    Text(black)
                                        .font(Theme.rounded(14, .medium).monospaced())
                                        .foregroundStyle(Theme.ink)
                                        .frame(width: 64, alignment: .leading)
                                }
                                Spacer()
                            }
                            .id(row.id)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onChange(of: moves.count) { _, _ in
                    if let last = rows.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }
}
