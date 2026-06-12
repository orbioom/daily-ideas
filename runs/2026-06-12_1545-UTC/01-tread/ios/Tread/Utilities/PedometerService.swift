import Foundation
import CoreMotion
import Observation

/// A plain value describing one day's pedometer figures.
struct DaySteps: Equatable {
    var day: Date
    var steps: Int
    var distanceMeters: Double
    var flights: Int
}

/// Wraps `CMPedometer`. Publishes today's live figures and can fetch the last
/// few days of history (CoreMotion keeps roughly the past 7 days). All work
/// is marshalled back to the main actor so SwiftUI observation stays correct.
@MainActor
@Observable
final class PedometerService {
    enum Phase: Equatable {
        case idle, requesting, ready, unavailable, denied, failed(String)
    }

    private let pedometer = CMPedometer()
    private(set) var phase: Phase = .idle
    private(set) var today: DaySteps
    private var isStreaming = false

    init() {
        today = DaySteps(day: Calendar.current.startOfDay(for: Date()), steps: 0, distanceMeters: 0, flights: 0)
    }

    var isAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    /// Begin live updates for the current day. Safe to call repeatedly.
    func start() {
        guard !isStreaming else { return }
        guard CMPedometer.isStepCountingAvailable() else {
            phase = .unavailable
            return
        }
        let status = CMPedometer.authorizationStatus()
        if status == .denied || status == .restricted {
            phase = .denied
            return
        }
        phase = .requesting
        isStreaming = true
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: start) { [weak self] data, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    // Re-check authorization to classify the failure calmly.
                    switch CMPedometer.authorizationStatus() {
                    case .denied, .restricted:
                        self.phase = .denied
                    default:
                        if self.phase == .requesting {
                            self.phase = .failed(error.localizedDescription)
                        }
                    }
                    return
                }
                guard let data else { return }
                self.today = DaySteps(
                    day: start,
                    steps: data.numberOfSteps.intValue,
                    distanceMeters: data.distance?.doubleValue ?? 0,
                    flights: data.floorsAscended?.intValue ?? 0)
                self.phase = .ready
            }
        }
    }

    func stop() {
        guard isStreaming else { return }
        pedometer.stopUpdates()
        isStreaming = false
    }

    /// Fetch one finished day's totals (midnight to midnight).
    func fetchDay(_ day: Date) async -> DaySteps? {
        guard CMPedometer.isStepCountingAvailable() else { return nil }
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<DaySteps?, Never>) in
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                guard let data else { cont.resume(returning: nil); return }
                cont.resume(returning: DaySteps(
                    day: start,
                    steps: data.numberOfSteps.intValue,
                    distanceMeters: data.distance?.doubleValue ?? 0,
                    flights: data.floorsAscended?.intValue ?? 0))
            }
        }
    }

    /// Fetch the last `days` completed days plus today. Returns most-recent first.
    func fetchHistory(days: Int) async -> [DaySteps] {
        guard CMPedometer.isStepCountingAvailable() else { return [] }
        var out: [DaySteps] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for offset in 0...max(0, days) {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if let s = await fetchDay(d), s.steps > 0 || cal.isDateInToday(d) {
                out.append(s)
            }
        }
        return out
    }
}
