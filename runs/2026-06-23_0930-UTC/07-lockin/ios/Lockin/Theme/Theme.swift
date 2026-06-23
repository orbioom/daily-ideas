import SwiftUI

/// Centralized colors, typography and spacing for a cohesive identity.
enum Theme {
    enum Palette {
        static let appBackground = Color("AppBackground")
        static let surface = Color("Surface")
        static let surfaceElevated = Color("SurfaceElevated")
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let brand = Color("BrandPrimary")
        static let brandSoft = Color("BrandSoft")
        static let warm = Color("Warm")
        static let success = Color("Success")
        static let danger = Color("Danger")
        static let hairline = Color("Hairline")
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
    }
}

extension View {
    /// Standard card surface used across the app.
    func cardSurface(elevated: Bool = false) -> some View {
        self
            .background(elevated ? Theme.Palette.surfaceElevated : Theme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Palette.hairline, lineWidth: 1)
            )
    }
}
