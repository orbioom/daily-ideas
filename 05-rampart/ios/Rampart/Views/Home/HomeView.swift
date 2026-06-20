import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var records: [GameRecord]
    @Query private var settingsQuery: [RampartSettings]
    @State private var showingSettings = false

    private var hasPro: Bool { settingsQuery.first?.hasPro ?? false }
    private var totalWins: Int { records.filter(\.won).count }
    private var highScore: Int { records.map(\.score).max() ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                RampartTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RampartTheme.spacingL) {
                        // Hero header
                        VStack(spacing: RampartTheme.spacingS) {
                            Text("🏰")
                                .font(.system(size: 64))
                                .shadow(color: RampartTheme.gold.opacity(0.4), radius: 16)
                            Text("Rampart")
                                .font(.system(size: 40, weight: .black, design: .serif))
                                .foregroundStyle(RampartTheme.gold)
                            Text("Defend the walls.")
                                .font(RampartTheme.bodyFont)
                                .foregroundStyle(RampartTheme.textSecondary)
                                .italic()
                        }
                        .padding(.top, RampartTheme.spacingL)

                        // Stats row
                        if totalWins > 0 || highScore > 0 {
                            HStack(spacing: RampartTheme.spacingM) {
                                HomeStatBadge(value: "\(totalWins)", label: "Victories", icon: "crown.fill", color: RampartTheme.gold)
                                HomeStatBadge(value: "\(highScore)", label: "High Score", icon: "star.fill", color: .yellow)
                                HomeStatBadge(value: "\(records.count)", label: "Games", icon: "flag.fill", color: .orange)
                            }
                        }

                        // Map cards
                        VStack(spacing: 10) {
                            Text("Choose Map")
                                .font(RampartTheme.labelFont)
                                .foregroundStyle(RampartTheme.textTertiary)
                                .textCase(.uppercase)
                                .tracking(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(GameMap.all) { map in
                                let locked = isLocked(map: map)
                                NavigationLink(destination: GameContainerView(map: map)) {
                                    HomeMapCard(
                                        map: map,
                                        bestScore: bestScore(for: map.id),
                                        isLocked: locked
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(locked)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, RampartTheme.spacingL)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(RampartTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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

private struct HomeStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(RampartTheme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(RampartTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RampartTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: RampartTheme.radiusM))
    }
}

private struct HomeMapCard: View {
    let map: GameMap
    let bestScore: Int
    let isLocked: Bool

    var body: some View {
        HStack(spacing: RampartTheme.spacingM) {
            Text(mapEmoji(map.id))
                .font(.system(size: 32))
                .opacity(isLocked ? 0.4 : 1.0)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(map.name)
                        .font(RampartTheme.headlineFont)
                        .foregroundStyle(isLocked ? RampartTheme.textTertiary : RampartTheme.textPrimary)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(RampartTheme.gold)
                    }
                }

                // Difficulty stars
                HStack(spacing: 3) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= map.difficulty ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundStyle(i <= map.difficulty ? RampartTheme.gold : RampartTheme.textTertiary)
                    }
                }

                if isLocked {
                    Text("Requires Pro — $3.99")
                        .font(RampartTheme.captionFont)
                        .foregroundStyle(RampartTheme.gold.opacity(0.7))
                } else if bestScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text("Best: \(bestScore)")
                            .font(RampartTheme.captionFont)
                            .foregroundStyle(RampartTheme.textSecondary)
                    }
                } else {
                    Text("Not played yet")
                        .font(RampartTheme.captionFont)
                        .foregroundStyle(RampartTheme.textTertiary)
                }
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RampartTheme.gold)
            }
        }
        .padding(RampartTheme.spacingM)
        .background(RampartTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: RampartTheme.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: RampartTheme.radiusM)
                .stroke(RampartTheme.gold.opacity(isLocked ? 0.1 : 0.25), lineWidth: 1)
        )
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
