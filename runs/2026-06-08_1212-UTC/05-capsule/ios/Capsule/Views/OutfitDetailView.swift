import SwiftUI
import SwiftData

struct OutfitDetailView: View {
    @Bindable var outfit: Outfit
    @Environment(\.modelContext) private var context
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @State private var editing = false
    @State private var wornConfirm = false

    private let engine = WardrobeEngine()

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    summary
                    wearButton
                    piecesCard
                    if !outfit.notes.isEmpty { notesCard }
                }
                .padding()
            }
        }
        .navigationTitle(outfit.name.isEmpty ? "Outfit" : outfit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit outfit")
            }
        }
        .sheet(isPresented: $editing) { OutfitEditorView(outfit: outfit, isNew: false) }
        .alert("Logged!", isPresented: $wornConfirm) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Added a wear to each of the \(outfit.items.count) pieces in this outfit.")
        }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            stat("\(outfit.items.count)", "pieces", "square.stack.3d.up.fill")
            stat(Money.string(outfit.totalValue, code: currency), "total value", "tag.fill")
            stat(outfit.favorite ? "Yes" : "No", "favorite", "heart.fill")
        }
    }

    private func stat(_ v: String, _ l: String, _ s: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: s).font(.subheadline).foregroundStyle(Color.accentColor)
            Text(v).font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 12)
        .accessibilityElement(children: .combine).accessibilityLabel("\(v) \(l)")
    }

    private var wearButton: some View {
        Button {
            for pair in engine.wearLogs(for: outfit, on: .now) {
                context.insert(WearLog(date: pair.date, item: pair.item))
            }
            Haptics.success()
            wornConfirm = true
        } label: { Label("Wear this today", systemImage: "checkmark.circle.fill") }
            .buttonStyle(InkButtonStyle())
            .disabled(outfit.items.isEmpty)
    }

    private var piecesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pieces").font(.headline).foregroundStyle(Brand.text)
            if outfit.items.isEmpty {
                Text("No pieces yet. Tap edit to add some.").font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(outfit.items.sorted { $0.category.rawValue < $1.category.rawValue }) { item in
                    HStack(spacing: 12) {
                        ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 44, corner: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name.isEmpty ? "Untitled" : item.name)
                                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text(item.category.label).font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text("\(item.wearCount)×").font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Notes")
            Text(outfit.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}
