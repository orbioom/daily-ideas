import SwiftUI
import SwiftData

/// Immunization schedule for one child: due/overdue/given by age, grouped by age band.
struct VaccinesDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Bindable var child: Child

    private var ageMonths: Int { child.ageMonths() }

    private var recordsByKey: [String: VaccineRecord] {
        Dictionary(child.vaccineRecords.map { ($0.vaccineKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private func status(for dose: VaccineDose) -> VaccineStatus {
        let given = recordsByKey[dose.key]?.isGiven ?? false
        return VaccineCatalog.status(childAgeMonths: ageMonths, dose: dose, given: given)
    }

    private var givenCount: Int { child.vaccineRecords.filter { $0.isGiven }.count }
    private var overdueCount: Int {
        VaccineCatalog.all.filter { status(for: $0) == .overdue }.count
    }
    private var dueCount: Int {
        VaccineCatalog.all.filter { status(for: $0) == .due }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                ForEach(VaccineCatalog.byBand, id: \.band.id) { group in
                    bandSection(group.band, items: group.items)
                }
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Vaccines")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Immunization status", systemImage: "cross.case.fill")
                HStack(spacing: 10) {
                    statTile(count: givenCount, label: "Given", color: Theme.good)
                    statTile(count: dueCount, label: "Due now", color: Theme.warn)
                    statTile(count: overdueCount, label: "Overdue", color: Theme.bad)
                }
                Text("Based on a routine CDC-style schedule for \(AgeMath.description(from: child.birthDate, to: Date())).")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private func statTile(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(color)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(label)")
    }

    private func bandSection(_ band: AgeBand, items: [VaccineDose]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: band.title)
            LazyVStack(spacing: 10) {
                ForEach(items) { dose in
                    VaccineRow(dose: dose,
                               record: recordsByKey[dose.key],
                               status: status(for: dose),
                               birthDate: child.birthDate,
                               onToggle: { toggle(dose) })
                }
            }
        }
    }

    private var disclaimer: some View {
        Text("This is a general reference schedule and is informational only — not medical advice. Always follow your pediatrician's plan.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func toggle(_ dose: VaccineDose) {
        if let record = recordsByKey[dose.key] {
            if record.isGiven {
                record.givenDate = nil
                Haptics.tap(settings.hapticsEnabled)
            } else {
                record.givenDate = Date()
                Haptics.success(settings.hapticsEnabled)
            }
        } else {
            let record = VaccineRecord(vaccineKey: dose.key, givenDate: Date(), child: child)
            context.insert(record)
            Haptics.success(settings.hapticsEnabled)
        }
        try? context.save()
    }
}

/// One vaccine dose row with given toggle and status pill.
private struct VaccineRow: View {
    let dose: VaccineDose
    let record: VaccineRecord?
    let status: VaccineStatus
    let birthDate: Date
    let onToggle: () -> Void

    private var given: Bool { record?.isGiven ?? false }

    var body: some View {
        CardView(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: given ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(given ? Theme.good : Theme.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(given ? "Given, tap to undo" : "Mark given")

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dose.name)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        StatusPill(text: status.title, color: statusColor)
                    }
                    Text("\(dose.series) · \(dose.doseLabel)")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    if let date = record?.givenDate {
                        Text("Given \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.good)
                    } else {
                        Text("Recommended at \(recommendedLabel)")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var recommendedLabel: String {
        dose.recommendedAgeMonths == 0 ? "birth" : "\(dose.recommendedAgeMonths) months"
    }

    private var statusColor: Color {
        switch status {
        case .given:    return Theme.good
        case .due:      return Theme.warn
        case .overdue:  return Theme.bad
        case .upcoming: return Theme.inkSoft
        }
    }
}
