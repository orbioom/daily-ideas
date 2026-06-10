import SwiftUI
import SwiftData

/// Resolves the currently-selected dog from the persisted UUID, falling back
/// to the first dog. Centralizes the "which dog" question every screen asks.
struct CurrentDog {
    static func resolve(from dogs: [Dog], selectedID: String) -> Dog? {
        if let uuid = UUID(uuidString: selectedID),
           let match = dogs.first(where: { $0.uuid == uuid }) {
            return match
        }
        return dogs.first
    }
}

/// Picker shown in nav bars when more than one dog exists.
struct DogPickerMenu: View {
    let dogs: [Dog]
    @Binding var selectedID: String

    var body: some View {
        if dogs.count > 1 {
            Menu {
                ForEach(dogs) { dog in
                    Button {
                        selectedID = dog.uuid.uuidString
                        Haptics.selection()
                    } label: {
                        Label("\(dog.emoji)  \(dog.name)", systemImage:
                                selectedID == dog.uuid.uuidString ? "checkmark" : "")
                    }
                }
            } label: {
                let current = CurrentDog.resolve(from: dogs, selectedID: selectedID)
                Text("\(current?.emoji ?? "🐶") \(current?.name ?? "Dog")")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
            }
            .accessibilityLabel("Switch dog")
        }
    }
}
