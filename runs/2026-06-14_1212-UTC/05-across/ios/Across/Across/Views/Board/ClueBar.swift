import SwiftUI

/// The clue bar above the keyboard: current clue + prev/next arrows. Tapping the
/// clue toggles the active direction.
struct ClueBar: View {
    @ObservedObject var vm: BoardViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button {
                vm.previousClue()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 52)
            }
            .accessibilityLabel("Previous clue")

            Button {
                vm.toggleDirection()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if let slot = vm.currentSlot {
                        Text("\(slot.number) \(slot.direction.label.uppercased())")
                            .font(Theme.mono(11, .bold))
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Text(vm.currentClue.isEmpty ? "Tap a square to begin" : vm.currentClue)
                        .font(Theme.serif(17, .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel("Current clue")
            .accessibilityValue(vm.currentClue)
            .accessibilityHint("Double tap to switch between across and down")

            Button {
                vm.nextClue()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 52)
            }
            .accessibilityLabel("Next clue")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.accent)
    }
}
