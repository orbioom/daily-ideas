import SwiftUI
import Observation

/// Loading phase for the computed sky snapshot.
enum SkyLoadState {
    case idle
    case loading
    case loaded(SkySnapshot)
    case failed(String)
}

/// Resolves the active observer context from settings and computes the SkySnapshot.
/// Owns the async compute + loading/error states. Re-run when location/time change.
@MainActor
@Observable
final class SkyViewModel {
    var state: SkyLoadState = .idle

    /// The context the current snapshot was computed for.
    private(set) var context: ObserverContext?

    /// Recompute the snapshot for the given settings + Pro status.
    func refresh(settings: AppSettings, isPro: Bool) async {
        let ctx = Self.resolveContext(settings: settings)
        context = ctx
        state = .loading

        let magLimit = isPro ? settings.magnitudeLimit : min(settings.magnitudeLimit, 3.5)
        let includeOuter = isPro

        // Compute off the main actor; the engine is pure value-type math.
        let snapshot = await Task.detached(priority: .userInitiated) {
            SkyEngine.snapshot(for: ctx, magnitudeLimit: magLimit, includeOuterPlanets: includeOuter)
        }.value

        // Sanity guard — a snapshot always has the luminaries.
        if snapshot.planets.isEmpty {
            state = .failed("Could not compute the sky for this location.")
        } else {
            state = .loaded(snapshot)
        }
    }

    /// Build the ObserverContext from the persisted settings.
    static func resolveContext(settings: AppSettings) -> ObserverContext {
        let date: Date = settings.timeMode == .custom ? settings.customDate : Date()
        let id = settings.selectedLocationID

        if id == "manual" {
            return ObserverContext(
                name: settings.manualLocationName,
                latitude: clampLat(settings.manualLatitude),
                longitude: clampLon(settings.manualLongitude),
                date: date,
                timeZone: .current
            )
        }
        if let city = Gazetteer.byID[id] {
            return ObserverContext(
                name: city.displayName,
                latitude: clampLat(city.latitude),
                longitude: clampLon(city.longitude),
                date: date,
                timeZone: city.timeZone
            )
        }
        // Fallback to London.
        let london = Gazetteer.byID["city.london"]
        return ObserverContext(
            name: london?.displayName ?? "London, UK",
            latitude: london?.latitude ?? 51.5074,
            longitude: london?.longitude ?? -0.1278,
            date: date,
            timeZone: london?.timeZone ?? .gmt
        )
    }

    static func clampLat(_ v: Double) -> Double { min(89.9, max(-89.9, v.isFinite ? v : 0)) }
    static func clampLon(_ v: Double) -> Double { min(180, max(-180, v.isFinite ? v : 0)) }
}
