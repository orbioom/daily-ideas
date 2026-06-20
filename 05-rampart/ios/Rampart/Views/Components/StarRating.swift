import SwiftUI

struct StarRating: View {
    let stars: Int
    let maxStars: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxStars, id: \.self) { i in
                Image(systemName: i <= stars ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(i <= stars
                        ? Color(red: 0.831, green: 0.686, blue: 0.216)
                        : Color.white.opacity(0.25))
            }
        }
    }
}
