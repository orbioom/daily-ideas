import SwiftUI

struct SleepTimerView: View {
    @Environment(MixerEngine.self) private var engine
    @AppStorage("hush.defaultFade") private var defaultFade = 30.0

    private let presets = [15, 30, 45, 60, 90, 120]
    @State private var custom = 25

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if engine.isTimerActive {
                        activeCard
                    } else {
                        idleCard
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Sleep timer")
        }
    }

    private var activeCard: some View {
        VStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: ringProgress, lineWidth: 12, tint: Brand.magic)
                    .frame(width: 220, height: 220)
                VStack(spacing: 4) {
                    Text("FADING TO SILENCE")
                        .font(Brand.mono(10, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(Brand.text3)
                        .opacity(engine.timerRemaining <= Int(engine.fadeSeconds) ? 1 : 0)
                    Text(Format.clock(engine.timerRemaining))
                        .font(Brand.mono(48, weight: .light))
                        .foregroundStyle(Brand.text)
                        .monospacedDigit()
                    Text("until sleep")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sleep timer, \(Format.clock(engine.timerRemaining)) remaining")
            .padding(.top, 12)

            Button("Cancel timer") {
                Haptics.tap()
                engine.cancelTimer()
            }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard(padding: 20)
    }

    private var idleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(text: "Fade out after")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 12) {
                ForEach(presets, id: \.self) { minutes in
                    Button {
                        Haptics.tap()
                        engine.startTimer(minutes: minutes)
                    } label: {
                        Text(Format.minutesLabel(minutes))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    }
                    .accessibilityLabel("Set timer for \(Format.minutesLabel(minutes))")
                }
            }

            Divider().overlay(Brand.hairline)

            VStack(alignment: .leading, spacing: 10) {
                Text("Custom").font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
                Stepper(value: $custom, in: 1...600, step: 5) {
                    HStack {
                        Text("Length")
                        Spacer()
                        Text(Format.minutesLabel(custom))
                            .font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                }
                Button {
                    Haptics.tap()
                    engine.startTimer(minutes: custom)
                } label: {
                    Label("Start \(Format.minutesLabel(custom)) timer", systemImage: "moon.zzz.fill")
                }
                .buttonStyle(InkButtonStyle())
            }

            if engine.activeCount == 0 {
                Text("Tip: the timer also starts playback if nothing is playing.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard(padding: 18)
    }

    private var ringProgress: Double {
        // Show the fade window filling as we approach silence.
        let fade = max(1, engine.fadeSeconds)
        let r = Double(engine.timerRemaining)
        if r >= fade { return 0.0 }
        return 1.0 - (r / fade)
    }
}
