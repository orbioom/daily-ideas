import SwiftUI
import SwiftData

/// Add or edit an expense with a live, always-reconciling per-person preview.
/// Validates: title, amount > 0, a payer, at least one participant, and (for exact
/// mode) that entered amounts sum exactly to the total.
struct ExpenseEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let group: SplitGroup
    let expense: Expense?

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var notes = ""
    @State private var splitMode: SplitMode = .equal
    @State private var payerID: UUID?
    /// memberID -> selected (participant toggle).
    @State private var selected: Set<UUID> = []
    /// memberID -> raw text for exact amount or weight.
    @State private var shareText: [UUID: String] = [:]
    @State private var validationMessage: String?

    private var isEditing: Bool { expense != nil }
    private var members: [Member] { group.orderedMembers }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                payerSection
                splitSection
                participantsSection
                previewSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit expense" : "New expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canAttemptSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            TextField("Title", text: $title)
                .accessibilityLabel("Expense title, required")
            HStack {
                Text(group.currencySymbol)
                    .foregroundStyle(Brand.text2)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(Brand.mono(17))
                    .accessibilityLabel("Amount, required")
            }
            DatePicker("Date", selection: $date, displayedComponents: .date)
        } header: {
            Text("Details")
        } footer: {
            if let validationMessage {
                Text(validationMessage).foregroundStyle(Brand.owe)
            }
        }
    }

    private var payerSection: some View {
        Section("Paid by") {
            Picker("Paid by", selection: Binding(
                get: { payerID ?? members.first?.id },
                set: { payerID = $0 }
            )) {
                ForEach(members) { member in
                    Text(member.name).tag(Optional(member.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var splitSection: some View {
        Section {
            Picker("Split", selection: $splitMode) {
                ForEach(SplitMode.allCases) { mode in
                    Text(mode.shortTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Split")
        } footer: {
            Text(splitMode.hint)
        }
    }

    private var participantsSection: some View {
        Section {
            ForEach(members) { member in
                participantRow(member)
            }
        } header: {
            HStack {
                Text("Participants")
                Spacer()
                Button(allSelected ? "None" : "All") { toggleAll() }
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
            }
        }
    }

    @ViewBuilder
    private func participantRow(_ member: Member) -> some View {
        let isOn = selected.contains(member.id)
        HStack(spacing: 12) {
            Button {
                toggle(member.id)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isOn ? Brand.live : Brand.text3)
                    MemberAvatar(member: member, size: 28)
                    Text(member.name)
                        .foregroundStyle(Brand.text)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            if isOn && splitMode != .equal {
                TextField(splitMode == .exact ? "0.00" : "1",
                          text: bindingForShare(member.id))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Brand.mono(15))
                    .frame(maxWidth: 90)
                    .accessibilityLabel(splitMode == .exact
                                        ? "\(member.name) exact amount"
                                        : "\(member.name) weight")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var previewSection: some View {
        Section {
            let preview = computePreview()
            if preview.isEmpty {
                Text("Select at least one participant to see the split.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(preview) { row in
                    HStack {
                        Text(row.name)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text(Money.string(row.amount, symbol: group.currencySymbol))
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(Brand.text)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.name) owes \(Money.string(row.amount, symbol: group.currencySymbol))")
                }
                Divider().overlay(Brand.glassStroke.opacity(0.4))
                HStack {
                    Text(reconciles ? "Reconciles to total" : "Doesn't match total")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(reconciles ? Brand.live : Brand.owe)
                    Spacer()
                    Text(Money.string(previewSum, symbol: group.currencySymbol))
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(reconciles ? Brand.live : Brand.owe)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Per-person preview")
        } footer: {
            if splitMode == .exact {
                Text("Exact amounts must add up to the total before you can save.")
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Optional notes", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    // MARK: - Preview computation

    private struct PreviewRow: Identifiable {
        let id: UUID
        let name: String
        let amount: Decimal
    }

    private var amountValue: Decimal { Money.parse(amountText) ?? 0 }

    private func selectedShareInputs() -> [BalanceEngine.ShareInput] {
        members.filter { selected.contains($0.id) }.map { member in
            let raw = shareText[member.id] ?? ""
            let value: Decimal
            switch splitMode {
            case .equal: value = 0
            case .exact: value = Money.parseWeight(raw) ?? 0
            case .shares: value = Money.parseWeight(raw) ?? 0
            }
            return BalanceEngine.ShareInput(memberID: member.id, value: value)
        }
    }

    private func computePreview() -> [PreviewRow] {
        let inputs = selectedShareInputs()
        guard !inputs.isEmpty, amountValue > 0 else { return [] }
        let owed = BalanceEngine.owedShares(amount: amountValue, mode: splitMode, shares: inputs)
        return members.compactMap { member in
            guard selected.contains(member.id), let amount = owed[member.id] else { return nil }
            return PreviewRow(id: member.id, name: member.name, amount: amount)
        }
    }

    private var previewSum: Decimal {
        computePreview().reduce(Decimal()) { $0 + $1.amount }
    }

    private var reconciles: Bool {
        BalanceEngine.round2(previewSum) == BalanceEngine.round2(amountValue)
    }

    // MARK: - Bindings & toggles

    private func bindingForShare(_ id: UUID) -> Binding<String> {
        Binding(
            get: { shareText[id] ?? "" },
            set: { shareText[id] = $0 }
        )
    }

    private var allSelected: Bool {
        !members.isEmpty && members.allSatisfy { selected.contains($0.id) }
    }

    private func toggleAll() {
        if allSelected { selected.removeAll() }
        else { selected = Set(members.map(\.id)) }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) }
        else { selected.insert(id) }
    }

    private var canAttemptSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && Money.parse(amountText) != nil
        && !selected.isEmpty
        && payerID != nil
    }

    // MARK: - Load & save

    private func load() {
        if let expense {
            title = expense.title
            amountText = NSDecimalNumber(decimal: expense.amount).stringValue
            date = expense.date
            notes = expense.notes
            splitMode = expense.splitMode
            payerID = expense.payer?.id ?? members.first?.id
            for share in expense.shares {
                if let mid = share.member?.id {
                    selected.insert(mid)
                    if expense.splitMode != .equal {
                        shareText[mid] = NSDecimalNumber(decimal: share.value).stringValue
                    }
                }
            }
        } else {
            splitMode = settings.defaultSplitMode
            payerID = members.first?.id
            // Default to everyone selected for a fresh expense.
            selected = Set(members.map(\.id))
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            validationMessage = "Give the expense a title."
            return
        }
        guard let amount = Money.parse(amountText) else {
            validationMessage = "Enter an amount greater than zero."
            return
        }
        guard !selected.isEmpty else {
            validationMessage = "Pick at least one participant."
            return
        }
        guard let payerID, let payer = members.first(where: { $0.id == payerID }) else {
            validationMessage = "Choose who paid."
            return
        }

        let inputs = selectedShareInputs()

        if splitMode == .exact {
            let sum = inputs.reduce(Decimal()) { $0 + BalanceEngine.round2($1.value) }
            if BalanceEngine.round2(sum) != BalanceEngine.round2(amount) {
                validationMessage = "Exact amounts must add up to \(Money.string(amount, symbol: group.currencySymbol)). They currently total \(Money.string(sum, symbol: group.currencySymbol))."
                return
            }
        }

        if splitMode == .shares {
            let totalWeight = inputs.reduce(Decimal()) { $0 + max(0, $1.value) }
            if totalWeight <= 0 {
                validationMessage = "Give at least one participant a positive share weight."
                return
            }
        }

        let target: Expense
        if let expense {
            target = expense
            target.title = cleanTitle
            target.amount = amount
            target.date = date
            target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            target.splitMode = splitMode
            target.payer = payer
            // Rebuild shares to match the current selection cleanly.
            for old in target.shares { context.delete(old) }
            target.shares.removeAll()
        } else {
            target = Expense(title: cleanTitle, amount: amount, date: date,
                             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                             splitMode: splitMode, payer: payer)
            target.group = group
            group.expenses.append(target)
            context.insert(target)
        }

        for input in inputs {
            guard let member = members.first(where: { $0.id == input.memberID }) else { continue }
            let value: Decimal = splitMode == .equal ? 0 : input.value
            let share = ExpenseShare(value: value, member: member)
            share.expense = target
            target.shares.append(share)
        }

        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
