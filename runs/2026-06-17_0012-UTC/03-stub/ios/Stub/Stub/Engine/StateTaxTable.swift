import Foundation

/// A US state / territory with an *approximate* flat effective state income-tax rate.
///
/// These are deliberately simplified single representative rates applied to taxable
/// wages — real state systems are progressive with their own deductions and credits.
/// The nine no-income-tax states are 0%. Clearly labeled "approximate" in the UI.
struct USState: Identifiable, Hashable {
    let code: String       // e.g. "CA"
    let name: String       // e.g. "California"
    let effectiveRate: Decimal   // flat approximation, e.g. 0.06

    var id: String { code }
    var hasIncomeTax: Bool { effectiveRate > 0 }
}

enum StateTaxTable {

    /// All 50 states + DC, alphabetical by name.
    /// No-income-tax states: AK, FL, NV, NH, SD, TN, TX, WA, WY → 0%.
    /// (NH taxes only interest/dividends, not wages → 0% here.)
    static let all: [USState] = [
        USState(code: "AL", name: "Alabama",              effectiveRate: 0.045),
        USState(code: "AK", name: "Alaska",               effectiveRate: 0.0),
        USState(code: "AZ", name: "Arizona",              effectiveRate: 0.025),
        USState(code: "AR", name: "Arkansas",             effectiveRate: 0.039),
        USState(code: "CA", name: "California",           effectiveRate: 0.060),
        USState(code: "CO", name: "Colorado",             effectiveRate: 0.044),
        USState(code: "CT", name: "Connecticut",          effectiveRate: 0.050),
        USState(code: "DE", name: "Delaware",             effectiveRate: 0.052),
        USState(code: "DC", name: "District of Columbia", effectiveRate: 0.065),
        USState(code: "FL", name: "Florida",              effectiveRate: 0.0),
        USState(code: "GA", name: "Georgia",              effectiveRate: 0.0539),
        USState(code: "HI", name: "Hawaii",               effectiveRate: 0.070),
        USState(code: "ID", name: "Idaho",                effectiveRate: 0.053),
        USState(code: "IL", name: "Illinois",             effectiveRate: 0.0495),
        USState(code: "IN", name: "Indiana",              effectiveRate: 0.030),
        USState(code: "IA", name: "Iowa",                 effectiveRate: 0.038),
        USState(code: "KS", name: "Kansas",               effectiveRate: 0.050),
        USState(code: "KY", name: "Kentucky",             effectiveRate: 0.040),
        USState(code: "LA", name: "Louisiana",            effectiveRate: 0.030),
        USState(code: "ME", name: "Maine",                effectiveRate: 0.058),
        USState(code: "MD", name: "Maryland",             effectiveRate: 0.050),
        USState(code: "MA", name: "Massachusetts",        effectiveRate: 0.050),
        USState(code: "MI", name: "Michigan",             effectiveRate: 0.0425),
        USState(code: "MN", name: "Minnesota",            effectiveRate: 0.060),
        USState(code: "MS", name: "Mississippi",          effectiveRate: 0.044),
        USState(code: "MO", name: "Missouri",             effectiveRate: 0.047),
        USState(code: "MT", name: "Montana",              effectiveRate: 0.055),
        USState(code: "NE", name: "Nebraska",             effectiveRate: 0.052),
        USState(code: "NV", name: "Nevada",               effectiveRate: 0.0),
        USState(code: "NH", name: "New Hampshire",        effectiveRate: 0.0),
        USState(code: "NJ", name: "New Jersey",           effectiveRate: 0.050),
        USState(code: "NM", name: "New Mexico",           effectiveRate: 0.047),
        USState(code: "NY", name: "New York",             effectiveRate: 0.055),
        USState(code: "NC", name: "North Carolina",       effectiveRate: 0.0425),
        USState(code: "ND", name: "North Dakota",         effectiveRate: 0.020),
        USState(code: "OH", name: "Ohio",                 effectiveRate: 0.035),
        USState(code: "OK", name: "Oklahoma",             effectiveRate: 0.0475),
        USState(code: "OR", name: "Oregon",               effectiveRate: 0.085),
        USState(code: "PA", name: "Pennsylvania",         effectiveRate: 0.0307),
        USState(code: "RI", name: "Rhode Island",         effectiveRate: 0.045),
        USState(code: "SC", name: "South Carolina",       effectiveRate: 0.055),
        USState(code: "SD", name: "South Dakota",         effectiveRate: 0.0),
        USState(code: "TN", name: "Tennessee",            effectiveRate: 0.0),
        USState(code: "TX", name: "Texas",                effectiveRate: 0.0),
        USState(code: "UT", name: "Utah",                 effectiveRate: 0.0455),
        USState(code: "VT", name: "Vermont",              effectiveRate: 0.060),
        USState(code: "VA", name: "Virginia",             effectiveRate: 0.0525),
        USState(code: "WA", name: "Washington",           effectiveRate: 0.0),
        USState(code: "WV", name: "West Virginia",        effectiveRate: 0.051),
        USState(code: "WI", name: "Wisconsin",            effectiveRate: 0.053),
        USState(code: "WY", name: "Wyoming",              effectiveRate: 0.0)
    ]

    /// Fast lookup by 2-letter code; falls back to the first entry if missing.
    static func state(forCode code: String) -> USState {
        all.first(where: { $0.code == code }) ?? defaultState
    }

    /// Sensible default used when a stored code is unknown.
    static let defaultState = USState(code: "CA", name: "California", effectiveRate: 0.060)
}
