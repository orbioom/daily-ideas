import Foundation

/// A fixed catalogue star (J2000 equatorial coordinates).
struct CatalogStar: Identifiable {
    let id: Int
    let name: String          // proper name (may be empty for line-only stars)
    let bayer: String         // Bayer designation, e.g. "α Ori"
    let raDeg: Double         // right ascension, degrees J2000
    let decDeg: Double        // declination, degrees J2000
    let magnitude: Double     // apparent visual magnitude
    let constellation: String

    var equatorial: EquatorialCoord { EquatorialCoord(raDeg: raDeg, decDeg: decDeg) }
    var displayName: String { name.isEmpty ? bayer : name }
    var raHours: Double { raDeg / 15.0 }
}

/// A constellation figure: a name plus line segments as index pairs into `Catalog.stars`.
struct Constellation: Identifiable {
    let id: String            // IAU abbreviation
    let name: String
    let segments: [(Int, Int)] // index pairs into Catalog.stars
}

/// The bundled bright-star catalogue and constellation figures.
/// Coordinates are J2000; magnitudes are apparent visual.
/// (Used directly for the chart — proper motion is negligible at this scale.)
enum Catalog {

    /// Build an EquatorialCoord from RA in H:M and Dec in D:M for readability.
    private static func hms(_ h: Double, _ m: Double, _ s: Double) -> Double {
        (h + m / 60.0 + s / 3600.0) * 15.0
    }
    private static func dms(_ sign: Double, _ d: Double, _ m: Double, _ s: Double) -> Double {
        sign * (d + m / 60.0 + s / 3600.0)
    }

