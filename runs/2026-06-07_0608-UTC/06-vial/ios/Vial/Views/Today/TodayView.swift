import SwiftUI
import SwiftData

/// The day's doses, in time order, with one-tap taken/skip and a progress ring.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var slots: [DoseEngine.Slot] {
        DoseEngine.slots(for: meds.filter { $0.isActive }, on: Date(), logs: logs)
    }
    private var takenCount: Int { slots.filter { $0.taken }.count }

    var body: some View {
        NavigationStack {
            Group {
                if meds.filter({ $0.isActive }).isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "pills", title: "No medications",
                                       message: "Add a medication on the Meds tab to see today's doses here.")
                        .glassCard().padding()
                    }
                } else if slots.isEmpty {
                    ScrollView {
                        ringCard
                        EmptyStateView(icon: "moon.zzz", title: "Nothing due today",
                                       message: "No doses are scheduled for today. Enjoy the day off.")
                        .glassCard().padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ringCard
                            VStack(spacing: 10) {
                                ForEach(slots) { slot in DoseSlotRow(slot: slot,
                                    onTaken: { apply(slot, "taken") },
                                    onSkip: { apply(slot, "skipped") },
                                    onClear: { apply(slot, nil) }) }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(Date().formatted(.dateTime.weekday(.wide).month().day()))
            .background(Brand.pageBackground)
        }
    }

    private var ringCard: some View {
        let total = slots.count
        let frac = total > 0 ? Double(takenCount) / Double(total) : 0
        return HStack(spacing: 20) {
            DoseRing(fraction: frac, reduceMotion: reduceMotion)
                .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 4) {
                Text(total == 0 ? "No doses" : "\(takenCount) of \(total) taken")
                    .font(.headline).foregroundStyle(Brand.text)
                let remaining = total - slots.filter { $0.log != nil }.count
                Text(remaining > 0 ? "\(remaining) still to log" : "All doses logged")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
            Spacer()
        }
        .padding(20)
        .glassCard()
    }

    /// Applies a status change and keeps supply counts consistent.
    private func apply(_ slot: DoseEngine.Slot, _ newStatus: String?) {
        let oldConsumed = (slot.log?.status == "taken") ? 1.0 : 0.0
        let newConsumed = (newStatus == "taken") ? 1.0 : 0.0
        let delta = (oldConsumed - newConsumed) * slot.medication.unitsPerDose
        // delta > 0 means we are giving units back to supply

        if let newStatus {
            if let log = slot.log { log.status = newStatus; log.loggedAt = Date() }
            else {
                let log = DoseLog(scheduledAt: slot.scheduledAt, status: newStatus, medication: slot.medication)
                context.insert(log)
            }
        } else if let log = slot.log {
            context.delete(log)
        }
        slot.medication.quantityOnHand = max(0, slot.medication.quantityOnHand + delta)
        try? context.save()
        if newStatus == "taken" { Haptics.success() } else { Haptics.tap() }
    }
}

struct DoseSlotRow: View {
    let slot: DoseEngine.Slot
    var onTaken: () -> Void, onSkip: () -> Void, onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: slot.medication.colorHex)).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.medication.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(DoseEngine.formatMinutes(slot.minutesOfDay)) · \(doseText)")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            statusControl
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(slot.taken ? Brand.live.opacity(0.5) : Brand.glassStroke.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slot.medication.name) at \(DoseEngine.formatMinutes(slot.minutesOfDay)), \(slot.status)")
    }

    private var doseText: String {
        let u = slot.medication.unitsPerDose
        let n = u == u.rounded() ? "\(Int(u))" : String(format: "%.1f", u)
        return "\(n) \(slot.medication.form.lowercased())\(u == 1 ? "" : "s")"
    }

    @ViewBuilder private var statusControl: some View {
        if slot.taken {
            Button { onClear() } label: {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Brand.live)
            }.accessibilityLabel("Taken — tap to undo")
        } else if slot.skipped {
            Button { onClear() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Brand.text3)
            }.accessibilityLabel("Skipped — tap to undo")
        } else {
            HStack(spacing: 8) {
                Button { onSkip() } label: {
                    Image(systemName: "xmark").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text3)
                        .frame(width: 34, height: 34)
                        .background(Brand.hairline.opacity(0.6), in: Circle())
                }.accessibilityLabel("Skip")
                Button { onTaken() } label: {
                    Image(systemName: "checkmark").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Brand.inkGradient, in: Circle())
                }.accessibilityLabel("Mark taken")
            }
        }
    }
}

/// A breathing progress ring.
struct DoseRing: View {
    let fraction: Double
    var reduceMotion: Bool = false
    var body: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.001, fraction))
                .stroke(Brand.live, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: fraction)
            Text("\(Int((fraction * 100).rounded()))%")
                .font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
        }
        .accessibilityElement()
        .accessibilityLabel("\(Int((fraction * 100).rounded())) percent of today's doses taken")
    }
}
