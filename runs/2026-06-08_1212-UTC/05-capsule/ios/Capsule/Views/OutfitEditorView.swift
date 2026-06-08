import SwiftUI
import SwiftData

struct OutfitEditorView: View {
    @Bindable var outfit: Outfit
    let isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ClothingItem> { !$0.archived }, sort: \ClothingItem.name) private var items: [ClothingItem]

    private var selectedIDs: Set<UUID> { Set(outfit.items.map { $0.id }) }

    private var grouped: [(category: ItemCategory, items: [ClothingItem])] {
        ItemCategory.allCases.compactMap { cat in
            let inCat = items.filter { $0.category == cat }
            return inCat.isEmpty ? nil : (cat, inCat)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Outfit") {
                        TextField("Name", text: $outfit.name)
                        Toggle("Favorite", isOn: $outfit.favorite).tint(Color(hex: 0x9E5E7E))
                        TextField("Notes", text: $outfit.notes, axis: .vertical).lineLimit(1...4)
                    }
                    Section("Pieces (\(outfit.items.count) selected)") {
                        if items.isEmpty {
                            Text("No pieces in your closet yet.").foregroundStyle(Brand.text3)
                        } else {
                            ForEach(grouped, id: \.category) { group in
                                DisclosureGroup {
                                    ForEach(group.items) { item in
                                        toggleRow(item)
                                    }
                                } label: {
                                    Label(group.category.label, systemImage: group.category.symbol)
                                        .font(.subheadline.weight(.medium))
                                }
                            }
                        }
                    }
                    if !isNew {
                        Section {
                            Button(role: .destructive) {
                                context.delete(outfit); Haptics.warning(); dismiss()
                            } label: {
                                Label("Delete outfit", systemImage: "trash").frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "New Outfit" : "Edit Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if isNew && outfit.name.trimmingCharacters(in: .whitespaces).isEmpty && outfit.items.isEmpty {
                            context.delete(outfit)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { try? context.save(); Haptics.success(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(outfit.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func toggleRow(_ item: ClothingItem) -> some View {
        let on = selectedIDs.contains(item.id)
        return Button {
            if let idx = outfit.items.firstIndex(where: { $0.id == item.id }) {
                outfit.items.remove(at: idx)
            } else {
                outfit.items.append(item)
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 36, corner: 8)
                Text(item.name.isEmpty ? "Untitled" : item.name)
                    .foregroundStyle(Brand.text)
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(on ? Color.accentColor : Brand.text3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
