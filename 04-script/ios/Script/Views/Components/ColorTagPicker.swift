import SwiftUI

struct ColorTagPicker: View {
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ScriptTheme.colorTags, id: \.self) { hex in
                Circle()
                    .fill(ScriptTheme.colorTag(hex))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.primary, lineWidth: selected == hex ? 2 : 0)
                    )
                    .onTapGesture { selected = hex }
                    .accessibilityLabel("Color \(hex)")
            }
        }
    }
}
