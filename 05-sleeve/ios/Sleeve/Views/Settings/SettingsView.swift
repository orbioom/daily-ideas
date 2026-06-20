import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @Query private var decks: [Deck]
    @Query private var wants: [WantCard]

    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("defaultGame") private var defaultGame = CardGame.pokemon.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    @State private var showingClearAlert = false
    @State private var showingOnboarding = false

    let currencies = ["$", "€", "£", "¥", "A$", "C$"]

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                Form {
                    // Display
                    Section {
                        Picker("Currency", selection: $currencySymbol) {
                            ForEach(currencies, id: \.self) { symbol in
                                Text("\(symbol) — \(currencyName(symbol))").tag(symbol)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)

                        Picker("Default Game", selection: $defaultGame) {
                            ForEach(CardGame.allCases) { game in
                                Text(game.rawValue).tag(game.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)
                    } header: {
                        Text("Display").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Collection summary
                    Section {
                        HStack {
                            Text("Cards in Collection")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(cards.count)")
                                .foregroundStyle(SleeveTheme.subtleText)
                        }
                        HStack {
                            Text("Decks")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(decks.count)")
                                .foregroundStyle(SleeveTheme.subtleText)
                        }
                        HStack {
                            Text("Want List Items")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(wants.count)")
                                .foregroundStyle(SleeveTheme.subtleText)
                        }
                    } header: {
                        Text("Collection").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // About
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(SleeveTheme.subtleText)
                        }
                        Button {
                            showingOnboarding = true
                        } label: {
                            Text("View Intro")
                                .foregroundStyle(SleeveTheme.accent)
                        }
                    } header: {
                        Text("About").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Danger zone
                    Section {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Collection Data")
                            }
                        }
                    } header: {
                        Text("Data").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Clear All Data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Everything", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all \(cards.count) cards, \(decks.count) decks, and \(wants.count) want list items. This cannot be undone.")
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .preferredColorScheme(.dark)
    }

    private func currencyName(_ symbol: String) -> String {
        switch symbol {
        case "$":  return "US Dollar"
        case "€":  return "Euro"
        case "£":  return "British Pound"
        case "¥":  return "Japanese Yen"
        case "A$": return "Australian Dollar"
        case "C$": return "Canadian Dollar"
        default:   return symbol
        }
    }

    private func clearAllData() {
        cards.forEach { modelContext.delete($0) }
        decks.forEach { modelContext.delete($0) }
        wants.forEach { modelContext.delete($0) }
    }
}

#Preview {
    SettingsView()
}
