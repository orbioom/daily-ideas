import SwiftUI
import SwiftData

struct ShiftDetailView: View {
    @Bindable var shift: Shift
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalCard
                breakdownCard
                if !shift.notes.isEmpty { notesCard }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(Fmt.relativeDay(shift.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { ShiftEditView(shift: shift, preselectedJob: shift.job) }
        .confirmationDialog("Delete this shift?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { context.delete(shift); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var totalCard: some View {
        VStack(spacing: 8) {
            if let job = shift.job { JobBadge(job: job) }
            Text(Currency.string(shift.totalEarnings))
                .font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(.white)
                .minimumScaleFactor(0.5).lineLimit(1)
            Text("\(Fmt.hours(shift.hoursWorked)) · \(Currency.string(shift.effectiveHourly))/hour")
                .font(.subheadline).foregroundStyle(.white.opacity(0.9))
        }
        .padding(.vertical, 22).frame(maxWidth: .infinity)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22))
    }

    private var breakdownCard: some View {
        VStack(spacing: 0) {
            row("Cash tips", Currency.precise(shift.cashTips), Theme.cash)
            Divider().overlay(Theme.track)
            row("Card tips", Currency.precise(shift.cardTips), Theme.card)
            if shift.tipOut > 0 {
                Divider().overlay(Theme.track)
                row("Tip-out", "−" + Currency.precise(shift.tipOut), Theme.textSecondary)
            }
            Divider().overlay(Theme.track)
            row("Net tips", Currency.precise(shift.netTips), Theme.accent, bold: true)
            Divider().overlay(Theme.track)
            row("Wages", Currency.precise(shift.wages), Theme.wage)
            if let tp = shift.tipPercent {
                Divider().overlay(Theme.track)
                row("Tip rate", Fmt.percent(tp), Theme.textPrimary)
            }
            if shift.sales > 0 {
                Divider().overlay(Theme.track)
                row("Sales", Currency.precise(shift.sales), Theme.textPrimary)
            }
        }
        .apronCard()
    }

    private func row(_ label: String, _ value: String, _ tint: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(bold ? .subheadline.weight(.bold) : .subheadline.weight(.medium)).foregroundStyle(tint)
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine).accessibilityLabel("\(label): \(value)")
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text(shift.notes).font(.body).foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .apronCard()
    }
}
