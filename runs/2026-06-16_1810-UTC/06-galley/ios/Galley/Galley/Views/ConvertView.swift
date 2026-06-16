import SwiftUI

/// Ingredient choice for a conversion: a specific library ingredient,
/// or a "generic" mode where no density is available.
private enum IngredientChoice: Hashable {
    case generic
    case ingredient(id: String)

    var label: String {
        switch self {
        case .generic: return "Generic (no ingredient)"
        case .ingredient(let id): return IngredientLibrary.ingredient(id: id)?.name ?? "Ingredient"
        }
    }

    var gramsPerCup: Double? {
        switch self {
        case .generic: return nil
        case .ingredient(let id): return IngredientLibrary.ingredient(id: id)?.gramsPerCup
        }
    }
}

private struct RecentConversion: Identifiable {
    let id = UUID()
    let summary: String
    let resultValue: String
}

struct ConvertView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.useFractions) private var useFractions: Bool = true
    @AppStorage(PrefKey.lastIngredientID) private var lastIngredientID: String = ""
    @AppStorage(PrefKey.measurementSystem) private var measurementSystemRaw: String = MeasurementSystem.us.rawValue

    @State private var amountText: String = "1"
    @State private var fromUnit: MeasureUnit = .cup
    @State private var toUnit: MeasureUnit = .gram
    @State private var choice: IngredientChoice = .generic
    @State private var showingSettings = false
    @State private var showingIngredientPicker = false
    @State private var recents: [RecentConversion] = []
    @State private var didApplyDefaults = false

    private var measurementSystem: MeasurementSystem {
        MeasurementSystem(rawValue: measurementSystemRaw) ?? .us
    }

    private var amount: Double? {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Accept simple fraction entry like "1/2".
        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/")
            if parts.count == 2,
               let n = Double(parts[0]), let d = Double(parts[1]), d != 0 {
                return n / d
            }
            return nil
        }
        return Double(trimmed)
    }

    private var result: ConversionResult {
        guard let amount else { return .invalid(reason: "Enter an amount to convert.") }
        return ConversionEngine.convert(
            amount: amount,
            from: fromUnit,
            to: toUnit,
            gramsPerCup: choice.gramsPerCup
        )
    }

    private var crossTypeNeedsIngredient: Bool {
        ConversionEngine.requiresIngredient(from: fromUnit, to: toUnit)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        ingredientCard
                        inputCard
                        resultCard
                        quickPicks
                        if !recents.isEmpty { recentsCard }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Convert")
            .toolbar { settingsToolbar($showingSettings) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingIngredientPicker) {
                IngredientPickerSheet(selectedID: bindingSelectedID)
            }
            .onAppear(perform: restoreLastIngredient)
        }
    }

    // MARK: - Cards

    private var ingredientCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Ingredient")
                Button {
                    showingIngredientPicker = true
                } label: {
                    HStack {
                        Image(systemName: choice == .generic ? "circle.dashed" : "leaf.fill")
                            .foregroundStyle(GalleyTheme.sageDeep)
                            .accessibilityHidden(true)
                        Text(choice.label)
                            .foregroundStyle(GalleyTheme.primaryText(scheme))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Ingredient: \(choice.label)")
                .accessibilityHint("Choose an ingredient for volume to weight conversions")

                if crossTypeNeedsIngredient && choice == .generic {
                    Label("Pick an ingredient to convert between volume and weight.",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(GalleyTheme.terracottaDeep)
                }
            }
        }
    }

    private var inputCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Amount")
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(GalleyTheme.primaryText(scheme))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GalleyTheme.subtleSurface(scheme))
                    )
                    .accessibilityLabel("Amount to convert")

                HStack(spacing: 12) {
                    unitMenu(title: "From", selection: $fromUnit)
                    Button(action: swap) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(GalleyTheme.sage))
                    }
                    .accessibilityLabel("Swap from and to units")
                    unitMenu(title: "To", selection: $toUnit)
                }
            }
        }
    }

    private var resultCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Result")
                resultContent
            }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        switch result {
        case .success(let value):
            let text = FractionFormatter.string(value, useFractions: useFractions)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(text)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(GalleyTheme.terracotta)
                Text(toUnit.abbreviation)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityResult(text))
            Button {
                addRecent(resultText: text)
            } label: {
                Label("Save to recent", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline)
            }
            .buttonStyle(GalleySecondaryButtonStyle())
            .padding(.top, 4)

        case .needsIngredient:
            calmMessage(
                symbol: "leaf",
                title: "Choose an ingredient",
                message: "Volume-to-weight needs an ingredient's density. Tap the ingredient field above."
            )
        case .invalid(let reason):
            calmMessage(symbol: "exclamationmark.circle", title: "Can't convert yet", message: reason)
        }
    }

    private func calmMessage(symbol: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(GalleyTheme.sageDeep)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(GalleyTheme.primaryText(scheme))
                Text(message).font(.subheadline).foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var quickPicks: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Quick conversions")
                ForEach(quickPickData, id: \.label) { pick in
                    Button {
                        fromUnit = pick.from
                        toUnit = pick.to
                        amountText = pick.amount
                        if let id = pick.ingredientID { choice = .ingredient(id: id); lastIngredientID = id }
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.footnote)
                                .foregroundStyle(GalleyTheme.terracotta)
                                .accessibilityHidden(true)
                            Text(pick.label)
                                .foregroundStyle(GalleyTheme.primaryText(scheme))
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                    if pick.label != quickPickData.last?.label {
                        Divider().background(GalleyTheme.hairline(scheme))
                    }
                }
            }
        }
    }

    private var recentsCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel(text: "Recent")
                    Spacer()
                    Button("Clear") { recents.removeAll() }
                        .font(.caption)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                }
                ForEach(recents) { r in
                    HStack {
                        Text(r.summary)
                            .font(.subheadline)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        Spacer()
                        Text(r.resultValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GalleyTheme.primaryText(scheme))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Helpers

    private func unitMenu(title: String, selection: Binding<MeasureUnit>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
            Menu {
                Section("Volume") {
                    ForEach(MeasureUnit.volumeUnits) { u in
                        Button(u.fullName) { selection.wrappedValue = u }
                    }
                }
                Section("Weight") {
                    ForEach(MeasureUnit.weightUnits) { u in
                        Button(u.fullName) { selection.wrappedValue = u }
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.abbreviation)
                        .foregroundStyle(GalleyTheme.primaryText(scheme))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GalleyTheme.subtleSurface(scheme))
                )
            }
            .accessibilityLabel("\(title) unit, \(selection.wrappedValue.fullName)")
        }
    }

    private func swap() {
        let old = fromUnit
        fromUnit = toUnit
        toUnit = old
        Haptics.light()
    }

    private func accessibilityResult(_ text: String) -> String {
        let from = amountText.isEmpty ? "the amount" : amountText
        return "\(from) \(fromUnit.fullName) equals \(text) \(toUnit.fullName)"
    }

    private func addRecent(resultText: String) {
        let summary = "\(amountText) \(fromUnit.abbreviation) → \(toUnit.abbreviation)"
        let entry = RecentConversion(summary: summary, resultValue: "\(resultText) \(toUnit.abbreviation)")
        recents.insert(entry, at: 0)
        if recents.count > 6 { recents.removeLast(recents.count - 6) }
        Haptics.light()
    }

    private var bindingSelectedID: Binding<String> {
        Binding(
            get: {
                if case .ingredient(let id) = choice { return id }
                return ""
            },
            set: { newID in
                if newID.isEmpty { choice = .generic }
                else { choice = .ingredient(id: newID); lastIngredientID = newID }
            }
        )
    }

    private func restoreLastIngredient() {
        // Apply the user's default measurement system to the starting "from"
        // unit, once per appearance of a fresh view.
        if !didApplyDefaults {
            didApplyDefaults = true
            fromUnit = measurementSystem.defaultVolumeUnit
            if measurementSystem == .metric { toUnit = .gram }
        }
        guard choice == .generic, !lastIngredientID.isEmpty,
              IngredientLibrary.ingredient(id: lastIngredientID) != nil else { return }
        choice = .ingredient(id: lastIngredientID)
    }

    private struct QuickPick {
        let label: String
        let amount: String
        let from: MeasureUnit
        let to: MeasureUnit
        let ingredientID: String?
    }

    private var quickPickData: [QuickPick] {
        [
            .init(label: "1 cup flour → grams", amount: "1", from: .cup, to: .gram, ingredientID: "all-purpose flour"),
            .init(label: "1 cup sugar → grams", amount: "1", from: .cup, to: .gram, ingredientID: "granulated sugar"),
            .init(label: "1 cup butter → grams", amount: "1", from: .cup, to: .gram, ingredientID: "butter"),
            .init(label: "1 cup → tablespoons", amount: "1", from: .cup, to: .tablespoon, ingredientID: nil),
            .init(label: "1 tablespoon → teaspoons", amount: "1", from: .tablespoon, to: .teaspoon, ingredientID: nil),
            .init(label: "250 ml → cups", amount: "250", from: .milliliter, to: .cup, ingredientID: nil)
        ]
    }
}

