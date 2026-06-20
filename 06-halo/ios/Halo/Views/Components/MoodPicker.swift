import SwiftUI

struct MoodPicker: View {
    @Binding var rating: Int

    private let moods: [(emoji: String, label: String)] = [
        ("😞", "Low"),
        ("😕", "Meh"),
        ("😐", "Okay"),
        ("🙂", "Good"),
        ("😄", "Great"),
    ]

    var body: some View {
        HStack(spacing: HaloTheme.spacingS) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        rating = value
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(moods[value - 1].emoji)
                            .font(.system(size: rating == value ? 32 : 24))
                            .scaleEffect(rating == value ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)

                        Text(moods[value - 1].label)
                            .font(.system(size: 10, weight: rating == value ? .semibold : .regular))
                            .foregroundColor(rating == value ? HaloTheme.accent : HaloTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HaloTheme.spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: HaloTheme.radiusS)
                            .fill(rating == value
                                  ? HaloTheme.accent.opacity(0.15)
                                  : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: HaloTheme.radiusS)
                                    .stroke(
                                        rating == value
                                            ? HaloTheme.accent.opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ZStack {
        HaloTheme.background.ignoresSafeArea()
        MoodPicker(rating: .constant(3))
            .padding()
    }
}
