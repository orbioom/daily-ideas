import Foundation
import CoreMotion
import Observation

/// Magnetic-north heading from CoreMotion's device-motion fusion.
/// Needs no permission prompt and no location access — readings never leave the device.
/// Updates are delivered on the main OperationQueue, so observable mutations
/// happen on the main thread without actor annotations.
@Observable
final class CompassService {
    private let manager = CMMotionManager()
    /// Degrees clockwise from magnetic north, or nil while unavailable.
    private(set) var heading: Double?
    private(set) var isAvailable = true

    func start() {
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            heading = nil
            return
        }
        guard !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, _ in
            guard let self else { return }
            if let motion, motion.heading >= 0 {
                self.heading = motion.heading
                self.isAvailable = true
            } else {
                self.heading = nil
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        heading = nil
    }
}
