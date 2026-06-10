import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ListItem

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Item") {
                        TextField("Name", text: $item.name)
                    }
                    Section("Quantity") {
                        Stepper(value: $item.quantity, in: 0.5...99, step: item.quantity < 5 ? 0.5 : 1) {
                            HStack {
                                Text("Amount")
                                Spacer()
                                Text(item.quantity == item.quantity.rounded()
                                     ? String(Int(item.quantity)) : String(format: "%.1f", item.quantity))
                                    .foregroundStyle(Brand.text3).font(Brand.mono(15))
                            }
                        }
                        Picker("Unit", selection: $item.unit) {
                            ForEach(ToteEngine.units, id: \.self) { u in
                                Text(u.isEmpty ? "—" : u).tag(u)
                            }
                        }
                    }
                    Section("Aisle") {
                        Picker("Aisle", selection: $item.aisleRaw) {
                            ForEach(Aisle.allCases) { a in
                                Label(a.rawValue, systemImage: a.icon).tag(a.rawValue)
                            }
                        }
                    }
                    Section("Note") {
                        TextField("e.g. the ripe ones", text: $item.note, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { try? context.save(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
