import Foundation

/// Helpers for resolving the selected profile from a list, given the stored id.
enum ProfileLookup {
    static func selected(in profiles: [Profile], selectedID: String) -> Profile? {
        if let match = profiles.first(where: { $0.persistentModelID.storageIdentifier == selectedID }) {
            return match
        }
        return profiles.first
    }
}
