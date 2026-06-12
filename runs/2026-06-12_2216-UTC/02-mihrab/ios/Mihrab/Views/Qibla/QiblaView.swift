import SwiftUI

struct QiblaView: View {
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var compass = CompassService()
    @State private var celebratedAlignment = false

    private var city: City { Gazetteer.city(id: cityID) ?? Gazetteer.cities[0] }
    private var bearing: Double {
        PrayerEngine.qiblaBearing(latitude: city.latitude, longitude: city.longitude)
    }
    private var distanceKm: Double {
        PrayerEngine.distanceToKaabaKm(latitude: city.latitude, longitude: city.longitude)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabTheme.skyGradient(colorScheme).ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Qibla from \(city.name)")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(Int(bearing.rounded()))° from north · \(Int(distanceKm.rounded()).formatted()) km to the Kaaba")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .accessibilityElement(children: .combine)

                    compassDial
                        .frame(maxWidth: 320)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.horizontal, 24)

                    statusFooter
                }
                .padding()
            }
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear { compass.start() }
        .onDisappear { compass.stop() }
    }

    // MARK: - Dial

    private var compassDial: some View {
        let heading = compass.heading
        let dialRotation = -(heading ?? 0)
        let aligned: Bool = {
            guard let heading else { return false }
            let diff = abs((heading - bearing).truncatingRemainder(dividingBy: 360))
            return min(diff, 360 - diff) < 4
        }()

        return ZStack {
            // Rose: rotates against the device heading so north stays true.
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 36)
                    .padding(18)
                ForEach(0..<72, id: \.self) { tick in
                    Capsule()
                        .fill(Color.white.opacity(tick % 18 == 0 ? 0.9 : 0.30))
                        .frame(width: tick % 18 == 0 ? 3 : 1.5, height: tick % 18 == 0 ? 18 : 9)
                        .offset(y: -150 + 9)
                        .rotationEffect(.degrees(Double(tick) * 5))
                }
                ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(label == "N" ? MihrabTheme.gold : .white.opacity(0.7))
                        .offset(y: -112)
                        .rotationEffect(.degrees(Double(index) * 90))
                }
                // Qibla marker on the rose at the fixed bearing.
                VStack(spacing: 2) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(aligned ? Color.green : MihrabTheme.gold)
                    Capsule()
                        .fill(aligned ? Color.green : MihrabTheme.gold)
                        .frame(width: 4, height: 56)
                }
                .offset(y: -96)
                .rotationEffect(.degrees(bearing))
            }
            .rotationEffect(.degrees(dialRotation))
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dialRotation)

            // Fixed device-forward indicator.
            VStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.title2)
                    .foregroundStyle(aligned ? Color.green : .white)
                Spacer()
            }
            .padding(.top, -14)

            VStack(spacing: 2) {
                Text(heading != nil ? "\(Int((heading ?? 0).rounded()))°" : "—")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(aligned ? "Facing the qibla" : "Rotate toward the gold marker")
                    .font(.caption)
                    .foregroundStyle(aligned ? Color.green : .white.opacity(0.65))
            }
        }
        .frame(width: 320, height: 320)
        .onChange(of: aligned) { _, isAligned in
            if isAligned && !celebratedAlignment {
                Haptics.success()
                celebratedAlignment = true
            } else if !isAligned {
                celebratedAlignment = false
            }
        }
        .accessibilityElement()
        .accessibilityLabel(qiblaAccessibilityLabel(heading: heading, aligned: aligned))
    }

    private func qiblaAccessibilityLabel(heading: Double?, aligned: Bool) -> String {
        guard let heading else {
            return "Compass unavailable. The qibla is \(Int(bearing.rounded())) degrees from north."
        }
        if aligned { return "You are facing the qibla." }
        var delta = bearing - heading
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        let direction = delta >= 0 ? "right" : "left"
        return "Turn \(abs(Int(delta.rounded()))) degrees to the \(direction) to face the qibla."
    }

    private var statusFooter: some View {
        Group {
            if compass.heading == nil {
                VStack(spacing: 6) {
                    Label(
                        compass.isAvailable ? "Waiting for the compass…" : "Compass unavailable on this device",
                        systemImage: compass.isAvailable ? "antenna.radiowaves.left.and.right" : "exclamationmark.triangle"
                    )
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    Text("You can still orient manually: face \(Int(bearing.rounded()))° from north (use a physical compass or the sun). Magnetic heading may differ slightly from true north.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            } else {
                Text("Heading uses the magnetometer only — no location access, nothing leaves your iPhone.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}
