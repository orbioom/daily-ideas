import SwiftUI

/// The ten national real-estate exam topic areas Parcel covers.
///
/// Content is intentionally NATIONAL / general — clearly not state-specific law.
enum Topic: String, CaseIterable, Identifiable, Codable {
    case ownership
    case agency
    case valuation
    case financing
    case contracts
    case titleTransfer
    case disclosures
    case leasing
    case math
    case practice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ownership: return "Property Ownership & Land Use"
        case .agency: return "Agency & Fiduciary Duties"
        case .valuation: return "Valuation & Appraisal"
        case .financing: return "Financing"
        case .contracts: return "Contracts"
        case .titleTransfer: return "Transfer of Title"
        case .disclosures: return "Property Disclosures"
        case .leasing: return "Leasing & Property Management"
        case .math: return "Real Estate Math"
        case .practice: return "Practice of Real Estate"
        }
    }

    var shortTitle: String {
        switch self {
        case .ownership: return "Ownership"
        case .agency: return "Agency"
        case .valuation: return "Valuation"
        case .financing: return "Financing"
        case .contracts: return "Contracts"
        case .titleTransfer: return "Title"
        case .disclosures: return "Disclosures"
        case .leasing: return "Leasing"
        case .math: return "Math"
        case .practice: return "Practice"
        }
    }

    var systemImage: String {
        switch self {
        case .ownership: return "map"
        case .agency: return "person.2"
        case .valuation: return "chart.bar.doc.horizontal"
        case .financing: return "banknote"
        case .contracts: return "doc.text"
        case .titleTransfer: return "signature"
        case .disclosures: return "exclamationmark.shield"
        case .leasing: return "key"
        case .math: return "function"
        case .practice: return "briefcase"
        }
    }

    /// A distinct topic chip color, all harmonized with the warm palette.
    var chipColor: Color {
        switch self {
        case .ownership: return Color(red: 0x6E / 255.0, green: 0x8B / 255.0, blue: 0x52 / 255.0)   // olive
        case .agency: return Color(red: 0xC9 / 255.0, green: 0x86 / 255.0, blue: 0x3A / 255.0)       // amber
        case .valuation: return Color(red: 0x4F / 255.0, green: 0x84 / 255.0, blue: 0x96 / 255.0)    // teal
        case .financing: return Color(red: 0x2F / 255.0, green: 0x6F / 255.0, blue: 0x57 / 255.0)    // emerald
        case .contracts: return Color(red: 0x8A / 255.0, green: 0x5A / 255.0, blue: 0x44 / 255.0)    // umber
        case .titleTransfer: return Color(red: 0x5B / 255.0, green: 0x5E / 255.0, blue: 0x9C / 255.0) // indigo
        case .disclosures: return Color(red: 0xB2 / 255.0, green: 0x5A / 255.0, blue: 0x3A / 255.0)  // clay
        case .leasing: return Color(red: 0x96 / 255.0, green: 0x73 / 255.0, blue: 0x3A / 255.0)      // bronze
        case .math: return Color(red: 0x7A / 255.0, green: 0x52 / 255.0, blue: 0x8A / 255.0)         // plum
        case .practice: return Color(red: 0x4A / 255.0, green: 0x6E / 255.0, blue: 0x8A / 255.0)     // slate-blue
        }
    }

    /// A one-line description of the topic for browse/topic detail.
    var blurb: String {
        switch self {
        case .ownership: return "Estates, freehold & leasehold, encumbrances, easements, zoning, deed restrictions."
        case .agency: return "Agency types, disclosure, and the fiduciary duties (OLD CAR)."
        case .valuation: return "Sales comparison, cost & income approaches, GRM, and appraisal principles."
        case .financing: return "Mortgages & notes, FHA/VA/conventional, points, LTV, RESPA/TILA, foreclosure."
        case .contracts: return "Essential elements, offer & acceptance, contingencies, breach, contract types."
        case .titleTransfer: return "Deeds, title insurance, recording, adverse possession, escrow & closing."
        case .disclosures: return "Lead paint, material defects, and fair housing protected classes & exemptions."
        case .leasing: return "Lease types, landlord-tenant law, security deposits, and management."
        case .math: return "Commission, proration, area, interest, profit/loss, and tax calculations."
        case .practice: return "License law concepts, advertising, trust accounts, and antitrust."
        }
    }
}

/// One authored multiple-choice exam question.
///
/// Pure value type, authored as a bundled fixture (see `QuestionBank`).
/// `options` are stored in canonical order with `correctIndex` pointing to the
/// right one; the exam engine shuffles a presentation order per attempt while
/// keeping a stable mapping back to this canonical correct answer.
struct Question: Identifiable, Hashable, Codable {
    /// Stable identity (also used as the QuestionStat key).
    let id: Int
    let topic: Topic
    let prompt: String
    /// Exactly four options in canonical order.
    let options: [String]
    /// Index into `options` of the correct answer (0...3).
    let correctIndex: Int
    /// A 1–3 sentence explanation shown after answering.
    let explanation: String

    /// The correct option text, guarded against an out-of-range index.
    var correctOption: String {
        guard options.indices.contains(correctIndex) else { return options.first ?? "—" }
        return options[correctIndex]
    }
}
