import SwiftUI
import SwiftData
import PhotosUI

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Editing mode
    var editingCard: Card? = nil

    // Form fields
    @State private var name = ""
    @State private var setName = ""
    @State private var cardNumber = ""
    @State private var game: CardGame = .pokemon
    @State private var rarity: CardRarity = .common
    @State private var condition: CardCondition = .nearMint
    @State private var quantity = 1
    @State private var estimatedValue = ""
    @State private var isFoil = false
    @State private var isGraded = false
    @State private var gradeScore = ""
    @State private var notes = ""
    @State private var imageData: Data? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil

    @AppStorage("defaultGame") private var defaultGame = CardGame.pokemon.rawValue

    var isEditing: Bool { editingCard != nil }

    init(editingCard: Card? = nil) {
        self.editingCard = editingCard
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                Form {
                    // Game
                    Section {
                        Picker("Game", selection: $game) {
                            ForEach(CardGame.allCases) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)
                    } header: {
                        Text("Game").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Card info
                    Section {
                        TextField("Card Name", text: $name)
                            .foregroundStyle(.white)
                        TextField("Set Name", text: $setName)
                            .foregroundStyle(.white)
                        TextField("Card Number (e.g. 025/165)", text: $cardNumber)
                            .foregroundStyle(.white)
                    } header: {
                        Text("Card Info").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Details
                    Section {
                        Picker("Rarity", selection: $rarity) {
                            ForEach(CardRarity.allCases) { r in
                                HStack {
                                    Circle()
                                        .fill(SleeveTheme.rarityColor(r))
                                        .frame(width: 8, height: 8)
                                    Text(r.rawValue)
                                }
                                .tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)

                        Picker("Condition", selection: $condition) {
                            ForEach(CardCondition.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)

                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                            .foregroundStyle(.white)

                        HStack {
                            Text("Est. Value")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("$")
                                .foregroundStyle(SleeveTheme.subtleText)
                            TextField("0.00", text: $estimatedValue)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .frame(width: 80)
                        }
                    } header: {
                        Text("Details").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Flags
                    Section {
                        Toggle("Foil / Holo", isOn: $isFoil)
                            .tint(SleeveTheme.accent)
                        Toggle("Graded Card", isOn: $isGraded)
                            .tint(SleeveTheme.accent)
                        if isGraded {
                            TextField("Grade (e.g. PSA 9, BGS 9.5)", text: $gradeScore)
                                .foregroundStyle(.white)
                        }
                    } header: {
                        Text("Flags").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Photo
                    Section {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                if let data = imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(SleeveTheme.darkBg)
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "camera")
                                            .foregroundStyle(SleeveTheme.subtleText)
                                    }
                                }
                                Text(imageData == nil ? "Add Photo" : "Change Photo")
                                    .foregroundStyle(SleeveTheme.accent)
                                Spacer()
                                if imageData != nil {
                                    Button("Remove") {
                                        imageData = nil
                                        selectedPhoto = nil
                                    }
                                    .foregroundStyle(.red)
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data),
                                       let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                                        imageData = jpegData
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Photo").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    // Notes
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
            .navigationTitle(isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SleeveTheme.silver)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveCard()
                    }
                    .foregroundStyle(name.isEmpty ? SleeveTheme.subtleText : SleeveTheme.accent)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear { populateIfEditing() }
        }
        .preferredColorScheme(.dark)
    }

    private func populateIfEditing() {
        guard let card = editingCard else {
            // Set default game
            if let g = CardGame(rawValue: defaultGame) { game = g }
            return
        }
        name = card.name
        setName = card.setName
        cardNumber = card.cardNumber
        game = CardGame(rawValue: card.game) ?? .pokemon
        rarity = CardRarity(rawValue: card.rarity) ?? .common
        condition = CardCondition(rawValue: card.condition) ?? .nearMint
        quantity = card.quantity
        estimatedValue = card.estimatedValue > 0 ? String(format: "%.2f", card.estimatedValue) : ""
        isFoil = card.isFoil
        isGraded = card.isGraded
        gradeScore = card.gradeScore
        notes = card.notes
        imageData = card.imageData
    }

    private func saveCard() {
        let value = Double(estimatedValue) ?? 0.0
        if let card = editingCard {
            card.name = name
            card.setName = setName
            card.cardNumber = cardNumber
            card.game = game.rawValue
            card.rarity = rarity.rawValue
            card.condition = condition.rawValue
            card.quantity = quantity
            card.estimatedValue = value
            card.isFoil = isFoil
            card.isGraded = isGraded
            card.gradeScore = gradeScore
            card.notes = notes
            card.imageData = imageData
        } else {
            let card = Card(
                name: name,
                setName: setName,
                cardNumber: cardNumber,
                game: game.rawValue,
                rarity: rarity.rawValue,
                condition: condition.rawValue,
                quantity: quantity,
                estimatedValue: value,
                isFoil: isFoil,
                isGraded: isGraded,
                gradeScore: gradeScore,
                notes: notes,
                imageData: imageData
            )
            modelContext.insert(card)
        }
        dismiss()
    }
}

#Preview {
    AddCardView()
}
