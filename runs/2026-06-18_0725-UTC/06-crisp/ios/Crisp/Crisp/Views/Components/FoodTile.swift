import SwiftUI

/// A food card for the guide grid — big icon, name, temp+time chip.
struct FoodTile: View {
    let food: Food
    let tempUnit: TempUnit
    var isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(food.icon)
                    .font(.system(size: 34))
                    .accessibilityHidden(true)
                Spacer()
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }
            Text(food.name)
                .font(Theme.roundedStyle(.headline, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Label(Fmt.temp(fahrenheit: food.fresh.tempF, unit: tempUnit),
                      systemImage: "thermometer.medium")
                    .labelStyle(.titleAndIcon)
                Text("·").foregroundStyle(Theme.inkSoft)
                Label(Fmt.minutesLabel(food.fresh.minutes), systemImage: "clock")
            }
            .font(Theme.roundedStyle(.caption, .medium))
            .foregroundStyle(Theme.inkSoft)
            .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .crispCard(radius: Theme.tileRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(food.name)\(isFavorite ? ", favorite" : "")")
        .accessibilityValue("\(Fmt.temp(fahrenheit: food.fresh.tempF, unit: tempUnit)) for \(Fmt.minutesLabel(food.fresh.minutes))")
        .accessibilityHint("Opens cooking details")
    }
}
