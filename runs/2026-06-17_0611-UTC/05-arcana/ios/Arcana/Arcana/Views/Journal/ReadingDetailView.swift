import SwiftUI
import SwiftData

struct ReadingDetailView: View {
    @Bindable var reading: Reading
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @State private var paywall: PaywallReason?
    @State private var showShare = false

    private var orderedCards: [DrawnCard] {
        reading.cards.sorted { $0.positionIndex < $1.positionIndex }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                ForEach(orderedCards, id: \.positionIndex) { dc in
                    positionRow(dc)
                }
                reflectionEditor
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(reading.spreadType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isPro { showShare = true } else { paywall = .export }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export reading")
            }
        }
        .sheet(item: $paywall) { PaywallView(reason: $0) }
        .sheet(isPresented: $showShare) {
            ShareSheet(text: exportText)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: reading.spreadType.icon)
                .font(.system(size: 36)).foregroundStyle(Theme.gold)
            Text(reading.date, format: .dateTime.weekday().month().day().year().hour().minute())
                .font(.subheadline).foregroundStyle(Theme.inkSoft)
            if let q = reading.question, !q.isEmpty {
                Text("“\(q)”")
                    .font(Theme.serif(18, .medium).italic())
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func positionRow(_ dc: DrawnCard) -> some View {
        if let card = dc.card {
            let pos = reading.spreadType.positions[safe: dc.positionIndex]
            HStack(alignment: .top, spacing: 14) {
                NavigationLink {
                    CardDetailView(card: card)
                } label: {
                    CardArtView(card: card, reversed: dc.reversed, showName: false)
                        .frame(width: 70)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 5) {
                    Text(pos?.title ?? "Card \(dc.positionIndex + 1)")
                        .font(.headline).foregroundStyle(Theme.ink)
                    HStack(spacing: 6) {
                        Text(card.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accentDeep)
                        if dc.reversed {
                            Text("Reversed").font(.caption2.weight(.bold)).foregroundStyle(Theme.gold)
                        }
                    }
                    Text(dc.reversed ? card.reversed : card.upright)
                        .font(.footnote).foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .cardSurface()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(pos?.title ?? "Card"): \(cardAccessibilityLabel(card, reversed: dc.reversed))")
        }
    }

    private var reflectionEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Reflection", icon: "square.and.pencil")
            TextEditor(text: $reading.reflection)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                .accessibilityLabel("Reflection note")
                .onChange(of: reading.reflection) { _, _ in
                    try? context.save()
                }
            Text("Mood").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.inkSoft)
            MoodPicker(mood: Binding(
                get: { reading.mood },
                set: { reading.mood = $0; try? context.save() }
            ))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var exportText: String {
        var lines: [String] = []
        lines.append("Arcana — \(reading.spreadType.rawValue)")
        lines.append(reading.date.formatted(.dateTime.month().day().year().hour().minute()))
        if let q = reading.question, !q.isEmpty { lines.append("Question: \(q)") }
        lines.append("")
        for dc in orderedCards {
            guard let card = dc.card else { continue }
            let title = reading.spreadType.positions[safe: dc.positionIndex]?.title ?? "Card \(dc.positionIndex + 1)"
            lines.append("\(title): \(card.name)\(dc.reversed ? " (Reversed)" : "")")
            lines.append("  \(dc.reversed ? card.reversed : card.upright)")
        }
        if !reading.reflection.isEmpty {
            lines.append("")
            lines.append("Reflection: \(reading.reflection)")
        }
        return lines.joined(separator: "\n")
    }
}

/// Daily-draw detail with an editable reflection.
struct DailyDrawDetailView: View {
    @Bindable var draw: DailyDraw
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let card = draw.card {
                    CardArtView(card: card, reversed: draw.reversed)
                        .frame(maxWidth: 200)
                        .accessibilityHidden(false)
                        .accessibilityLabel(cardAccessibilityLabel(card, reversed: draw.reversed))
                    Text(card.name).font(Theme.serif(26, .bold)).foregroundStyle(Theme.ink)
                    Text(draw.date, format: .dateTime.weekday().month().day().year())
                        .font(.subheadline).foregroundStyle(Theme.inkSoft)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: draw.reversed ? "Reversed" : "Upright")
                        Text(draw.reversed ? card.reversed : card.upright)
                            .font(.body).foregroundStyle(Theme.ink)
                        KeywordRow(keywords: card.keywords)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding().cardSurface()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Reflection", icon: "square.and.pencil")
                        TextEditor(text: $draw.reflection)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                            .accessibilityLabel("Reflection note")
                            .onChange(of: draw.reflection) { _, _ in try? context.save() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding().cardSurface()

                    NavigationLink {
                        CardDetailView(card: card)
                    } label: {
                        Label("Open full card", systemImage: "arrow.right.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accentDeep)
                    }
                } else {
                    EmptyStateView(icon: "questionmark.circle",
                                   title: "Card unavailable",
                                   message: "This entry's card couldn't be found.")
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Daily Draw")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Thin UIActivityViewController wrapper for exporting a reading as text.
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
