import Foundation
import CoreLocation
import Observation
import SwiftUI

enum RunState {
    case idle
    case requestingPermission
    case ready
    case running
    case paused
    case finished
}

@Observable
final class RunEngine: NSObject {
    private(set) var state: RunState = .idle
    private(set) var locationPermission: CLAuthorizationStatus = .notDetermined

    private(set) var elapsedSeconds: Double = 0
    private(set) var distanceMeters: Double = 0
    private(set) var currentSpeedMps: Double = 0
    private(set) var elevationGainMeters: Double = 0
    private(set) var currentPaceSecondsPerKm: Double = 0
    private(set) var route: [CLLocation] = []
    private(set) var currentLocation: CLLocation?

    var activityType: ActivityType = .run
    var locationError: String? = nil

    private var locationManager: CLLocationManager?
    private var timer: Timer?
    private var timerStartDate: Date?
    private var lastLocation: CLLocation?
    private var lastAltitude: Double?

    override init() {
        super.init()
    }

    func requestPermission() {
        if locationManager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 5
            self.locationManager = manager
        }
        state = .requestingPermission
        locationManager?.requestWhenInUseAuthorization()
    }

    func startRun() {
        guard state == .ready || state == .paused else { return }

        if state == .ready {
            elapsedSeconds = 0
            distanceMeters = 0
            elevationGainMeters = 0
            currentSpeedMps = 0
            currentPaceSecondsPerKm = 0
            route = []
            lastLocation = nil
            lastAltitude = nil
        }

        state = .running
        locationManager?.startUpdatingLocation()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false

        startTimer()
    }

    func pauseRun() {
        guard state == .running else { return }
        state = .paused
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    func resumeRun() {
        guard state == .paused else { return }
        startRun()
    }

    func finishRun() -> RunSession? {
        guard state == .running || state == .paused else { return nil }

        locationManager?.stopUpdatingLocation()
        locationManager?.allowsBackgroundLocationUpdates = false
        timer?.invalidate()
        timer = nil

        let session = buildSession()
        state = .finished
        return session
    }

    func resetToReady() {
        state = .ready
        route = []
        elapsedSeconds = 0
        distanceMeters = 0
        currentSpeedMps = 0
        elevationGainMeters = 0
        currentPaceSecondsPerKm = 0
        lastLocation = nil
        lastAltitude = nil
        timerStartDate = nil
    }

    private func startTimer() {
        timer?.invalidate()
        let alreadyElapsed = elapsedSeconds
        let start = Date().addingTimeInterval(-alreadyElapsed)
        timerStartDate = start
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsedSeconds = -start.timeIntervalSinceNow
                self.updatePace()
            }
        }
    }

    private func updatePace() {
        guard distanceMeters > 50 && elapsedSeconds > 0 else { return }
        let distKm = distanceMeters / 1000
        currentPaceSecondsPerKm = distKm > 0 ? elapsedSeconds / distKm : 0
    }

    private func buildSession() -> RunSession {
        let session = RunSession(activityType: activityType)
        session.duration = elapsedSeconds
        session.distanceMeters = distanceMeters
        session.elevationGainMeters = elevationGainMeters
        session.averageSpeedMps = elapsedSeconds > 0 ? distanceMeters / elapsedSeconds : 0
        session.maxSpeedMps = route.map { $0.speed }.filter { $0 >= 0 }.max() ?? 0

        let durationHours = elapsedSeconds / 3600
        let met: Double
        switch activityType {
        case .run: met = 8.5
        case .walk: met = 3.5
        case .hike: met = 5.0
        }
        session.calories = met * 70 * durationHours

        session.points = route.map { RoutePoint(location: $0) }
        session.points.forEach { $0.session = session }
        return session
    }

    var elapsedFormatted: String {
        let s = Int(elapsedSeconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }

    var paceFormatted: String {
        guard currentPaceSecondsPerKm > 0 && currentPaceSecondsPerKm < 3600 else { return "--:--" }
        let m = Int(currentPaceSecondsPerKm) / 60
        let s = Int(currentPaceSecondsPerKm) % 60
        return String(format: "%d:%02d", m, s)
    }

    var distanceFormatted: String {
        String(format: "%.2f km", distanceMeters / 1000)
    }

    deinit {
        timer?.invalidate()
        locationManager?.stopUpdatingLocation()
    }
}

extension RunEngine: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationPermission = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.state == .requestingPermission || self.state == .idle {
                    self.state = .ready
                }
                self.locationError = nil
            case .denied, .restricted:
                self.state = .idle
                self.locationError = "Location access denied. Please enable in Settings."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .running else { return }

        for location in locations {
            guard location.horizontalAccuracy >= 0,
                  location.horizontalAccuracy <= 30 else { continue }

            Task { @MainActor in
                self.currentLocation = location
                if location.speed >= 0 {
                    self.currentSpeedMps = location.speed
                }

                if let last = self.lastLocation {
                    let delta = location.distance(from: last)
                    if delta > 3 {
                        self.distanceMeters += delta
                        self.route.append(location)
                        self.lastLocation = location
                    }
                } else {
                    self.route.append(location)
                    self.lastLocation = location
                }

                if let lastAlt = self.lastAltitude {
                    let gain = location.altitude - lastAlt
                    if gain > 0 {
                        self.elevationGainMeters += gain
                    }
                }
                self.lastAltitude = location.altitude
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error.localizedDescription
        }
    }
}
