import Foundation
import SwiftData

/// Seeds a realistic sample collection (50+ records across genres, decades and
/// formats, with tracklists and spins) behind the "didSeed" flag.
enum SeedData {

    /// A compact seed entry. `status == .wishlist` → wantlist (no condition/spins).
    private struct Entry {
        let title: String
        let artist: String
        let year: Int
        let genre: Genre
        let format: Format
        let label: String
        let catalog: String
        let media: Grade
        let sleeve: Grade
        let paid: Double
        let value: Double
        let color: String
        let status: RecordStatus
        let trackTitles: [String]   // simple A/B split for the tracklist
    }

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertAll(context: context)
        didSeed = true
    }

    /// Insert the full catalog. Used by seed and by "reset & reseed".
    static func insertAll(context: ModelContext) {
        let entries = catalog()
        let base = Date()
        for (i, e) in entries.enumerated() {
            let rec = Record(title: e.title,
                             artist: e.artist,
                             year: e.year,
                             format: e.format,
                             speed: e.format == .sevenInch || e.format == .single ? .rpm45 : .rpm33,
                             genre: e.genre,
                             label: e.label,
                             catalogNo: e.catalog,
                             mediaCondition: e.media,
                             sleeveCondition: e.sleeve,
                             pricePaid: e.paid,
                             estValue: e.value,
                             vinylColor: e.color,
                             status: e.status,
                             notes: "",
                             addedAt: base.addingTimeInterval(Double(-i) * 64_800))
            context.insert(rec)
            attachTracks(to: rec, titles: e.trackTitles, seedIndex: i)
            if e.status == .owned { attachSpins(to: rec, seedIndex: i, base: base) }
        }
        try? context.save()
    }

    /// Remove every record (cascades to tracks & spins).
    static func clearAll(context: ModelContext) {
        let descriptor = FetchDescriptor<Record>()
        if let all = try? context.fetch(descriptor) {
            for r in all { context.delete(r) }
            try? context.save()
        }
    }

    // MARK: Tracks

    private static func attachTracks(to rec: Record, titles: [String], seedIndex: Int) {
        guard !titles.isEmpty else { return }
        // Split tracks across A / B sides; deterministic durations.
        let half = max(1, (titles.count + 1) / 2)
        for (i, t) in titles.enumerated() {
            let side = i < half ? "A" : "B"
            let pos = i < half ? i + 1 : i - half + 1
            // Pseudo-duration 2:10 … 6:40, deterministic from index.
            let seconds = 130 + ((seedIndex * 37 + i * 53) % 270)
            let track = Track(side: side, position: pos, title: t, seconds: seconds)
            track.record = rec
            rec.tracks.append(track)
        }
    }

    // MARK: Spins

    private static func attachSpins(to rec: Record, seedIndex: Int, base: Date) {
        // ~1 in 5 owned records is "never spun"; the rest get 1–6 spins spread over the past year.
        if seedIndex % 5 == 0 { return }
        let count = 1 + (seedIndex % 6)
        for k in 0..<count {
            let daysAgo = Double((seedIndex * 11 + k * 29) % 360)
            let date = base.addingTimeInterval(-daysAgo * 86_400)
            let rating = (seedIndex + k) % 3 == 0 ? 0 : 3 + ((seedIndex + k) % 3)
            let spin = Spin(date: date, rating: rating, note: "")
            spin.record = rec
            rec.spins.append(spin)
        }
    }

    // MARK: Catalog (>=50 owned across genres/decades/formats + a wantlist)

    private static func catalog() -> [Entry] {
        var e: [Entry] = []
        func add(_ title: String, _ artist: String, _ year: Int, _ genre: Genre,
                 _ format: Format, _ label: String, _ catalog: String,
                 _ media: Grade, _ sleeve: Grade, _ paid: Double, _ value: Double,
                 _ color: String, _ status: RecordStatus, _ tracks: [String]) {
            e.append(Entry(title: title, artist: artist, year: year, genre: genre,
                           format: format, label: label, catalog: catalog,
                           media: media, sleeve: sleeve, paid: paid, value: value,
                           color: color, status: status, trackTitles: tracks))
        }

        // --- Owned ---
        add("Kind of Blue", "Miles Davis", 1959, .jazz, .lp, "Columbia", "CL 1355", .vgPlus, .vg, 28, 65, "Black", .owned, ["So What", "Freddie Freeloader", "Blue in Green", "All Blues", "Flamenco Sketches"])
        add("A Love Supreme", "John Coltrane", 1965, .jazz, .lp, "Impulse!", "A-77", .nearMint, .vgPlus, 35, 90, "Black", .owned, ["Acknowledgement", "Resolution", "Pursuance", "Psalm"])
        add("Mingus Ah Um", "Charles Mingus", 1959, .jazz, .lp, "Columbia", "CL 1370", .vg, .vg, 22, 48, "Black", .owned, ["Better Git It in Your Soul", "Goodbye Pork Pie Hat", "Boogie Stop Shuffle", "Self-Portrait in Three Colors"])
        add("Rumours", "Fleetwood Mac", 1977, .rock, .lp, "Warner Bros.", "BSK 3010", .vgPlus, .vgPlus, 18, 30, "Black", .owned, ["Second Hand News", "Dreams", "Never Going Back Again", "Don't Stop", "Go Your Own Way", "The Chain"])
        add("Led Zeppelin IV", "Led Zeppelin", 1971, .rock, .lp, "Atlantic", "SD 7208", .vg, .gPlus, 20, 40, "Black", .owned, ["Black Dog", "Rock and Roll", "The Battle of Evermore", "Stairway to Heaven", "Misty Mountain Hop"])
        add("Abbey Road", "The Beatles", 1969, .rock, .lp, "Apple", "PCS 7088", .nearMint, .vgPlus, 40, 85, "Black", .owned, ["Come Together", "Something", "Octopus's Garden", "Here Comes the Sun", "Because"])
        add("The Dark Side of the Moon", "Pink Floyd", 1973, .rock, .lp, "Harvest", "SHVL 804", .vgPlus, .vg, 30, 55, "Black", .owned, ["Speak to Me", "Breathe", "Time", "The Great Gig in the Sky", "Money", "Us and Them"])
        add("Songs in the Key of Life", "Stevie Wonder", 1976, .soul, .box, "Tamla", "T13-340C2", .vgPlus, .vgPlus, 36, 70, "Black", .owned, ["Love's in Need of Love Today", "Have a Talk with God", "Village Ghetto Land", "Sir Duke", "I Wish", "Isn't She Lovely"])
        add("What's Going On", "Marvin Gaye", 1971, .soul, .lp, "Tamla", "TS 310", .vg, .vg, 24, 50, "Black", .owned, ["What's Going On", "What's Happening Brother", "Flyin' High", "Save the Children", "Mercy Mercy Me", "Inner City Blues"])
        add("Innervisions", "Stevie Wonder", 1973, .soul, .lp, "Tamla", "T-326L", .vgPlus, .vgPlus, 19, 38, "Black", .owned, ["Too High", "Visions", "Living for the City", "Golden Lady", "Higher Ground", "Jesus Children of America"])
        add("Maggot Brain", "Funkadelic", 1971, .funk, .lp, "Westbound", "WB 2007", .vg, .gPlus, 26, 60, "Black", .owned, ["Maggot Brain", "Can You Get to That", "Hit It and Quit It", "You and Your Folks", "Super Stupid"])
        add("Mothership Connection", "Parliament", 1975, .funk, .lp, "Casablanca", "NBLP 7022", .vgPlus, .vg, 21, 45, "Black", .owned, ["P-Funk", "Mothership Connection", "Unfunky UFO", "Supergroovalisticprosifunkstication", "Give Up the Funk"])
        add("Head Hunters", "Herbie Hancock", 1973, .funk, .lp, "Columbia", "KC 32731", .vgPlus, .vgPlus, 23, 44, "Black", .owned, ["Chameleon", "Watermelon Man", "Sly", "Vein Melter"])
        add("Illmatic", "Nas", 1994, .hiphop, .lp, "Columbia", "C 57684", .nearMint, .nearMint, 45, 80, "Black", .owned, ["The Genesis", "N.Y. State of Mind", "Life's a Bitch", "The World Is Yours", "Halftime", "Memory Lane"])
        add("Midnight Marauders", "A Tribe Called Quest", 1993, .hiphop, .lp, "Jive", "01241-41490", .vgPlus, .vgPlus, 32, 58, "Black", .owned, ["Midnight Marauders Tour Guide", "Steve Biko", "Award Tour", "Sucka Nigga", "Electric Relaxation"])
        add("Madvillainy", "Madvillain", 2004, .hiphop, .twelveInch, "Stones Throw", "STH2065", .nearMint, .nearMint, 30, 65, "Black", .owned, ["The Illest Villains", "Accordion", "Meat Grinder", "Bistro", "Raid", "America's Most Blunted"])
        add("Discovery", "Daft Punk", 2001, .electronic, .lp, "Virgin", "7243 8497", .nearMint, .vgPlus, 28, 52, "Black", .owned, ["One More Time", "Aerodynamic", "Digital Love", "Harder Better Faster Stronger", "Crescendolls", "Something About Us"])
        add("Selected Ambient Works 85-92", "Aphex Twin", 1992, .electronic, .lp, "Apollo", "AMB 3922", .vgPlus, .vg, 34, 70, "Black", .owned, ["Xtal", "Tha", "Pulsewidth", "Ageispolis", "i", "Green Calx", "Heliosphan"])
        add("Untrue", "Burial", 2007, .electronic, .twelveInch, "Hyperdub", "HDBLP002", .nearMint, .nearMint, 26, 48, "Black", .owned, ["Untitled", "Archangel", "Near Dark", "Ghost Hardware", "Endorphin", "Etched Headplate"])
        add("Thriller", "Michael Jackson", 1982, .pop, .lp, "Epic", "QE 38112", .vgPlus, .vg, 15, 25, "Black", .owned, ["Wanna Be Startin' Somethin'", "Baby Be Mine", "The Girl Is Mine", "Thriller", "Beat It", "Billie Jean"])
        add("Tapestry", "Carole King", 1971, .pop, .lp, "Ode", "SP 77009", .vg, .vg, 8, 18, "Black", .owned, ["I Feel the Earth Move", "So Far Away", "It's Too Late", "Home Again", "You've Got a Friend", "Will You Love Me Tomorrow"])
        add("Blue", "Joni Mitchell", 1971, .folk, .lp, "Reprise", "MS 2038", .vgPlus, .vgPlus, 24, 46, "Black", .owned, ["All I Want", "My Old Man", "Little Green", "Carey", "Blue", "California", "River"])
        add("Pink Moon", "Nick Drake", 1972, .folk, .lp, "Island", "ILPS 9184", .vg, .gPlus, 30, 62, "Black", .owned, ["Pink Moon", "Place to Be", "Road", "Which Will", "Things Behind the Sun", "From the Morning"])
        add("The Köln Concert", "Keith Jarrett", 1975, .classical, .lp, "ECM", "ECM 1064/65", .vgPlus, .vgPlus, 27, 50, "Black", .owned, ["Part I", "Part II a", "Part II b", "Part II c"])
        add("Goldberg Variations", "Glenn Gould", 1981, .classical, .lp, "CBS", "IM 37779", .nearMint, .vgPlus, 22, 42, "Black", .owned, ["Aria", "Variatio 1", "Variatio 5", "Variatio 25", "Aria da Capo"])
        add("Born to Run", "Bruce Springsteen", 1975, .rock, .lp, "Columbia", "PC 33795", .vgPlus, .vg, 16, 28, "Black", .owned, ["Thunder Road", "Tenth Avenue Freeze-Out", "Night", "Backstreets", "Born to Run", "Jungleland"])
        add("Horses", "Patti Smith", 1975, .punk, .lp, "Arista", "AL 4066", .vg, .vg, 19, 36, "Black", .owned, ["Gloria", "Redondo Beach", "Birdland", "Free Money", "Kimberly", "Land", "Elegie"])
        add("London Calling", "The Clash", 1979, .punk, .lp, "CBS", "CLASH 3", .vgPlus, .vgPlus, 21, 40, "Black", .owned, ["London Calling", "Brand New Cadillac", "Jimmy Jazz", "Hateful", "Rudie Can't Fail", "Spanish Bombs"])
        add("Paranoid", "Black Sabbath", 1970, .metal, .lp, "Vertigo", "VO 6", .vg, .gPlus, 25, 55, "Black", .owned, ["War Pigs", "Paranoid", "Planet Caravan", "Iron Man", "Electric Funeral", "Hand of Doom"])
        add("Master of Puppets", "Metallica", 1986, .metal, .lp, "Elektra", "60439-1", .vgPlus, .vg, 23, 48, "Black", .owned, ["Battery", "Master of Puppets", "The Thing That Should Not Be", "Welcome Home", "Disposable Heroes", "Orion"])
        add("Legend", "Bob Marley & The Wailers", 1984, .reggae, .lp, "Island", "BMW 1", .vgPlus, .vgPlus, 14, 24, "Black", .owned, ["Is This Love", "No Woman No Cry", "Could You Be Loved", "Three Little Birds", "Buffalo Soldier", "Jamming", "Redemption Song"])
        add("Catch a Fire", "The Wailers", 1973, .reggae, .lp, "Island", "ILPS 9241", .vg, .vg, 26, 52, "Black", .owned, ["Concrete Jungle", "Slave Driver", "400 Years", "Stop That Train", "Stir It Up", "Kinky Reggae"])
        add("At Folsom Prison", "Johnny Cash", 1968, .country, .lp, "Columbia", "CS 9639", .vgPlus, .vg, 18, 34, "Black", .owned, ["Folsom Prison Blues", "Dark as the Dungeon", "I Still Miss Someone", "Cocaine Blues", "25 Minutes to Go", "Jackson"])
        add("Red Headed Stranger", "Willie Nelson", 1975, .country, .lp, "Columbia", "KC 33482", .vg, .vg, 12, 22, "Black", .owned, ["Time of the Preacher", "Blue Rock Montana", "Blue Eyes Crying in the Rain", "Red Headed Stranger", "Hands on the Wheel"])
        add("Modern Sounds in Country", "Ray Charles", 1962, .soul, .lp, "ABC-Paramount", "ABC-410", .vg, .gPlus, 20, 44, "Black", .owned, ["Bye Bye Love", "You Don't Know Me", "Half as Much", "I Love You So Much", "Just a Little Lovin'", "Born to Lose"])
        add("Buena Vista Social Club", "Buena Vista Social Club", 1997, .world, .twelveInch, "World Circuit", "WCD 050", .nearMint, .nearMint, 24, 46, "Black", .owned, ["Chan Chan", "De Camino a La Vereda", "El Cuarto de Tula", "Pueblo Nuevo", "Dos Gardenias", "Candela"])
        add("Graceland", "Paul Simon", 1986, .world, .lp, "Warner Bros.", "25447-1", .vgPlus, .vgPlus, 13, 24, "Black", .owned, ["The Boy in the Bubble", "Graceland", "I Know What I Know", "Gumboots", "Diamonds on the Soles of Her Shoes", "You Can Call Me Al"])
        add("The Velvet Underground & Nico", "The Velvet Underground", 1967, .rock, .lp, "Verve", "V6-5008", .vg, .gPlus, 38, 95, "Black", .owned, ["Sunday Morning", "I'm Waiting for the Man", "Femme Fatale", "Venus in Furs", "Run Run Run", "Heroin"])
        add("Trout Mask Replica", "Captain Beefheart", 1969, .rock, .lp, "Straight", "STS 1053", .vg, .vg, 33, 70, "Black", .owned, ["Frownland", "The Dust Blows Forward", "Dachau Blues", "Ella Guru", "My Human Gets Me Blues", "Moonlight on Vermont"])
        add("Spiderland", "Slint", 1991, .rock, .lp, "Touch and Go", "TG 64", .nearMint, .nearMint, 29, 58, "Black", .owned, ["Breadcrumb Trail", "Nosferatu Man", "Don, Aman", "Washer", "For Dinner...", "Good Morning, Captain"])
        add("In the Aeroplane Over the Sea", "Neutral Milk Hotel", 1998, .folk, .lp, "Merge", "MRG 136", .nearMint, .vgPlus, 22, 44, "Black", .owned, ["The King of Carrot Flowers", "Holland 1945", "Two-Headed Boy", "The Fool", "Communist Daughter", "Oh Comely"])
        add("OK Computer", "Radiohead", 1997, .rock, .lp, "Parlophone", "NODATA 02", .nearMint, .nearMint, 27, 50, "Black", .owned, ["Airbag", "Paranoid Android", "Subterranean Homesick Alien", "Exit Music", "Let Down", "Karma Police", "No Surprises"])
        add("Either/Or", "Elliott Smith", 1997, .folk, .lp, "Kill Rock Stars", "KRS 269", .vgPlus, .vgPlus, 25, 48, "Clear", .owned, ["Speed Trials", "Alameda", "Ballad of Big Nothing", "Between the Bars", "Pictures of Me", "Angeles", "Say Yes"])
        add("Donuts", "J Dilla", 2006, .hiphop, .twelveInch, "Stones Throw", "STH2126", .nearMint, .nearMint, 26, 52, "Splatter", .owned, ["Donuts (Outro)", "Workinonit", "Waves", "Light My Fire", "The New", "Stop", "Time: The Donut of the Heart"])
        add("Voodoo", "D'Angelo", 2000, .soul, .lp, "Virgin", "7243 8 48499", .vgPlus, .vgPlus, 30, 60, "Black", .owned, ["Playa Playa", "Devil's Pie", "Left & Right", "The Line", "Send It On", "Chicken Grease", "Untitled"])
        add("Aja", "Steely Dan", 1977, .jazz, .lp, "ABC", "AB 1006", .vgPlus, .vg, 17, 32, "Black", .owned, ["Black Cow", "Aja", "Deacon Blues", "Peg", "Home at Last", "I Got the News", "Josie"])
        add("Pet Sounds", "The Beach Boys", 1966, .pop, .lp, "Capitol", "T 2458", .vg, .gPlus, 28, 56, "Black", .owned, ["Wouldn't It Be Nice", "You Still Believe in Me", "Sloop John B", "God Only Knows", "I Know There's an Answer", "Caroline No"])
        add("Hounds of Love", "Kate Bush", 1985, .pop, .lp, "EMI", "KAB 1", .vgPlus, .vgPlus, 23, 46, "Black", .owned, ["Running Up That Hill", "Hounds of Love", "The Big Sky", "Cloudbusting", "And Dream of Sheep", "Jig of Life"])
        add("Remain in Light", "Talking Heads", 1980, .rock, .lp, "Sire", "SRK 6095", .vgPlus, .vgPlus, 20, 40, "Black", .owned, ["Born Under Punches", "Crosseyed and Painless", "The Great Curve", "Once in a Lifetime", "Houses in Motion"])
        add("Music Has the Right to Children", "Boards of Canada", 1998, .electronic, .twelveInch, "Warp", "WARP LP 55", .nearMint, .nearMint, 31, 64, "Black", .owned, ["Wildlife Analysis", "An Eagle in Your Mind", "Telephasic Workshop", "Roygbiv", "Aquarius", "Olson"])
        add("Bitches Brew", "Miles Davis", 1970, .jazz, .lp, "Columbia", "GP 26", .vg, .vg, 26, 50, "Black", .owned, ["Pharaoh's Dance", "Bitches Brew", "Spanish Key", "John McLaughlin", "Miles Runs the Voodoo Down", "Sanctuary"])
        add("Forever Changes", "Love", 1967, .rock, .lp, "Elektra", "EKS-74013", .vg, .vg, 24, 50, "Black", .owned, ["Alone Again Or", "A House Is Not a Motel", "Andmoreagain", "The Daily Planet", "Old Man", "The Red Telephone"])
        add("The Low End Theory", "A Tribe Called Quest", 1991, .hiphop, .lp, "Jive", "1418-1-J", .vgPlus, .vgPlus, 28, 54, "Black", .owned, ["Excursions", "Buggin' Out", "Rap Promoter", "Butter", "Verses from the Abstract", "Check the Rhime", "Scenario"])
        add("Fear of a Black Planet", "Public Enemy", 1990, .hiphop, .lp, "Def Jam", "FC 45413", .vg, .vg, 19, 38, "Black", .owned, ["Brothers Gonna Work It Out", "911 Is a Joke", "Welcome to the Terrordome", "Burn Hollywood Burn", "Fight the Power"])
        add("Stankonia", "OutKast", 2000, .hiphop, .lp, "LaFace", "26072-1", .vgPlus, .vgPlus, 22, 42, "Black", .owned, ["Gasoline Dreams", "So Fresh, So Clean", "Ms. Jackson", "Snappin' & Trappin'", "B.O.B.", "Humble Mumble"])

        // --- Wantlist ---
        add("Maggot Brain (Reissue)", "Funkadelic", 2021, .funk, .lp, "Westbound", "WEW 2007", .mint, .mint, 0, 35, "Green", .wishlist, ["Maggot Brain", "Can You Get to That", "Hit It and Quit It", "Super Stupid"])
        add("Moondance", "Van Morrison", 1970, .rock, .lp, "Warner Bros.", "WS 1835", .nearMint, .nearMint, 0, 30, "Black", .wishlist, ["And It Stoned Me", "Moondance", "Crazy Love", "Caravan", "Into the Mystic"])
        add("Black Saint and the Sinner Lady", "Charles Mingus", 1963, .jazz, .lp, "Impulse!", "A-35", .nearMint, .nearMint, 0, 75, "Black", .wishlist, ["Track A", "Track B", "Track C", "Track D"])
        add("Ege Bamyasi", "Can", 1972, .electronic, .lp, "United Artists", "UAS 29 414", .nearMint, .nearMint, 0, 48, "Black", .wishlist, ["Pinch", "Sing Swan Song", "One More Night", "Vitamin C", "Soup", "I'm So Green", "Spoon"])
        add("Aquemini", "OutKast", 1998, .hiphop, .lp, "LaFace", "26053-1", .mint, .mint, 0, 70, "Black", .wishlist, ["Hold On, Be Strong", "Return of the 'G'", "Rosa Parks", "Skew It on the Bar-B", "Aquemini", "SpottieOttieDopaliscious"])
        add("Songs of Leonard Cohen", "Leonard Cohen", 1967, .folk, .lp, "Columbia", "CL 2733", .nearMint, .nearMint, 0, 32, "Black", .wishlist, ["Suzanne", "Master Song", "Winter Lady", "The Stranger Song", "Sisters of Mercy", "So Long, Marianne"])
        add("Endtroducing.....", "DJ Shadow", 1996, .electronic, .lp, "Mo Wax", "MW 059", .mint, .mint, 0, 55, "Black", .wishlist, ["Best Foot Forward", "Building Steam with a Grain of Salt", "The Number Song", "Stem", "Midnight in a Perfect World", "Organ Donor"])

        return e
    }
}
