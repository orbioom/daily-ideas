import SwiftUI
import SwiftData

struct UnitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let property: Property
    let unit: Unit?
    var onSave: () -> Void

    @State private var label = ""
    @State private var bedrooms = 1
    @State private var bathrooms = 1.0
    @State private var sqft = ""
    @State private var marketRent = ""
    @State private var status: UnitStatus = .vacant

    // Lease fields
    @State private var hasLease = false
    @State private var tenantName = ""
    @State private var tenantEmail = ""
    @State private var tenantPhone = ""
    @State private var leaseStart = Date()
    @State private var hasEndDate = false
    @State private var leaseEnd = Date()
    @State private var monthlyRent = ""
    @State private var deposit = ""
    @State private var rentDueDay = 1
    @State private var validationMessage: String?

    private var isEditing: Bool { unit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Unit") {
                    TextField("Label (e.g. Unit A)", text: $label)
                        .accessibilityLabel("Unit label")
                    Stepper("Bedrooms: \(bedrooms)", value: $bedrooms, in: 0...12)
                    Stepper("Bathrooms: \(bathString)", value: $bathrooms, in: 0...12, step: 0.5)
                    moneyField("Square feet", text: $sqft, keyboard: .numberPad)
                    moneyField("Market rent", text: $marketRent)
                    Picker("Status", selection: $status) {
                        ForEach(UnitStatus.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                }

                Section {
                    Toggle("Active lease / tenant", isOn: $hasLease.animation())
                        .tint(Theme.accent)
                } header: {
                    Text("Tenant")
                } footer: {
                    Text("Adding a tenant marks this unit occupied and includes it in the rent roll.")
                }

                if hasLease {
                    Section("Lease details") {
                        TextField("Tenant name", text: $tenantName)
                        TextField("Email", text: $tenantEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        TextField("Phone", text: $tenantPhone)
                            .keyboardType(.phonePad)
                        moneyField("Monthly rent", text: $monthlyRent)
                        moneyField("Deposit", text: $deposit)
                        Picker("Rent due day", selection: $rentDueDay) {
                            ForEach(1...28, id: \.self) { Text("\($0)").tag($0) }
                        }
                        DatePicker("Start date", selection: $leaseStart, displayedComponents: .date)
                        Toggle("Has end date", isOn: $hasEndDate.animation())
                            .tint(Theme.accent)
                        if hasEndDate {
                            DatePicker("End date", selection: $leaseEnd, displayedComponents: .date)
                        }
                    }
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(isEditing ? "Edit Unit" : "New Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private var bathString: String {
        bathrooms.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(bathrooms)) : String(format: "%.1f", bathrooms)
    }

    private func moneyField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .decimalPad) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.ink)
            Spacer()
            TextField("0", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                .accessibilityLabel(label)
        }
    }

    private func loadIfEditing() {
        guard let unit, label.isEmpty else { return }
        label = unit.label
        bedrooms = unit.bedrooms
        bathrooms = unit.bathrooms
        sqft = "\(unit.sqft)"
        marketRent = decimalString(unit.marketRent)
        status = unit.status
        if let lease = unit.activeLease {
            hasLease = true
            tenantName = lease.tenantName
            tenantEmail = lease.tenantEmail
            tenantPhone = lease.tenantPhone
            leaseStart = lease.startDate
            if let end = lease.endDate {
                hasEndDate = true
                leaseEnd = end
            }
            monthlyRent = decimalString(lease.monthlyRent)
            deposit = decimalString(lease.deposit)
            rentDueDay = lease.rentDueDay
        }
    }

    private func decimalString(_ value: Decimal) -> String {
        let rounded = Money.round(value, scale: 2)
        var result = "\(rounded)"
        if result.hasSuffix(".0") { result = String(result.dropLast(2)) }
        return result
    }

    private func parse(_ text: String) -> Decimal {
        Decimal(string: text.filter { $0.isNumber || $0 == "." }) ?? 0
    }

    private func parseInt(_ text: String) -> Int {
        Int(text.filter { $0.isNumber }) ?? 0
    }

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else {
            validationMessage = "Please enter a unit label."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        if hasLease {
            guard !tenantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                validationMessage = "Please enter a tenant name."
                Haptics.notify(.error, enabled: settings.hapticsEnabled)
                return
            }
            guard parse(monthlyRent) > 0 else {
                validationMessage = "Monthly rent must be greater than zero."
                Haptics.notify(.error, enabled: settings.hapticsEnabled)
                return
            }
            if hasEndDate && leaseEnd < leaseStart {
                validationMessage = "End date must be after the start date."
                Haptics.notify(.error, enabled: settings.hapticsEnabled)
                return
            }
        }

        let targetUnit: Unit
        if let unit {
            targetUnit = unit
            unit.label = trimmedLabel
            unit.bedrooms = bedrooms
            unit.bathrooms = bathrooms
            unit.sqft = parseInt(sqft)
            unit.marketRent = parse(marketRent)
        } else {
            let newUnit = Unit(
                label: trimmedLabel,
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                sqft: parseInt(sqft),
                marketRent: parse(marketRent),
                status: .vacant
            )
            newUnit.property = property
            property.units.append(newUnit)
            context.insert(newUnit)
            targetUnit = newUnit
        }

        applyLease(to: targetUnit)

        do {
            try context.save()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            validationMessage = "Could not save. Please try again."
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
        }
    }

    private func applyLease(to unit: Unit) {
        let existing = unit.activeLease
        if hasLease {
            let lease = existing ?? {
                let l = Lease(tenantName: "", startDate: leaseStart, monthlyRent: 0, deposit: 0, rentDueDay: rentDueDay)
                l.unit = unit
                unit.leases.append(l)
                context.insert(l)
                return l
            }()
            lease.tenantName = tenantName.trimmingCharacters(in: .whitespacesAndNewlines)
            lease.tenantEmail = tenantEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            lease.tenantPhone = tenantPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            lease.startDate = leaseStart
            lease.endDate = hasEndDate ? leaseEnd : nil
            lease.monthlyRent = parse(monthlyRent)
            lease.deposit = parse(deposit)
            lease.rentDueDay = min(max(rentDueDay, 1), 28)
            lease.isActive = true
            unit.status = .occupied
        } else {
            // Deactivate any active lease and mark vacant.
            if let lease = existing {
                lease.isActive = false
                if lease.endDate == nil { lease.endDate = Date() }
            }
            unit.status = .vacant
        }
    }
}
