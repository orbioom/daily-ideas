import Foundation

struct ColorNamer {
    private static let cssColors: [(name: String, r: Double, g: Double, b: Double)] = [
        ("Red",        1.000, 0.000, 0.000),
        ("Orange",     1.000, 0.647, 0.000),
        ("Gold",       1.000, 0.843, 0.000),
        ("Yellow",     1.000, 1.000, 0.000),
        ("Lime",       0.000, 1.000, 0.000),
        ("Green",      0.000, 0.502, 0.000),
        ("Teal",       0.000, 0.502, 0.502),
        ("Cyan",       0.000, 1.000, 1.000),
        ("Blue",       0.000, 0.000, 1.000),
        ("Navy",       0.000, 0.000, 0.502),
        ("Purple",     0.502, 0.000, 0.502),
        ("Magenta",    1.000, 0.000, 1.000),
        ("Pink",       1.000, 0.753, 0.796),
        ("Coral",      1.000, 0.498, 0.314),
        ("Salmon",     0.980, 0.502, 0.447),
        ("Crimson",    0.863, 0.078, 0.235),
        ("Indigo",     0.294, 0.000, 0.510),
        ("Violet",     0.933, 0.510, 0.933),
        ("Lavender",   0.902, 0.902, 0.980),
        ("Maroon",     0.502, 0.000, 0.000),
        ("Olive",      0.502, 0.502, 0.000),
        ("Turquoise",  0.251, 0.878, 0.816),
        ("Silver",     0.753, 0.753, 0.753),
        ("Gray",       0.502, 0.502, 0.502),
        ("Black",      0.000, 0.000, 0.000),
        ("White",      1.000, 1.000, 1.000),
        ("Beige",      0.961, 0.961, 0.863),
        ("Ivory",      1.000, 1.000, 0.941),
        ("Khaki",      0.941, 0.902, 0.549),
        ("Chocolate",  0.824, 0.412, 0.118),
        ("Sienna",     0.627, 0.322, 0.176),
        ("Tan",        0.824, 0.706, 0.549),
        ("Peach",      1.000, 0.855, 0.725),
        ("Mint",       0.741, 0.988, 0.788),
        ("Sky Blue",   0.529, 0.808, 0.922),
        ("Steel Blue", 0.275, 0.510, 0.706),
        ("Rose",       1.000, 0.000, 0.502),
        ("Amber",      1.000, 0.749, 0.000),
    ]

    func name(r: Double, g: Double, b: Double) -> String {
        var bestName = "Color"
        var bestDist = Double.infinity
        for entry in Self.cssColors {
            let dr = r - entry.r
            let dg = g - entry.g
            let db = b - entry.b
            let dist = dr*dr + dg*dg + db*db
            if dist < bestDist {
                bestDist = dist
                bestName = entry.name
            }
        }
        return bestName
    }
}
