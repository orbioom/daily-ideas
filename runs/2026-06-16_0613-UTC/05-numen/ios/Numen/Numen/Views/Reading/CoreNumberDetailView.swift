import SwiftUI

/// The interpretation sheet for one core number, with transparent math.
struct CoreNumberDetailView: View {
    let core: CoreNumber
    let profile: Profile
    @Environment(\.dismiss) private var dismiss

    private var meaning: NumberMeaning { InterpretationLibrary.meaning(for: core.value) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    framing
                    section(title: "Essence", body: meaning.essence)
                    keywordSection
                    twoColumn
                    derivation
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(core.position.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            NumberGlyph(value: core.value, size: 78, isMaster: core.reduction.isMaster)
            Text(meaning.title)
                .font(Theme.serif(.title))
                .foregroundStyle(Theme.ink)
            Text(core.position.subtitle)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 8) {
                if core.reduction.isMaster { TagPill(text: "Master Number", tint: Theme.accent) }
                if let debt = core.reduction.karmicDebt { TagPill(text: "Karmic Debt \(debt)", tint: Theme.warn) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(core.position.rawValue) number \(core.value), \(meaning.title)")
    }

    private var framing: some View {
        Text(meaning.framing(for: core.position))
            .font(Theme.serif(.body))
            .italic()
            .foregroundStyle(Theme.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.cornerM))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func section(title: String, body text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var keywordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keywords").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
            FlowTags(items: meaning.keywords)
        }
    }

    private var twoColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            listBlock(title: "Strengths", symbol: "checkmark.seal.fill", tint: Theme.good, items: meaning.strengths)
            listBlock(title: "Challenges", symbol: "exclamationmark.circle.fill", tint: Theme.warn, items: meaning.challenges)
        }
    }

    private func listBlock(title: String, symbol: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(tint)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(tint).frame(width: 5, height: 5).padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(item).font(.callout).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
    }

    private var derivation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How this was derived", systemImage: "function")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.accent)
            ForEach(Array(core.reduction.steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityHidden(true)
                    Text(step)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                }
            }
            Text(sourceNote)
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.cornerM))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Derivation. " + core.reduction.steps.joined(separator: ", then "))
    }

    private var sourceNote: String {
        switch core.position {
        case .lifePath: return "Derived from \(profile.displayName)'s birthdate by reducing month, day and year, then summing."
        case .birthday: return "Derived from the day of the month of birth."
        case .expression: return "Sum of every letter in the full birth name."
        case .soulUrge: return "Sum of the vowels in the full birth name."
        case .personality: return "Sum of the consonants in the full birth name."
        case .maturity: return "The sum of the Life Path and Expression numbers."
        default: return "Computed from the relevant date and birth values."
        }
    }
}

/// Simple wrapping tag layout for keywords (iOS 17 safe).
struct FlowTags: View {
    let items: [String]
    var body: some View {
        Flow(spacing: 8) {
            ForEach(items, id: \.self) { TagPill(text: $0) }
        }
    }
}

/// A minimal flow layout using the iOS 16+ Layout protocol (available in iOS 17).
struct Flow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
                rows.append(0)
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
