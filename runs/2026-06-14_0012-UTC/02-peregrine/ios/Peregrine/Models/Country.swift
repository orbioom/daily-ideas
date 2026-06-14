import Foundation

/// A single country fact-card. Value type — the curated dataset lives in
/// `CountryData`; user progress is tracked separately in SwiftData.
struct Country: Identifiable, Hashable, Codable {
    let iso2: String
    let name: String
    let capital: String
    let continent: Continent
    let region: String
    let populationMillions: Double
    let currency: String
    let facts: [String]

    var id: String { iso2 }

    /// Flag emoji computed from the ISO-3166 alpha-2 code using Unicode
    /// regional-indicator symbols (0x1F1E6 + offset from 'A').
    var flag: String {
        let base: UInt32 = 0x1F1E6
        let scalarA: UInt32 = 65 // 'A'
        var result = ""
        for ch in iso2.uppercased().unicodeScalars {
            guard ch.value >= scalarA, ch.value <= scalarA + 25 else { continue }
            if let scalar = Unicode.Scalar(base + (ch.value - scalarA)) {
                result.unicodeScalars.append(scalar)
            }
        }
        return result.isEmpty ? "🏳️" : result
    }

    /// Compact population string e.g. "67.4M" or "0.8M".
    var populationText: String {
        if populationMillions >= 1 {
            return String(format: "%.1fM", populationMillions)
        } else {
            let thousands = populationMillions * 1000
            return String(format: "%.0fk", thousands)
        }
    }
}
