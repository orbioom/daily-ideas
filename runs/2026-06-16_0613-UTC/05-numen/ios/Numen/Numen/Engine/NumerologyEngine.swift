import Foundation

/// Configuration the engine reads from app settings.
struct NumerologyConfig: Equatable {
    var system: NumerologySystem
    var preserveMasterNumbers: Bool
}

/// Which core/position a number occupies — used to frame the interpretation.
enum NumberPosition: String, CaseIterable, Identifiable {
    case lifePath = "Life Path"
    case expression = "Expression"
    case soulUrge = "Soul Urge"
    case personality = "Personality"
    case birthday = "Birthday"
    case maturity = "Maturity"
    case personalYear = "Personal Year"
    case personalMonth = "Personal Month"
    case personalDay = "Personal Day"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .lifePath: return "Your life's central lesson and path"
        case .expression: return "Your natural talents and how you build a life"
        case .soulUrge: return "What your heart truly longs for"
        case .personality: return "The self the world meets first"
        case .birthday: return "A specific gift you carry"
        case .maturity: return "The goal your later years move toward"
        case .personalYear: return "The theme of your current annual cycle"
        case .personalMonth: return "The texture of this month"
        case .personalDay: return "The tone of today"
        }
    }

    /// SF Symbol used on the card.
    var symbol: String {
        switch self {
        case .lifePath: return "signpost.right.fill"
        case .expression: return "sparkles"
        case .soulUrge: return "heart.fill"
        case .personality: return "theatermasks.fill"
        case .birthday: return "gift.fill"
        case .maturity: return "leaf.fill"
        case .personalYear: return "calendar"
        case .personalMonth: return "calendar.day.timeline.left"
        case .personalDay: return "sun.max.fill"
        }
    }
}

/// The result of a digit reduction, retaining the trail and any karmic-debt flag.
struct ReductionResult: Equatable {
    /// The sum before any reduction (e.g. 38 for "MICHAEL" total).
    let rawSum: Int
    /// Final reduced value (1–9, or 11/22/33 when preserved).
    let value: Int
    /// Whether `value` is a master number (11/22/33).
    let isMaster: Bool
    /// Karmic debt number (13/14/16/19) if one appeared in the reduction trail.
    let karmicDebt: Int?
    /// Human-readable derivation steps, e.g. ["38", "3 + 8 = 11"].
    let steps: [String]
}

/// One computed core number with everything the UI needs.
struct CoreNumber: Identifiable, Equatable {
    let position: NumberPosition
    let reduction: ReductionResult
    var id: String { position.rawValue }
    var value: Int { reduction.value }
}

/// Personal cycle numbers relative to a reference date.
struct PersonalCycles: Equatable {
    let referenceDate: Date
    let year: ReductionResult
    let month: ReductionResult
    let day: ReductionResult
}

/// A complete chart for a profile.
struct NumerologyChart: Equatable {
    let lifePath: CoreNumber
    let expression: CoreNumber
    let soulUrge: CoreNumber
    let personality: CoreNumber
    let birthday: CoreNumber
    let maturity: CoreNumber

    /// All six core numbers in display order.
    var cores: [CoreNumber] {
        [lifePath, expression, soulUrge, personality, birthday, maturity]
    }

    /// Distinct karmic-debt numbers found anywhere in the chart.
    var karmicDebts: [Int] {
        let found = cores.compactMap { $0.reduction.karmicDebt }
        return Array(Set(found)).sorted()
    }

    /// Distinct master numbers present among the core values.
    var masterNumbers: [Int] {
        let found = cores.filter { $0.reduction.isMaster }.map { $0.value }
        return Array(Set(found)).sorted()
    }
}

/// Pure numerology mathematics. No state, no I/O — fully testable.
enum NumerologyEngine {

    // MARK: Letter maps

    /// Pythagorean: A=1…I=9, J=1…R=9, S=1…Z=8 (i.e. (position-1) % 9 + 1).
    static func pythagoreanValue(for letter: Character) -> Int? {
        guard let scalar = letter.asciiUppercasedLetterIndex else { return nil }
        return (scalar - 1) % 9 + 1
    }

    /// Chaldean mapping (1–8; 9 is reserved/sacred and never assigned to a letter).
    private static let chaldeanMap: [Character: Int] = [
        "A": 1, "I": 1, "J": 1, "Q": 1, "Y": 1,
        "B": 2, "K": 2, "R": 2,
        "C": 3, "G": 3, "L": 3, "S": 3,
        "D": 4, "M": 4, "T": 4,
        "E": 5, "H": 5, "N": 5, "X": 5,
        "U": 6, "V": 6, "W": 6,
        "O": 7, "Z": 7,
        "F": 8, "P": 8
    ]

