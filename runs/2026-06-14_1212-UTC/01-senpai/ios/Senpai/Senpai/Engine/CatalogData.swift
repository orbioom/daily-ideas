import Foundation

/// One offline catalog entry — a well-known title with sensible defaults.
struct CatalogEntry: Identifiable, Hashable {
    let name: String
    let kind: AnimeMediaKind
    let defaultUnits: Int          // episodes (anime) or chapters (manga)
    let studioOrAuthor: String
    let genres: [String]           // 1–3 genre names
    let season: AnimeSeason?
    let year: Int

    var id: String { name + kind.rawValue }

    var seasonLabel: String? {
        guard let season else { return nil }
        return "\(season.rawValue) \(year)"
    }
}

/// A hard-coded, offline catalog of ~60 widely-known titles for friction-free quick-add.
enum CatalogData {

    /// Grouping key for the Browse screen (kind, then year descending).
    static let all: [CatalogEntry] = anime + manga

    static let anime: [CatalogEntry] = [
        CatalogEntry(name: "Fullmetal Alchemist: Brotherhood", kind: .anime, defaultUnits: 64, studioOrAuthor: "Bones", genres: ["Action", "Adventure", "Fantasy"], season: .spring, year: 2009),
        CatalogEntry(name: "Attack on Titan", kind: .anime, defaultUnits: 25, studioOrAuthor: "Wit Studio", genres: ["Action", "Drama", "Fantasy"], season: .spring, year: 2013),
        CatalogEntry(name: "Death Note", kind: .anime, defaultUnits: 37, studioOrAuthor: "Madhouse", genres: ["Mystery", "Thriller", "Psychological"], season: .fall, year: 2006),
        CatalogEntry(name: "Steins;Gate", kind: .anime, defaultUnits: 24, studioOrAuthor: "White Fox", genres: ["Sci-Fi", "Thriller", "Drama"], season: .spring, year: 2011),
        CatalogEntry(name: "Demon Slayer", kind: .anime, defaultUnits: 26, studioOrAuthor: "ufotable", genres: ["Action", "Supernatural", "Shounen"], season: .spring, year: 2019),
        CatalogEntry(name: "Jujutsu Kaisen", kind: .anime, defaultUnits: 24, studioOrAuthor: "MAPPA", genres: ["Action", "Supernatural", "Shounen"], season: .fall, year: 2020),
        CatalogEntry(name: "My Hero Academia", kind: .anime, defaultUnits: 13, studioOrAuthor: "Bones", genres: ["Action", "Shounen", "Adventure"], season: .spring, year: 2016),
        CatalogEntry(name: "One Punch Man", kind: .anime, defaultUnits: 12, studioOrAuthor: "Madhouse", genres: ["Action", "Comedy", "Supernatural"], season: .fall, year: 2015),
        CatalogEntry(name: "Hunter x Hunter", kind: .anime, defaultUnits: 148, studioOrAuthor: "Madhouse", genres: ["Action", "Adventure", "Shounen"], season: .fall, year: 2011),
        CatalogEntry(name: "Cowboy Bebop", kind: .anime, defaultUnits: 26, studioOrAuthor: "Sunrise", genres: ["Action", "Sci-Fi", "Drama"], season: .spring, year: 1998),
        CatalogEntry(name: "Neon Genesis Evangelion", kind: .anime, defaultUnits: 26, studioOrAuthor: "Gainax", genres: ["Mecha", "Psychological", "Sci-Fi"], season: .fall, year: 1995),
        CatalogEntry(name: "Code Geass", kind: .anime, defaultUnits: 25, studioOrAuthor: "Sunrise", genres: ["Mecha", "Drama", "Thriller"], season: .fall, year: 2006),
        CatalogEntry(name: "Spy x Family", kind: .anime, defaultUnits: 25, studioOrAuthor: "Wit / CloverWorks", genres: ["Action", "Comedy", "Slice of Life"], season: .spring, year: 2022),
        CatalogEntry(name: "Chainsaw Man", kind: .anime, defaultUnits: 12, studioOrAuthor: "MAPPA", genres: ["Action", "Supernatural", "Shounen"], season: .fall, year: 2022),
        CatalogEntry(name: "Vinland Saga", kind: .anime, defaultUnits: 24, studioOrAuthor: "Wit Studio", genres: ["Action", "Adventure", "Drama"], season: .summer, year: 2019),
        CatalogEntry(name: "Mob Psycho 100", kind: .anime, defaultUnits: 12, studioOrAuthor: "Bones", genres: ["Action", "Supernatural", "Comedy"], season: .summer, year: 2016),
        CatalogEntry(name: "Your Lie in April", kind: .anime, defaultUnits: 22, studioOrAuthor: "A-1 Pictures", genres: ["Drama", "Romance", "Music"], season: .fall, year: 2014),
        CatalogEntry(name: "Violet Evergarden", kind: .anime, defaultUnits: 13, studioOrAuthor: "Kyoto Animation", genres: ["Drama", "Slice of Life"], season: .winter, year: 2018),
        CatalogEntry(name: "A Silent Voice", kind: .anime, defaultUnits: 1, studioOrAuthor: "Kyoto Animation", genres: ["Drama", "Romance"], season: .summer, year: 2016),
        CatalogEntry(name: "Spirited Away", kind: .anime, defaultUnits: 1, studioOrAuthor: "Studio Ghibli", genres: ["Adventure", "Fantasy", "Supernatural"], season: .summer, year: 2001),
        CatalogEntry(name: "Re:Zero", kind: .anime, defaultUnits: 25, studioOrAuthor: "White Fox", genres: ["Isekai", "Fantasy", "Thriller"], season: .spring, year: 2016),
        CatalogEntry(name: "Sword Art Online", kind: .anime, defaultUnits: 25, studioOrAuthor: "A-1 Pictures", genres: ["Isekai", "Action", "Romance"], season: .summer, year: 2012),
        CatalogEntry(name: "No Game No Life", kind: .anime, defaultUnits: 12, studioOrAuthor: "Madhouse", genres: ["Isekai", "Comedy", "Fantasy"], season: .spring, year: 2014),
        CatalogEntry(name: "Konosuba", kind: .anime, defaultUnits: 10, studioOrAuthor: "Studio Deen", genres: ["Isekai", "Comedy", "Fantasy"], season: .winter, year: 2016),
        CatalogEntry(name: "The Eminence in Shadow", kind: .anime, defaultUnits: 20, studioOrAuthor: "Nexus", genres: ["Isekai", "Action", "Comedy"], season: .fall, year: 2022),
        CatalogEntry(name: "Gurren Lagann", kind: .anime, defaultUnits: 27, studioOrAuthor: "Gainax", genres: ["Mecha", "Action", "Adventure"], season: .spring, year: 2007),
        CatalogEntry(name: "Made in Abyss", kind: .anime, defaultUnits: 13, studioOrAuthor: "Kinema Citrus", genres: ["Adventure", "Fantasy", "Drama"], season: .summer, year: 2017),
        CatalogEntry(name: "Haikyuu!!", kind: .anime, defaultUnits: 25, studioOrAuthor: "Production I.G", genres: ["Sports", "Comedy", "Drama"], season: .spring, year: 2014),
        CatalogEntry(name: "Bocchi the Rock!", kind: .anime, defaultUnits: 12, studioOrAuthor: "CloverWorks", genres: ["Comedy", "Music", "Slice of Life"], season: .fall, year: 2022),
        CatalogEntry(name: "K-On!", kind: .anime, defaultUnits: 13, studioOrAuthor: "Kyoto Animation", genres: ["Music", "Comedy", "Slice of Life"], season: .spring, year: 2009),
        CatalogEntry(name: "Toradora!", kind: .anime, defaultUnits: 25, studioOrAuthor: "J.C.Staff", genres: ["Romance", "Comedy", "Drama"], season: .fall, year: 2008),
        CatalogEntry(name: "Clannad: After Story", kind: .anime, defaultUnits: 24, studioOrAuthor: "Kyoto Animation", genres: ["Drama", "Romance", "Slice of Life"], season: .fall, year: 2008),
        CatalogEntry(name: "Frieren: Beyond Journey's End", kind: .anime, defaultUnits: 28, studioOrAuthor: "Madhouse", genres: ["Adventure", "Fantasy", "Drama"], season: .fall, year: 2023),
        CatalogEntry(name: "Bleach", kind: .anime, defaultUnits: 366, studioOrAuthor: "Studio Pierrot", genres: ["Action", "Supernatural", "Shounen"], season: .fall, year: 2004),
        CatalogEntry(name: "Naruto", kind: .anime, defaultUnits: 220, studioOrAuthor: "Studio Pierrot", genres: ["Action", "Adventure", "Shounen"], season: .fall, year: 2002),
        CatalogEntry(name: "Tokyo Ghoul", kind: .anime, defaultUnits: 12, studioOrAuthor: "Studio Pierrot", genres: ["Action", "Horror", "Supernatural"], season: .summer, year: 2014)
    ]

