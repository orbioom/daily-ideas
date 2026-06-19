import SwiftUI
import SwiftData

struct MainMenuView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Query private var preferences: [AppPreferences]
    @Environment(\.modelContext) private var modelContext

    @State private var showingGame = false
    @State private var showingStats = false
    @State private var showingRules = false
    @State private var showingSettings = false
    @State private var gameMode: String = "singlePlayer"

    private var prefs: AppPreferences {
        preferences.first ?? AppPreferences()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnteTheme.feltGreenDark
                    .ignoresSafeArea()

                // Subtle felt texture overlay
                Canvas { ctx, size in
                    for _ in 0..<800 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let rect = CGRect(x: x, y: y, width: 1, height: 1)
                        ctx.fill(Path(rect), with: .color(.white.opacity(0.03)))
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Logo header
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("♠")
                                .font(.system(size: 48))
                                .foregroundColor(AnteTheme.gold)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("ANTE")
                                    .font(.system(size: 42, weight: .black, design: .serif))
                                    .foregroundColor(AnteTheme.gold)
                                Text("GIN RUMMY")
                                    .font(.system(size: 13, weight: .medium, design: .serif))
                                    .foregroundColor(AnteTheme.textSecondary)
                                    .kerning(4)
                            }
                        }

                        if !records.isEmpty {
                            let wins = records.filter { $0.playerWon }.count
                            Text("\(wins)W / \(records.count - wins)L  •  \(records.count) games played")
                                .font(.caption)
                                .foregroundColor(AnteTheme.textMuted)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Main buttons
                    VStack(spacing: 14) {
                        MenuButton(
                            title: "Single Player",
                            subtitle: "vs. CPU opponent",
                            icon: "person.fill",
                            color: AnteTheme.gold
                        ) {
                            gameMode = "singlePlayer"
                            showingGame = true
                        }

                        MenuButton(
                            title: "Pass & Play",
                            subtitle: "2 players, one device",
                            icon: "person.2.fill",
                            color: AnteTheme.gold.opacity(0.85)
                        ) {
                            gameMode = "passAndPlay"
                            showingGame = true
                        }

                        Divider()
                            .background(AnteTheme.gold.opacity(0.3))
                            .padding(.vertical, 4)

                        HStack(spacing: 14) {
                            SecondaryMenuButton(title: "Stats", icon: "chart.bar.fill") {
                                showingStats = true
                            }
                            SecondaryMenuButton(title: "Rules", icon: "book.fill") {
                                showingRules = true
                            }
                            SecondaryMenuButton(title: "Settings", icon: "gearshape.fill") {
                                showingSettings = true
                            }
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    // Recent game
                    if let last = records.first {
                        VStack(spacing: 6) {
                            Text("LAST GAME")
                                .font(.caption2)
                                .foregroundColor(AnteTheme.textMuted)
                                .kerning(2)
                            HStack(spacing: 16) {
                                Label(last.playerWon ? "Won" : "Lost", systemImage: last.playerWon ? "crown.fill" : "xmark")
                                    .foregroundColor(last.playerWon ? AnteTheme.gold : .red.opacity(0.8))
                                    .font(.caption.weight(.semibold))
                                Text("\(last.playerScore) – \(last.opponentScore)")
                                    .foregroundColor(AnteTheme.textSecondary)
                                    .font(.caption)
                                Text("\(last.roundsPlayed) rounds")
                                    .foregroundColor(AnteTheme.textMuted)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 16)
                    }

                    Text("v1.0  •  Gin Rummy offline")
                        .font(.caption2)
                        .foregroundColor(AnteTheme.textMuted)
                        .padding(.bottom, 20)
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                GameContainerView(gameMode: gameMode)
            }
            .navigationDestination(isPresented: $showingStats) {
                StatsView()
            }
            .navigationDestination(isPresented: $showingRules) {
                RulesView()
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AnteTheme.feltGreen)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AnteTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(color)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AnteTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct SecondaryMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AnteTheme.gold)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AnteTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AnteTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AnteTheme.gold.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
