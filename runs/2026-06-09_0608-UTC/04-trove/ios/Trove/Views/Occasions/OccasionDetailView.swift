import SwiftUI
import SwiftData

struct OccasionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var occasion: Occasion

    @AppStorage("trove.currencyCode") private var currencyCode = "USD"
    @AppStorage("trove.showGiven") private var showGiven = true

    @State private var showEdit = false
    @State private var showAddGift = false
    @State private var showDeleteConfirm = false

    private var status: GiftEngine.BudgetStatus { GiftEngine.budgetStatus(for: occasion) }
    private var nextDate: Date { GiftEngine.nextOccurrence(of: occasion) }

    private var visibleGifts: [Gift] {
        occasion.gifts
            .filter { showGiven || $0.status != .given }
            .sorted { $0.status.order < $1.status.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                dateCard
                budgetCard
                if !occasion.notes.isEmpty {
                    InfoCard(icon: "note.text", title: "Notes", value: occasion.notes, tint: Brand.text2)
                }
                giftsSection
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(occasion.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit occasion", systemImage: "pencil") }
                    Button { showAddGift = true } label: { Label("Add gift", systemImage: "gift") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete occasion", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Occasion options")
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { OccasionEditorView(occasion: occasion) }
        }
        .sheet(isPresented: $showAddGift) {
            NavigationStack { GiftEditorView(presetOccasion: occasion) }
        }
        .confirmationDialog("Delete \(occasion.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteOccasion() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Gifts linked to this occasion are kept but no longer tied to it.")
        }
    }

    private var dateCard: some View {
        InfoCard(icon: occasion.isAnnual ? "arrow.triangle.2.circlepath" : "calendar",
                 title: occasion.isAnnual ? "Next (annual)" : "Date",
                 value: "\(Format.fullDay.string(from: nextDate)) · \(Format.countdown(daysAway: GiftEngine.daysAway(nextDate)))",
                 tint: Brand.info)
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Budget")
            HStack(alignment: .center, spacing: 16) {
                ProgressRing(progress: status.budget > 0 ? status.fraction : 0,
                             lineWidth: 12,
                             tint: status.overBudget ? Brand.danger : Brand.live)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: status.overBudget ? "exclamationmark" : "gift")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(status.overBudget ? Brand.danger : Brand.text)
                            .accessibilityHidden(true)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Format.currency(status.spent, code: currencyCode)) spent")
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if status.budget > 0 {
                        Text("of \(Format.currency(status.budget, code: currencyCode))")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                        Text(status.overBudget
                             ? "Over by \(Format.currency(-status.remaining, code: currencyCode))"
                             : "\(Format.currency(status.remaining, code: currencyCode)) left")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(status.overBudget ? Brand.danger : Brand.live)
                    } else {
                        Text("No budget set")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(budgetAccessibility)
    }

    private var budgetAccessibility: String {
        if status.budget > 0 {
            let tail = status.overBudget
                ? "over by \(Format.currency(-status.remaining, code: currencyCode))"
                : "\(Format.currency(status.remaining, code: currencyCode)) remaining"
            return "Spent \(Format.currency(status.spent, code: currencyCode)) of \(Format.currency(status.budget, code: currencyCode)), \(tail)"
        }
        return "Spent \(Format.currency(status.spent, code: currencyCode)), no budget set"
    }

    private var giftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Gifts")
                Spacer()
                Button {
                    Haptics.tap()
                    showAddGift = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                }
            }
            if visibleGifts.isEmpty {
                Text("No gifts for this occasion yet. Add one to start a list.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .glassCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(visibleGifts) { gift in
                        NavigationLink {
                            GiftEditorView(gift: gift)
                        } label: {
                            GiftRow(gift: gift, showPerson: true, currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .glassCard(padding: 14)
            }
        }
    }

    private func deleteOccasion() {
        context.delete(occasion)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
