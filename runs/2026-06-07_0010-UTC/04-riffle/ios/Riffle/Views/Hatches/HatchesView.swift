import SwiftUI
import SwiftData

struct HatchesView: View {
    @Query private var patterns: [Pattern]
    @State private var month = Calendar.current.component(.month, from: .now)

    private var active: [Hatch] { HatchCatalog.active(in: month) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        monthPicker
                        if active.isEmpty {
                            EmptyStateView(icon: "calendar",
                                           title: "Quiet month",
                                           message: "No major hatches charted for \(Fmt.monthName(month)). Search nymphs and midges subsurface.")
                        } else {
                            ForEach(active) { hatch in hatchCard(hatch) }
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
            .navigationTitle("Hatch chart")
        }
    }

    private var monthPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Month", trailing: "\(active.count) active")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { m in
                        Button {
                            Haptics.selection(); month = m
                        } label: {
                            Text(Fmt.shortMonth(m)).font(Brand.mono(13, weight: .medium))
                                .foregroundStyle(month == m ? .white : Brand.text)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(month == m ? AnyShapeStyle(Brand.inkGradient)
                                                       : AnyShapeStyle(.ultraThinMaterial),
                                            in: Capsule())
                        }
                        .accessibilityLabel(Fmt.monthName(m))
                    }
                }
            }
        }
        .glassCard()
    }

    private func hatchCard(_ hatch: Hatch) -> some View {
        let matched = RiffleLogic.matches(for: hatch, in: patterns)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hatch.name).font(.headline).foregroundStyle(Brand.text)
                    Text(hatch.order).font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Chip(text: "#\(hatch.hookSizes.lowerBound)–\(hatch.hookSizes.upperBound)")
            }
            Text(hatch.note).font(.subheadline).foregroundStyle(Brand.text2)
            HStack(spacing: 6) {
                ForEach(hatch.matchTypes) { t in
                    Chip(text: t.label, system: t.symbol, tint: t.tint)
                }
            }
            Divider().overlay(Brand.hairline)
            VStack(alignment: .leading, spacing: 6) {
                Text(matched.isEmpty ? "Nothing in your box matches — one to tie."
                                     : "In your box").font(Brand.mono(11, weight: .medium))
                    .tracking(1).foregroundStyle(matched.isEmpty ? Brand.warn : Brand.live)
                if !matched.isEmpty {
                    let cols = [GridItem(.adaptive(minimum: 110), spacing: 8)]
                    LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                        ForEach(matched) { p in
                            Chip(text: "\(p.name) \(p.sizeLabel)", system: "ant", tint: Brand.text)
                        }
                    }
                }
            }
        }
        .glassCard(padding: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hatch.name), \(hatch.order), sizes \(hatch.hookSizes.lowerBound) to \(hatch.hookSizes.upperBound). \(matched.count) matching flies in your box.")
    }
}
