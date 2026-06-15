import SwiftUI

/// The scannable code formats Stash can render on-device.
enum BarcodeFormat: String, Codable, CaseIterable, Identifiable {
    case code128
    case ean13
    case upca
    case qr
    case aztec
    case pdf417

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .code128: return "Code 128"
        case .ean13:   return "EAN-13"
        case .upca:    return "UPC-A"
        case .qr:      return "QR Code"
        case .aztec:   return "Aztec"
        case .pdf417:  return "PDF417"
        }
    }

    /// A short hint shown under the format picker describing valid input.
    var inputHint: String {
        switch self {
        case .code128: return "Any letters, digits, or symbols."
        case .ean13:   return "12 or 13 digits (retail product codes)."
        case .upca:    return "11 or 12 digits (US/Canada retail)."
        case .qr:      return "Any text, URL, or membership token."
        case .aztec:   return "Any text — common on transit & airline passes."
        case .pdf417:  return "Any text — common on IDs & boarding passes."
        }
    }

    /// True for 1-D (linear) symbologies, which render wide and short.
    var isLinear: Bool {
        switch self {
        case .code128, .ean13, .upca: return true
        case .qr, .aztec, .pdf417:    return false
        }
    }

    var symbol: String {
        switch self {
        case .qr:    return "qrcode"
        case .aztec: return "qrcode"
        default:     return "barcode"
        }
    }
}

/// Loyalty-card categories used for filtering, icons, and Insights charts.
enum CardCategory: String, Codable, CaseIterable, Identifiable {
    case grocery
    case pharmacy
    case coffee
    case retail
    case airline
    case fuel
    case dining
    case fitness
    case entertainment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grocery:       return "Grocery"
        case .pharmacy:      return "Pharmacy"
        case .coffee:        return "Coffee"
        case .retail:        return "Retail"
        case .airline:       return "Airline"
        case .fuel:          return "Fuel"
        case .dining:        return "Dining"
        case .fitness:       return "Fitness"
        case .entertainment: return "Entertainment"
        case .other:         return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .grocery:       return "cart.fill"
        case .pharmacy:      return "cross.case.fill"
        case .coffee:        return "cup.and.saucer.fill"
        case .retail:        return "bag.fill"
        case .airline:       return "airplane"
        case .fuel:          return "fuelpump.fill"
        case .dining:        return "fork.knife"
        case .fitness:       return "figure.run"
        case .entertainment: return "ticket.fill"
        case .other:         return "creditcard.fill"
        }
    }
}
