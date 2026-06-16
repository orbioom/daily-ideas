import Foundation
import SwiftData

/// Seeds a realistic library of well-known films & TV shows (public facts) plus a spread of
/// diary entries across the past year. Used by "Load sample data" and #Previews.
enum SeedData {

    /// One catalog entry. `episodes`/`seasons` apply to shows; `runtime` is per-episode for shows.
    struct Entry {
        let name: String
        let year: Int
        let kind: TitleKind
        let genres: [Genre]
        let runtime: Int          // minutes (per-episode for shows)
        let creator: String
        let status: WatchStatus
        let rating: Double?
        let favorite: Bool
        let episodes: Int
        let seasons: Int
        let synopsis: String

        init(_ name: String, _ year: Int, _ kind: TitleKind, _ genres: [Genre],
             _ runtime: Int, _ creator: String, _ status: WatchStatus,
             _ rating: Double?, favorite: Bool = false,
             episodes: Int = 0, seasons: Int = 0, _ synopsis: String = "") {
            self.name = name; self.year = year; self.kind = kind; self.genres = genres
            self.runtime = runtime; self.creator = creator; self.status = status
            self.rating = rating; self.favorite = favorite
            self.episodes = episodes; self.seasons = seasons; self.synopsis = synopsis
        }
    }

    // MARK: - Public API

