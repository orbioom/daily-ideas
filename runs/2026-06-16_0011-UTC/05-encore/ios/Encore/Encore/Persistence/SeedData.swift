import Foundation
import SwiftData

/// Realistic sample concert history for "Load sample data" and #Previews.
/// 50+ shows across many years with setlists, support acts, genres, ratings and prices,
/// plus a handful of upcoming wishlist shows.
enum SeedData {

    /// Seeds only when the store is empty (used on first launch).
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Concert>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        load(context: context)
    }

    /// Inserts the full sample set. Safe to call again — it only adds, it doesn't clear.
    @MainActor
    static func load(context: ModelContext) {
        // Build the shared genre objects first so the many-to-many links reuse them.
        var genreByName: [String: Genre] = [:]
        for entry in GenreCatalog.all where genreByName[entry.name] == nil {
            let g = Genre(name: entry.name, colorSeed: entry.seed)
            genreByName[entry.name] = g
            context.insert(g)
        }
        func genres(_ names: [String]) -> [Genre] {
            names.compactMap { genreByName[$0] }
        }

        let cal = Calendar.current
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: d)) ?? Date(timeIntervalSince1970: 0)
        }
        func future(daysFromNow days: Int) -> Date {
            cal.date(byAdding: .day, value: days, to: Date()) ?? Date().addingTimeInterval(Double(days) * 86_400)
        }

        for fixture in fixtures(date: date, future: future) {
            let c = Concert(headliner: fixture.headliner,
                            date: fixture.date,
                            venueName: fixture.venue,
                            city: fixture.city,
                            country: fixture.country,
                            tourName: fixture.tour,
                            status: fixture.status,
                            type: fixture.type,
                            rating: fixture.rating,
                            ticketPrice: fixture.price,
                            seatInfo: fixture.seat,
                            companions: fixture.companions,
                            notes: fixture.notes,
                            colorSeed: fixture.seed,
                            isFavorite: fixture.favorite)
            c.genres = genres(fixture.genres)
            for (i, name) in fixture.support.enumerated() {
                let act = SupportAct(order: i, name: name)
                act.concert = c
                c.supportActs.append(act)
            }
            for (i, song) in fixture.setlist.enumerated() {
                let s = SetlistSong(order: i,
                                    title: song.0,
                                    isEncore: song.1,
                                    isHighlight: song.2)
                s.concert = c
                c.setlist.append(s)
            }
            context.insert(c)
        }
        try? context.save()
    }

    // MARK: - Fixtures

    private struct Fixture {
        let headliner: String
        let date: Date
        let venue: String
        let city: String
        let country: String
        let tour: String
        let status: ConcertStatus
        let type: ConcertType
        let rating: Double?
        let price: Decimal
        let seat: String
        let companions: String
        let notes: String
        let seed: Int
        let favorite: Bool
        let genres: [String]
        let support: [String]
        /// (title, isEncore, isHighlight)
        let setlist: [(String, Bool, Bool)]
    }

    private static func fixtures(date: (Int, Int, Int) -> Date,
                                 future: (Int) -> Date) -> [Fixture] {
        var f: [Fixture] = []

        func add(_ headliner: String, _ d: Date, _ venue: String, _ city: String, _ country: String,
                 tour: String = "", status: ConcertStatus = .attended, type: ConcertType = .concert,
                 rating: Double? = nil, price: Decimal = 0, seat: String = "", companions: String = "",
                 notes: String = "", seed: Int = 0, favorite: Bool = false,
                 genres: [String] = [], support: [String] = [],
                 setlist: [(String, Bool, Bool)] = []) {
            f.append(Fixture(headliner: headliner, date: d, venue: venue, city: city, country: country,
                             tour: tour, status: status, type: type, rating: rating, price: price,
                             seat: seat, companions: companions, notes: notes, seed: seed,
                             favorite: favorite, genres: genres, support: support, setlist: setlist))
        }

        // A couple of fully-detailed marquee shows (rich setlists + support).
        add("Radiohead", date(2017, 7, 9), "Madison Square Garden", "New York", "USA",
            tour: "A Moon Shaped Pool Tour", rating: 5, price: 145, seat: "Sec 112, Row F",
            companions: "Sam, Priya", notes: "Thom opened solo on piano. Otherworldly light show.",
            seed: 0, favorite: true, genres: ["Alternative", "Rock"],
            support: ["Junun"],
            setlist: [("Daydreaming", false, false), ("Desert Island Disk", false, false),
                      ("Ful Stop", false, true), ("15 Step", false, false),
                      ("Myxomatosis", false, false), ("Lucky", false, false),
                      ("No Surprises", false, false), ("Pyramid Song", false, false),
                      ("Everything in Its Right Place", false, true),
                      ("Idioteque", false, false), ("The National Anthem", false, false),
                      ("Reckoner", false, false), ("Nude", false, false),
                      ("Weird Fishes/Arpeggi", false, true),
                      ("Paranoid Android", true, true), ("Karma Police", true, true),
                      ("Fake Plastic Trees", true, false), ("Street Spirit (Fade Out)", true, true)])

        add("Beyoncé", date(2023, 8, 3), "MetLife Stadium", "East Rutherford", "USA",
            tour: "Renaissance World Tour", rating: 5, price: 220, seat: "Floor GA",
            companions: "Maya", notes: "Silver everything. The chrome horse. Pure spectacle.",
            seed: 2, favorite: true, genres: ["Pop", "R&B"],
            support: [],
            setlist: [("Dangerously in Love", false, false), ("Flaws and All", false, false),
                      ("1+1", false, false), ("I'm Goin' Down", false, false),
                      ("I Care", false, true), ("Cozy", false, false),
                      ("Alien Superstar", false, true), ("Cuff It", false, true),
                      ("Energy", false, false), ("Break My Soul", false, true),
                      ("Formation", false, false), ("Diva", false, false),
                      ("Run the World (Girls)", false, false), ("Crazy in Love", false, true),
                      ("Love On Top", false, true), ("Summer Renaissance", true, true)])

        add("The Strokes", date(2011, 3, 23), "Roseland Ballroom", "New York", "USA",
            tour: "Angles Tour", rating: 4.5, price: 55, seat: "GA",
            companions: "Dev", notes: "Sweaty, loud, perfect comeback show.",
            seed: 4, favorite: false, genres: ["Indie", "Rock", "Alternative"],
            support: ["Cults"],
            setlist: [("Is This It", false, false), ("New York City Cops", false, true),
                      ("Hard to Explain", false, false), ("Someday", false, false),
                      ("Reptilia", false, true), ("Under Cover of Darkness", false, false),
                      ("Last Nite", false, true), ("You Only Live Once", false, false),
                      ("Take It or Leave It", true, true)])

        // The rest fill out a believable, varied history.
        add("Tame Impala", date(2019, 10, 12), "The Forum", "Los Angeles", "USA",
            tour: "The Slow Rush Tour", rating: 4.5, price: 89, seat: "Sec 204",
            companions: "Sam", notes: "Confetti and lasers everywhere.", seed: 3,
            genres: ["Indie", "Electronic"], support: ["Clairo"],
            setlist: [("Let It Happen", false, true), ("Borderline", false, false),
                      ("The Less I Know the Better", false, true), ("Elephant", false, false),
                      ("Feels Like We Only Go Backwards", false, true), ("New Person, Same Old Mistakes", true, false)])

        add("Arctic Monkeys", date(2018, 9, 5), "Alexandra Palace", "London", "UK",
            tour: "Tranquility Base Hotel & Casino", rating: 4, price: 60, seat: "GA",
            companions: "Olu", notes: "Alex in full crooner mode.", seed: 5,
            genres: ["Indie", "Rock"], support: ["Mini Mansions"],
            setlist: [("Four Out of Five", false, false), ("Brianstorm", false, true),
                      ("Crying Lightning", false, false), ("Do I Wanna Know?", false, true),
                      ("505", false, true), ("R U Mine?", true, true)])

        add("Kendrick Lamar", date(2018, 6, 1), "United Center", "Chicago", "USA",
            tour: "The DAMN. Tour", rating: 5, price: 110, seat: "Sec 118",
            companions: "Marcus", notes: "Martial-arts film interludes. Insane energy.",
            seed: 1, favorite: true, genres: ["Hip-Hop"], support: ["Travis Scott"],
            setlist: [("DNA.", false, true), ("ELEMENT.", false, false), ("King Kunta", false, true),
                      ("Swimming Pools (Drank)", false, false), ("HUMBLE.", false, true),
                      ("Alright", true, true)])

        add("Florence + the Machine", date(2015, 9, 27), "Greek Theatre", "Berkeley", "USA",
            tour: "How Big How Blue How Beautiful", rating: 4.5, price: 75, seat: "Terrace",
            companions: "Aisha", notes: "She ran barefoot through the whole crowd.", seed: 6,
            genres: ["Indie", "Pop"], support: ["Of Monsters and Men"],
            setlist: [("What the Water Gave Me", false, false), ("Ship to Wreck", false, false),
                      ("Rabbit Heart", false, true), ("Dog Days Are Over", false, true),
                      ("Shake It Out", true, true)])

        add("Daft Punk", date(2007, 8, 3), "Keyspan Park", "Brooklyn", "USA",
            tour: "Alive 2007", rating: 5, price: 65, seat: "GA",
            companions: "Theo", notes: "The pyramid. Still the best show I've seen.",
            seed: 7, favorite: true, genres: ["Electronic"], support: ["Sebastian"],
            setlist: [("Robot Rock / Oh Yeah", false, true), ("Harder Better Faster Stronger", false, true),
                      ("One More Time", false, true), ("Around the World", false, false),
                      ("Da Funk", true, false)])

        add("The National", date(2013, 6, 5), "Beacon Theatre", "New York", "USA",
            tour: "Trouble Will Find Me", rating: 4, price: 70, seat: "Mezzanine",
            companions: "Lena", notes: "Matt climbed into the balcony.", seed: 0,
            genres: ["Indie", "Alternative"], support: ["This Is the Kit"],
            setlist: [("Don't Swallow the Cap", false, false), ("Bloodbuzz Ohio", false, true),
                      ("I Need My Girl", false, false), ("Fake Empire", false, true),
                      ("Mr. November", true, true), ("Terrible Love", true, false)])

        add("Glass Animals", date(2022, 9, 14), "Red Rocks Amphitheatre", "Morrison", "USA",
            tour: "Dreamland Tour", rating: 4.5, price: 95, seat: "Row 30",
            companions: "Priya", notes: "Red Rocks at sunset. Heat Waves singalong.",
            seed: 2, favorite: true, genres: ["Indie", "Pop", "Electronic"], support: ["beabadoobee"],
            setlist: [("Life Itself", false, false), ("Tangerine", false, false),
                      ("Gooey", false, true), ("Heat Waves", false, true),
                      ("Pork Soda", true, true)])

        // Festivals
        add("Coachella", date(2016, 4, 15), "Empire Polo Club", "Indio", "USA",
            type: .festival, rating: 4, price: 399, seat: "GA Weekend 1",
            companions: "Sam, Dev, Maya", notes: "Saw LCD reunite. Desert dust everywhere.",
            seed: 4, genres: ["Rock", "Electronic", "Indie"],
            support: ["LCD Soundsystem", "Sufjan Stevens", "Disclosure"],
            setlist: [])

        add("Glastonbury", date(2019, 6, 28), "Worthy Farm", "Pilton", "UK",
            type: .festival, rating: 5, price: 280, seat: "Camping",
            companions: "Olu, Lena", notes: "Mud, magic, and The Killers at midnight.",
            seed: 6, favorite: true, genres: ["Rock", "Pop", "Indie"],
            support: ["The Killers", "Stormzy", "The Cure"], setlist: [])

        add("Primavera Sound", date(2022, 6, 3), "Parc del Fòrum", "Barcelona", "Spain",
            type: .festival, rating: 4.5, price: 245, seat: "GA",
            companions: "Theo", notes: "Beach, sea, and Tyler the Creator at 2am.",
            seed: 1, genres: ["Hip-Hop", "Indie", "Electronic"],
            support: ["Tyler, the Creator", "Massive Attack", "Charli XCX"], setlist: [])

        // Single-line variety to reach 50+
        let extras: [(String, Date, String, String, String, Double?, Decimal, Int, [String])] = [
            ("Vampire Weekend", date(2013, 9, 19), "Terminal 5", "New York", "USA", 4.0, 48, 3, ["Indie", "Rock"]),
            ("Bon Iver", date(2017, 9, 22), "Auditorium Theatre", "Chicago", "USA", 4.5, 80, 5, ["Folk", "Indie"]),
            ("LCD Soundsystem", date(2016, 11, 18), "Hollywood Palladium", "Los Angeles", "USA", 4.5, 72, 7, ["Electronic", "Rock"]),
            ("Frank Ocean", date(2017, 8, 1), "FYF Fest", "Los Angeles", "USA", 5.0, 130, 2, ["R&B", "Hip-Hop"]),
            ("St. Vincent", date(2018, 1, 26), "Brooklyn Steel", "Brooklyn", "USA", 4.0, 55, 0, ["Alternative", "Indie"]),
            ("Sigur Rós", date(2013, 3, 24), "United Palace", "New York", "USA", 4.5, 68, 4, ["Alternative"]),
            ("Tyler, the Creator", date(2019, 9, 10), "The Anthem", "Washington", "USA", 4.5, 70, 1, ["Hip-Hop"]),
            ("Phoebe Bridgers", date(2021, 9, 4), "The Greek", "Los Angeles", "USA", 4.5, 60, 6, ["Indie", "Folk"]),
            ("The War on Drugs", date(2018, 2, 2), "The Fillmore", "San Francisco", "USA", 4.0, 50, 3, ["Rock", "Indie"]),
            ("Mac DeMarco", date(2017, 5, 11), "The Observatory", "Santa Ana", "USA", 3.5, 35, 5, ["Indie"]),
            ("Khruangbin", date(2022, 4, 8), "Stubb's", "Austin", "USA", 4.5, 58, 7, ["Indie", "Soul"]),
            ("Mitski", date(2019, 3, 12), "Webster Hall", "New York", "USA", 4.5, 45, 2, ["Indie", "Alternative"]),
            ("Hozier", date(2019, 11, 7), "Radio City Music Hall", "New York", "USA", 4.0, 85, 0, ["Folk", "Soul"]),
            ("FKA twigs", date(2019, 11, 16), "The Wiltern", "Los Angeles", "USA", 4.5, 65, 1, ["R&B", "Electronic"]),
            ("Run the Jewels", date(2017, 1, 14), "Aragon Ballroom", "Chicago", "USA", 4.0, 42, 4, ["Hip-Hop"]),
            ("Father John Misty", date(2017, 4, 21), "The Met", "Philadelphia", "USA", 4.0, 52, 6, ["Folk", "Indie"]),
            ("Janelle Monáe", date(2018, 7, 6), "Fox Theatre", "Oakland", "USA", 4.5, 75, 2, ["R&B", "Pop"]),
            ("Caribou", date(2015, 4, 4), "Terminal 5", "New York", "USA", 4.0, 40, 7, ["Electronic"]),
            ("Sufjan Stevens", date(2015, 5, 9), "Beacon Theatre", "New York", "USA", 5.0, 78, 5, ["Folk", "Indie"]),
            ("Big Thief", date(2022, 2, 19), "Brooklyn Steel", "Brooklyn", "USA", 4.5, 55, 3, ["Folk", "Indie"]),
            ("Jamie xx", date(2015, 10, 2), "Brooklyn Mirage", "Brooklyn", "USA", 4.0, 50, 1, ["Electronic"]),
            ("Anderson .Paak", date(2019, 12, 1), "Hollywood Bowl", "Los Angeles", "USA", 4.5, 95, 4, ["R&B", "Hip-Hop"]),
            ("Lorde", date(2018, 3, 10), "Spark Arena", "Auckland", "New Zealand", 4.5, 88, 6, ["Pop", "Indie"]),
            ("M83", date(2016, 5, 20), "The Greek", "Berkeley", "USA", 4.0, 48, 0, ["Electronic", "Indie"]),
            ("CHVRCHES", date(2018, 10, 18), "The Hollywood Palladium", "Los Angeles", "USA", 4.0, 45, 2, ["Electronic", "Pop"]),
            ("Wolf Alice", date(2022, 3, 30), "The Fonda", "Los Angeles", "USA", 4.0, 42, 5, ["Rock", "Alternative"]),
            ("Japanese Breakfast", date(2021, 10, 8), "Brooklyn Steel", "Brooklyn", "USA", 4.5, 50, 7, ["Indie"]),
            ("IDLES", date(2019, 4, 30), "Terminal 5", "New York", "USA", 4.5, 38, 3, ["Punk", "Rock"]),
            ("Thundercat", date(2017, 6, 28), "The Regency Ballroom", "San Francisco", "USA", 4.0, 44, 1, ["Jazz", "Soul"]),
            ("Kaytranada", date(2019, 11, 22), "Shrine Expo Hall", "Los Angeles", "USA", 4.0, 55, 4, ["Electronic", "Hip-Hop"]),
            ("ODESZA", date(2017, 7, 8), "Bill Graham Civic", "San Francisco", "USA", 4.5, 65, 6, ["Electronic"]),
            ("Foals", date(2016, 9, 30), "Terminal 5", "New York", "USA", 4.0, 46, 2, ["Rock", "Indie"]),
            ("Alt-J", date(2015, 6, 13), "Pier 97", "New York", "USA", 3.5, 50, 0, ["Indie", "Alternative"]),
            ("Disclosure", date(2016, 6, 4), "Bill Graham Civic", "San Francisco", "USA", 4.0, 60, 5, ["Electronic"]),
            ("Snail Mail", date(2019, 2, 16), "Music Hall of Williamsburg", "Brooklyn", "USA", 3.5, 28, 7, ["Indie"]),
            ("Parquet Courts", date(2018, 5, 24), "Brooklyn Steel", "Brooklyn", "USA", 3.5, 32, 3, ["Punk", "Indie"]),
            ("Beach House", date(2018, 11, 9), "The Anthem", "Washington", "USA", 4.0, 48, 1, ["Indie", "Alternative"]),
            ("Charli XCX", date(2022, 11, 19), "Brooklyn Steel", "Brooklyn", "USA", 4.5, 58, 4, ["Pop", "Electronic"]),
            ("Black Midi", date(2022, 10, 5), "Webster Hall", "New York", "USA", 4.0, 35, 6, ["Rock", "Alternative"]),
            ("Toro y Moi", date(2019, 5, 18), "The Novo", "Los Angeles", "USA", 4.0, 40, 2, ["Indie", "Electronic"])
        ]

        for (i, e) in extras.enumerated() {
            let companions = ["Sam", "Maya", "Dev", "Priya", "Theo", "Lena", "Olu", "Marcus", "Aisha"][i % 9]
            add(e.0, e.1, e.2, e.3, e.4, rating: e.5, price: e.6,
                seat: i % 3 == 0 ? "GA" : "Sec \(100 + i)",
                companions: companions,
                notes: "",
                seed: e.7, favorite: e.5 == 5.0, genres: e.8,
                support: [], setlist: [])
        }

        // Upcoming wishlist / bucket-list shows with future dates.
        add("Fontaines D.C.", future(18), "Brooklyn Paramount", "Brooklyn", "USA",
            tour: "Romance Tour", status: .wishlist, rating: nil, price: 65, seat: "GA",
            companions: "Sam", notes: "Been dying to see them live.", seed: 3,
            genres: ["Rock", "Punk", "Indie"], support: [], setlist: [])

        add("Caroline Polachek", future(45), "The Wiltern", "Los Angeles", "USA",
            tour: "Desire Tour", status: .wishlist, rating: nil, price: 58, seat: "Balcony",
            companions: "Maya", notes: "", seed: 1, genres: ["Pop", "Electronic"],
            support: [], setlist: [])

        add("King Gizzard & the Lizard Wizard", future(92), "Hollywood Bowl", "Los Angeles", "USA",
            tour: "Marathon Set", status: .wishlist, rating: nil, price: 78, seat: "Garden Box",
            companions: "Dev, Theo", notes: "3-hour set apparently. Bring water.", seed: 5,
            genres: ["Rock", "Metal", "Alternative"], support: [], setlist: [])

        add("Jamie xx", future(7), "Knockdown Center", "Queens", "USA",
            tour: "In Waves Tour", status: .wishlist, rating: nil, price: 62, seat: "GA",
            companions: "Lena", notes: "All-night warehouse set.", seed: 7,
            genres: ["Electronic"], support: [], setlist: [])

        // A wishlist artist without a date yet (pure bucket-list entry).
        add("Daft Punk (reunion?)", future(365), "TBD", "", "",
            status: .wishlist, rating: nil, price: 0, seat: "",
            companions: "", notes: "If they ever come back.", seed: 0,
            genres: ["Electronic"], support: [], setlist: [])

        return f
    }
}