// MARK: - Ingredient picker sheet

struct IngredientPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Binding var selectedID: String
    @State private var search = ""

    private var grouped: [(category: IngredientDensity.Category, items: [IngredientDensity])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return IngredientLibrary.grouped().compactMap { group in
            let items = q.isEmpty ? group.items : group.items.filter { $0.name.lowercased().contains(q) }
            return items.isEmpty ? nil : (group.category, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedID = ""
                    dismiss()
                } label: {
                    Label("Generic (no ingredient)", systemImage: "circle.dashed")
                }

                if grouped.isEmpty {
                    ContentUnavailableView.search(text: search)
                }

                ForEach(grouped, id: \.category.id) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.items) { ing in
                            Button {
                                selectedID = ing.id
                                dismiss()
                            } label: {
                                HStack {
                                    Text(ing.name)
                                        .foregroundStyle(GalleyTheme.primaryText(scheme))
                                    Spacer()
                                    Text("\(Int(ing.gramsPerCup)) g/cup")
                                        .font(.caption)
                                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                                    if ing.id == selectedID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(GalleyTheme.terracotta)
                                    }
                                }
                            }
                            .accessibilityLabel("\(ing.name), \(Int(ing.gramsPerCup)) grams per cup")
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search ingredients")
            .navigationTitle("Choose Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Shared settings toolbar

@ToolbarContentBuilder
func settingsToolbar(_ isPresented: Binding<Bool>) -> some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            isPresented.wrappedValue = true
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
    }
}
