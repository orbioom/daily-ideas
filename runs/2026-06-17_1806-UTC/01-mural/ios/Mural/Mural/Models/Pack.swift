import Foundation

/// A themed collection of ready-made wallpaper presets. Built-in; some are Pro-gated.
struct Pack: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let isProOnly: Bool
    let presets: [WallpaperSpec]
}

enum BuiltInPacks {
    private static func spec(
        _ style: WallpaperStyle,
        _ palette: String,
        seed: UInt64,
        angle: Double = 45,
        grain: Double = 0.1,
        vignette: Double = 0.18,
        blur: Double = 0,
        complexity: Int = 6,
        quote: String? = nil
    ) -> WallpaperSpec {
        let pal = BuiltInPalettes.palette(withID: palette) ?? BuiltInPalettes.defaultPalette
        return WallpaperSpec(
            style: style,
            paletteHexes: pal.hexes,
            paletteName: pal.name,
            seed: seed,
            angle: angle,
            grain: grain,
            vignette: vignette,
            blur: blur,
            complexity: complexity,
            quoteText: quote,
            quoteWeightRaw: 3
        )
    }

    static let all: [Pack] = [
        Pack(
            id: "golden-hour",
            name: "Golden Hour",
            tagline: "Warm sunset sweeps",
            isProOnly: false,
            presets: [
                spec(.linearGradient, "sun-ember", seed: 101, angle: 110, grain: 0.14),
                spec(.aurora, "sun-coral", seed: 102, angle: 20, complexity: 4),
                spec(.meshGradient, "sun-dusk", seed: 103, blur: 0.4),
                spec(.lowPoly, "sun-ember", seed: 104, complexity: 7)
            ]
        ),
        Pack(
            id: "minimal-mono",
            name: "Minimal Mono",
            tagline: "Quiet, focused tones",
            isProOnly: false,
            presets: [
                spec(.linearGradient, "mono-slate", seed: 201, angle: 90, grain: 0.06),
                spec(.stripes, "mono-paper", seed: 202, angle: 0, complexity: 6),
                spec(.dotField, "mono-violet", seed: 203, complexity: 10),
                spec(.quote, "mono-slate", seed: 204, quote: "Less, but better.")
            ]
        ),
        Pack(
            id: "vaporwave",
            name: "Vaporwave",
            tagline: "Retro neon dreamscapes",
            isProOnly: true,
            presets: [
                spec(.meshGradient, "neon-vapor", seed: 301, blur: 0.5),
                spec(.stripes, "neon-cyber", seed: 302, angle: 25, complexity: 14),
                spec(.aurora, "neon-pulse", seed: 303, angle: 10, complexity: 5),
                spec(.dotField, "neon-vapor", seed: 304, complexity: 16)
            ]
        ),
        Pack(
            id: "forest",
            name: "Forest",
            tagline: "Grounded, organic greens",
            isProOnly: true,
            presets: [
                spec(.lowPoly, "earth-forest", seed: 401, complexity: 8),
                spec(.linearGradient, "earth-clay", seed: 402, angle: 70, grain: 0.16),
                spec(.aurora, "earth-forest", seed: 403, angle: 5, complexity: 3),
                spec(.quote, "earth-sand", seed: 404, quote: "Go outside.")
            ]
        ),
        Pack(
            id: "cosmic",
            name: "Cosmic",
            tagline: "Deep space gradients",
            isProOnly: true,
            presets: [
                spec(.meshGradient, "ocean-deep", seed: 501, blur: 0.6),
                spec(.aurora, "neon-pulse", seed: 502, angle: 15, complexity: 6),
                spec(.dotField, "mono-violet", seed: 503, complexity: 18),
                spec(.lowPoly, "ocean-deep", seed: 504, complexity: 10)
            ]
        ),
        Pack(
            id: "oceanic",
            name: "Oceanic",
            tagline: "Calm coastal blues",
            isProOnly: false,
            presets: [
                spec(.linearGradient, "ocean-lagoon", seed: 601, angle: 120),
                spec(.meshGradient, "ocean-tide", seed: 602, blur: 0.35),
                spec(.aurora, "ocean-deep", seed: 603, angle: 8, complexity: 4),
                spec(.stripes, "ocean-lagoon", seed: 604, angle: 90, complexity: 8)
            ]
        )
    ]

    /// Packs available to free users.
    static var freePackIDs: Set<String> { ["golden-hour", "minimal-mono"] }
}
