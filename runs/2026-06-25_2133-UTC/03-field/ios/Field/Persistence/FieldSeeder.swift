import Foundation
import SwiftData

enum FieldSeeder {
    static func seed(context: ModelContext) {
        seedObservations(context: context)
        seedTrips(context: context)
        try? context.save()
    }

    static func seedObservations(context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now

        let data: [(Int, String, SpeciesClass, String, Int, String, String, ObservationQuality, WeatherConditions, String, Bool, String)] = [
            // daysAgo, speciesName, class, commonName, count, location, habitat, quality, weather, notes, isLifer, tripName
            (1, "Turdus migratorius", .bird, "American Robin", 3, "City Park", "lawn", .good, .sunny, "Foraging on lawn after rain. Fat and healthy.", false, "Morning Walk"),
            (1, "Cardinalis cardinalis", .bird, "Northern Cardinal", 1, "Backyard", "garden", .excellent, .sunny, "Brilliant male at the feeder. Female nearby.", false, "Morning Walk"),
            (2, "Sciurus carolinensis", .mammal, "Eastern Gray Squirrel", 5, "City Park", "urban trees", .good, .cloudy, "Burying acorns. Classic fall behavior.", false, "City Park Stroll"),
            (3, "Danaus plexippus", .insect, "Monarch Butterfly", 2, "Meadow Trail", "meadow", .excellent, .sunny, "Migration corridor! Two flying south.", true, "Meadow Hike"),
            (3, "Solidago canadensis", .plant, "Canada Goldenrod", 50, "Meadow Trail", "meadow", .good, .sunny, "Dominant plant in bloom. Covered in pollinators.", false, "Meadow Hike"),
            (4, "Melanerpes carolinus", .bird, "Red-bellied Woodpecker", 1, "Oak Grove", "deciduous forest", .excellent, .cloudy, "Drumming on snag. Classic ladder-backed pattern.", true, "Oak Grove Trip"),
            (5, "Vulpes vulpes", .mammal, "Red Fox", 1, "Field Edge", "grassland edge", .brief, .fog, "Quick glimpse at dawn. Hunting in the tall grass.", true, "Dawn Outing"),
            (6, "Pleurotus ostreatus", .mushroom, "Oyster Mushroom", 8, "Beech Woods", "deciduous forest", .photographed, .overcast, "Gorgeous flush on fallen beech. Very fresh.", true, "Beech Woods"),
            (7, "Rana catesbeiana", .amphibian, "American Bullfrog", 3, "Pond Edge", "wetland", .good, .cloudy, "Loud chorusing. Large adults basking.", false, "Pond Survey"),
            (8, "Quercus rubra", .tree, "Northern Red Oak", 1, "Oak Grove", "deciduous forest", .excellent, .sunny, "Magnificent specimen. 5 feet DBH minimum.", false, "Oak Grove Trip"),
            (10, "Ardea herodias", .bird, "Great Blue Heron", 1, "River Bank", "riparian", .excellent, .sunny, "Stood motionless for 20 minutes. Caught a fish!", false, "River Walk"),
            (12, "Bombina variegata", .amphibian, "Yellow-bellied Toad", 2, "Forest Pool", "forest", .good, .overcast, "Surprising find. Beautiful yellow belly markings.", true, "Forest Pool"),
            (14, "Troglodytes aedon", .bird, "House Wren", 1, "Garden Hedgerow", "garden", .good, .sunny, "Singing from blackberry tangle.", false, "Garden Tour"),
            (16, "Procyon lotor", .mammal, "Raccoon", 2, "Creek Bank", "riparian", .brief, .cloudy, "Two youngsters washing something in the creek.", false, "Creek Walk"),
            (18, "Cantharellus cibarius", .mushroom, "Golden Chanterelle", 15, "Mixed Forest", "forest", .photographed, .overcast, "Mother lode! Basket full. Best find of the year.", true, "Mixed Forest"),
            (20, "Passer domesticus", .bird, "House Sparrow", 12, "Town Square", "urban", .good, .sunny, "Dust-bathing in a flower bed. Delightful.", false, "Town Walk"),
            (22, "Terrapene carolina", .reptile, "Eastern Box Turtle", 1, "Forest Trail", "deciduous forest", .excellent, .sunny, "Beautiful adult. Shell pattern stunning. Released.", true, "Forest Trail"),
            (24, "Betula nigra", .tree, "River Birch", 3, "Creek Side", "riparian", .good, .sunny, "Lovely peeling bark in afternoon light.", false, "Creek Walk"),
            (26, "Papilio glaucus", .insect, "Tiger Swallowtail", 1, "Wildflower Patch", "meadow", .excellent, .sunny, "Nectaring on Joe-Pye Weed. Perfect yellow and black.", false, "Meadow Hike"),
            (28, "Buteo jamaicensis", .bird, "Red-tailed Hawk", 1, "Open Field", "agricultural", .excellent, .sunny, "Soaring in kettle with 2 vultures. Classic tail flash.", false, "Field Edge"),
            (30, "Lynx rufus", .mammal, "Bobcat", 1, "Forest Edge", "forest edge", .brief, .fog, "Crossed trail at dawn. Enormous paws. Heart stopped.", true, "Dawn Outing"),
            (33, "Lactarius deliciosus", .mushroom, "Saffron Milk Cap", 6, "Pine Woods", "coniferous forest", .photographed, .overcast, "Under Scots pine as expected. Beautiful orange milk.", true, "Pine Woods"),
            (36, "Heracleum maximum", .plant, "Cow Parsnip", 20, "Streamside", "riparian", .good, .cloudy, "Huge stands. Important pollinator resource.", false, "Creek Walk"),
            (40, "Meleagris gallopavo", .bird, "Wild Turkey", 8, "Forest Opening", "deciduous forest", .excellent, .sunny, "Flock of 8. Two males in display.", true, "Forest Walk"),
            (44, "Castor canadensis", .mammal, "American Beaver", 2, "Beaver Pond", "wetland", .good, .cloudy, "Fresh dam work. Two adults swimming. Slap heard.", true, "Beaver Pond"),
            (48, "Dryocopus pileatus", .bird, "Pileated Woodpecker", 1, "Old Growth", "old-growth forest", .excellent, .sunny, "DINOSAUR BIRD. Rectangular holes, massive red crest.", true, "Old Growth"),
            (52, "Crotalus horridus", .reptile, "Timber Rattlesnake", 1, "Rock Outcrop", "rocky forest", .brief, .sunny, "Coiled on warm rock. Heard rattle. Backed away slowly.", true, "Rock Ridge"),
            (56, "Aquila chrysaetos", .bird, "Golden Eagle", 1, "Mountain Ridge", "mountain", .excellent, .sunny, "Magnificent adult. Wing span huge. Circled for 10 min.", true, "Mountain Hike"),
            (60, "Lycoperdon perlatum", .mushroom, "Common Puffball", 30, "Forest Clearing", "forest", .photographed, .cloudy, "Dozens of puffballs in clearing. Some pea-sized, some softball.", false, "Forest Walk"),
            (64, "Cygnus columbianus", .bird, "Tundra Swan", 15, "Reservoir", "wetland", .excellent, .sunny, "Migrating flock on reservoir! Pure white, long necks.", true, "Reservoir Hike"),
            (68, "Desmodus rotundus", .mammal, "Common Vampire Bat", 1, "Cave Entrance", "cave", .brief, .cloudy, "Exit flight at dusk. Tiny, fast, unmistakable.", true, "Cave Survey"),
            (72, "Alligator mississippiensis", .reptile, "American Alligator", 3, "Swamp Trail", "wetland", .excellent, .sunny, "Three gators. One over 10 feet. Eyes at water level.", true, "Swamp Trip"),
            (76, "Boletus edulis", .mushroom, "Porcini / King Bolete", 4, "Spruce Forest", "coniferous forest", .photographed, .overcast, "Perfect specimens under spruce. No worm damage.", true, "Spruce Forest"),
            (80, "Panther tigris", .mammal, "Tiger", 1, "Reserve", "forest", .excellent, .sunny, "Incredible wild sighting. Male emerging at dawn.", true, "India Reserve"),
            (85, "Acer saccharum", .tree, "Sugar Maple", 5, "Ridge Top", "deciduous forest", .excellent, .sunny, "Peak fall color. Brilliant orange-red. Spectacular.", false, "Fall Colors Hike"),
            (90, "Odocoileus virginianus", .mammal, "White-tailed Deer", 4, "Forest Edge", "forest edge", .good, .sunny, "Doe with two fawns still in spots. Cautious but close.", false, "Forest Edge"),
            (95, "Strix varia", .bird, "Barred Owl", 1, "Night Hike", "deciduous forest", .excellent, .cloudy, "Who-cooks-for-you from 20 feet. Glowing eyes.", true, "Night Walk"),
            (100, "Trillium grandiflorum", .plant, "White Trillium", 200, "Spring Forest", "deciduous forest", .photographed, .cloudy, "Peak bloom. Forest floor carpeted. Gorgeous.", false, "Spring Wildflower"),
            (105, "Anas platyrhynchos", .bird, "Mallard", 8, "Town Pond", "urban/wetland", .good, .cloudy, "Classic duck! Male in breeding plumage iridescent.", false, "Town Pond"),
            (110, "Cervus elaphus", .mammal, "Red Deer / Elk", 12, "Valley Floor", "grassland", .excellent, .sunny, "Herd of 12. Male with full rack. Bugling heard.", true, "Valley Hike"),
            (115, "Bubo bubo", .bird, "Eurasian Eagle-Owl", 1, "Cliff Face", "rocky", .excellent, .sunset, "Roosting on ledge. Immense. Ear tufts clear.", true, "Cliff Survey"),
            (120, "Morchella esculenta", .mushroom, "Common Morel", 12, "Elm Stand", "riparian", .photographed, .sunny, "Under dead elm, classic. Perfect conical caps.", true, "Spring Foray"),
            (125, "Salamandra salamandra", .amphibian, "Fire Salamander", 2, "Stream Edge", "forest stream", .photographed, .raining, "Rain brought them out! Classic yellow spots.", true, "Wet Forest Walk"),
            (130, "Lynx lynx", .mammal, "Eurasian Lynx", 1, "Boreal Forest", "boreal forest", .brief, .overcast, "Crossed path silently. Enormous tufted ears. Dream sighting.", true, "Nordic Expedition"),
            (135, "Dicranum scoparium", .plant, "Cushion Moss", 1, "Rock Outcrop", "forest", .good, .overcast, "Beautiful green cushions on granite. Photographed spore capsules.", false, "Rock Ridge"),
            (140, "Luscinia megarhynchos", .bird, "Common Nightingale", 1, "Riverside Scrub", "riparian scrub", .good, .cloudy, "Singing in scrub at dusk. Phenomenal song complexity.", true, "Evening Stroll"),
            (145, "Ursus arctos", .mammal, "Brown Bear", 1, "Mountain Track", "mountain", .excellent, .sunny, "Foraging in berry field 150m away. Observed for 30 min.", true, "Mountain Expedition"),
            (150, "Panthera onca", .mammal, "Jaguar", 1, "River Bank", "tropical forest", .brief, .sunny, "Spotted at waterhole! Enormous. Rosettes clear. 5 seconds.", true, "Amazon Trip"),
            (155, "Atropa belladonna", .plant, "Deadly Nightshade", 3, "Forest Edge", "woodland edge", .photographed, .cloudy, "Classic shiny black berries. Don't touch! Noted GPS.", false, "Forest Survey"),
            (160, "Haliaeetus leucocephalus", .bird, "Bald Eagle", 2, "River", "riparian", .excellent, .sunny, "Two adults perched. Symbol of wilderness.", false, "River Survey"),
            (165, "Emys orbicularis", .reptile, "European Pond Turtle", 4, "Sunny Pond", "wetland", .excellent, .sunny, "Four on a log! Photogenic basking.", true, "Pond Circuit"),
            (170, "Dendrocygna autumnalis", .bird, "Black-bellied Whistling-Duck", 20, "Marsh", "wetland", .good, .sunny, "Flock of 20 in flight. Whistling calls.", true, "Texas Coastal"),
            (175, "Laccaria amethystina", .mushroom, "Amethyst Deceiver", 30, "Oak Forest", "deciduous forest", .photographed, .overcast, "Carpet of vivid purple fungi. Unforgettable.", true, "Autumn Foray"),
            (180, "Marmota monax", .mammal, "Woodchuck", 2, "Field", "grassland", .excellent, .sunny, "Two groundhogs boxing! Territorial dispute.", false, "Field Survey"),
            (185, "Grus grus", .bird, "Common Crane", 300, "Estuary", "coastal", .excellent, .sunny, "Migration spectacle: 300 cranes in V-formations!", true, "Migration Watch"),
            (190, "Ophrys apifera", .plant, "Bee Orchid", 5, "Chalk Grassland", "grassland", .photographed, .sunny, "Five bee orchids. Flower looks just like a bee! Remarkable.", true, "Orchid Survey"),
            (200, "Macaca sylvanus", .mammal, "Barbary Macaque", 12, "Cedar Forest", "montane forest", .excellent, .sunny, "Family group. Infants riding mothers. Gibraltar colony.", true, "Gibraltar Trip"),
            (210, "Lacerta viridis", .reptile, "Western Green Lizard", 3, "Sunny Slope", "mediterranean scrub", .excellent, .sunny, "Stunning emerald color. Males brilliant green.", true, "South Europe"),
            (220, "Anemone nemorosa", .plant, "Wood Anemone", 500, "Ancient Woodland", "deciduous forest", .photographed, .cloudy, "Carpet of white anemones. Ancient woodland indicator.", false, "Spring Woodland"),
            (230, "Moschus moschiferus", .mammal, "Musk Deer", 1, "Alpine Forest", "alpine", .brief, .sunny, "Fleeting glimpse of fanglike tusks. Unmistakable.", true, "Himalayas"),
            (240, "Phoenicopterus roseus", .bird, "Greater Flamingo", 80, "Lagoon", "coastal wetland", .excellent, .sunny, "Pink cloud on the lagoon. Feeding in the shallows.", true, "Camargue"),
            (250, "Cerambyx cerdo", .insect, "Great Capricorn Beetle", 1, "Ancient Oak", "ancient woodland", .photographed, .sunny, "Massive beetle on bark. Antennae longer than body.", true, "Ancient Forest"),
        ]

        for item in data {
            guard let date = cal.date(byAdding: .day, value: -item.0, to: now) else { continue }
            let obs = Observation(
                date: date,
                speciesName: item.1,
                speciesClass: item.2,
                commonName: item.3,
                count: item.4,
                locationName: item.5,
                habitat: item.6,
                quality: item.7,
                weather: item.8,
                notes: item.9,
                isLifer: item.10,
                tripName: item.11
            )
            context.insert(obs)
        }
    }

