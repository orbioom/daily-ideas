import SwiftUI

/// US states + DC + territories for the state picker.
enum USState: String, CaseIterable, Identifiable, Codable {
    case AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA, HI, ID, IL, IN, IA, KS, KY, LA,
         ME, MD, MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NY, NC, ND, OH, OK,
         OR, PA, RI, SC, SD, TN, TX, UT, VT, VA, WA, WV, WI, WY,
         DC, PR, GU, VI, AS, MP

    var id: String { rawValue }

    var displayName: String {
        Self.names[rawValue] ?? rawValue
    }

    private static let names: [String: String] = [
        "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas",
        "CA": "California", "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware",
        "FL": "Florida", "GA": "Georgia", "HI": "Hawaii", "ID": "Idaho",
        "IL": "Illinois", "IN": "Indiana", "IA": "Iowa", "KS": "Kansas",
        "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine", "MD": "Maryland",
        "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota", "MS": "Mississippi",
        "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada",
        "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico", "NY": "New York",
        "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma",
        "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island", "SC": "South Carolina",
        "SD": "South Dakota", "TN": "Tennessee", "TX": "Texas", "UT": "Utah",
        "VT": "Vermont", "VA": "Virginia", "WA": "Washington", "WV": "West Virginia",
        "WI": "Wisconsin", "WY": "Wyoming", "DC": "Washington, D.C.",
        "PR": "Puerto Rico", "GU": "Guam", "VI": "U.S. Virgin Islands",
        "AS": "American Samoa", "MP": "Northern Mariana Islands",
    ]
}

/// App-wide preferences backed by @AppStorage, exposed as an @Observable object
/// so views can read/write them without each owning their own @AppStorage.
@Observable
final class AppPreferences {
    var stateCode: String {
        didSet { UserDefaults.standard.set(stateCode, forKey: Keys.state) }
    }
    var seniorExemption: Bool {
        didSet { UserDefaults.standard.set(seniorExemption, forKey: Keys.senior) }
    }
    var audioEnabled: Bool {
        didSet { UserDefaults.standard.set(audioEnabled, forKey: Keys.audio) }
    }
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: Keys.pro) }
    }

    enum Keys {
        static let state = "userStateCode"
        static let senior = "seniorExemption"
        static let audio = "audioEnabled"
        static let haptics = "hapticsEnabled"
        static let pro = "isPro"
    }

    init() {
        let d = UserDefaults.standard
        // Register sensible defaults once.
        d.register(defaults: [
            Keys.audio: true,
            Keys.haptics: true,
            Keys.senior: false,
            Keys.pro: false,
        ])
        self.stateCode = d.string(forKey: Keys.state) ?? ""
        self.seniorExemption = d.bool(forKey: Keys.senior)
        self.audioEnabled = d.bool(forKey: Keys.audio)
        self.hapticsEnabled = d.bool(forKey: Keys.haptics)
        self.isPro = d.bool(forKey: Keys.pro)
    }

    var state: USState? {
        USState(rawValue: stateCode)
    }

    var stateDisplay: String {
        state?.displayName ?? "Not set"
    }
}
