import SwiftUI

struct ElementCellView: View {
    let element: Element
    var width: CGFloat = 44
    var height: CGFloat = 52
    var colorBlindMode: Bool = false
    var showMass: Bool = true

    private var bgColor: Color {
        element.category.displayColor(colorBlind: colorBlindMode).opacity(0.80)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                        .stroke(AtomTheme.cellBorder, lineWidth: 1)
                )

            VStack(spacing: 0) {
                HStack {
                    Text("\(element.atomicNumber)")
                        .font(.system(size: min(width * 0.22, 9), weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 3)
                .padding(.top, 3)

                Spacer(minLength: 0)

                Text(element.symbol)
                    .font(.system(size: min(width * 0.50, 20), weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 0)

                if showMass {
                    Text(String(format: "%.1f", element.atomicMass))
                        .font(.system(size: min(width * 0.20, 8), weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .lineLimit(1)
                        .padding(.bottom, 3)
                }
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(element.name), symbol \(element.symbol), atomic number \(element.atomicNumber)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack(spacing: 4) {
        ElementCellView(element: Element.all[0])
        ElementCellView(element: Element.all[25])
        ElementCellView(element: Element.all[78])
    }
    .padding()
    .background(AtomTheme.background)
    .preferredColorScheme(.dark)
}
