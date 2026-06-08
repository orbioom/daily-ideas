import SwiftUI

struct MoodPicker: View {
    @Binding var mood: Int   // 1…5

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    mood = value
                    Haptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(Format.moodEmoji(value))
                            .font(.title2)

                        Text(Format.moodLabel(value))
                            .font(.caption2)
                            .foregroundStyle(mood == value ? Brand.text : Brand.text3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        mood == value
                            ? Brand.live.opacity(0.18)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(mood == value ? Brand.live : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Format.moodLabel(value))
                .accessibilityAddTraits(mood == value ? [.isSelected] : [])
            }
        }
    }
}