    static func chaldeanValue(for letter: Character) -> Int? {
        guard let scalar = letter.asciiUppercasedLetterIndex else { return nil }
        let upper = Character(UnicodeScalar(UInt8(64 + scalar)))
        return chaldeanMap[upper]
    }

    static func letterValue(for letter: Character, system: NumerologySystem) -> Int? {
        switch system {
        case .pythagorean: return pythagoreanValue(for: letter)
        case .chaldean: return chaldeanValue(for: letter)
        }
    }

    private static let vowels: Set<Character> = ["A", "E", "I", "O", "U"]

    /// Whether a character is treated as a vowel. Y is treated as a vowel only
    /// when it functions as one — here we keep it deterministic and simple:
    /// Y counts as a vowel (a common convention) so Soul Urge captures it.
    static func isVowel(_ letter: Character) -> Bool {
        guard let scalar = letter.asciiUppercasedLetterIndex else { return false }
        let upper = Character(UnicodeScalar(UInt8(64 + scalar)))
        return vowels.contains(upper) || upper == "Y"
    }

    // MARK: Reduction

    /// Reduce a sum to a single digit while optionally preserving master numbers,
    /// recording each step and detecting karmic-debt numbers in the trail.
    static func reduce(_ initial: Int, preserveMasters: Bool, recordRaw: Bool = true) -> ReductionResult {
        var steps: [String] = []
        var current = max(0, initial)
        var karmic: Int? = (Self.karmicDebtNumbers.contains(initial)) ? initial : nil

        if recordRaw { steps.append("\(current)") }

        while current > 9 {
            if preserveMasters && Self.masterValues.contains(current) {
                break
            }
            let digits = Self.digits(of: current)
            let next = digits.reduce(0, +)
            let expr = digits.map(String.init).joined(separator: " + ")
            steps.append("\(expr) = \(next)")
            if Self.karmicDebtNumbers.contains(next), karmic == nil {
                karmic = next
            }
            current = next
        }

        let isMaster = Self.masterValues.contains(current)
        return ReductionResult(
            rawSum: initial,
            value: current,
            isMaster: isMaster,
            karmicDebt: karmic,
            steps: steps
        )
    }

    private static let masterValues: Set<Int> = [11, 22, 33]
    static let karmicDebtNumbers: Set<Int> = [13, 14, 16, 19]

    private static func digits(of n: Int) -> [Int] {
        guard n > 0 else { return [0] }
        var value = n
        var out: [Int] = []
        while value > 0 {
            out.append(value % 10)
            value /= 10
        }
        return out.reversed()
    }

    // MARK: Name-based cores

    /// Sum of all letters in a name string for a given letter predicate.
    private static func nameSum(_ name: String, system: NumerologySystem, include: (Character) -> Bool) -> Int {
        name.reduce(0) { partial, char in
            guard include(char), let value = letterValue(for: char, system: system) else { return partial }
            return partial + value
        }
    }

    /// Expression / Destiny — all letters.
    static func expression(name: String, config: NumerologyConfig) -> ReductionResult {
        let sum = nameSum(name, system: config.system) { _ in true }
        return reduce(sum, preserveMasters: config.preserveMasterNumbers)
    }

    /// Soul Urge — vowels only.
    static func soulUrge(name: String, config: NumerologyConfig) -> ReductionResult {
        let sum = nameSum(name, system: config.system) { isVowel($0) }
        return reduce(sum, preserveMasters: config.preserveMasterNumbers)
    }

    /// Personality — consonants only.
    static func personality(name: String, config: NumerologyConfig) -> ReductionResult {
        let sum = nameSum(name, system: config.system) { char in
            char.asciiUppercasedLetterIndex != nil && !isVowel(char)
        }
        return reduce(sum, preserveMasters: config.preserveMasterNumbers)
    }

    // MARK: Date-based cores

