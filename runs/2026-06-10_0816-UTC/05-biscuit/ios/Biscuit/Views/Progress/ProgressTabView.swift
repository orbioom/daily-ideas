import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @AppStorage("selectedDogID") private var selectedDogID = ""

    private var dog: Dog? { CurrentDog.resolve(from: dogs, selectedID: selectedDogID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let dog {
                    content(dog)
                } else {
                    EmptyStateView(icon: "chart.bar.xaxis",
                                   title: "No dog selected",
                                   message: "Add a dog to track progress.")
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DogPickerMenu(dogs: dogs, selectedID: $selectedDogID)
                }
            }
        }
    }

    private func content(_ dog: Dog) -> some View {
        let stats = TrainingEngine.stats(for: dog)
        return ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    bigStat("\(stats.masteredCount)", "mastered")
                    bigStat("\(stats.streak)", "day streak")
                    bigStat(DurationFormat.friendly(stats.totalMinutes), "trained")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Curriculum progress")
                    ForEach(stats.levelProgress) { lp in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lp.level.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(lp.mastered)/\(lp.total)")
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text3)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Brand.hairline)
                                    Capsule()
                                        .fill(Brand.live.gradient)
                                        .frame(width: geo.size.width * lp.fraction)
                                }
                            }
                            .frame(height: 8)
                            .accessibilityLabel("\(lp.level.rawValue): \(lp.mastered) of \(lp.total) mastered")
                        }
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Sessions · last 14 days")
                    if stats.sessionCount == 0 {
                        Text("No sessions logged yet.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        Chart(stats.sessionsPerDay) { d in
                            BarMark(
                                x: .value("Day", d.day, unit: .day),
                                y: .value("Sessions", d.count)
                            )
                            .foregroundStyle(d.count > 0 ? Brand.live.gradient : Brand.text3.gradient)
                            .cornerRadius(3)
                        }
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day(), centered: true)
                            }
                        }
                    }
                }
                .glassCard()
                .accessibilityLabel("Bar chart of training sessions per day over the last two weeks")

                if stats.sessionCount > 0 {
                    HStack(spacing: 14) {
                        bigStat("\(stats.sessionCount)", "sessions")
                        bigStat("\(Int((stats.greatRate * 100).rounded()))%", "rated great")
                        bigStat("\(stats.inProgressCount)", "in progress")
                    }
                }
            }
            .padding(16)
        }
    }

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(17, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
