import SwiftUI

/// A circular pet avatar using the pet's color and species glyph.
struct PetAvatar: View {
    let pet: Pet
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(pet.color.color.opacity(0.22))
            Circle().strokeBorder(pet.color.color.opacity(0.5), lineWidth: 1)
            Image(systemName: pet.species.icon)
                .font(.system(size: size * 0.42))
                .foregroundStyle(pet.color.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
