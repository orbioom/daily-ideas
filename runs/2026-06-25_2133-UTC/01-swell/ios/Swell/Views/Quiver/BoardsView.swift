import SwiftUI
import SwiftData

struct BoardsView: View {
    @Query(sort: \Board.createdAt, order: .reverse) private var boards: [Board]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var editBoard: Board?

    private var activeBoards: [Board] { boards.filter { !$0.isRetired } }
    private var retiredBoards: [Board] { boards.filter { $0.isRetired } }

    var body: some View {
        Group {
            if boards.isEmpty {
                emptyState
                    .toolbar { addButton }
            } else {
                List {
                    Section("Active") {
                        if activeBoards.isEmpty {
                            Text("No active boards")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(activeBoards) { board in
                                BoardRowView(board: board)
                                    .onTapGesture { editBoard = board }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(board)
                                            try? context.save()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            board.isRetired = true
                                            try? context.save()
                                        } label: {
                                            Label("Retire", systemImage: "archivebox")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                    }
                    if !retiredBoards.isEmpty {
                        Section("Retired") {
                            ForEach(retiredBoards) { board in
                                BoardRowView(board: board)
                                    .opacity(0.6)
                                    .onTapGesture { editBoard = board }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar { addButton }
            }
        }
        .sheet(isPresented: $showingAdd) { BoardFormView(board: nil) }
        .sheet(item: $editBoard) { board in BoardFormView(board: board) }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(SwellTheme.teal)
            }
            .accessibilityLabel("Add board")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "surfboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(SwellTheme.teal.opacity(0.5))
                .accessibilityHidden(true)
            Text("No boards yet")
                .font(.title3.bold())
            Text("Add your boards to pick them when logging sessions.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BoardRowView: View {
    let board: Board

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(SwellTheme.teal.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "surfboard.fill")
                        .foregroundStyle(SwellTheme.teal)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(board.name)
                    .font(.subheadline.bold())
                Text("\(board.type.rawValue) • \(board.displayLength) • \(String(format: "%.0fL", board.volumeLiters))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(board.finSetup.rawValue)
                    .font(.caption2)
                    .foregroundStyle(SwellTheme.teal)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(board.name), \(board.type.rawValue), \(board.displayLength)")
    }
}

struct BoardFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let board: Board?

    @State private var name: String
    @State private var type: BoardType
    @State private var lengthFt: Int
    @State private var lengthIn: Int
    @State private var volumeLiters: Double
    @State private var finSetup: FinSetup
    @State private var notes: String
    @State private var showError = false

    init(board: Board?) {
        self.board = board
        _name = State(initialValue: board?.name ?? "")
        _type = State(initialValue: board?.type ?? .shortboard)
        _lengthFt = State(initialValue: board?.lengthFt ?? 6)
        _lengthIn = State(initialValue: board?.lengthIn ?? 2)
        _volumeLiters = State(initialValue: board?.volumeLiters ?? 32.0)
        _finSetup = State(initialValue: board?.finSetup ?? .thruster)
        _notes = State(initialValue: board?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Board") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(BoardType.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                }
                Section("Dimensions") {
                    HStack {
                        Text("Length")
                        Spacer()
                        Stepper("\(lengthFt)'", value: $lengthFt, in: 4...12)
                        Stepper("\(lengthIn)\"", value: $lengthIn, in: 0...11)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text(String(format: "%.1f L", volumeLiters))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $volumeLiters, in: 15...150, step: 0.5)
                            .tint(SwellTheme.teal)
                    }
                }
                Section("Fins & Notes") {
                    Picker("Fin Setup", selection: $finSetup) {
                        ForEach(FinSetup.allCases) { f in Text(f.rawValue).tag(f) }
                    }
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle(board == nil ? "Add Board" : "Edit Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(SwellTheme.teal)
                }
            }
            .alert("Please enter a board name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }

        if let b = board {
            b.name = trimmed
            b.type = type
            b.lengthFt = lengthFt
            b.lengthIn = lengthIn
            b.volumeLiters = volumeLiters
            b.finSetup = finSetup
            b.notes = notes
        } else {
            let b = Board(name: trimmed, type: type, lengthFt: lengthFt, lengthIn: lengthIn, volumeLiters: volumeLiters, finSetup: finSetup, notes: notes)
            context.insert(b)
        }
        try? context.save()
        dismiss()
    }
}
