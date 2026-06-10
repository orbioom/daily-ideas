import SwiftUI
import SwiftData

/// Browse, filter, favorite, and "spin" the built-in date-idea deck.
struct IdeasView: View {
    @Environment(\.modelContext) private var context
    @Query private var marks: [IdeaMark]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cost: IdeaCost?
    @State private var setting: IdeaSetting?
    @State private var energy: IdeaEnergy?
    @State private var spunID: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        filters
                        spinCard
                        if filtered.isEmpty {
                            EmptyStateView(
                                icon: "lightbulb.slash",
                                title: "Nothing matches",
                                message: "Loosen a filter — the perfect date is hiding behind one of them."
                            )
                        } else {
                            ForEach(filtered) { idea in
                                IdeaCard(idea: idea, mark: mark(for: idea),
                                         highlighted: idea.id == spunID,
                                         onFavorite: { toggleFavorite(idea) },
                                         onDone: { toggleDone(idea) })
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Date Ideas")
        }
    }

    private var filtered: [DateIdea] {
        DateIdeaCatalog.all.filter { idea in
            (cost == nil || idea.cost == cost)
            && (setting == nil || idea.setting == setting)
            && (energy == nil || idea.energy == energy)
        }
    }

    private func mark(for idea: DateIdea) -> IdeaMark? {
        marks.first { $0.ideaID == idea.id }
    }

    private func ensureMark(_ idea: DateIdea) -> IdeaMark {
        if let m = mark(for: idea) { return m }
        let m = IdeaMark(ideaID: idea.id)
        context.insert(m)
        return m
    }

    private func toggleFavorite(_ idea: DateIdea) {
        let m = ensureMark(idea)
        m.favorite.toggle()
        Haptics.tap()
    }

    private func toggleDone(_ idea: DateIdea) {
        let m = ensureMark(idea)
        m.done.toggle()
        m.doneDate = m.done ? .now : nil
        if m.done { Haptics.success() } else { Haptics.tap() }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Filters")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("Any cost", isOn: cost == nil) { cost = nil }
                    ForEach(IdeaCost.allCases) { c in
                        chip(c.label, isOn: cost == c) { cost = (cost == c ? nil : c) }
                    }
                    Divider().frame(height: 22)
                    ForEach(IdeaSetting.allCases) { s in
                        chip(s.rawValue, isOn: setting == s) { setting = (setting == s ? nil : s) }
                    }
                    Divider().frame(height: 22)
                    ForEach(IdeaEnergy.allCases) { e in
                        chip(e.rawValue, isOn: energy == e) { energy = (energy == e ? nil : e) }
                    }
                }
            }
        }
        .glassCard()
    }

    private func chip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isOn ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                            in: Capsule())
                .foregroundStyle(isOn ? Color.white : Brand.text)
                .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(isOn ? 0 : 0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var spinCard: some View {
        Button {
            guard let pick = filtered.randomElement() else { return }
            Haptics.success()
            withAnimation(reduceMotion ? nil : Brand.ease()) { spunID = pick.id }
        } label: {
            Label("Spin — pick tonight for us", systemImage: "sparkles")
        }
        .buttonStyle(InkButtonStyle())
        .disabled(filtered.isEmpty)
        .accessibilityHint("Randomly highlights one idea from the filtered list")
    }
}

private struct IdeaCard: View {
    let idea: DateIdea
    let mark: IdeaMark?
    let highlighted: Bool
    let onFavorite: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(idea.title)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer()
                if highlighted {
                    HStack(spacing: 5) {
                        StatusDot()
                        Text("tonight?")
                            .font(.caption)
                            .foregroundStyle(Brand.live)
                    }
                }
            }
            Text(idea.blurb)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                tag(idea.cost.label)
                tag(idea.setting.rawValue)
                tag(idea.energy.rawValue)
                Spacer()
                Button(action: onFavorite) {
                    Image(systemName: mark?.favorite == true ? "star.fill" : "star")
                        .foregroundStyle(mark?.favorite == true ? Brand.warn : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mark?.favorite == true ? "Unfavorite" : "Favorite")
                Button(action: onDone) {
                    Image(systemName: mark?.done == true ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(mark?.done == true ? Brand.live : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mark?.done == true ? "Mark as not done" : "Mark as done")
            }
        }
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(highlighted ? Brand.live.opacity(0.7) : Color.clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .contain)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Brand.mono(11))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(Brand.text3)
    }
}
