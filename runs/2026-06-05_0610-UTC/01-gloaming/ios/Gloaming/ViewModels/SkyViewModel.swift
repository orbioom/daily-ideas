import Foundation
import CoreLocation
import SwiftUI

@MainActor
final class SkyViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var place: Place { didSet { recompute() } }
    @Published var moments: [SunMoment] = []
    @Published var solarNoon: Date?
    @Published var elevation: Double = 0
    @Published var dayLength: String = "—"
    @Published var now = Date()
    @Published var usingDeviceLocation = false

    private let manager = CLLocationManager()
    private var timer: Timer?

    override init() {
        self.place = .london
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        recompute()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func tick() {
        now = Date()
        elevation = SolarCalculator.elevation(
            date: now, lat: place.lat, lon: place.lon,
            tz: place.tzOffsetHours(now))
    }

    func requestDeviceLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func select(_ p: Place) {
        usingDeviceLocation = false
        place = p
    }

    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManager(_ m: CLLocationManager,
                                     didUpdateLocations locs: [CLLocation]) {
        guard let c = locs.last?.coordinate else { return }
        Task { @MainActor in
            self.usingDeviceLocation = true
            self.place = Place(name: "Current location",
                               lat: c.latitude, lon: c.longitude,
                               tzIdentifier: nil)
        }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {}

    // MARK: - computation
    private func dateFrom(_ minutes: Double?, base: Date) -> Date? {
        guard let minutes else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = place.timeZone
        let midnight = cal.startOfDay(for: base)
        return midnight.addingTimeInterval(minutes * 60.0)
    }

    private func recompute() {
        let today = now
        let tz = place.tzOffsetHours(today)
        var list: [SunMoment] = []

        for p in SunPhase.morning {
            let m = SolarCalculator.eventMinutes(angle: p.3, date: today,
                lat: place.lat, lon: place.lon, tz: tz, rising: true)
            list.append(SunMoment(name: p.0, subtitle: p.1, symbol: p.2,
                                  date: dateFrom(m, base: today), tint: p.4))
        }
        let noonMin = SolarCalculator.solarNoonMinutes(date: today,
            lon: place.lon, tz: tz)
        solarNoon = dateFrom(noonMin, base: today)
        list.append(SunMoment(name: "Solar noon", subtitle: "Sun at its highest",
            symbol: "sun.max", date: solarNoon, tint: Color(red: 0.96, green: 0.83, blue: 0.5)))
        for p in SunPhase.evening {
            let m = SolarCalculator.eventMinutes(angle: p.3, date: today,
                lat: place.lat, lon: place.lon, tz: tz, rising: false)
            list.append(SunMoment(name: p.0, subtitle: p.1, symbol: p.2,
                                  date: dateFrom(m, base: today), tint: p.4))
        }
        moments = list

        // day length from sunrise/sunset
        if let rise = list.first(where: { $0.name == "Sunrise" })?.date,
           let set = list.first(where: { $0.name == "Sunset" })?.date {
            let s = Int(set.timeIntervalSince(rise))
            dayLength = String(format: "%dh %02dm", s / 3600, (s % 3600) / 60)
        } else {
            dayLength = place.lat > 0 ? "Polar day/night" : "Polar day/night"
        }
        elevation = SolarCalculator.elevation(date: today, lat: place.lat,
            lon: place.lon, tz: tz)
    }

    /// The moment most recently passed (for "now" highlighting).
    var currentPhaseIndex: Int {
        var idx = -1
        for (i, m) in moments.enumerated() {
            if let d = m.date, d <= now { idx = i }
        }
        return idx
    }
}