    /// ~110 named bright stars across the prominent constellations.
    static let stars: [CatalogStar] = {
        var s: [CatalogStar] = []
        var id = 0
        func add(_ name: String, _ bayer: String, _ ra: Double, _ dec: Double, _ mag: Double, _ con: String) {
            s.append(CatalogStar(id: id, name: name, bayer: bayer, raDeg: ra, decDeg: dec, magnitude: mag, constellation: con))
            id += 1
        }

        // --- Orion (0–6)
        add("Betelgeuse", "α Ori", hms(5, 55, 10.3), dms(1, 7, 24, 25), 0.45, "Orion")
        add("Rigel", "β Ori", hms(5, 14, 32.3), dms(-1, 8, 12, 6), 0.18, "Orion")
        add("Bellatrix", "γ Ori", hms(5, 25, 7.9), dms(1, 6, 20, 59), 1.64, "Orion")
        add("Mintaka", "δ Ori", hms(5, 32, 0.4), dms(-1, 0, 17, 57), 2.23, "Orion")
        add("Alnilam", "ε Ori", hms(5, 36, 12.8), dms(-1, 1, 12, 7), 1.69, "Orion")
        add("Alnitak", "ζ Ori", hms(5, 40, 45.5), dms(-1, 1, 56, 34), 1.74, "Orion")
        add("Saiph", "κ Ori", hms(5, 47, 45.4), dms(-1, 9, 40, 11), 2.07, "Orion")

        // --- Ursa Major / Big Dipper (7–13)
        add("Dubhe", "α UMa", hms(11, 3, 43.7), dms(1, 61, 45, 3), 1.81, "Ursa Major")
        add("Merak", "β UMa", hms(11, 1, 50.5), dms(1, 56, 22, 57), 2.34, "Ursa Major")
        add("Phecda", "γ UMa", hms(11, 53, 49.8), dms(1, 53, 41, 41), 2.41, "Ursa Major")
        add("Megrez", "δ UMa", hms(12, 15, 25.6), dms(1, 57, 1, 57), 3.31, "Ursa Major")
        add("Alioth", "ε UMa", hms(12, 54, 1.7), dms(1, 55, 57, 35), 1.77, "Ursa Major")
        add("Mizar", "ζ UMa", hms(13, 23, 55.5), dms(1, 54, 55, 31), 2.27, "Ursa Major")
        add("Alkaid", "η UMa", hms(13, 47, 32.4), dms(1, 49, 18, 48), 1.86, "Ursa Major")

        // --- Cassiopeia (14–18)
        add("Schedar", "α Cas", hms(0, 40, 30.4), dms(1, 56, 32, 14), 2.24, "Cassiopeia")
        add("Caph", "β Cas", hms(0, 9, 10.7), dms(1, 59, 8, 59), 2.28, "Cassiopeia")
        add("Gamma Cas", "γ Cas", hms(0, 56, 42.5), dms(1, 60, 43, 0), 2.47, "Cassiopeia")
        add("Ruchbah", "δ Cas", hms(1, 25, 49.0), dms(1, 60, 14, 7), 2.68, "Cassiopeia")
        add("Segin", "ε Cas", hms(1, 54, 23.7), dms(1, 63, 40, 13), 3.38, "Cassiopeia")

        // --- Scorpius (19–25)
        add("Antares", "α Sco", hms(16, 29, 24.4), dms(-1, 26, 25, 55), 1.06, "Scorpius")
        add("Graffias", "β Sco", hms(16, 5, 26.2), dms(-1, 19, 48, 19), 2.62, "Scorpius")
        add("Dschubba", "δ Sco", hms(16, 0, 20.0), dms(-1, 22, 37, 18), 2.29, "Scorpius")
        add("Sargas", "θ Sco", hms(17, 37, 19.1), dms(-1, 42, 59, 52), 1.86, "Scorpius")
        add("Shaula", "λ Sco", hms(17, 33, 36.5), dms(-1, 37, 6, 14), 1.62, "Scorpius")
        add("Lesath", "υ Sco", hms(17, 30, 45.8), dms(-1, 37, 17, 45), 2.69, "Scorpius")
        add("Epsilon Sco", "ε Sco", hms(16, 50, 9.8), dms(-1, 34, 17, 36), 2.29, "Scorpius")

        // --- Leo (26–31)
        add("Regulus", "α Leo", hms(10, 8, 22.3), dms(1, 11, 58, 2), 1.36, "Leo")
        add("Denebola", "β Leo", hms(11, 49, 3.6), dms(1, 14, 34, 19), 2.14, "Leo")
        add("Algieba", "γ Leo", hms(10, 19, 58.4), dms(1, 19, 50, 29), 2.08, "Leo")
        add("Zosma", "δ Leo", hms(11, 14, 6.5), dms(1, 20, 31, 25), 2.56, "Leo")
        add("Ras Elased", "ε Leo", hms(9, 45, 51.1), dms(1, 23, 46, 27), 2.98, "Leo")
        add("Adhafera", "ζ Leo", hms(10, 16, 41.4), dms(1, 23, 25, 2), 3.33, "Leo")

        // --- Cygnus (32–36)
        add("Deneb", "α Cyg", hms(20, 41, 25.9), dms(1, 45, 16, 49), 1.25, "Cygnus")
        add("Albireo", "β Cyg", hms(19, 30, 43.3), dms(1, 27, 57, 35), 3.18, "Cygnus")
        add("Sadr", "γ Cyg", hms(20, 22, 13.7), dms(1, 40, 15, 24), 2.23, "Cygnus")
        add("Gienah Cyg", "ε Cyg", hms(20, 46, 12.7), dms(1, 33, 58, 13), 2.48, "Cygnus")
        add("Delta Cyg", "δ Cyg", hms(19, 44, 58.5), dms(1, 45, 7, 51), 2.87, "Cygnus")

        // --- Lyra (37–40)
        add("Vega", "α Lyr", hms(18, 36, 56.3), dms(1, 38, 47, 1), 0.03, "Lyra")
        add("Sheliak", "β Lyr", hms(18, 50, 4.8), dms(1, 33, 21, 46), 3.52, "Lyra")
        add("Sulafat", "γ Lyr", hms(18, 58, 56.6), dms(1, 32, 41, 22), 3.24, "Lyra")
        add("Delta Lyr", "δ Lyr", hms(18, 54, 30.3), dms(1, 36, 53, 55), 4.30, "Lyra")

        // --- Taurus (41–46)
        add("Aldebaran", "α Tau", hms(4, 35, 55.2), dms(1, 16, 30, 33), 0.87, "Taurus")
        add("Elnath", "β Tau", hms(5, 26, 17.5), dms(1, 28, 36, 27), 1.65, "Taurus")
        add("Alcyone", "η Tau", hms(3, 47, 29.1), dms(1, 24, 6, 18), 2.87, "Taurus")
        add("Hyadum I", "γ Tau", hms(4, 19, 47.6), dms(1, 15, 37, 40), 3.65, "Taurus")
        add("Ain", "ε Tau", hms(4, 28, 37.0), dms(1, 19, 10, 49), 3.53, "Taurus")
        add("Zeta Tau", "ζ Tau", hms(5, 37, 38.7), dms(1, 21, 8, 33), 3.00, "Taurus")

        // --- Gemini (47–52)
        add("Pollux", "β Gem", hms(7, 45, 18.9), dms(1, 28, 1, 34), 1.16, "Gemini")
        add("Castor", "α Gem", hms(7, 34, 35.9), dms(1, 31, 53, 18), 1.58, "Gemini")
        add("Alhena", "γ Gem", hms(6, 37, 42.7), dms(1, 16, 23, 57), 1.93, "Gemini")
        add("Wasat", "δ Gem", hms(7, 20, 7.4), dms(1, 21, 58, 56), 3.53, "Gemini")
        add("Mebsuta", "ε Gem", hms(6, 43, 55.9), dms(1, 25, 7, 52), 2.98, "Gemini")
        add("Tejat", "μ Gem", hms(6, 22, 57.6), dms(1, 22, 30, 49), 2.87, "Gemini")

        // --- Canis Major (53–57)
        add("Sirius", "α CMa", hms(6, 45, 8.9), dms(-1, 16, 42, 58), -1.46, "Canis Major")
        add("Adhara", "ε CMa", hms(6, 58, 37.5), dms(-1, 28, 58, 20), 1.50, "Canis Major")
        add("Wezen", "δ CMa", hms(7, 8, 23.5), dms(-1, 26, 23, 36), 1.84, "Canis Major")
        add("Mirzam", "β CMa", hms(6, 22, 42.0), dms(-1, 17, 57, 21), 1.98, "Canis Major")
        add("Aludra", "η CMa", hms(7, 24, 5.7), dms(-1, 29, 18, 11), 2.45, "Canis Major")

        // --- Boötes (58–62)
        add("Arcturus", "α Boo", hms(14, 15, 39.7), dms(1, 19, 10, 56), -0.05, "Boötes")
        add("Izar", "ε Boo", hms(14, 44, 59.2), dms(1, 27, 4, 27), 2.35, "Boötes")
        add("Muphrid", "η Boo", hms(13, 54, 41.1), dms(1, 18, 23, 52), 2.68, "Boötes")
        add("Seginus", "γ Boo", hms(14, 32, 4.7), dms(1, 38, 18, 30), 3.04, "Boötes")
        add("Nekkar", "β Boo", hms(15, 1, 56.8), dms(1, 40, 23, 26), 3.49, "Boötes")

        // --- Aquila (63–66)
        add("Altair", "α Aql", hms(19, 50, 47.0), dms(1, 8, 52, 6), 0.76, "Aquila")
        add("Tarazed", "γ Aql", hms(19, 46, 15.6), dms(1, 10, 36, 48), 2.72, "Aquila")
        add("Alshain", "β Aql", hms(19, 55, 18.8), dms(1, 6, 24, 29), 3.71, "Aquila")
        add("Deneb el Okab", "ζ Aql", hms(19, 5, 24.6), dms(1, 13, 51, 49), 2.98, "Aquila")

        // --- Pegasus (67–71)
        add("Markab", "α Peg", hms(23, 4, 45.7), dms(1, 15, 12, 19), 2.49, "Pegasus")
        add("Scheat", "β Peg", hms(23, 3, 46.5), dms(1, 28, 4, 58), 2.42, "Pegasus")
        add("Algenib", "γ Peg", hms(0, 13, 14.2), dms(1, 15, 11, 1), 2.83, "Pegasus")
        add("Enif", "ε Peg", hms(21, 44, 11.2), dms(1, 9, 52, 30), 2.39, "Pegasus")
        add("Homam", "ζ Peg", hms(22, 41, 27.7), dms(1, 10, 49, 53), 3.40, "Pegasus")

        // --- Andromeda (72–75)
        add("Alpheratz", "α And", hms(0, 8, 23.2), dms(1, 29, 5, 26), 2.06, "Andromeda")
        add("Mirach", "β And", hms(1, 9, 43.9), dms(1, 35, 37, 14), 2.05, "Andromeda")
        add("Almach", "γ And", hms(2, 3, 53.9), dms(1, 42, 19, 47), 2.10, "Andromeda")
        add("Delta And", "δ And", hms(0, 39, 19.7), dms(1, 30, 51, 40), 3.27, "Andromeda")

        // --- Perseus (76–80)
        add("Mirfak", "α Per", hms(3, 24, 19.4), dms(1, 49, 51, 40), 1.79, "Perseus")
        add("Algol", "β Per", hms(3, 8, 10.1), dms(1, 40, 57, 20), 2.09, "Perseus")
        add("Gorgonea", "ρ Per", hms(3, 5, 10.6), dms(1, 38, 50, 25), 3.39, "Perseus")
        add("Miram", "η Per", hms(2, 50, 41.8), dms(1, 55, 53, 44), 3.77, "Perseus")
        add("Menkib", "ζ Per", hms(3, 54, 7.9), dms(1, 31, 53, 1), 2.85, "Perseus")

        // --- Bright extras / pole + bright loners (81–...)
        add("Polaris", "α UMi", hms(2, 31, 49.1), dms(1, 89, 15, 51), 1.97, "Ursa Minor")
        add("Capella", "α Aur", hms(5, 16, 41.4), dms(1, 45, 59, 53), 0.08, "Auriga")
        add("Procyon", "α CMi", hms(7, 39, 18.1), dms(1, 5, 13, 30), 0.40, "Canis Minor")
        add("Spica", "α Vir", hms(13, 25, 11.6), dms(-1, 11, 9, 41), 0.98, "Virgo")
        add("Fomalhaut", "α PsA", hms(22, 57, 39.0), dms(-1, 29, 37, 20), 1.16, "Piscis Austrinus")
        add("Achernar", "α Eri", hms(1, 37, 42.8), dms(-1, 57, 14, 12), 0.45, "Eridanus")
        add("Hadar", "β Cen", hms(14, 3, 49.4), dms(-1, 60, 22, 23), 0.61, "Centaurus")
        add("Rigil Kent", "α Cen", hms(14, 39, 36.5), dms(-1, 60, 50, 2), -0.27, "Centaurus")
        add("Canopus", "α Car", hms(6, 23, 57.1), dms(-1, 52, 41, 44), -0.72, "Carina")
        add("Acrux", "α Cru", hms(12, 26, 35.9), dms(-1, 63, 5, 57), 0.77, "Crux")
        add("Mimosa", "β Cru", hms(12, 47, 43.3), dms(-1, 59, 41, 19), 1.25, "Crux")
        add("Gacrux", "γ Cru", hms(12, 31, 9.9), dms(-1, 57, 6, 47), 1.59, "Crux")
        add("Delta Cru", "δ Cru", hms(12, 15, 8.7), dms(-1, 58, 44, 56), 2.79, "Crux")
        add("Alphard", "α Hya", hms(9, 27, 35.2), dms(-1, 8, 39, 31), 1.98, "Hydra")
        add("Diphda", "β Cet", hms(0, 43, 35.4), dms(-1, 17, 59, 12), 2.04, "Cetus")
        add("Hamal", "α Ari", hms(2, 7, 10.4), dms(1, 23, 27, 45), 2.01, "Aries")
        add("Sheratan", "β Ari", hms(1, 54, 38.4), dms(1, 20, 48, 29), 2.64, "Aries")
        add("Kaus Australis", "ε Sgr", hms(18, 24, 10.3), dms(-1, 34, 23, 5), 1.85, "Sagittarius")
        add("Nunki", "σ Sgr", hms(18, 55, 15.9), dms(-1, 26, 17, 48), 2.05, "Sagittarius")
        add("Kaus Media", "δ Sgr", hms(18, 20, 59.6), dms(-1, 29, 49, 41), 2.70, "Sagittarius")
        add("Rasalhague", "α Oph", hms(17, 34, 56.1), dms(1, 12, 33, 36), 2.08, "Ophiuchus")
        add("Alphecca", "α CrB", hms(15, 34, 41.3), dms(1, 26, 42, 53), 2.22, "Corona Borealis")
        add("Menkalinan", "β Aur", hms(5, 59, 31.7), dms(1, 44, 56, 51), 1.90, "Auriga")
        add("Castor extra", "θ Aur", hms(5, 59, 43.2), dms(1, 37, 12, 45), 2.62, "Auriga")
        add("Mirach extra", "δ Cas2", hms(1, 25, 49.0), dms(1, 60, 14, 7), 2.68, "Cassiopeia")

        return s
    }()

