import Foundation

/// Stable keys for small @AppStorage-backed preferences and flags.
enum PrefKey {
    static let hasOnboarded = "sprig.hasOnboarded"
    static let activeBabyID = "sprig.activeBabyID"
    static let volumeUnit = "sprig.volumeUnit"
    static let weightUnit = "sprig.weightUnit"
    static let lengthUnit = "sprig.lengthUnit"
    static let hapticsEnabled = "sprig.hapticsEnabled"
    static let confirmDelete = "sprig.confirmDelete"
    static let isPro = "sprig.isPro"
    static let didSeed = "sprig.didSeed"
}
