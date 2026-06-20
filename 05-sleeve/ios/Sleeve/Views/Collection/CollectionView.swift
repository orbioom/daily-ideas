import SwiftUI
import SwiftData

enum CollectionSort: String, CaseIterable {
    case name     = "Name"
    case value    = "Value"
    case dateAdded = "Date Added"
}

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.addedDate, order: .reverse) private var allCards: [Card]

    @State private var searchText = ""
    @State private var selectedGame: CardGame? = nil
    @State private var sortOption: CollectionSort = .dateAdded
    @State private var isGrid = true
    @State private var showingAddCard = false

    var filteredCards: [Card] {
        var cards = allCards

        if !searchText.isEmpty {
            cards = cards.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.setName.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let game = selectedGame {
            cards = cards.filter { $0.game == game.rawValue }
        }

        switch sortOption {
        case .name:
            cards.sort { $0.name < $1.name }
        case .value:
            cards.sort { $0.totalValue > $1.totalValue }
        case .dateAdded:
            cards.sort { $0.addedDate > $1.addedDate }
        }

        return cards
    }

    var totalValue: Double {
        allCards.reduce(0) { $0 + $1.totalValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(SleeveTheme.subtleText)
                        TextField("Search cards...", text: $searchText)
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(SleeveTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedGame == nil) {
                                selectedGame = nil
                            }
                            ForEach(CardGame.allCases) { game in
                                FilterChip(title: game.rawValue, isSelected: selectedGame == game) {
                                    selectedGame = selectedGame == game ? nil : game
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    // Sort + view toggle bar
                    HStack {
                        Menu {
                            ForEach(CollectionSort.allCases, id: \.self) { sort in
                                Button(sort.rawValue) { sortOption = sort }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Sort: \(sortOption.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(SleeveTheme.silver)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(SleeveTheme.silver)
                            }
                        }

                        Spacer()

                        Text("\(filteredCards.count) cards")
                            .font(.caption)
                            .foregroundStyle(SleeveTheme.subtleText)

                        Spacer()

                        Button {
                            isGrid.toggle()
                        } label: {
                            Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                                .foregroundStyle(SleeveTheme.silver)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Card grid/list
                    if filteredCards.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundStyle(SleeveTheme.subtleText)
                            Text(allCards.isEmpty ? "No cards yet" : "No results")
                                .font(.title3)
                                .foregroundStyle(.white)
                            if allCards.isEmpty {
                                Text("Tap + to add your first card")
                                    .font(.subheadline)
                                    .foregroundStyle(SleeveTheme.subtleText)
                            }
                        }
                        Spacer()
                    } else if isGrid {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(filteredCards) { card in
                                    NavigationLink(destination: CardDetailView(card: card)) {
                                        CardGridCell(card: card)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 80)
                        }
                    } else {
                        List {
                            ForEach(filteredCards) { card in
                                NavigationLink(destination: CardDetailView(card: card)) {
                                    CardListRow(card: card)
                                }
                                .listRowBackground(SleeveTheme.cardBg)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddCard = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(SleeveTheme.accent)
                                .clipShape(Circle())
                                .shadow(color: SleeveTheme.accent.opacity(0.5), radius: 8, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("$\(totalValue, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(SleeveTheme.gold)
                        Text("est. value")
                            .font(.caption2)
                            .foregroundStyle(SleeveTheme.subtleText)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sub Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : SleeveTheme.silver)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? SleeveTheme.accent : SleeveTheme.cardBg)
                .clipShape(Capsule())
        }
    }
}

struct CardGridCell: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image or placeholder
            if let data = card.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SleeveTheme.darkBg)
                        .frame(height: 100)
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.title)
                        .foregroundStyle(SleeveTheme.subtleText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(SleeveTheme.rarityColorFromString(card.rarity))
                        .frame(width: 6, height: 6)
                    Text(card.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Text(card.setName.isEmpty ? "—" : card.setName)
                    .font(.caption2)
                    .foregroundStyle(SleeveTheme.subtleText)
                    .lineLimit(1)

                HStack {
                    if card.estimatedValue > 0 {
                        Text("$\(card.estimatedValue, specifier: "%.2f")")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(SleeveTheme.gold)
                    }
                    Spacer()
                    if card.quantity > 1 {
                        Text("x\(card.quantity)")
                            .font(.caption2)
                            .foregroundStyle(SleeveTheme.silver)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .cardCellBackground()
    }
}

struct CardListRow: View {
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(SleeveTheme.rarityColorFromString(card.rarity))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(card.setName.isEmpty ? card.game : "\(card.setName) · \(card.game)")
                    .font(.caption)
                    .foregroundStyle(SleeveTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if card.estimatedValue > 0 {
                    Text("$\(card.estimatedValue, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(SleeveTheme.gold)
                }
                Text(card.conditionEnum?.abbreviation ?? "—")
                    .font(.caption2)
                    .foregroundStyle(SleeveTheme.subtleText)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CollectionView()
}
