import SwiftUI

struct MistakesView: View {
    let remaining: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("Mistakes remaining:")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < remaining ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(remaining) mistake\(remaining == 1 ? "" : "s") remaining")
    }
}
