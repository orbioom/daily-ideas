import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Attack.start, order: .reverse) private var attacks: [Attack]

    @AppStorage("aura.overuseThreshold") private var overuseThreshold = 10

    @State private var showEditor = false
    @State private var showMedSheetForOngoing = false

    @Query(sort: \Medication.name) private var catalog: [Medication]

    private var ongoing: Attack? { AuraEngine.ongoingAttack(attacks) }
    private var overuse: AuraEngine.OveruseResult {
        AuraEngine.medicationOveruse(attacks, threshold: overuseThreshold)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let ongoing {
                        OngoingAttackCard(attack: ongoing,
                                          onEnd: { endAttack(ongoing) },
                                          onAddMeds: { showMedSheetForOngoing = true })
                    } else {
                        calmOverview
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Today")
            .sheet(isPresented: $showEditor) {
                AttackEditorView(existing: nil)
            }
            .sheet(isPresented: $showMedSheetForOngoing) {
                MedEntryView(catalog: catalog) { draft in
                    addMed(draft, to: ongoing)
                }
            }
        }
    }

    // MARK: Calm overview (no ongoing attack)

    private var calmOverview: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Eyebrow(text: "Status")
                if let days = AuraEngine.daysSinceLast(attacks) {
                    Text("\(days)")
                        .font(Brand.mono(56, weight: .bold))
                        .foregroundStyle(Brand.live)
                    Text(days == 1 ? "day since your last attack" : "days since your last attack")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                } else {
                    Text("All clear")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("No attacks logged yet. Hopefully it stays that way.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .glassCard(padding: 22)
            .accessibilityElement(children: .combine)

            if overuse.status == .atRisk {
                overuseBanner
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(value: "\(AuraEngine.attacksThisMonth(attacks))", label: "This month")
                StatTile(value: "\(overuse.acuteDays)", label: "Acute-med days /30",
                         tint: overuse.status == .atRisk ? Brand.warn : Brand.text)
            }

            Button {
                Haptics.tap()
                showEditor = true
            } label: {
                Label("Log attack", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.top, 4)
        }
    }

    private var overuseBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pills.circle")
                .font(.title2)
                .foregroundStyle(Brand.warn)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Medication-overuse watch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("You've taken acute medication on \(overuse.acuteDays) of the last 30 days (limit \(overuse.threshold)). Frequent use can itself drive headaches — worth a chat with your clinician.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.warn.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.warn.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Medication overuse warning. Acute medication taken on \(overuse.acuteDays) of the last 30 days, limit \(overuse.threshold).")
    }

    // MARK: Actions

    private func endAttack(_ attack: Attack) {
        attack.end = Date()
        try? context.save()
        Haptics.success()
    }

    private func addMed(_ draft: DraftMed, to attack: Attack?) {
        guard let attack else { return }
        let m = MedTaken(name: draft.name, doseMg: draft.doseMg,
                         minutesAfterOnset: draft.minutesAfterOnset,
                         relief: draft.relief, isAcute: draft.isAcute)
        m.attack = attack
        context.insert(m)
        try? context.save()
        Haptics.tap()
    }
}

/// A live card for an ongoing attack: duration ticks via TimelineView.
struct OngoingAttackCard: View {
    let attack: Attack
    let onEnd: () -> Void
    let onAddMeds: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                StatusDot(color: Brand.danger)
                Eyebrow(text: "Ongoing attack")
                Spacer()
                Label(attack.type.label, systemImage: attack.type.symbol)
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = max(0, Int(context.date.timeIntervalSince(attack.start)))
                Text(Format.clock(seconds))
                    .font(Brand.mono(44, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .accessibilityLabel("Attack duration")
                    .accessibilityValue(Format.duration(minutes: seconds / 60))
            }

            HStack(spacing: 10) {
                IntensityDot(intensity: attack.intensity)
                if attack.auraPresent {
                    TagChip(text: "Aura", systemImage: "sparkles", tint: Brand.magic)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    Haptics.success()
                    onEnd()
                } label: {
                    Label("End attack", systemImage: "checkmark")
                }
                .buttonStyle(InkButtonStyle())

                Button {
                    onAddMeds()
                } label: {
                    Label("Add meds", systemImage: "pills")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .glassCard(padding: 20)
    }
}
