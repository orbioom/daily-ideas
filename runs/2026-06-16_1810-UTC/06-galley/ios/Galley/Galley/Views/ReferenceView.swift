import SwiftUI

struct ReferenceView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.temperatureUnit) private var temperatureUnitRaw: String = TemperatureUnit.fahrenheit.rawValue
    @State private var showingSettings = false
    @State private var densitySearch = ""
    @State private var tempInput: String = ""
    @State private var didSeedTemp = false

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .fahrenheit
    }

    /// Converted temperature in the *other* unit, plus a gas mark when sensible.
    private var convertedTemp: (value: String, gas: String)? {
        let trimmed = tempInput.trimmingCharacters(in: .whitespaces)
        guard let input = Double(trimmed), input.isFinite else { return nil }
        switch temperatureUnit {
        case .fahrenheit:
            let c = TempEngine.fahrenheitToCelsius(input)
            let gas = TempEngine.gasMark(forCelsius: c).map { "gas \($0)" } ?? "—"
            return ("\(Int(c.rounded())) °C", gas)
        case .celsius:
            let f = TempEngine.celsiusToFahrenheit(input)
            let gas = TempEngine.gasMark(forCelsius: input).map { "gas \($0)" } ?? "—"
            return ("\(Int(f.rounded())) °F", gas)
        }
    }

    private var groupedDensities: [(category: IngredientDensity.Category, items: [IngredientDensity])] {
        let q = densitySearch.trimmingCharacters(in: .whitespaces).lowercased()
        return IngredientLibrary.grouped().compactMap { group in
            let items = q.isEmpty ? group.items : group.items.filter { $0.name.lowercased().contains(q) }
            return items.isEmpty ? nil : (group.category, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        tempConverterCard
                        equivalentsCard
                        ovenCard
                        densityCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Reference")
            .toolbar { settingsToolbar($showingSettings) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .onAppear {
                if !didSeedTemp {
                    didSeedTemp = true
                    tempInput = temperatureUnit == .fahrenheit ? "350" : "177"
                }
            }
        }
    }

    private var tempConverterCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Oven temperature converter")
                HStack {
                    TextField("Temp", text: $tempInput)
                        .keyboardType(.numbersAndPunctuation)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(GalleyTheme.primaryText(scheme))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(GalleyTheme.subtleSurface(scheme)))
                        .accessibilityLabel("Temperature in \(temperatureUnit.rawValue)")
                    Text(temperatureUnit.symbol)
                        .font(.headline)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                }
                if let result = convertedTemp {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(GalleyTheme.sage)
                            .accessibilityHidden(true)
                        Text(result.value)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(GalleyTheme.terracotta)
                        Text("·  \(result.gas)")
                            .font(.subheadline)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Equals \(result.value), \(result.gas)")
                } else {
                    Text("Enter a temperature to convert.")
                        .font(.subheadline)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                }
            }
        }
    }

    private var equivalentsCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Common equivalents")
                EquivalenceRow(left: "3 teaspoons", right: "1 tablespoon")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "16 tablespoons", right: "1 cup")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "4 tablespoons", right: "¼ cup")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "2 cups", right: "1 pint")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "2 pints", right: "1 quart")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "4 quarts", right: "1 gallon")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "1 fluid ounce", right: "2 tablespoons")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "1 stick butter", right: "½ cup · 8 tbsp · 113 g")
                Divider().background(GalleyTheme.hairline(scheme))
                EquivalenceRow(left: "1 cup", right: "≈ 237 ml")
            }
        }
    }

    private var ovenCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Oven temperatures")
                HStack {
                    Text("°F").frame(width: 52, alignment: .leading)
                    Text("°C").frame(width: 52, alignment: .leading)
                    Text("Gas").frame(width: 44, alignment: .leading)
                    Text("Description")
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                .accessibilityHidden(true)

                ForEach(TempEngine.ovenPresets) { preset in
                    HStack {
                        Text("\(preset.fahrenheit)").frame(width: 52, alignment: .leading)
                        Text("\(preset.celsius)").frame(width: 52, alignment: .leading)
                        Text("\(preset.gasMark)").frame(width: 44, alignment: .leading)
                        Text(preset.label)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(GalleyTheme.primaryText(scheme))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(preset.fahrenheit) Fahrenheit, \(preset.celsius) Celsius, gas mark \(preset.gasMark), \(preset.label)")
                    if preset.id != TempEngine.ovenPresets.last?.id {
                        Divider().background(GalleyTheme.hairline(scheme))
                    }
                }
            }
        }
    }

    private var densityCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Ingredient densities (grams per cup)")
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        .accessibilityHidden(true)
                    TextField("Filter ingredients", text: $densitySearch)
                        .accessibilityLabel("Filter ingredients")
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GalleyTheme.subtleSurface(scheme)))

                if groupedDensities.isEmpty {
                    Text("No ingredients match “\(densitySearch)”.")
                        .font(.subheadline)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        .padding(.vertical, 8)
                }

                ForEach(groupedDensities, id: \.category.id) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.category.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GalleyTheme.terracottaDeep)
                            .padding(.top, 4)
                        ForEach(group.items) { ing in
                            HStack {
                                Text(ing.name)
                                    .foregroundStyle(GalleyTheme.primaryText(scheme))
                                Spacer()
                                Text("\(Int(ing.gramsPerCup)) g")
                                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            }
                            .font(.subheadline)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(ing.name), \(Int(ing.gramsPerCup)) grams per cup")
                        }
                    }
                }
            }
        }
    }
}
