import SwiftUI
import SwiftData

struct RecurringView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringRule.dayOfMonth) private var rules: [RecurringRule]
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var editing: RecurringRule?
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            if rules.isEmpty {
                EmptyStateView(icon: "repeat",
                               title: "No recurring items",
                               message: "Add bills or income that repeat monthly — Tally posts them automatically.")
            } else {
                List {
                    ForEach(rules) { r in
                        Button { editing = r } label: { row(r) }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.white.opacity(0.001))
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(rules[i]) }
                        try? context.save(); Haptics.warning()
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Recurring")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add recurring item")
            }
        }
        .sheet(item: $editing) { r in RecurringEditorView(mode: .edit(r)) }
        .sheet(isPresented: $showAdd) { RecurringEditorView(mode: .create) }
    }

    private func row(_ r: RecurringRule) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(r.category.color.opacity(0.16)).frame(width: 38, height: 38)
                Image(systemName: r.category.icon).foregroundStyle(r.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(r.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("Day \(r.dayOfMonth) · \(r.isActive ? "active" : "paused")")
                    .font(.caption2).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(Money.format(r.isIncome ? r.amount : -r.amount, code: currency, showSign: true))
                .font(Brand.mono(13)).foregroundStyle(r.isIncome ? Brand.live : Brand.text)
        }
        .accessibilityElement(children: .combine)
    }
}
