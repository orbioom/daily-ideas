import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var callerEngine = CallerEngine()
    @Query private var settings: [BingoSettings]

    var currentSettings: BingoSettings {
        settings.first ?? BingoSettings()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(callerEngine: callerEngine)
                .tabItem {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .tag(0)

            CardGridView(callerEngine: callerEngine)
                .tabItem {
                    Label("Cards", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(1)

            PacksView()
                .tabItem {
                    Label("Packs", systemImage: "text.badge.star")
                }
                .tag(2)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(BingoTheme.gold)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(BingoTheme.navy)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct HomeView: View {
    @Bindable var callerEngine: CallerEngine
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [BingoSettings]
    @Query(sort: \SavedCard.cardIndex) private var savedCards: [SavedCard]

    @State private var showGameSetup = false
    @State private var showCelebration = false
    @State private var winningCardLabel = ""
    @State private var winningPattern = ""
    @State private var gameType = "number"
    @State private var packName = "Classic Number"
    @State private var currentGameId: String = ""

    var currentSettings: BingoSettings {
        settings.first ?? BingoSettings()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        if callerEngine.isRunning || !callerEngine.calledItems.isEmpty {
                            gameInProgressSection
                        } else {
                            notStartedSection
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Bingo!")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if callerEngine.isRunning || !callerEngine.calledItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("New Game") {
                            endGame()
                        }
                        .foregroundColor(BingoTheme.red)
                    }
                }
            }
            .sheet(isPresented: $showGameSetup) {
                GameSetupView(callerEngine: callerEngine, onStart: startGame)
            }
            .sheet(isPresented: $showCelebration) {
                CelebrationView(
                    cardLabel: winningCardLabel,
                    pattern: winningPattern,
                    calledCount: callerEngine.calledItems.count
                ) {
                    showCelebration = false
                } onNewGame: {
                    showCelebration = false
                    endGame()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            if callerEngine.isRunning || !callerEngine.calledItems.isEmpty {
                if !callerEngine.lastCalled.isEmpty {
                    BallView(text: callerEngine.lastCalled, size: 100)
                        .padding(.top, 8)
                }

                Text("Called: \(callerEngine.calledItems.count) / \(callerEngine.totalItems)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var gameInProgressSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    callerEngine.callNext()
                    checkAllCardsForWin()
                }) {
                    Label("Call Next", systemImage: "arrow.right.circle.fill")
                        .font(.headline.bold())
                        .foregroundColor(BingoTheme.navy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(callerEngine.remainingItems.isEmpty ? BingoTheme.gold.opacity(0.4) : BingoTheme.gold)
                        .cornerRadius(12)
                }
                .disabled(callerEngine.remainingItems.isEmpty)

                if callerEngine.isPaused {
                    Button(action: { callerEngine.resume() }) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(BingoTheme.gold)
                            .frame(width: 50, height: 50)
                            .background(BingoTheme.lightNavy)
                            .cornerRadius(10)
                    }
                } else if currentSettings.autoAdvance {
                    Button(action: { callerEngine.pause() }) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .foregroundColor(BingoTheme.gold)
                            .frame(width: 50, height: 50)
                            .background(BingoTheme.lightNavy)
                            .cornerRadius(10)
                    }
                }
            }

            CalledItemsView(calledItems: callerEngine.calledItems, gameType: gameType)
        }
    }

    private var notStartedSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "b.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(BingoTheme.gold)

                Text("Ready to Play?")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Classic number bingo, word bingo, or custom themes — your choice!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 32)

            Button("Start New Game") {
                showGameSetup = true
            }
            .buttonStyle(GoldButtonStyle())
        }
    }

    func startGame(type: String, pack: String, items: [String], cardCount: Int) {
        gameType = type
        packName = pack
        currentGameId = UUID().uuidString

        for card in savedCards {
            modelContext.delete(card)
        }

        for i in 0..<cardCount {
            let grid: [[String]]
            if type == "number" {
                grid = CardGenerator.generateNumberCard()
            } else {
                grid = CardGenerator.generateWordCard(words: items)
            }
            let card = SavedCard(
                gameId: currentGameId,
                cells: grid,
                cardIndex: i,
                label: "Card \(i + 1)"
            )
            modelContext.insert(card)
        }
        try? modelContext.save()

        callerEngine.speechEnabled = currentSettings.speechEnabled
        callerEngine.callDelay = currentSettings.callDelaySeconds
        callerEngine.startGame(items: items)

        if currentSettings.autoAdvance {
            callerEngine.startAutoAdvance()
        }

        callerEngine.onItemCalled = { [self] _ in
            checkAllCardsForWin()
        }
    }

    func endGame() {
        let itemsCopy = callerEngine.calledItems
        let countCopy = itemsCopy.count
        let wasComplete = showCelebration

        callerEngine.reset()
        callerEngine.stopAutoAdvance()

        if !itemsCopy.isEmpty {
            let game = BingoGame(gameType: gameType, packName: packName)
            game.calledItems = itemsCopy
            game.isComplete = wasComplete
            game.callCount = countCopy
            modelContext.insert(game)
        }

        for card in savedCards {
            modelContext.delete(card)
        }
        try? modelContext.save()
    }

    private func checkAllCardsForWin() {
        let patterns = currentSettings.winPatterns
        for card in savedCards {
            let wins = WinDetector.checkWins(
                grid: card.cells,
                marked: card.marked,
                enabledPatterns: patterns
            )
            if !wins.isEmpty {
                winningCardLabel = card.label
                winningPattern = wins.first?.name ?? "row"
                callerEngine.announceWinner(cardLabel: card.label)
                callerEngine.pause()
                showCelebration = true

                if currentSettings.hapticsEnabled {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                return
            }
        }
    }
}
