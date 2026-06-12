import Foundation

enum PayloadKind: String, CaseIterable, Codable, Identifiable {
    case url, text, wifi, contact, email, sms, phone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .url: return "Link"
        case .text: return "Text"
        case .wifi: return "Wi-Fi"
        case .contact: return "Contact"
        case .email: return "Email"
        case .sms: return "Message"
        case .phone: return "Phone"
        }
    }

    var symbol: String {
        switch self {
        case .url: return "link"
        case .text: return "text.alignleft"
        case .wifi: return "wifi"
        case .contact: return "person.crop.square.filled.and.at.rectangle"
        case .email: return "envelope"
        case .sms: return "message"
        case .phone: return "phone"
        }
    }
}

enum WifiSecurity: String, CaseIterable, Codable, Identifiable {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .wpa: return "WPA/WPA2/WPA3"
        case .wep: return "WEP"
        case .none: return "Open (no password)"
        }
    }
}

/// All editable fields for every payload kind. One struct keeps the form,
/// validation, and encoding in lockstep; unused fields are simply ignored.
struct PayloadDraft: Codable, Equatable {
    var kind: PayloadKind = .url

    var urlString = ""
    var text = ""

    var wifiSSID = ""
    var wifiPassword = ""
    var wifiSecurity: WifiSecurity = .wpa
    var wifiHidden = false

    var contactGivenName = ""
    var contactFamilyName = ""
    var contactOrganization = ""
    var contactPhone = ""
    var contactEmail = ""
    var contactURL = ""

    var emailAddress = ""
    var emailSubject = ""
    var emailBody = ""

    var smsNumber = ""
    var smsBody = ""

    var phoneNumber = ""

    // MARK: - Validation

    /// Human-readable problem with the current draft, or nil when encodable.
    var validationError: String? {
        switch kind {
        case .url:
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "Enter a link." }
            guard let url = URL(string: trimmed), url.scheme != nil || !trimmed.contains(" ") else {
                return "That doesn't look like a valid link."
            }
            return nil
        case .text:
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter some text." : nil
        case .wifi:
            if wifiSSID.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter the network name (SSID)." }
            if wifiSecurity != .none && wifiPassword.isEmpty { return "Enter the network password (or choose Open)." }
            return nil
        case .contact:
            let hasName = !contactGivenName.trimmingCharacters(in: .whitespaces).isEmpty
                || !contactFamilyName.trimmingCharacters(in: .whitespaces).isEmpty
            return hasName ? nil : "Enter at least a first or last name."
        case .email:
            let trimmed = emailAddress.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("@"), trimmed.contains(".") else { return "Enter a valid email address." }
            return nil
        case .sms:
            return smsNumber.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter a phone number." : nil
        case .phone:
            return phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter a phone number." : nil
        }
    }

    // MARK: - Encoding

    /// The exact string embedded in the QR code.
    func encoded() -> String {
        switch kind {
        case .url:
            var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            if URL(string: trimmed)?.scheme == nil {
                trimmed = "https://" + trimmed
            }
            return trimmed
        case .text:
            return text
        case .wifi:
            // WIFI:T:WPA;S:ssid;P:pass;H:true;;  (escape \ ; , : ")
            func esc(_ s: String) -> String {
                var out = ""
                for ch in s {
                    if "\\;,:\"".contains(ch) { out.append("\\") }
                    out.append(ch)
                }
                return out
            }
            var parts = "WIFI:T:\(wifiSecurity.rawValue);S:\(esc(wifiSSID));"
            if wifiSecurity != .none {
                parts += "P:\(esc(wifiPassword));"
            }
            if wifiHidden {
                parts += "H:true;"
            }
            return parts + ";"
        case .contact:
            var lines = ["BEGIN:VCARD", "VERSION:3.0"]
            let family = vEscape(contactFamilyName)
            let given = vEscape(contactGivenName)
            lines.append("N:\(family);\(given);;;")
            let full = [contactGivenName, contactFamilyName]
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: " ")
            lines.append("FN:\(vEscape(full))")
            if !contactOrganization.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.append("ORG:\(vEscape(contactOrganization))")
            }
            if !contactPhone.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.append("TEL;TYPE=CELL:\(contactPhone.trimmingCharacters(in: .whitespaces))")
            }
            if !contactEmail.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.append("EMAIL:\(contactEmail.trimmingCharacters(in: .whitespaces))")
            }
            if !contactURL.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.append("URL:\(contactURL.trimmingCharacters(in: .whitespaces))")
            }
            lines.append("END:VCARD")
            return lines.joined(separator: "\n")
        case .email:
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = emailAddress.trimmingCharacters(in: .whitespaces)
            var queryItems: [URLQueryItem] = []
            if !emailSubject.isEmpty { queryItems.append(URLQueryItem(name: "subject", value: emailSubject)) }
            if !emailBody.isEmpty { queryItems.append(URLQueryItem(name: "body", value: emailBody)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            return components.string ?? "mailto:\(emailAddress)"
        case .sms:
            let number = smsNumber.trimmingCharacters(in: .whitespaces)
            if smsBody.isEmpty { return "SMSTO:\(number)" }
            return "SMSTO:\(number):\(smsBody)"
        case .phone:
            return "tel:\(phoneNumber.trimmingCharacters(in: .whitespaces))"
        }
    }

    private func vEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
    }

    /// A sensible default title for saving to the library.
    var suggestedTitle: String {
        switch kind {
        case .url:
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            return URL(string: trimmed)?.host ?? (trimmed.isEmpty ? "Link" : trimmed)
        case .text:
            let line = text.split(separator: "\n").first.map(String.init) ?? "Text"
            return String(line.prefix(40))
        case .wifi: return wifiSSID.isEmpty ? "Wi-Fi network" : "Wi-Fi · \(wifiSSID)"
        case .contact:
            let full = [contactGivenName, contactFamilyName]
                .filter { !$0.isEmpty }.joined(separator: " ")
            return full.isEmpty ? "Contact" : full
        case .email: return emailAddress.isEmpty ? "Email" : emailAddress
        case .sms: return smsNumber.isEmpty ? "Message" : "SMS · \(smsNumber)"
        case .phone: return phoneNumber.isEmpty ? "Phone" : "Call · \(phoneNumber)"
        }
    }
}
