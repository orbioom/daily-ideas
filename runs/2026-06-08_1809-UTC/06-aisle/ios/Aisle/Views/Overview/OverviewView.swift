import SwiftUI
import SwiftData

struct OverviewView: View {
    @Bindable var wedding: Wedding
    @Query private var guests: [Guest]
    @Query private var lines: [BudgetLine]
    @Query private var tasks: [ChecklistTask]
    @Query private var tables: [SeatingTable]

    @State private var showSettings = false

    private var days: Int { WeddingEngine.daysUntil(wedding.weddingDate) }
    private var guestSummary: WeddingEngine.GuestSummary { WeddingEngine.guestSummary(guests) }
    private var budget: WeddingEngine.BudgetSummary {
        WeddingEngine.budgetSummary(lines, totalBudget: wedding.totalBudget)
    }
    private var checklist: WeddingEngine.ChecklistSummary { WeddingEngine.checklistSummary(tasks) }
    private var seating: WeddingEngine.SeatingSummary {
        WeddingEngine.seatingSummary(tables: tables, guests: guests)
    }
    private var code: String { wedding.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    countdownCard
                    rsvpCard
                    budgetCard
                    checklistCard
                    seatingLink
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView(wedding: wedding) }
        }
    }

    private var countdownCard: some View {
        VStack(spacing: 6) {
            Text(wedding.coupleNames).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            Text(days >= 0 ? "\(days)" : "🎉")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0xB07A8C))
            Text(days > 0 ? "days to go" : (days == 0 ? "Today!" : "Congratulations!"))
                .font(.subheadline).foregroundStyle(Brand.text2)
            Text(wedding.weddingDate.formatted(date: .complete, time: .omitted))
                .font(.caption).foregroundStyle(Brand.text3)
            if !wedding.venue.isEmpty {
                Label(wedding.venue, systemImage: "mappin.and.ellipse")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(wedding.coupleNames), \(days) days to go")
    }

    private var rsvpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Guests")
            HStack(spacing: 0) {
                stat("\(guestSummary.attendingHeads)", "attending", Brand.live)
                div
                stat("\(guestSummary.pendingHeads)", "pending", Brand.text3)
                div
                stat("\(guestSummary.declinedHeads)", "declined", Brand.danger)
                div
                stat("\(guestSummary.invitedHeads)", "invited", Brand.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Budget")
                if wedding.totalBudget > 0 {
                    ProgressBarLine(fraction: min(budget.actual / wedding.totalBudget, 1),
                                    tint: budget.overBudget ? Brand.danger : Color(hex: 0xB07A8C))
                }
                HStack {
                    Text("\(Money.compact(budget.actual, code: code)) planned")
                        .font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    if wedding.totalBudget > 0 {
                        Text(budget.overBudget
                             ? "Over by \(Money.compact(-budget.budgetRemaining, code: code))"
                             : "\(Money.compact(budget.budgetRemaining, code: code)) left")
                            .font(.caption).foregroundStyle(budget.overBudget ? Brand.danger : Brand.text2)
                    }
                }
                Text("\(Money.compact(budget.paid, code: code)) paid · \(Money.compact(budget.remainingToPay, code: code)) still owed")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Checklist")
            ProgressBarLine(fraction: checklist.fraction, tint: Color(hex: 0xB07A8C))
            HStack {
                Text("\(checklist.done) of \(checklist.total) done")
                    .font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                if checklist.overdue > 0 {
                    Text("\(checklist.overdue) overdue").font(.caption).foregroundStyle(Brand.danger)
                }
            }
        }
        .glassCard()
    }

    private var seatingLink: some View {
        NavigationLink { SeatingView(wedding: wedding) } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.grid.3x3.fill").font(.title2).foregroundStyle(Color(hex: 0xB07A8C))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seating plan").font(.headline).foregroundStyle(Brand.text)
                    Text(seating.tableCount == 0 ? "No tables yet"
                         : "\(seating.seatsAssigned)/\(seating.seatsCapacity) seats · \(seating.unassignedHeads) to seat")
                        .font(.caption).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var div: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 30) }

    private func stat(_ v: String, _ l: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(tint)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(l): \(v)")
    }
}

struct ProgressBarLine: View {
    let fraction: Double
    var tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: 9)
                Capsule().fill(tint).frame(width: max(6, geo.size.width * min(max(fraction, 0), 1)), height: 9)
            }
        }
        .frame(height: 9)
        .accessibilityHidden(true)
    }
}
