import Foundation
import SwiftData

/// Seeds a bird catalog and a record of trips and sightings so every screen has
/// life-list, year-list, and trend data on first launch.
enum SampleData {

    /// (common, scientific, family) in rough checklist order.
    static let catalog: [(String, String, String)] = [
        ("Canada Goose", "Branta canadensis", "Waterfowl"),
        ("Wood Duck", "Aix sponsa", "Waterfowl"),
        ("Mallard", "Anas platyrhynchos", "Waterfowl"),
        ("Hooded Merganser", "Lophodytes cucullatus", "Waterfowl"),
        ("Wild Turkey", "Meleagris gallopavo", "Gamebirds"),
        ("Ruffed Grouse", "Bonasa umbellus", "Gamebirds"),
        ("Mourning Dove", "Zenaida macroura", "Pigeons & Doves"),
        ("Rock Pigeon", "Columba livia", "Pigeons & Doves"),
        ("Ruby-throated Hummingbird", "Archilochus colubris", "Hummingbirds"),
        ("Killdeer", "Charadrius vociferus", "Plovers"),
        ("Great Blue Heron", "Ardea herodias", "Herons"),
        ("Great Egret", "Ardea alba", "Herons"),
        ("Green Heron", "Butorides virescens", "Herons"),
        ("Turkey Vulture", "Cathartes aura", "Vultures"),
        ("Bald Eagle", "Haliaeetus leucocephalus", "Hawks & Eagles"),
        ("Cooper's Hawk", "Accipiter cooperii", "Hawks & Eagles"),
        ("Red-tailed Hawk", "Buteo jamaicensis", "Hawks & Eagles"),
        ("Belted Kingfisher", "Megaceryle alcyon", "Kingfishers"),
        ("Red-bellied Woodpecker", "Melanerpes carolinus", "Woodpeckers"),
        ("Downy Woodpecker", "Dryobates pubescens", "Woodpeckers"),
        ("Hairy Woodpecker", "Dryobates villosus", "Woodpeckers"),
        ("Northern Flicker", "Colaptes auratus", "Woodpeckers"),
        ("Pileated Woodpecker", "Dryocopus pileatus", "Woodpeckers"),
        ("Eastern Phoebe", "Sayornis phoebe", "Flycatchers"),
        ("Great Crested Flycatcher", "Myiarchus crinitus", "Flycatchers"),
        ("Eastern Kingbird", "Tyrannus tyrannus", "Flycatchers"),
        ("Blue Jay", "Cyanocitta cristata", "Jays & Crows"),
        ("American Crow", "Corvus brachyrhynchos", "Jays & Crows"),
        ("Common Raven", "Corvus corax", "Jays & Crows"),
        ("Black-capped Chickadee", "Poecile atricapillus", "Chickadees & Titmice"),
        ("Tufted Titmouse", "Baeolophus bicolor", "Chickadees & Titmice"),
        ("White-breasted Nuthatch", "Sitta carolinensis", "Nuthatches"),
        ("Red-breasted Nuthatch", "Sitta canadensis", "Nuthatches"),
        ("Brown Creeper", "Certhia americana", "Creepers"),
        ("Carolina Wren", "Thryothorus ludovicianus", "Wrens"),
        ("House Wren", "Troglodytes aedon", "Wrens"),
        ("Ruby-crowned Kinglet", "Corthylio calendula", "Kinglets"),
        ("Eastern Bluebird", "Sialia sialis", "Thrushes"),
        ("Wood Thrush", "Hylocichla mustelina", "Thrushes"),
        ("American Robin", "Turdus migratorius", "Thrushes"),
        ("Gray Catbird", "Dumetella carolinensis", "Mimids"),
        ("Northern Mockingbird", "Mimus polyglottos", "Mimids"),
        ("Brown Thrasher", "Toxostoma rufum", "Mimids"),
        ("European Starling", "Sturnus vulgaris", "Starlings"),
        ("Cedar Waxwing", "Bombycilla cedrorum", "Waxwings"),
        ("House Finch", "Haemorhous mexicanus", "Finches"),
        ("Purple Finch", "Haemorhous purpureus", "Finches"),
        ("American Goldfinch", "Spinus tristis", "Finches"),
        ("Chipping Sparrow", "Spizella passerina", "Sparrows"),
        ("Song Sparrow", "Melospiza melodia", "Sparrows"),
        ("White-throated Sparrow", "Zonotrichia albicollis", "Sparrows"),
        ("Dark-eyed Junco", "Junco hyemalis", "Sparrows"),
        ("Eastern Towhee", "Pipilo erythrophthalmus", "Sparrows"),
        ("Baltimore Oriole", "Icterus galbula", "Blackbirds"),
        ("Red-winged Blackbird", "Agelaius phoeniceus", "Blackbirds"),
        ("Common Grackle", "Quiscalus quiscula", "Blackbirds"),
        ("Brown-headed Cowbird", "Molothrus ater", "Blackbirds"),
        ("Common Yellowthroat", "Geothlypis trichas", "Warblers"),
        ("Yellow Warbler", "Setophaga petechia", "Warblers"),
        ("Yellow-rumped Warbler", "Setophaga coronata", "Warblers"),
        ("Black-throated Green Warbler", "Setophaga virens", "Warblers"),
        ("Scarlet Tanager", "Piranga olivacea", "Cardinals & Allies"),
        ("Northern Cardinal", "Cardinalis cardinalis", "Cardinals & Allies"),
        ("Rose-breasted Grosbeak", "Pheucticus ludovicianus", "Cardinals & Allies"),
        ("Indigo Bunting", "Passerina cyanea", "Cardinals & Allies")
    ]

    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        init(_ s: UInt64) { state = s == 0 ? 88172645463325252 : s }
        mutating func next() -> UInt64 {
            state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
        }
    }

    static func seed(into context: ModelContext) {
        var all: [Species] = []
        for (i, c) in catalog.enumerated() {
            let sp = Species(commonName: c.0, scientificName: c.1, family: c.2, taxonOrder: i)
            context.insert(sp)
            all.append(sp)
        }

        let cal = Calendar.current
        let today = Date()
        var rng = Seeded(7)

        let tripDefs: [(String, String, Int)] = [
            ("Backyard morning", "Home feeders", 150),
            ("Marsh boardwalk", "Salt Marsh NWR", 120),
            ("Spring migration walk", "Oak Ridge Park", 75),
            ("Lakeshore count", "Crescent Lake", 40),
            ("Woodland loop", "Hollow Creek Trail", 12)
        ]

        for (name, loc, daysAgo) in tripDefs {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let trip = Trip(name: name, date: date, location: loc)
            context.insert(trip)
            // pick a pseudo-random set of species for this trip
            let n = 7 + Int(rng.next() % 7)
            var picked = Set<Int>()
            while picked.count < n { picked.insert(Int(rng.next() % UInt64(all.count))) }
            for idx in picked {
                let sp = all[idx]
                let cnt = 1 + Int(rng.next() % 6)
                let s = Sighting(date: date, location: loc, count: cnt,
                                 notes: "", species: sp, trip: trip)
                context.insert(s)
            }
        }

        // a few stray sightings not tied to trips, across earlier months
        for _ in 0..<8 {
            let idx = Int(rng.next() % UInt64(all.count))
            let d = cal.date(byAdding: .day, value: -Int(rng.next() % 300) - 10, to: today) ?? today
            let s = Sighting(date: d, location: "Field notes", count: 1 + Int(rng.next() % 3),
                             species: all[idx])
            context.insert(s)
        }

        try? context.save()
    }
}
