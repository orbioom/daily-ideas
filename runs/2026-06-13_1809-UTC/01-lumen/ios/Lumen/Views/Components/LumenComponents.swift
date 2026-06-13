import SwiftUI
import UIKit

/// A horizontal adjustment slider for one field.
struct AdjustSlider: View {
    let field: Adjustments.Field
    @Binding var value: Double
    var onChange: (Double) -> Void

    private var range: ClosedRange<Double> { field.bipolar ? -1...1 : 0...1 }
    private var displayValue: Int {
        field.bipolar ? Int((value * 100).rounded()) : Int((value * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(field.label, systemImage: field.icon)
                    .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                Text(field.bipolar && value > 0 ? "+\(displayValue)" : "\(displayValue)")
                    .font(Theme.rounded(14, .bold)).foregroundStyle(value == 0 ? Theme.inkSoft : Theme.accent)
                    .monospacedDigit()
            }
            Slider(value: Binding(get: { value }, set: { value = $0; onChange($0) }),
                   in: range, step: 0.01)
                .tint(Theme.accent)
                .accessibilityValue("\(displayValue)")
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A circular preview chip for a preset.
struct PresetChip: View {
    let name: String
    let image: UIImage?
    let selected: Bool
    let locked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt).frame(width: 60, height: 60)
                }
                if locked {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.35)).frame(width: 60, height: 60)
                    Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? Theme.accent : Color.clear, lineWidth: 2.5).padding(-2))
            Text(name).font(Theme.rounded(11, .semibold))
                .foregroundStyle(selected ? Theme.accent : Theme.inkSoft).lineLimit(1)
        }
        .frame(width: 68)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name)\(locked ? ", locked" : "")\(selected ? ", selected" : "")")
    }
}

/// A brief floating confirmation toast.
struct Toast: View {
    let text: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(.white)
            Text(text).font(Theme.rounded(15, .bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.ink.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}