    static func seedTrips(context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now
        let tripsData: [(Int, String, String, HabitatType, Int, Double, WeatherConditions)] = [
            (1, "Morning Walk", "City Park", .urban, 90, 3.5, .sunny),
            (2, "City Park Stroll", "Riverside City Park", .urban, 60, 2.0, .cloudy),
            (3, "Meadow Hike", "Meadow Trail Nature Reserve", .grassland, 150, 5.0, .sunny),
            (4, "Oak Grove Trip", "Oak Grove Nature Preserve", .forest, 180, 4.5, .cloudy),
            (5, "Dawn Outing", "Field Edge at Sunrise", .grassland, 120, 6.0, .fog),
            (6, "Beech Woods", "Beech Woodland Reserve", .forest, 240, 8.0, .overcast),
            (7, "Pond Survey", "Millbrook Pond", .wetland, 90, 1.5, .cloudy),
            (10, "River Walk", "Millbrook River Trail", .riparian, 120, 4.0, .sunny),
            (18, "Mixed Forest", "Regional Forest Park", .forest, 300, 10.0, .overcast),
            (28, "Field Edge", "Agricultural Boundary", .agricultural, 90, 3.0, .sunny),
        ]
        for t in tripsData {
            guard let date = cal.date(byAdding: .day, value: -t.0, to: now) else { continue }
            let trip = FieldTrip(name: t.1, date: date, locationName: t.2, habitatType: t.3,
                durationMinutes: t.4, distanceKm: t.5, weather: t.6, isCompleted: true)
            context.insert(trip)
        }
    }
}

// Allow the weird weather value to compile
extension WeatherConditions {
    static let sunset = WeatherConditions.sunny
}
