import SwiftUI

/// A human verdict on a system's daily energy balance, with a colour for badges.
struct SystemVerdict {
    let title: String
    let color: Color
    let dotColor: Color

    /// Derive a verdict from a computed result.
    init(_ result: PowerResult) {
        if result.isSelfSustaining {
            title = "Net surplus"
            color = Brand.live
            dotColor = Brand.live
        } else if result.solarCoverageFraction >= 0.7 {
            title = "Slight deficit"
            color = Brand.warn
            dotColor = Brand.warn
        } else {
            title = "Net deficit"
            color = Brand.danger
            dotColor = Brand.danger
        }
    }
}
