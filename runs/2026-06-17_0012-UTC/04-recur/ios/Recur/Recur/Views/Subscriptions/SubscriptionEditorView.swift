import SwiftUI
import SwiftData

enum EditorMode {
    case create
    case edit(Subscription)
}

/// Draft holds editable values; an @Observable view model owns it.
@Observable
final class EditorModel {
    var name: String = ""
    var costText: String = ""
    var currencyCode: String
    var cycle: BillingCycle
    var customDaysText: String = "30"
    var firstBillingDate: Date = Date()
    var category: SubCategory = .other
    var colorHex: String = SubCategory.other.defaultHex
    var iconName: String = SubCategory.other.symbol
    var isTrial: Bool = false
    var trialEndDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var paymentMethod: String = ""
    var notes: String = ""

    init(defaultCurrency: String, defaultCycle: BillingCycle) {
        self.currencyCode = defaultCurrency
        self.cycle = defaultCycle
    }

    /// Loads values from an existing subscription for editing.
    func load(from sub: Subscription) {
        name = sub.name
        costText = String(format: "%.2f", sub.costAmount)
        currencyCode = sub.currencyCode
        cycle = sub.cycle
        if case let .customDays(d) = sub.cycle { customDaysText = String(d) }
        firstBillingDate = sub.firstBillingDate
        category = sub.category
        colorHex = sub.colorHex
        iconName = sub.iconName
        isTrial = sub.isTrial
        if let end = sub.trialEndDate { trialEndDate = end }
        paymentMethod = sub.paymentMethod
        notes = sub.notes
    }

    // MARK: - Validation

    /// Parsed, non-negative cost or nil when invalid.
    var parsedCost: Decimal? {
        let cleaned = costText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: cleaned), value >= 0 else { return nil }
        return value
    }

    var parsedCustomDays: Int {
        max(1, Int(customDaysText.trimmingCharacters(in: .whitespaces)) ?? 30)
    }

    /// The effective cycle (resolves custom days from the text field).
    var effectiveCycle: BillingCycle {
        if case .customDays = cycle { return .customDays(parsedCustomDays) }
        return cycle
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isValid: Bool {
        !trimmedName.isEmpty && parsedCost != nil
    }

    var validationMessage: String? {
        if trimmedName.isEmpty { return "Please enter a name." }
        if parsedCost == nil { return "Enter a valid, non-negative cost." }
        return nil
    }
}

