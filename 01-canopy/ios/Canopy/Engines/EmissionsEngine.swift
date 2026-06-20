import Foundation

struct Activity: Identifiable {
    let id: String
    let name: String
    let category: EmissionCategory
    let unit: String
    let kgCO2ePerUnit: Double
    let tip: String
}

struct EmissionsEngine {

    static let worldAverageWeeklyKg: Double = 192.3
    static let targetWeeklyKg: Double = 96.2

    static let catalog: [Activity] = [
        // Transport
        Activity(id: "car_petrol",    name: "Petrol Car",      category: .transport, unit: "km",   kgCO2ePerUnit: 0.21,  tip: "Carpooling halves your per-person emissions."),
        Activity(id: "car_diesel",    name: "Diesel Car",      category: .transport, unit: "km",   kgCO2ePerUnit: 0.17,  tip: "Modern diesel is cleaner per km but still significant."),
        Activity(id: "car_electric",  name: "Electric Car",    category: .transport, unit: "km",   kgCO2ePerUnit: 0.07,  tip: "On green energy, EVs can be near-zero."),
        Activity(id: "flight_short",  name: "Short-Haul Flight",category: .transport, unit: "km",  kgCO2ePerUnit: 0.255, tip: "Train alternatives for under 1,000 km save ~90%."),
        Activity(id: "flight_long",   name: "Long-Haul Flight", category: .transport, unit: "km",  kgCO2ePerUnit: 0.195, tip: "One long flight can equal weeks of other emissions."),
        Activity(id: "train",         name: "Train",           category: .transport, unit: "km",   kgCO2ePerUnit: 0.041, tip: "Rail is 6× cleaner than flying the same route."),
        Activity(id: "bus",           name: "Bus",             category: .transport, unit: "km",   kgCO2ePerUnit: 0.089, tip: "Full buses are among the most efficient city transport."),
        Activity(id: "motorbike",     name: "Motorbike",       category: .transport, unit: "km",   kgCO2ePerUnit: 0.14,  tip: "Motorbikes emit more per km than most assume."),
        Activity(id: "cycling",       name: "Cycling / Walking",category: .transport, unit: "km",  kgCO2ePerUnit: 0.0,   tip: "Zero direct emissions — the gold standard."),

        // Food
        Activity(id: "beef",          name: "Beef",            category: .food,      unit: "kg",   kgCO2ePerUnit: 27.0,  tip: "Swapping one beef meal/week saves ~1.4 t CO₂e/yr."),
        Activity(id: "lamb",          name: "Lamb",            category: .food,      unit: "kg",   kgCO2ePerUnit: 39.2,  tip: "Lamb has the highest footprint of any common meat."),
        Activity(id: "pork",          name: "Pork",            category: .food,      unit: "kg",   kgCO2ePerUnit: 7.6,   tip: "Pork emits ~4× less than beef."),
        Activity(id: "chicken",       name: "Chicken",         category: .food,      unit: "kg",   kgCO2ePerUnit: 6.9,   tip: "Poultry is the lowest-impact meat."),
        Activity(id: "fish",          name: "Fish & Seafood",  category: .food,      unit: "kg",   kgCO2ePerUnit: 5.4,   tip: "Smaller fish and shellfish tend to be lower impact."),
        Activity(id: "dairy",         name: "Dairy",           category: .food,      unit: "kg",   kgCO2ePerUnit: 3.2,   tip: "Plant-based milks emit 3× less than cow's milk."),
        Activity(id: "eggs",          name: "Eggs",            category: .food,      unit: "kg",   kgCO2ePerUnit: 4.5,   tip: "Eggs are a relatively low-carbon animal protein."),
        Activity(id: "vegetables",    name: "Vegetables",      category: .food,      unit: "kg",   kgCO2ePerUnit: 2.0,   tip: "Seasonal, local veg can be even lower impact."),
        Activity(id: "plant_protein", name: "Plant Protein",   category: .food,      unit: "kg",   kgCO2ePerUnit: 2.0,   tip: "Legumes fix nitrogen, reducing fertiliser needs."),
        Activity(id: "coffee",        name: "Coffee",          category: .food,      unit: "kg",   kgCO2ePerUnit: 17.0,  tip: "Shade-grown, certified coffee has a lower footprint."),

        // Energy
        Activity(id: "electricity",   name: "Electricity",     category: .energy,    unit: "kWh",  kgCO2ePerUnit: 0.233, tip: "Switching to renewable tariff cuts this to near zero."),
        Activity(id: "natural_gas",   name: "Natural Gas",     category: .energy,    unit: "kWh",  kgCO2ePerUnit: 0.203, tip: "Heat pumps use ~3× less energy than gas boilers."),
        Activity(id: "heating_oil",   name: "Heating Oil",     category: .energy,    unit: "L",    kgCO2ePerUnit: 2.52,  tip: "Oil heating is the most carbon-intensive home fuel."),
        Activity(id: "solar",         name: "Solar Generation",category: .energy,    unit: "kWh",  kgCO2ePerUnit: 0.05,  tip: "Solar panels pay back their carbon in under 2 years."),

        // Shopping
        Activity(id: "clothing",      name: "Clothing",        category: .shopping,  unit: "item", kgCO2ePerUnit: 33.0,  tip: "Buying second-hand cuts garment footprint by ~70%."),
        Activity(id: "smartphone",    name: "Smartphone",      category: .shopping,  unit: "item", kgCO2ePerUnit: 70.0,  tip: "Extending phone life by 1 year saves ~70 kg CO₂e."),
        Activity(id: "laptop",        name: "Laptop",          category: .shopping,  unit: "item", kgCO2ePerUnit: 300.0, tip: "Refurbished laptops save ~80% of manufacturing emissions."),
        Activity(id: "tv",            name: "Television",      category: .shopping,  unit: "item", kgCO2ePerUnit: 400.0, tip: "OLED TVs use less energy than older plasma screens."),
        Activity(id: "furniture",     name: "Furniture",       category: .shopping,  unit: "item", kgCO2ePerUnit: 50.0,  tip: "Solid wood from certified forests is more sustainable."),

        // Waste
        Activity(id: "landfill",      name: "Landfill Waste",  category: .waste,     unit: "kg",   kgCO2ePerUnit: 0.57,  tip: "Reducing food waste is the single best waste action."),
        Activity(id: "recycled",      name: "Recycled Waste",  category: .waste,     unit: "kg",   kgCO2ePerUnit: 0.02,  tip: "Clean sorting improves recycling rates significantly."),
        Activity(id: "composted",     name: "Composted Waste", category: .waste,     unit: "kg",   kgCO2ePerUnit: 0.01,  tip: "Home composting also enriches soil and offsets fertiliser.")
    ]

    static func activity(for key: String) -> Activity? {
        catalog.first { $0.id == key }
    }

    static func activities(in category: EmissionCategory) -> [Activity] {
        catalog.filter { $0.category == category }
    }

    static func co2e(activityKey: String, amount: Double) -> Double {
        guard let act = activity(for: activityKey) else { return 0 }
        return act.kgCO2ePerUnit * amount
    }
}
