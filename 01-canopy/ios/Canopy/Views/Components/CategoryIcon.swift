import SwiftUI

struct CategoryIcon: View {
    let category: EmissionCategory
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(category.swiftUIColor.opacity(0.18))
                .frame(width: size, height: size)

            Image(systemName: category.icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(category.swiftUIColor)
        }
        .accessibilityLabel(category.rawValue)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(EmissionCategory.allCases, id: \.self) { cat in
            CategoryIcon(category: cat)
        }
    }
    .padding()
}
