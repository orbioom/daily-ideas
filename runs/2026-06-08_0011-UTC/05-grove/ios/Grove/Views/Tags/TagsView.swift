import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FocusTag.order) private var tags: [FocusTag]
    @State private var showingNew = false
    @State private var editing: FocusTag?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if tags.isEmpty {
                    EmptyStateView(icon: "tag.fill", title: "No tags",
                                   message: "Add tags to categorise your focus sessions.")
                } else {
                    List {
                        ForEach(tags) { tag in
                            Button { editing = tag } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color(hex: tag.colorHex)).frame(width: 34, height: 34)
                                        Image(systemName: tag.symbol).font(.caption).foregroundStyle(.white)
                                    }
                                    Text(tag.name).foregroundStyle(Brand.text)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add tag")
                }
            }
            .sheet(isPresented: $showingNew) { TagEditView(tag: nil) }
            .sheet(item: $editing) { TagEditView(tag: $0) }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(tags[i]) }
        try? context.save(); Haptics.tap()
    }
}

struct TagEditView: View {
    var tag: FocusTag?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var all: [FocusTag]

    @State private var name = ""
    @State private var symbol = "tag.fill"
    @State private var colorHex: UInt32 = 0x4E6BA8

    private let symbols = ["book.fill", "laptopcomputer", "books.vertical.fill", "paintbrush.fill",
                           "brain.head.profile", "pencil", "function", "guitars.fill", "dumbbell.fill",
                           "envelope.fill", "chart.bar.fill", "hammer.fill"]
    private let palette: [UInt32] = [0x4E6BA8, 0x3E7E5A, 0xB5552F, 0x7A5EA8, 0x2C8C7C, 0xC08A3E, 0xC0553E, 0x565A70]
    private let cols = Array(repeating: GridItem(.flexible()), count: 6)

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Name") { TextField("e.g. Thesis", text: $name) }
                    Section("Icon") {
                        LazyVGrid(columns: cols, spacing: 14) {
                            ForEach(symbols, id: \.self) { s in
                                Button { symbol = s; Haptics.selection() } label: {
                                    Image(systemName: s).font(.title3).frame(width: 40, height: 40)
                                        .foregroundStyle(symbol == s ? .white : Brand.text2)
                                        .background(Circle().fill(symbol == s ? AnyShapeStyle(Color(hex: colorHex)) : AnyShapeStyle(Color.clear)))
                                }
                                .buttonStyle(.plain).accessibilityLabel(s)
                            }
                        }.padding(.vertical, 4)
                    }
                    Section("Colour") {
                        LazyVGrid(columns: cols, spacing: 14) {
                            ForEach(palette, id: \.self) { c in
                                Button { colorHex = c; Haptics.selection() } label: {
                                    Circle().fill(Color(hex: c)).frame(width: 34, height: 34)
                                        .overlay(Circle().strokeBorder(Brand.text, lineWidth: colorHex == c ? 2 : 0))
                                }
                                .buttonStyle(.plain).accessibilityLabel("Colour")
                            }
                        }.padding(.vertical, 4)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(tag == nil ? "New tag" : "Edit tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear { if let t = tag { name = t.name; symbol = t.symbol; colorHex = t.colorHex } }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let t = tag { t.name = trimmed; t.symbol = symbol; t.colorHex = colorHex }
        else {
            let order = (all.map(\.order).max() ?? 0) + 1
            context.insert(FocusTag(name: trimmed, symbol: symbol, colorHex: colorHex, order: order))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
