import SwiftUI

/// A breathing band of sky whose color and sun position reflect the live
/// solar elevation for the selected place.
struct SkyBandView: View {
    let elevation: Double
    let dayLength: String

    private func skyColors(_ e: Double) -> [Color] {
        switch e {
        case 6...:        return [Color(red: 0.53, green: 0.74, blue: 0.93),
                                  Color(red: 0.80, green: 0.88, blue: 0.97)]
        case 0..<6:       return [Color(red: 0.97, green: 0.80, blue: 0.50),
                                  Color(red: 0.95, green: 0.69, blue: 0.52)]
        case -6..<0:      return [Color(red: 0.43, green: 0.49, blue: 0.70),
                                  Color(red: 0.90, green: 0.66, blue: 0.55)]
        case -12 ..< -6:  return [Color(red: 0.17, green: 0.21, blue: 0.40),
                                  Color(red: 0.43, green: 0.38, blue: 0.52)]
        case -18 ..< -12: return [Color(red: 0.09, green: 0.11, blue: 0.23),
                                  Color(red: 0.22, green: 0.21, blue: 0.36)]
        default:          return [Color(red: 0.05, green: 0.06, blue: 0.14),
                                  Color(red: 0.10, green: 0.11, blue: 0.21)]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let frac = max(0, min(1, (elevation + 18) / 36))   // -18°..+18° -> 0..1
            let sunY = h * (1 - frac)
            ZStack {
                LinearGradient(colors: skyColors(elevation),
                               startPoint: .top, endPoint: .bottom)
                // horizon line
                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(height: 1)
                    .position(x: geo.size.width / 2, y: h * 0.72)
                // sun / moon disk
                Circle()
                    .fill(elevation > -6
                          ? Color(red: 1, green: 0.93, blue: 0.72)
                          : Color(red: 0.85, green: 0.87, blue: 0.95))
                    .frame(width: 46, height: 46)
                    .shadow(color: .white.opacity(0.6), radius: 18)
                    .position(x: geo.size.width * 0.72, y: min(h * 0.95, max(28, sunY)))
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DAY LENGTH").eyebrow()
                                .foregroundStyle(.white.opacity(0.7))
                            Text(dayLength)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("SUN").eyebrow().foregroundStyle(.white.opacity(0.7))
                            Text(String(format: "%.1f°", elevation))
                                .font(.system(.title3, design: .monospaced).weight(.medium))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(18)
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(.white.opacity(0.4), lineWidth: 1))
        .shadow(color: Color(red: 0.157, green: 0.173, blue: 0.314).opacity(0.18),
                radius: 22, x: 0, y: 14)
        .animation(.easeInOut(duration: 0.8), value: elevation)
    }
}
