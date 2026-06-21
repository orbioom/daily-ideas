import Foundation

// 60 brightest stars + key constellation stars (RA in degrees, Dec in degrees)
enum StarCatalog {
    static let stars: [Star] = [
        Star(id:  0, name: "Sirius",       constellation: "Canis Major",   raDeg: 101.287, decDeg:  -16.716, magnitude: -1.46, bv:  0.00, spectralType: "A1V",   description: "Brightest star in the night sky, the Dog Star."),
        Star(id:  1, name: "Canopus",      constellation: "Carina",        raDeg:  95.988, decDeg:  -52.696, magnitude: -0.72, bv:  0.15, spectralType: "F0Ib",  description: "Second-brightest star, navigational star of the southern sky."),
        Star(id:  2, name: "Arcturus",     constellation: "Boötes",        raDeg: 213.915, decDeg:  +19.182, magnitude: -0.05, bv:  1.23, spectralType: "K1III", description: "Brightest star in the northern sky, red giant 36 light-years away."),
        Star(id:  3, name: "Vega",         constellation: "Lyra",          raDeg: 279.235, decDeg:  +38.784, magnitude:  0.03, bv:  0.00, spectralType: "A0V",   description: "5th brightest star overall, former pole star, part of the Summer Triangle."),
        Star(id:  4, name: "Capella",      constellation: "Auriga",        raDeg:  79.172, decDeg:  +45.998, magnitude:  0.08, bv:  0.80, spectralType: "G5III", description: "Sixth-brightest, a pair of giant stars orbiting each other."),
        Star(id:  5, name: "Rigel",        constellation: "Orion",         raDeg:  78.634, decDeg:   -8.202, magnitude:  0.13, bv: -0.03, spectralType: "B8Ia",  description: "Blue supergiant marking Orion's right foot, 860 light-years away."),
        Star(id:  6, name: "Procyon",      constellation: "Canis Minor",   raDeg: 114.825, decDeg:   +5.225, magnitude:  0.38, bv:  0.42, spectralType: "F5IV",  description: "The Little Dog Star, one of our nearest stellar neighbors at 11 ly."),
        Star(id:  7, name: "Achernar",     constellation: "Eridanus",      raDeg:  24.429, decDeg:  -57.237, magnitude:  0.46, bv: -0.15, spectralType: "B3V",   description: "End of the River, fastest-spinning major star known."),
        Star(id:  8, name: "Betelgeuse",   constellation: "Orion",         raDeg:  88.793, decDeg:   +7.407, magnitude:  0.50, bv:  1.85, spectralType: "M2Iab", description: "Red supergiant marking Orion's right shoulder, a future supernova."),
        Star(id:  9, name: "Hadar",        constellation: "Centaurus",     raDeg: 210.956, decDeg:  -60.373, magnitude:  0.61, bv: -0.23, spectralType: "B1III", description: "Southern Pointer, used to locate the Southern Cross."),
        Star(id: 10, name: "Altair",       constellation: "Aquila",        raDeg: 297.696, decDeg:   +8.868, magnitude:  0.77, bv:  0.22, spectralType: "A7V",   description: "The Eagle Star, part of the Summer Triangle, 17 light-years away."),
        Star(id: 11, name: "Acrux",        constellation: "Crux",          raDeg: 186.650, decDeg:  -63.099, magnitude:  0.77, bv: -0.26, spectralType: "B0.5V", description: "Brightest star in the Southern Cross."),
        Star(id: 12, name: "Aldebaran",    constellation: "Taurus",        raDeg:  68.980, decDeg:  +16.509, magnitude:  0.87, bv:  1.54, spectralType: "K5III", description: "The Bull's Eye, a red giant 65 light-years away."),
        Star(id: 13, name: "Spica",        constellation: "Virgo",         raDeg: 201.298, decDeg:  -11.161, magnitude:  1.04, bv: -0.24, spectralType: "B1III", description: "Brightest star in Virgo, a binary system 250 light-years away."),
        Star(id: 14, name: "Antares",      constellation: "Scorpius",      raDeg: 247.352, decDeg:  -26.432, magnitude:  1.06, bv:  1.83, spectralType: "M1Iab", description: "Rival of Mars, red supergiant heart of the Scorpion."),
        Star(id: 15, name: "Pollux",       constellation: "Gemini",        raDeg: 116.329, decDeg:  +28.026, magnitude:  1.16, bv:  1.00, spectralType: "K0III", description: "Brighter twin of Gemini, has a confirmed exoplanet."),
        Star(id: 16, name: "Fomalhaut",    constellation: "Piscis Austrin", raDeg: 344.412, decDeg:  -29.622, magnitude:  1.17, bv:  0.09, spectralType: "A3V",   description: "Lonely Autumn star, surrounded by a debris disk with possible planet."),
        Star(id: 17, name: "Deneb",        constellation: "Cygnus",        raDeg: 310.358, decDeg:  +45.280, magnitude:  1.25, bv:  0.09, spectralType: "A2Ia",  description: "Tail of the Swan, one of the most luminous stars visible to the naked eye."),
        Star(id: 18, name: "Mimosa",       constellation: "Crux",          raDeg: 191.930, decDeg:  -59.689, magnitude:  1.25, bv: -0.22, spectralType: "B0.5IV", description: "Second-brightest star in the Southern Cross."),
        Star(id: 19, name: "Regulus",      constellation: "Leo",           raDeg: 152.093, decDeg:  +11.967, magnitude:  1.36, bv: -0.11, spectralType: "B8IVn", description: "Little King, lies almost exactly on the ecliptic."),
        Star(id: 20, name: "Adhara",       constellation: "Canis Major",   raDeg: 104.657, decDeg:  -28.972, magnitude:  1.50, bv: -0.21, spectralType: "B2II",  description: "Second-brightest star in Canis Major."),
        Star(id: 21, name: "Castor",       constellation: "Gemini",        raDeg: 113.650, decDeg:  +31.888, magnitude:  1.57, bv:  0.03, spectralType: "A2V",   description: "The other Twin, a remarkable sextuple star system."),
        Star(id: 22, name: "Shaula",       constellation: "Scorpius",      raDeg: 263.402, decDeg:  -37.103, magnitude:  1.62, bv: -0.22, spectralType: "B1.5V", description: "The Sting of the Scorpion."),
        Star(id: 23, name: "Gacrux",       constellation: "Crux",          raDeg: 187.791, decDeg:  -57.113, magnitude:  1.63, bv:  1.60, spectralType: "M3.5III", description: "Top star of the Southern Cross."),
        Star(id: 24, name: "Bellatrix",    constellation: "Orion",         raDeg:  81.283, decDeg:   +6.350, magnitude:  1.64, bv: -0.22, spectralType: "B2III", description: "The Female Warrior, Orion's left shoulder."),
        Star(id: 25, name: "Elnath",       constellation: "Taurus",        raDeg:  81.573, decDeg:  +28.608, magnitude:  1.65, bv: -0.13, spectralType: "B7III", description: "The Butting One, tip of Taurus's northern horn."),
        Star(id: 26, name: "Alnilam",      constellation: "Orion",         raDeg:  84.053, decDeg:   -1.202, magnitude:  1.69, bv: -0.19, spectralType: "B0Ia",  description: "Middle star of Orion's Belt, 1344 light-years away."),
        Star(id: 27, name: "Alioth",       constellation: "Ursa Major",    raDeg: 193.507, decDeg:  +55.960, magnitude:  1.76, bv:  0.02, spectralType: "A0p",   description: "Brightest star in the Big Dipper's handle."),
        Star(id: 28, name: "Mirfak",       constellation: "Perseus",       raDeg:  51.080, decDeg:  +49.861, magnitude:  1.79, bv:  0.48, spectralType: "F5Ib",  description: "Brightest star in Perseus, embedded in a rich star cluster."),
        Star(id: 29, name: "Dubhe",        constellation: "Ursa Major",    raDeg: 165.932, decDeg:  +61.751, magnitude:  1.79, bv:  1.07, spectralType: "K0III", description: "The outer bowl star of the Big Dipper, a pointer to Polaris."),
        Star(id: 30, name: "Wezen",        constellation: "Canis Major",   raDeg: 107.098, decDeg:  -26.393, magnitude:  1.82, bv:  0.67, spectralType: "F8Ia",  description: "The Weight, one of the most luminous stars within 2000 light-years."),
        Star(id: 31, name: "Kaus Australis",constellation:"Sagittarius",   raDeg: 276.043, decDeg:  -34.384, magnitude:  1.85, bv:  0.09, spectralType: "B9.5V", description: "Brightest star in Sagittarius, the Southern Bow."),
        Star(id: 32, name: "Alkaid",       constellation: "Ursa Major",    raDeg: 206.885, decDeg:  +49.313, magnitude:  1.86, bv: -0.19, spectralType: "B3V",   description: "End of the Big Dipper's handle, named for the chief of the mourning daughters."),
        Star(id: 33, name: "Avior",        constellation: "Carina",        raDeg: 125.628, decDeg:  -59.510, magnitude:  1.86, bv:  1.20, spectralType: "K3III", description: "A giant binary system in Carina."),
        Star(id: 34, name: "Peacock",      constellation: "Pavo",          raDeg: 306.412, decDeg:  -56.735, magnitude:  1.94, bv: -0.19, spectralType: "B2IV",  description: "The Peacock Star, brightest in the southern constellation Pavo."),
        Star(id: 35, name: "Mirzam",       constellation: "Canis Major",   raDeg:  95.675, decDeg:  -17.956, magnitude:  1.98, bv: -0.24, spectralType: "B1II",  description: "The Herald, announces the arrival of Sirius."),
        Star(id: 36, name: "Alphard",      constellation: "Hydra",         raDeg: 141.897, decDeg:   -8.659, magnitude:  1.99, bv:  1.44, spectralType: "K3II",  description: "The Lonely One, only bright star in Hydra."),
        Star(id: 37, name: "Hamal",        constellation: "Aries",         raDeg:  31.793, decDeg:  +23.462, magnitude:  2.00, bv:  1.15, spectralType: "K2III", description: "Head of the Ram, former vernal equinox location."),
        Star(id: 38, name: "Nunki",        constellation: "Sagittarius",   raDeg: 283.816, decDeg:  -26.297, magnitude:  2.05, bv: -0.20, spectralType: "B2.5V", description: "Sacred star of the city in Babylonian astronomy."),
        Star(id: 39, name: "Mintaka",      constellation: "Orion",         raDeg:  83.001, decDeg:   -0.300, magnitude:  2.25, bv: -0.22, spectralType: "O9.5II","description: "Western end of Orion's Belt, lies almost exactly on the celestial equator."),
        Star(id: 40, name: "Alnitak",      constellation: "Orion",         raDeg:  85.190, decDeg:   -1.943, magnitude:  1.77, bv: -0.21, spectralType: "O9Ib",  description: "Eastern end of Orion's Belt, near the Horsehead Nebula."),
        Star(id: 41, name: "Saiph",        constellation: "Orion",         raDeg:  86.939, decDeg:   -9.670, magnitude:  2.07, bv: -0.18, spectralType: "B0.5Ia","description: "Orion's left knee."),
        Star(id: 42, name: "Merak",        constellation: "Ursa Major",    raDeg: 165.460, decDeg:  +56.383, magnitude:  2.37, bv:  0.03, spectralType: "A1V",   description: "Inner bowl of the Big Dipper, pointer to Polaris."),
        Star(id: 43, name: "Phecda",       constellation: "Ursa Major",    raDeg: 178.458, decDeg:  +53.695, magnitude:  2.44, bv:  0.04, spectralType: "A0Ve",  description: "Hind paw of the Great Bear, part of the Dipper bowl."),
        Star(id: 44, name: "Megrez",       constellation: "Ursa Major",    raDeg: 183.857, decDeg:  +57.033, magnitude:  3.31, bv:  0.08, spectralType: "A3V",   description: "Root of the Bear's tail, the faintest Dipper star."),
        Star(id: 45, name: "Mizar",        constellation: "Ursa Major",    raDeg: 200.981, decDeg:  +54.926, magnitude:  2.23, bv:  0.14, spectralType: "A2V",   description: "Middle of the Dipper handle, visual binary with Alcor."),
        Star(id: 46, name: "Schedar",      constellation: "Cassiopeia",    raDeg:  10.127, decDeg:  +56.537, magnitude:  2.24, bv:  1.17, spectralType: "K0IIIa","description: "Brightest star in Cassiopeia's W pattern."),
        Star(id: 47, name: "Caph",         constellation: "Cassiopeia",    raDeg:   2.295, decDeg:  +59.150, magnitude:  2.27, bv:  0.34, spectralType: "F2III", description: "The Hand, tip of Cassiopeia's W pattern."),
        Star(id: 48, name: "Gamma Cas",    constellation: "Cassiopeia",    raDeg:  14.177, decDeg:  +60.717, magnitude:  2.47, bv: -0.15, spectralType: "B0IVe", description: "The center star of Cassiopeia's W, a variable Be star."),
        Star(id: 49, name: "Ruchbah",      constellation: "Cassiopeia",    raDeg:  21.454, decDeg:  +60.235, magnitude:  2.68, bv:  0.13, spectralType: "A5III", description: "Kneecap of the seated Queen Cassiopeia."),
        Star(id: 50, name: "Epsilon Cas",  constellation: "Cassiopeia",    raDeg:  28.599, decDeg:  +63.670, magnitude:  3.37, bv: -0.15, spectralType: "B3IVp", description: "Fifth star completing Cassiopeia's W asterism."),
        Star(id: 51, name: "Polaris",      constellation: "Ursa Minor",    raDeg:  37.954, decDeg:  +89.264, magnitude:  1.97, bv:  0.60, spectralType: "F7Ib",  description: "The North Star, within 1° of the celestial pole."),
        Star(id: 52, name: "Acrab",        constellation: "Scorpius",      raDeg: 241.359, decDeg:  -19.806, magnitude:  2.62, bv: -0.24, spectralType: "B0.5V", description: "Scorpion's head, a complex multiple star system."),
        Star(id: 53, name: "Dschubba",     constellation: "Scorpius",      raDeg: 240.083, decDeg:  -22.622, magnitude:  2.32, bv: -0.12, spectralType: "B0.3V", description: "Forehead of the Scorpion."),
        Star(id: 54, name: "Denebola",     constellation: "Leo",           raDeg: 177.265, decDeg:  +14.572, magnitude:  2.14, bv:  0.09, spectralType: "A3V",   description: "Tail of the Lion."),
        Star(id: 55, name: "Algieba",      constellation: "Leo",           raDeg: 154.993, decDeg:  +19.842, magnitude:  2.01, bv:  1.14, spectralType: "K0III", description: "The Mane, a beautiful binary system."),
        Star(id: 56, name: "Sargas",       constellation: "Scorpius",      raDeg: 264.330, decDeg:  -42.998, magnitude:  1.87, bv:  0.41, spectralType: "F1II",  description: "Part of Scorpius's tail."),
        Star(id: 57, name: "Zeta Pup",     constellation: "Puppis",        raDeg: 119.193, decDeg:  -40.003, magnitude:  2.21, bv: -0.27, spectralType: "O4If",  description: "The Sky Puppy, a massive runaway star."),
        Star(id: 58, name: "Eta Sgr",      constellation: "Sagittarius",   raDeg: 274.407, decDeg:  -36.762, magnitude:  3.11, bv:  1.56, spectralType: "M3.5III","description: "Bright star in the handle of the Teapot asterism."),
        Star(id: 59, name: "Phi Sgr",      constellation: "Sagittarius",   raDeg: 279.235, decDeg:  -26.987, magnitude:  3.17, bv: -0.09, spectralType: "B8III", description: "Part of the Teapot asterism in Sagittarius."),
    ]

    static let constellations: [ConstellationData] = [
        // Orion - the Hunter
        ConstellationData(name: "Orion", abbreviation: "Ori", lines: [
            (8, 24),  // Betelgeuse - Bellatrix
            (8, 26),  // Betelgeuse - Alnilam
            (24, 39), // Bellatrix - Mintaka
            (39, 26), // Mintaka - Alnilam
            (26, 40), // Alnilam - Alnitak
            (5, 40),  // Rigel - Alnitak
            (5, 41),  // Rigel - Saiph
            (41, 40), // Saiph - Alnitak
        ]),
        // Ursa Major - Big Dipper
        ConstellationData(name: "Ursa Major", abbreviation: "UMa", lines: [
            (29, 42), // Dubhe - Merak
            (42, 43), // Merak - Phecda
            (43, 44), // Phecda - Megrez
            (44, 27), // Megrez - Alioth
            (27, 45), // Alioth - Mizar
            (45, 32), // Mizar - Alkaid
            (29, 44), // Dubhe - Megrez (bowl)
        ]),
        // Cassiopeia - the Queen
        ConstellationData(name: "Cassiopeia", abbreviation: "Cas", lines: [
            (47, 46), // Caph - Schedar
            (46, 48), // Schedar - Gamma Cas
            (48, 49), // Gamma Cas - Ruchbah
            (49, 50), // Ruchbah - Epsilon Cas
        ]),
        // Scorpius - the Scorpion
        ConstellationData(name: "Scorpius", abbreviation: "Sco", lines: [
            (52, 53), // Acrab - Dschubba
            (53, 14), // Dschubba - Antares
            (14, 22), // Antares - Shaula
            (22, 56), // Shaula - Sargas
        ]),
        // Leo - the Lion
        ConstellationData(name: "Leo", abbreviation: "Leo", lines: [
            (19, 55), // Regulus - Algieba
            (55, 54), // Algieba - Denebola
            (19, 36), // Regulus - Alphard (approximate sickle)
        ]),
        // Gemini - the Twins
        ConstellationData(name: "Gemini", abbreviation: "Gem", lines: [
            (15, 21), // Pollux - Castor
            (15, 12), // Pollux - Aldebaran direction
            (21, 4),  // Castor - Capella direction
        ]),
        // Taurus - the Bull
        ConstellationData(name: "Taurus", abbreviation: "Tau", lines: [
            (12, 25), // Aldebaran - Elnath
        ]),
        // Sagittarius - the Teapot
        ConstellationData(name: "Sagittarius", abbreviation: "Sgr", lines: [
            (31, 38), // Kaus Australis - Nunki
            (38, 59), // Nunki - Phi Sgr
            (31, 58), // Kaus Australis - Eta Sgr (teapot handle)
        ]),
        // Crux - Southern Cross
        ConstellationData(name: "Crux", abbreviation: "Cru", lines: [
            (23, 18), // Gacrux - Mimosa (vertical beam)
            (11, 18), // Acrux - Mimosa (bottom-up)
            (11, 23), // Acrux - Gacrux (vertical)
        ]),
        // Summer Triangle
        ConstellationData(name: "Summer Triangle*", abbreviation: "SuT", lines: [
            (3, 10),  // Vega - Altair
            (3, 17),  // Vega - Deneb
            (17, 10), // Deneb - Altair
        ]),
    ]

    static func starByName(_ name: String) -> Star? {
        stars.first { $0.name.lowercased() == name.lowercased() }
    }
}
