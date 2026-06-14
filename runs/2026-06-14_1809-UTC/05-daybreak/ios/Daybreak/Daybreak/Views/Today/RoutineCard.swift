import SwiftUI

/// A routine card on Today: icon, name, step/minute meta, done-state, and a big Start.
struct RoutineCard: View {
    let routine: Routine
    let status: TodayStatus
    let onStart: () -> Void

    private var accent: Color {
        Color(hex: parseHex(routine.colorHex))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: routine.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(routine.name)
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Label("\(routine.orderedSteps.count) steps", systemImage: "checklist")
                        Text("·")
                        Label(TimeFormat.minutesLabel(routine.estimatedMinutes), systemImage: "clock")
                    }
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .labelStyle(.titleAndIcon)
                }
                Spacer()
                if status == .done {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.good)
                        .accessibilityLabel("Done today")
                }
            }

            Button(action: onStart) {
                HStack(spacing: 8) {
                    Image(systemName: status == .done ? "arrow.clockwise" : "play.fill")
                        .accessibilityHidden(true)
                    Text(status == .done ? "Run again" : "Start")
                }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
            }
            .disabled(routine.orderedSteps.isEmpty)
            .opacity(routine.orderedSteps.isEmpty ? 0.5 : 1)
            .accessibilityLabel(status == .done ? "Run \(routine.name) again" : "Start \(routine.name)")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

/// Parse a hex string like "C77E22" / "#C77E22" → UInt, defaulting to the app gold.
func parseHex(_ string: String) -> UInt {
    var cleaned = string.trimmingCharacters(in: .whitespaces)
    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
    guard let value = UInt(cleaned, radix: 16), !cleaned.isEmpty else { return 0xC77E22 }
    return value
}
