import SwiftUI
import SwiftData

struct OutfitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]
    @Query(filter: #Predicate<ClothingItem> { !$0.archived }) private var items: [ClothingItem]

    @State private var editing: Outfit?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if outfits.isEmpty {
                    EmptyStateView(
                        icon: "hanger",
                        title: "No outfits yet",
                        message: items.isEmpty
                            ? "Add some pieces to your closet first, then combine them into outfits here."
                            : "Tap + to build your first outfit from pieces in your closet."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(outfits) { outfit in
                                NavigationLink(value: outfit) { OutfitCard(outfit: outfit) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Outfits")
            .navigationDestination(for: Outfit.self) { OutfitDetailView(outfit: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let o = Outfit(name: "")
                        context.insert(o); editing = o
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New outfit")
                        .disabled(items.isEmpty)
                }
            }
            .sheet(item: $editing) { OutfitEditorView(outfit: $0, isNew: true) }
        }
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(outfit.name.isEmpty ? "Untitled outfit" : outfit.name)
                    .font(.headline).foregroundStyle(Brand.text)
                if outfit.favorite {
                    Image(systemName: "heart.fill").font(.caption).foregroundStyle(Color(hex: 0x9E5E7E))
                }
                Spacer()
                Text("\(outfit.items.count) pieces").font(.caption).foregroundStyle(Brand.text3)
            }
            if outfit.items.isEmpty {
                Text("No pieces added").font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(outfit.items.prefix(8)) { item in
                            ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 56, corner: 12)
                        }
                    }
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(outfit.name), \(outfit.items.count) pieces")
    }
}
