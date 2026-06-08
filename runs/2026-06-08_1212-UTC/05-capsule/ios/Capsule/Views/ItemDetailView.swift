import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: ClothingItem
    @Environment(\.modelContext) private var context
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @State private var editing = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    statsRow
                    wearButton
                    if !item.outfits.isEmpty { outfitsCard }
                    historyCard
                    if !item.notes.isEmpty { notesCard }
                }
                .padding()
            }
        }
        .navigationTitle(item.name.isEmpty ? "Piece" : item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit")
            }
        }
        .sheet(isPresented: $editing) { ItemEditorView(item: item, isNew: false) }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 140, corner: 22)
            VStack(spacing: 4) {
                Text(item.name.isEmpty ? "Untitled" : item.name)
                    .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Text(item.category.label)
                    if !item.brand.isEmpty { Text("· \(item.brand)") }
                    if !item.colorName.isEmpty { Text("· \(item.colorName)") }
                }
                .font(.caption).foregroundStyle(Brand.text3)
            }
            if !item.seasons().isEmpty && item.seasonsMask != 0 {
                HStack(spacing: 8) {
                    ForEach(item.seasons()) { s in
                        Label(s.label, systemImage: s.symbol)
                            .font(.caption2).foregroundStyle(Brand.text2)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.gray.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat("\(item.wearCount)", "wears", "arrow.triangle.2.circlepath")
            stat(item.cost > 0 ? Money.string(item.cost, code: currency) : "—", "cost", "tag.fill")
            stat(item.costPerWear.map { Money.precise($0, code: currency) } ?? "—", "per wear", "chart.line.downtrend.xyaxis")
        }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.subheadline).foregroundStyle(Color.accentColor)
            Text(value).font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 12)
        .accessibilityElement(children: .combine).accessibilityLabel("\(value) \(label)")
    }

    private var wearButton: some View {
        Button {
            context.insert(WearLog(date: .now, item: item))
            Haptics.success()
        } label: {
            Label("I wore this today", systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(InkButtonStyle())
    }

    private var outfitsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In outfits").font(.headline).foregroundStyle(Brand.text)
            FlexibleWrap(spacing: 8, lineSpacing: 8) {
                ForEach(item.outfits) { o in
                    Text(o.name)
                        .font(Brand.mono(12)).foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
            }
        }
        .glassCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wear history").font(.headline).foregroundStyle(Brand.text)
            if item.wearLogs.isEmpty {
                Text("Not worn yet. Tap the button above the first time you wear it.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(item.wearLogs.sorted { $0.date > $1.date }.prefix(12)) { log in
                    HStack {
                        Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(Color.accentColor)
                        Text(Format.dayFull.string(from: log.date)).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Button {
                            context.delete(log); Haptics.warning()
                        } label: { Image(systemName: "minus.circle").font(.caption).foregroundStyle(Brand.text3) }
                            .accessibilityLabel("Remove wear")
                    }
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Notes")
            Text(item.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}
