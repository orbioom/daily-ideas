import SwiftUI

/// A reference library: signs, planets, houses — the vocabulary the rest of
/// the app uses, explained in plain language.
struct GuideView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case signs = "Signs"
        case planets = "Planets"
        case houses = "Houses"
        var id: String { rawValue }
    }

    @State private var section: Section = .signs

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        Picker("Section", selection: $section) {
                            ForEach(Section.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch section {
                        case .signs: signsList
                        case .planets: planetsList
                        case .houses: housesList
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Guide")
        }
    }

    private var signsList: some View {
        VStack(spacing: 10) {
            ForEach(Sign.allCases) { sign in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(sign.glyph)
                            .font(.title3)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        Text(sign.name)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(sign.element) · \(sign.modality)")
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                    Text(sign.style.prefix(1).uppercased() + sign.style.dropFirst() + ".")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                .glassCard()
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var planetsList: some View {
        VStack(spacing: 10) {
            ForEach(Planet.allCases) { planet in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(planet.glyph)
                            .font(.title3)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        Text(planet.name)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        if !planet.isClassical {
                            Text("modern")
                                .font(Brand.mono(11))
                                .foregroundStyle(Brand.text3)
                        }
                    }
                    Text("Governs \(planet.theme).")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                .glassCard()
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var housesList: some View {
        VStack(spacing: 10) {
            ForEach(Array(ChartEngine.houseMeanings.enumerated()), id: \.offset) { index, meaning in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text2)
                        .frame(width: 26)
                    Text(meaning)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer(minLength: 0)
                }
                .glassCard(padding: 14)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("House \(index + 1): \(meaning)")
            }
            Text("House counting starts at your rising sign and runs counterclockwise around the wheel.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
                .padding(.top, 4)
        }
    }
}
