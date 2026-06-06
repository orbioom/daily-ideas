import SwiftUI
import Observation

/// Which exposure leg the calculator solves for. The other two are user-controlled.
enum SolveTarget: String, CaseIterable, Identifiable {
    case aperture, shutter, iso

    var id: String { rawValue }
    var title: String {
        switch self {
        case .aperture: return "Aperture"
        case .shutter:  return "Shutter"
        case .iso:      return "ISO"
        }
    }
    var systemImage: String {
        switch self {
        case .aperture: return "camera.aperture"
        case .shutter:  return "timer"
        case .iso:      return "circle.dotted"
        }
    }
}

/// Drives the exposure calculator/visualizer. Pure logic delegates to `Exposure`.
/// Preloaded with a sensible, immediately-usable scene.
@Observable
final class CalculatorViewModel {

    // MARK: - User-controlled inputs (positions on the stop grid)

    /// Aperture f-number.
    var aperture: Double = 8
    /// Shutter time in seconds.
    var shutterSeconds: Double = 1.0 / 250
    /// ISO.
    var iso: Double = 400
    /// Focal length (mm) — drives DoF & motion-blur guidance only.
    var focalLengthMM: Double = 50

    /// Which leg is solved from the target EV.
    var solveTarget: SolveTarget = .shutter
    /// The increment used for snapping & equivalent enumeration.
    var increment: StopIncrement = .third

    /// A metered target EV the user is dialing toward (the "scene" brightness at ISO 100).
    /// Default ~ EV12 daylight shade.
    var targetEV100: Double = 12

    // MARK: - Derived: current EV at ISO 100 from the live aperture/shutter

    var currentEV100: Double? {
        Exposure.ev100(aperture: aperture, shutterSeconds: shutterSeconds)
    }

    /// Current EV at the working ISO.
    var currentEV: Double? {
        Exposure.ev(aperture: aperture, shutterSeconds: shutterSeconds, iso: iso)
    }

    /// The EV the scene+ISO together demand (target adjusted for ISO).
    var targetEVAtISO: Double {
        targetEV100 + log2(iso / 100.0)
    }

    /// Stops under/over the metered target (positive = under-exposed).
    var stopsFromTarget: Double? {
        guard let ev = currentEV else { return nil }
        return Exposure.stopsBetweenEV(ev, target: targetEVAtISO)
    }

    // MARK: - Solving

    /// Solve the selected leg so the exposure matches `targetEVAtISO`, then snap it.
    /// Writes the result back into the corresponding input. Guarded throughout.
    func solveSelectedLeg() {
        switch solveTarget {
        case .aperture:
            if let n = Exposure.solveAperture(shutterSeconds: shutterSeconds,
                                              targetEV: targetEVAtISO, iso: iso),
               let snapped = Exposure.snapAperture(n, increment: increment) {
                aperture = clampAperture(snapped)
            }
        case .shutter:
            if let t = Exposure.solveShutter(aperture: aperture,
                                             targetEV: targetEVAtISO, iso: iso),
               let snapped = Exposure.snapShutter(t, increment: increment) {
                shutterSeconds = clampShutter(snapped)
            }
        case .iso:
            if let s = Exposure.solveISO(aperture: aperture,
                                         shutterSeconds: shutterSeconds,
                                         targetEV: targetEVAtISO) {
                iso = clampISO(s)
            }
        }
    }

    /// Set the target EV to whatever the current aperture/shutter/ISO produce — "meter from here".
    func captureCurrentAsTarget() {
        if let ev100 = currentEV100 {
            targetEV100 = ev100
        }
    }

    // MARK: - Snapping live inputs to the grid

    func snapInputs() {
        if let n = Exposure.snapAperture(aperture, increment: increment) {
            aperture = clampAperture(n)
        }
        if let t = Exposure.snapShutter(shutterSeconds, increment: increment) {
            shutterSeconds = clampShutter(t)
        }
    }

    // MARK: - Equivalent exposures

    var equivalents: [EquivalentExposure] {
        guard let ev100 = currentEV100 else { return [] }
        return Exposure.equivalents(targetEV: ev100 + log2(iso / 100.0),
                                    iso: iso,
                                    increment: increment)
    }

    // MARK: - Guidance

    var depthOfField: GuidanceLevel {
        Exposure.depthOfField(aperture: aperture, focalLengthMM: focalLengthMM)
    }
    var motionBlur: GuidanceLevel {
        Exposure.motionBlurRisk(shutterSeconds: shutterSeconds, focalLengthMM: focalLengthMM)
    }
    var noiseLevel: GuidanceLevel {
        Exposure.noise(iso: iso)
    }

    // MARK: - Clamps (keep inputs in honest, usable bounds)

    private func clampAperture(_ n: Double) -> Double { min(max(n, 1.0), 64.0) }
    private func clampShutter(_ t: Double) -> Double { min(max(t, 1.0/16000), 60) }
    private func clampISO(_ s: Double) -> Double { min(max(s, 25), 25600) }
}
