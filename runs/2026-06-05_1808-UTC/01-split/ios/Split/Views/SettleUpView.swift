import SwiftUI
import SwiftData

/// Settle Up: the simplified settlement suggestions, a way to record an actual
/// payment (creating a Settlement), and the history of recorded payments.
struct SettleUpView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context

    @Bindable var group: SplitGroup

    @State private var showingRecord = false
    @State private var prefill: GroupAnalysis.NamedTransfer?
    @State private var settlementToDelete: Settlement?
    @State private var toast: String?

    var body: some View {
        let analysis = GroupAnalysis(group: group)
        ZStack {
            Brand.pageBackground

            ScrollView {
                VStack(spacing: 16) {
                    suggestionsCard(analysis)
                    historyCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 90)
            }

            VStack {
                Spacer()
                if !group.members.isEmpty {
                    InkButton(title: "Record a payment", systemImage: "plus") {
                        prefill = nil
                        showingRecord = true
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
            }
        }
        .navigationTitle("Settle up")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecord) {
            RecordSettlementView(group: group, prefill: prefill)
        }
        .alert("Delete this payment?", isPresented: deleteBinding, presenting: settlementToDelete) { settlement in
            Button("Delete", role: .destructive) { delete(settlement) }
            Button("Cancel", role: .cancel) { settlementToDelete = nil }
        } message: { _ in
            Text("Removing a recorded payment will adjust the balances accordingly.")
        }
        .overlay(alignment: .bottom) {
            if let toast { ToastView(message: toast) }
        }
    }

    // MARK: - Suggestions

    private func suggestionsCard(_ analysis: GroupAnalysis) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Suggested settlement")
                if group.members.isEmpty {
                    Text("Add members and expenses to see suggestions.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else if analysis.isSettled {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Brand.live)
                        Text("Everyone is settled up.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                } else {
                    Text("The fewest payments to clear all debts:")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    ForEach(analysis.transfers) { t in
                        Button {
                            prefill = t
                            showingRecord = true
                        } label: {
                            HStack {
                                TransferRow(transfer: t, symbol: group.currencySymbol)
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Brand.text3)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Record this payment")
                    }
                }
            }
        }
    }

    // MARK: - History

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Recorded payments")
                if group.settlements.isEmpty {
                    Text("No payments recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(group.orderedSettlements) { settlement in
                        settlementRow(settlement)
                        if settlement.id != group.orderedSettlements.last?.id {
                            Divider().overlay(Brand.glassStroke.opacity(0.4))
                        }
                    }
                }
            }
        }
    }

    private func settlementRow(_ settlement: Settlement) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(settlement.fromMember?.name ?? "Someone")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                    Text(settlement.toMember?.name ?? "Someone")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                }
                Text(detailLine(settlement))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer(minLength: 4)
            Text(Money.string(settlement.amount, symbol: group.currencySymbol))
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.live)
                .monospacedDigit()
            Button(role: .destructive) {
                settlementToDelete = settlement
            } label: {
                Image(systemName: "trash")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete payment")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(settlement.fromMember?.name ?? "Someone") paid \(settlement.toMember?.name ?? "someone") \(Money.string(settlement.amount, symbol: group.currencySymbol))")
    }

    private func detailLine(_ settlement: Settlement) -> String {
        var parts = [settlement.date.formatted(date: .abbreviated, time: .omitted)]
        let note = settlement.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty { parts.append(note) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Actions

    private var deleteBinding: Binding<Bool> {
        Binding(get: { settlementToDelete != nil },
                set: { if !$0 { settlementToDelete = nil } })
    }

    private func delete(_ settlement: Settlement) {
        context.delete(settlement)
        settlementToDelete = nil
        Haptics.warning(enabled: settings.hapticsEnabled)
        flash("Payment removed")
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

// MARK: - Record settlement sheet

struct RecordSettlementView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let group: SplitGroup
    let prefill: GroupAnalysis.NamedTransfer?

    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var validationMessage: String?

    private var members: [Member] { group.orderedMembers }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("From", selection: Binding(
                        get: { fromID ?? members.first?.id },
                        set: { fromID = $0 }
                    )) {
                        ForEach(members) { m in Text(m.name).tag(Optional(m.id)) }
                    }
                    Picker("To", selection: Binding(
                        get: { toID ?? members.dropFirst().first?.id ?? members.first?.id },
                        set: { toID = $0 }
                    )) {
                        ForEach(members) { m in Text(m.name).tag(Optional(m.id)) }
                    }
                } header: {
                    Text("Payment")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage).foregroundStyle(Brand.owe)
                    }
                }

                Section("Amount") {
                    HStack {
                        Text(group.currencySymbol).foregroundStyle(Brand.text2)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(Brand.mono(17))
                            .accessibilityLabel("Payment amount, required")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Note") {
                    TextField("e.g. Venmo, cash", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Record payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(Money.parse(amountText) == nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let prefill {
            fromID = prefill.from.id
            toID = prefill.to.id
            amountText = NSDecimalNumber(decimal: prefill.amount).stringValue
        } else {
            fromID = members.first?.id
            toID = members.dropFirst().first?.id ?? members.first?.id
        }
    }

    private func save() {
        guard let amount = Money.parse(amountText) else {
            validationMessage = "Enter an amount greater than zero."
            return
        }
        let resolvedFrom = fromID ?? members.first?.id
        let resolvedTo = toID ?? members.dropFirst().first?.id ?? members.first?.id
        guard let fid = resolvedFrom, let tid = resolvedTo else {
            validationMessage = "This group needs at least two members."
            return
        }
        guard fid != tid else {
            validationMessage = "Choose two different people."
            return
        }
        guard let from = members.first(where: { $0.id == fid }),
              let to = members.first(where: { $0.id == tid }) else {
            validationMessage = "Couldn't find those members."
            return
        }

        let settlement = Settlement(amount: amount, date: date,
                                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                    fromMember: from, toMember: to)
        settlement.group = group
        group.settlements.append(settlement)
        context.insert(settlement)
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
