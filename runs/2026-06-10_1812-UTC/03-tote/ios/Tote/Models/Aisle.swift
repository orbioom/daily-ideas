import SwiftUI

/// Store sections, ordered roughly the way you walk a supermarket. Items are
/// auto-sorted into these so the list reads like your route through the store.
enum Aisle: String, CaseIterable, Identifiable, Codable {
    case produce = "Produce"
    case bakery = "Bakery"
    case dairy = "Dairy & Eggs"
    case meat = "Meat & Seafood"
    case deli = "Deli"
    case frozen = "Frozen"
    case pantry = "Pantry"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case household = "Household"
    case personal = "Personal Care"
    case other = "Other"

    var id: String { rawValue }

    /// Walk order — lower comes first in the list.
    var order: Int { Aisle.allCases.firstIndex(of: self) ?? 99 }

    var icon: String {
        switch self {
        case .produce: return "carrot.fill"
        case .bakery: return "birthday.cake.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fish.fill"
        case .deli: return "takeoutbag.and.cup.and.straw.fill"
        case .frozen: return "snowflake"
        case .pantry: return "shippingbox.fill"
        case .snacks: return "popcorn.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .household: return "house.fill"
        case .personal: return "sparkles"
        case .other: return "bag.fill"
        }
    }

    var tint: Color {
        switch self {
        case .produce: return Brand.dynamic(0x4FA07C, 0x86C79A)
        case .bakery: return Brand.dynamic(0xC0913E, 0xE0B86A)
        case .dairy: return Brand.dynamic(0x5E86B0, 0x9ABEE8)
        case .meat: return Brand.dynamic(0xB1604E, 0xE08A78)
        case .deli: return Brand.dynamic(0xB07E4E, 0xE0B086)
        case .frozen: return Brand.dynamic(0x5E9AB0, 0x86C7E8)
        case .pantry: return Brand.dynamic(0x8A7A5E, 0xC9B486)
        case .snacks: return Brand.dynamic(0xB07050, 0xE0A078)
        case .beverages: return Brand.dynamic(0x6A6AA8, 0x9AA8E0)
        case .household: return Brand.dynamic(0x5566A8, 0x9AA8E0)
        case .personal: return Brand.dynamic(0x8A6FC0, 0xB59EE8)
        case .other: return Brand.dynamic(0x787C90, 0x9CA0B4)
        }
    }
}

/// Guesses the aisle for a typed item name using a built-in keyword map.
/// Learned catalog overrides take priority and are applied by the caller.
enum AisleGuesser {
    private static let map: [Aisle: [String]] = [
        .produce: ["apple","banana","orange","lettuce","spinach","kale","tomato","potato","onion","garlic",
                   "carrot","celery","pepper","cucumber","broccoli","avocado","lemon","lime","berry","berries",
                   "strawberr","blueberr","grape","mushroom","cilantro","parsley","ginger","lettuce","salad",
                   "zucchini","squash","corn","peach","pear","melon","mango","herb","greens","cabbage"],
        .bakery: ["bread","bagel","baguette","roll","croissant","muffin","tortilla","pita","bun","cake",
                  "donut","pastry","loaf","naan"],
        .dairy: ["milk","cheese","yogurt","yoghurt","butter","cream","egg","eggs","sour cream","cottage",
                 "half and half","creamer","margarine"],
        .meat: ["chicken","beef","pork","steak","bacon","sausage","turkey","ham","fish","salmon","shrimp",
                "tuna","ground","lamb","tilapia","cod","crab"],
        .deli: ["deli","prosciutto","salami","pepperoni","hummus","olives","rotisserie"],
        .frozen: ["frozen","ice cream","pizza","fries","popsicle","waffle"],
        .pantry: ["rice","pasta","flour","sugar","oil","vinegar","sauce","beans","soup","cereal","oat",
                  "peanut butter","jam","jelly","honey","salt","pepper","spice","stock","broth","noodle",
                  "can","canned","tomato sauce","ketchup","mustard","mayo","syrup","baking","yeast","lentil",
                  "quinoa","couscous","tea","coffee","granola","crackers"],
        .snacks: ["chips","cookie","candy","chocolate","pretzel","popcorn","nuts","trail mix","granola bar",
                  "snack","crisps","gum"],
        .beverages: ["water","juice","soda","cola","beer","wine","sparkling","kombucha","lemonade","drink",
                     "seltzer","gatorade","energy drink"],
        .household: ["paper towel","toilet paper","detergent","soap","cleaner","trash bag","dish soap",
                     "sponge","foil","wrap","ziploc","bag","napkin","tissue","bleach","laundry","battery",
                     "light bulb","candle"],
        .personal: ["shampoo","conditioner","toothpaste","toothbrush","deodorant","lotion","razor","floss",
                    "vitamin","medicine","band-aid","sunscreen","makeup","cotton","feminine","body wash"]
    ]

    static func guess(_ name: String) -> Aisle {
        let n = name.lowercased()
        for aisle in Aisle.allCases where aisle != .other {
            if let keywords = map[aisle], keywords.contains(where: { n.contains($0) }) {
                return aisle
            }
        }
        return .other
    }
}
