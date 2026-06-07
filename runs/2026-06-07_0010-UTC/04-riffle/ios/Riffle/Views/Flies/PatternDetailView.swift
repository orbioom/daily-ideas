import SwiftUI
import SwiftData

struct PatternDetailView: View {
    @Bindable var pattern: Pattern
    @Environment(\.modelContext) private var context
    @Query private var catches: [Catch]
    @State private var showingEdit = false

    private var catchesOnFly: [Catch] {
        catches.filter { $0.patternName == pattern.name }.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    stockCard
                    recipeCard
                    catchesCard
                    if !pattern.notes.isEmpty { notesCard }
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        pattern.isFavorite.toggle(); try? context.save()
                    } label: { Label(pattern.isFavorite ? "Unfavorite" : "Favorite", systemImage: "star") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { PatternEditView(pattern: pattern) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: pattern.type.symbol).font(.system(size: 34, weight: .light))
                .foregroundStyle(pattern.type.tint).accessibilityHidden(true)
            HStack(spacing: 8) {
                Chip(text: pattern.type.label, tint: pattern.type.tint)
                Chip(text: pattern.sizeLabel)
                if !pattern.imitates.isEmpty { Chip(text: pattern.imitates, system: "leaf") }
            }
            DifficultyDots(level: pattern.difficulty)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 18)
    }

    private var stockCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "In the box")
                Text("\(pattern.inStock)").font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(pattern.isLow ? Brand.warn : Brand.text)
                    .contentTransition(.numericText())
            }
            Spacer()
            HStack(spacing: 10) {
                stockButton("minus", "Lost one") {
                    if pattern.inStock > 0 { pattern.inStock -= 1; try? context.save(); Haptics.tap() }
                }
                stockButton("plus", "Tied one") {
                    pattern.inStock += 1; try? context.save(); Haptics.success()
                }
            }
        }
        .glassCard(padding: 18)
    }

    private func stockButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }

    private var recipeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recipe", trailing: "\(pattern.materials.count) materials")
            if pattern.materials.isEmpty {
                Text("No materials listed. Edit the pattern to add its recipe.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(pattern.orderedMaterials) { m in
                    HStack(alignment: .top) {
                        Text(m.part.label.uppercased())
                            .font(Brand.mono(11, weight: .medium)).tracking(0.8)
                            .foregroundStyle(Brand.text3)
                            .frame(width: 74, alignment: .leading)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(m.name).font(.subheadline).foregroundStyle(Brand.text)
                            if !m.detail.isEmpty {
                                Text(m.detail).font(.caption).foregroundStyle(Brand.text3)
                            }
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(m.part.label): \(m.name) \(m.detail)")
                }
            }
        }
        .glassCard()
    }

    private var catchesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Catches on this fly", trailing: "\(catchesOnFly.count)")
            if catchesOnFly.isEmpty {
                Text("No catches logged on this pattern yet.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(catchesOnFly.prefix(6)) { c in
                    HStack {
                        Image(systemName: "fish").foregroundStyle(Brand.info)
                            .frame(width: 22).accessibilityHidden(true)
                        Text(c.species).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Fmt.shortDate(c.date)).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Notes")
            Text(pattern.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}
