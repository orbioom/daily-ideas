import SwiftUI

/// A horizontal palette of selectable color dots. Locked colors (Pro) show a
/// small lock and route to the paywall via `onLockedTap`.
struct ColorPaletteView: View {
    @Binding var selectedHex: UInt
    let isPro: Bool
    var onLockedTap: () -> Void = {}

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CoverPalette.all, id: \.self) { hex in
                    let locked = !isPro && !CoverPalette.base.contains(hex)
                    dot(hex: hex, locked: locked)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func dot(hex: UInt, locked: Bool) -> some View {
        let isSelected = (selectedHex == hex) && !locked
        Button {
            if locked {
                onLockedTap()
            } else {
                selectedHex = hex
            }
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle().stroke(Theme.surface, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Circle().stroke(isSelected ? Theme.accent : Theme.hairline,
                                    lineWidth: isSelected ? 2 : 1)
                )
                .overlay {
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "Locked color, requires Quill Pro" : "Color")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
