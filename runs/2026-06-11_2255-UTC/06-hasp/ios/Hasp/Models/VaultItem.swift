import Foundation

enum ItemKind: String, Codable, CaseIterable, Identifiable {
    case login, card, note

    var id: String { rawValue }
    var label: String {
        switch self {
        case .login: return "Login"
        case .card: return "Card"
        case .note: return "Secure note"
        }
    }
    var icon: String {
        switch self {
        case .login: return "key.fill"
        case .card: return "creditcard.fill"
        case .note: return "note.text"
        }
    }
}

struct VaultItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: ItemKind = .login
    var title: String = ""
    /// Login: username/email. Card: cardholder name. Note: unused.
    var username: String = ""
    /// Login: password. Card: card number. Note: the note body.
    var secret: String = ""
    /// Login: website. Card: expiry + CVC line. Note: unused.
    var detail: String = ""
    var notes: String = ""
    var isFavorite: Bool = false
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var usernameLabel: String {
        switch kind {
        case .login: return "Username / email"
        case .card: return "Cardholder name"
        case .note: return ""
        }
    }
    var secretLabel: String {
        switch kind {
        case .login: return "Password"
        case .card: return "Card number"
        case .note: return "Note"
        }
    }
    var detailLabel: String {
        switch kind {
        case .login: return "Website"
        case .card: return "Expiry / CVC"
        case .note: return ""
        }
    }
}

struct Vault: Codable {
    var version: Int = 1
    var items: [VaultItem] = []
}
