import SwiftUI
import SwiftData
import UIKit

struct SessionPlayerView: View {
    let preset: MeditationPreset

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("chime.keepAwake") private var keepAwake = true
    @AppStorage("chime.hapticsOnBell") private var hapticsOnBell = true

    @State private var engine = SessionEngine()
    @State private var feeling = 0
    @State private var note = ""
    @State private var breatheUp = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1E2A), Color(hex: 0x0E0F15)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if engine.phase == .finished {
                reflection
            } else {
                activeSit
            }
        }
        .onAppear {
            engine.hapticsOnBell = hapticsOnBell
            UIApplication.shared.isIdleTimerDisabled = keepAwake
            engine.start(preset)
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    breatheUp = true
                }
            }
        }
        .onDisappear {
            engine.reset()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .statusBarHidden(true)
    }

    // MARK: - Active sit

    private var activeSit: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    Haptics.tap()
                    engine.endEarly()
                } label: {
                    Text("End")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .accessibilityLabel("End sit early")
                Spacer()
                Text(preset.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            ZStack {
                Circle()
                    .fill(Brand.magic.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .scaleEffect(breatheUp ? 1.06 : 0.94)
                ProgressRing(progress: engine.progress, lineWidth: 8, tint: Brand.magic)
                    .frame(width: 280, height: 280)
                VStack(spacing: 8) {
                    Text(engine.phaseLabel.uppercased())
                        .font(Brand.mono(12, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(Brand.magic)
                    Text(Format.clock(engine.displayRemaining))
                        .font(Brand.mono(56, weight: .light))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text("of \(Format.duration(preset.totalSeconds))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(engine.phaseLabel), \(Format.clock(engine.displayRemaining)) remaining")

            Spacer()

            Button {
                Haptics.tap()
                if engine.isPaused { engine.resume() } else { engine.pause() }
            } label: {
                Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
            .padding(.bottom, 48)
        }
    }

    // MARK: - Reflection

    private var reflection: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: engine.completedFully ? "checkmark.circle.fill" : "moon.stars.fill")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text(engine.completedFully ? "Sit complete" : "Sit ended")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("You sat for \(Format.duration(min(engine.elapsed, preset.totalSeconds)))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("How do you feel?")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            Haptics.selection()
                            feeling = i
                        } label: {
                            Image(systemName: feeling >= i ? "circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(feeling >= i ? Brand.live : .white.opacity(0.4))
                        }
                        .accessibilityLabel("Rate \(i) of 5")
                        .accessibilityAddTraits(feeling == i ? [.isSelected] : [])
                    }
                }
            }
            .padding(.top, 4)

            TextField("A word about this sit (optional)", text: $note, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)

            Spacer()

            Button("Save & close") {
                save()
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24)

            Button("Discard") {
                Haptics.tap()
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 8)
    }

    private func save() {
        let session = engine.buildSession()
        session.feeling = feeling
        session.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(session)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
