import SwiftUI

/// The vertical timeline: hour rails in the background, blocks positioned by
/// time, overlapping blocks packed into side-by-side columns, and a live
/// "now" line when the shown day is today.
struct TimelineCanvas: View {
    let blocks: [TimeBlock]
    let dayStartHour: Int
    let dayEndHour: Int
    let isToday: Bool
    let now: Date
    let onTap: (TimeBlock) -> Void
    let onToggle: (TimeBlock) -> Void

    private let pointsPerMinute: CGFloat = 1.05
    private let railInset: CGFloat = 56

    private var startMinute: Int { dayStartHour * 60 }
    private var endMinute: Int { dayEndHour * 60 }
    private var totalMinutes: Int { max(60, endMinute - startMinute) }
    private var canvasHeight: CGFloat { CGFloat(totalMinutes) * pointsPerMinute }

    private var placed: [ScheduleEngine.Placed] {
        ScheduleEngine.layout(blocks.filter {
            $0.endMinuteOfDay > startMinute && $0.startMinuteOfDay < endMinute
        })
    }

    private func y(forMinute minute: Int) -> CGFloat {
        CGFloat(minute - startMinute) * pointsPerMinute
    }

    var body: some View {
        GeometryReader { geo in
            let laneWidth = geo.size.width - railInset - 8
            ZStack(alignment: .topLeading) {
                hourRails(width: geo.size.width)

                ForEach(placed) { p in
                    blockCard(p, laneWidth: laneWidth)
                }

                if isToday {
                    nowLine(width: geo.size.width)
                }
            }
            .frame(width: geo.size.width, height: canvasHeight, alignment: .topLeading)
        }
        .frame(height: canvasHeight)
    }

    private func hourRails(width: CGFloat) -> some View {
        ForEach(dayStartHour...dayEndHour, id: \.self) { hour in
            let yy = y(forMinute: hour * 60)
            HStack(alignment: .center, spacing: 8) {
                Text(ScheduleEngine.clockString(minuteOfDay: hour * 60)
                        .replacingOccurrences(of: ":00", with: ""))
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
                    .frame(width: railInset - 8, alignment: .trailing)
                Rectangle()
                    .fill(Brand.hairline)
                    .frame(height: 1)
            }
            .offset(y: yy - 6)
            .accessibilityHidden(true)
        }
    }

    private func blockCard(_ p: ScheduleEngine.Placed, laneWidth: CGFloat) -> some View {
        let b = p.block
        let top = y(forMinute: max(b.startMinuteOfDay, startMinute))
        let bottom = y(forMinute: min(b.endMinuteOfDay, endMinute))
        let height = max(30, bottom - top)
        let colW = (laneWidth - CGFloat(p.columnCount - 1) * 6) / CGFloat(p.columnCount)
        let x = railInset + CGFloat(p.column) * (colW + 6)

        return Button { onTap(b) } label: {
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(b.category.color)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .strikethrough(b.isDone, color: Brand.text3)
                        .lineLimit(height > 46 ? 2 : 1)
                    if height > 40 {
                        Text("\(ScheduleEngine.clockString(minuteOfDay: b.startMinuteOfDay)) · \(ScheduleEngine.durationString(b.durationMinutes))")
                            .font(Brand.mono(10))
                            .foregroundStyle(Brand.text3)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                Button {
                    onToggle(b)
                } label: {
                    Image(systemName: b.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundStyle(b.isDone ? Brand.live : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(b.isDone ? "Mark not done" : "Mark done")
            }
            .padding(8)
            .frame(width: colW, height: height, alignment: .topLeading)
            .background(b.category.color.opacity(b.isDone ? 0.08 : 0.16),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(b.category.color.opacity(0.4), lineWidth: 1)
            )
            .opacity(b.isDone ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .offset(x: x, y: top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(b.title), \(ScheduleEngine.clockString(minuteOfDay: b.startMinuteOfDay)), \(ScheduleEngine.durationString(b.durationMinutes)), \(b.category.title)")
        .accessibilityValue(b.isDone ? "Done" : "Not done")
        .accessibilityHint("Double tap to edit")
    }

    private func nowLine(width: CGFloat) -> some View {
        let c = Calendar.current.dateComponents([.hour, .minute], from: now)
        let minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let visible = minute >= startMinute && minute <= endMinute
        return Group {
            if visible {
                HStack(spacing: 0) {
                    Circle().fill(Brand.danger).frame(width: 8, height: 8)
                    Rectangle().fill(Brand.danger).frame(height: 1.5)
                }
                .offset(x: railInset - 4, y: y(forMinute: minute))
                .accessibilityHidden(true)
            }
        }
    }
}
