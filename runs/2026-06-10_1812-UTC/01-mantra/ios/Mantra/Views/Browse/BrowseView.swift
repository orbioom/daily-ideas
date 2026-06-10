import SwiftUI
import SwiftData

struct BrowseView: View {
    @Query private var affirmations: [Affirmation]

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private func count(_ cat: MantraCategory) -> Int {
        affirmations.filter { $0.category == cat }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(MantraCategory.allCases) { cat in
                            NavigationLink(value: cat) {
                                categoryTile(cat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Browse")
            .navigationDestination(for: MantraCategory.self) { cat in
                CategoryListView(category: cat)
            }
        }
    }

    private func categoryTile(_ cat: MantraCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: cat.icon)
                .font(.title2)
                .foregroundStyle(cat.tint)
                .frame(width: 46, height: 46)
                .background(cat.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(cat.rawValue)
                .font(.headline)
                .foregroundStyle(Brand.text)
            Text("\(count(cat)) affirmations")
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cat.rawValue), \(count(cat)) affirmations")
    }
}

struct CategoryListView: View {
    let category: MantraCategory
    @Environment(\.modelContext) private var context
    @Query private var affirmations: [Affirmation]

    init(category: MantraCategory) {
        self.category = category
        let raw = category.rawValue
        _affirmations = Query(filter: #Predicate { $0.categoryRaw == raw },
                              sort: \Affirmation.createdAt)
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if affirmations.isEmpty {
                EmptyStateView(icon: category.icon, title: "Nothing here yet",
                               message: "Add your own \(category.rawValue.lowercased()) affirmation from the Mine tab.")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(affirmations) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Text(item.text)
                                    .font(.body)
                                    .foregroundStyle(Brand.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    item.isFavorite.toggle()
                                    Haptics.selection()
                                    try? context.save()
                                } label: {
                                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                        .foregroundStyle(item.isFavorite ? Brand.danger : Brand.text3)
                                }
                                .accessibilityLabel(item.isFavorite ? "Unfavorite" : "Favorite")
                            }
                            .glassCard()
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
