import SwiftUI

struct LevelCardView: View {
    let level: SokobanLevel
    let record: PushRecord?

    private var isSolved: Bool { record != nil }

    private var stars: Int {
        guard let record else { return 0 }
        let moves = record.bestMoves
        if moves <= level.parMoves { return 3 }
        if moves <= Int(Double(level.parMoves) * 1.5) { return 2 }
        return 1
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSolved ? PushTheme.packColor(level.packId).opacity(0.12) : PushTheme.floor)
                    .frame(height: 88)

                VStack(spacing: 4) {
                    Text("\(level.id % 10 == 0 ? 10 : level.id % 10)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(isSolved ? PushTheme.packColor(level.packId) : PushTheme.wall.opacity(0.4))

                    if isSolved {
                        HStack(spacing: 2) {
                            ForEach(1...3, id: \.self) { star in
                                Image(systemName: star <= stars ? "star.fill" : "star")
                                    .font(.system(size: 11))
                                    .foregroundColor(star <= stars ? .yellow : PushTheme.wall.opacity(0.2))
                            }
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(PushTheme.wall.opacity(0.2))
                            .opacity(0) // not locked — just spacing placeholder
                    }
                }
            }

            VStack(spacing: 2) {
                Text(level.title)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundColor(PushTheme.wall.opacity(0.7))
                    .lineLimit(1)

                if let record {
                    Text("Best: \(record.bestMoves)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(PushTheme.wall.opacity(0.45))
                } else {
                    Text("Par: \(level.parMoves)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(PushTheme.wall.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 4)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var desc = "Level \(level.id), \(level.title)."
        if isSolved {
            desc += " Completed with \(record!.bestMoves) moves."
            desc += " \(stars) star\(stars == 1 ? "" : "s")."
        } else {
            desc += " Not yet solved. Par: \(level.parMoves) moves."
        }
        return desc
    }
}

#Preview {
    HStack {
        LevelCardView(level: allLevels[0], record: nil)
        LevelCardView(level: allLevels[1], record: PushRecord(levelId: 2, packId: 1, bestMoves: 4, bestPushes: 1))
    }
    .padding()
    .background(PushTheme.background)
}
