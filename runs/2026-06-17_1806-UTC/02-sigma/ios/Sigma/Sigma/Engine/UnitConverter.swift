import Foundation

/// A single unit within a category.
struct ConvUnit: Identifiable, Hashable {
    let symbol: String   // short label, e.g. "km"
    let name: String     // full name, e.g. "Kilometer"
    /// Multiplicative factor to the category's base unit. Unused for temperature.
    let factor: Double
    var id: String { symbol }
}

/// A conversion category (Length, Mass, …) holding its unit table.
struct ConvCategory: Identifiable, Hashable {
    let name: String
    let systemImage: String
    let units: [ConvUnit]
    /// True for the temperature category, which uses affine (not factor) conversion.
    let isTemperature: Bool
    var id: String { name }
}

/// Pure unit-conversion engine with factor tables plus an affine temperature case.
/// All divisions are guarded.
enum UnitConverter {

    static let categories: [ConvCategory] = [
        ConvCategory(name: "Length", systemImage: "ruler", isTemperature: false, units: [
            ConvUnit(symbol: "mm", name: "Millimeter", factor: 0.001),
            ConvUnit(symbol: "cm", name: "Centimeter", factor: 0.01),
            ConvUnit(symbol: "m",  name: "Meter",      factor: 1),
            ConvUnit(symbol: "km", name: "Kilometer",  factor: 1000),
            ConvUnit(symbol: "in", name: "Inch",       factor: 0.0254),
            ConvUnit(symbol: "ft", name: "Foot",       factor: 0.3048),
            ConvUnit(symbol: "yd", name: "Yard",       factor: 0.9144),
            ConvUnit(symbol: "mi", name: "Mile",       factor: 1609.344),
            ConvUnit(symbol: "nmi", name: "Nautical Mile", factor: 1852)
        ]),
        ConvCategory(name: "Mass", systemImage: "scalemass", isTemperature: false, units: [
            ConvUnit(symbol: "mg", name: "Milligram", factor: 0.000001),
            ConvUnit(symbol: "g",  name: "Gram",      factor: 0.001),
            ConvUnit(symbol: "kg", name: "Kilogram",  factor: 1),
            ConvUnit(symbol: "t",  name: "Tonne",     factor: 1000),
            ConvUnit(symbol: "oz", name: "Ounce",     factor: 0.0283495),
            ConvUnit(symbol: "lb", name: "Pound",     factor: 0.453592),
            ConvUnit(symbol: "st", name: "Stone",     factor: 6.35029)
        ]),
        ConvCategory(name: "Temperature", systemImage: "thermometer", isTemperature: true, units: [
            ConvUnit(symbol: "°C", name: "Celsius",    factor: 1),
            ConvUnit(symbol: "°F", name: "Fahrenheit", factor: 1),
            ConvUnit(symbol: "K",  name: "Kelvin",     factor: 1)
        ]),
        ConvCategory(name: "Volume", systemImage: "drop", isTemperature: false, units: [
            ConvUnit(symbol: "mL",  name: "Milliliter", factor: 0.001),
            ConvUnit(symbol: "L",   name: "Liter",      factor: 1),
            ConvUnit(symbol: "m³",  name: "Cubic Meter", factor: 1000),
            ConvUnit(symbol: "tsp", name: "Teaspoon",   factor: 0.00492892),
            ConvUnit(symbol: "tbsp", name: "Tablespoon", factor: 0.0147868),
            ConvUnit(symbol: "cup", name: "Cup",        factor: 0.24),
            ConvUnit(symbol: "pt",  name: "Pint (US)",  factor: 0.473176),
            ConvUnit(symbol: "gal", name: "Gallon (US)", factor: 3.78541)
        ]),
        ConvCategory(name: "Area", systemImage: "square.dashed", isTemperature: false, units: [
            ConvUnit(symbol: "cm²", name: "Sq Centimeter", factor: 0.0001),
            ConvUnit(symbol: "m²",  name: "Sq Meter",      factor: 1),
            ConvUnit(symbol: "ha",  name: "Hectare",       factor: 10000),
            ConvUnit(symbol: "km²", name: "Sq Kilometer",  factor: 1000000),
            ConvUnit(symbol: "ft²", name: "Sq Foot",       factor: 0.092903),
            ConvUnit(symbol: "ac",  name: "Acre",          factor: 4046.86),
            ConvUnit(symbol: "mi²", name: "Sq Mile",       factor: 2589988.11)
        ]),
        ConvCategory(name: "Speed", systemImage: "speedometer", isTemperature: false, units: [
            ConvUnit(symbol: "m/s",  name: "Meter / Second", factor: 1),
            ConvUnit(symbol: "km/h", name: "Kilometer / Hour", factor: 0.277778),
            ConvUnit(symbol: "mph",  name: "Mile / Hour",    factor: 0.44704),
            ConvUnit(symbol: "kn",   name: "Knot",           factor: 0.514444),
            ConvUnit(symbol: "ft/s", name: "Foot / Second",  factor: 0.3048)
        ]),
        ConvCategory(name: "Time", systemImage: "clock", isTemperature: false, units: [
            ConvUnit(symbol: "ms",  name: "Millisecond", factor: 0.001),
            ConvUnit(symbol: "s",   name: "Second",      factor: 1),
            ConvUnit(symbol: "min", name: "Minute",      factor: 60),
            ConvUnit(symbol: "h",   name: "Hour",        factor: 3600),
            ConvUnit(symbol: "d",   name: "Day",         factor: 86400),
            ConvUnit(symbol: "wk",  name: "Week",        factor: 604800),
            ConvUnit(symbol: "yr",  name: "Year",        factor: 31557600)
        ]),
        ConvCategory(name: "Storage", systemImage: "externaldrive", isTemperature: false, units: [
            ConvUnit(symbol: "bit", name: "Bit",      factor: 0.125),
            ConvUnit(symbol: "B",   name: "Byte",     factor: 1),
            ConvUnit(symbol: "KB",  name: "Kilobyte", factor: 1000),
            ConvUnit(symbol: "MB",  name: "Megabyte", factor: 1000000),
            ConvUnit(symbol: "GB",  name: "Gigabyte", factor: 1000000000),
            ConvUnit(symbol: "TB",  name: "Terabyte", factor: 1000000000000),
            ConvUnit(symbol: "KiB", name: "Kibibyte", factor: 1024),
            ConvUnit(symbol: "MiB", name: "Mebibyte", factor: 1048576),
            ConvUnit(symbol: "GiB", name: "Gibibyte", factor: 1073741824)
        ]),
        ConvCategory(name: "Energy", systemImage: "bolt", isTemperature: false, units: [
            ConvUnit(symbol: "J",    name: "Joule",        factor: 1),
            ConvUnit(symbol: "kJ",   name: "Kilojoule",    factor: 1000),
            ConvUnit(symbol: "cal",  name: "Calorie",      factor: 4.184),
            ConvUnit(symbol: "kcal", name: "Kilocalorie",  factor: 4184),
            ConvUnit(symbol: "Wh",   name: "Watt-hour",    factor: 3600),
            ConvUnit(symbol: "kWh",  name: "Kilowatt-hour", factor: 3600000),
            ConvUnit(symbol: "eV",   name: "Electronvolt", factor: 1.602176634e-19),
            ConvUnit(symbol: "BTU",  name: "BTU",          factor: 1055.06)
        ])
    ]

    static func category(named name: String) -> ConvCategory {
        categories.first { $0.name == name } ?? categories[0]
    }

    /// Converts a value from one unit to another within the same category.
    static func convert(_ value: Double, from: ConvUnit, to: ConvUnit, isTemperature: Bool) -> Double {
        guard value.isFinite else { return .nan }
        if isTemperature {
            let celsius = toCelsius(value, from: from.symbol)
            return fromCelsius(celsius, to: to.symbol)
        }
        guard to.factor != 0 else { return .nan }
        let base = value * from.factor
        return base / to.factor
    }

    // MARK: Temperature (affine)

    private static func toCelsius(_ value: Double, from symbol: String) -> Double {
        switch symbol {
        case "°F": return (value - 32) * 5 / 9
        case "K":  return value - 273.15
        default:   return value // °C
        }
    }

    private static func fromCelsius(_ celsius: Double, to symbol: String) -> Double {
        switch symbol {
        case "°F": return celsius * 9 / 5 + 32
        case "K":  return celsius + 273.15
        default:   return celsius // °C
        }
    }
}
