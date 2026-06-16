import SwiftUI

/// Draws a road sign using SwiftUI shapes and SF Symbols (no image files).
struct SignView: View {
    let sign: RoadSign
    var size: CGFloat = 80

    var body: some View {
        content
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(sign.name) sign")
    }

    @ViewBuilder
    private var content: some View {
        switch sign.name {
        case "Stop":
            octagon(fill: Theme.signRed) {
                Text("STOP")
                    .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signWhite)
            }
        case "Yield":
            downTriangle(fill: Theme.signWhite, stroke: Theme.signRed) {
                Text("YIELD")
                    .font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signRed)
                    .offset(y: -size * 0.08)
            }
        case "Do Not Enter":
            circleSign(fill: Theme.signRed) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.signWhite)
                    .frame(width: size * 0.5, height: size * 0.14)
            }
        case "Wrong Way":
            rectSign(fill: Theme.signRed) {
                Text("WRONG\nWAY")
                    .multilineTextAlignment(.center)
                    .font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signWhite)
            }
        case "Speed Limit":
            rectSign(fill: Theme.signWhite, stroke: Theme.signBlack) {
                VStack(spacing: 0) {
                    Text("SPEED").font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                    Text("LIMIT").font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                    Text("55").font(.system(size: size * 0.30, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(Theme.signBlack)
            }
        case "No U-Turn":
            prohibitionSquare(symbol: "arrow.uturn.left")
        case "No Left Turn":
            prohibitionSquare(symbol: "arrow.turn.up.left")
        case "No Parking":
            prohibitionSquare(letter: "P")
        case "No Passing Zone":
            pennant(fill: Theme.signYellow, stroke: Theme.signBlack) {
                Text("DO NOT\nPASS")
                    .multilineTextAlignment(.center)
                    .font(.system(size: size * 0.10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.signBlack)
                    .offset(x: -size * 0.12)
            }
        case "One Way":
            rectSign(fill: Theme.signBlack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right").font(.system(size: size * 0.2, weight: .heavy))
                    Text("ONE WAY").font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Theme.signWhite)
            }
        case "Keep Right":
            diamond(fill: Theme.signWhite, stroke: Theme.signBlack) {
                Image(systemName: "arrow.down.right")
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundStyle(Theme.signBlack)
            }
        case "Railroad Crossing":
            circleSign(fill: Theme.signYellow, stroke: Theme.signBlack) {
                ZStack {
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.42, weight: .black))
                        .foregroundStyle(Theme.signBlack)
                    HStack(spacing: size * 0.34) {
                        Text("R").font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                        Text("R").font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(Theme.signBlack)
                }
            }
        case "Hospital":
            rectSign(fill: Theme.signBlue) {
                Text("H").font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signWhite)
            }
        case "Rest Area":
            rectSign(fill: Theme.signBlue) {
                VStack(spacing: 2) {
                    Image(systemName: "fork.knife").font(.system(size: size * 0.2, weight: .bold))
                    Text("REST").font(.system(size: size * 0.11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Theme.signWhite)
            }
        case "Route Marker":
            shield(fill: Theme.signGreen) {
                Text("66").font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signWhite)
            }
        case "Work Zone":
            diamond(fill: Theme.signOrange, stroke: Theme.signBlack) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            }
        case "Flagger Ahead":
            diamond(fill: Theme.signOrange, stroke: Theme.signBlack) {
                Image(systemName: "flag.fill")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            }
        case "School Zone":
            pentagon(fill: Theme.signYellow, stroke: Theme.signBlack) {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            }
        case "Pedestrian Crossing":
            diamond(fill: Theme.signYellow, stroke: Theme.signBlack) {
                Image(systemName: "figure.walk")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            }
        default:
            // Generic warning diamond with a representative SF Symbol.
            diamond(fill: diamondFill, stroke: Theme.signBlack) {
                Image(systemName: defaultSymbol)
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            }
        }
    }

    // Pick a fill for generic warning signs by kind.
    private var diamondFill: Color {
        switch sign.kind {
        case .warning: return Theme.signYellow
        case .regulatory: return Theme.signWhite
        case .guidance: return Theme.signGreen
        }
    }

    private var defaultSymbol: String {
        switch sign.name {
        case "Curve Ahead": return "arrow.turn.right.up"
        case "Stop Ahead": return "octagon.fill"
        case "Signal Ahead": return "stoplight"
        case "Slippery When Wet": return "car.fill"
        case "Merge": return "arrow.triangle.merge"
        case "Divided Highway Begins": return "arrow.left.and.right"
        case "Two-Way Traffic": return "arrow.up.arrow.down"
        case "Deer Crossing": return "hare.fill"
        case "T Intersection": return "t.square"
        case "Roundabout Ahead": return "arrow.triangle.2.circlepath"
        case "Lane Ends": return "arrow.triangle.merge"
        case "Steep Grade": return "arrow.down.right.circle"
        default: return "exclamationmark.triangle.fill"
        }
    }

    // MARK: Shape wrappers

    private func octagon<C: View>(fill: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            RegularPolygon(sides: 8, rotation: .degrees(22.5)).fill(fill)
            RegularPolygon(sides: 8, rotation: .degrees(22.5))
                .stroke(Theme.signWhite, lineWidth: max(2, size * 0.04))
                .padding(size * 0.06)
            label()
        }
    }

    private func downTriangle<C: View>(fill: Color, stroke: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            TriangleShape(pointingDown: true).fill(fill)
            TriangleShape(pointingDown: true).stroke(stroke, lineWidth: max(3, size * 0.07))
            label()
        }
    }

    private func diamond<C: View>(fill: Color, stroke: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            DiamondShape().fill(fill)
            DiamondShape().stroke(stroke, lineWidth: max(1.5, size * 0.03))
            label()
        }
    }

    private func pentagon<C: View>(fill: Color, stroke: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            RegularPolygon(sides: 5, rotation: .degrees(0)).fill(fill)
            RegularPolygon(sides: 5, rotation: .degrees(0)).stroke(stroke, lineWidth: max(1.5, size * 0.03))
            label()
        }
    }

    private func pennant<C: View>(fill: Color, stroke: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            PennantShape().fill(fill)
            PennantShape().stroke(stroke, lineWidth: max(1.5, size * 0.03))
            label()
        }
    }

    private func shield<C: View>(fill: Color, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            ShieldShape().fill(fill)
            ShieldShape().stroke(Theme.signWhite, lineWidth: max(1.5, size * 0.03)).padding(size * 0.04)
            label()
        }
    }

    private func circleSign<C: View>(fill: Color, stroke: Color = .clear, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(stroke, lineWidth: max(1.5, size * 0.03))
            label()
        }
    }

    private func rectSign<C: View>(fill: Color, stroke: Color = .clear, @ViewBuilder label: () -> C) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08).fill(fill)
            RoundedRectangle(cornerRadius: size * 0.08).stroke(stroke, lineWidth: max(1.5, size * 0.03))
            label()
        }
    }

    private func prohibitionSquare(symbol: String? = nil, letter: String? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08).fill(Theme.signWhite)
            RoundedRectangle(cornerRadius: size * 0.08).stroke(Theme.signBlack, lineWidth: max(1.5, size * 0.03))
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Theme.signBlack)
            } else if let letter {
                Text(letter)
                    .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.signBlack)
            }
            Circle()
                .stroke(Theme.signRed, lineWidth: max(2, size * 0.05))
                .frame(width: size * 0.62, height: size * 0.62)
            Rectangle()
                .fill(Theme.signRed)
                .frame(width: size * 0.62, height: max(2, size * 0.05))
                .rotationEffect(.degrees(-45))
        }
    }
}
