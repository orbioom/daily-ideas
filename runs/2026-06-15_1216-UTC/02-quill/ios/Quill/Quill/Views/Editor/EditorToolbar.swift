import SwiftUI

/// The custom drawing toolbar: tools, color palette, width stepper, undo/redo,
/// and clear. Replaces PKToolPicker's floating UI entirely.
struct EditorToolbar: View {
    @ObservedObject var vm: EditorViewModel
    let isPro: Bool
    var onLockedColor: () -> Void
    var onClear: () -> Void

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                toolButtons
                Divider().frame(height: 28)
                undoRedo
                Spacer(minLength: 0)
                clearButton
            }

            HStack(spacing: 14) {
                if vm.toolKind.isInking {
                    ColorPaletteView(
                        selectedHex: Binding(
                            get: { vm.inkColorHex },
                            set: { vm.setColor($0) }
                        ),
                        isPro: isPro,
                        onLockedTap: onLockedColor
                    )
                } else {
                    Text("Eraser — drag across strokes to remove")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
            }

            widthControl
        }
        .padding(14)
        .background(Theme.surface)
        .overlay(alignment: .top) { Divider() }
    }

    private var toolButtons: some View {
        HStack(spacing: 6) {
            ForEach(ToolKind.allCases) { kind in
                let selected = vm.toolKind == kind
                Button {
                    Haptics.select(settings.hapticsEnabled)
                    vm.select(kind)
                } label: {
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 40, height: 38)
                        .background(
                            selected ? Theme.accentSoft : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .foregroundStyle(selected ? Theme.accent : Theme.inkSoft)
                }
                .accessibilityLabel(kind.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private var undoRedo: some View {
        HStack(spacing: 6) {
            Button {
                Haptics.tap(settings.hapticsEnabled)
                vm.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(vm.canUndo ? Theme.ink : Theme.inkFaint)
            }
            .disabled(!vm.canUndo)
            .accessibilityLabel("Undo")

            Button {
                Haptics.tap(settings.hapticsEnabled)
                vm.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(vm.canRedo ? Theme.ink : Theme.inkFaint)
            }
            .disabled(!vm.canRedo)
            .accessibilityLabel("Redo")
        }
    }

    private var clearButton: some View {
        Button(role: .destructive) {
            onClear()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 38, height: 38)
                .foregroundStyle(Theme.bad)
        }
        .accessibilityLabel("Clear page")
    }

    private var widthControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "lineweight")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .accessibilityHidden(true)
            Slider(
                value: Binding(
                    get: { Double(vm.width) },
                    set: { vm.width = CGFloat($0) }
                ),
                in: Double(vm.toolKind.widthRange.lowerBound)...Double(vm.toolKind.widthRange.upperBound)
            )
            .tint(Theme.accent)
            Text("\(Int(vm.width))")
                .font(Theme.rounded(14, .medium).monospacedDigit())
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 28, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stroke width")
        .accessibilityValue("\(Int(vm.width)) points")
        .accessibilityAdjustableAction { direction in
            let range = vm.toolKind.widthRange
            switch direction {
            case .increment: vm.width = min(range.upperBound, vm.width + 1)
            case .decrement: vm.width = max(range.lowerBound, vm.width - 1)
            default: break
            }
        }
    }
}
