import SwiftUI

/// Unit converter across nine categories with a live "all units" breakdown.
struct ConverterView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var category = UnitConverter.categories[0]
    @State private var fromUnit = UnitConverter.categories[0].units[0]
    @State private var toUnit = UnitConverter.categories[0].units[1]
    @State private var inputText = "1"
    @State private var allRows: [(unit: ConvUnit, value: Double)] = []
    @State private var isComputing = false
    @State private var showCopied = false

    private var accent: Color { settings.activeTheme(isPro: pro.isPro).accent }

    private var inputValue: Double {
        Double(inputText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var resultValue: Double {
        UnitConverter.convert(inputValue, from: fromUnit, to: toUnit, isTemperature: category.isTemperature)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ConverterCategoryStrip(categories: UnitConverter.categories,
                                               selected: category,
                                               accent: accent,
                                               onSelect: selectCategory)
                        conversionCard
                        AllUnitsCard(title: "\(formatted(inputValue)) \(fromUnit.symbol) in all \(category.name.lowercased()) units",
                                     rows: allRows,
                                     highlightUnitID: toUnit.id,
                                     isComputing: isComputing,
                                     accent: accent,
                                     format: formatted)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Convert")
            .toast(isPresented: $showCopied, message: "Copied")
        }
        .onAppear(perform: restoreSelection)
        .onChange(of: inputText) { _, _ in recompute() }
        .onChange(of: category) { _, _ in recompute() }
        .onChange(of: fromUnit) { _, _ in recompute() }
        .onChange(of: toUnit) { _, _ in recompute() }
    }

    // MARK: Conversion card

    private var conversionCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Value")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            TextField("0", text: $inputText)
                .keyboardType(.numbersAndPunctuation)
                .font(Theme.rounded(34, .medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Input value")

            unitRow(title: "From", selection: $fromUnit)
            swapButton
            unitRow(title: "To", selection: $toUnit)

            Divider().overlay(Theme.hairline)

            Button(action: copyResult) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Result")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text("\(formatted(resultValue)) \(toUnit.symbol)")
                        .font(Theme.rounded(30, .bold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Result \(formatted(resultValue)) \(toUnit.name)")
            .accessibilityHint("Double tap to copy")
        }
        .card()
    }

    private func unitRow(title: String, selection: Binding<ConvUnit>) -> some View {
        HStack {
            Text(title)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Menu {
                ForEach(category.units) { unit in
                    Button {
                        selection.wrappedValue = unit
                    } label: {
                        Text("\(unit.name) (\(unit.symbol))")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selection.wrappedValue.symbol)
                        .font(Theme.rounded(17, .semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(Theme.rounded(12, .semibold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.surfaceDeep))
            }
            .accessibilityLabel("\(title) unit, \(selection.wrappedValue.name)")
        }
    }

    private var swapButton: some View {
        Button {
            let temp = fromUnit
            fromUnit = toUnit
            toUnit = temp
            Haptics.selection(enabled: settings.hapticsEnabled)
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(accent)
        }
        .accessibilityLabel("Swap units")
    }

    // MARK: Logic

    private func selectCategory(_ cat: ConvCategory) {
        category = cat
        fromUnit = cat.units[0]
        toUnit = cat.units.count > 1 ? cat.units[1] : cat.units[0]
        Haptics.selection(enabled: settings.hapticsEnabled)
        persistSelection()
    }

    private func recompute() {
        persistSelection()
        Task {
            isComputing = true
            // A brief, perceptible compute pass (also satisfies the loading state).
            try? await Task.sleep(nanoseconds: 120_000_000)
            let value = inputValue
            let rows = category.units.map { unit in
                (unit: unit, value: UnitConverter.convert(value, from: fromUnit, to: unit, isTemperature: category.isTemperature))
            }
            allRows = rows
            isComputing = false
        }
    }

    private func persistSelection() {
        settings.converterCategory = category.name
        settings.converterFromUnit = fromUnit.symbol
        settings.converterToUnit = toUnit.symbol
    }

    private func restoreSelection() {
        let cat = UnitConverter.category(named: settings.converterCategory)
        category = cat
        fromUnit = cat.units.first { $0.symbol == settings.converterFromUnit } ?? cat.units[0]
        toUnit = cat.units.first { $0.symbol == settings.converterToUnit } ?? (cat.units.count > 1 ? cat.units[1] : cat.units[0])
        recompute()
    }

    private func formatted(_ value: Double) -> String {
        NumberFormatting.string(value, grouping: settings.groupingEnabled, places: settings.effectivePlaces, highPrecision: settings.highPrecision)
    }

    private func copyResult() {
        ClipboardService.copy(formatted(resultValue))
        Haptics.success(enabled: settings.hapticsEnabled)
        showCopied = true
    }
}
