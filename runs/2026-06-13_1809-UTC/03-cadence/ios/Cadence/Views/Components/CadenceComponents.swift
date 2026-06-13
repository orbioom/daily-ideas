import SwiftUI

enum TimeFmt {
    static func clock(_ minuteOfDay: Int) -> String {
        let h = (minuteOfDay / 60) % 24
        let m = minuteOfDay % 60
        var comps = DateComponents(); comps.hour = h; comps.minute = m
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
    static func clock(date: Date) -> String { date.formatted(.dateTime.hour().minute()) }
}

extension Medication {
    var scheduleSummary: String {
        switch schedule {
        case .asNeeded:
            return "As needed"
        case .everyDay:
            let t = times.map { TimeFmt.clock($0) }.joined(separator: ", ")
            return times.isEmpty ? "Every day" : "Daily · \(t)"
        case .daysOfWeek:
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let days = (0..<7).filter { (dayMask & (1 << $0)) != 0 }.map { names[$0] }
            let t = times.map { TimeFmt.clock($0) }.joined(separator: ", ")
            let d = days.count == 7 ? "Daily" : days.joined(separator: " ")
            return "\(d) · \(t)"
        }
    }
}

/// A circular progress ring with optional centered content.
struct RingView: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var tint: Color = Theme.accent
    var center: AnyView? = nil
    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let center { center }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// Colored capsule glyph used to identify a medication at a glance.
struct PillGlyph: View {
    let med: Medication
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Theme.pillColor(UInt(med.colorHex)).opacity(0.18))
            Image(systemName: med.form.icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Theme.pillColor(UInt(med.colorHex)))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One due dose with take / skip controls.
struct DoseRow: View {
    let occ: DoseOccurrence
    let onTake: () -> Void
    let onSkip: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            PillGlyph(med: occ.med)
            VStack(alignment: .leading, spacing: 3) {
                Text(occ.med.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                Text(detail).font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            controls
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(occ.med.name) at \(TimeFmt.clock(date: occ.slotDate)), \(statusWord)")
    }

    private var detail: String {
        let units = "\(occ.med.dosesPerTime) \(occ.med.form.label.lowercased())"
        let strength = occ.med.strength.isEmpty ? "" : " · \(occ.med.strength)"
        return "\(TimeFmt.clock(date: occ.slotDate)) · \(units)\(strength)"
    }

    private var statusWord: String {
        switch occ.status {
        case .taken: return "taken"
        case .skipped: return "skipped"
        case .missed: return "missed"
        case .pending: return "due"
        }
    }

    @ViewBuilder private var controls: some View {
        switch occ.status {
        case .taken:
            Button(action: onUndo) {
                Label("Taken", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly).font(.system(size: 28)).foregroundStyle(Theme.good)
            }
            .accessibilityLabel("Taken. Tap to undo.")
        case .skipped:
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward.circle").font(.system(size: 28)).foregroundStyle(Theme.inkFaint)
            }
            .accessibilityLabel("Skipped. Tap to undo.")
        case .missed, .pending:
            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.inkSoft).frame(width: 38, height: 38)
                        .background(Theme.surfaceAlt, in: Circle())
                }
                .accessibilityLabel("Skip dose")
                Button(action: onTake) {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white).frame(width: 38, height: 38)
                        .background(Theme.accent, in: Circle())
                }
                .accessibilityLabel("Mark taken")
            }
        }
    }
}
