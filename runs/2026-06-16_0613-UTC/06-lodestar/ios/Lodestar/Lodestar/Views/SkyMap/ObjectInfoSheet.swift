import SwiftUI

/// A compact info sheet shown when tapping a body on the chart.
/// Offers a path to the full ObjectDetailView.
struct ObjectInfoSheet: View {
    let object: SkyObject
    let context: ObserverContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(object.tint.opacity(0.2)).frame(width: 56, height: 56)
                        Image(systemName: object.kind.symbol).font(.title2).foregroundStyle(object.tint)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(object.name).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                        HStack(spacing: 6) {
                            Pill(text: object.kind.rawValue)
                            if !object.constellation.isEmpty { Pill(text: object.constellation, color: Theme.gold) }
                        }
                    }
                    Spacer()
                }

                HStack {
                    miniStat("Direction", object.horizontal.compass16, Theme.accent)
                    miniStat("Altitude", Fmt.altitude(object.horizontal.altitude),
                             object.isAboveHorizon ? Theme.good : Theme.inkSoft)
                    if object.kind != .sun {
                        miniStat("Brightness", Fmt.mag(object.magnitude), Theme.inkSoft)
                    }
                }
                .padding(14)
                .cardSurface()

                Text(object.summary)
                    .font(.callout)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    ObjectDetailView(object: object, context: context)
                } label: {
                    Text("Full details")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.accent))
                        .foregroundStyle(Color(hex: 0x05070E))
                }
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle(object.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }

    private func miniStat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.rounded(17, .bold)).foregroundStyle(tint)
            Text(title).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}
