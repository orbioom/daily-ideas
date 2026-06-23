import SwiftUI

/// A 1–5 mood selector with emoji + label. Used in check-ins and the mood logger.
struct MoodPicker: View {
    @Binding var selection: Int
    var reduceMotion: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(Mood.range), id: \.self) { value in
                Button {
                    Haptics.shared.tap()
                    selection = value
                } label: {
                    VStack(spacing: 4) {
                        Text(Mood.emoji(value))
                            .font(.system(size: 30))
                        Text(Mood.label(value))
                            .font(.caption2)
                            .foregroundStyle(selection == value ? Theme.textPrimary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .fill(selection == value ? Theme.accent.opacity(0.18) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .strokeBorder(selection == value ? Theme.accent : Theme.textSecondary.opacity(0.2),
                                          lineWidth: selection == value ? 2 : 1)
                    )
                    .scaleEffect(reduceMotion ? 1 : (selection == value ? 1.04 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(Mood.label(value)), \(value) of 5")
                .accessibilityAddTraits(selection == value ? [.isSelected] : [])
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.25), value: selection)
    }
}

#Preview {
    StatefulPreviewWrapper(3) { MoodPicker(selection: $0) }
        .padding()
}

/// Small helper to preview a binding-driven view.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
