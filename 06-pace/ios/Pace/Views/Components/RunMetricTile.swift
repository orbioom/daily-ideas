import SwiftUI

struct RunMetricTile: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    HStack {
        RunMetricTile(label: "TIME", value: "12:34", icon: "clock.fill")
        RunMetricTile(label: "DISTANCE", value: "3.21 km", icon: "ruler.fill")
        RunMetricTile(label: "PACE", value: "5:23", icon: "speedometer")
    }
    .padding()
}
