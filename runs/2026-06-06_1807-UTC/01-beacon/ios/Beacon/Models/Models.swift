import Foundation
import SwiftData

/// Amateur radio band. Raw value is the conventional wavelength label; each
/// carries a representative center frequency in MHz for sorting and display.
enum Band: String, Codable, CaseIterable, Identifiable {
    case m160 = "160m", m80 = "80m", m60 = "60m", m40 = "40m", m30 = "30m"
    case m20 = "20m", m17 = "17m", m15 = "15m", m12 = "12m", m10 = "10m"
    case m6 = "6m", m2 = "2m", cm70 = "70cm", cm23 = "23cm"
    var id: String { rawValue }
    var label: String { rawValue }
    /// Representative dial frequency (MHz) used as a default and for ordering.
    var centerMHz: Double {
        switch self {
        case .m160: return 1.840; case .m80: return 3.700; case .m60: return 5.357
        case .m40: return 7.100; case .m30: return 10.120; case .m20: return 14.200
        case .m17: return 18.120; case .m15: return 21.250; case .m12: return 24.940
        case .m10: return 28.400; case .m6: return 50.150; case .m2: return 144.200
        case .cm70: return 432.100; case .cm23: return 1296.100
        }
    }
}

/// Operating mode for a contact.
enum Mode: String, Codable, CaseIterable, Identifiable {
    case ssb = "SSB", cw = "CW", fm = "FM", am = "AM"
    case ft8 = "FT8", ft4 = "FT4", rtty = "RTTY", psk = "PSK31", digital = "Digital"
    var id: String { rawValue }
    var isDigital: Bool { [.ft8, .ft4, .rtty, .psk, .digital].contains(self) }
    /// A sensible default signal report token for the mode.
    var defaultReport: String { isDigital ? "+00" : (self == .cw ? "599" : "59") }
}

/// What kind of outing a group of contacts belongs to.
enum ActivationKind: String, Codable, CaseIterable, Identifiable {
    case pota = "POTA", sota = "SOTA", field = "Field Day", contest = "Contest", home = "Home"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .pota: return "tree"; case .sota: return "mountain.2"
        case .field: return "tent"; case .contest: return "trophy"; case .home: return "house"
        }
    }
    /// POTA needs 10 valid QSOs to count as an activation; others have no formal floor.
    var qsoTarget: Int { self == .pota ? 10 : 0 }
}

/// An outing — a park, summit, or session that owns its contacts.
@Model
final class Activation {
    var reference: String          // e.g. "US-1234" or summit ref; empty for casual home sessions
    var title: String
    var kindRaw: String
    var grid: String               // operator's grid for this outing
    var date: Date
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \QSO.activation)
    var qsos: [QSO]

    init(reference: String = "", title: String, kind: ActivationKind = .pota,
         grid: String = "", date: Date = .now, notes: String = "") {
        self.reference = reference
        self.title = title
        self.kindRaw = kind.rawValue
        self.grid = grid
        self.date = date
        self.notes = notes
        self.qsos = []
    }

    var kind: ActivationKind {
        get { ActivationKind(rawValue: kindRaw) ?? .pota }
        set { kindRaw = newValue.rawValue }
    }

    var qsoCount: Int { qsos.count }
    /// Whether a POTA-style target has been reached (true when no target applies).
    var isActivated: Bool { kind.qsoTarget == 0 ? !qsos.isEmpty : qsos.count >= kind.qsoTarget }
    var remainingForTarget: Int { max(0, kind.qsoTarget - qsos.count) }
}

/// A single logged contact (QSO).
@Model
final class QSO {
    var callsign: String
    var dateTime: Date
    var bandRaw: String
    var modeRaw: String
    var freqMHz: Double
    var rstSent: String
    var rstRcvd: String
    var theirGrid: String
    var theirName: String
    var theirQTH: String
    var confirmed: Bool
    var notes: String
    var activation: Activation?

    init(callsign: String, dateTime: Date = .now, band: Band = .m20, mode: Mode = .ssb,
         freqMHz: Double? = nil, rstSent: String = "", rstRcvd: String = "",
         theirGrid: String = "", theirName: String = "", theirQTH: String = "",
         confirmed: Bool = false, notes: String = "", activation: Activation? = nil) {
        self.callsign = callsign.uppercased()
        self.dateTime = dateTime
        self.bandRaw = band.rawValue
        self.modeRaw = mode.rawValue
        self.freqMHz = freqMHz ?? band.centerMHz
        self.rstSent = rstSent.isEmpty ? mode.defaultReport : rstSent
        self.rstRcvd = rstRcvd.isEmpty ? mode.defaultReport : rstRcvd
        self.theirGrid = theirGrid.uppercased()
        self.theirName = theirName
        self.theirQTH = theirQTH
        self.confirmed = confirmed
        self.notes = notes
        self.activation = activation
    }

    var band: Band {
        get { Band(rawValue: bandRaw) ?? .m20 }
        set { bandRaw = newValue.rawValue }
    }
    var mode: Mode {
        get { Mode(rawValue: modeRaw) ?? .ssb }
        set { modeRaw = newValue.rawValue }
    }
}
