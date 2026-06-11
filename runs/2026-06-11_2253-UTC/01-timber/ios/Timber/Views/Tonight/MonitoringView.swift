import SwiftUI
import UIKit

/// Full-screen overnight monitoring UI. Dimmed, glanceable, idle-timer off.
struct MonitoringView: View {
    @Environment(RecorderEngine.self) private var recorder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinish: ((startedAt: Date, endedAt: Date,
                    episodes: [SnoreDetector.Detected], minuteLevels: [Double])?) -> Void

    @State private var confirmEnd = false

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    VStack(spacing: 8) {
                        if case .monitoring(let started) = recorder.state {
                            Text(elapsedString(since: started, now: timeline.date))
                                .font(.system(size: 56, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.92))
                                .accessibilityLabel("Session running for \(elapsedString(since: started, now: timeline.date))")
                        }
                        Text(recorder.isSnoringNow ? "Snoring detected…" : "Listening")
                            .font(.subheadline)
                            .foregroundStyle(recorder.isSnoringNow ? Theme.amber : .white.opacity(0.45))
                    }
                }

                levelMeter

                HStack(spacing: 24) {
                    statPill(value: "\(recorder.liveEpisodes.count)", label: "episodes")
                    statPill(value: String(format: "%.0f dB", recorder.currentDB), label: "level")
                }

                Spacer()

                Text("Keep your iPhone plugged in, screen can be locked.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))

                Button {
                    confirmEnd = true
                } label: {
                    Text("End session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.amber)
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .confirmationDialog("End tonight's session?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End and save") {
                Haptics.tap()
                onFinish(recorder.finish())
            }
            Button("Discard session", role: .destructive) {
                recorder.cancel()
                onFinish(nil)
            }
            Button("Keep monitoring", role: .cancel) {}
        }
    }

    private var levelMeter: some View {
        let normalized = recorder.normalized(recorder.currentDB)
        let thresholdNorm = recorder.normalized(recorder.threshold)
        return VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.10))
                    Capsule()
                        .fill(recorder.isSnoringNow ? Theme.amber : Theme.moss)
                        .frame(width: max(geo.size.width * normalized, 8))
                        .animation(reduceMotion ? nil : .linear(duration: 0.4), value: normalized)
                    Rectangle()
                        .fill(.white.opacity(0.55))
                        .frame(width: 2)
                        .offset(x: geo.size.width * thresholdNorm)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 14)
            Text("The white line is your room's snore threshold — it adapts as Timber learns the noise floor.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sound level \(Int(normalized * 100)) percent")
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.white.opacity(0.07), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private func elapsedString(since start: Date, now: Date) -> String {
        let seconds = max(Int(now.timeIntervalSince(start)), 0)
        return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}
