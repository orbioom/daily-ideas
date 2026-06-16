import SwiftUI
import SwiftData

struct ExpenseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var vehicles: [Vehicle]

    let expense: Expense?
    let onSave: () -> Void

    @State private var date = Date()
    @State private var category: ExpenseCategory = .fuel
    @State private var customLabel = ""
    @State private var amountText = ""
    @State private var deductible = true
    @State private var notes = ""
    @State private var selectedVehicle: Vehicle?
    @State private var saveError: String?
    @State private var showPaywall = false

    private let isEditing: Bool

    init(expense: Expense?, onSave: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        self.isEditing = expense != nil
    }

    private var parsedAmount: Decimal? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, let d = Decimal(string: cleaned), d >= 0 else { return nil }
        return d
    }

    private var canSave: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.symbol).tag(c)
                        }
                    }
                    if category == .other {
                        customField
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(17, .semibold))
                            .frame(maxWidth: 140)
                    }
                    if !canSave {
                        Text("Enter an amount greater than zero.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.warn)
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    Toggle("Tax deductible", isOn: $deductible)
                        .tint(Theme.accent)
                } footer: {
                    Text("Deductible expenses count toward your year total. Personal costs can be logged but won't reduce your deduction.")
                }
                .listRowBackground(Theme.surface)

                Section("Details") {
                    if !vehicles.isEmpty {
                        Picker("Vehicle", selection: $selectedVehicle) {
                            Text("None").tag(Vehicle?.none)
                            ForEach(vehicles) { v in
                                Text(v.name).tag(Vehicle?.some(v))
                            }
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Expense" : "Log Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear(perform: loadInitial)
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private var customField: some View {
        Group {
            if isPro {
                TextField("Custom category name", text: $customLabel)
            } else {
                Button {
                    showPaywall = true
                    Haptics.warning(settings.hapticsEnabled)
                } label: {
                    HStack {
                        Text("Custom category name")
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Label("Pro", systemImage: "lock.fill")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private func loadInitial() {
        if let expense {
            date = expense.date
            category = expense.category
            customLabel = expense.customLabel
            amountText = NSDecimalNumber(decimal: expense.amount).stringValue
            deductible = expense.deductible
            notes = expense.notes
            selectedVehicle = expense.vehicle
        } else {
            selectedVehicle = vehicles.first { $0.isDefault } ?? vehicles.first
        }
    }

    private func save() {
        guard let amount = parsedAmount, amount > 0 else {
            saveError = "Please enter an amount greater than zero."
            return
        }
        let target = expense ?? Expense()
        target.date = date
        target.category = category
        target.customLabel = (isPro && category == .other)
            ? customLabel.trimmingCharacters(in: .whitespaces) : ""
        target.amount = amount
        target.deductible = deductible
        target.notes = notes.trimmingCharacters(in: .whitespaces)
        target.vehicle = selectedVehicle

        if expense == nil { context.insert(target) }
        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            saveError = "Something went wrong saving this expense. Please try again."
        }
    }
}
