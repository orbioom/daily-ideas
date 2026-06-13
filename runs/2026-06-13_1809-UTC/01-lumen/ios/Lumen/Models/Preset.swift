import Foundation

struct Preset: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let isPro: Bool
    let adjustments: Adjustments

    static func == (l: Preset, r: Preset) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

/// A curated library of film-inspired looks.
enum PresetLibrary {
    static let original = Preset(id: "original", name: "Original", blurb: "No edit", isPro: false, adjustments: .neutral)

    static let all: [Preset] = [
        original,
        make("kodak", "Portra", "Warm, creamy skin tones", false) { a in
            a.warmth = 0.35; a.saturation = -0.08; a.vibrance = 0.2; a.contrast = 0.1; a.shadows = 0.12; a.highlights = -0.1
        },
        make("fuji", "Superia", "Punchy greens, cool shadows", false) { a in
            a.warmth = -0.12; a.saturation = 0.18; a.vibrance = 0.25; a.contrast = 0.2; a.tint = -0.1
        },
        make("mono", "Tri-X", "Classic black & white", false) { a in
            a.saturation = -1; a.contrast = 0.28; a.grain = 0.35; a.shadows = -0.1
        },
        make("faded", "Faded", "Soft matte, lifted blacks", false) { a in
            a.fade = 0.6; a.saturation = -0.2; a.contrast = -0.1; a.warmth = 0.1
        },
        make("golden", "Golden Hour", "Sun-kissed warmth", false) { a in
            a.warmth = 0.5; a.exposure = 0.1; a.vibrance = 0.25; a.highlights = -0.15; a.vignette = 0.2
        },
        make("noir", "Noir", "High-contrast mono", false) { a in
            a.saturation = -1; a.contrast = 0.5; a.shadows = -0.3; a.vignette = 0.4; a.grain = 0.25
        },
        make("teal", "Cinematic", "Teal & orange grade", true) { a in
            a.warmth = 0.2; a.tint = -0.2; a.contrast = 0.25; a.shadows = -0.15; a.saturation = 0.05; a.vignette = 0.25
        },
        make("pastel", "Pastel", "Airy, gentle tones", true) { a in
            a.exposure = 0.15; a.fade = 0.35; a.saturation = -0.25; a.warmth = 0.12; a.highlights = 0.1
        },
        make("vivid", "Vivid", "Bold, saturated pop", true) { a in
            a.saturation = 0.4; a.vibrance = 0.35; a.contrast = 0.25; a.sharpness = 0.3
        },
        make("vintage", "Vintage", "Aged film with grain", true) { a in
            a.warmth = 0.3; a.fade = 0.45; a.saturation = -0.15; a.grain = 0.5; a.vignette = 0.35; a.contrast = -0.05
        },
        make("moody", "Moody", "Dark, dramatic mood", true) { a in
            a.exposure = -0.15; a.shadows = -0.25; a.contrast = 0.3; a.warmth = -0.1; a.vignette = 0.3
        },
        make("crisp", "Crisp", "Clean and sharp", true) { a in
            a.contrast = 0.15; a.sharpness = 0.5; a.vibrance = 0.2; a.highlights = -0.08
        },
        make("blush", "Blush", "Soft pink warmth", true) { a in
            a.warmth = 0.25; a.tint = 0.2; a.fade = 0.25; a.saturation = -0.05; a.exposure = 0.08
        },
        make("forest", "Forest", "Deep, earthy greens", true) { a in
            a.warmth = -0.15; a.tint = -0.15; a.saturation = 0.1; a.contrast = 0.18; a.shadows = -0.1
        },
        make("sun", "Sunwashed", "Bright, bleached film", true) { a in
            a.exposure = 0.25; a.fade = 0.4; a.warmth = 0.2; a.contrast = -0.08; a.highlights = 0.15
        },
        make("ice", "Ice", "Cool blue cast", true) { a in
            a.warmth = -0.35; a.tint = -0.05; a.contrast = 0.15; a.saturation = -0.05; a.highlights = 0.05
        }
    ]

    static let free: [Preset] = all.filter { !$0.isPro }

    private static func make(_ id: String, _ name: String, _ blurb: String, _ isPro: Bool,
                             _ build: (inout Adjustments) -> Void) -> Preset {
        var a = Adjustments(); build(&a)
        return Preset(id: id, name: name, blurb: blurb, isPro: isPro, adjustments: a)
    }
}
