import SwiftUI
import SwiftData

struct GameSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [BingoSettings]
    @Query private var customPacks: [CustomPack]

    var callerEngine: CallerEngine
    var onStart: (String, String, [String], Int) -> Void

    @State private var selectedGameType = "number"
    @State private var selectedPackName = "Baby Shower"
    @State private var cardCount = 2

    var currentSettings: BingoSettings {
        settings.first ?? BingoSettings()
    }

    var maxCards: Int { 4 }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                Form {
                    Section("Game Type") {
                        Picker("Mode", selection: $selectedGameType) {
                            Text("🎱 Number Bingo").tag("number")
                            Text("💬 Word Bingo").tag("word")
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(BingoTheme.lightNavy)
                    }

                    if selectedGameType == "word" {
                        Section("Word Pack") {
                            ForEach(WordPackLibrary.builtInPacks) { pack in
                                Button(action: { selectedPackName = pack.name }) {
                                    HStack {
                                        Text("\(pack.emoji) \(pack.name)")
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedPackName == pack.name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(BingoTheme.gold)
                                        }
                                    }
                                }
                                .listRowBackground(BingoTheme.lightNavy)
                            }

                            if !customPacks.isEmpty {
                                ForEach(customPacks) { pack in
                                    Button(action: { selectedPackName = pack.name }) {
                                        HStack {
                                            Text("📝 \(pack.name)")
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedPackName == pack.name {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(BingoTheme.gold)
                                            }
                                        }
                                    }
                                    .listRowBackground(BingoTheme.lightNavy)
                                }
                            }
                        }
                    }

                    Section("Number of Cards") {
                        Stepper(
                            "\(cardCount) Card\(cardCount > 1 ? "s" : "")",
                            value: $cardCount,
                            in: 1...maxCards
                        )
                        .foregroundColor(.white)
                        .listRowBackground(BingoTheme.lightNavy)
                    }

                    Section {
                        Button(action: startGame) {
                            HStack {
                                Spacer()
                                Label("Start Game!", systemImage: "play.fill")
                                    .font(.headline.bold())
                                    .foregroundColor(BingoTheme.navy)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(BingoTheme.gold)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BingoTheme.gold)
                }
            }
        }
    }

    private func startGame() {
        let items: [String]

        if selectedGameType == "number" {
            items = (1...75).map { n -> String in
                switch n {
                case 1...15: return "B\(n)"
                case 16...30: return "I\(n)"
                case 31...45: return "N\(n)"
                case 46...60: return "G\(n)"
                case 61...75: return "O\(n)"
                default: return "\(n)"
                }
            }.shuffled()
        } else {
            if let pack = WordPackLibrary.builtInPacks.first(where: { $0.name == selectedPackName }) {
                items = pack.words.shuffled()
            } else if let custom = customPacks.first(where: { $0.name == selectedPackName }) {
                items = custom.words.shuffled()
            } else {
                items = WordPackLibrary.builtInPacks[0].words.shuffled()
            }
        }

        let finalPackName = selectedGameType == "number" ? "Classic Number" : selectedPackName
        onStart(selectedGameType, finalPackName, items, cardCount)
        dismiss()
    }
}
