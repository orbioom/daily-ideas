import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \FoodLogEntry.date, order: .reverse) private var foods: [FoodLogEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]

    private var totalFoods: Int { foods.count }
    private var totalSymptoms: Int { symptoms.count }
    private var avgSeverity: Double {
        guard !symptoms.isEmpty else { return 0 }
        return Double(symptoms.reduce(0) { $0 + $1.severity }) / Double(symptoms.count)
    }

    private var symptomsByName: [(name: String, avg: Double, count: Int)] {
        let grouped = Dictionary(grouping: symptoms, by: \.symptomName)
        return grouped.map { (name: $0.key, avg: Double($0.value.reduce(0){$0+$1.severity})/Double($0.value.count), count: $0.value.count) }
            .sorted { $0.avg > $1.avg }
            .prefix(6).map { $0 }
    }

    private var recentSymptomTrend: [(day: String, avg: Double)] {
        let cal = Calendar.current
        let last7 = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }.reversed()
        return last7.map { day in
            let daySymptoms = symptoms.filter { cal.isDate($0.date, inSameDayAs: day) }
            let avg = daySymptoms.isEmpty ? 0.0 : Double(daySymptoms.reduce(0){$0+$1.severity}) / Double(daySymptoms.count)
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return (day: fmt.string(from: day), avg: avg)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    statsRow
                    if symptoms.count >= 3 {
                        trendChart
                        symptomBars
                    } else {
                        placeholderInsight
                    }
                }
                .padding()
            }
            .background(NourishTheme.background.ignoresSafeArea())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            InsightStatCard(value: "\(totalFoods)", label: "Foods Logged", color: NourishTheme.sage)
            InsightStatCard(value: "\(totalSymptoms)", label: "Symptoms", color: NourishTheme.terra)
            InsightStatCard(value: String(format: "%.1f", avgSeverity), label: "Avg Severity", color: NourishTheme.corn)
        }
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Severity — Last 7 Days")
                .font(.headline)
            Chart(recentSymptomTrend, id: \.day) { item in
                LineMark(x: .value("Day", item.day), y: .value("Severity", item.avg))
                    .foregroundStyle(NourishTheme.terra)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Day", item.day), y: .value("Severity", item.avg))
                    .foregroundStyle(NourishTheme.terra.opacity(0.1))
                    .interpolationMethod(.catmullRom)
            }
            .frame(height: 140)
            .chartYScale(domain: 0...5)
        }
        .padding()
        .background(NourishTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var symptomBars: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Symptoms by Severity")
                .font(.headline)
            ForEach(symptomsByName, id: \.name) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name).font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f avg · \(item.count)×", item.avg))
                            .font(.caption)
                            .foregroundStyle(NourishTheme.secondaryText)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NourishTheme.terra.opacity(0.2))
                            .frame(width: geo.size.width)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NourishTheme.terra)
                            .frame(width: geo.size.width * (item.avg / 5.0))
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(NourishTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var placeholderInsight: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(NourishTheme.sage.opacity(0.4))
            Text("Log more data to see patterns")
                .font(.subheadline)
                .foregroundStyle(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(NourishTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct InsightStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(NourishTheme.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(NourishTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }
}
