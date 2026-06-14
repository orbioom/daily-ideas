import SwiftUI
import SwiftData
import UIKit

struct TripOverviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Bindable var trip: Trip

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var paywallReason: PaywallReason?
    @State private var showingExport = false

    private var countdown: ItineraryEngine.Countdown {
        ItineraryEngine.countdown(start: trip.startDate, end: trip.endDate)
    }
    private var orderedDays: [TripDay] { TripService.orderedDays(trip) }
    private var itemCount: Int { trip.days.reduce(0) { $0 + $1.items.count } }
    private var packProgress: PackingEngine.Progress { PackingEngine.progress(for: trip.packItems) }
    private var summary: BudgetEngine.Summary { BudgetEngine.summary(for: trip) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                quickStats
                budgetBar
                actionLinks
                if !trip.notes.isEmpty { notesCard }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit trip", systemImage: "pencil") }
                    Button { attemptExport() } label: { Label("Export itinerary", systemImage: "square.and.arrow.up") }
                    Divider()
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Trip options")
            }
        }
        .sheet(isPresented: $showingEdit) { TripEditorView(trip: trip) }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .sheet(isPresented: $showingExport) {
            ExportView(text: TripService.itineraryText(for: trip,
                                                       use24h: settings.timeFormat.use24h,
                                                       currencySymbol: settings.currencySymbol))
        }
        .confirmationDialog("Delete \(trip.name)?",
                            isPresented: $showingDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete trip", role: .destructive) {
                Haptics.warning()
                context.delete(trip)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the itinerary, packing list and expenses. This can't be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            Theme.coverGradient(hue: trip.coverHue)
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.45)],
                           startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text(ItineraryEngine.countdownLabel(countdown))
                    .font(Theme.font(.headline, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.22)))
                Text(trip.destination.isEmpty ? "Destination TBD" : trip.destination)
                    .font(Theme.font(.title2, weight: .bold))
                    .foregroundStyle(.white)
                Text(dateRangeLong)
                    .font(Theme.font(.subheadline, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(trip.destination). \(ItineraryEngine.countdownLabel(countdown)). \(dateRangeLong)")
    }

    private var dateRangeLong: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return "\(f.string(from: trip.startDate)) – \(f.string(from: trip.endDate))"
    }

    // MARK: Quick stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            StatPill(symbol: "calendar.day.timeline.left",
                     value: "\(orderedDays.count)",
                     caption: "Days")
            StatPill(symbol: "list.bullet",
                     value: "\(itemCount)",
                     caption: "Plans")
            packStat
        }
    }

    private var packStat: some View {
        VStack(spacing: 4) {
            ProgressRing(fraction: packProgress.fraction,
                         size: 40, lineWidth: 5,
                         tint: Theme.success,
                         label: "\(Int((packProgress.fraction * 100).rounded()))%")
            Text("Packed")
                .font(Theme.font(.caption2))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Packing progress")
        .accessibilityValue("\(packProgress.packed) of \(packProgress.total) packed")
    }

    // MARK: Budget bar

    private var budgetBar: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Budget")
                }
                let spent = summary.logged
                let planned = summary.planned
                let budget = summary.budget
                HStack(alignment: .firstTextBaseline) {
                    Text(BudgetEngine.currencyString(spent, symbol: settings.currencySymbol))
                        .font(Theme.font(.title3, weight: .bold))
                        .foregroundStyle(summary.isOverBudget ? Theme.danger : Theme.textPrimary)
                    Text(budget > 0 ? "of \(BudgetEngine.currencyString(budget, symbol: settings.currencySymbol))" : "no budget set")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("Planned \(BudgetEngine.currencyString(planned, symbol: settings.currencySymbol))")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                }
                budgetMeter(spent: spent, budget: budget)
                if let frac = summary.spentFraction {
                    Text(summary.isOverBudget
                         ? "Over budget by \(BudgetEngine.currencyString(spent - budget, symbol: settings.currencySymbol))"
                         : "\(Int((frac * 100).rounded()))% of budget used")
                        .font(Theme.font(.caption, weight: .medium))
                        .foregroundStyle(summary.isOverBudget ? Theme.danger : Theme.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func budgetMeter(spent: Double, budget: Double) -> some View {
        GeometryReader { geo in
            let fraction = budget > 0 ? min(spent / budget, 1.0) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(summary.isOverBudget ? Theme.danger : Theme.accent)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }

    // MARK: Action links

    private var actionLinks: some View {
        VStack(spacing: 10) {
            NavigationLink {
                ItineraryView(trip: trip)
            } label: {
                actionRow(symbol: "calendar.day.timeline.left",
                          title: "Itinerary",
                          subtitle: "\(itemCount) plans across \(orderedDays.count) days",
                          tint: Theme.accent)
            }
            NavigationLink {
                PackingView(trip: trip)
            } label: {
                actionRow(symbol: "checklist",
                          title: "Packing",
                          subtitle: packProgress.total == 0 ? "No items yet" : "\(packProgress.packed)/\(packProgress.total) packed",
                          tint: Theme.success)
            }
            NavigationLink {
                BudgetView(trip: trip)
            } label: {
                actionRow(symbol: "chart.pie.fill",
                          title: "Budget",
                          subtitle: trip.expenses.isEmpty ? "No expenses logged" : "\(trip.expenses.count) expenses",
                          tint: Theme.warning)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionRow(symbol: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(tint.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(.headline)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(Theme.font(.caption)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(Theme.separator, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(title)")
    }

    private var notesCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Notes")
                Text(trip.notes)
                    .font(Theme.font(.subheadline))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func attemptExport() {
        if isPro {
            Haptics.tap()
            showingExport = true
        } else {
            Haptics.warning()
            paywallReason = .export
        }
    }
}

// MARK: - Export sheet

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    let text: String
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = text
                        Haptics.success()
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                }
            }
        }
    }
}
