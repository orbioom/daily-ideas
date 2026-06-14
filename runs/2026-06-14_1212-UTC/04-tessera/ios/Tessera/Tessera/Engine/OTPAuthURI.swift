import Foundation

/// A parsed `otpauth://` URI. Used for QR import, paste-URI import, and export.
///
/// Format (Key Uri Format):
/// `otpauth://TYPE/LABEL?secret=...&issuer=...&algorithm=...&digits=...&period=...&counter=...`
/// where TYPE is `totp` or `hotp` and LABEL is `Issuer:account` (issuer prefix optional).
struct OTPAuthURI: Equatable {
    var type: OTPType
    var issuer: String
    var accountName: String
    var secretBase32: String
    var algorithm: OTPAlgorithm
    var digits: Int
    var period: Int
    var counter: Int

    /// Parse an `otpauth://` string. Tolerant of URL-encoding, missing optional
    /// params (defaults: SHA1 / 6 digits / period 30 / counter 0), and an
    /// `issuer:` prefix in the label. Returns `nil` if there is no valid secret.
    static func parse(_ string: String) -> OTPAuthURI? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return nil }
        guard components.scheme?.lowercased() == "otpauth" else { return nil }

        let type = OTPType.from(host: components.host)

        // Query items → dictionary (last value wins; keys lowercased).
        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let value = item.value {
                query[item.name.lowercased()] = value
            }
        }

        // Secret is mandatory.
        guard let rawSecret = query["secret"], !rawSecret.isEmpty else { return nil }
        // Validate it decodes; if not, reject so we never store a dead secret.
        guard Base32.decode(rawSecret) != nil else { return nil }

        // Label path: strip leading "/", URL-decode, split "Issuer:account".
        var labelPath = components.path
        if labelPath.hasPrefix("/") { labelPath.removeFirst() }
        let decodedLabel = labelPath.removingPercentEncoding ?? labelPath

        var labelIssuer = ""
        var accountName = decodedLabel
        if let colon = decodedLabel.firstIndex(of: ":") {
            labelIssuer = String(decodedLabel[decodedLabel.startIndex..<colon])
                .trimmingCharacters(in: .whitespaces)
            let after = decodedLabel.index(after: colon)
            accountName = String(decodedLabel[after...]).trimmingCharacters(in: .whitespaces)
        }

        // Issuer query param takes precedence over the label prefix.
        let queryIssuer = (query["issuer"]?.removingPercentEncoding ?? query["issuer"]) ?? ""
        let issuer = !queryIssuer.isEmpty ? queryIssuer : labelIssuer

        let algorithm = OTPAlgorithm.from(uriValue: query["algorithm"])
        let digits = OTPGenerator.clampDigits(Int(query["digits"] ?? "") ?? 6)
        let period = max(Int(query["period"] ?? "") ?? 30, 1)
        let counter = max(Int(query["counter"] ?? "") ?? 0, 0)

        return OTPAuthURI(type: type,
                          issuer: issuer,
                          accountName: accountName.isEmpty && !issuer.isEmpty ? issuer : accountName,
                          secretBase32: rawSecret.trimmingCharacters(in: .whitespaces),
                          algorithm: algorithm,
                          digits: digits,
                          period: period,
                          counter: counter)
    }

    /// Serialize back to a canonical `otpauth://` URI (for export / QR regeneration).
    func serialized() -> String {
        var labelComponents: [String] = []
        if !issuer.isEmpty { labelComponents.append(issuer) }
        labelComponents.append(accountName.isEmpty ? "account" : accountName)
        let label = labelComponents.joined(separator: ":")

        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = type.uriValue
        components.path = "/" + label

        var items: [URLQueryItem] = [
            URLQueryItem(name: "secret", value: secretBase32),
            URLQueryItem(name: "algorithm", value: algorithm.uriValue),
            URLQueryItem(name: "digits", value: String(OTPGenerator.clampDigits(digits)))
        ]
        if !issuer.isEmpty {
            items.insert(URLQueryItem(name: "issuer", value: issuer), at: 1)
        }
        switch type {
        case .totp:
            items.append(URLQueryItem(name: "period", value: String(max(period, 1))))
        case .hotp:
            items.append(URLQueryItem(name: "counter", value: String(max(counter, 0))))
        }
        components.queryItems = items

        return components.url?.absoluteString
            ?? "otpauth://\(type.uriValue)/\(label)?secret=\(secretBase32)"
    }
}
