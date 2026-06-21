import SwiftUI

struct ElementDetailView: View {
    let element: Element
    var colorBlindMode: Bool = false
    var kelvin: Bool = false

    private var catColor: Color {
        element.category.displayColor(colorBlind: colorBlindMode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                heroSection

                // Properties card
                VStack(spacing: 0) {
                    propertyGroup("Identity") {
                        PropertyRow(label: "Symbol", value: element.symbol)
                        PropertyDivider()
                        PropertyRow(label: "Atomic Number", value: "\(element.atomicNumber)")
                        PropertyDivider()
                        PropertyRow(label: "Atomic Mass", value: String(format: "%.4f u", element.atomicMass))
                        PropertyDivider()
                        PropertyRow(label: "Category", value: element.category.rawValue, valueColor: catColor)
                        if let grp = element.group {
                            PropertyDivider()
                            PropertyRow(label: "Group", value: "\(grp)")
                        }
                        PropertyDivider()
                        PropertyRow(label: "Period", value: "\(element.period)")
                    }

                    Spacer().frame(height: 12)

                    propertyGroup("Electronic") {
                        PropertyRow(label: "Electron Config.", value: element.electronConfig)
                        if let en = element.electronegativity {
                            PropertyDivider()
                            PropertyRow(label: "Electronegativity", value: String(format: "%.2f (Pauling)", en))
                        }
                    }

                    Spacer().frame(height: 12)

                    propertyGroup("Physical") {
                        meltingRow
                        PropertyDivider()
                        boilingRow
                        if let year = element.discoveredYear {
                            PropertyDivider()
                            PropertyRow(label: "Discovered", value: "\(year)")
                        }
                    }

                    Spacer().frame(height: 12)

                    propertyGroup("Uses") {
                        HStack(alignment: .top) {
                            Text(element.uses)
                                .font(.subheadline)
                                .foregroundStyle(AtomTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Spacer().frame(height: 12)

                    propertyGroup("Fun Fact") {
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AtomTheme.warning)
                                .font(.subheadline)
                                .padding(.top, 1)
                            Text(element.funFact)
                                .font(.subheadline)
                                .foregroundStyle(AtomTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(AtomTheme.background)
        .navigationTitle(element.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var heroSection: some View {
        ZStack {
            catColor.opacity(0.25)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 8) {
                Text(element.symbol)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(catColor)

                Text(element.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AtomTheme.textPrimary)

                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("Z")
                            .font(.caption)
                            .foregroundStyle(AtomTheme.textSecondary)
                        Text("\(element.atomicNumber)")
                            .font(.headline)
                            .foregroundStyle(AtomTheme.textPrimary)
                    }
                    VStack(spacing: 2) {
                        Text("Mass")
                            .font(.caption)
                            .foregroundStyle(AtomTheme.textSecondary)
                        Text(String(format: "%.3f", element.atomicMass))
                            .font(.headline)
                            .foregroundStyle(AtomTheme.textPrimary)
                    }
                    VStack(spacing: 2) {
                        Text("Period")
                            .font(.caption)
                            .foregroundStyle(AtomTheme.textSecondary)
                        Text("\(element.period)")
                            .font(.headline)
                            .foregroundStyle(AtomTheme.textPrimary)
                    }
                }

                Text(element.category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(catColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(catColor.opacity(0.20))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func propertyGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AtomTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
        }
    }

    private var meltingRow: some View {
        Group {
            if let mp = element.meltingPointK {
                if kelvin {
                    PropertyRow(label: "Melting Point", value: String(format: "%.2f K", mp))
                } else {
                    PropertyRow(label: "Melting Point", value: String(format: "%.2f °C", mp - 273.15))
                }
            } else {
                PropertyRow(label: "Melting Point", value: "Unknown", valueColor: AtomTheme.textSecondary)
            }
        }
    }

    private var boilingRow: some View {
        Group {
            if let bp = element.boilingPointK {
                if kelvin {
                    PropertyRow(label: "Boiling Point", value: String(format: "%.2f K", bp))
                } else {
                    PropertyRow(label: "Boiling Point", value: String(format: "%.2f °C", bp - 273.15))
                }
            } else {
                PropertyRow(label: "Boiling Point", value: "Unknown", valueColor: AtomTheme.textSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ElementDetailView(element: Element.all[78])
    }
    .preferredColorScheme(.dark)
}
