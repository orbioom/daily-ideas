import SwiftUI

/// Tracks which shopping-list ingredients have been checked off ("got it"),
/// persisted across launches by normalized name.
@MainActor
final class ShoppingState: ObservableObject {
    @AppStorage("checkedShoppingItems") private var stored: String = ""

    @Published private(set) var checked: Set<String> = []

    init() {
        checked = decode(stored)
    }

    func isChecked(_ normalized: String) -> Bool {
        checked.contains(normalized)
    }

    func toggle(_ normalized: String) {
        if checked.contains(normalized) {
            checked.remove(normalized)
        } else {
            checked.insert(normalized)
        }
        persist()
    }

    func clearChecked() {
        checked.removeAll()
        persist()
    }

    /// Uncheck specific names (so newly-added items appear as "to buy").
    func clearChecked(for names: [String]) {
        var changed = false
        for n in names where checked.contains(n) {
            checked.remove(n)
            changed = true
        }
        if changed { persist() }
    }

    /// Drop any checked names no longer present in the live list.
    func prune(keeping liveNames: Set<String>) {
        let intersection = checked.intersection(liveNames)
        if intersection != checked {
            checked = intersection
            persist()
        }
    }

    private func persist() {
        stored = checked.sorted().joined(separator: "\n")
    }

    private func decode(_ raw: String) -> Set<String> {
        Set(raw.components(separatedBy: "\n").filter { !$0.isEmpty })
    }
}
