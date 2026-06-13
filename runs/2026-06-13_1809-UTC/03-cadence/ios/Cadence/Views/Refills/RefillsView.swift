import SwiftUI
import SwiftData

struct RefillsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Medication.createdAt) private var meds: [Medication]

    @State private var refilling: Medication?

    private var tracked: [Medication] { meds.filter { $0.trackSupply && $0.isActive } }
    private var lowCount: Int { tracked.filter { $0.needsRefill }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if tracked.isEmpty {
                    EmptyStateView(icon: "shippingbox.fill",
                                   title: "No supply tracked",
                                   message: "Turn on “Track how much I have” when editing a medication, and Cadence will count it down and warn you before you run out.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if lowCount > 0 { banner }
                            ForEach(tracked) { med in supplyCard(med) }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Refills")
            .sheet(item: $refilling) { med in RefillSheet(med: med) }
        }
    }

    private var banner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
            Text("\(lowCount) medication\(lowCount == 1 ? "" : "s") running low")
                .font(Theme.rounded(15, .bold)).foregroundStyle(.white)
            Spacer()
        }
        .padding(16)
        .background(Theme.warn, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func supplyCard(_ med: Medication) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PillGlyph(med: med, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(med.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                        Text(med.scheduleSummary).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                    }
                    Spacer()
                    if med.needsRefill { Pill(text: "Refill", color: Theme.warn) }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(med.supplyCount))")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(med.needsRefill ? Theme.warn : Theme.ink)
                    Text(med.form.label.lowercased() + "s left")
                        .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if let days = med.daysOfSupply {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("~\(days)").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.accent)
                            Text(days == 1 ? "day" : "days").font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                if med.unitsPerDay > 0, med.refillThreshold > 0 {
                    ProgressBar(value: min(1, med.supplyCount / max(med.refillThreshold * 4, 1)),
                                tint: med.needsRefill ? Theme.warn : Theme.accent, height: 8)
                }
                Button {
                    refilling = med
                } label: {
                    Label("Mark refilled", systemImage: "plus.circle.fill")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

// A tiny reuse of the progress bar from Cascade's components is not available here,
// so Cadence defines its own lightweight bar.
struct ProgressBar: View {
    var value: Double
    var tint: Color = Theme.accent
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule().fill(tint).frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct RefillSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let med: Medication

    @State private var addText = "30"
    @State private var mode = 0   // 0 = add, 1 = set total

    private var amount: Double { Double(addText) ?? -1 }
    private var isValid: Bool { amount >= 0 }
    private var resultTotal: Double { mode == 0 ? med.supplyCount + max(0, amount) : max(0, amount) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Mode", selection: $mode) {
                            Text("Add to supply").tag(0)
                            Text("Set new total").tag(1)
                        }.pickerStyle(.segmented)
                        HStack {
                            Text(mode == 0 ? "Add" : "New total")
                            Spacer()
                            TextField("0", text: $addText).keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing).frame(maxWidth: 100)
                            Text(med.form.label.lowercased() + "s").foregroundStyle(Theme.inkSoft)
                        }
                    } footer: {
                        Text("New on-hand total: \(Int(resultTotal)) \(med.form.label.lowercased())s")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Refill \(med.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        med.supplyCount = resultTotal
                        try? context.save(); Haptics.success(); dismiss()
                    }.disabled(!isValid).bold()
                }
            }
        }
    }
}