    @MainActor
    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertAll(into: context)
        didSeed = true
    }

    /// Force a fresh seed (used by Settings "Load sample data"). Returns inserted count.
    @MainActor
    @discardableResult
    static func loadSample(into context: ModelContext) -> Int {
        insertAll(into: context)
    }

    @MainActor
    @discardableResult
    private static func insertAll(into context: ModelContext) -> Int {
        let entries = catalog()
        let calendar = Calendar.current
        let now = Date()
        var inserted: [Title] = []

        for (i, e) in entries.enumerated() {
            let title = Title(name: e.name,
                              year: e.year,
                              kind: e.kind,
                              genres: e.genres.map { $0.rawValue },
                              synopsis: e.synopsis,
                              runtimeMinutes: e.runtime,
                              creator: e.creator,
                              status: e.status,
                              rating: e.rating,
                              isFavorite: e.favorite,
                              colorSeed: i * 7 + e.year,
                              addedDate: now.addingTimeInterval(Double(-i) * 36_000),
                              totalEpisodes: e.episodes,
                              watchedEpisodes: showWatchedEpisodes(for: e),
                              totalSeasons: e.seasons)
            context.insert(title)
            inserted.append(title)
        }

        // Diary entries: spread ~32 across the past year on watched titles.
        attachDiary(to: inserted, calendar: calendar, now: now, context: context)

        try? context.save()
        return inserted.count
    }

    // MARK: - Diary

    @MainActor
    private static func attachDiary(to titles: [Title],
                                    calendar: Calendar,
                                    now: Date,
                                    context: ModelContext) {
        // Choose watched titles deterministically and back-date entries over ~365 days.
        let watched = titles.filter { $0.status == .watched }
        guard !watched.isEmpty else { return }

        let reviews = [
            "An absolute classic. Holds up beautifully.",
            "Even better on a rewatch — caught so many details.",
            "Stunning cinematography, lost in it the whole time.",
            "Slow start but the payoff is worth every minute.",
            "Comfort watch. Put it on after a long week.",
            "The ending wrecked me in the best way.",
            "Performances carried this entirely.",
            "Not my favorite, but I get the hype now.",
            "Watched with friends — instant good night.",
            "Tighter than I remembered. No wasted scene.",
            "The score alone deserves an award.",
            "A near-perfect blend of tension and heart."
        ]

        // Deterministic day offsets across the year so months are well covered.
        let dayOffsets = [3, 12, 21, 34, 45, 58, 67, 79, 92, 104, 118, 131,
                          145, 159, 172, 186, 199, 213, 228, 240, 255, 269,
                          283, 297, 310, 322, 336, 347, 355, 360, 8, 41]

        var count = 0
        for offset in dayOffsets {
            let title = watched[count % watched.count]
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let baseRating = title.rating ?? 3.5
            let jitter = (count % 3 == 0) ? -0.5 : (count % 5 == 0 ? 0.5 : 0)
            let rating = min(5, max(0.5, baseRating + jitter))
            let entry = DiaryEntry(watchedDate: date,
                                   rating: rating,
                                   review: reviews[count % reviews.count],
                                   isRewatch: count % 4 == 0)
            entry.title = title
            title.entries.append(entry)
            context.insert(entry)
            count += 1
        }
    }

    private static func showWatchedEpisodes(for e: Entry) -> Int {
        guard e.kind.isShow, e.episodes > 0 else { return 0 }
        switch e.status {
        case .watched: return e.episodes
        case .watching: return max(1, e.episodes / 2)
        case .abandoned: return max(1, e.episodes / 5)
        case .watchlist: return 0
        }
    }

    // MARK: - Catalog (50+ real titles, public facts)

    static func catalog() -> [Entry] {
        [
            // Films — watched & rated
            Entry("The Godfather", 1972, .movie, [.crime, .drama], 175, "Francis Ford Coppola", .watched, 5.0, favorite: true,
                  "The aging patriarch of a crime dynasty transfers control to his reluctant son."),
            Entry("Pulp Fiction", 1994, .movie, [.crime, .drama], 154, "Quentin Tarantino", .watched, 4.5, favorite: true,
                  "Interwoven tales of mob hitmen, a boxer, and a pair of diner robbers."),
            Entry("The Dark Knight", 2008, .movie, [.action, .crime, .thriller], 152, "Christopher Nolan", .watched, 5.0, favorite: true,
                  "Batman faces the Joker, a criminal who plunges Gotham into anarchy."),
            Entry("Parasite", 2019, .movie, [.thriller, .drama, .comedy], 132, "Bong Joon-ho", .watched, 5.0, favorite: true,
                  "A poor family schemes to become employed by a wealthy household."),
            Entry("Spirited Away", 2001, .movie, [.animation, .fantasy, .adventure], 125, "Hayao Miyazaki", .watched, 4.5, favorite: true,
                  "A girl wanders into a world of spirits and must work to free her parents."),
            Entry("Inception", 2010, .movie, [.action, .sciFi, .thriller], 148, "Christopher Nolan", .watched, 4.5,
                  "A thief who steals secrets through dream-sharing is offered a chance to erase his past."),
            Entry("Goodfellas", 1990, .movie, [.crime, .drama], 145, "Martin Scorsese", .watched, 4.5,
                  "The rise and fall of a mob associate over three decades."),
            Entry("Whiplash", 2014, .movie, [.drama], 106, "Damien Chazelle", .watched, 5.0,
                  "A young drummer enrolls at a cut-throat music conservatory."),
            Entry("Mad Max: Fury Road", 2015, .movie, [.action, .adventure, .sciFi], 120, "George Miller", .watched, 4.5,
                  "In a post-apocalyptic wasteland, a woman rebels against a tyrannical ruler."),
            Entry("The Shawshank Redemption", 1994, .movie, [.drama], 142, "Frank Darabont", .watched, 5.0, favorite: true,
                  "Two imprisoned men bond over years, finding solace and eventual redemption."),
            Entry("Alien", 1979, .movie, [.horror, .sciFi], 117, "Ridley Scott", .watched, 4.5,
                  "A spacecraft crew is hunted by a deadly extraterrestrial."),
            Entry("Blade Runner 2049", 2017, .movie, [.sciFi, .drama, .mystery], 164, "Denis Villeneuve", .watched, 4.5,
                  "A new blade runner unearths a secret that could plunge society into chaos."),
            Entry("Get Out", 2017, .movie, [.horror, .mystery, .thriller], 104, "Jordan Peele", .watched, 4.5,
                  "A young man visits his girlfriend's family estate and uncovers a sinister truth."),
            Entry("La La Land", 2016, .movie, [.romance, .drama, .comedy], 128, "Damien Chazelle", .watched, 4.0,
                  "A jazz musician and an aspiring actress fall in love in Los Angeles."),
            Entry("The Grand Budapest Hotel", 2014, .movie, [.comedy, .adventure, .crime], 99, "Wes Anderson", .watched, 4.0,
                  "A legendary concierge and his protégé become embroiled in a theft."),
            Entry("Spider-Man: Into the Spider-Verse", 2018, .movie, [.animation, .action, .adventure], 117, "Bob Persichetti", .watched, 5.0, favorite: true,
                  "Teen Miles Morales becomes Spider-Man and joins others from across dimensions."),
            Entry("Everything Everywhere All at Once", 2022, .movie, [.sciFi, .comedy, .action], 139, "Daniel Kwan", .watched, 5.0,
                  "A laundromat owner is swept into a multiverse-spanning adventure."),
            Entry("Dune", 2021, .movie, [.sciFi, .adventure, .drama], 155, "Denis Villeneuve", .watched, 4.5,
                  "A noble family becomes embroiled in a war over a desert planet's precious resource."),
            Entry("No Country for Old Men", 2007, .movie, [.crime, .thriller, .drama], 122, "Joel & Ethan Coen", .watched, 4.5,
                  "A hunter stumbles on drug-deal money and is pursued by a relentless killer."),
            Entry("The Social Network", 2010, .movie, [.drama], 120, "David Fincher", .watched, 4.0,
                  "The founding of Facebook and the lawsuits that followed."),
            Entry("Coco", 2017, .movie, [.animation, .adventure, .fantasy], 105, "Lee Unkrich", .watched, 4.5,
                  "A boy travels to the Land of the Dead to uncover his family's history."),
            Entry("Knives Out", 2019, .movie, [.crime, .mystery, .comedy], 130, "Rian Johnson", .watched, 4.0,
                  "A detective investigates the death of a wealthy crime novelist."),
            Entry("Heat", 1995, .movie, [.crime, .action, .thriller], 170, "Michael Mann", .watched, 4.5,
                  "A career thief and a determined detective face off across Los Angeles."),
            Entry("Arrival", 2016, .movie, [.sciFi, .drama, .mystery], 116, "Denis Villeneuve", .watched, 4.5,
                  "A linguist works to communicate with alien visitors."),
            Entry("Oldboy", 2003, .movie, [.thriller, .mystery, .action], 120, "Park Chan-wook", .watched, 4.5,
                  "A man seeks answers after being imprisoned for fifteen years without explanation."),
            Entry("The Lord of the Rings: The Fellowship of the Ring", 2001, .movie, [.fantasy, .adventure], 178, "Peter Jackson", .watched, 5.0, favorite: true,
                  "A hobbit sets out to destroy a powerful ring and the dark lord who seeks it."),
            Entry("Jaws", 1975, .movie, [.thriller, .horror, .adventure], 124, "Steven Spielberg", .watched, 4.0,
                  "A police chief hunts a great white shark terrorizing a beach town."),
            Entry("Toy Story", 1995, .movie, [.animation, .adventure, .comedy], 81, "John Lasseter", .watched, 4.5,
                  "A cowboy doll is threatened by a new spaceman figure in a boy's room."),

            // Films — watchlist / watching / abandoned
            Entry("Oppenheimer", 2023, .movie, [.drama, .thriller], 180, "Christopher Nolan", .watchlist, nil,
                  "The story of J. Robert Oppenheimer and the making of the atomic bomb."),
            Entry("Past Lives", 2023, .movie, [.romance, .drama], 105, "Celine Song", .watchlist, nil,
                  "Two childhood friends reconnect across decades and continents."),
            Entry("Poor Things", 2023, .movie, [.comedy, .drama, .sciFi], 141, "Yorgos Lanthimos", .watchlist, nil,
                  "A young woman brought back to life embarks on an odyssey of self-discovery."),
            Entry("The Holdovers", 2023, .movie, [.comedy, .drama], 133, "Alexander Payne", .watchlist, nil,
                  "A curmudgeonly teacher is stuck on campus over the holidays with a student."),
            Entry("The Lighthouse", 2019, .movie, [.horror, .drama, .mystery], 109, "Robert Eggers", .watchlist, nil,
                  "Two lighthouse keepers descend into madness on a remote island."),
            Entry("Memories of Murder", 2003, .movie, [.crime, .drama, .thriller], 132, "Bong Joon-ho", .watchlist, nil,
                  "Detectives hunt a serial killer in 1980s South Korea."),
            Entry("Portrait of a Lady on Fire", 2019, .movie, [.romance, .drama], 122, "Céline Sciamma", .watchlist, nil,
                  "A painter falls for the woman she is secretly commissioned to paint."),
            Entry("Tenet", 2020, .movie, [.action, .sciFi, .thriller], 150, "Christopher Nolan", .abandoned, 2.5,
                  "A secret agent manipulates the flow of time to prevent World War III."),

            // TV shows — watched / watching / watchlist / abandoned
            Entry("Breaking Bad", 2008, .tvShow, [.crime, .drama, .thriller], 47, "Vince Gilligan", .watched, 5.0, favorite: true,
                  episodes: 62, seasons: 5,
                  "A chemistry teacher turns to manufacturing meth after a cancer diagnosis."),
            Entry("The Sopranos", 1999, .tvShow, [.crime, .drama], 55, "David Chase", .watched, 5.0, favorite: true,
                  episodes: 86, seasons: 6,
                  "A New Jersey mob boss juggles family and a crime family in therapy."),
            Entry("The Wire", 2002, .tvShow, [.crime, .drama], 59, "David Simon", .watched, 5.0,
                  episodes: 60, seasons: 5,
                  "The drug trade in Baltimore seen from many interconnected angles."),
            Entry("Chernobyl", 2019, .tvShow, [.drama, .thriller], 67, "Craig Mazin", .watched, 5.0,
                  episodes: 5, seasons: 1,
                  "The 1986 nuclear disaster and the people who responded to it."),
            Entry("Fleabag", 2016, .tvShow, [.comedy, .drama], 27, "Phoebe Waller-Bridge", .watched, 5.0, favorite: true,
                  episodes: 12, seasons: 2,
                  "A sharp, grief-stricken woman navigates life and love in London."),
            Entry("The Bear", 2022, .tvShow, [.comedy, .drama], 30, "Christopher Storer", .watching, 4.5,
                  episodes: 28, seasons: 3,
                  "A fine-dining chef returns home to run his family's sandwich shop."),
            Entry("Succession", 2018, .tvShow, [.drama, .comedy], 60, "Jesse Armstrong", .watching, 4.5,
                  episodes: 39, seasons: 4,
                  "A media dynasty's children vie to succeed their ailing father."),
            Entry("Better Call Saul", 2015, .tvShow, [.crime, .drama], 46, "Vince Gilligan", .watched, 4.5,
                  episodes: 63, seasons: 6,
                  "A small-time lawyer's transformation into a morally flexible attorney."),
            Entry("Severance", 2022, .tvShow, [.sciFi, .thriller, .drama], 50, "Dan Erickson", .watching, 4.5,
                  episodes: 19, seasons: 2,
                  "Office workers surgically divide their work and personal memories."),
            Entry("The Last of Us", 2023, .tvShow, [.drama, .horror, .action], 55, "Craig Mazin", .watching, 4.5,
                  episodes: 9, seasons: 1,
                  "A smuggler escorts a teenage girl across a fungal-ravaged America."),
            Entry("Stranger Things", 2016, .tvShow, [.sciFi, .horror, .drama], 50, "The Duffer Brothers", .watched, 4.0,
                  episodes: 42, seasons: 4,
                  "Kids in a small town confront supernatural forces and secret experiments."),
            Entry("Game of Thrones", 2011, .tvShow, [.fantasy, .drama, .adventure], 57, "Benioff & Weiss", .watched, 4.0,
                  episodes: 73, seasons: 8,
                  "Noble families vie for control of the Iron Throne of Westeros."),
            Entry("True Detective", 2014, .tvShow, [.crime, .drama, .mystery], 55, "Nic Pizzolatto", .watched, 4.5,
                  episodes: 8, seasons: 1,
                  "Two detectives' hunt for a killer spans seventeen years."),
            Entry("Mad Men", 2007, .tvShow, [.drama], 47, "Matthew Weiner", .watchlist, nil,
                  episodes: 92, seasons: 7,
                  "Advertising executives navigate the changing culture of 1960s New York."),
            Entry("Arcane", 2021, .tvShow, [.animation, .action, .fantasy], 42, "Christian Linke", .watchlist, nil,
                  episodes: 18, seasons: 2,
                  "Two sisters end up on opposite sides of a brewing conflict between cities."),
            Entry("Dark", 2017, .tvShow, [.sciFi, .mystery, .thriller], 53, "Baran bo Odar", .watchlist, nil,
                  episodes: 26, seasons: 3,
                  "Four families unravel a time-travel mystery in a German town."),
            Entry("Twin Peaks", 1990, .tvShow, [.mystery, .drama, .horror], 47, "David Lynch", .watchlist, nil,
                  episodes: 30, seasons: 2,
                  "An FBI agent investigates the murder of a homecoming queen."),
            Entry("Westworld", 2016, .tvShow, [.sciFi, .drama, .western], 60, "Jonathan Nolan", .abandoned, 3.0,
                  episodes: 36, seasons: 4,
                  "A futuristic theme park populated by lifelike androids begins to malfunction."),
            Entry("The Crown", 2016, .tvShow, [.drama], 58, "Peter Morgan", .watchlist, nil,
                  episodes: 60, seasons: 6,
                  "The reign of Queen Elizabeth II from the 1940s onward.")
        ]
    }
}
