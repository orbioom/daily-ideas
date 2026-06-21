import Foundation
import Observation
import SwiftUI

@Observable
final class SkyViewModel {
    var currentDate: Date = .now
    var city: CelestialCity = CityData.cities[0]
    var limitingMagnitude: Double = 4.5
    var showConstellationLines: Bool = true
    var showConstellationNames: Bool = true
    var showPlanets: Bool = true
    var showMoon: Bool = true
    var northUp: Bool = true

    private(set) var skyObjects: [SkyObject] = []
    private(set) var moonPhase: Double = 0
    private(set) var moonAge: Double = 0
    private(set) var sunAlt: Double = 0
    private(set) var isNighttime: Bool = true

    private var timer: Timer?

    func startLive() {
        updateSky()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateSky()
        }
    }

    func stopLive() {
        timer?.invalidate()
        timer = nil
    }

    func updateSky() {
        currentDate = .now
        recalculate()
    }

    func recalculate() {
        let jd = AstroMath.julianDate(from: currentDate)
        let gmst = AstroMath.gmstDeg(jd: jd)
        let lst = AstroMath.lstDeg(gmst: gmst, lonDeg: city.longitude)
        let lat = city.latitude

        moonPhase = AstroMath.moonPhase(jd: jd)
        moonAge = AstroMath.moonAge(jd: jd)

        var objects: [SkyObject] = []

        // Stars
        for star in StarCatalog.stars where star.magnitude <= limitingMagnitude + 0.5 {
            let (alt, az) = AstroMath.altAz(raDeg: star.raDeg, decDeg: star.decDeg, lstDeg: lst, latDeg: lat)
            var obj = SkyObject(name: star.name, kind: .star(id: star.id), raDeg: star.raDeg, decDeg: star.decDeg, magnitude: star.magnitude, bv: star.bv)
            obj.altDeg = alt
            obj.azDeg = az
            objects.append(obj)
        }

        // Sun
        let (sunRA, sunDec) = AstroMath.sunPosition(jd: jd)
        let (sAlt, sAz) = AstroMath.altAz(raDeg: sunRA, decDeg: sunDec, lstDeg: lst, latDeg: lat)
        sunAlt = sAlt
        isNighttime = sAlt < -6
        var sunObj = SkyObject(name: "Sun", kind: .sun, raDeg: sunRA, decDeg: sunDec, magnitude: -26.7)
        sunObj.altDeg = sAlt; sunObj.azDeg = sAz
        objects.append(sunObj)

        // Moon
        if showMoon {
            let (moonRA, moonDec) = AstroMath.moonPosition(jd: jd)
            let (mAlt, mAz) = AstroMath.altAz(raDeg: moonRA, decDeg: moonDec, lstDeg: lst, latDeg: lat)
            var moonObj = SkyObject(name: "Moon", kind: .moon, raDeg: moonRA, decDeg: moonDec, magnitude: -12.6)
            moonObj.altDeg = mAlt; moonObj.azDeg = mAz
            objects.append(moonObj)
        }

        // Planets
        if showPlanets {
            for planet in PlanetName.allCases {
                let (pRA, pDec) = AstroMath.planetPosition(planet: planet, jd: jd)
                let (pAlt, pAz) = AstroMath.altAz(raDeg: pRA, decDeg: pDec, lstDeg: lst, latDeg: lat)
                var pObj = SkyObject(name: planet.rawValue, kind: .planet(name: planet), raDeg: pRA, decDeg: pDec, magnitude: 1.5)
                pObj.altDeg = pAlt; pObj.azDeg = pAz
                objects.append(pObj)
            }
        }

        skyObjects = objects
    }

    // For the star map, compute screen position using stereographic projection
    func skyPoint(altDeg: Double, azDeg: Double, in size: CGSize) -> CGPoint? {
        guard altDeg > -2 else { return nil } // below horizon + small margin
        let r = (90.0 - altDeg) / 90.0
        let azRad = azDeg * .pi / 180.0
        let cx = size.width / 2
        let cy = size.height / 2
        let maxR = min(cx, cy) * 0.94

        // northUp: N at top (az=0 is up)
        let effectiveAz = northUp ? azRad : (azRad + .pi)
        let x = cx + maxR * r * sin(effectiveAz)
        let y = cy - maxR * r * cos(effectiveAz)
        return CGPoint(x: x, y: y)
    }

    func starDotRadius(magnitude: Double) -> CGFloat {
        let base = 4.5 - magnitude
        return max(1.0, min(6.0, CGFloat(base * 0.9 + 1.0)))
    }

    // What's visible tonight
    var visiblePlanets: [SkyObject] {
        skyObjects.filter {
            if case .planet = $0.kind { return $0.isAboveHorizon }
            return false
        }
    }

    var moonObject: SkyObject? {
        skyObjects.first { if case .moon = $0.kind { return true }; return false }
    }

    var moonPhaseName: String {
        switch moonAge {
        case 0..<1.85:   return "New Moon"
        case 1.85..<7.38: return "Waxing Crescent"
        case 7.38..<9.22: return "First Quarter"
        case 9.22..<14.76: return "Waxing Gibbous"
        case 14.76..<16.61: return "Full Moon"
        case 16.61..<22.15: return "Waning Gibbous"
        case 22.15..<23.99: return "Last Quarter"
        default: return "Waning Crescent"
        }
    }

    var brightestStars: [SkyObject] {
        skyObjects
            .filter { if case .star = $0.kind { return $0.isAboveHorizon && $0.magnitude < 2.0 }; return false }
            .sorted { $0.magnitude < $1.magnitude }
            .prefix(10)
            .map { $0 }
    }
}
