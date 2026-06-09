import Foundation

/// Pure functions over the inventory: warranty status, value rollups, search,
/// and plain-text / CSV export. Kept free of SwiftUI so it stays testable and
/// deterministic. All date math is guarded; no force-unwraps.
enum InventoryEngine {

    // MARK: - Warranty

    /// The warranty status for an item relative to `now`, plus the number of
    /// whole days remaining (nil when there is no warranty).
    /// `window` is the "expiring soon" threshold in days.
    static func warrantyStatus(for item: Item,
                               window days: Int,
                               now: Date = .now,
                               calendar: Calendar = .current) -> (status: WarrantyStatus, daysRemaining: Int?) {
        guard let expiry = item.warrantyExpiry else { return (.none, nil) }
        let startOfNow = calendar.startOfDay(for: now)
        let startOfExpiry = calendar.startOfDay(for: expiry)
        let comps = calendar.dateComponents([.day], from: startOfNow, to: startOfExpiry)
        let remaining = comps.day ?? 0
        if remaining < 0 {
            return (.expired, remaining)
        }
        if remaining <= max(0, days) {
            return (.expiringSoon, remaining)
        }
        return (.active, remaining)
    }

    // MARK: - Value rollups

    static func totalValue(_ items: [Item]) -> Double {
        items.reduce(0) { $0 + max(0, $1.price) }
    }

    /// Value grouped by room name. Items with no room are bucketed under
    /// `unassignedLabel`. Sorted by value descending.
    static func value(byRoom items: [Item],
                      unassignedLabel: String = "Unassigned") -> [(room: String, value: Double)] {
        var dict: [String: Double] = [:]
        for item in items {
            let key = item.room?.name ?? unassignedLabel
            dict[key, default: 0] += max(0, item.price)
        }
        return dict.map { (room: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    /// Value grouped by category, sorted by value descending. Categories with
    /// no items are omitted.
    static func value(byCategory items: [Item]) -> [(category: InventoryCategory, value: Double)] {
        var dict: [InventoryCategory: Double] = [:]
        for item in items {
            dict[item.category, default: 0] += max(0, item.price)
        }
        return dict.map { (category: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    static func itemCount(_ items: [Item]) -> Int { items.count }

    static func count(byCategory items: [Item]) -> [(category: InventoryCategory, count: Int)] {
        var dict: [InventoryCategory: Int] = [:]
        for item in items { dict[item.category, default: 0] += 1 }
        return dict.map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    static func count(byRoom items: [Item],
                      unassignedLabel: String = "Unassigned") -> [(room: String, count: Int)] {
        var dict: [String: Int] = [:]
        for item in items {
            let key = item.room?.name ?? unassignedLabel
            dict[key, default: 0] += 1
        }
        return dict.map { (room: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Warranty queries

    /// Items whose warranty is expiring within the window (still covered),
    /// sorted by soonest expiry first.
    static func expiringSoon(_ items: [Item],
                             window days: Int,
                             now: Date = .now,
                             calendar: Calendar = .current) -> [Item] {
        items.filter {
            warrantyStatus(for: $0, window: days, now: now, calendar: calendar).status == .expiringSoon
        }
        .sorted { ($0.warrantyExpiry ?? .distantFuture) < ($1.warrantyExpiry ?? .distantFuture) }
    }

    /// Items whose warranty has already lapsed, most recently expired first.
    static func expired(_ items: [Item],
                        now: Date = .now,
                        calendar: Calendar = .current) -> [Item] {
        items.filter {
            warrantyStatus(for: $0, window: 0, now: now, calendar: calendar).status == .expired
        }
        .sorted { ($0.warrantyExpiry ?? .distantPast) > ($1.warrantyExpiry ?? .distantPast) }
    }

    /// Items with active coverage beyond the expiring-soon window, soonest first.
    static func active(_ items: [Item],
                       window days: Int,
                       now: Date = .now,
                       calendar: Calendar = .current) -> [Item] {
        items.filter {
            warrantyStatus(for: $0, window: days, now: now, calendar: calendar).status == .active
        }
        .sorted { ($0.warrantyExpiry ?? .distantFuture) < ($1.warrantyExpiry ?? .distantFuture) }
    }

    // MARK: - Search

    /// Case-insensitive substring match across name, brand, model and serial.
    static func search(_ items: [Item], query: String) -> [Item] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { item in
            item.name.lowercased().contains(q)
                || item.brand.lowercased().contains(q)
                || item.modelNumber.lowercased().contains(q)
                || item.serial.lowercased().contains(q)
        }
    }

    // MARK: - Export

    private static let exportDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return exportDateFormatter.string(from: date)
    }

    /// Escapes a single CSV field: wraps in quotes when it contains a comma,
    /// quote, or newline, doubling any embedded quotes (RFC 4180).
    static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return field
    }

    private static let csvColumns = [
        "Room", "Name", "Category", "Brand", "Model", "Serial",
        "PurchaseDate", "Price", "WarrantyExpiry"
    ]

    /// A CSV document of every item. `rooms` is accepted for signature parity
    /// and to keep the call site explicit; row order follows `items`.
    static func csvSummary(rooms: [Room], items: [Item]) -> String {
        var lines: [String] = [csvColumns.joined(separator: ",")]
        for item in items {
            let row = [
                item.room?.name ?? "Unassigned",
                item.name,
                item.category.label,
                item.brand,
                item.modelNumber,
                item.serial,
                dateString(item.purchaseDate),
                String(format: "%.2f", max(0, item.price)),
                dateString(item.warrantyExpiry)
            ].map(csvEscape).joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// A human-readable plain-text summary grouped by room, with a value total.
    static func textSummary(rooms: [Room],
                            items: [Item],
                            currencyCode: String = "USD") -> String {
        var out: [String] = []
        out.append("COFFER — HOME INVENTORY")
        out.append("Generated \(exportDateFormatter.string(from: .now))")
        out.append("Items: \(items.count) · Total value: \(currency(totalValue(items), code: currencyCode))")
        out.append("")

        // Group by room name, with Unassigned last.
        var groups: [String: [Item]] = [:]
        for item in items {
            groups[item.room?.name ?? "Unassigned", default: []].append(item)
        }
        let orderedRoomNames = rooms.sorted { $0.sortIndex < $1.sortIndex }.map(\.name)
        var seen = Set<String>()
        var sectionOrder: [String] = []
        for name in orderedRoomNames where groups[name] != nil && !seen.contains(name) {
            sectionOrder.append(name); seen.insert(name)
        }
        // Any room names present in items but not in the rooms list, then Unassigned.
        for name in groups.keys.sorted() where !seen.contains(name) && name != "Unassigned" {
            sectionOrder.append(name); seen.insert(name)
        }
        if groups["Unassigned"] != nil { sectionOrder.append("Unassigned") }

        for room in sectionOrder {
            guard let roomItems = groups[room] else { continue }
            out.append("== \(room) (\(currency(totalValue(roomItems), code: currencyCode))) ==")
            for item in roomItems.sorted(by: { $0.name < $1.name }) {
                var line = "• \(item.name) — \(item.category.label)"
                if !item.brand.isEmpty { line += " · \(item.brand)" }
                line += " · \(currency(max(0, item.price), code: currencyCode))"
                if let expiry = item.warrantyExpiry {
                    line += " · warranty to \(dateString(expiry))"
                }
                out.append(line)
            }
            out.append("")
        }
        return out.joined(separator: "\n")
    }

    /// Currency formatting that never crashes (falls back to a plain number).
    static func currency(_ value: Double, code: String) -> String {
        value.formatted(.currency(code: code))
    }
}
