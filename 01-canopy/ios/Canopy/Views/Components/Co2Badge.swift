import SwiftUI

struct Co2Badge: View {
    let kg: Double
    var compact: Bool = false

    private var badgeColor: Color {
        switch kg {
        case ..<5:    return .canopyLight
        case 5..<20:  return Color(hex: "F4A261")
        default:      return Color(hex: "E63946")
        }
    }

    private var label: String {
        if compact {
            return String(format: "%.1f kg", kg)
        } else {
            return String(format: "%.2f kg CO₂e", kg)
        }
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badgeColor, in: Capsule())
            .accessibilityLabel("\(String(format: "%.2f", kg)) kilograms CO2 equivalent")
    }
}

#Preview {
    VStack(spacing: 12) {
        Co2Badge(kg: 2.5)
        Co2Badge(kg: 12.0)
        Co2Badge(kg: 45.0)
        Co2Badge(kg: 2.5, compact: true)
    }
    .padding()
}
