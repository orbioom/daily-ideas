import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var patterns: [RotationPattern]
    @Query private var overrides: [ShiftOverride]
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    private var activePattern: RotationPattern? {
        patterns.first(where: \.isActive) ?? patterns.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    todayCard
                    countdownCard
                    weekStrip
                    weekSummary
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        let resolved = RotaEngine.shift(on: .now, pattern: activePattern, overrides: overrides)
        return VStack(spacing: 10) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            if let type = resolved.shiftType, !type.isRest {
                ShiftBadge(symbol: type.symbol, colorHex: type.colorHex)
                Text(type.name)
                    .font(.title.weight(.bold))
                Text(type.timeRangeString(use24Hour: use24Hour))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("\(type.paidHours.formatted(.number.precision(.fractionLength(0...1)))) paid hours · \(Money.format(type.earningsPerShift, symbol: currencySymbol))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(RotaTheme.amber)
                Text(activePattern == nil && resolved.shiftType == nil && !resolved.isOverride ? "No rotation set" : "Day Off")
                    .font(.title.weight(.bold))
                if activePattern == nil && !resolved.isOverride {
                    Text("Build your rotation on the Rotation tab and every day fills in automatically.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            if resolved.isOverride {
                Label(resolved.note.isEmpty ? "Manually changed" : resolved.note, systemImage: "pencil")
                    .font(.caption)
                    .foregroundStyle(RotaTheme.amber)
            }
        }
        .frame(maxWidth: .infinity)
        .rotaPanel()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Countdown

    private var countdownCard: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Group {
                if let next = RotaEngine.nextShift(after: context.date, pattern: activePattern, overrides: overrides) {
                    HStack(spacing: 14) {
                        Image(systemName: "timer")
                            .font(.title2)
                            .foregroundStyle(RotaTheme.amber)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next shift · \(next.type.name)")
                                .font(.subheadline.weight(.semibold))
                            Text("\(next.start.formatted(.dateTime.weekday(.wide).day().month())) at \(next.start.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(countdown(to: next.start, from: context.date))
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(RotaTheme.amber)
                    }
                    .rotaPanel()
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func countdown(to target: Date, from now: Date) -> String {
        let seconds = max(0, Int(target.timeIntervalSince(now)))
        let d = seconds / 86400
        let h = (seconds % 86400) / 3600
        let m = (seconds % 3600) / 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next 7 Days")
                .font(.headline)
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now)) ?? .now
                    let resolved = RotaEngine.shift(on: day, pattern: activePattern, overrides: overrides)
                    VStack(spacing: 5) {
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(day, format: .dateTime.day())
                            .font(.callout.weight(offset == 0 ? .bold : .regular))
                        if let type = resolved.shiftType, !type.isRest {
                            ShiftBadge(symbol: type.symbol, colorHex: type.colorHex, small: true)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(offset == 0 ? RotaTheme.amber.opacity(0.12) : Color.clear)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(weekDayLabel(day: day, resolved: resolved))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rotaPanel()
    }

    private func weekDayLabel(day: Date, resolved: (shiftType: ShiftType?, isOverride: Bool, note: String)) -> String {
        let dayName = day.formatted(.dateTime.weekday(.wide).day().month())
        if let type = resolved.shiftType, !type.isRest {
            return "\(dayName): \(type.name)"
        }
        return "\(dayName): day off"
    }

    // MARK: - This week summary

    private var weekSummary: some View {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let summary = RotaEngine.summary(from: start, through: end, pattern: activePattern, overrides: overrides)
        return HStack(spacing: 12) {
            metric("Shifts", "\(summary.workDays)")
            metric("Paid hours", summary.paidHours.formatted(.number.precision(.fractionLength(0...1))))
            metric("Est. pay", Money.format(summary.earnings, symbol: currencySymbol))
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) over the next 7 days")
    }
}
