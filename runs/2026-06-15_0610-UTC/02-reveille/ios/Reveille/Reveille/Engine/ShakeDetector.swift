import Foundation
import CoreMotion

/// Counts physical shakes using CoreMotion's accelerometer (user acceleration, gravity
/// removed). A shake is one spike above threshold followed by a dip below half-threshold,
/// debounced so a single jerk can't register twice. Degrades gracefully if the device has
/// no accelerometer (the Ring screen offers a tap fallback in that case).
@MainActor
final class ShakeDetector: ObservableObject {

    @Published private(set) var count = 0
    @Published private(set) var magnitude: Double = 0
    @Published private(set) var isAvailable = true

    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    private var armed = true
    private let threshold: Double
    private let lowGate: Double

    init(threshold: Double = MissionEngine.shakeThreshold) {
        self.threshold = threshold
        self.lowGate = threshold * 0.5
    }

    func start() {
        count = 0
        magnitude = 0
        armed = true
        guard motion.isAccelerometerAvailable else {
            isAvailable = false
            return
        }
        isAvailable = true
        motion.accelerometerUpdateInterval = 1.0 / 50.0
        motion.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            // Subtract 1g baseline by computing magnitude then removing gravity component.
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let total = (x * x + y * y + z * z).squareRoot()
            let net = abs(total - 1.0)  // ~0 at rest, spikes when shaken
            Task { @MainActor in
                self.handle(net)
            }
        }
    }

    func stop() {
        if motion.isAccelerometerActive {
            motion.stopAccelerometerUpdates()
        }
    }

    private func handle(_ net: Double) {
        magnitude = net
        if armed && net > threshold {
            count += 1
            armed = false
        } else if !armed && net < lowGate {
            armed = true
        }
    }

    /// Manually register a shake — used as a fallback tap on devices without an accelerometer
    /// (e.g. some simulators) so the mission is never unwinnable.
    func registerManualShake() {
        count += 1
    }
}
