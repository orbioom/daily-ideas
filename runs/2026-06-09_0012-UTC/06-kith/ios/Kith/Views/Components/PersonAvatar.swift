import SwiftUI

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(person.color.color.opacity(0.22))
            Circle().strokeBorder(person.color.color.opacity(0.5), lineWidth: 1)
            Text(person.initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(person.color.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