    private static func components(of date: Date) -> (year: Int, month: Int, day: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Life Path — reduce month, day, year separately, then sum and reduce.
    /// This is the most widely accepted method and preserves masters correctly.
    static func lifePath(birthdate: Date, config: NumerologyConfig) -> ReductionResult {
        let parts = components(of: birthdate)
        let m = reduce(parts.month, preserveMasters: config.preserveMasterNumbers, recordRaw: false)
        let d = reduce(parts.day, preserveMasters: config.preserveMasterNumbers, recordRaw: false)
        let y = reduce(parts.year, preserveMasters: config.preserveMasterNumbers, recordRaw: false)
        let total = m.value + d.value + y.value
        var result = reduce(total, preserveMasters: config.preserveMasterNumbers)
        // Prepend a clear derivation line showing the component reductions.
        let header = "Month \(m.value) + Day \(d.value) + Year \(y.value) = \(total)"
        result = ReductionResult(
            rawSum: total,
            value: result.value,
            isMaster: result.isMaster,
            karmicDebt: result.karmicDebt,
            steps: [header] + result.steps.dropFirst()
        )
        return result
    }

    /// Birthday number — the day of the month, reduced.
    static func birthday(birthdate: Date, config: NumerologyConfig) -> ReductionResult {
        let parts = components(of: birthdate)
        return reduce(parts.day, preserveMasters: config.preserveMasterNumbers)
    }

    // MARK: Maturity

    static func maturity(lifePath: ReductionResult, expression: ReductionResult, config: NumerologyConfig) -> ReductionResult {
        let total = lifePath.value + expression.value
        var result = reduce(total, preserveMasters: config.preserveMasterNumbers)
        let header = "Life Path \(lifePath.value) + Expression \(expression.value) = \(total)"
        result = ReductionResult(
            rawSum: total,
            value: result.value,
            isMaster: result.isMaster,
            karmicDebt: result.karmicDebt,
            steps: [header] + result.steps.dropFirst()
        )
        return result
    }

    // MARK: Full chart

    static func chart(for profile: Profile, config: NumerologyConfig) -> NumerologyChart {
        let name = profile.fullName
        let lp = lifePath(birthdate: profile.birthdate, config: config)
        let ex = expression(name: name, config: config)
        let su = soulUrge(name: name, config: config)
        let pe = personality(name: name, config: config)
        let bd = birthday(birthdate: profile.birthdate, config: config)
        let mt = maturity(lifePath: lp, expression: ex, config: config)
        return NumerologyChart(
            lifePath: CoreNumber(position: .lifePath, reduction: lp),
            expression: CoreNumber(position: .expression, reduction: ex),
            soulUrge: CoreNumber(position: .soulUrge, reduction: su),
            personality: CoreNumber(position: .personality, reduction: pe),
            birthday: CoreNumber(position: .birthday, reduction: bd),
            maturity: CoreNumber(position: .maturity, reduction: mt)
        )
    }

    // MARK: Personal cycles

    /// Personal Year/Month/Day for a profile relative to a reference date.
    static func personalCycles(for profile: Profile, on referenceDate: Date, config: NumerologyConfig) -> PersonalCycles {
        let birth = components(of: profile.birthdate)
        let ref = components(of: referenceDate)

        // Personal Year: reduce(birthMonth) + reduce(birthDay) + reduce(currentYear).
        let bm = reduce(birth.month, preserveMasters: config.preserveMasterNumbers, recordRaw: false).value
        let bdv = reduce(birth.day, preserveMasters: config.preserveMasterNumbers, recordRaw: false).value
        let cy = reduce(ref.year, preserveMasters: config.preserveMasterNumbers, recordRaw: false).value
        let yearTotal = bm + bdv + cy
        var yearResult = reduce(yearTotal, preserveMasters: config.preserveMasterNumbers)
        yearResult = ReductionResult(
            rawSum: yearTotal,
            value: yearResult.value,
            isMaster: yearResult.isMaster,
            karmicDebt: yearResult.karmicDebt,
            steps: ["Birth month \(bm) + birth day \(bdv) + year \(cy) = \(yearTotal)"] + yearResult.steps.dropFirst()
        )

        // Personal Month: personalYear + currentMonth.
        let monthTotal = yearResult.value + reduce(ref.month, preserveMasters: config.preserveMasterNumbers, recordRaw: false).value
        var monthResult = reduce(monthTotal, preserveMasters: config.preserveMasterNumbers)
        monthResult = ReductionResult(
            rawSum: monthTotal,
            value: monthResult.value,
            isMaster: monthResult.isMaster,
            karmicDebt: monthResult.karmicDebt,
            steps: ["Personal Year \(yearResult.value) + month \(ref.month) = \(monthTotal)"] + monthResult.steps.dropFirst()
        )

        // Personal Day: personalMonth + currentDay.
        let dayTotal = monthResult.value + reduce(ref.day, preserveMasters: config.preserveMasterNumbers, recordRaw: false).value
        var dayResult = reduce(dayTotal, preserveMasters: config.preserveMasterNumbers)
        dayResult = ReductionResult(
            rawSum: dayTotal,
            value: dayResult.value,
            isMaster: dayResult.isMaster,
            karmicDebt: dayResult.karmicDebt,
            steps: ["Personal Month \(monthResult.value) + day \(ref.day) = \(dayTotal)"] + dayResult.steps.dropFirst()
        )

        return PersonalCycles(referenceDate: referenceDate, year: yearResult, month: monthResult, day: dayResult)
    }
}

private extension Character {
    /// 1...26 for A–Z (case-insensitive), nil for anything else.
    var asciiUppercasedLetterIndex: Int? {
        guard let ascii = uppercased().unicodeScalars.first?.value,
              ascii >= 65, ascii <= 90 else { return nil }
        return Int(ascii) - 64
    }
}
