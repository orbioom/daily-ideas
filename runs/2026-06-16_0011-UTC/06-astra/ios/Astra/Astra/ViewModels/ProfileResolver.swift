import Foundation

/// Resolves the "primary" profile from a fetched list + the stored preference,
/// falling back gracefully so the UI always has a sensible default.
enum ProfileResolver {
    static func primary(from profiles: [Profile], primaryID: String) -> Profile? {
        if !primaryID.isEmpty, let match = profiles.first(where: { $0.id.uuidString == primaryID }) {
            return match
        }
        if let flagged = profiles.first(where: { $0.isPrimary }) {
            return flagged
        }
        return profiles.first
    }
}
