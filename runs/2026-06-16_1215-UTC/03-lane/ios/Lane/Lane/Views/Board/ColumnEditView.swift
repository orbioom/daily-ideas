import SwiftUI
import SwiftData

struct ColumnEditView: View {
    @Bindable var column: BoardColumn
    let board: Board

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @State private var name: String
    @State private var wipLimit: Int
    @State private var colorHex: Int
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    init(column: BoardColumn, board: Board) {
        self.column = column
        self.board = board
        _name = State(initialValue: column.name)
        _wipLimit = State(initialValue: column.wipLimit)
        _colorHex = State(initialValue: column.colorHex)
    }

    private let colorColumns = [GridItem(.adaptive(minimum: 44), spacing: 10)]
    private var canDelete: Bool { board.columns.count > 1 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Lane name", text: $name)
                }

                Section {
                    if proStore.isPro {
                        Stepper(value: $wipLimit, in: 0...50) {
                            HStack {
                                Text("WIP limit")
                                Spacer()
                                Text(wipLimit == 0 ? "Off" : "\(wipLimit)")
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text("WIP limit")
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                ProLockBadge()
                            }
                        }
                    }
                } header: {
                    Text("Work-in-progress")
                } footer: {
                    Text("Cap how many cards a lane can hold. The count badge turns red when exceeded.")
                }

                Section("Color") {
                    LazyVGrid(columns: colorColumns, spacing: 10) {
                        ForEach(Palette.columnColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: UInt(hex)))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().stroke(Theme.ink, lineWidth: colorHex == hex ? 3 : 0))
                                .onTapGesture { colorHex = hex }
                                .accessibilityLabel("Lane color")
                        }
                    }
                    .padding(.vertical, 4)
                }

                if canDelete {
                    Section {
                        Button(role: .destructive) {
                            if settings.confirmBeforeDelete {
                                showDeleteConfirm = true
                            } else {
                                deleteColumn()
                            }
                        } label: {
                            SwiftUI.Label("Delete lane", systemImage: "trash")
                        }
                    } footer: {
                        Text("Deleting a lane removes its cards.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Edit Lane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete lane?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteColumn() }
            } message: {
                Text("This removes \"\(column.name)\" and its \(column.cards.count) card\(column.cards.count == 1 ? "" : "s").")
            }
        }
    }

    private func saveChanges() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        column.name = trimmed.isEmpty ? column.name : trimmed
        column.wipLimit = proStore.isPro ? max(0, wipLimit) : 0
        column.colorHex = colorHex
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteColumn() {
        context.delete(column)
        // Recompact remaining columns and re-evaluate completion (done column may shift).
        let remaining = board.columns.filter { $0.id != column.id }
        CardMover.compactColumns(remaining)
        for col in remaining.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            for card in col.cards {
                CardMover.updateCompletion(for: card, in: col)
            }
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
