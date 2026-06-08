import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Plant.order) private var plants: [Plant]
    @Query(sort: \CareEvent.date) private var allEvents: [CareEvent]
    @Query(sort: \Room.order) private var rooms: [Room]
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true

    private var now: Date { Date() }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if plants.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No data yet",
                        message: "Add plants and log care events to see insights."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            streakCard
                            weeklyActivityChart
                            plantsByRoomChart
                            plantsByLightChart
                            neediestPlants
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Streak

    private var careStreak: Int {
        guard !allEvents.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: now)

        while true {
            let hasEvent = allEvents.contains { cal.startOfDay(for: $0.date) == checkDate }
            if hasEvent {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    private var thisMonthCount: Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: now)
        return allEvents.filter {
            let ec = cal.dateComponents([.year, .month], from: $0.date)
            return ec.year == comps.year && ec.month == comps.month
        }.count
    }

    private var streakCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                statBlock(
                    value: "\(careStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: Brand.warn
                )
                Divider()
                    .frame(height: 48)
                    .padding(.horizontal, 16)
                    .background(Brand.hairline)
                statBlock(
                    value: "\(thisMonthCount)",
                    label: "This Month",
                    icon: "calendar",
                    color: Brand.info
                )
                Divider()
                    .frame(height: 48)
                    .padding(.horizontal, 16)
                    .background(Brand.hairline)
                statBlock(
                    value: "\(plants.filter { !$0.archived }.count)",
                    label: "Active Plants",
                    icon: "leaf.fill",
                    color: Brand.live
                )
            }
        }
    }

    private func statBlock(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Weekly Activity

    private struct WeeklyBucket: Identifiable {
        let id = UUID()
        let weekStart: Date
        let count: Int
        let label: String
    }

    private var weeklyBuckets: [WeeklyBucket] {
        let cal = Calendar.current
        var buckets: [WeeklyBucket] = []
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: cal.startOfDay(for: now)) else { continue }
            guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let count = allEvents.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let label = weekOffset == 0 ? "This wk" : "W-\(weekOffset)"
            buckets.append(WeeklyBucket(weekStart: weekStart, count: count, label: label))
        }
        return buckets
    }

    private var weeklyActivityChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Care Events — Last 8 Weeks")

                Chart(weeklyBuckets) { bucket in
                    BarMark(
                        x: .value("Week", bucket.label),
                        y: .value("Events", bucket.count)
                    )
                    .foregroundStyle(Brand.live.gradient)
                    .cornerRadius(4)
                    .annotation(position: .top, alignment: .center) {
                        if bucket.count > 0 {
                            Text("\(bucket.count)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Brand.text3)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Bar chart of care events over last 8 weeks")
            }
        }
    }

    // MARK: - Plants by Room

    private struct RoomBucket: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    private var plantsByRoom: [RoomBucket] {
        var buckets: [RoomBucket] = []
        for room in rooms {
            let count = plants.filter { $0.room?.id == room.id && !$0.archived }.count
            if count > 0 {
                buckets.append(RoomBucket(name: room.name, count: count))
            }
        }
        let unassigned = plants.filter { $0.room == nil && !$0.archived }.count
        if unassigned > 0 {
            buckets.append(RoomBucket(name: "Unassigned", count: unassigned))
        }
        return buckets.sorted { $0.count > $1.count }
    }

    private var plantsByRoomChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Plants by Room")

                if plantsByRoom.isEmpty {
                    Text("No room data")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    Chart(plantsByRoom) { bucket in
                        BarMark(
                            x: .value("Count", bucket.count),
                            y: .value("Room", bucket.name)
                        )
                        .foregroundStyle(Brand.info.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text("\(bucket.count)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.system(size: 11))
                        }
                    }
                    .frame(height: max(CGFloat(plantsByRoom.count * 36), 80))
                    .accessibilityLabel("Horizontal bar chart of plants by room")
                }
            }
        }
    }

    // MARK: - Plants by Light

    private struct LightBucket: Identifiable {
        let id = UUID()
        let level: LightLevel
        let count: Int
    }

    private var plantsByLight: [LightBucket] {
        LightLevel.allCases.compactMap { level in
            let count = plants.filter { $0.light == level && !$0.archived }.count
            return count > 0 ? LightBucket(level: level, count: count) : nil
        }
    }

    private var plantsByLightChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Plants by Light Level")

                if plantsByLight.isEmpty {
                    Text("No data")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        Chart(plantsByLight) { bucket in
                            SectorMark(
                                angle: .value("Plants", bucket.count),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(bucket.level.color)
                            .cornerRadius(3)
                        }
                        .frame(width: 110, height: 110)
                        .accessibilityLabel("Donut chart of plants by light level")

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(plantsByLight) { bucket in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(bucket.level.color)
                                        .frame(width: 8, height: 8)
                                        .accessibilityHidden(true)
                                    Text(bucket.level.label)
                                        .font(.caption)
                                        .foregroundStyle(Brand.text2)
                                    Spacer()
                                    Text("\(bucket.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Brand.text)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(bucket.level.label): \(bucket.count) plants")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Neediest Plants

    private struct NeedyPlant: Identifiable {
        let id: UUID
        let nickname: String
        let species: String
        let symbol: String
        let colorHex: UInt32
        let intervalDays: Int
        let overdueDays: Int
    }

    private var neediestPlants: some View {
        let activePlants = plants.filter { !$0.archived }
        let neediest: [NeedyPlant] = activePlants
            .sorted { a, b in
                let dA = CareEngine.daysUntil(
                    CareEngine.nextWaterDue(plant: a, seasonalAdjust: seasonalAdjust, now: now) ?? now,
                    now: now
                )
                let dB = CareEngine.daysUntil(
                    CareEngine.nextWaterDue(plant: b, seasonalAdjust: seasonalAdjust, now: now) ?? now,
                    now: now
                )
                return dA < dB
            }
            .prefix(5)
            .map { p in
                let due = CareEngine.nextWaterDue(plant: p, seasonalAdjust: seasonalAdjust, now: now) ?? now
                let days = CareEngine.daysUntil(due, now: now)
                return NeedyPlant(
                    id: p.id,
                    nickname: p.nickname,
                    species: p.species,
                    symbol: p.symbol,
                    colorHex: p.colorHex,
                    intervalDays: p.wateringIntervalDays,
                    overdueDays: days
                )
            }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Neediest Plants")

                if neediest.isEmpty {
                    Text("No plants")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(neediest) { p in
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: p.colorHex).opacity(0.16))
                                    .frame(width: 36, height: 36)
                                Image(systemName: p.symbol)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(hex: p.colorHex))
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.nickname)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.text)
                                Text(Format.intervalLabel(days: p.intervalDays))
                                    .font(.caption2)
                                    .foregroundStyle(Brand.text3)
                            }

                            Spacer()

                            Text(Format.relativeDue(days: p.overdueDays))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(p.overdueDays < 0 ? Brand.danger : (p.overdueDays == 0 ? Brand.warn : Brand.live))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(p.nickname): \(Format.relativeDue(days: p.overdueDays))")

                        if p.id != neediest.last?.id {
                            Divider().background(Brand.hairline)
                        }
                    }
                }
            }
        }
    }
}
