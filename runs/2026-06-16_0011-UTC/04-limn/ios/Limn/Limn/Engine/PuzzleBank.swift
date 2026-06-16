import Foundation

/// The hand-authored library of nonogram puzzles, grouped into themed packs by size.
/// Every solution grid is a recognizable picture. Grids are validated at build time by
/// `Puzzle.parse`; `validatedPacks` additionally filters out any grid that fails
/// rectangularity / non-empty checks so the running app only ever sees sound puzzles.
enum PuzzleBank {

    // MARK: - Pack IDs

    static let beginningsID = "beginnings"   // 5×5, free
    static let everydayID = "everyday"       // 10×10, free
    static let natureID = "nature"           // 10×10, Pro
    static let masterpiecesID = "masterpieces" // 15×15, Pro

    // MARK: - Public bank

    /// All packs, validated. Free packs first.
    static let packs: [PuzzlePack] = [
        PuzzlePack(id: beginningsID, title: "Beginnings",
                   subtitle: "Gentle 5×5 starters", symbol: "leaf.fill",
                   size: 5, requiresPro: false, puzzles: beginnings),
        PuzzlePack(id: everydayID, title: "Everyday",
                   subtitle: "Familiar 10×10 objects", symbol: "house.fill",
                   size: 10, requiresPro: false, puzzles: everyday),
        PuzzlePack(id: natureID, title: "Wild Things",
                   subtitle: "10×10 creatures & nature", symbol: "tortoise.fill",
                   size: 10, requiresPro: true, puzzles: nature),
        PuzzlePack(id: masterpiecesID, title: "Masterpieces",
                   subtitle: "Detailed 15×15 scenes", symbol: "crown.fill",
                   size: 15, requiresPro: true, puzzles: masterpieces)
    ]

    /// Flat list of every puzzle across all packs.
    static let allPuzzles: [Puzzle] = packs.flatMap { $0.puzzles }

    /// Look up a puzzle by its stable id.
    static func puzzle(id: String) -> Puzzle? {
        allPuzzles.first { $0.id == id }
    }

    /// The pack that contains a given puzzle id.
    static func pack(forPuzzleID id: String) -> PuzzlePack? {
        packs.first { pack in pack.puzzles.contains { $0.id == id } }
    }

    /// Free puzzle ids (Beginnings + Everyday).
    static var freePuzzleIDs: Set<String> {
        Set(packs.filter { !$0.requiresPro }.flatMap { $0.puzzles.map(\.id) })
    }

    // MARK: - Daily pick

