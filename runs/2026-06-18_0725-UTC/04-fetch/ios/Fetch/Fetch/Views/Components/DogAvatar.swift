import SwiftUI

/// Circular dog avatar — shows the photo if present, otherwise a friendly paw monogram.
struct DogAvatar: View {
    let dog: Dog
    var size: CGFloat = 56

    private var image: UIImage? { ImageStore.load(dog.photoFilename) }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Theme.heroGradient
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
        .accessibilityLabel("\(dog.name)\(image == nil ? "" : " photo")")
    }
}
