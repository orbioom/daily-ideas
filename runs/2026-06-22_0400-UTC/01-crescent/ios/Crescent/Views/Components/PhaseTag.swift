import SwiftUI

struct PhaseTag: View {
    let phase: MoonPhase

    var body: some View {
        Text(phase.symbol + " " + phase.rawValue)
            .font(.caption2)
            .foregroundColor(CrescentTheme.navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(CrescentTheme.gold.opacity(0.8))
            .cornerRadius(8)
    }
}
