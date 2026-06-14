import SwiftUI

/// The three-piece tray below the board. Tapping a piece selects it for placement.
struct TrayView: View {
    @ObservedObject var vm: GameViewModel
    let palette: BlockPalette
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { slot in
                let piece = vm.tray[safe: slot] ?? nil
                Button {
                    vm.select(slot: slot)
                } label: {
                    PieceView(piece: piece,
                              palette: palette,
                              selected: vm.selectedSlot == slot,
                              cellSize: 17)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(piece == nil || vm.phase != .playing)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: vm.selectedSlot)
    }
}
