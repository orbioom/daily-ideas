import SwiftUI
import SwiftData

struct PrintsView: View {
    @Query(sort: \PrintJob.date, order: .reverse) private var jobs: [PrintJob]
    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("kwhRate") private var kwhRate = 0.15
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if jobs.isEmpty {
                    EmptyStateView(icon: "cube",
                                   title: "No prints logged",
                                   message: "Log a print to deduct filament from a spool and see what it cost.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(jobs) { j in
                                NavigationLink(value: j) { PrintRow(job: j, currency: currency, kwhRate: kwhRate) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Prints")
            .navigationDestination(for: PrintJob.self) { PrintDetailView(job: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log print")
                }
            }
            .sheet(isPresented: $showAdd) { PrintEditView(job: nil) }
        }
    }
}

private struct PrintRow: View {
    let job: PrintJob
    let currency: String
    let kwhRate: Double
    var body: some View {
        HStack(spacing: 12) {
            if let s = job.spool { ColorSwatch(hex: s.colorHex, size: 30) }
            else { Image(systemName: "cube").foregroundStyle(Brand.text3).frame(width: 30) }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(job.name).font(.headline).foregroundStyle(Brand.text).lineLimit(1)
                    if !job.success {
                        Image(systemName: "xmark.circle.fill").font(.caption).foregroundStyle(Brand.danger)
                            .accessibilityLabel("Failed")
                    }
                }
                HStack(spacing: 6) {
                    Chip(text: "\(Int(job.gramsUsed)) g")
                    if job.durationMinutes > 0 { Chip(text: durationLabel) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Money.string(job.totalCost(kwhRate: kwhRate), symbol: currency))
                    .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                Text(job.date, format: .dateTime.month().day())
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
    private var durationLabel: String {
        let h = job.durationMinutes / 60, m = job.durationMinutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
