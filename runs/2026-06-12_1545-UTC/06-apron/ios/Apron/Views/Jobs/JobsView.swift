import SwiftUI
import SwiftData

struct JobsView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var editing: Job?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if jobs.isEmpty {
                    EmptyStateView(symbol: "briefcase",
                                   title: "No jobs yet",
                                   message: "Add the places you work — each tracks its own wage, shifts and stats.",
                                   actionTitle: "Add a job") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(jobs) { job in
                                JobCard(job: job) { editing = job }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add job")
                }
            }
            .sheet(isPresented: $showAdd) { JobEditView(job: nil) }
            .sheet(item: $editing) { JobEditView(job: $0) }
        }
    }
}

struct JobCard: View {
    let job: Job
    let edit: () -> Void
    @Environment(\.modelContext) private var context

    private var summary: EarningsSummary { EarningsEngine.summarize(job.shifts) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(job.tint.opacity(0.18)).frame(width: 44, height: 44)
                    Image(systemName: job.role.symbol).foregroundStyle(job.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.name).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Text("\(job.role.rawValue) · \(Currency.string(job.hourlyWage))/h")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if job.isArchived {
                    Text("Archived").font(.caption2.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.track, in: Capsule())
                }
                Button { Haptics.tap(); edit() } label: { Image(systemName: "pencil.circle") }
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel("Edit \(job.name)")
            }
            HStack {
                MiniStat(value: "\(summary.shifts)", label: "Shifts")
                MiniStat(value: Currency.string(summary.total), label: "Earned")
                MiniStat(value: summary.hours > 0 ? Currency.string(summary.effectiveHourly) + "/h" : "—", label: "Real rate", tint: Theme.accent)
            }
        }
        .apronCard()
    }
}
