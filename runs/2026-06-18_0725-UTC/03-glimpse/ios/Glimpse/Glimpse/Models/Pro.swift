import SwiftUI

/// Simulated one-time Pro unlock. Stored in @AppStorage; StoreKit-ready.
enum Pro {
    /// Free tier allows up to this many tags per moment.
    static let freeTagLimit = 4
    /// Free tier allows exactly one moment per calendar day.
    static let freeMomentsPerDay = 1
    static let priceLabel = "$14.99 once"

    struct Feature: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let detail: String
    }

    static let features: [Feature] = [
        Feature(symbol: "square.stack.3d.up.fill",
                title: "More than one moment a day",
                detail: "Some days hold more than a single frame. Capture them all."),
        Feature(symbol: "rectangle.grid.3x2.fill",
                title: "Montage export",
                detail: "Render a whole month as a mosaic and save or share it."),
        Feature(symbol: "tag.fill",
                title: "Unlimited tags",
                detail: "Tag a moment with as many threads as you like."),
        Feature(symbol: "paintpalette.fill",
                title: "Extra themes",
                detail: "Unlock warmer film looks and a midnight palette."),
        Feature(symbol: "books.vertical.fill",
                title: "Multiple journals",
                detail: "Keep separate journals for trips, family or work.")
    ]
}
