import SwiftUI
import SwiftData

struct ShiftMonth: Identifiable {
    let month: Date
    let shifts: [Shift]
    var id: Date { month }
}

struct ShiftsView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @State private var jobFilter: UUID? = nil
    @State private var showAdd = false

    private var allShifts: [Shift] {
        var list = jobs.flatMap(\.shifts)
        if let jobFilter { list = list.filter { $0.job?.id == jobFilter } }
        return list.sorted { $0.date > $1.date }
    }
    private var grouped: [ShiftMonth] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: allShifts) { sh -> Date in
            cal.date(from: cal.dateComponents([.year, .month], from: sh.date)) ?? sh.date
        }
        return groups.map { ShiftMonth(month: $0.key, shifts: $0.value) }.sorted { $0.month > $1.month }
    }
    private var hasShifts: Bool { jobs.contains { !$0.shifts.isEmpty } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if jobs.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No shifts yet",
                                   message: "Add a job first, then log your shifts to build your record.")
                } else if !hasShifts {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "Log your first shift",
                                   message: "Record your hours and tips and they'll appear here.",
                                   actionTitle: "Log a shift") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if jobs.filter({ !$0.shifts.isEmpty }).count > 1 { filterBar }
                            ForEach(grouped) { group in
                                monthSection(group.month, group.shifts)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Shifts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log shift").disabled(jobs.isEmpty)
                }
            }
            .navigationDestination(for: Shift.self) { ShiftDetailView(shift: $0) }
            .sheet(isPresented: $showAdd) {
                ShiftEditView(shift: nil, preselectedJob: jobs.first { !$0.isArchived })
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All jobs", nil)
                ForEach(jobs.filter { !$0.shifts.isEmpty }) { job in
                    chip(job.name, job.id, tint: job.tint)
                }
            }
        }
    }

    private func chip(_ title: String, _ id: UUID?, tint: Color = Theme.accent) -> some View {
        Button {
            Haptics.tap(); jobFilter = id
        } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(jobFilter == id ? tint : Theme.bgElevated, in: Capsule())
                .foregroundStyle(jobFilter == id ? .white : Theme.textPrimary)
        }
        .accessibilityAddTraits(jobFilter == id ? [.isSelected] : [])
    }

    private func monthSection(_ month: Date, _ shifts: [Shift]) -> some View {
        let total = shifts.reduce(0) { $0 + $1.totalEarnings }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Fmt.monthYear(month))
                    .font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(Currency.string(total)).font(.subheadline.weight(.bold)).foregroundStyle(Theme.accent)
            }
            ForEach(shifts) { shift in
                NavigationLink(value: shift) { ShiftRow(shift: shift).apronCard() }
                    .buttonStyle(.plain)
            }
        }
    }
}
