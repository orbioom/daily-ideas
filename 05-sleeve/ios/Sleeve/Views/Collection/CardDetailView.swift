import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ZStack {
            SleeveTheme.darkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Card image
                    if let data = card.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 300)
                            .clipped()
                    } else {
                        ZStack {
                            SleeveTheme.cardBg
                            VStack(spacing: 12) {
                                Image(systemName: "rectangle.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundStyle(SleeveTheme.subtleText)
                                Text("No Photo")
                                    .font(.caption)
                                    .foregroundStyle(SleeveTheme.subtleText)
                            }
                        }
                        .frame(height: 200)
                    }

                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    if !card.setName.isEmpty {
                                        Text(card.setName)
                                            .font(.subheadline)
                                            .foregroundStyle(SleeveTheme.silver)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    if card.estimatedValue > 0 {
                                        Text("$\(card.estimatedValue, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(SleeveTheme.gold)
                                    }
                                    if card.quantity > 1 {
                                        Text("x\(card.quantity)")
                                            .font(.subheadline)
                                            .foregroundStyle(SleeveTheme.subtleText)
                                    }
                                }
                            }

                            // Rarity badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(SleeveTheme.rarityColorFromString(card.rarity))
                                    .frame(width: 8, height: 8)
                                Text(card.rarity)
                                    .font(.caption)
                                    .foregroundStyle(SleeveTheme.rarityColorFromString(card.rarity))
                                if card.isFoil {
                                    Text("✦ Foil")
                                        .font(.caption)
                                        .foregroundStyle(SleeveTheme.gold)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Details grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DetailCell(label: "Game", value: card.game)
                            DetailCell(label: "Condition", value: card.condition)
                            if !card.cardNumber.isEmpty {
                                DetailCell(label: "Card #", value: card.cardNumber)
                            }
                            DetailCell(label: "Quantity", value: "\(card.quantity)")
                            if card.isGraded {
                                DetailCell(label: "Grade", value: card.gradeScore.isEmpty ? "Graded" : card.gradeScore)
                            }
                            if card.estimatedValue > 0 && card.quantity > 1 {
                                DetailCell(label: "Total Value", value: "$\(String(format: "%.2f", card.totalValue))")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Notes
                        if !card.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .sleeveSectionHeader()
                                Text(card.notes)
                                    .font(.body)
                                    .foregroundStyle(SleeveTheme.silver)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(SleeveTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Date added
                        Text("Added \(card.addedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(SleeveTheme.subtleText)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Card", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Card", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(SleeveTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddCardView(editingCard: card)
        }
        .alert("Delete Card", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(card)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(card.name)\"? This cannot be undone.")
        }
    }
}

struct DetailCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .sleeveSectionHeader()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SleeveTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: Card(name: "Charizard", setName: "Base Set", rarity: CardRarity.rare.rawValue, estimatedValue: 150.0, isFoil: true))
    }
}
