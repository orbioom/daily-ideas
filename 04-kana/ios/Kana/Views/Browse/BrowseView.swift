import SwiftUI
import SwiftData

enum BrowseSortOrder: String, CaseIterable {
    case dueDate = "Due Date"
    case accuracy = "Accuracy"
    case character = "Character"
}

struct BrowseView: View {
    @Query private var allCards: [KanaCard]
    @State private var searchText: String = ""
    @State private var selectedType: CardType? = nil
    @State private var sortOrder: BrowseSortOrder = .character

    private var filteredCards: [KanaCard] {
        var cards = allCards

        if let type = selectedType {
            cards = cards.filter { $0.cardType == type }
        }

        if !searchText.isEmpty {
            cards = cards.filter {
                $0.character.localizedCaseInsensitiveContains(searchText) ||
                $0.romaji.localizedCaseInsensitiveContains(searchText) ||
                $0.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .dueDate:
            cards.sort { $0.srsDueDate < $1.srsDueDate }
        case .accuracy:
            cards.sort { $0.accuracy < $1.accuracy }
        case .character:
            cards.sort { $0.character < $1.character }
        }

        return cards
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        TypeFilterChip(label: "All", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(CardType.allCases, id: \.self) { type in
                            TypeFilterChip(
                                label: type.displayName,
                                color: KanaTheme.cardTypeColor(type),
                                isSelected: selectedType == type
                            ) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                Divider()

                List(filteredCards) { card in
                    NavigationLink(destination: CardDetailView(card: card)) {
                        CardRowView(card: card)
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search characters or romaji")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            ForEach(BrowseSortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
}

// MARK: - Card Row View

struct CardRowView: View {
    let card: KanaCard

    var body: some View {
        HStack(spacing: 14) {
            // Character display
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(KanaTheme.cardTypeColor(card.cardType).opacity(0.1))
                    .frame(width: 56, height: 56)
                Text(card.character)
                    .font(.system(size: 28, weight: .regular))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.romaji)
                    .font(.headline)

                if !card.meaning.isEmpty {
                    Text(card.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    // Type badge
                    HStack(spacing: 3) {
                        Image(systemName: KanaTheme.cardTypeIcon(card.cardType))
                            .font(.caption2)
                        Text(card.cardType.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(KanaTheme.cardTypeColor(card.cardType))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(KanaTheme.cardTypeColor(card.cardType).opacity(0.12))
                    )

                    if card.isLearned {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text("Learned")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.12))
                        )
                    } else if card.isDue {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("Due")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.12))
                        )
                    }
                }
            }

            Spacer()

            // Accuracy
            if card.totalReviews > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(card.accuracy * 100))%")
                        .font(.headline)
                        .foregroundStyle(accuracyColor(card.accuracy))
                    Text("accuracy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("New")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: KanaCard

    private var nextDueText: String {
        if card.isDue {
            return "Due now"
        }
        let days = Calendar.current.dateComponents([.day], from: Date.now, to: card.srsDueDate).day ?? 0
        if days == 1 {
            return "Due in 1 day"
        }
        return "Due in \(days) days"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Character card
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(KanaTheme.cardTypeColor(card.cardType).opacity(0.1))

                    VStack(spacing: 12) {
                        Text(card.character)
                            .font(.system(size: 100, weight: .regular))

                        Text(card.romaji)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(KanaTheme.cardTypeColor(card.cardType))

                        if !card.meaning.isEmpty {
                            Text(card.meaning)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(32)
                }
                .padding(.horizontal)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailStatCard(
                        title: "Accuracy",
                        value: card.totalReviews > 0 ? "\(Int(card.accuracy * 100))%" : "—",
                        icon: "target",
                        color: card.totalReviews > 0 ? accuracyColor(card.accuracy) : .secondary
                    )
                    DetailStatCard(
                        title: "Total Reviews",
                        value: "\(card.totalReviews)",
                        icon: "repeat",
                        color: .blue
                    )
                    DetailStatCard(
                        title: "SRS Interval",
                        value: "\(card.srsInterval) day\(card.srsInterval == 1 ? "" : "s")",
                        icon: "calendar",
                        color: KanaTheme.goldAccent
                    )
                    DetailStatCard(
                        title: "Next Review",
                        value: nextDueText,
                        icon: "clock",
                        color: card.isDue ? .orange : .green
                    )
                    DetailStatCard(
                        title: "Correct",
                        value: "\(card.correctReviews)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    DetailStatCard(
                        title: "Incorrect",
                        value: "\(card.totalReviews - card.correctReviews)",
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)

                // Status
                HStack(spacing: 12) {
                    if card.isLearned {
                        Label("Learned", systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.12))
                            )
                    }

                    HStack(spacing: 4) {
                        Image(systemName: KanaTheme.cardTypeIcon(card.cardType))
                        Text(card.cardType.displayName)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(KanaTheme.cardTypeColor(card.cardType))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KanaTheme.cardTypeColor(card.cardType).opacity(0.12))
                    )
                }

                if let lastReview = card.lastReviewDate {
                    Text("Last reviewed \(lastReview, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
        .navigationTitle(card.character)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return .red
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
