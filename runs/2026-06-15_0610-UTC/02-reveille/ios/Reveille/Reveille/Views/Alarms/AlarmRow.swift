import SwiftUI

/// One alarm in the list: big time, label + repeat summary, mission/sound pills, next-fire
/// subtitle, and an enable toggle. Dimmed when disabled.
struct AlarmRow: View {
    let alarm: Alarm
    let now: Date
    let use24Hour: Bool
    let onToggle: () -> Void
    let onTest: () -> Void

    private var nextFire: Date? {
        AlarmScheduler.nextFireDate(for: alarm, reference: now)
    }

    var body: some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(TimeFormat.clockNumerals(hour: alarm.hour, minute: alarm.minute, use24Hour: use24Hour))
                            .font(Theme.rounded(34, .bold))
                            .foregroundStyle(alarm.isEnabled ? Theme.ink : Theme.inkFaint)
                        let meridiem = TimeFormat.meridiem(hour: alarm.hour, use24Hour: use24Hour)
                        if !meridiem.isEmpty {
                            Text(meridiem)
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(alarm.isEnabled ? Theme.inkSoft : Theme.inkFaint)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                        .labelsHidden()
                        .tint(Theme.accent)
                        .accessibilityLabel("\(alarm.label) enabled")
                        .accessibilityValue(alarm.isEnabled ? "On" : "Off")
                }

                Text(alarm.label)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(alarm.isEnabled ? Theme.ink : Theme.inkSoft)

                HStack(spacing: 6) {
                    Pill(text: AlarmScheduler.repeatSummary(alarm.repeatDays), systemImage: "repeat")
                    Pill(text: alarm.missionType.title,
                         systemImage: alarm.missionType.symbol,
                         fill: Theme.surfaceAlt, foreground: Theme.inkSoft)
                    Pill(text: SoundLibrary.sound(named: alarm.soundName).title,
                         systemImage: "speaker.wave.2.fill",
                         fill: Theme.surfaceAlt, foreground: Theme.inkSoft)
                }
                .lineLimit(1)

                if alarm.isEnabled, let fire = nextFire {
                    Label(AlarmScheduler.ringsInLabel(to: fire, from: now),
                          systemImage: "clock")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.accent)
                } else if !alarm.isEnabled {
                    Label("Off", systemImage: "moon.zzz")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .opacity(alarm.isEnabled ? 1 : 0.7)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Double-tap to edit. Swipe for test and delete.")
    }
}