struct SubscriptionEditorView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PrefKey.currencyCode) private var defaultCurrency: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.defaultCycle) private var defaultCycleToken: String = PrefDefault.defaultCycle
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    let mode: EditorMode
    @State private var model: EditorModel
    @State private var showColorPicker = false
    @State private var showIconPicker = false
    @State private var showPaywall = false

    @Query private var allSubscriptions: [Subscription]

    init(mode: EditorMode) {
        self.mode = mode
        // Seed the model with app defaults; overwritten in onAppear for edit mode.
        let cycle = BillingCycle.from(token: UserDefaults.standard.string(forKey: PrefKey.defaultCycle) ?? PrefDefault.defaultCycle, customDays: 30)
        let currency = UserDefaults.standard.string(forKey: PrefKey.currencyCode) ?? PrefDefault.currencyCode
        _model = State(initialValue: EditorModel(defaultCurrency: currency, defaultCycle: cycle))
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var activeCount: Int {
        allSubscriptions.filter { $0.isActive }.count
    }

    /// Free users are blocked from creating a 9th active subscription.
    private var hitFreeLimit: Bool {
        !isPro && !isEditing && activeCount >= FreeTier.maxSubscriptions
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                Form {
                    if hitFreeLimit { freeLimitSection }
                    detailsSection
                    cycleSection
                    appearanceSection
                    trialSection
                    extrasSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Subscription" : "New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!model.isValid || hitFreeLimit)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: configureForMode)
            .onChange(of: model.category) { _, newValue in
                // Update color/icon to the category default unless user customized.
                model.colorHex = newValue.defaultHex
                model.iconName = newValue.symbol
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(selectedHex: $model.colorHex)
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerSheet(selectedIcon: $model.iconName)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func configureForMode() {
        if case let .edit(sub) = mode {
            model.load(from: sub)
        }
    }

    // MARK: - Sections

    private var freeLimitSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("Free limit reached", systemImage: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RecurTheme.violet)
                Text("Recur free tracks up to \(FreeTier.maxSubscriptions) active subscriptions. Unlock Recur Pro for unlimited tracking.")
                    .font(.caption)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                Button("Unlock Recur Pro") { showPaywall = true }
                    .buttonStyle(RecurPrimaryButtonStyle())
            }
            .padding(.vertical, 4)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name (e.g. Netflix)", text: $model.name)
                .textInputAutocapitalization(.words)
            HStack {
                Text(MoneyFormatter.symbol(for: model.currencyCode))
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                TextField("0.00", text: $model.costText)
                    .keyboardType(.decimalPad)
                Picker("", selection: $model.currencyCode) {
                    ForEach(MoneyFormatter.currencyOptions, id: \.code) { opt in
                        Text(opt.code).tag(opt.code)
                    }
                }
                .labelsHidden()
            }
            Picker("Category", selection: $model.category) {
                ForEach(SubCategory.allCases) { cat in
                    Label(cat.label, systemImage: cat.symbol).tag(cat)
                }
            }
        }
    }

    private var cycleSection: some View {
        Section("Billing cycle") {
            Picker("Repeats", selection: Binding(
                get: { isCustom ? "custom" : model.cycle.token },
                set: { token in
                    if token == "custom" {
                        model.cycle = .customDays(model.parsedCustomDays)
                    } else {
                        model.cycle = BillingCycle.from(token: token, customDays: model.parsedCustomDays)
                    }
                })) {
                ForEach(BillingCycle.standardCases) { c in
                    Text(c.label).tag(c.token)
                }
                Text("Custom").tag("custom")
            }
            if isCustom {
                HStack {
                    Text("Every")
                    TextField("30", text: $model.customDaysText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("days")
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                }
            }
            DatePicker("First billing date", selection: $model.firstBillingDate, displayedComponents: .date)
        }
    }

    private var isCustom: Bool {
        if case .customDays = model.cycle { return true }
        return false
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Button { showColorPicker = true } label: {
                HStack {
                    Text("Color").foregroundStyle(RecurTheme.primaryText(scheme))
                    Spacer()
                    Circle().fill(Color(hex: model.colorHex)).frame(width: 24, height: 24)
                }
            }
            Button { showIconPicker = true } label: {
                HStack {
                    Text("Icon").foregroundStyle(RecurTheme.primaryText(scheme))
                    Spacer()
                    Image(systemName: model.iconName)
                        .foregroundStyle(Color(hex: model.colorHex))
                        .font(.title3)
                }
            }
        }
    }

    private var trialSection: some View {
        Section("Free trial") {
            Toggle("This is a free trial", isOn: $model.isTrial)
                .tint(RecurTheme.violet)
            if model.isTrial {
                DatePicker("Trial ends", selection: $model.trialEndDate, displayedComponents: .date)
            }
        }
    }

    private var extrasSection: some View {
        Section("Notes") {
            TextField("Payment method (e.g. Visa •• 4242)", text: $model.paymentMethod)
            TextField("Notes", text: $model.notes, axis: .vertical)
                .lineLimit(2...5)
            if let msg = model.validationMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(RecurTheme.coral)
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let cost = model.parsedCost else { return }
        let costDouble = NSDecimalNumber(decimal: cost).doubleValue

        switch mode {
        case .create:
            guard !hitFreeLimit else { showPaywall = true; return }
            let sub = Subscription(
                name: model.trimmedName,
                costAmount: costDouble,
                currencyCode: model.currencyCode,
                cycle: model.effectiveCycle,
                firstBillingDate: model.firstBillingDate,
                category: model.category,
                colorHex: model.colorHex,
                iconName: model.iconName,
                isTrial: model.isTrial,
                trialEndDate: model.isTrial ? model.trialEndDate : nil,
                paymentMethod: model.paymentMethod,
                notes: model.notes
            )
            modelContext.insert(sub)
        case .edit(let sub):
            // Log a price change if the cost actually changed.
            if abs(sub.costAmount - costDouble) > 0.0001 {
                let change = PriceChange(oldAmount: sub.costAmount, newAmount: costDouble, subscription: sub)
                modelContext.insert(change)
            }
            sub.name = model.trimmedName
            sub.costAmount = costDouble
            sub.currencyCode = model.currencyCode
            let ec = model.effectiveCycle
            sub.cycleRaw = ec.token
            if case let .customDays(d) = ec { sub.customDays = d }
            sub.firstBillingDate = model.firstBillingDate
            sub.categoryRaw = model.category.rawValue
            sub.colorHex = model.colorHex
            sub.iconName = model.iconName
            sub.isTrial = model.isTrial
            sub.trialEndDate = model.isTrial ? model.trialEndDate : nil
            sub.paymentMethod = model.paymentMethod
            sub.notes = model.notes
        }
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}
