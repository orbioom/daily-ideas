import Foundation
import AVFAudio
import Observation

/// Live microphone tuner. Owns an `AVAudioEngine`, installs an input tap, feeds
/// captured buffers to the pure `PitchDetector`, and publishes a smoothed
/// frequency / note / cents / clarity reading on the main actor.
///
/// Uses the iOS 17 permission API `AVAudioApplication.requestRecordPermission`
/// and exposes a calm permission-denied state instead of crashing.
@MainActor
@Observable
final class TunerEngine {

    /// Microphone authorization state, mirrored from `AVAudioApplication`.
    enum Permission: Equatable {
        case undetermined
        case denied
        case granted
    }

    /// High-level listening state for the UI.
    enum Status: Equatable {
        case idle
        case starting
        case listening   // running, but no confident pitch yet
        case detecting   // running and locked onto a pitch
        case denied
        case failed(String)
    }

    // MARK: - Published state

    private(set) var status: Status = .idle
    private(set) var permission: Permission = .undetermined

    /// Smoothed fundamental frequency (Hz) or nil when no signal.
    private(set) var frequency: Double?
    /// Resolved note reading for the smoothed frequency.
    private(set) var reading: NoteMath.Reading?
    /// Detection clarity / confidence 0...1.
    private(set) var clarity: Double = 0

    /// A4 reference (Hz). Set by the view from @AppStorage.
    var a4Reference: Double = NoteMath.defaultA4

    // MARK: - Private audio

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var detector = PitchDetector()
    @ObservationIgnored private var isRunning = false

    // Smoothing: a small median window plus an EMA to settle the readout.
    @ObservationIgnored private var freqWindow: [Double] = []
    @ObservationIgnored private var emaFrequency: Double?
    @ObservationIgnored private let windowSize = 5
    @ObservationIgnored private let emaAlpha = 0.25
    // Frames with no confident pitch before we clear the readout.
    @ObservationIgnored private var silentFrames = 0

    init() {
        refreshPermission()
    }

    // MARK: - Permission

    func refreshPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:      permission = .granted
        case .denied:       permission = .denied
        case .undetermined: permission = .undetermined
        @unknown default:   permission = .undetermined
        }
    }

    /// Request mic access (iOS 17 API) then start if granted.
    func requestPermissionAndStart() {
        refreshPermission()
        switch permission {
        case .granted:
            start()
        case .denied:
            status = .denied
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    self.permission = granted ? .granted : .denied
                    if granted { self.start() } else { self.status = .denied }
                }
            }
        }
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        refreshPermission()
        guard permission == .granted else {
            status = permission == .denied ? .denied : .starting
            if permission == .undetermined { requestPermissionAndStart() }
            return
        }

        status = .starting
        resetReadout()

        // Configure the audio session for recording.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: [])
        } catch {
            status = .failed("Couldn't access the microphone.")
            return
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            status = .failed("Microphone format unavailable.")
            return
        }
        let sampleRate = format.sampleRate

        // Install the tap. Keep the render closure simple & allocation-light.
        // Capture a local copy of the (value-type, Sendable) detector so the
        // audio-thread closure never touches main-actor state for analysis.
        let localDetector = detector
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            let samples = TunerEngine.monoSamples(from: buffer)
            guard !samples.isEmpty else { return }
            let result = localDetector.detect(samples: samples, sampleRate: sampleRate)
            Task { @MainActor in
                self?.ingest(result)
            }
        }

        engine.prepare()
        do {
            try engine.start()
            isRunning = true
            status = .listening
        } catch {
            input.removeTap(onBus: 0)
            status = .failed("Couldn't start the audio engine.")
        }
    }

    func stop() {
        guard isRunning else {
            status = .idle
            return
        }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        status = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        resetReadout()
    }

    // MARK: - Ingest & smoothing (main actor)

    private func ingest(_ result: PitchDetector.Result?) {
        guard isRunning else { return }

        guard let result else {
            silentFrames += 1
            // After a few empty frames, clear the readout but keep listening.
            if silentFrames >= 6 {
                resetReadout()
                if status == .detecting { status = .listening }
            }
            return
        }

        silentFrames = 0
        clarity = result.clarity

        // Median window to reject octave-jump outliers.
        freqWindow.append(result.frequency)
        if freqWindow.count > windowSize { freqWindow.removeFirst() }
        let sorted = freqWindow.sorted()
        guard let median = sorted[safe: sorted.count / 2] else { return }

        // EMA on top of the median for a smooth needle.
        if let prev = emaFrequency {
            emaFrequency = prev + emaAlpha * (median - prev)
        } else {
            emaFrequency = median
        }

        guard let smooth = emaFrequency else { return }
        frequency = smooth
        reading = NoteMath.reading(forFrequency: smooth, a4: a4Reference)
        status = .detecting
    }

    private func resetReadout() {
        freqWindow.removeAll(keepingCapacity: true)
        emaFrequency = nil
        frequency = nil
        reading = nil
        clarity = 0
        silentFrames = 0
    }

    // MARK: - Buffer → [Float]

    /// Extract a mono Float array from a PCM buffer, guarding the channel pointer.
    nonisolated private static func monoSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return [] }
        // Use the first channel; mono is sufficient for pitch detection.
        let ptr = channelData[0]
        return Array(UnsafeBufferPointer(start: ptr, count: frameCount))
    }
}
