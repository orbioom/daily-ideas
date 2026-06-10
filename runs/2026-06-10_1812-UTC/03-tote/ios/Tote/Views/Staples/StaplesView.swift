import SwiftUI
import SwiftData

struct StaplesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CatalogItem.useCount, order: .reverse) private var catalog: [CatalogItem]
    @Query(sort: \GroceryList.sortIndex) private var lists: [GroceryList]
    @State private var segment = 0
    @State private var toast: String?

    private var activeLists: [GroceryList] { lists.filter { !$0.isArchived } }
    private var shown: [CatalogItem] {
        segment == 0 ? catalog : catalog.filter { $0.isStaple }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 12) {
                    Picker("Filter", selection: $segment) {
                        Text("Frequent").tag(0)
                        Text("Staples").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.top, 8)

                    if shown.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: segment == 0 ? "star" : "star.fill",
                            title: segment == 0 ? "Nothing remembered yet" : "No staples marked",
                            message: segment == 0
                                ? "As you add items, Tote remembers them here for one-tap re-adding."
                                : "Tap the star on any item to keep it in your staples.")
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(shown, id: \.nameKey) { item in row(item) }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Staples")
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Brand.live, in: Capsule()).padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func row(_ item: CatalogItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.aisle.icon).font(.callout).foregroundStyle(item.aisle.tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName).foregroundStyle(Brand.text)
                Text("\(item.aisle.rawValue) · used \(item.useCount)×")
                    .font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
            Spacer()
            Button {
                item.isStaple.toggle(); try? context.save(); Haptics.selection()
            } label: {
                Image(systemName: item.isStaple ? "star.fill" : "star")
                    .foregroundStyle(item.isStaple ? Brand.warn : Brand.text3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isStaple ? "Remove staple" : "Mark staple")

            if let target = activeLists.first {
                Menu {
                    ForEach(activeLists) { list in
                        Button("Add to \(list.name)") { addTo(item, list) }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Brand.magic)
                } primaryAction: {
                    addTo(item, target)
                }
                .accessibilityLabel("Add \(item.displayName)")
            }
        }
        .glassCard(padding: 12)
        .contextMenu {
            Button(role: .destructive) {
                context.delete(item); try? context.save()
            } label: { Label("Forget", systemImage: "trash") }
        }
    }

    private func addTo(_ item: CatalogItem, _ list: GroceryList) {
        ToteEngine.addItem(name: item.displayName, quantity: 1, unit: "", aisle: item.aisle, to: list, in: context)
        item.useCount += 1
        item.lastUsed = .now
        try? context.save()
        Haptics.tap()
        withAnimation(Brand.ease()) { toast = "Added to \(list.name)" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}
