import SwiftUI
import SwiftData

struct DrinksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CaffeineSource.name) private var sources: [CaffeineSource]
    @State private var showAdd = false
    @State private var editing: CaffeineSource?
    @State private var search = ""

    private var grouped: [(category: DrinkCategory, items: [CaffeineSource])] {
        let filtered = sources.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
        return DrinkCategory.allCases.compactMap { cat in
            let items = filtered.filter { $0.category == cat }
            return items.isEmpty ? nil : (category: cat, items: items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sources.isEmpty {
                    EmptyStateView(icon: "cup.and.saucer", title: "No drinks yet",
                                   message: "Add the drinks you have often, with their caffeine in mg, for one-tap logging.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(grouped, id: \.category) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: group.category.icon).font(.caption)
                                            .foregroundStyle(Brand.text2).accessibilityHidden(true)
                                        Eyebrow(text: group.category.rawValue)
                                    }
                                    .padding(.horizontal, 4)
                                    ForEach(group.items) { src in
                                        Button { editing = src } label: { row(src) }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Drinks")
            .searchable(text: $search, prompt: "Search drinks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add drink")
                }
            }
            .sheet(isPresented: $showAdd) { SourceEditView(source: nil) }
            .sheet(item: $editing) { SourceEditView(source: $0) }
        }
    }

    private func row(_ src: CaffeineSource) -> some View {
        HStack(spacing: 12) {
            Button {
                src.favorite.toggle(); try? context.save(); Haptics.selection()
            } label: {
                Image(systemName: src.favorite ? "star.fill" : "star")
                    .foregroundStyle(src.favorite ? Brand.warn : Brand.text3)
            }
            .accessibilityLabel(src.favorite ? "Unfavorite" : "Favorite for quick add")
            VStack(alignment: .leading, spacing: 1) {
                Text(src.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                if !src.serving.isEmpty {
                    Text(src.serving).font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            Text(Fmt.mg(src.mg)).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 12)
    }
}
