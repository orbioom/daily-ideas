import SwiftUI
import SwiftData
import Combine

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]

    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var occurrences: [DoseOccurrence] {
        ScheduleEngine.occurrences(on: now, meds: meds, logs: logs, now: now)
    }
    private var takenCount: Int { occurrences.filter { $0.status == .taken }.count }
    private var asNeededMeds: [Medication] { meds.filter { $0.isActive && $0.schedule == .asNeeded } }
    private var hasAnything: Bool { !occurrences.isEmpty || !asNeededMeds.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if !hasAnything {
                    EmptyStateView(icon: "checklist",
                                   title: "Nothing scheduled",
                                   message: "Add a medication or supplement on the Meds tab and it’ll show up here each day.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerCard
                            if !occurrences.isEmpty { scheduleList }
                            if !asNeededMeds.isEmpty { asNeededSection }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle(greeting)
            .onReceive(ticker) { now = $0 }
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Tonight"
        }
    }

    private var headerCard: some View {
        Card(padding: 20) {
            HStack(spacing: 18) {
                let total = max(1, occurrences.count)
                RingView(progress: Double(takenCount) / Double(total), lineWidth: 10, size: 84,
                         tint: Theme.accent,
                         center: AnyView(VStack(spacing: 0) {
                            Text("\(takenCount)").font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                            Text("of \(occurrences.count)").font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkSoft)
                         }))
                VStack(alignment: .leading, spacing: 6) {
                    if occurrences.isEmpty {
                        Text("As-needed only today").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                    } else if takenCount == occurrences.count {
                        Text("All done for today 🎉").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.good)
                        Text("Every scheduled dose is logged.").font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    } else if let next = ScheduleEngine.nextDose(meds: meds, logs: logs, now: now) {
                        Text("Next up").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                        Text("\(next.med.name) · \(TimeFmt.clock(date: next.slotDate))")
                            .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                    } else {
                        Text("You’re caught up").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                        Text("No more doses due today.").font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
        }
    }

    private var scheduleList: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(Array(occurrences.enumerated()), id: \.element.id) { idx, occ in
                    DoseRow(occ: occ,
                            onTake: { take(occ) },
                            onSkip: { skip(occ) },
                            onUndo: { undo(occ) })
                    if idx < occurrences.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private var asNeededSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("As needed").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                ForEach(asNeededMeds) { med in
                    HStack(spacing: 14) {
                        PillGlyph(med: med, size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                            Text(takenTodayLabel(med)).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Button {
                            logAsNeeded(med)
                        } label: {
                            Text("Log dose").font(Theme.rounded(13, .bold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Theme.accentSoft, in: Capsule()).foregroundStyle(Theme.accent)
                        }
                    }
                    if med.id != asNeededMeds.last?.id { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private func takenTodayLabel(_ med: Medication) -> String {
        let count = logs.filter { $0.medID == med.id && $0.wasAsNeeded && Calendar.current.isDateInToday($0.takenAt) }.count
        return count == 0 ? "Not taken today" : "Taken \(count)× today"
    }

    // MARK: - Actions

    private func take(_ occ: DoseOccurrence) {
        let log = DoseLog(medID: occ.med.id, medName: occ.med.name, status: .taken,
                          scheduledAt: occ.slotDate, takenAt: Date(),
                          unitCount: Double(occ.med.dosesPerTime))
        context.insert(log)
        if occ.med.trackSupply { occ.med.supplyCount = max(0, occ.med.supplyCount - Double(occ.med.dosesPerTime)) }
        try? context.save()
        Haptics.success()
    }

    private func skip(_ occ: DoseOccurrence) {
        let log = DoseLog(medID: occ.med.id, medName: occ.med.name, status: .skipped,
                          scheduledAt: occ.slotDate, takenAt: Date(),
                          unitCount: 0)
        context.insert(log)
        try? context.save()
        Haptics.soft()
    }

    private func undo(_ occ: DoseOccurrence) {
        guard let log = occ.log else { return }
        if log.status == .taken && occ.med.trackSupply {
            occ.med.supplyCount += log.unitCount
        }
        context.delete(log)
        try? context.save()
        Haptics.tap()
    }

    private func logAsNeeded(_ med: Medication) {
        let log = DoseLog(medID: med.id, medName: med.name, status: .taken,
                          scheduledAt: Date(), takenAt: Date(),
                          unitCount: Double(med.dosesPerTime), wasAsNeeded: true)
        context.insert(log)
        if med.trackSupply { med.supplyCount = max(0, med.supplyCount - Double(med.dosesPerTime)) }
        try? context.save()
        Haptics.success()
    }
}
