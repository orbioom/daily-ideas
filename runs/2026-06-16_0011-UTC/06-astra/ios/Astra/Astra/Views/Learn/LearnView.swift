import SwiftUI

/// The glossary: signs, planets, houses, and aspects with grounded meanings.
struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var section: Section = .signs

    enum Section: String, CaseIterable, Identifiable {
        case signs = "Signs"
        case planets = "Planets"
        case houses = "Houses"
        case aspects = "Aspects"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    picker
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            switch section {
                            case .signs: signsContent
                            case .planets: planetsContent
                            case .houses: housesContent
                            case .aspects: aspectsContent
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var picker: some View {
        Picker("Topic", selection: $section) {
            ForEach(Section.allCases) { s in Text(s.rawValue).tag(s) }
        }
        .pickerStyle(.segmented)
        .padding(16)
    }

    private var signsContent: some View {
        ForEach(ZodiacSign.allCases) { sign in
            entryCard(glyph: sign.glyph,
                      tint: sign.element.color,
                      title: sign.name,
                      subtitle: "\(sign.element.rawValue) · \(sign.modality.rawValue) · ruled by \(sign.rulingPlanet.name) · \(sign.dateRange)",
                      body: sign.summary)
        }
    }

    private var planetsContent: some View {
        ForEach(Planet.allCases) { planet in
            entryCard(glyph: planet.glyph,
                      tint: Theme.gold,
                      title: planet.name,
                      subtitle: planet.keywords.joined(separator: " · "),
                      body: planet.role)
        }
    }

    private var housesContent: some View {
        ForEach(House.allCases) { house in
            entryCard(glyph: house.ordinal,
                      tint: Theme.accent,
                      title: "\(house.ordinal) House · \(house.title)",
                      subtitle: nil,
                      body: house.meaning)
        }
    }

    private var aspectsContent: some View {
        ForEach(AspectKind.allCases) { kind in
            entryCard(glyph: kind.glyph,
                      tint: kind.color,
                      title: "\(kind.rawValue) (\(Int(kind.angle))\u{00B0})",
                      subtitle: kind.isChallenging ? "Tension" : "Flowing",
                      body: kind.meaning)
        }
    }

    private func entryCard(glyph: String, tint: Color, title: String, subtitle: String?, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(glyph)
                .font(.system(size: 26))
                .foregroundStyle(tint)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
                Text(body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LearnView()
}
