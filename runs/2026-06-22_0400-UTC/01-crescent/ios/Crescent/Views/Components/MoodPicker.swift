import SwiftUI

struct MoodPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Button(action: { rating = i }) {
                    Text(i <= rating ? "★" : "☆")
                        .font(.title3)
                        .foregroundColor(i <= rating ? CrescentTheme.gold : CrescentTheme.silver)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
