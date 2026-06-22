import SwiftUI

struct WeeklyGrid: View {
    let plannedRuns: [PlannedRun]
    let currentDayOfWeek: Int
    var onTapDay: ((PlannedRun) -> Void)? = nil

    private let dayNames = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { dayIndex in
                let run = plannedRuns.first(where: { $0.dayOfWeek == dayIndex })
                DayCell(
                    dayName: dayNames[dayIndex],
                    run: run,
                    isToday: dayIndex == currentDayOfWeek
                )
                .onTapGesture {
                    if let run = run {
                        onTapDay?(run)
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    let dayName: String
    let run: PlannedRun?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .surgeAccent : .surgeTextSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(cellBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(cellBorder, lineWidth: isToday ? 1.5 : 0.5)
                    )

                if let run = run {
                    if run.type == .rest {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.surgeTextSecondary.opacity(0.5))
                    } else if run.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.surgeSuccess)
                    } else {
                        Text(run.type.shortName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(RunTypeColor.color(for: run.type))
                    }
                } else {
                    Text("·")
                        .foregroundColor(.surgeTextSecondary.opacity(0.3))
                }
            }
            .frame(height: 36)

            if let run = run, run.distanceKm > 0 {
                Text(String(format: "%.0f", run.distanceKm))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.surgeTextSecondary)
            } else {
                Text("")
                    .font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var cellBackground: Color {
        guard let run = run else { return Color.surgeSurface.opacity(0.3) }
        if run.isCompleted { return Color.surgeSuccess.opacity(0.1) }
        if isToday { return RunTypeColor.backgroundColor(for: run.type) }
        if run.type == .rest { return Color.surgeSurface.opacity(0.3) }
        return Color.surgeSurface
    }

    private var cellBorder: Color {
        if isToday { return .surgeAccent }
        guard let run = run else { return .surgeDivider }
        if run.isCompleted { return .surgeSuccess.opacity(0.3) }
        return .surgeDivider
    }
}
