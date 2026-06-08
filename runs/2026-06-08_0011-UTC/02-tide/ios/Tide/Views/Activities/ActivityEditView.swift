import SwiftUI
import SwiftData

struct ActivityEditView: View {
    var activity: Activity?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var all: [Activity]

    @State private var name = ""
    @State private var symbol = "star.fill"
    @State private var category = "Day"

    private let categories = ["Body", "Day", "Social", "Joy"]
    private let symbols = ["figure.run", "bed.double.fill", "carrot.fill", "laptopcomputer",
                           "book.fill", "house.fill", "person.2.fill", "heart.fill", "moon.fill",
                           "leaf.fill", "books.vertical.fill", "iphone", "cup.and.saucer.fill",
                           "music.note", "gamecontroller.fill", "cart.fill", "star.fill", "pawprint.fill"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Name") { TextField("e.g. Meditation", text: $name) }
                    Section("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.segmented)
                    }
                    Section("Icon") {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(symbols, id: \.self) { s in
                                Button {
                                    symbol = s; Haptics.selection()
                                } label: {
                                    Image(systemName: s)
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(symbol == s ? .white : Brand.text2)
                                        .background(Circle().fill(symbol == s ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(Color.clear)))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(s)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(activity == nil ? "New activity" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear {
                if let activity { name = activity.name; symbol = activity.symbol; category = activity.category }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let activity {
            activity.name = trimmed; activity.symbol = symbol; activity.category = category
        } else {
            let order = (all.map(\.order).max() ?? 0) + 1
            context.insert(Activity(name: trimmed, symbol: symbol, category: category, order: order))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
