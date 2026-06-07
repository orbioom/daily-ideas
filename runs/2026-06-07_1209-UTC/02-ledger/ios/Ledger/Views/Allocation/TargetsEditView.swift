import SwiftUI
import SwiftData

/// Edit target allocation percentages per asset class. Live total shows whether
/// the plan adds up to 100%.
struct TargetsEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [Target]

    @State private var percents: [AssetClass: Double] = [:]

    private var total: Double { percents.values.map { max(0, $0) }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Target weights")
                        Text("Set the share of your investable assets you want in each class. Aim for a total of 100%.")
                            .font(.caption).foregroundStyle(Brand.text2)
                    }.frame(maxWidth: .infinity, alignment: .leading).glassCard()

                    VStack(spacing: 14) {
                        ForEach(AssetClass.investable) { cls in
                            VStack(spacing: 6) {
                                HStack {
                                    Label(cls.rawValue, systemImage: cls.symbol)
                                        .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    Spacer()
                                    Text(String(format: "%.0f%%", percents[cls] ?? 0))
                                        .font(Brand.mono(15, weight: .semibold)).foregroundStyle(cls.tint)
                                }
                                Slider(value: bindingFor(cls), in: 0...100, step: 1)
                                    .tint(cls.tint)
                            }
                        }
                    }.glassCard()

                    HStack {
                        Text("Total").font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(String(format: "%.0f%%", total))
                            .font(Brand.mono(18, weight: .bold))
                            .foregroundStyle(abs(total - 100) < 0.5 ? Brand.live : Brand.warn)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Targets")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.tint(Brand.text) }
            }
            .onAppear(perform: load)
        }
    }

    private func bindingFor(_ cls: AssetClass) -> Binding<Double> {
        Binding(get: { percents[cls] ?? 0 }, set: { percents[cls] = $0 })
    }

    private func load() {
        for t in existing { percents[t.assetClass] = t.percent }
    }

    private func save() {
        for t in existing { context.delete(t) }
        for cls in AssetClass.investable {
            let p = percents[cls] ?? 0
            if p > 0 { context.insert(Target(assetClass: cls, percent: p)) }
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
