import SwiftUI
import SwiftData

struct DrinksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DrinkType.order) private var drinks: [DrinkType]
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue

    @State private var editing: DrinkType?

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if drinks.isEmpty {
                    EmptyStateView(
                        icon: "cup.and.saucer",
                        title: "No drinks",
                        message: "Add the drinks you reach for most. Each one remembers its size and how much it hydrates."
                    )
                } else {
                    List {
                        ForEach(drinks) { drink in
                            Button { editing = drink } label: { drinkRow(drink) }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Drinks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let new = DrinkType(name: "", symbol: "drop.fill", colorHex: 0x3E7EA6,
                                            defaultVolumeML: 250, isCustom: true, order: drinks.count)
                        context.insert(new)
                        editing = new
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add drink")
                }
            }
            .sheet(item: $editing) { DrinkEditorView(drink: $0) }
        }
    }

    private func drinkRow(_ drink: DrinkType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: drink.symbol)
                .font(.title3)
                .foregroundStyle(Color(hex: drink.colorHex))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.name.isEmpty ? "Untitled" : drink.name)
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(Units.string(drink.defaultVolumeML, as: unit)) · \(Int(drink.hydrationFactor * 100))% hydrating")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            if drink.caffeineMgPerML > 0 {
                Text("\(Int(drink.caffeineMgPerML * drink.defaultVolumeML)) mg")
                    .font(Brand.mono(11)).foregroundStyle(Brand.warn)
            }
        }
        .contentShape(Rectangle())
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(drinks[i]) }
        Haptics.warning()
    }
}
