import SwiftUI

struct TowerCard: View {
    let type: TowerType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? type.color : type.color.opacity(0.4))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(isSelected ? .white : Color.white.opacity(0.3), lineWidth: 1.5))

                Image(systemName: type.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(type.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 3) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                Text("\(type.cost)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
            }

            VStack(spacing: 2) {
                MiniStat(label: "DMG", value: "\(Int(type.damage))")
                MiniStat(label: "RNG", value: "\(Int(type.range))")
                MiniStat(label: "SPD", value: String(format: "%.1f", type.fireRate) + "s")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? type.color.opacity(0.8) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

private struct MiniStat: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