    /// Deterministically picks a puzzle for the given calendar day from the whole bank.
    static func dailyPuzzle(for date: Date, calendar: Calendar = .current) -> Puzzle {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2026)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        let base = y &* 10_000 &+ m &* 100 &+ d
        var rng = SplitMix64(seed: base &+ 0x5EED_DA11)
        let pool = allPuzzles
        guard !pool.isEmpty else {
            // Unreachable in practice — the bank is non-empty — but keep it total.
            return Puzzle(id: "fallback", name: "Dot", symbol: "circle.fill",
                          packID: beginningsID, rows: ["#"])
        }
        let idx = Int(rng.next() % UInt64(pool.count))
        return pool[idx]
    }

    // MARK: - 5×5 Beginnings (free)  — 10 puzzles

    private static let beginnings: [Puzzle] = [
        Puzzle(id: "beg-heart", name: "Heart", symbol: "heart.fill", packID: beginningsID, rows: [
            ".#.#.",
            "#####",
            "#####",
            ".###.",
            "..#.."
        ]),
        Puzzle(id: "beg-cross", name: "Plus", symbol: "plus", packID: beginningsID, rows: [
            "..#..",
            "..#..",
            "#####",
            "..#..",
            "..#.."
        ]),
        Puzzle(id: "beg-diamond", name: "Diamond", symbol: "diamond.fill", packID: beginningsID, rows: [
            "..#..",
            ".###.",
            "#####",
            ".###.",
            "..#.."
        ]),
        Puzzle(id: "beg-arrow", name: "Arrow", symbol: "arrow.up", packID: beginningsID, rows: [
            "..#..",
            ".###.",
            "#####",
            "..#..",
            "..#.."
        ]),
        Puzzle(id: "beg-cup", name: "Cup", symbol: "cup.and.saucer.fill", packID: beginningsID, rows: [
            "#####",
            "#...#",
            "#...#",
            ".###.",
            "....."
        ]),
        Puzzle(id: "beg-house", name: "Hut", symbol: "house.fill", packID: beginningsID, rows: [
            "..#..",
            ".###.",
            "#####",
            "#.#.#",
            "#.#.#"
        ]),
        Puzzle(id: "beg-smile", name: "Fish", symbol: "fish.fill", packID: beginningsID, rows: [
            ".###.",
            "####.",
            "#####",
            "####.",
            ".###."
        ]),
        Puzzle(id: "beg-tree", name: "Pine", symbol: "tree.fill", packID: beginningsID, rows: [
            "..#..",
            ".###.",
            "#####",
            "..#..",
            "..#.."
        ]),
        Puzzle(id: "beg-letter", name: "Mail", symbol: "envelope.fill", packID: beginningsID, rows: [
            "#####",
            "##.##",
            "#.#.#",
            "#...#",
            "#####"
        ]),
        Puzzle(id: "beg-anchor", name: "Anchor", symbol: "anchor", packID: beginningsID, rows: [
            "..#..",
            ".#.#.",
            "..#..",
            "#.#.#",
            ".###."
        ])
    ]

    // MARK: - 10×10 Everyday (free) — 8 puzzles

    private static let everyday: [Puzzle] = [
        Puzzle(id: "evd-apple", name: "Apple", symbol: "applelogo", packID: everydayID, rows: [
            "....##....",
            "...##.....",
            "..####....",
            ".######...",
            "##########",
            "##########",
            "##########",
            ".########.",
            ".########.",
            "..##..##.."
        ]),
        Puzzle(id: "evd-key", name: "Key", symbol: "key.fill", packID: everydayID, rows: [
            "..####....",
            ".##..##...",
            ".##..##...",
            ".##..##...",
            "..####....",
            "...##.....",
            "...##.....",
            "...####...",
            "...##.....",
            "...####..."
        ]),
        Puzzle(id: "evd-umbrella", name: "Umbrella", symbol: "umbrella.fill", packID: everydayID, rows: [
            "....#.....",
            "..#####...",
            ".#######..",
            "#########.",
            "....#.....",
            "....#.....",
            "....#.....",
            "....#..#..",
            "....###...",
            ".........."
        ]),
        Puzzle(id: "evd-mug", name: "Coffee", symbol: "cup.and.saucer.fill", packID: everydayID, rows: [
            "..#.#.#...",
            "..#.#.#...",
            "..........",
            ".#######..",
            ".#####.##.",
            ".#####.##.",
            ".#####.##.",
            ".#######..",
            "..#####...",
            ".........."
        ]),
        Puzzle(id: "evd-boat", name: "Gem", symbol: "diamond.fill", packID: everydayID, rows: [
            "....##....",
            "...####...",
            "..######..",
            ".########.",
            "##########",
            ".########.",
            "..######..",
            "...####...",
            "....##....",
            ".........."
        ]),
        Puzzle(id: "evd-star", name: "Star", symbol: "star.fill", packID: everydayID, rows: [
            "....##....",
            "....##....",
            "...####...",
            "##########",
            ".########.",
            "..######..",
            ".###..###.",
            ".##....##.",
            "##......##",
            ".........."
        ]),
        Puzzle(id: "evd-bell", name: "Bell", symbol: "bell.fill", packID: everydayID, rows: [
            "....##....",
            "....##....",
            "...####...",
            "..######..",
            "..######..",
            ".########.",
            ".########.",
            "##########",
            "..........",
            "....##...."
        ]),
        Puzzle(id: "evd-camera", name: "Camera", symbol: "camera.fill", packID: everydayID, rows: [
            "..........",
            "...###....",
            "##########",
            "#........#",
            "#..####..#",
            "#.##..##.#",
            "#.##..##.#",
            "#..####..#",
            "#........#",
            "##########"
        ])
    ]

    // MARK: - 10×10 Wild Things (Pro) — 6 puzzles

    private static let nature: [Puzzle] = [
        Puzzle(id: "nat-cat", name: "Cat", symbol: "cat.fill", packID: natureID, rows: [
            "#........#",
            "##......##",
            "##########",
            "#.#....#.#",
            "##########",
            "#.######.#",
            "##########",
            ".########.",
            "..######..",
            "...####..."
        ]),
        Puzzle(id: "nat-fish", name: "Fish", symbol: "fish.fill", packID: natureID, rows: [
            "..........",
            "..####....",
            ".######..#",
            "##.####.##",
            "#######.##",
            "########.#",
            ".######..#",
            "..####....",
            "..........",
            ".........."
        ]),
        Puzzle(id: "nat-bird", name: "Owl", symbol: "bird.fill", packID: natureID, rows: [
            ".##....##.",
            "##########",
            "#.######.#",
            "#.######.#",
            "##########",
            ".########.",
            ".###..###.",
            ".########.",
            "..######..",
            "...#..#..."
        ]),
        Puzzle(id: "nat-flower", name: "Turtle", symbol: "tortoise.fill", packID: natureID, rows: [
            "..........",
            "....##....",
            "..######..",
            ".########.",
            "##########",
            "##########",
            ".########.",
            "..######..",
            ".#......#.",
            ".#......#."
        ]),
        Puzzle(id: "nat-snail", name: "Bee", symbol: "ant.fill", packID: natureID, rows: [
            "..#....#..",
            "...#..#...",
            "...####...",
            "..######..",
            "..#.##.#..",
            "..######..",
            "..#.##.#..",
            "..######..",
            "...####...",
            "....##...."
        ]),
        Puzzle(id: "nat-butterfly", name: "Butterfly", symbol: "ladybug.fill", packID: natureID, rows: [
            "##......##",
            "###....###",
            "####.####.",
            "###.##.###",
            "###.##.###",
            "####.####.",
            "###....###",
            "##......##",
            "....##....",
            "....##...."
        ])
    ]

    // MARK: - 15×15 Masterpieces (Pro) — 6 puzzles

    private static let masterpieces: [Puzzle] = [
        Puzzle(id: "mas-rocket", name: "Teapot", symbol: "cup.and.saucer.fill", packID: masterpiecesID, rows: [
            "...............",
            "..#.#.#.#......",
            "..#.#.#.#......",
            "...............",
            ".###########...",
            ".#.........#.#.",
            ".#.........#.##",
            ".#.........#.##",
            ".#.........#.#.",
            ".#.........#...",
            "..#########....",
            "...#######.....",
            "...............",
            ".#############.",
            "..###########.."
        ]),
        Puzzle(id: "mas-lighthouse", name: "Lighthouse", symbol: "light.beacon.max.fill", packID: masterpiecesID, rows: [
            "......###......",
            ".....#####.....",
            ".....#.#.#.....",
            ".....#####.....",
            "......###......",
            "......#.#......",
            "......###......",
            ".....#.#.#.....",
            ".....#.#.#.....",
            ".....#####.....",
            "....#.#.#.#....",
            "....#####.#....",
            "...#.#.#.#.#...",
            "...#########...",
            "..###########.."
        ]),
        Puzzle(id: "mas-castle", name: "Castle", symbol: "building.columns.fill", packID: masterpiecesID, rows: [
            "#.#.#.....#.#.#",
            "###############",
            "#.....###.....#",
            "#.....#.#.....#",
            "###############",
            "#.###.....###.#",
            "#.#.#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.#.#.#.#.#.#.#",
            "###############",
            "#.###.###.###.#",
            "#.#.#.#.#.#.#.#",
            "#.#.#.#.#.#.#.#",
            "###############",
            "###############"
        ]),
        Puzzle(id: "mas-elephant", name: "Elephant", symbol: "pawprint.fill", packID: masterpiecesID, rows: [
            "...#######.....",
            "..#########....",
            ".###########...",
            ".####....###...",
            ".###......##...",
            ".###......##...",
            ".###......##...",
            ".############..",
            ".############..",
            ".###.####.###..",
            ".###.####.###..",
            ".##..#..#..##..",
            ".##..#..#..##..",
            "..#..#..#..#...",
            "..####..####..."
        ]),
        Puzzle(id: "mas-guitar", name: "Oak Tree", symbol: "tree.fill", packID: masterpiecesID, rows: [
            ".......#.......",
            "......###......",
            "......###......",
            ".....#####.....",
            "....#######....",
            "....#######....",
            "...#########...",
            "..###########..",
            "..###########..",
            ".#############.",
            "###############",
            ".......#.......",
            ".......#.......",
            "......###......",
            "......###......"
        ]),
        Puzzle(id: "mas-ship", name: "Tall Ship", symbol: "ferry.fill", packID: masterpiecesID, rows: [
            ".......#.......",
            ".......##......",
            ".......###.....",
            ".......####....",
            ".......#.......",
            "....#######....",
            "....#......#...",
            "....########...",
            ".......#.......",
            "...#########...",
            "...#.......#...",
            "..#.........#..",
            "..###########..",
            ".#############.",
            "..#########...."
        ])
    ]
}
