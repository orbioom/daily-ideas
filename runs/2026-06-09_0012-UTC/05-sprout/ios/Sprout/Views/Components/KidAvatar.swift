import SwiftUI

struct KidAvatar: View {
    let kid: Kid
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(kid.color.color.opacity(0.22))
            Circle().strokeBorder(kid.color.color.opacity(0.55), lineWidth: 1)
            Image(systemName: kid.symbol)
                .font(.system(size: size * 0.42))
                .foregroundStyle(kid.color.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
