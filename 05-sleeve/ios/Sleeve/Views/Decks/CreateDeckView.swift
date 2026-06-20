import SwiftUI
import SwiftData

struct CreateDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var game: CardGame = .pokemon
    @State private var format = ""
    @State private var notes = ""

    var formats: [String] {
        let gameFormats = game.formats
        if format.isEmpty || !gameFormats.contains(format) {
            // Reset format selection on game change
        }
        return gameFormats
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                Form {
                    Section {
                        TextField("Deck Name", text: $name)
                            .foregroundStyle(.white)
                    } header: {
                        Text("Name").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    Section {
                        Picker("Game", selection: $game) {
                            ForEach(CardGame.allCases) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)
                        .onChange(of: game) { _, _ in
                            format = game.formats.first ?? ""
                        }

                        Picker("Format", selection: $format) {
                            ForEach(game.formats, id: \.self) { f in
                                Text(f).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)
                    } header: {
                        Text("Game & Format").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    Section {
                        TextEditor(text: $notes)
                            .foregroundStyle(.white)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    } header: {
                        Text("Notes").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SleeveTheme.silver)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDeck()
                    }
                    .foregroundStyle(name.isEmpty ? SleeveTheme.subtleText : SleeveTheme.accent)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                format = game.formats.first ?? ""
            }
        }
        .preferredColorScheme(.dark)
    }

    private func createDeck() {
        let deck = Deck(
            name: name,
            game: game.rawValue,
            format: format.isEmpty ? (game.formats.first ?? "Custom") : format,
            notes: notes
        )
        modelContext.insert(deck)
        dismiss()
    }
}

#Preview {
    CreateDeckView()
}
