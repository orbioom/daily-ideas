import SwiftUI
import SwiftData

struct CardGridView: View {
    @Bindable var callerEngine: CallerEngine
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedCard.cardIndex) private var savedCards: [SavedCard]
    @Query private var settings: [BingoSettings]

    var currentSettings: BingoSettings {
        settings.first ?? BingoSettings()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                if savedCards.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.grid.2x2")
                            .font(.system(size: 60))
                            .foregroundColor(BingoTheme.gold.opacity(0.5))
                        Text("No Active Game")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Start a new game from the Play tab to see your cards here.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        let columns = savedCards.count <= 1 ? 1 : 2
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns),
                            spacing: 12
                        ) {
                            ForEach(savedCards) { card in
                                BingoCardView(
                                    card: card,
                                    calledItems: callerEngine.calledItems,
                                    enabledPatterns: currentSettings.winPatterns,
                                    hapticsEnabled: currentSettings.hapticsEnabled
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cards")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
