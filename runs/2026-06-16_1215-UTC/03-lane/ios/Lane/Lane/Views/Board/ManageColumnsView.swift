import SwiftUI
import SwiftData

/// Reorder lanes with drag handles (edit mode). Moving the last lane changes the
/// "done" column, so completion is recomputed after every move.
struct ManageColumnsView: View {
    @Bindable var board: Board
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(board.orderedColumns) { column in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: UInt(max(0, column.colorHex))))
                                .frame(width: 10, height: 10)
                            Text(column.name)
                                .font(Theme.rounded(16, .semibold))
                            Spacer()
                            Text("\(column.cards.count)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .onMove(perform: moveColumns)
                } footer: {
                    Text("The last lane is treated as \"Done\". Cards moved there are marked complete.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Lanes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func moveColumns(from offsets: IndexSet, to destination: Int) {
        CardMover.reorderColumns(in: board, from: offsets, to: destination)
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }
}
