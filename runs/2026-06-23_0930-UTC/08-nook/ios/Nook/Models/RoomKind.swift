import Foundation

/// A room / area of the home. Drives the icon + default grouping.
enum RoomKind: String, CaseIterable, Codable, Identifiable {
    case kitchen
    case bathroom
    case livingRoom
    case bedroom
    case laundry
    case garage
    case basement
    case attic
    case exterior
    case yard
    case hallway
    case wholeHome
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kitchen:    return "Kitchen"
        case .bathroom:   return "Bathroom"
        case .livingRoom: return "Living Room"
        case .bedroom:    return "Bedroom"
        case .laundry:    return "Laundry"
        case .garage:     return "Garage"
        case .basement:   return "Basement"
        case .attic:      return "Attic"
        case .exterior:   return "Exterior"
        case .yard:       return "Yard & Garden"
        case .hallway:    return "Hallway"
        case .wholeHome:  return "Whole Home"
        case .other:      return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .kitchen:    return "fork.knife"
        case .bathroom:   return "shower"
        case .livingRoom: return "sofa"
        case .bedroom:    return "bed.double"
        case .laundry:    return "washer"
        case .garage:     return "car"
        case .basement:   return "stairs"
        case .attic:      return "house.lodge"
        case .exterior:   return "house"
        case .yard:       return "tree"
        case .hallway:    return "door.left.hand.open"
        case .wholeHome:  return "house.fill"
        case .other:      return "square.grid.2x2"
        }
    }
}

/// Equipment categories for appliances / systems.
enum ApplianceKind: String, CaseIterable, Codable, Identifiable {
    case hvac
    case waterHeater
    case refrigerator
    case dishwasher
    case washer
    case dryer
    case oven
    case microwave
    case furnace
    case sumpPump
    case garageDoor
    case smokeDetector
    case waterSoftener
    case generator
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hvac:          return "HVAC / AC"
        case .waterHeater:   return "Water Heater"
        case .refrigerator:  return "Refrigerator"
        case .dishwasher:    return "Dishwasher"
        case .washer:        return "Washing Machine"
        case .dryer:         return "Dryer"
        case .oven:          return "Oven / Range"
        case .microwave:     return "Microwave"
        case .furnace:       return "Furnace"
        case .sumpPump:      return "Sump Pump"
        case .garageDoor:    return "Garage Door"
        case .smokeDetector: return "Smoke / CO Detector"
        case .waterSoftener: return "Water Softener"
        case .generator:     return "Generator"
        case .other:         return "Other Equipment"
        }
    }

    var systemImage: String {
        switch self {
        case .hvac:          return "wind"
        case .waterHeater:   return "spigot"
        case .refrigerator:  return "refrigerator"
        case .dishwasher:    return "dishwasher"
        case .washer:        return "washer"
        case .dryer:         return "dryer"
        case .oven:          return "oven"
        case .microwave:     return "microwave"
        case .furnace:       return "flame"
        case .sumpPump:      return "drop.triangle"
        case .garageDoor:    return "door.garage.closed"
        case .smokeDetector: return "sensor"
        case .waterSoftener: return "drop"
        case .generator:     return "bolt.batteryblock"
        case .other:         return "wrench.and.screwdriver"
        }
    }
}
