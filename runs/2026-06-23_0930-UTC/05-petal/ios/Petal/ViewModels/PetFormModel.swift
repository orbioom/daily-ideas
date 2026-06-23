import Foundation
import SwiftUI

/// Holds editable state for creating or editing a `Pet`, with validation.
@Observable
final class PetFormModel {
    var name: String = ""
    var species: Species = .dog
    var breed: String = ""
    var hasBirthday: Bool = false
    var birthday: Date = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    var avatarSymbol: String = Species.dog.defaultSymbol
    var avatarTint: AvatarTint = .teal
    var notes: String = ""

    /// True if `species` changed and user hasn't manually overridden the symbol.
    private var symbolFollowsSpecies = true

    init() {}

    init(pet: Pet) {
        name = pet.name
        species = pet.species
        breed = pet.breed
        if let b = pet.birthday {
            hasBirthday = true
            birthday = b
        }
        avatarSymbol = pet.avatarSymbol
        avatarTint = pet.avatarTint
        notes = pet.notes
        symbolFollowsSpecies = (pet.avatarSymbol == pet.species.defaultSymbol)
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty }
    var validationMessage: String? {
        trimmedName.isEmpty ? "Please enter a name." : nil
    }

    /// Available avatar symbols to choose from.
    static let symbolChoices = [
        "dog.fill", "cat.fill", "hare.fill", "bird.fill", "lizard.fill",
        "fish.fill", "tortoise.fill", "pawprint.fill", "ant.fill", "ladybug.fill"
    ]

    func selectSpecies(_ s: Species) {
        species = s
        if symbolFollowsSpecies {
            avatarSymbol = s.defaultSymbol
        }
    }

    func selectSymbol(_ symbol: String) {
        avatarSymbol = symbol
        symbolFollowsSpecies = (symbol == species.defaultSymbol)
    }

    /// Applies the form to a new or existing pet.
    func apply(to pet: Pet) {
        pet.name = trimmedName
        pet.species = species
        pet.breed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        pet.birthday = hasBirthday ? birthday : nil
        pet.avatarSymbol = avatarSymbol
        pet.avatarTint = avatarTint
        pet.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func makePet() -> Pet {
        let pet = Pet(name: trimmedName, species: species)
        apply(to: pet)
        return pet
    }
}
