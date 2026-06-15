import SwiftUI
import SwiftData

/// Add or edit a holding. Validates inputs (positive shares, non-negative money) and writes
/// to SwiftData. Decimal-safe parsing via a TextField bound to string state.
struct HoldingFormView: View {
    enum Mode: Equatable {
        case add
        case edit(Holding)
    }

    let mode: Mode
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    // String-backed fields for robust numeric entry.
    @State private var ticker = ""
    @State private var name = ""
    @State private var sharesText = ""
    @State private var costText = ""
    @State private var dpsText = ""
    @State private var priceText = ""
    @State private var frequency: DividendFrequency = .quarterly
    @State private var payCycle: PayCycle = .cycle1
    @State private var payDay = 15
    @State private var sector: Sector = .broadETF
    @State private var account = "Taxable"

    @State private var showAccountPaywall = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var sharesValue: Decimal? { Self.parse(sharesText) }
    private var costValue: Decimal? { Self.parse(costText) }
    private var dpsValue: Decimal? { Self.parse(dpsText) }
    private var priceValue: Decimal? { priceText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : Self.parse(priceText) }

    private var canSave: Bool {
        !ticker.trimmingCharacters(in: .whitespaces).isEmpty &&
        (sharesValue ?? 0) > 0 &&
        (costValue ?? -1) >= 0 &&
        (dpsValue ?? -1) >= 0
    }

    /// Live preview of projected annual income from the current inputs.
    private var previewAnnual: Decimal {
        max(sharesValue ?? 0, 0) * max(dpsValue ?? 0, 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                positionSection
                scheduleSection
                accountSection
                previewSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Holding" : "Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAccountPaywall) {
                PaywallView(reason: .accounts)
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: Sections

    private var identitySection: some View {
        Section {
            TextField("Ticker (e.g. SCHD)", text: $ticker)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            TextField("Name (optional)", text: $name)
        } header: {
            Text("Identity")
        }
    }

    private var positionSection: some View {
        Section {
            decimalField("Shares", text: $sharesText, placeholder: "100")
            decimalField("Avg cost / share", text: $costText, placeholder: "50.00")
            decimalField("Annual dividend / share", text: $dpsText, placeholder: "2.40")
            decimalField("Current price (optional)", text: $priceText, placeholder: "—")
            Picker("Sector", selection: $sector) {
                ForEach(Sector.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
        } header: {
            Text("Position")
        } footer: {
            Text("Annual dividend per share drives all income projections. Current price is only used for current-yield and market value.")
        }
    }

    private var scheduleSection: some View {
        Section {
            Picker("Frequency", selection: $frequency) {
                ForEach(DividendFrequency.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            if frequency != .monthly {
                Picker("Pay cycle", selection: $payCycle) {
                    ForEach(PayCycle.allCases) { c in
                        Text(c.label(for: frequency)).tag(c)
                    }
                }
            }
            Stepper(value: $payDay, in: 1...28) {
                HStack {
                    Text("Pay day")
                    Spacer()
                    Text("Day \(payDay)").foregroundStyle(Theme.inkSoft)
                }
            }
        } header: {
            Text("Schedule")
        } footer: {
            Text("Used to place income in the right months on the calendar and to estimate the next payment date.")
        }
    }

    private var accountSection: some View {
        Section {
            if isPro {
                TextField("Account (e.g. Taxable, IRA)", text: $account)
            } else {
                Button {
                    showAccountPaywall = true
                } label: {
                    HStack {
                        Label("Multiple accounts", systemImage: "lock.fill")
                        Spacer()
                        Text("Pro").font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.accent)
                    }
                }
            }
        } header: {
            Text("Account")
        }
    }

    private var previewSection: some View {
        Section {
            HStack {
                Text("Projected annual income")
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(MoneyFormat.currency(previewAnnual, code: settings.currencyCode))
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.good)
                    .monospacedDigit()
            }
            if let yoc = yieldOnCostPreview {
                HStack {
                    Text("Yield on cost").foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(MoneyFormat.percent(yoc)).foregroundStyle(Theme.ink).monospacedDigit()
                }
            }
        } header: {
            Text("Preview")
        }
    }

    private var yieldOnCostPreview: Double? {
        guard let cost = costValue, cost > 0, let dps = dpsValue else { return nil }
        return IncomeEngine.ratio(dps, cost)
    }

    private func decimalField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
        }
    }

    // MARK: Load / Save

    private func loadIfEditing() {
        guard case let .edit(h) = mode else { return }
        // Avoid clobbering edits if the view re-appears.
        guard ticker.isEmpty else { return }
        ticker = h.ticker
        name = h.name
        sharesText = MoneyFormat.shares(h.shares)
        costText = NSDecimalNumber(decimal: h.avgCostPerShare).stringValue
        dpsText = NSDecimalNumber(decimal: h.annualDividendPerShare).stringValue
        priceText = h.currentPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        frequency = h.frequency
        payCycle = h.payCycle
        payDay = min(max(h.payDayOfMonth, 1), 28)
        sector = h.sector
        account = h.account ?? "Taxable"
    }

    private func save() {
        guard canSave,
              let shares = sharesValue,
              let cost = costValue,
              let dps = dpsValue else { return }
        let cleanTicker = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let resolvedName = cleanName.isEmpty ? cleanTicker : cleanName
        let resolvedAccount = isPro ? account.trimmingCharacters(in: .whitespaces) : "Taxable"

        switch mode {
        case .add:
            let holding = Holding(ticker: cleanTicker,
                                  name: resolvedName,
                                  shares: shares,
                                  avgCostPerShare: cost,
                                  annualDividendPerShare: dps,
                                  currentPrice: priceValue,
                                  frequency: frequency,
                                  payCycle: payCycle,
                                  payDayOfMonth: payDay,
                                  sector: sector,
                                  account: resolvedAccount.isEmpty ? nil : resolvedAccount)
            context.insert(holding)
        case .edit(let h):
            h.ticker = cleanTicker
            h.name = resolvedName
            h.shares = shares
            h.avgCostPerShare = cost
            h.annualDividendPerShare = dps
            h.currentPrice = priceValue
            h.frequency = frequency
            h.payCycle = payCycle
            h.payDayOfMonth = payDay
            h.sector = sector
            h.account = resolvedAccount.isEmpty ? nil : resolvedAccount
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    /// Parse a locale-tolerant decimal string. Returns nil on empty/invalid input.
    static func parse(_ raw: String) -> Decimal? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Accept both "," and "." as decimal separators; strip grouping spaces.
        let normalized = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }
}
