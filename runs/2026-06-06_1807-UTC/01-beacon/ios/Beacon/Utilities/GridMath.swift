import Foundation
import CoreLocation

/// Maidenhead locator math + great-circle geodesy. Pure value type, fully
/// crash-proof: every parser returns an optional, never force-unwraps.
///
/// A Maidenhead locator encodes a position as field/square/subsquare pairs,
/// e.g. "FN31pr". Amateur radio operators exchange these to know roughly where
/// a contact is — and from two of them you can derive distance and bearing.
enum GridMath {

    private static let fieldChars = Array("ABCDEFGHIJKLMNOPQR")
    private static let subChars   = Array("abcdefghijklmnopqrstuvwx")

    /// Validate a 4- or 6-character locator. Returns the normalized form
    /// (uppercase field, lowercase subsquare) or nil.
    static func normalize(_ raw: String) -> String? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard s.count == 4 || s.count == 6 else { return nil }
        let chars = Array(s)
        // Field A-R
        guard let f1 = upperIndex(chars[0], in: fieldChars), f1 >= 0,
              let f2 = upperIndex(chars[1], in: fieldChars), f2 >= 0 else { return nil }
        // Square 0-9
        guard chars[2].isNumber, chars[3].isNumber else { return nil }
        var out = String([fieldChars[f1], fieldChars[f2], chars[2], chars[3]])
        if s.count == 6 {
            guard let s1 = lowerIndex(chars[4]), let s2 = lowerIndex(chars[5]) else { return nil }
            out += String([subChars[s1], subChars[s2]])
        }
        return out
    }

    private static func upperIndex(_ c: Character, in arr: [Character]) -> Int? {
        let u = Character(c.uppercased())
        return arr.firstIndex(of: u)
    }
    private static func lowerIndex(_ c: Character) -> Int? {
        let l = Character(c.lowercased())
        return subChars.firstIndex(of: l)
    }

    /// Center coordinate of the cell a locator describes. nil if invalid.
    static func coordinate(of locator: String) -> CLLocationCoordinate2D? {
        guard let g = normalize(locator) else { return nil }
        let c = Array(g)
        guard let lonF = fieldChars.firstIndex(of: c[0]),
              let latF = fieldChars.firstIndex(of: c[1]),
              let lonS = c[2].wholeNumberValue,
              let latS = c[3].wholeNumberValue else { return nil }

        var lon = Double(lonF) * 20.0 + Double(lonS) * 2.0
        var lat = Double(latF) * 10.0 + Double(latS) * 1.0

        if g.count == 6, let sub1 = subChars.firstIndex(of: c[4]),
           let sub2 = subChars.firstIndex(of: c[5]) {
            lon += (Double(sub1) + 0.5) * (2.0 / 24.0)
            lat += (Double(sub2) + 0.5) * (1.0 / 24.0)
        } else {
            lon += 1.0   // center of 2° square
            lat += 0.5   // center of 1° square
        }
        return CLLocationCoordinate2D(latitude: lat - 90.0, longitude: lon - 180.0)
    }

    /// Encode a coordinate as a 6-character locator. Clamped to valid ranges.
    static func locator(for coord: CLLocationCoordinate2D) -> String {
        let lat = min(max(coord.latitude, -90), 89.99999) + 90.0
        let lon = min(max(coord.longitude, -180), 179.99999) + 180.0
        let lonF = Int(lon / 20.0)
        let latF = Int(lat / 10.0)
        let lonS = Int((lon.truncatingRemainder(dividingBy: 20.0)) / 2.0)
        let latS = Int(lat.truncatingRemainder(dividingBy: 10.0))
        let lonSub = Int((lon.truncatingRemainder(dividingBy: 2.0)) * 12.0)
        let latSub = Int((lat.truncatingRemainder(dividingBy: 1.0)) * 24.0)
        func clampIdx(_ i: Int, _ n: Int) -> Int { min(max(i, 0), n - 1) }
        return String([
            fieldChars[clampIdx(lonF, 18)], fieldChars[clampIdx(latF, 18)],
            Character("\(clampIdx(lonS, 10))"), Character("\(clampIdx(latS, 10))"),
            subChars[clampIdx(lonSub, 24)], subChars[clampIdx(latSub, 24)]
        ])
    }

    private static let earthRadiusKm = 6371.0088

    /// Great-circle distance in kilometers between two locators. nil if either invalid.
    static func distanceKm(from a: String, to b: String) -> Double? {
        guard let c1 = coordinate(of: a), let c2 = coordinate(of: b) else { return nil }
        return distanceKm(c1, c2)
    }

    static func distanceKm(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(h), sqrt(max(0, 1 - h)))
        return earthRadiusKm * c
    }

    /// Initial great-circle bearing in degrees (0-360) from a to b. nil if invalid.
    static func bearing(from a: String, to b: String) -> Double? {
        guard let c1 = coordinate(of: a), let c2 = coordinate(of: b) else { return nil }
        return bearing(c1, c2)
    }

    static func bearing(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let brng = atan2(y, x) * 180 / .pi
        return (brng + 360).truncatingRemainder(dividingBy: 360)
    }

    /// 16-point compass label for a bearing.
    static func compass(_ bearing: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let idx = Int((bearing / 22.5).rounded()) % 16
        return dirs[max(0, idx)]
    }
}
