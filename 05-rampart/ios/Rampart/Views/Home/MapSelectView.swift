import SwiftUI
import SwiftData

struct MapSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [GameRecord]
    @Query private var settingsQuery: [RampartSettings]
    let onSelect: (GameMap) -> Void

    private var hasPro: Bool { settingsQuery.first?.hasPro ?? false }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.172, green: 0.141, blue: 0.086)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(GameMap.all) { map in
                            MapCard(
                                map: map,
                                bestScore: bestScore(for: map.id),
                                isLocked: isLocked(map: map),
                                onTap: {
                                    if !isLocked(map: map) {
                                        onSelect(map)
                                        dismiss()
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                }
            }
        }
    }

    private func bestScore(for mapID: Int) -> Int {
        records.filter { $0.mapID == mapID }.map(\.score).max() ?? 0
    }

    private func isLocked(map: GameMap) -> Bool {
        (map.id == 4 || map.id == 5) && !hasPro
    }
}

private struct MapCard: View {
    let map: GameMap
    let bestScore: Int
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Map icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isLocked ? Color.gray.opacity(0.3) : Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.2))
                        .frame(width: 56, height: 56)
                    Text(mapEmoji(map.id))
                        .font(.system(size: 28))
                        .opacity(isLocked ? 0.4 : 1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(map.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isLocked ? .white.opacity(0.4) : .white)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                        }
                    }

                    StarRating(stars: map.difficulty, maxStars: 3)

                    if bestScore > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text("Best: \(bestScore)")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } else if !isLocked {
                        Text("Not played yet")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text("Requires Pro")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.7))
                    }
                }

                Spacer()

                if !isLocked {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.831, green: 0.686, blue: 0.216).opacity(isLocked ? 0.1 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private func mapEmoji(_ id: Int) -> String {
        switch id {
        case 1: return "🏰"
        case 2: return "🌊"
        case 3: return "🌲"
        case 4: return "⛰️"
        case 5: return "🐉"
        default: return "🗺️"
        }
    }
}
