import Foundation

/// Decodes the most common named & numeric HTML entities in pure Swift,
/// avoiding any dependency on NSAttributedString HTML parsing (which is
/// main-thread-bound and slow). Unknown entities are left intact.
enum HTMLEntities {
    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "copy": "©", "reg": "®", "trade": "™",
        "hellip": "…", "mdash": "—", "ndash": "–", "lsquo": "\u{2018}",
        "rsquo": "\u{2019}", "ldquo": "\u{201C}", "rdquo": "\u{201D}",
        "laquo": "«", "raquo": "»", "deg": "°", "plusmn": "±",
        "times": "×", "divide": "÷", "frac12": "½", "frac14": "¼",
        "frac34": "¾", "sect": "§", "para": "¶", "middot": "·",
        "bull": "•", "dagger": "†", "Dagger": "‡", "permil": "‰",
        "euro": "€", "pound": "£", "cent": "¢", "yen": "¥",
        "eacute": "é", "egrave": "è", "agrave": "à", "uuml": "ü",
        "ouml": "ö", "auml": "ä", "ntilde": "ñ", "ccedil": "ç",
        "ecirc": "ê", "ocirc": "ô", "acirc": "â", "icirc": "î",
        "aacute": "á", "iacute": "í", "oacute": "ó", "uacute": "ú",
        "Eacute": "É", "Aacute": "Á", "szlig": "ß", "thinsp": "\u{2009}"
    ]

    /// Replace entities in a string. Safe on any input; never throws.
    static func decode(_ input: String) -> String {
        guard input.contains("&") else { return input }
        var result = ""
        result.reserveCapacity(input.count)

        var iterator = input.startIndex
        while iterator < input.endIndex {
            let ch = input[iterator]
            if ch == "&", let semi = input[iterator...].firstIndex(of: ";"),
               input.distance(from: iterator, to: semi) <= 12 {
                let entity = String(input[input.index(after: iterator)..<semi])
                if let decoded = decodeEntity(entity) {
                    result.append(decoded)
                    iterator = input.index(after: semi)
                    continue
                }
            }
            result.append(ch)
            iterator = input.index(after: iterator)
        }
        return result
    }

    private static func decodeEntity(_ entity: String) -> String? {
        if entity.hasPrefix("#") {
            let numberPart = String(entity.dropFirst())
            let scalarValue: UInt32?
            if numberPart.hasPrefix("x") || numberPart.hasPrefix("X") {
                scalarValue = UInt32(numberPart.dropFirst(), radix: 16)
            } else {
                scalarValue = UInt32(numberPart)
            }
            if let value = scalarValue, let scalar = Unicode.Scalar(value) {
                return String(scalar)
            }
            return nil
        }
        return named[entity]
    }
}