    static let manga: [CatalogEntry] = [
        CatalogEntry(name: "Berserk", kind: .manga, defaultUnits: 374, studioOrAuthor: "Kentaro Miura", genres: ["Action", "Horror", "Seinen"], season: nil, year: 1989),
        CatalogEntry(name: "One Piece", kind: .manga, defaultUnits: 1100, studioOrAuthor: "Eiichiro Oda", genres: ["Action", "Adventure", "Shounen"], season: nil, year: 1997),
        CatalogEntry(name: "Vagabond", kind: .manga, defaultUnits: 327, studioOrAuthor: "Takehiko Inoue", genres: ["Action", "Drama", "Seinen"], season: nil, year: 1998),
        CatalogEntry(name: "Vinland Saga", kind: .manga, defaultUnits: 210, studioOrAuthor: "Makoto Yukimura", genres: ["Action", "Adventure", "Seinen"], season: nil, year: 2005),
        CatalogEntry(name: "Monster", kind: .manga, defaultUnits: 162, studioOrAuthor: "Naoki Urasawa", genres: ["Mystery", "Thriller", "Seinen"], season: nil, year: 1994),
        CatalogEntry(name: "Slam Dunk", kind: .manga, defaultUnits: 276, studioOrAuthor: "Takehiko Inoue", genres: ["Sports", "Comedy", "Drama"], season: nil, year: 1990),
        CatalogEntry(name: "Fullmetal Alchemist", kind: .manga, defaultUnits: 116, studioOrAuthor: "Hiromu Arakawa", genres: ["Action", "Adventure", "Fantasy"], season: nil, year: 2001),
        CatalogEntry(name: "Chainsaw Man", kind: .manga, defaultUnits: 160, studioOrAuthor: "Tatsuki Fujimoto", genres: ["Action", "Supernatural", "Shounen"], season: nil, year: 2018),
        CatalogEntry(name: "Jujutsu Kaisen", kind: .manga, defaultUnits: 271, studioOrAuthor: "Gege Akutami", genres: ["Action", "Supernatural", "Shounen"], season: nil, year: 2018),
        CatalogEntry(name: "Demon Slayer", kind: .manga, defaultUnits: 205, studioOrAuthor: "Koyoharu Gotouge", genres: ["Action", "Supernatural", "Shounen"], season: nil, year: 2016),
        CatalogEntry(name: "Attack on Titan", kind: .manga, defaultUnits: 139, studioOrAuthor: "Hajime Isayama", genres: ["Action", "Drama", "Fantasy"], season: nil, year: 2009),
        CatalogEntry(name: "Death Note", kind: .manga, defaultUnits: 108, studioOrAuthor: "Tsugumi Ohba", genres: ["Mystery", "Thriller", "Psychological"], season: nil, year: 2003),
        CatalogEntry(name: "Naruto", kind: .manga, defaultUnits: 700, studioOrAuthor: "Masashi Kishimoto", genres: ["Action", "Adventure", "Shounen"], season: nil, year: 1999),
        CatalogEntry(name: "Bleach", kind: .manga, defaultUnits: 686, studioOrAuthor: "Tite Kubo", genres: ["Action", "Supernatural", "Shounen"], season: nil, year: 2001),
        CatalogEntry(name: "Hunter x Hunter", kind: .manga, defaultUnits: 400, studioOrAuthor: "Yoshihiro Togashi", genres: ["Action", "Adventure", "Shounen"], season: nil, year: 1998),
        CatalogEntry(name: "Spy x Family", kind: .manga, defaultUnits: 100, studioOrAuthor: "Tatsuya Endo", genres: ["Action", "Comedy", "Slice of Life"], season: nil, year: 2019),
        CatalogEntry(name: "Tokyo Ghoul", kind: .manga, defaultUnits: 143, studioOrAuthor: "Sui Ishida", genres: ["Action", "Horror", "Supernatural"], season: nil, year: 2011),
        CatalogEntry(name: "Oyasumi Punpun", kind: .manga, defaultUnits: 147, studioOrAuthor: "Inio Asano", genres: ["Drama", "Psychological", "Seinen"], season: nil, year: 2007),
        CatalogEntry(name: "Solo Leveling", kind: .manga, defaultUnits: 179, studioOrAuthor: "Chugong", genres: ["Action", "Fantasy", "Adventure"], season: nil, year: 2018),
        CatalogEntry(name: "The Promised Neverland", kind: .manga, defaultUnits: 181, studioOrAuthor: "Kaiu Shirai", genres: ["Mystery", "Thriller", "Shounen"], season: nil, year: 2016),
        CatalogEntry(name: "Dragon Ball", kind: .manga, defaultUnits: 519, studioOrAuthor: "Akira Toriyama", genres: ["Action", "Adventure", "Shounen"], season: nil, year: 1984),
        CatalogEntry(name: "Kaguya-sama: Love Is War", kind: .manga, defaultUnits: 281, studioOrAuthor: "Aka Akasaka", genres: ["Romance", "Comedy", "Psychological"], season: nil, year: 2015),
        CatalogEntry(name: "Fruits Basket", kind: .manga, defaultUnits: 136, studioOrAuthor: "Natsuki Takaya", genres: ["Romance", "Drama", "Shoujo"], season: nil, year: 1998),
        CatalogEntry(name: "Nana", kind: .manga, defaultUnits: 84, studioOrAuthor: "Ai Yazawa", genres: ["Romance", "Drama", "Shoujo"], season: nil, year: 2000),
        CatalogEntry(name: "Blue Lock", kind: .manga, defaultUnits: 270, studioOrAuthor: "Muneyuki Kaneshiro", genres: ["Sports", "Drama", "Shounen"], season: nil, year: 2018)
    ]
}
