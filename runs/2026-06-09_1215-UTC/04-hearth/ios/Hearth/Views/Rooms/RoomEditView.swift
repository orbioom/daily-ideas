import SwiftUI
import SwiftData

/// Add or edit a room. Passing a non-nil `room` edits it in place; nil creates
/// a new one at `nextSortIndex`.
struct RoomEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let room: Room?
    let nextSortIndex: Int

    @State private var name: String
    @State private var symbol: String
    @State private var colorIndex: Int

    init(room: Room?, nextSortIndex: Int) {
        self.room = room
        self.nextSortIndex = nextSortIndex
        _name = State(initialValue: room?.name ?? "")
        _symbol = State(initialValue: room?.symbol ?? "house")
        _colorIndex = State(initialValue: room?.colorIndex ?? 0)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !trimmedName.isEmpty }

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Room name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(0..<Palette.count, id: \.self) { idx in
                            Circle()
                                .fill(Palette.color(idx))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().strokeBorder(Brand.text, lineWidth: colorIndex == idx ? 2 : 0)
                                )
                                .onTapGesture {
                                    Haptics.selection()
                                    colorIndex = idx
                                }
                                .accessibilityLabel("Color \(idx + 1)")
                                .accessibilityAddTraits(colorIndex == idx ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Palette.roomSymbols, id: \.self) { sym in
                            Image(systemName: sym)
                                .font(.system(size: 20))
                                .foregroundStyle(symbol == sym ? Palette.color(colorIndex) : Brand.text2)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(symbol == sym ? Palette.color(colorIndex).opacity(0.15) : Brand.hairline.opacity(0.4))
                                )
                                .onTapGesture {
                                    Haptics.selection()
                                    symbol = sym
                                }
                                .accessibilityLabel(sym)
                                .accessibilityAddTraits(symbol == sym ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(room == nil ? "New Room" : "Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        if let room {
            room.name = trimmedName
            room.symbol = symbol
            room.colorIndex = colorIndex
        } else {
            let new = Room(name: trimmedName, symbol: symbol, colorIndex: colorIndex, sortIndex: nextSortIndex)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
