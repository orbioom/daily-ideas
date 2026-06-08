import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    let wedding: Wedding
    @Environment(\.modelContext) private var context
    @Query(sort: \BudgetLine.createdAt, order: .reverse) private var lines: [BudgetLine]

    @State private var showAdd = false
    @State private var editing: BudgetLine?

    private var code: String { wedding.currencyCode }
    private var summary: WeddingEngine.BudgetSummary {
        WeddingEngine.budgetSummary(lines, totalBudget: wedding.totalBudget)
    }
    private var byCat: [WeddingEngine.CategoryTotal] { WeddingEngine.budgetByCategory(lines) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if lines.isEmpty {
                    EmptyStateView(icon: "dollarsign.circle",
                                   title: "No budget items",
                                   message: "Add the things you're paying for — venue, catering, the dress — and track every cost.")
                } else {
                    List {
                        Section { summaryCard.listRowBackground(Color.white.opacity(0.001)) }
                        if byCat.count >= 2 {
                            Section { donut.listRowBackground(Color.white.opacity(0.001)) }
                        }
                        Section("Items") {
                            ForEach(lines) { line in
                                Button { editing = line } label: { row(line) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add budget item")
                }
            }
            .sheet(isPresented: $showAdd) { BudgetLineEditorView(mode: .create) }
            .sheet(item: $editing) { l in BudgetLineEditorView(mode: .edit(l)) }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                stat(Money.compact(summary.actual, code: code), "planned")
                div
                stat(Money.compact(summary.paid, code: code), "paid")
                div
                stat(Money.compact(summary.remainingToPay, code: code), "owed")
            }
            if wedding.totalBudget > 0 {
                ProgressBarLine(fraction: min(summary.actual / wedding.totalBudget, 1),
                                tint: summary.overBudget ? Brand.danger : Color(hex: 0xB07A8C))
                Text(summary.overBudget
                     ? "Over budget by \(Money.compact(-summary.budgetRemaining, code: code)) of \(Money.compact(wedding.totalBudget, code: code))"
                     : "\(Money.compact(summary.budgetRemaining, code: code)) of \(Money.compact(wedding.totalBudget, code: code)) left")
                    .font(.caption).foregroundStyle(summary.overBudget ? Brand.danger : Brand.text3)
            }
        }
        .padding(.vertical, 4)
    }

    private var donut: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "By category")
            Chart(byCat) { c in
                SectorMark(angle: .value("Amount", c.amount),
                           innerRadius: .ratio(0.6), angularInset: 1.5)
                    .foregroundStyle(c.category.color)
                    .cornerRadius(4)
            }
            .frame(height: 170)
            .accessibilityLabel("Donut chart of budget by category")
        }
        .padding(.vertical, 4)
    }

    private var div: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 30) }
    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ line: BudgetLine) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(line.category.color.opacity(0.16)).frame(width: 40, height: 40)
                Image(systemName: line.category.icon).foregroundStyle(line.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(line.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(line.vendor.isEmpty ? line.category.title : line.vendor)
                    .font(.caption2).foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(line.effectiveCost, code: code))
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                if line.isPaid {
                    Label("Paid", systemImage: "checkmark.seal.fill")
                        .font(.caption2).foregroundStyle(Brand.live).labelStyle(.titleAndIcon)
                } else if line.remainingToPay > 0 {
                    Text("\(Money.compact(line.remainingToPay, code: code)) owed")
                        .font(.caption2).foregroundStyle(Brand.warn)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(line.title), \(Money.format(line.effectiveCost, code: code))\(line.isPaid ? ", paid" : "")")
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(lines[i]) }
        try? context.save(); Haptics.warning()
    }
}