    /// Index of stars by id for fast lookup.
    static let starByID: [Int: CatalogStar] = {
        Dictionary(uniqueKeysWithValues: stars.map { ($0.id, $0) })
    }()

    /// Constellation figures referencing star indices above.
    static let constellations: [Constellation] = [
        Constellation(id: "Ori", name: "Orion", segments: [
            (0, 2), (0, 5), (2, 3), (3, 4), (4, 5), (1, 3), (5, 6), (1, 6), (0, 4)
        ]),
        Constellation(id: "UMa", name: "Ursa Major", segments: [
            (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (7, 10)
        ]),
        Constellation(id: "Cas", name: "Cassiopeia", segments: [
            (15, 14), (14, 16), (16, 17), (17, 18)
        ]),
        Constellation(id: "Sco", name: "Scorpius", segments: [
            (21, 20), (20, 19), (19, 25), (25, 22), (22, 23), (23, 24)
        ]),
        Constellation(id: "Leo", name: "Leo", segments: [
            (26, 28), (28, 30), (30, 31), (26, 29), (29, 27), (27, 28)
        ]),
        Constellation(id: "Cyg", name: "Cygnus", segments: [
            (32, 34), (34, 36), (34, 33), (35, 34)
        ]),
        Constellation(id: "Lyr", name: "Lyra", segments: [
            (37, 39), (39, 40), (40, 38), (38, 37)
        ]),
        Constellation(id: "Tau", name: "Taurus", segments: [
            (41, 44), (41, 45), (41, 43), (43, 42)
        ]),
        Constellation(id: "Gem", name: "Gemini", segments: [
            (47, 49), (48, 51), (51, 50), (50, 47), (49, 52)
        ]),
        Constellation(id: "CMa", name: "Canis Major", segments: [
            (53, 56), (53, 55), (55, 54), (55, 57)
        ]),
        Constellation(id: "Boo", name: "Boötes", segments: [
            (58, 60), (58, 59), (59, 61), (61, 62), (62, 58)
        ]),
        Constellation(id: "Aql", name: "Aquila", segments: [
            (64, 63), (63, 65), (63, 66)
        ]),
        Constellation(id: "Peg", name: "Pegasus", segments: [
            (67, 68), (68, 71), (71, 69), (69, 67), (69, 70)
        ]),
        Constellation(id: "And", name: "Andromeda", segments: [
            (72, 75), (75, 73), (73, 74)
        ]),
        Constellation(id: "Per", name: "Perseus", segments: [
            (76, 77), (77, 78), (76, 80), (76, 79)
        ]),
        Constellation(id: "Cru", name: "Crux", segments: [
            (90, 91), (92, 93)
        ])
    ]
}
