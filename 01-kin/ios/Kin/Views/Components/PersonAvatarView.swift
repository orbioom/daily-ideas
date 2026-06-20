import SwiftUI

struct PersonAvatarView: View {
    let person: Person
    var size: CGFloat = 48

    @State private var photo: UIImage?

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    KinTheme.genderColor(person.gender)
                    Text(person.initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(KinTheme.genderColor(person.gender).opacity(0.4), lineWidth: 2))
        .onAppear { loadPhoto() }
        .onChange(of: person.photoFilename) { _, _ in loadPhoto() }
        .accessibilityLabel("\(person.fullName) profile photo")
    }

    private func loadPhoto() {
        guard let filename = person.photoFilename else {
            photo = nil
            return
        }
        photo = PhotoStore.shared.load(filename: filename)
    }
}
