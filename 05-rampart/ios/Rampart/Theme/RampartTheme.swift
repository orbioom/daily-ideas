import SwiftUI

enum RampartTheme {
    static let background   = Color(hex: "#2C2416")
    static let surface      = Color(hex: "#3A3020")
    static let surfaceHigh  = Color(hex: "#4A3D28")
    static let gold         = Color(hex: "#D4AF37")
    static let goldLight    = Color(hex: "#F0CC60")
    static let stone        = Color(hex: "#6B6B6B")
    static let stoneLight   = Color(hex: "#9A9A9A")
    static let enemyRed     = Color(hex: "#C0392B")
    static let textPrimary  = Color(hex: "#F5E6C8")
    static let textSecondary = Color(hex: "#B0A080")
    static let textTertiary = Color(hex: "#7A6A50")

    static let archerGreen  = Color(hex: "#27AE60")
    static let cannonBlue   = Color(hex: "#2980B9")
    static let frostPurple  = Color(hex: "#8E44AD")

    static let pathColor    = Color(hex: "#1E180F")
    static let buildable    = Color(hex: "#3A3020")
    static let nonBuildable = Color(hex: "#221C0D")

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat  = 8
    static let spacingM: CGFloat  = 16
    static let spacingL: CGFloat  = 24
    static let spacingXL: CGFloat = 32

    static let radiusS: CGFloat = 6
    static let radiusM: CGFloat = 10
    static let radiusL: CGFloat = 16

    static let headlineFont = Font.system(size: 20, weight: .bold, design: .rounded)
    static let bodyFont     = Font.system(size: 15, weight: .regular, design: .rounded)
    static let labelFont    = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let captionFont  = Font.system(size: 11, weight: .regular, design: .rounded)
    static let monoFont     = Font.system(size: 13, weight: .semibold, design: .monospaced)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
